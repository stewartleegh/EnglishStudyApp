# 本地 CI 冒烟脚本（T-0102）：与 .github/workflows/ci.yml 的 job 一一对应。
# 本脚本将 LOCALAPPDATA / PLAYWRIGHT_BROWSERS_PATH 重定向到项目内，
# 保证在受沙箱限制的开发机上也能完整跑通（CI 上无需这些重定向）。
# 用法：powershell -File scripts/ci-check.ps1 [job]
param(
    [ValidateSet("typecheck", "lint", "unit", "integration", "migrations", "e2e", "all")]
    [string]$Job = "all"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# 沙箱重定向
$env:LOCALAPPDATA = Join-Path $root ".next-sandbox-home"
$env:PLAYWRIGHT_BROWSERS_PATH = Join-Path $root ".playwright-browsers"
$env:NEXT_TELEMETRY_DISABLED = "1"

function Invoke-CiStep([string]$name, [string]$cmd) {
    Write-Host "==> [$name]" -ForegroundColor Cyan
    & npx.cmd -y pnpm@11.25.0 run $cmd
    if ($LASTEXITCODE -ne 0) { throw "[$name] failed with exit code $LASTEXITCODE" }
    Write-Host "==> [$name] OK" -ForegroundColor Green
}

function Invoke-Migrations {
    Write-Host "==> [migrations] db reset gate" -ForegroundColor Cyan
    $sqlFiles = @(Get-ChildItem -Path "db/migrations" -Filter "*.sql" -File -ErrorAction SilentlyContinue)
    if ($sqlFiles.Count -eq 0) {
        Write-Host "no migration files, empty-db gate passed" -ForegroundColor Green
        return
    }
    $dbUrl = $env:TEST_DATABASE_URL
    $useDocker = $false
    $psqlCmd = Get-Command psql -ErrorAction SilentlyContinue
    if (-not $psqlCmd) {
        $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
        if ($dockerCmd) {
            $containerName = docker ps --filter "name=esapp-supabase-db" --format "{{.Names}}" 2>$null
            if ($containerName -eq "esapp-supabase-db") {
                $useDocker = $true
            }
        }
    }
    if (-not $psqlCmd -and -not $useDocker) {
        Write-Host "[migrations] WARNING: no psql and Docker Supabase not running, skipping (CI enforces this)" -ForegroundColor Yellow
        return
    }
    foreach ($f in $sqlFiles) {
        Write-Host "applying: $($f.Name)"
        if ($useDocker) {
            Get-Content $f.FullName -Raw | docker exec -i esapp-supabase-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 -q
        } else {
            if (-not $dbUrl) {
                $dbUrl = "postgres://postgres:local-dev-postgres-password-change-me@localhost:5432/postgres"
            }
            Get-Content $f.FullName -Raw | psql $dbUrl -v ON_ERROR_STOP=1 -q
        }
        if ($LASTEXITCODE -ne 0) { throw "[migrations] failed applying $($f.Name) with exit code $LASTEXITCODE" }
    }
    Write-Host "db reset OK" -ForegroundColor Green
}

switch ($Job) {
    "typecheck"   { Invoke-CiStep "typecheck" "typecheck" }
    "lint"        { Invoke-CiStep "lint" "lint" }
    "unit"        { Invoke-CiStep "unit (coverage)" "test:unit" }
    "integration" { Invoke-CiStep "integration" "test:integration" }
    "migrations"  { Invoke-Migrations }
    "e2e" {
        Write-Host "==> [e2e] install chromium browser" -ForegroundColor Cyan
        & npx.cmd -y pnpm@11.25.0 exec playwright install chromium
        if ($LASTEXITCODE -ne 0) { throw "[e2e] browser install failed" }
        Invoke-CiStep "e2e build" "build"
        Write-Host "==> [e2e] playwright chromium" -ForegroundColor Cyan
        & npx.cmd -y pnpm@11.25.0 exec playwright test --project=chromium
        if ($LASTEXITCODE -ne 0) { throw "[e2e] failed" }
        Write-Host "==> [e2e] OK" -ForegroundColor Green
    }
    default {
        Invoke-CiStep "typecheck" "typecheck"
        Invoke-CiStep "lint" "lint"
        Invoke-CiStep "unit (coverage)" "test:unit"
        Invoke-CiStep "integration" "test:integration"
        Invoke-Migrations
        Invoke-CiStep "e2e build" "build"
        Write-Host "==> [e2e] install chromium browser" -ForegroundColor Cyan
        & npx.cmd -y pnpm@11.25.0 exec playwright install chromium
        if ($LASTEXITCODE -ne 0) { throw "[e2e] browser install failed" }
        Write-Host "==> [e2e] playwright chromium" -ForegroundColor Cyan
        & npx.cmd -y pnpm@11.25.0 exec playwright test --project=chromium
        if ($LASTEXITCODE -ne 0) { throw "[e2e] failed" }
        Write-Host "==> [e2e] OK" -ForegroundColor Green
    }
}

Write-Host "ALL CI STEPS PASSED" -ForegroundColor Green
