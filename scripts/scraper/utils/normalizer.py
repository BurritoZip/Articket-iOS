"""텍스트 정규화 및 한국어 날짜 파싱"""
import re
import unicodedata
from datetime import date, datetime
from typing import Optional, Tuple


# 제목 정규화 (dedup 키 생성용)
def normalize_title(text: str) -> str:
    text = unicodedata.normalize("NFKC", text)
    text = text.lower()
    text = re.sub(r"[^\w가-힣]", "", text, flags=re.UNICODE)
    return text.strip()


def normalize_venue(text: str) -> str:
    text = unicodedata.normalize("NFKC", text)
    text = text.lower()
    text = re.sub(r"\s+", "", text)
    text = re.sub(r"[^\w가-힣]", "", text, flags=re.UNICODE)
    return text.strip()


def parse_date_range(raw: str) -> Tuple[Optional[date], Optional[date]]:
    """
    지원 형식:
      "2026.08.14 ~ 2026.08.16"   "2026.08.14 - 2026.08.16"
      "2026. 08. 14 ~ 2026. 08. 16"  (공백 포함)
      "2026년 6월 6~7일 (토~일)"   "2026년 6월 6일 (토)"
      "2026-08-14 ~ 2026-08-16"
    """
    raw = raw.strip()
    # 구분자 사이 공백 정규화: "2026. 06. 06" → "2026.06.06"
    raw = re.sub(r"(\d)\s*\.\s*(\d)", r"\1.\2", raw)

    # 형식 1: "YYYY.MM.DD ~ YYYY.MM.DD" / "YYYY.MM.DD - YYYY.MM.DD"
    m = re.search(
        r"(\d{4})[.\-](\d{1,2})[.\-](\d{1,2})\s*[~～\-]\s*(\d{4})[.\-](\d{1,2})[.\-](\d{1,2})",
        raw
    )
    if m:
        y1, mo1, d1, y2, mo2, d2 = (int(x) for x in m.groups())
        return _safe_date(y1, mo1, d1), _safe_date(y2, mo2, d2)

    # 형식 2: "YYYY.MM.DD" (단일)
    m = re.search(r"(\d{4})[.\-](\d{1,2})[.\-](\d{1,2})", raw)
    if m:
        y, mo, d = int(m.group(1)), int(m.group(2)), int(m.group(3))
        return _safe_date(y, mo, d), None

    # 형식 3: "YYYY년 MM월 DD~DD일"
    m = re.search(r"(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})[~～](\d{1,2})일", raw)
    if m:
        y, mo, d1, d2 = int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4))
        return _safe_date(y, mo, d1), _safe_date(y, mo, d2)

    # 형식 4: "YYYY년 MM월 DD일"
    m = re.search(r"(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일", raw)
    if m:
        y, mo, d = int(m.group(1)), int(m.group(2)), int(m.group(3))
        return _safe_date(y, mo, d), None

    # 형식 5: "MM.DD ~ MM.DD" (연도 없음 → 올해 또는 내년)
    m = re.search(r"(\d{1,2})[.\-](\d{1,2})\s*[~～]\s*(\d{1,2})[.\-](\d{1,2})", raw)
    if m:
        mo1, d1, mo2, d2 = int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4))
        year = _infer_year(mo1)
        return _safe_date(year, mo1, d1), _safe_date(year, mo2, d2)

    return None, None


def _safe_date(y: int, mo: int, d: int) -> Optional[date]:
    try:
        return date(y, mo, d)
    except ValueError:
        return None


def _infer_year(month: int) -> int:
    today = date.today()
    if month >= today.month:
        return today.year
    return today.year + 1


def determine_status(start: Optional[date], end: Optional[date]) -> str:
    if start is None:
        return "upcoming"
    today = date.today()
    if end and today > end:
        return "ended"
    if today >= start:
        return "on_sale"
    return "upcoming"
