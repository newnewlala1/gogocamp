# 캠핑장 JSON → 개별 HTML 페이지 자동 생성 (확장 필드·비교함 담기 포함)

$ROOT = Split-Path -Parent $PSScriptRoot
$DATA_FILE = Join-Path $ROOT "data\campgrounds.json"
$OUT_DIR = Join-Path $ROOT "camp"
$SITEMAP = Join-Path $ROOT "sitemap-camps.xml"

if (-not (Test-Path $DATA_FILE)) {
    Write-Host "❌ $DATA_FILE 없음." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $OUT_DIR)) { New-Item -ItemType Directory -Path $OUT_DIR -Force | Out-Null }

$sidoLink = @{
    "서울특별시"       = "../region-gyeonggi.html"
    "경기도"           = "../region-gyeonggi.html"
    "인천광역시"       = "../region-gyeonggi.html"
    "강원도"           = "../region-gangwon.html"
    "강원특별자치도"   = "../region-gangwon.html"
    "충청북도"         = "../region-chungcheong.html"
    "충청남도"         = "../region-chungcheong.html"
    "대전광역시"       = "../region-chungcheong.html"
    "세종특별자치시"   = "../region-chungcheong.html"
    "전라북도"         = "../region-jeolla.html"
    "전북특별자치도"   = "../region-jeolla.html"
    "전라남도"         = "../region-jeolla.html"
    "광주광역시"       = "../region-jeolla.html"
    "경상북도"         = "../region-gyeongsang.html"
    "경상남도"         = "../region-gyeongsang.html"
    "대구광역시"       = "../region-gyeongsang.html"
    "부산광역시"       = "../region-gyeongsang.html"
    "울산광역시"       = "../region-gyeongsang.html"
    "제주특별자치도"   = "../region-jeju.html"
}

function Get-Slug($name, $cid) { return "camp-$cid" }
Add-Type -AssemblyName System.Web
function Enc($s) { if (-not $s) { return "" }; return [System.Web.HttpUtility]::HtmlEncode([string]$s) }
function JsEsc($s) { return ("$s" -replace "'", "\'" -replace '"', '\"') }

function Row-Num($label, $v) {
    $n = 0
    if ([int]::TryParse($v, [ref]$n) -and $n -gt 0) {
        return "<tr><td>$label</td><td>$n 개</td></tr>"
    }
    return ""
}
function Row-YN($label, $v) {
    if ($v -eq 'Y') { return "<tr><td>$label</td><td>✓ 가능</td></tr>" }
    if ($v -eq 'N') { return "<tr><td>$label</td><td>✗ 불가</td></tr>" }
    return ""
}
function Row-Text($label, $v) {
    if ($v) { return "<tr><td>$label</td><td>$(Enc $v)</td></tr>" }
    return ""
}

$json = Get-Content $DATA_FILE -Raw -Encoding UTF8 | ConvertFrom-Json
$items = $json.items
$updateDate = if ($json.updated) { $json.updated } else { Get-Date -Format "yyyy-MM-dd" }
Write-Host "📂 $($items.Count)개 캠핑장 로드 (데이터 기준일: $updateDate)"

