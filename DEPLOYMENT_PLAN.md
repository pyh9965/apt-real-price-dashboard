# 실거래가 분석 대시보드 - Streamlit Cloud 배포 계획

## 1. 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 프로젝트명 | 아파트 실거래가 분석 대시보드 |
| 기술 스택 | Python 3.11+, Streamlit, Pandas, Plotly |
| 배포 플랫폼 | Streamlit Cloud (무료) |
| 데이터 소스 | 국토교통부 실거래가 API |

---

## 2. 배포 전 준비사항

### 2.1 필수 파일 확인

| 파일 | 상태 | 설명 |
|------|------|------|
| `app.py` | ✅ 존재 | 메인 Streamlit 애플리케이션 |
| `requirements.txt` | ✅ 존재 | Python 의존성 목록 |
| `api_client.py` | ✅ 존재 | API 클라이언트 모듈 |
| `region_codes.py` | ✅ 존재 | 지역 코드 데이터 |
| `.streamlit/config.toml` | ❌ 생성 필요 | Streamlit 설정 파일 |

### 2.2 생성해야 할 파일

#### `.streamlit/config.toml`
```toml
[theme]
primaryColor = "#1E88E5"
backgroundColor = "#FFFFFF"
secondaryBackgroundColor = "#F5F5F5"
textColor = "#262730"
font = "sans serif"

[server]
headless = true
port = 8501
enableCORS = false

[browser]
gatherUsageStats = false
```

#### `.gitignore` (수정 권장)
```gitignore
# 환경 변수
.env
.env.local

# Python
__pycache__/
*.py[cod]
*$py.class
.Python
venv/
.venv/

# IDE
.vscode/
.idea/

# 데이터 파일
*.xlsx
*.xls
*.csv

# 로그
*.log
```

---

## 3. 배포 단계

### Phase 1: GitHub 저장소 설정

**Step 1.1: 저장소 생성**
1. GitHub에서 새 저장소 생성
2. 저장소 이름: `apartment-price-dashboard` (권장)
3. 공개(Public) 설정 (Streamlit Cloud 무료 배포 조건)

**Step 1.2: 코드 업로드**
```bash
# Git 초기화 (이미 되어있다면 생략)
git init

# 원격 저장소 연결
git remote add origin https://github.com/{username}/apartment-price-dashboard.git

# 파일 추가 및 커밋
git add .
git commit -m "Initial commit: Apartment price dashboard"

# 푸시
git push -u origin main
```

**Step 1.3: 브랜치 전략**
```
main (production)
  └── develop (staging)
        └── feature/* (개발)
```

---

### Phase 2: Streamlit Cloud 배포

**Step 2.1: Streamlit Cloud 계정 설정**
1. https://share.streamlit.io 접속
2. GitHub 계정으로 로그인
3. 저장소 접근 권한 부여

**Step 2.2: 앱 배포**
1. "New app" 클릭
2. 설정:
   - Repository: `{username}/apartment-price-dashboard`
   - Branch: `main`
   - Main file path: `app.py`
   - App URL: `apartment-price-dashboard` (커스텀 가능)

**Step 2.3: 환경 변수 설정 (Secrets)**
Streamlit Cloud > App settings > Secrets에서 설정:

```toml
# secrets.toml 형식
API_SERVICE_KEY = "your-api-key-here"
```

앱 코드에서 접근 방법:
```python
import streamlit as st

# Streamlit Cloud에서 secrets 접근
api_key = st.secrets.get("API_SERVICE_KEY", os.getenv("API_SERVICE_KEY"))
```

---

### Phase 3: 코드 수정 사항

**Step 3.1: API 키 로딩 방식 변경**

`api_client.py` 수정:
```python
import streamlit as st

def get_api_key():
    """Streamlit Cloud와 로컬 환경 모두 지원하는 API 키 로딩"""
    # 1. Streamlit Secrets 확인 (Cloud 환경)
    try:
        return st.secrets["API_SERVICE_KEY"]
    except (KeyError, FileNotFoundError):
        pass

    # 2. 환경 변수 확인 (로컬 환경)
    key = os.getenv("API_SERVICE_KEY")
    if key:
        return key

    # 3. 키가 없으면 None 반환
    return None
```

