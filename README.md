# 아파트 실거래가 분석 대시보드

국토교통부 공공 API를 활용하여 **아파트 실거래가 데이터를 시각화**하는 웹 대시보드입니다.
Streamlit으로 만들어져 브라우저에서 바로 사용할 수 있습니다.

---

## 주요 기능

- 서울 및 경기도 지역별 아파트 실거래가 조회
- 거래 금액 시계열 차트 (월별 추이)
- 면적별, 단지별 가격 비교
- 금액 표시 한글화 (억원 단위 자동 변환)
- 엑셀 호환 데이터 다운로드

---

## 설치 방법

**필요 환경:** Python 3.8 이상

```bash
# 1. 저장소 다운로드
git clone https://github.com/pyh9965/apt-real-price-dashboard.git
cd apt-real-price-dashboard

# 2. 필요한 라이브러리 설치
pip install -r requirements.txt
```

### 필요 라이브러리

| 라이브러리 | 용도 |
|------------|------|
| streamlit | 웹 대시보드 프레임워크 |
| pandas | 데이터 처리 |
| plotly | 인터랙티브 차트 |
| openpyxl | 엑셀 파일 처리 |
| requests | API 호출 |
| python-dotenv | 환경변수 관리 |

---

## API 키 발급 방법

국토교통부 실거래가 API를 사용하려면 공공데이터포털에서 API 키를 발급받아야 합니다.

1. [공공데이터포털](https://www.data.go.kr) 회원가입 및 로그인
2. **"아파트매매 실거래 상세 자료"** 검색
3. **활용 신청** 클릭 후 API 키 발급 (즉시 발급)
4. 발급받은 키를 아래 방법으로 설정

---

## API 키 설정

```bash
# secrets.toml 파일 생성
cp .streamlit/secrets.toml.example .streamlit/secrets.toml
```

`.streamlit/secrets.toml` 파일을 열어 API 키를 입력합니다:

```toml
[api]
key = "여기에_발급받은_API_키_입력"
```

또는 `.env` 파일로도 설정 가능합니다:

```bash
API_KEY=여기에_발급받은_API_키_입력
```

---

## 실행 방법

### Windows

```bash
# 방법 1: bat 파일 더블클릭
간단실행.bat

# 방법 2: 명령 프롬프트에서 실행
streamlit run app.py
```

### Mac / Linux

```bash
streamlit run app.py
```

실행 후 브라우저에서 자동으로 `http://localhost:8501` 이 열립니다.

---

## 사용 방법

1. 왼쪽 사이드바에서 **지역** (시/군/구)을 선택합니다.
2. 조회할 **기간** (년/월)을 설정합니다.
3. 원하는 **아파트 단지**를 선택합니다.
4. 차트와 표에서 실거래가 정보를 확인합니다.
5. **데이터 다운로드** 버튼으로 엑셀 파일을 저장합니다.

---

## 프로젝트 구조

```
apt-real-price-dashboard/
├── app.py                  # 메인 대시보드 (Streamlit)
├── api_client.py           # 국토부 API 클라이언트
├── region_codes.py         # 서울/경기 지역 코드 목록
├── requirements.txt        # 필요 라이브러리 목록
├── .streamlit/
│   ├── config.toml         # Streamlit 설정
│   └── secrets.toml.example # API 키 설정 예시
├── 간단실행.bat             # Windows 간편 실행
└── start_streamlit.py      # Python으로 직접 실행
```

---

## 지원 지역

| 지역 | 상세 |
|------|------|
| 서울 | 25개 자치구 전체 |
| 경기 | 주요 시/군 |

---

## 주의 사항

- 공공데이터포털 API는 1일 요청 횟수 제한이 있습니다 (기본 1,000건/일).
- API 키는 외부에 노출되지 않도록 `.gitignore`에 포함되어 있습니다.
- 인터넷 연결이 필요합니다.