$slugs = @()
$i = 0
foreach ($it in $items) {
    $i++
    if (-not $it.name) { continue }
    $cid = $it.contentId
    $slug = "camp-$cid"
    $name = Enc $it.name
    $nameJs = JsEsc $it.name
    $sido = Enc $it.sido
    $sidoJs = JsEsc $it.sido
    $sigungu = Enc $it.sigungu
    $sigunguJs = JsEsc $it.sigungu
    $address = if ($it.address) { Enc $it.address } else { "—" }

    $tagsArr = @()
    if ($it.induty) { $it.induty -split ',' | ForEach-Object { if ($_.Trim()) { $tagsArr += $_.Trim() } } }
    if ($it.lctCl) { $it.lctCl -split ',' | ForEach-Object { if ($_.Trim()) { $tagsArr += $_.Trim() } } }
    if ($it.animalCmgCl -and $it.animalCmgCl.IndexOf('가능') -ge 0) { $tagsArr += "반려동물" }
    $tagsHtml = ($tagsArr | Select-Object -First 6 | ForEach-Object { "<span class=`"cp-tag`">$(Enc $_)</span>" }) -join ""

    $homepage = $it.homepage
    $homepageHtml = "—"
    $homepageCta = ""
    if ($homepage -and $homepage.StartsWith("http")) {
        $hpEnc = Enc $homepage
        $homepageHtml = "<a href=`"$hpEnc`" target=`"_blank`" rel=`"noopener`">$hpEnc</a>"
        $homepageCta = "<a class=`"cp-cta sub`" href=`"$hpEnc`" target=`"_blank`" rel=`"noopener`">공식 사이트 →</a>"
    }

    $operation = if ($it.hvofBgnde) { "$($it.hvofBgnde)~$($it.hvofEnddle)" } else { "연중 (혹은 미표기)" }
    $animal = if ($it.animalCmgCl) { Enc $it.animalCmgCl } else { "정보 없음 (예약 시 확인)" }
    $tel = if ($it.tel) { Enc $it.tel } else { "정보 없음" }
    $induty = if ($it.induty) { Enc $it.induty } else { "—" }
    $lctCl = if ($it.lctCl) { Enc $it.lctCl } else { "—" }

    $introSection = ""
    if ($it.lineIntro -or $it.intro) {
        $introText = if ($it.lineIntro) { Enc $it.lineIntro } else { Enc $it.intro }
        $introSection = "<div class=`"cp-info`"><h2>소개</h2><p>$introText</p></div>"
    }

    $sitesRows = ""
    $sitesRows += Row-Num "일반 야영 사이트" $it.gnrlSiteCo
    $sitesRows += Row-Num "오토 사이트" $it.autoSiteCo
    $sitesRows += Row-Num "글램핑" $it.glampSiteCo
    $sitesRows += Row-Num "카라반" $it.caravSiteCo
    $sitesRows += Row-Num "개인 카라반 사이트" $it.indvdlCaravSiteCo
    $sitesSection = ""
    if ($sitesRows) {
        $sitesSection = "<div class=`"cp-info`"><h2>사이트 규모</h2><table>$sitesRows</table></div>"
    }

    $facRows = ""
    $facRows += Row-Num "화장실 수" $it.toiletCo
    $facRows += Row-Num "샤워실 수" $it.swrmCo
    $facRows += Row-Num "개수대 수" $it.wtrplCo
    $facRows += Row-Text "부대시설" $it.sbrsCl
    $facRows += Row-Text "대여 장비" $it.eqpmnLendCl
    $facRows += Row-Text "화로·모닥불" $it.brazierCl
    $facSection = ""
    if ($facRows) {
        $facSection = "<div class=`"cp-info`"><h2>편의 시설</h2><table>$facRows</table></div>"
    }

    $allowRows = ""
    $allowRows += Row-YN "카라반 동반" $it.caravAcmpnyAt
    $allowRows += Row-YN "외부 텐트 반입" $it.extshrAcmpnyAt
    $allowRows += Row-YN "트레일러 동반" $it.trlerAcmpnyAt
    $allowSection = ""
    if ($allowRows) {
        $allowSection = "<div class=`"cp-info`"><h2>동반·허용 조건</h2><table>$allowRows</table></div>"
    }

    $activityRows = ""
    $activityRows += Row-Text "체험 프로그램" $it.exprnProgrm
    $activityRows += Row-Text "문화 행사" $it.clturEvent
    $activityRows += Row-Text "관광 테마" $it.tourEraCl
    $activityRows += Row-Text "주변 이용 시설" $it.posblFcltyCl
    $activitySection = ""
    if ($activityRows) {
        $activitySection = "<div class=`"cp-info`"><h2>활동·주변</h2><table>$activityRows</table></div>"
    }

    $sidoLinkUrl = if ($sidoLink.ContainsKey($it.sido)) { $sidoLink[$it.sido] } else { "../campgrounds.html" }

    $schema = @{
        "@context" = "https://schema.org"
        "@type" = "Campground"
        name = $it.name
        address = @{
            "@type" = "PostalAddress"
            addressRegion = $it.sido
            addressLocality = $it.sigungu
            streetAddress = $it.address
            addressCountry = "KR"
        }
        telephone = if ($it.tel) { $it.tel } else { "" }
        url = "https://gogocamp.kr/camp/$slug.html"
    } | ConvertTo-Json -Compress -Depth 4

    $html = @"
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>$name — $sigungu 캠핑장 정보·시설·사이트 수 | 고고캠프</title>
<meta name="description" content="$name ($sigungu) 공공 데이터 기반 캠핑장 상세 — 사이트 수, 화장실·샤워실, 반려동물 동반, 체험 프로그램, 공식 홈페이지 요약.">
<link rel="canonical" href="https://gogocamp.kr/camp/$slug.html">
<link rel="stylesheet" href="../css/style.css?v=3">
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700;800&display=swap" rel="stylesheet">
<script type="application/ld+json">$schema</script>
<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-8296789991007286" crossorigin="anonymous"></script>
<style>
.cp-wrap{max-width:720px;margin:0 auto;padding:24px 16px}
.cp-wrap h1{font-size:1.6rem;margin:0 0 4px}
.cp-wrap .cp-loc{color:#6b7280;margin:0 0 20px;font-size:0.95rem}
.cp-info{background:#fff;border:1px solid #e5e7eb;border-radius:12px;padding:20px;margin-bottom:16px}
.cp-info h2{margin:0 0 12px;font-size:1.1rem;color:#065f46}
.cp-info table{width:100%;border-collapse:collapse}
.cp-info td{padding:8px 4px;border-bottom:1px solid #f3f4f6;font-size:0.95rem;vertical-align:top}
.cp-info td:first-child{color:#6b7280;width:140px;font-weight:600}
.cp-tags{margin:12px 0}
.cp-tag{display:inline-block;padding:4px 10px;background:#f0fdf4;color:#059669;border-radius:12px;font-size:0.8rem;margin-right:4px;margin-bottom:4px}
.cp-notice{background:#fffbeb;border:1px solid #fde68a;border-radius:8px;padding:12px;margin:16px 0;font-size:0.88rem;color:#78350f}
.cp-cta{display:inline-block;padding:10px 20px;background:#059669;color:#fff;border-radius:8px;text-decoration:none;font-weight:700;margin-top:8px;margin-right:8px}
.cp-cta:hover{background:#047857}
.cp-cta.sub{background:#fff;color:#059669;border:1px solid #059669}
.breadcrumb-cp{color:#6b7280;font-size:0.85rem;margin-bottom:16px}
.breadcrumb-cp a{color:#059669;text-decoration:none}
.cmp-add-btn{display:inline-flex;align-items:center;gap:6px;padding:12px 20px;background:#059669;color:#fff;border:0;border-radius:8px;font-size:0.95rem;font-weight:700;cursor:pointer;margin:4px 0}
.cmp-add-btn:hover{background:#047857}
.data-note{font-size:0.8rem;color:#9ca3af;text-align:center;margin-top:8px}
</style>
</head>
<body>

<header><div class="container"><div class="header-inner"><a href="../index.html" class="logo">고고<span class="accent">캠프</span></a><nav><ul class="nav-menu"><li><a href="../index.html">홈</a></li><li><a href="../campgrounds.html" class="active">캠핑장 찾기</a></li><li><a href="../map.html">지도</a></li><li><a href="../compare.html">비교</a></li><li><a href="../tools.html">도구</a></li><li><a href="../guide.html">가이드</a></li><li><a href="../about.html">소개</a></li></ul></nav></div></div></header>

<main>
<div class="cp-wrap">
<div class="breadcrumb-cp"><a href="../index.html">홈</a> › <a href="../campgrounds.html">캠핑장 찾기</a> › <a href="$sidoLinkUrl">$sido</a> › $name</div>
<h1>$name</h1>
<p class="cp-loc">📍 $sido $sigungu</p>

<div class="cp-tags">$tagsHtml</div>

<div style="text-align:center;margin:16px 0">
<button id="cmpAddBtn" class="cmp-add-btn" data-cid="$cid" data-name="$nameJs" data-sido="$sidoJs" data-sigungu="$sigunguJs">📋 비교함 담기</button>
<div class="data-note">최대 3곳 비교 가능 · 선택은 브라우저에 저장됩니다</div>
</div>

<div class="cp-info">
<h2>기본 정보</h2>
<table>
<tr><td>주소</td><td>$address</td></tr>
<tr><td>유형</td><td>$induty</td></tr>
<tr><td>입지</td><td>$lctCl</td></tr>
<tr><td>운영 기간</td><td>$operation</td></tr>
<tr><td>반려동물</td><td>$animal</td></tr>
<tr><td>연락처</td><td>$tel</td></tr>
<tr><td>공식 사이트</td><td>$homepageHtml</td></tr>
</table>
</div>

$sitesSection
$facSection
$allowSection
$activitySection
$introSection

<div class="cp-info">
<h2>예약·확인 안내</h2>
<p>캠핑장 운영 상태·요금·시설·반려동물 동반 조건 등은 변동될 수 있습니다. <strong>예약 전 반드시 공식 사이트 또는 전화로 재확인</strong>하시기 바랍니다.</p>
<a class="cp-cta" href="https://gocamping.or.kr" target="_blank" rel="noopener">고캠핑 공식 확인 →</a>
$homepageCta
</div>

<div class="cp-notice">
<strong>데이터 안내:</strong> 본 페이지의 정보는 한국관광공사 고캠핑 공공 데이터 ($updateDate 기준)를 기반으로 재구성한 민간 참고 정보입니다. 공식 예약·결제·시설 운영은 캠핑장 공식 채널을 이용하세요.
</div>

<div style="margin-top:28px">
<h3>관련 도구·가이드</h3>
<ul>
<li><a href="../compare.html">이 캠핑장 비교하기</a></li>
<li><a href="../map.html">지도에서 보기</a></li>
<li><a href="../tool-distance.html">거리·유류비 계산</a></li>
<li><a href="../tool-weather.html">캠핑 가능 여부 판정</a></li>
<li><a href="../tool-checklist.html">장비 체크리스트 생성</a></li>
<li><a href="$sidoLinkUrl">$sido 캠핑 가이드 보기</a></li>
</ul>
</div>

</div>
</main>

<script src="../js/compare.js?v=1" defer></script>
<script src="../js/mobile-nav.js?v=2" defer></script>

<footer><div class="container">
<div class="footer-grid">
<div class="footer-brand"><a href="../index.html" class="logo">고고캠프</a><p>민간 캠핑 정보 참고 서비스.</p></div>
<div class="footer-col"><h4>캠핑장</h4><ul><li><a href="../campgrounds.html">전체 캠핑장</a></li><li><a href="../map.html">지도</a></li><li><a href="../compare.html">비교</a></li></ul></div>
<div class="footer-col"><h4>도구</h4><ul><li><a href="../tools.html">전체 도구</a></li><li><a href="../tool-budget.html">예산 계산기</a></li><li><a href="../tool-weather.html">캠핑 가능 판정</a></li></ul></div>
<div class="footer-col"><h4>사이트</h4><ul><li><a href="../about.html">소개</a></li><li><a href="../contact.html">문의</a></li><li><a href="../terms.html">이용약관</a></li><li><a href="../privacy.html">개인정보처리방침</a></li></ul></div>
</div>
<div class="footer-bottom"><p>© 2026 고고캠프.</p></div>
</div></footer>

</body>
</html>
"@
    $outPath = Join-Path $OUT_DIR "$slug.html"
    [System.IO.File]::WriteAllText($outPath, $html, [System.Text.Encoding]::UTF8)
    $slugs += $slug
    if ($i % 500 -eq 0) { Write-Host "  $i / $($items.Count) 생성..." }
}

Write-Host "✅ $($slugs.Count)개 페이지 생성 완료" -ForegroundColor Green

# 지역별 index 페이지 — 체크박스 포함
$bySido = $items | Group-Object -Property sido
$sectionsHtml = ""
foreach ($g in $bySido | Sort-Object Name) {
    $sidoName = if ($g.Name) { Enc $g.Name } else { "기타" }
    $sectionsHtml += "<h2 style=`"margin-top:28px`">$sidoName <span style=`"color:#9ca3af;font-size:0.85rem;font-weight:400`">($($g.Count)개)</span></h2>"
    $sectionsHtml += "<ul style=`"columns:2;list-style:none;padding:0;column-gap:24px`">"
    foreach ($it in ($g.Group | Sort-Object name)) {
        if (-not $it.name) { continue }
        $slug = "camp-$($it.contentId)"
        $sectionsHtml += "<li style=`"padding:4px 0;break-inside:avoid`"><a href=`"$slug.html`" style=`"color:#059669;text-decoration:none`">▸ $(Enc $it.name)</a> <span style=`"color:#9ca3af;font-size:0.85rem`">$(Enc $it.sigungu)</span></li>"
    }
    $sectionsHtml += "</ul>"
}

$indexHtml = @"
<!DOCTYPE html>
<html lang="ko"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>전국 캠핑장 전체 목록 $($items.Count)개 — 지역별 디렉토리 | 고고캠프</title>
<meta name="description" content="전국 캠핑장 $($items.Count)개 지역별 전체 목록. 공공 데이터 기반 공식 캠핑장 디렉토리.">
<link rel="canonical" href="https://gogocamp.kr/camp/">
<link rel="stylesheet" href="../css/style.css?v=3">
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700;800&display=swap" rel="stylesheet">
<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-8296789991007286" crossorigin="anonymous"></script>
</head><body>
<header><div class="container"><div class="header-inner"><a href="../index.html" class="logo">고고<span class="accent">캠프</span></a><nav><ul class="nav-menu"><li><a href="../index.html">홈</a></li><li><a href="../campgrounds.html" class="active">캠핑장 찾기</a></li><li><a href="../map.html">지도</a></li><li><a href="../compare.html">비교</a></li><li><a href="../tools.html">도구</a></li><li><a href="../guide.html">가이드</a></li><li><a href="../about.html">소개</a></li></ul></nav></div></div></header>
<main><div style="max-width:960px;margin:0 auto;padding:32px 16px">
<h1>전국 캠핑장 디렉토리</h1>
<p>총 <strong>$($items.Count)개</strong> 캠핑장. 지역별로 정리했습니다. 각 캠핑장 페이지에서 비교함에 담은 뒤 <a href="../compare.html" style="color:#059669">비교 페이지</a>에서 조건을 한 눈에 보세요.</p>
<div style="background:#f0fdf4;border-radius:8px;padding:16px;margin:20px 0">
<strong>🗺️ <a href="../map.html" style="color:#059669">지도에서 캠핑장 보기</a></strong> ·
<strong>📋 <a href="../compare.html" style="color:#059669">비교하기 (0)</a></strong>
</div>
$sectionsHtml
</div></main>
<script src="../js/compare.js?v=1" defer></script>
<footer><div class="container"><p>© 2026 고고캠프.</p></div></footer>
</body></html>
"@
[System.IO.File]::WriteAllText((Join-Path $OUT_DIR "index.html"), $indexHtml, [System.Text.Encoding]::UTF8)

# sitemap
$xml = @('<?xml version="1.0" encoding="UTF-8"?>', '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
foreach ($s in $slugs) { $xml += "<url><loc>https://gogocamp.kr/camp/$s.html</loc></url>" }
$xml += '</urlset>'
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($SITEMAP, ($xml -join "`n"), $utf8NoBom)

Write-Host "📁 $OUT_DIR" -ForegroundColor Cyan
Write-Host "🗺️  $SITEMAP" -ForegroundColor Cyan
