# 한국관광공사 고캠핑 API 데이터 수집 (PowerShell)
# PS 5.1 UTF-8 디코딩 문제 해결: Invoke-WebRequest + 바이트 수동 디코드
# 사용법: powershell -ExecutionPolicy Bypass -File fetch-campgrounds.ps1

$SERVICE_KEY = "55e2fcb7b492a3d791a8730247bd535e0aedcf84996d49ae9f883dbad0aeb375"
$API_BASE = "https://apis.data.go.kr/B551011/GoCamping/basedList"
$OUT_DIR = Join-Path (Split-Path -Parent $PSScriptRoot) "data"
$OUT_FILE = Join-Path $OUT_DIR "campgrounds.json"
$PAGE_SIZE = 1000
$MAX_PAGES = 10

if (-not (Test-Path $OUT_DIR)) { New-Item -ItemType Directory -Path $OUT_DIR -Force | Out-Null }

function Get-JsonUtf8($url) {
    # PS 5.1: Invoke-WebRequest.Content은 Latin-1로 해석됨 → RawContentStream에서 바이트 직접 읽어 UTF-8 디코드
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
            contentId      = "$($it.contentId)"
            name           = "$($it.facltNm)".Trim()
            sido           = "$($it.doNm)"
            sigungu        = "$($it.sigunguNm)"
            address        = "$($it.addr1)"
            intro          = "$($it.intro)".Trim()
            features       = "$($it.featureNm)".Trim()
            theme          = "$($it.themaEnvrnCl)".Trim()
            induty         = "$($it.induty)".Trim()
            lctCl          = "$($it.lctCl)".Trim()
            hvofBgnde      = "$($it.hvofBgnde)"
            hvofEnddle     = "$($it.hvofEnddle)"
            animalCmgCl    = "$($it.animalCmgCl)".Trim()
            tooltip        = "$($it.tooltip)".Trim()
            tel            = "$($it.tel)"
            homepage       = "$($it.homepage)"
            mapX           = "$($it.mapX)"
            mapY           = "$($it.mapY)"
            firstImageUrl  = "$($it.firstImageUrl)"
        })
    }

    if ($totalCount -and $allItems.Count -ge $totalCount) { break }
    Start-Sleep -Milliseconds 300
}

Write-Host ""
Write-Host "✅ 총 $($allItems.Count) 개 수집 완료" -ForegroundColor Green

$out = [PSCustomObject]@{ total = $allItems.Count; items = @($allItems) }
$jsonText = $out | ConvertTo-Json -Depth 5
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($OUT_FILE, $jsonText, $utf8NoBom)
Write-Host "💾 저장: $OUT_FILE" -ForegroundColor Cyan
