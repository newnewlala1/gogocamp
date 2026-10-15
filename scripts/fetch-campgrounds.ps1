# 한국관광공사 고캠핑 API 데이터 수집 — 전체 필드 (비교 기능용)
# PS 5.1 UTF-8 버그 해결 포함

# 공공데이터포털에서 발급받은 서비스 키를 환경 변수 또는 로컬 파일에 저장하여 사용하세요
$SERVICE_KEY = $env:GOCAMPING_API_KEY
if (-not $SERVICE_KEY) {
    Write-Host "환경 변수 GOCAMPING_API_KEY를 설정하세요." -ForegroundColor Red
    Write-Host "예: `$env:GOCAMPING_API_KEY = '본인 키'" -ForegroundColor Yellow
    exit 1
}
$API_BASE = "https://apis.data.go.kr/B551011/GoCamping/basedList"
$OUT_DIR = Join-Path (Split-Path -Parent $PSScriptRoot) "data"
$OUT_FILE = Join-Path $OUT_DIR "campgrounds.json"
$PAGE_SIZE = 1000
$MAX_PAGES = 10

if (-not (Test-Path $OUT_DIR)) { New-Item -ItemType Directory -Path $OUT_DIR -Force | Out-Null }

function Get-JsonUtf8($url) {
    $resp = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec 60 -UserAgent "gogocamp-fetcher/1.0" -UseBasicParsing
    $bytes = $resp.RawContentStream.ToArray()
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    return $text | ConvertFrom-Json
}

$allItems = New-Object System.Collections.ArrayList
$totalCount = $null

for ($page = 1; $page -le $MAX_PAGES; $page++) {
    Write-Host "페이지 $page 요청 중..." -NoNewline
    $url = "$API_BASE`?serviceKey=$SERVICE_KEY&numOfRows=$PAGE_SIZE&pageNo=$page&MobileOS=ETC&MobileApp=gogocamp&_type=json"
    try {
        $resp = Get-JsonUtf8 $url
    } catch {
        Write-Host " 실패: $_" -ForegroundColor Red
        Start-Sleep -Seconds 2
        continue
    }

    if (-not $resp.response.body) {
        Write-Host " 응답 구조 오류" -ForegroundColor Red
        break
    }

    if ($null -eq $totalCount) {
        $totalCount = [int]$resp.response.body.totalCount
        Write-Host " 총 $totalCount 개 발견"
    } else {
        Write-Host ""
    }

    $items = $resp.response.body.items.item
    if (-not $items) { Write-Host "  더 이상 데이터 없음"; break }

    foreach ($it in $items) {
        [void]$allItems.Add([PSCustomObject]@{
            # 기본 정보
            contentId      = "$($it.contentId)"
            name           = "$($it.facltNm)".Trim()
            sido           = "$($it.doNm)"
            sigungu        = "$($it.sigunguNm)"
            address        = "$($it.addr1)"
            addrDetail     = "$($it.addr2)"
            zipcode        = "$($it.zipcode)"
            tel            = "$($it.tel)"
            homepage       = "$($it.homepage)"
            resveUrl       = "$($it.resveUrl)"
            # 소개
            lineIntro      = "$($it.lineIntro)".Trim()
            intro          = "$($it.intro)".Trim()
            # 분류·테마
            induty         = "$($it.induty)".Trim()
            lctCl          = "$($it.lctCl)".Trim()
            theme          = "$($it.themaEnvrnCl)".Trim()
            features       = "$($it.featureNm)".Trim()
            tourEraCl      = "$($it.tourEraCl)".Trim()
            # 운영
            manageSttus    = "$($it.manageSttus)"
            hvofBgnde      = "$($it.hvofBgnde)"
            hvofEnddle     = "$($it.hvofEnddle)"
            operPdCl       = "$($it.operPdCl)".Trim()
            operDeCl       = "$($it.operDeCl)".Trim()
            trlerAcmpnyAt  = "$($it.trlerAcmpnyAt)"
            caravAcmpnyAt  = "$($it.caravAcmpnyAt)"
            # 사이트 수·규모
            gnrlSiteCo     = "$($it.gnrlSiteCo)"
            autoSiteCo     = "$($it.autoSiteCo)"
            glampSiteCo    = "$($it.glampSiteCo)"
            caravSiteCo    = "$($it.caravSiteCo)"
            indvdlCaravSiteCo = "$($it.indvdlCaravSiteCo)"
            # 사이트 바닥
            sitedStnc      = "$($it.sitedStnc)"
            siteMg1Width   = "$($it.siteMg1Width)"
            siteMg1Vrticl  = "$($it.siteMg1Vrticl)"
            siteMg2Width   = "$($it.siteMg2Width)"
            siteMg2Vrticl  = "$($it.siteMg2Vrticl)"
            siteMg3Width   = "$($it.siteMg3Width)"
            siteMg3Vrticl  = "$($it.siteMg3Vrticl)"
            siteBottomCl1  = "$($it.siteBottomCl1)"
            siteBottomCl2  = "$($it.siteBottomCl2)"
            siteBottomCl3  = "$($it.siteBottomCl3)"
            siteBottomCl4  = "$($it.siteBottomCl4)"
            siteBottomCl5  = "$($it.siteBottomCl5)"
            # 시설
            toiletCo       = "$($it.toiletCo)"
            swrmCo         = "$($it.swrmCo)"
            wtrplCo        = "$($it.wtrplCo)"
            brazierCl      = "$($it.brazierCl)".Trim()
            sbrsCl         = "$($it.sbrsCl)".Trim()
            sbrsEtc        = "$($it.sbrsEtc)".Trim()
            # 체험
            exprnProgrm    = "$($it.exprnProgrm)".Trim()
            clturEventAt   = "$($it.clturEventAt)"
            clturEvent     = "$($it.clturEvent)".Trim()
            # 주변·대여
            posblFcltyCl   = "$($it.posblFcltyCl)".Trim()
            posblFcltyEtc  = "$($it.posblFcltyEtc)".Trim()
            eqpmnLendCl    = "$($it.eqpmnLendCl)".Trim()
            # 반려동물·동반
            animalCmgCl    = "$($it.animalCmgCl)".Trim()
            extshrAcmpnyAt = "$($it.extshrAcmpnyAt)"
            # 안전·주의
            tooltip        = "$($it.tooltip)".Trim()
            # 좌표·이미지
            mapX           = "$($it.mapX)"
            mapY           = "$($it.mapY)"
            direction      = "$($it.direction)".Trim()
            firstImageUrl  = "$($it.firstImageUrl)"
            # 메타
            createdtime    = "$($it.createdtime)"
            modifiedtime   = "$($it.modifiedtime)"
        })
    }

    if ($totalCount -and $allItems.Count -ge $totalCount) { break }
    Start-Sleep -Milliseconds 300
}

Write-Host ""
Write-Host "✅ 총 $($allItems.Count) 개 수집 완료" -ForegroundColor Green

$out = [PSCustomObject]@{ total = $allItems.Count; updated = (Get-Date -Format "yyyy-MM-dd"); items = @($allItems) }
$jsonText = $out | ConvertTo-Json -Depth 5
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($OUT_FILE, $jsonText, $utf8NoBom)
Write-Host "💾 저장: $OUT_FILE" -ForegroundColor Cyan
