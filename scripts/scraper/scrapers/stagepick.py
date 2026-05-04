"""StagePick 스크래퍼 — JSON REST API (공연 + 아티스트)"""
import html
from typing import Any, Optional

from config import STAGEPICK
from scrapers.base import BaseScraper
from utils.normalizer import parse_date_range, determine_status


class StagepickScraper(BaseScraper):

    BASE_API = "https://api.stagepick.co.kr/v1"

    def __init__(self):
        super().__init__(STAGEPICK["source_name"])
        self.session.headers.update({
            "Origin": "https://www.stagepick.co.kr",
            "Referer": "https://www.stagepick.co.kr/",
            "X-Requested-With": "XMLHttpRequest",
        })

    def scrape(self) -> list[dict[str, Any]]:
        events = self._fetch_performances()

        seen = set()
        unique = []
        for e in events:
            if e["dedup_key"] not in seen:
                seen.add(e["dedup_key"])
                unique.append(e)
        print(f"  [StagePick] 총 {len(unique)}개 이벤트 수집")
        return unique

    def scrape_artists(self) -> list[dict[str, Any]]:
        """아티스트 목록 수집 (main.py에서 별도 저장)"""
        artists = []
        seen_ids = set()

        try:
            resp = self.get(f"{self.BASE_API}/artists", params={"page": 1})
            data = resp.json()
        except Exception as e:
            print(f"  [StagePick 아티스트 오류] {e}")
            return []

        for item in data.get("upcoming", []) + data.get("popular", []):
            artist_id = str(item.get("id", ""))
            if artist_id in seen_ids:
                continue
            seen_ids.add(artist_id)
            name = item.get("name", "").strip()
            if name:
                artists.append({
                    "name": name,
                    "avatar_url": item.get("image_url"),
                    "upcoming_event_count": item.get("upcoming_performances"),
                })

        print(f"  [StagePick] 아티스트 {len(artists)}명 수집")
        return artists

    def _fetch_performances(self) -> list[dict[str, Any]]:
        events = []
        page = 1
        while True:
            params: dict = {"page": page}
            if page > 1:
                params["offset"] = 20 * (page - 1)

            try:
                resp = self.get(f"{self.BASE_API}/performances", params=params)
                data = resp.json()
            except Exception as e:
                print(f"  [StagePick 오류] page {page}: {e}")
                break

            for item in data.get("performances", []):
                event = self._parse_performance(item)
                if event:
                    events.append(event)

            print(f"  [StagePick] page {page} — {len(events)}개 누적")
            if not data.get("has_next_page"):
                break
            page += 1

        return events

    def _parse_performance(self, item: dict) -> Optional[dict[str, Any]]:
        try:
            title = html.unescape(item.get("title", "").strip())
            if not title:
                return None

            venue_name = item.get("venue", "").strip()
            date_raw = item.get("formatted_date", "")
            start_date, end_date = parse_date_range(date_raw)

            perf_id = item.get("id")
            image_url = item.get("image_url")
            source_url = f"https://www.stagepick.co.kr/performances/{perf_id}" if perf_id else None
            ticket_open_date = item.get("ticket_open_date")

            category = item.get("category") or ""
            _SKIP = {"뮤지컬", "연극", "클래식", "오페라", "발레"}
            if any(kw in category for kw in _SKIP):
                return None
            genre = "페스티벌" if "페스티벌" in category else "콘서트"
            status = determine_status(start_date, end_date)

            from utils.dedup import make_dedup_key
            dedup_key = make_dedup_key(title, venue_name, start_date)

            return {
                "title": title,
                "venue_name": venue_name,
                "start_date": start_date,
                "end_date": end_date,
                "genre": genre,
                "status": status,
                "image_url": image_url,
                "source_url": source_url,
                "dedup_key": dedup_key,
                "source_name": self.source_name,
                "artist_name": None,
                "ticket_provider": "stagepick",
            }
        except Exception as e:
            print(f"  [StagePick 파싱 오류] {e}")
            return None
