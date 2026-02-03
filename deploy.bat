@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo ============================================
echo   실거래가 분석 대시보드 - 자동 배포 스크립트
echo ============================================
echo.

:: GitHub CLI 확인
where gh >nul 2>&1
if %errorlevel% neq 0 (
    echo [오류] GitHub CLI가 설치되어 있지 않습니다.
    echo.
    echo GitHub CLI 설치 방법:
    echo   1. https://cli.github.com/ 에서 다운로드
    echo   2. 또는 PowerShell에서: winget install GitHub.cli
    echo.
    echo 설치 후 이 스크립트를 다시 실행하세요.
    pause
    exit /b 1
)

echo [1/6] GitHub CLI 확인 완료
echo.

:: GitHub 로그인 확인
gh auth status >nul 2>&1
if %errorlevel% neq 0 (
    echo [2/6] GitHub 로그인이 필요합니다...
    gh auth login
    if %errorlevel% neq 0 (
        echo [오류] GitHub 로그인에 실패했습니다.
        pause
        exit /b 1
    )
) else (
    echo [2/6] GitHub 로그인 확인 완료
)
echo.

:: Git 저장소 초기화
echo [3/6] Git 저장소 초기화 중...

:: 기존 .git 제거 (worktree 참조 파일인 경우)
if exist .git (
    del /f /q .git 2>nul
    rmdir /s /q .git 2>nul
)

git init
if %errorlevel% neq 0 (
    echo [오류] Git 초기화에 실패했습니다.
    pause
    exit /b 1
)
echo Git 저장소 초기화 완료
echo.

:: 파일 스테이징
echo [4/6] 파일 스테이징 중...
git add .
git commit -m "Initial commit: 아파트 실거래가 분석 대시보드"
echo.

:: GitHub 저장소 생성
echo [5/6] GitHub 저장소 생성 중...
set /p REPO_NAME="저장소 이름을 입력하세요 (기본: apartment-price-dashboard): "
if "!REPO_NAME!"=="" set REPO_NAME=apartment-price-dashboard

:: 공개/비공개 선택
set /p VISIBILITY="저장소 공개 여부 (public/private, 기본: public): "
if "!VISIBILITY!"=="" set VISIBILITY=public

gh repo create !REPO_NAME! --!VISIBILITY! --source=. --remote=origin --push
if %errorlevel% neq 0 (
    echo [오류] GitHub 저장소 생성에 실패했습니다.
    echo 저장소가 이미 존재하거나 권한 문제일 수 있습니다.
    pause
    exit /b 1
)
echo GitHub 저장소 생성 및 푸시 완료
echo.

:: 배포 안내
echo [6/6] 배포 안내
echo ============================================
echo.
echo GitHub 저장소가 성공적으로 생성되었습니다!
echo.
echo 다음 단계: Streamlit Cloud 배포
echo   1. https://share.streamlit.io 접속
echo   2. GitHub 계정으로 로그인
echo   3. "New app" 클릭
echo   4. 저장소 선택: !REPO_NAME!
echo   5. Main file path: app.py
echo   6. Deploy 클릭
echo.
echo Secrets 설정 (배포 후):
echo   1. App settings → Secrets
echo   2. 다음 내용 추가:
echo      API_SERVICE_KEY = "your-api-key"
echo.
echo ============================================

:: 브라우저로 Streamlit Cloud 열기
set /p OPEN_BROWSER="Streamlit Cloud 페이지를 열까요? (y/n): "
if /i "!OPEN_BROWSER!"=="y" (
    start https://share.streamlit.io
)

echo.
echo 배포 준비가 완료되었습니다!
pause
