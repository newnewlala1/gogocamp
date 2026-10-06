#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
수집된 캠핑장 JSON을 바탕으로 개별 캠핑장 HTML 페이지를 자동 생성합니다.

사용법:
    1) fetch-campgrounds.py 먼저 실행 (data/campgrounds.json 생성)
    2) python generate-pages.py 실행
    3) ../camp/<slug>.html 2,000여 개 생성
    4) ../camp/index.html (전체 목록) 생성
    5) ../sitemap-camps.xml 생성
"""
import json
import re
from pathlib import Path
from html import escape

ROOT = Path(__file__).parent.parent
DATA_FILE = ROOT / "data" / "campgrounds.json"
OUT_DIR = ROOT / "camp"
SITEMAP = ROOT / "sitemap-camps.xml"

TEMPLATE = """<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{name} — {sigungu} 캠핑장 정보 | 고고캠프</title>
<meta name="description" content="{name} ({sigungu}) 캠핑장 공식 정보 요약. 주소·연락처·유형·시설·운영 기간·반려동물 동반 여부. 공식 사이트 링크 포함.">
<link rel="canonical" href="https://gogocamp.kr/camp/{slug}.html">
<link rel="stylesheet" href="../css/style.css?v=3">
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700;800&display=swap" rel="stylesheet">
<script type="application/ld+json">{schema}</script>
<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-8296789991007286" crossorigin="anonymous"></script>
<style>
.cp-wrap{{max-width:720px;margin:0 auto;padding:24px 16px}}
.cp-wrap h1{{font-size:1.6rem;margin:0 0 4px}}
.cp-wrap .cp-loc{{color:#6b7280;margin:0 0 20px;font-size:0.95rem}}
.cp-info{{background:#fff;border:1px solid #e5e7eb;border-radius:12px;padding:20px;margin-bottom:16px}}
.cp-info h2{{margin:0 0 12px;font-size:1.1rem;color:#065f46}}
.cp-info table{{width:100%;border-collapse:collapse}}
.cp-info td{{padding:8px 4px;border-bottom:1px solid #f3f4f6;font-size:0.95rem;vertical-align:top}}
.cp-info td:first-child{{color:#6b7280;width:120px;font-weight:600}}
.cp-tags{{margin:12px 0}}
.cp-tag{{display:inline-block;padding:4px 10px;background:#f0fdf4;color:#059669;border-radius:12px;font-size:0.8rem;margin-right:4px;margin-bottom:4px}}
.cp-notice{{background:#fffbeb;border:1px solid #fde68a;border-radius:8px;padding:12px;margin:16px 0;font-size:0.88rem;color:#78350f}}
.cp-cta{{display:inline-block;padding:10px 20px;background:#059669;color:#fff;border-radius:8px;text-decoration:none;font-weight:700;margin-top:8px;margin-right:8px}}
.cp-cta:hover{{background:#047857}}
.cp-cta.sub{{background:#fff;color:#059669;border:1px solid #059669}}
.breadcrumb-cp{{color:#6b7280;font-size:0.85rem;margin-bottom:16px}}
.breadcrumb-cp a{{color:#059669;text-decoration:none}}
</style>
</head>
<body>

<header><div class="container"><div class="header-inner"><a href="../index.html" class="logo">고고<span class="accent">캠프</span></a><nav><ul class="nav-menu"><li><a href="../index.html">홈</a></li><li><a href="../campgrounds.html" class="active">캠핑장 찾기</a></li><li><a href="../tools.html">도구</a></li><li><a href="../guide.html">가이드</a></li><li><a href="../tips.html">팁</a></li><li><a href="../about.html">소개</a></li></ul></nav></div></div></header>

<main>
<div class="cp-wrap">
<div class="breadcrumb-cp"><a href="../index.html">홈</a> › <a href="../campgrounds.html">캠핑장 찾기</a> › <a href="{sido_link}">{sido}</a> › {name}</div>
<h1>{name}</h1>
<p class="cp-loc">📍 {sido} {sigungu}{address_short}</p>

<div class="cp-tags">{tags_html}</div>

<div class="cp-info">
<h2>기본 정보</h2>
<table>
<tr><td>주소</td><td>{address_html}</td></tr>
<tr><td>유형</td><td>{induty}</td></tr>
<tr><td>입지</td><td>{lctCl}</td></tr>
<tr><td>운영 기간</td><td>{operation}</td></tr>
<tr><td>반려동물</td><td>{animalCmgCl}</td></tr>
<tr><td>연락처</td><td>{tel}</td></tr>
<tr><td>공식 사이트</td><td>{homepage_html}</td></tr>
</table>
</div>

{intro_section}

<div class="cp-info">
<h2>예약·확인 안내</h2>
<p>캠핑장 운영 상태·요금·시설·반려동물 동반 조건 등은 변동될 수 있습니다. <strong>예약 전 반드시 공식 사이트 또는 전화로 재확인</strong>하시기 바랍니다.</p>
<a class="cp-cta" href="https://gocamping.or.kr" target="_blank" rel="noopener">고캠핑 공식 확인 →</a>
{homepage_cta}
</div>

<div class="cp-notice">
<strong>안내:</strong> 본 페이지의 정보는 한국관광공사 고캠핑 공공 데이터를 기반으로 재구성한 민간 참고 정보입니다. 공식 예약·결제·시설 운영은 캠핑장 공식 채널을 이용하세요.
</div>

<div style="margin-top:28px">
<h3>관련 도구·가이드</h3>
<ul>
<li><a href="../tool-distance.html">서울·주요 도시 → 이 지역 거리·유류비 계산</a></li>
<li><a href="../tool-weather.html">캠핑 가능 여부 판정</a></li>
<li><a href="../tool-checklist.html">장비 체크리스트 생성</a></li>
<li><a href="{sido_link}">{sido} 캠핑 가이드 보기</a></li>
</ul>
</div>

</div>
</main>

<footer><div class="container">
<div class="footer-grid">
<div class="footer-brand"><a href="../index.html" class="logo">고고캠프</a><p>민간 캠핑 정보 참고 서비스.</p></div>
<div class="footer-col"><h4>캠핑장</h4><ul><li><a href="../campgrounds.html">전체 캠핑장</a></li><li><a href="../region-gangwon.html">강원도</a></li><li><a href="../region-jeju.html">제주도</a></li></ul></div>
<div class="footer-col"><h4>도구</h4><ul><li><a href="../tools.html">전체 도구</a></li><li><a href="../tool-budget.html">예산 계산기</a></li><li><a href="../tool-weather.html">캠핑 가능 판정</a></li></ul></div>
<div class="footer-col"><h4>사이트</h4><ul><li><a href="../about.html">소개</a></li><li><a href="../contact.html">문의</a></li><li><a href="../terms.html">이용약관</a></li><li><a href="../privacy.html">개인정보처리방침</a></li></ul></div>
</div>
<div class="footer-bottom"><p>© 2026 고고캠프.</p></div>
</div></footer>

<script src="../js/mobile-nav.js?v=2" defer></script>
</body>
</html>
"""

SIDO_LINK = {
    "서울특별시": "../region-gyeonggi.html",
    "경기도": "../region-gyeonggi.html",
    "인천광역시": "../region-gyeonggi.html",
    "강원도": "../region-gangwon.html",
    "강원특별자치도": "../region-gangwon.html",
    "충청북도": "../region-chungcheong.html",
    "충청남도": "../region-chungcheong.html",
    "대전광역시": "../region-chungcheong.html",
    "세종특별자치시": "../region-chungcheong.html",
    "전라북도": "../region-jeolla.html",
    "전북특별자치도": "../region-jeolla.html",
    "전라남도": "../region-jeolla.html",
    "광주광역시": "../region-jeolla.html",
    "경상북도": "../region-gyeongsang.html",
    "경상남도": "../region-gyeongsang.html",
    "대구광역시": "../region-gyeongsang.html",
    "부산광역시": "../region-gyeongsang.html",
    "울산광역시": "../region-gyeongsang.html",
    "제주특별자치도": "../region-jeju.html",
}


def slugify(s: str, cid: str) -> str:
    """캠핑장 이름 + content ID로 안전한 파일명 생성."""
    s = re.sub(r"[^\w가-힣]+", "-", s or "").strip("-")[:40]
    if not s:
        s = "camp"
    return f"{s}-{cid}"


def render_page(item: dict) -> str:
    name = item["name"] or "캠핑장"
    sido = item["sido"] or ""
    sigungu = item["sigungu"] or ""
    address = item["address"] or ""
    cid = item["contentId"]
    slug = slugify(name, cid)

    tags = []
    if item.get("induty"):
        for t in item["induty"].split(","):
            t = t.strip()
            if t:
                tags.append(t)
    if item.get("lctCl"):
        for t in item["lctCl"].split(","):
            t = t.strip()
            if t:
                tags.append(t)
    tags_html = "".join(f'<span class="cp-tag">{escape(t)}</span>' for t in tags[:6])

    homepage = item["homepage"] or ""
    homepage_html = (
        f'<a href="{escape(homepage)}" target="_blank" rel="noopener">{escape(homepage)}</a>'
        if homepage.startswith("http") else "—"
    )
    homepage_cta = (
        f'<a class="cp-cta sub" href="{escape(homepage)}" target="_blank" rel="noopener">공식 사이트 →</a>'
        if homepage.startswith("http") else ""
    )

    operation = "연중" if not item.get("hvofBgnde") else f"{item.get('hvofBgnde', '')}~{item.get('hvofEnddle', '')}"
    animal = item.get("animalCmgCl") or "정보 없음 (예약 시 확인)"
    tel = item.get("tel") or "정보 없음"

    intro_section = ""
    intro = item.get("intro") or ""
    if intro:
        intro_section = f'<div class="cp-info"><h2>소개</h2><p>{escape(intro)}</p></div>'

    address_short = f" · {escape(address.split(sigungu)[-1].strip())}" if address and sigungu and sigungu in address else ""
    address_html = escape(address) if address else "—"

    schema = json.dumps({
        "@context": "https://schema.org",
        "@type": "Campground",
        "name": name,
        "address": {
            "@type": "PostalAddress",
            "addressRegion": sido,
            "addressLocality": sigungu,
            "streetAddress": address,
            "addressCountry": "KR",
        },
        "telephone": tel if tel != "정보 없음" else "",
        "url": f"https://gogocamp.kr/camp/{slug}.html",
    }, ensure_ascii=False)

    html = TEMPLATE.format(
        name=escape(name),
        slug=slug,
        sido=escape(sido),
        sigungu=escape(sigungu),
        address_short=address_short,
        tags_html=tags_html,
        address_html=address_html,
        induty=escape(item.get("induty") or "—"),
        lctCl=escape(item.get("lctCl") or "—"),
        operation=escape(operation),
        animalCmgCl=escape(animal),
        tel=escape(tel),
        homepage_html=homepage_html,
        homepage_cta=homepage_cta,
        intro_section=intro_section,
        sido_link=SIDO_LINK.get(sido, "../campgrounds.html"),
        schema=schema,
    )
    return html, slug


def write_sitemap(slugs: list):
    xml = ['<?xml version="1.0" encoding="UTF-8"?>',
           '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']
    for s in slugs:
        xml.append(f'<url><loc>https://gogocamp.kr/camp/{s}.html</loc></url>')
    xml.append('</urlset>')
    SITEMAP.write_text("\n".join(xml), encoding="utf-8")


def write_index(items):
    """camp/index.html — 전체 캠핑장 디렉토리."""
    by_sido = {}
    for it in items:
        by_sido.setdefault(it["sido"] or "기타", []).append(it)

    sections = []
    for sido in sorted(by_sido):
        sec = [f'<h2>{escape(sido)} <span style="color:#9ca3af;font-size:0.85rem">({len(by_sido[sido])}개)</span></h2><ul style="columns:2;list-style:none;padding:0">']
        for it in sorted(by_sido[sido], key=lambda x: x["name"]):
            cid = it["contentId"]
            slug = slugify(it["name"], cid)
            sec.append(f'<li style="padding:4px 0"><a href="{slug}.html" style="color:#059669;text-decoration:none">▸ {escape(it["name"])}</a> <span style="color:#9ca3af;font-size:0.85rem">{escape(it["sigungu"])}</span></li>')
        sec.append('</ul>')
        sections.append("".join(sec))

    html = f"""<!DOCTYPE html>
<html lang="ko"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>전국 캠핑장 전체 목록 — 지역별 디렉토리 | 고고캠프</title>
<meta name="description" content="전국 캠핑장 {len(items)}개 지역별 전체 목록. 각 캠핑장 공식 정보·연락처·주소 요약.">
<link rel="canonical" href="https://gogocamp.kr/camp/">
<link rel="stylesheet" href="../css/style.css?v=3">
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700;800&display=swap" rel="stylesheet">
<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-8296789991007286" crossorigin="anonymous"></script>
</head><body>
<header><div class="container"><div class="header-inner"><a href="../index.html" class="logo">고고<span class="accent">캠프</span></a><nav><ul class="nav-menu"><li><a href="../index.html">홈</a></li><li><a href="../campgrounds.html" class="active">캠핑장 찾기</a></li><li><a href="../tools.html">도구</a></li><li><a href="../guide.html">가이드</a></li><li><a href="../tips.html">팁</a></li><li><a href="../about.html">소개</a></li></ul></nav></div></div></header>
<main><div style="max-width:960px;margin:0 auto;padding:32px 16px">
<h1>전국 캠핑장 디렉토리</h1>
<p>총 <strong>{len(items)}개</strong> 캠핑장. 지역별로 정리했습니다.</p>
{"".join(sections)}
</div></main>
<footer><div class="container"><p>© 2026 고고캠프.</p></div></footer>
<script src="../js/mobile-nav.js?v=2" defer></script>
</body></html>"""
    (OUT_DIR / "index.html").write_text(html, encoding="utf-8")


def main():
    if not DATA_FILE.exists():
        print(f"❌ {DATA_FILE} 없음. fetch-campgrounds.py 먼저 실행하세요.")
        return

    data = json.loads(DATA_FILE.read_text(encoding="utf-8"))
    items = data.get("items", [])
    OUT_DIR.mkdir(exist_ok=True)
    slugs = []
    for i, it in enumerate(items, 1):
        if not it.get("name"):
            continue
        html, slug = render_page(it)
        (OUT_DIR / f"{slug}.html").write_text(html, encoding="utf-8")
        slugs.append(slug)
        if i % 100 == 0:
            print(f"  {i}/{len(items)} 생성...")
    write_index(items)
    write_sitemap(slugs)
    print(f"\n✅ {len(slugs)}개 페이지 생성 완료")
    print(f"📁 {OUT_DIR}")
    print(f"🗺️ {SITEMAP}")


if __name__ == "__main__":
    main()