**Step 3.2: requirements.txt 검증**
```txt
streamlit>=1.28.0
pandas>=2.0.0
plotly>=5.17.0
openpyxl>=3.1.0
requests>=2.31.0
python-dotenv>=1.0.0
```

---

## 4. 배포 체크리스트

### 배포 전
- [ ] GitHub 저장소 생성 및 코드 푸시
- [ ] `.streamlit/config.toml` 생성
- [ ] `.gitignore` 업데이트
- [ ] `requirements.txt` 버전 확인
- [ ] 민감 정보(API 키) 제거 확인
- [ ] 로컬 테스트 완료

### 배포 중
- [ ] Streamlit Cloud 앱 생성
- [ ] Secrets 설정 (API_SERVICE_KEY)
- [ ] 배포 로그 확인 (에러 없음)

### 배포 후
- [ ] 앱 URL 접속 테스트
- [ ] API 연결 테스트
- [ ] 데이터 조회 기능 테스트
- [ ] 차트 렌더링 확인
- [ ] 모바일 반응형 테스트

---

## 5. 예상 URL

배포 완료 시 앱 URL:
```
https://{app-name}.streamlit.app
```

예시:
```
https://apartment-price-dashboard.streamlit.app
```

---

## 6. 운영 및 유지보수

### 6.1 업데이트 방법
1. 로컬에서 코드 수정
2. `git commit` 및 `git push`
3. Streamlit Cloud가 자동으로 재배포

### 6.2 모니터링
- Streamlit Cloud 대시보드에서 앱 상태 확인
- 로그 확인: App settings > Logs

### 6.3 비용
| 플랜 | 가격 | 제한 |
|------|------|------|
| Free | $0/월 | 공개 앱, 1GB RAM |
| Teams | $250/월 | 비공개 앱, 더 많은 리소스 |

---

## 7. 보안 고려사항

### 7.1 API 키 보호
- ✅ Streamlit Secrets 사용 (암호화 저장)
- ❌ 코드에 직접 하드코딩 금지
- ❌ GitHub에 `.env` 파일 커밋 금지

### 7.2 데이터 보안
- 업로드된 Excel 파일은 세션 종료 시 자동 삭제
- 민감한 거래 정보는 서버에 저장되지 않음

---

## 8. 트러블슈팅

### 일반적인 문제 해결

| 문제 | 원인 | 해결 방법 |
|------|------|-----------|
| 배포 실패 | requirements.txt 오류 | 의존성 버전 확인 |
| API 연결 실패 | Secrets 미설정 | Secrets에 API_SERVICE_KEY 추가 |
| 메모리 초과 | 대용량 데이터 처리 | 데이터 청크 처리 구현 |
| 앱 느림 | 캐싱 미적용 | `@st.cache_data` 데코레이터 활용 |

---

## 9. 다음 단계

배포 완료 후 고려할 개선 사항:

1. **성능 최적화**
   - 데이터 캐싱 전략 강화
   - 지연 로딩(Lazy Loading) 구현

2. **기능 확장**
   - 사용자 인증 추가
   - 데이터 내보내기 기능
   - 알림 기능 (가격 변동 알림)

3. **모니터링**
   - Google Analytics 연동
   - 에러 추적 (Sentry)

---

## 10. 참고 자료

- [Streamlit Cloud 공식 문서](https://docs.streamlit.io/streamlit-community-cloud)
- [Streamlit Secrets 관리](https://docs.streamlit.io/streamlit-community-cloud/deploy-your-app/secrets-management)
- [국토교통부 실거래가 API](https://www.data.go.kr/data/15057511/openapi.do)

---

**문서 작성일**: 2026-02-03
**작성자**: MoAI
**버전**: 1.0.0
