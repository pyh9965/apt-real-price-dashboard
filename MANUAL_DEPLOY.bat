@echo off
chcp 65001 >nul
cd /d "D:\ai_program\실거래가분석대시보드-api"

echo ============================================
echo   수동 배포 스크립트
echo ============================================
echo.

echo [1/5] .git 파일 삭제 중...
attrib -h -s -r ".git" 2>nul
del /f /q ".git" 2>nul
rmdir /s /q ".git" 2>nul
echo 완료
echo.

echo [2/5] Git 초기화 중...
git init
echo.

echo [3/5] 파일 추가 및 커밋 중...
git add -A
git commit -m "Initial commit: 아파트 실거래가 분석 대시보드"
echo.

echo [4/5] GitHub 저장소 생성 중...
echo 저장소 이름: apartment-price-dashboard-v2
gh repo create apartment-price-dashboard-v2 --public --source=. --remote=origin --push
echo.

if %errorlevel% neq 0 (
    echo.
    echo [오류] 저장소 생성 실패. 수동으로 생성합니다...
    echo.
    echo 브라우저에서 GitHub 저장소를 생성하세요:
    start https://github.com/new
    echo.
    echo 저장소 생성 후 아래 명령어를 실행하세요:
    echo   git remote add origin https://github.com/pyh9965/apartment-price-dashboard-v2.git
    echo   git branch -M main
    echo   git push -u origin main
    echo.
) else (
    echo [5/5] 배포 준비 완료!
    echo.
    echo Streamlit Cloud 페이지를 엽니다...
    start https://share.streamlit.io
)

echo.
pause
