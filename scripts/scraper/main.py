#!/usr/bin/env python3
"""
Articket 크롤러 진입점

사용법:
  python main.py                      # 모든 사이트 크롤링 + Supabase 저장
  python main.py --site yes24         # 특정 사이트만
  python main.py --dry-run            # DB 저장 없이 파싱 결과만 출력
  python main.py --dry-run --site festivallife

환경 변수 (.env 파일):
  SUPABASE_URL          Supabase 프로젝트 URL
  SUPABASE_SERVICE_KEY  service_role 키 (write 권한 필요)
"""
import argparse
import json
import os
import sys

from dotenv import load_dotenv

load_dotenv()


def get_supabase_client():
    url = os.environ.get("SUPABASE_URL", "")
    key = os.environ.get("SUPABASE_SERVICE_KEY", "")
    if not url or not key:
        print("[오류] .env 파일에 SUPABASE_URL과 SUPABASE_SERVICE_KEY를 설정하세요.")
        sys.exit(1)
    from supabase import create_client
    return create_client(url, key)


def run_scraper(site: str):
    """지정된 사이트 스크래퍼를 실행하고 이벤트 목록 반환"""
    if site == "yes24":
        from scrapers.yes24 import Yes24Scraper
        return Yes24Scraper().scrape()
    elif site == "yanolja":
        from scrapers.yanolja import YanoljaScaper
        return YanoljaScaper().scrape()
    elif site == "festivallife":
        from scrapers.festivallife import FestivalLifeScraper
        return FestivalLifeScraper().scrape()
    elif site == "interpark":
        from scrapers.interpark import InterparkScraper
        return InterparkScraper().scrape()
    elif site == "melon":
        from scrapers.melon import MelonScraper
        return MelonScraper().scrape()
    elif site == "stagepick":
        from scrapers.stagepick import StagepickScraper
        return StagepickScraper().scrape()
    else:
        raise ValueError(f"알 수 없는 사이트: {site}")


def save_events(client, events: list[dict]) -> None:
    from database import upsert_venue, upsert_artist, upsert_event
    from utils.image import download_and_upload_poster

    for i, ev in enumerate(events, 1):
        try:
            # 1. 공연장 UPSERT — venue_name 이상값(title과 동일·날짜 패턴) 정제 후 저장
            venue_id = None
            from utils.normalizer import sanitize_venue
            clean_venue = sanitize_venue(ev.get("venue_name", ""), ev["title"])
            if clean_venue:
                venue_id = upsert_venue(
                    client,
                    name=clean_venue,
                    address=ev.get("venue_address", ""),
                )

            # 2. 아티스트 UPSERT (이름이 있을 때만)
            artist_id = None
            if ev.get("artist_name"):
                artist_id = upsert_artist(client, ev["artist_name"])

            # 3. 포스터 이미지 업로드
            poster_url = None
            if ev.get("image_url") and ev.get("dedup_key"):
                poster_url = download_and_upload_poster(
                    ev["image_url"], ev["dedup_key"], client
                )

            # 4. 이벤트 UPSERT
            upsert_event(
                client,
                dedup_key=ev["dedup_key"],
                title=ev["title"],
                artist_id=artist_id,
                venue_id=venue_id,
                start_date=ev.get("start_date"),
                end_date=ev.get("end_date"),
                status=ev.get("status", "upcoming"),
                genre=ev.get("genre", "콘서트"),
                poster_url=poster_url,
                ticket_provider=ev.get("ticket_provider"),
                source_name=ev["source_name"],
                source_url=ev.get("source_url"),
            )
            print(f"  [{i}/{len(events)}] 저장 완료: {ev['title'][:40]}")

        except Exception as e:
            print(f"  [{i}/{len(events)}] 저장 실패: {ev.get('title', '')[:40]} — {e}")


def _save_stagepick_artists(client) -> None:
    from scrapers.stagepick import StagepickScraper
    from database import upsert_artist
    artists = StagepickScraper().scrape_artists()
    print(f"\nStagePick 아티스트 저장 ({len(artists)}명)...")
    saved = 0
    for a in artists:
        try:
            upsert_artist(
                client,
                a["name"],
                avatar_url=a.get("avatar_url"),
                upcoming_event_count=a.get("upcoming_event_count"),
            )
            saved += 1
        except Exception as e:
            print(f"  [아티스트 저장 실패] {a['name']} — {e}")
    print(f"  아티스트 {saved}명 저장 완료")


def main():
    parser = argparse.ArgumentParser(description="Articket 공연 크롤러")
    parser.add_argument("--site", default="all", choices=["all", "yanolja", "yes24", "festivallife", "interpark", "melon", "stagepick"])
    parser.add_argument("--dry-run", action="store_true", help="DB 저장 없이 파싱 결과만 출력")
    args = parser.parse_args()

    sites = ["yanolja", "yes24", "festivallife", "interpark", "melon", "stagepick"] if args.site == "all" else [args.site]
    all_events = []

    for site in sites:
        print(f"\n{'='*50}")
        print(f"크롤링: {site}")
        print("="*50)
        try:
            events = run_scraper(site)
            all_events.extend(events)
        except Exception as e:
            print(f"[오류] {site} 크롤링 실패: {e}")

    # 공연이 아닌 콘텐츠 제외 (뮤지컬/연극/전시 등)
    _EXCLUDE_KEYWORDS = (
        "뮤지컬", "musical", "연극", "오페라", "발레",
        "전시회", "전람회", "전시관", "exhibition", "expo",
    )
    before = len(all_events)
    all_events = [
        e for e in all_events
        if not any(kw in e.get("title", "").lower() for kw in _EXCLUDE_KEYWORDS)
    ]
    excluded = before - len(all_events)
    if excluded:
        print(f"  [필터] 뮤지컬/연극/전시 등 {excluded}개 제외")

    # 장기 전시성 공연 제외 (90일 초과)
    from datetime import timedelta
    before = len(all_events)
    all_events = [
        e for e in all_events
        if not (
            e.get("start_date") and e.get("end_date")
            and (e["end_date"] - e["start_date"]).days > 90
        )
    ]
    long_excluded = before - len(all_events)
    if long_excluded:
        print(f"  [필터] 장기 공연(90일 초과) {long_excluded}개 제외")

    print(f"\n총 {len(all_events)}개 이벤트 수집 완료")

    if args.dry_run:
        print("\n[dry-run] 수집 결과 (최대 5개 미리보기):")
        for ev in all_events[:5]:
            printable = {k: str(v) if v else None for k, v in ev.items() if k != "image_url"}
            print(json.dumps(printable, ensure_ascii=False, indent=2))
        return

    client = get_supabase_client()

    # StagePick 아티스트 별도 저장
    if args.site in ("all", "stagepick"):
        _save_stagepick_artists(client)

    print(f"\nSupabase 저장 시작 ({len(all_events)}개)...")
    save_events(client, all_events)
    print("\n완료!")
    import subprocess
    subprocess.run([
        "terminal-notifier",
        "-message", f"{len(all_events)}개 이벤트 저장 완료!",
        "-title", "Articket 크롤러",
        "-sound", "Glass",
    ], check=False)


if __name__ == "__main__":
    main()
