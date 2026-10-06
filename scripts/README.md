# gogocamp 자동 생성 스크립트

이 폴더에는 전국 캠핑장 데이터를 공공 API에서 수집하고 개별 HTML 페이지를 자동 생성하는 Python 스크립트가 들어 있습니다.

## 준비

### 1. 공공데이터포털 API 키 발급
1. https://www.data.go.kr 접속·로그인 (회원가입 무료)
2. "**고캠핑 기본 정보**" 검색
3. **활용신청** 버튼 (즉시 승인·무료, 일 1,000회 쿼터)
4. 마이페이지 → 개발계정에서 **일반 인증키 (Encoding)** 복사

### 2. Python 환경
- Python 3.8 이상 (표준 라이브러리만 사용, 추가 설치 불필요)

## 실행 순서

### 1단계: 캠핑장 데이터 수집

`fetch-campgrounds.py` 상단에서 `SERVICE_KEY` 값을 발급받은 키로 교체:

```python
SERVICE_KEY = "본인의_실제_인증키_붙여넣기"
```

실행:
```bash
cd D:\gogocamp\scripts
python fetch-campgrounds.py
```

→ `../data/campgrounds.json` 생성 (약 2,000~3,000개 캠핑장)

### 2단계: HTML 페이지 자동 생성

```bash
python generate-pages.py
```

→ `../camp/<슬러그>.html` 각 캠핑장 페이지
→ `../camp/index.html` 전체 디렉토리
→ `../sitemap-camps.xml` 사이트맵

### 3단계: sitemap.xml 통합

`../sitemap.xml` 끝에 `../sitemap-camps.xml` 참조를 추가하거나,
sitemap index 방식으로 분리해도 됩니다.

### 4단계: 배포

```bash
cd D:\gogocamp
git add .
git commit -m "자동 생성 캠핑장 디렉토리 추가"
git push
```

Cloudflare Pages가 자동 재배포합니다.

## 주의

- **API 쿼터**: 일 1,000회. 2,000 캠핑장 수집에는 약 20 페이지 호출 (여유).
- **중복 실행**: 같은 캠핑장은 덮어쓰기됩니다. 안전.
- **삭제**: `../camp/` 폴더를 통째로 지우고 다시 생성 가능.

## 문제 해결

- `서비스키 미설정`: 1단계 재확인.
- `HTTP 403`: 승인 대기 (최대 1시간) 또는 쿼터 초과.
- `응답 구조 오류`: API 응답 포맷 변경 시 `normalize()` 함수 수정 필요.
- `페이지 생성 실패`: `../camp/` 폴더 쓰기 권한 확인.
