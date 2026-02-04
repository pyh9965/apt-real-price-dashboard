@echo off
chcp 65001 >nul
cd /d "D:\ai_program\실거래가분석대시보드-api"

echo ========================================
echo   GitHub 저장소 생성 및 푸시
echo ========================================
echo.

echo 저장소 생성 중...
gh repo create apt-real-price-dashboard --public --source=. --remote=origin --push

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo   성공! 저장소가 생성되었습니다!
    echo ========================================
    echo.
    echo https://github.com/pyh9965/apt-real-price-dashboard
    echo.
    echo Streamlit Cloud 배포 페이지를 엽니다...
    start https://share.streamlit.io
) else (
    echo 실패. 다른 이름으로 시도...
    gh repo create apt-dashboard-2026 --public --source=. --remote=origin --push
    if %errorlevel% equ 0 (
        echo 성공!
        start https://share.streamlit.io
    )
)

pause
