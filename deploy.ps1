# 실거래가 분석 대시보드 - PowerShell 배포 스크립트
# 실행: powershell -ExecutionPolicy Bypass -File deploy.ps1

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  실거래가 분석 대시보드 - 자동 배포 스크립트" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# 1. GitHub CLI 확인 및 설치
Write-Host "[1/6] GitHub CLI 확인 중..." -ForegroundColor Yellow

$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghInstalled) {
    Write-Host "GitHub CLI가 설치되어 있지 않습니다. 설치를 시도합니다..." -ForegroundColor Red

    # winget으로 설치 시도
    $wingetInstalled = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetInstalled) {
        Write-Host "winget으로 GitHub CLI 설치 중..." -ForegroundColor Yellow
        winget install GitHub.cli --accept-source-agreements --accept-package-agreements
    } else {
        Write-Host "winget이 없습니다. 수동 설치가 필요합니다." -ForegroundColor Red
        Write-Host "https://cli.github.com/ 에서 다운로드하세요." -ForegroundColor Yellow
        Read-Host "설치 후 Enter를 눌러 계속하세요"
    }

    # 설치 확인
    $ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $ghInstalled) {
        Write-Host "[오류] GitHub CLI 설치에 실패했습니다." -ForegroundColor Red
        exit 1
    }
}
Write-Host "GitHub CLI 확인 완료" -ForegroundColor Green
Write-Host ""

# 2. GitHub 로그인 확인
Write-Host "[2/6] GitHub 로그인 확인 중..." -ForegroundColor Yellow

$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "GitHub 로그인이 필요합니다..." -ForegroundColor Yellow
    gh auth login
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[오류] GitHub 로그인에 실패했습니다." -ForegroundColor Red
        exit 1
    }
}
Write-Host "GitHub 로그인 확인 완료" -ForegroundColor Green
Write-Host ""

# 3. Git 저장소 초기화
Write-Host "[3/6] Git 저장소 초기화 중..." -ForegroundColor Yellow

# 기존 .git 제거 (worktree 참조 파일인 경우)
if (Test-Path ".git") {
    $gitContent = Get-Content ".git" -ErrorAction SilentlyContinue
    if ($gitContent -match "gitdir:") {
        Write-Host "깨진 worktree 참조를 제거합니다..." -ForegroundColor Yellow
        Remove-Item ".git" -Force
    }
}

# Git 초기화
if (-not (Test-Path ".git")) {
    git init
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[오류] Git 초기화에 실패했습니다." -ForegroundColor Red
        exit 1
    }
}
Write-Host "Git 저장소 초기화 완료" -ForegroundColor Green
Write-Host ""

# 4. 파일 스테이징 및 커밋
Write-Host "[4/6] 파일 스테이징 중..." -ForegroundColor Yellow
git add .
git commit -m "Initial commit: 아파트 실거래가 분석 대시보드"
Write-Host "커밋 완료" -ForegroundColor Green
Write-Host ""

# 5. GitHub 저장소 생성
Write-Host "[5/6] GitHub 저장소 생성 중..." -ForegroundColor Yellow

$defaultRepoName = "apartment-price-dashboard"
$repoName = Read-Host "저장소 이름을 입력하세요 (기본: $defaultRepoName)"
if ([string]::IsNullOrEmpty($repoName)) {
    $repoName = $defaultRepoName
}

$visibility = Read-Host "저장소 공개 여부 (public/private, 기본: public)"
if ([string]::IsNullOrEmpty($visibility)) {
    $visibility = "public"
}

gh repo create $repoName --$visibility --source=. --remote=origin --push
if ($LASTEXITCODE -ne 0) {
    Write-Host "[오류] GitHub 저장소 생성에 실패했습니다." -ForegroundColor Red
    Write-Host "저장소가 이미 존재하거나 권한 문제일 수 있습니다." -ForegroundColor Yellow
    exit 1
}
Write-Host "GitHub 저장소 생성 및 푸시 완료" -ForegroundColor Green
Write-Host ""

# 6. 배포 안내
Write-Host "[6/6] 배포 안내" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "GitHub 저장소가 성공적으로 생성되었습니다!" -ForegroundColor Green
Write-Host ""
Write-Host "다음 단계: Streamlit Cloud 배포" -ForegroundColor White
Write-Host "  1. https://share.streamlit.io 접속" -ForegroundColor White
Write-Host "  2. GitHub 계정으로 로그인" -ForegroundColor White
Write-Host "  3. 'New app' 클릭" -ForegroundColor White
Write-Host "  4. 저장소 선택: $repoName" -ForegroundColor White
Write-Host "  5. Main file path: app.py" -ForegroundColor White
Write-Host "  6. Deploy 클릭" -ForegroundColor White
Write-Host ""
Write-Host "Secrets 설정 (배포 후):" -ForegroundColor White
Write-Host "  1. App settings → Secrets" -ForegroundColor White
Write-Host '  2. 다음 내용 추가:' -ForegroundColor White
Write-Host '     API_SERVICE_KEY = "your-api-key"' -ForegroundColor Yellow
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan

# 브라우저로 Streamlit Cloud 열기
$openBrowser = Read-Host "Streamlit Cloud 페이지를 열까요? (y/n)"
if ($openBrowser -eq "y") {
    Start-Process "https://share.streamlit.io"
}

Write-Host ""
Write-Host "배포 준비가 완료되었습니다!" -ForegroundColor Green
Read-Host "Enter를 눌러 종료"
