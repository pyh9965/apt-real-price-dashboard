@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ============================================
echo   원클릭 배포 스크립트
echo ============================================
echo.

:: GitHub CLI 확인
where gh >nul 2>&1
if %errorlevel% neq 0 (
    echo GitHub CLI 설치가 필요합니다.
    start https://github.com/cli/cli/releases/latest
    pause
    exit /b 1
)
echo [OK] GitHub CLI 확인됨

:: GitHub 로그인
gh auth status >nul 2>&1
if %errorlevel% neq 0 (
    echo GitHub 로그인 중...
    gh auth login -w
)
echo [OK] GitHub 로그인 완료
echo.

:: 깨진 .git 강제 삭제
echo 깨진 Git 참조 정리 중...
if exist ".git" (
    attrib -h -s -r ".git" 2>nul
    del /f /q ".git" 2>nul
    rmdir /s /q ".git" 2>nul
)
echo [OK] Git 정리 완료
echo.

:: Git 초기화
echo Git 저장소 초기화 중...
git init
if %errorlevel% neq 0 (
    echo [ERROR] Git 초기화 실패
    pause
    exit /b 1
)
echo [OK] Git 초기화 완료
echo.

:: 커밋
echo 파일 커밋 중...
git add .
git commit -m "Initial commit: 아파트 실거래가 분석 대시보드"
echo [OK] 커밋 완료
echo.

:: GitHub 저장소 생성 및 푸시
echo GitHub 저장소 생성 중...
gh repo create apartment-price-dashboard --public --source=. --remote=origin --push

if %errorlevel% equ 0 (
    echo.
    echo ============================================
    echo   배포 준비 완료!
    echo ============================================
    echo.
    start https://share.streamlit.io
    echo Streamlit Cloud에서 배포하세요:
    echo   1. New app 클릭
    echo   2. 저장소: apartment-price-dashboard
    echo   3. Main file: app.py
    echo   4. Deploy 클릭
) else (
    echo 저장소명 중복시 다른 이름으로 시도...
    set /a RAND=%random%
    gh repo create apt-dashboard-%RAND% --public --source=. --remote=origin --push
    if %errorlevel% equ 0 (
        echo.
        echo ============================================
        echo   배포 준비 완료! (저장소: apt-dashboard-%RAND%)
        echo ============================================
        start https://share.streamlit.io
    )
)

echo.
pause
