#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
한국관광공사 고캠핑 API에서 전국 캠핑장 데이터를 수집하여 JSON으로 저장합니다.

사용법:
    1) https://www.data.go.kr 에서 "고캠핑 기본 정보" API 신청 (무료, 즉시 승인)
    2) 발급받은 서비스키를 아래 SERVICE_KEY에 입력
    3) python fetch-campgrounds.py 실행
    4) ../data/campgrounds.json 생성

생성된 JSON은 generate-pages.py 로 개별 캠핑장 HTML 페이지를 자동 생성하는 데 사용됩니다.
"""
import json
import time
import urllib.parse
import urllib.request
import os
from pathlib import Path

# =========================================================================
# 설정: 아래 값을 본인의 실제 서비스 키로 교체하세요
# =========================================================================
SERVICE_KEY = "여기에_공공데이터포털에서_받은_서비스키_입력"
# =========================================================================

API_BASE = "https://apis.data.go.kr/B551011/GoCamping/basedList"
OUTPUT_DIR = Path(__file__).parent.parent / "data"
OUTPUT_FILE = OUTPUT_DIR / "campgrounds.json"
PAGE_SIZE = 100  # 한 번에 가져올 개수 (API 최대 1000)
MAX_PAGES = 50    # 최대 페이지 (안전장치)


def fetch_page(page_no: int) -> dict:
    """API에서 한 페이지 데이터를 가져옵니다."""
    params = {
        "serviceKey": SERVICE_KEY,
        "numOfRows": PAGE_SIZE,
        "pageNo": page_no,
        "MobileOS": "ETC",
        "MobileApp": "gogocamp",
        "_type": "json",
    }
    url = f"{API_BASE}?{urllib.parse.urlencode(params, safe=':/+')}"
    req = urllib.request.Request(url, headers={"User-Agent": "gogocamp-fetcher/1.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def normalize(item: dict) -> dict:
    """API 응답 항목을 사이트에서 쓰기 좋은 형태로 정리합니다."""
    return {
        "contentId": item.get("contentId", ""),
        "name": (item.get("facltNm") or "").strip(),
        "sido": item.get("doNm", ""),
        "sigungu": item.get("sigunguNm", ""),
        "address": item.get("addr1", ""),
        "intro": (item.get("intro") or "").strip(),
        "features": (item.get("featureNm") or "").strip(),
        "theme": (item.get("themaEnvrnCl") or "").strip(),
        "induty": (item.get("induty") or "").strip(),  # 오토·글램핑 등 유형
        "lctCl": (item.get("lctCl") or "").strip(),  # 입지(산·해변·계곡)
        "hvofBgnde": item.get("hvofBgnde", ""),  # 운영 시작월
        "hvofEnddle": item.get("hvofEnddle", ""),  # 운영 종료월
        "animalCmgCl": (item.get("animalCmgCl") or "").strip(),  # 반려동물
        "tooltip": (item.get("tooltip") or "").strip(),
        "tel": item.get("tel", ""),
        "homepage": item.get("homepage", ""),
        "mapX": item.get("mapX", ""),
        "mapY": item.get("mapY", ""),
        "firstImageUrl": item.get("firstImageUrl", ""),
    }


def main():
    if SERVICE_KEY.startswith("여기에"):
        print("❌ SERVICE_KEY를 설정하세요.")
        print("   https://www.data.go.kr → '고캠핑 기본 정보' 검색 → 활용신청")
        return

    OUTPUT_DIR.mkdir(exist_ok=True)
    all_items = []
    total_count = None

    for page in range(1, MAX_PAGES + 1):
        print(f"페이지 {page} 요청 중...", flush=True)
        try:
            data = fetch_page(page)
        except Exception as e:
            print(f"❌ 페이지 {page} 실패: {e}")
            time.sleep(2)
            continue

        try:
            body = data["response"]["body"]
            if total_count is None:
                total_count = int(body.get("totalCount", 0))
                print(f"  총 {total_count}개 발견")
            items = body.get("items", {}).get("item", [])
            if not items:
                print("  더 이상 데이터 없음")
                break
            if isinstance(items, dict):
                items = [items]
            for it in items:
                all_items.append(normalize(it))
        except (KeyError, TypeError) as e:
            print(f"❌ 응답 구조 오류 (페이지 {page}): {e}")
            break

        if total_count and len(all_items) >= total_count:
            break
        time.sleep(0.3)  # API 쿼터 보호

    print(f"\n✅ 총 {len(all_items)}개 수집 완료")

    with OUTPUT_FILE.open("w", encoding="utf-8") as f:
        json.dump({"total": len(all_items), "items": all_items}, f, ensure_ascii=False, indent=2)
    print(f"💾 저장: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
