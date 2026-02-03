@echo off
chcp 65001 >nul
cd /d "D:\ai_program\실거래가분석대시보드-api"

echo.
echo ========================================
echo    자동 배포 스크립트 v3.0
echo ========================================
echo.

REM Step 1: GitHub CLI 확인
echo [1/6] GitHub CLI 확인...
gh --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [X] GitHub CLI가 없습니다!
    echo     https://cli.github.com 에서 설치하세요
    pause
    exit /b 1
)
echo [OK] GitHub CLI 설치됨
echo.

REM Step 2: GitHub 로그인 확인
echo [2/6] GitHub 로그인 확인...
gh auth status >nul 2>&1
if %errorlevel% neq 0 (
    echo GitHub 로그인이 필요합니다...
    gh auth login
)
echo [OK] GitHub 로그인됨
echo.

REM Step 3: .git 완전 삭제 (여러 방법 시도)
echo [3/6] 기존 Git 정보 삭제...
if exist ".git" (
    echo     .git 발견 - 삭제 중...
    attrib -h -s -r ".git" >nul 2>&1
    del /f /q ".git" >nul 2>&1
    rd /s /q ".git" >nul 2>&1
)
if exist ".git" (
    echo     재시도...
    rmdir /s /q ".git" >nul 2>&1
)
if exist ".git" (
    echo [X] .git 삭제 실패 - 수동 삭제 필요
    explorer .
    pause
    exit /b 1
)
echo [OK] Git 정보 삭제됨
echo.

REM Step 4: Git 초기화
echo [4/6] Git 저장소 초기화...
git init
if %errorlevel% neq 0 (
    echo [X] Git 초기화 실패
    pause
    exit /b 1
)
echo [OK] Git 초기화 완료
echo.

REM Step 5: 커밋
echo [5/6] 파일 커밋...
git add -A
git commit -m "feat: 아파트 실거래가 분석 대시보드 초기 커밋"
if %errorlevel% neq 0 (
    echo [!] 커밋 경고 (이미 커밋됨일 수 있음)
)
echo [OK] 커밋 완료
echo.

REM Step 6: GitHub 저장소 생성 및 푸시
echo [6/6] GitHub 저장소 생성 및 푸시...
echo.

REM 먼저 기존 remote 제거
git remote remove origin >nul 2>&1

REM 저장소 생성 시도
gh repo create apt-real-price-dashboard --public --source=. --remote=origin --push

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo    SUCCESS! 배포 준비 완료!
    echo ========================================
    echo.
    echo 저장소: https://github.com/pyh9965/apt-real-price-dashboard
    echo.
    echo Streamlit Cloud로 이동합니다...
    timeout /t 3
    start https://share.streamlit.io/deploy?repository=pyh9965/apt-real-price-dashboard
    echo.
    echo [다음 단계]
    echo  1. Repository: apt-real-price-dashboard 선택
    echo  2. Branch: main
    echo  3. Main file: app.py
    echo  4. Deploy 클릭!
) else (
    echo.
    echo [!] 저장소 생성 실패 - 이름 변경해서 재시도...
    set REPO_NAME=apt-dashboard-%random%
    gh repo create %REPO_NAME% --public --source=. --remote=origin --push
    if %errorlevel% equ 0 (
        echo.
        echo ========================================
        echo    SUCCESS! 배포 준비 완료!
        echo ========================================
        echo 저장소: %REPO_NAME%
        start https://share.streamlit.io
    ) else (
        echo.
        echo [X] 저장소 생성 최종 실패
        echo     gh auth logout 후 다시 로그인하세요
    )
)

echo.
echo ========================================
pause
