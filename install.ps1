<#
.SYNOPSIS
    One-command install of the opencode-class-agents template into opencode's
    global config directory (Windows / PowerShell).

.DESCRIPTION
    - Backs up any existing config at the target path.
    - Clones the public template, then re-inits it as a fresh local git repo
      (so your config is yours - point the remote at your own private repo).
    - Scaffolds canvas/.env (prompts for base URL + optional cookie) and
      generates CONTEXT.md from CONTEXT.example.md.
    - Verifies the Canvas helper with `node canvas.mjs whoami`.

.PARAMETER ConfigDir
    Where to install the config. Default: ~/.config/opencode.

.PARAMETER SkipPrompts
    No interactive prompts. Uses defaults (base URL placeholder, empty cookie).
    Also honors the SKIP_PROMPTS=1 environment variable.

.PARAMETER InstallOpencode
    Install opencode automatically if it is missing (npm). Honors the
    INSTALL_OPENCODE=1 environment variable.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/DTA-Projects/opencode-class-agents/main/install.ps1 | iex"
#>
[CmdletBinding()]
param(
    [string]$ConfigDir   = "$HOME\.config\opencode",
    [switch]$SkipPrompts,
    [switch]$InstallOpencode
)

$ErrorActionPreference = "Stop"
$TemplateRepo = "https://github.com/DTA-Projects/opencode-class-agents.git"
$SkipPrompts  = $SkipPrompts -or ($env:SKIP_PROMPTS -eq "1")
$InstallOpencode = $InstallOpencode -or ($env:INSTALL_OPENCODE -eq "1")

function Write-Step { Write-Host "==> $args" -ForegroundColor Cyan }
function Write-Info { Write-Host "    $args" }
function Write-Done { Write-Host "==> $args" -ForegroundColor Green }
function Write-Warn { Write-Host "    WARNING: $args" -ForegroundColor Yellow }

Write-Step "opencode-class-agents installer"

# ---- 1. Prerequisites ----------------------------------------------------
Write-Step "Checking prerequisites"
$missing = @()
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $missing += "git  (https://git-scm.com)" }
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { $missing += "Node.js 18+  (https://nodejs.org)" }
if ($missing.Count -gt 0) {
    Write-Warn "Missing required tools:"
    foreach ($m in $missing) { Write-Host "      - $m" }
    throw "Install the missing tools, then re-run this installer."
}

# ---- 2. opencode itself --------------------------------------------------
if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
    Write-Step "opencode is not installed"
    $shouldInstall = $InstallOpencode
    if (-not $shouldInstall -and -not $SkipPrompts) {
        $ans = Read-Host "    Install opencode now via npm (npm install -g opencode-ai)? [y/N]"
        $shouldInstall = $ans -match "^(y|yes)$"
    }
    if ($shouldInstall) {
        npm install -g opencode-ai
        if ($LASTEXITCODE -ne 0) { throw "opencode install failed. Try: npm install -g opencode-ai" }
        Write-Done "opencode installed. (alternatives: choco install opencode / scoop install opencode)"
    } else {
        Write-Info "Skipping. Install later with: npm install -g opencode-ai"
    }
}

# ---- 3. Protect any existing config -------------------------------------
if (Test-Path $ConfigDir) {
    if (-not $SkipPrompts) {
        $ans = Read-Host "Existing config found at $ConfigDir. Back it up and replace it? [y/N]"
        if ($ans -notmatch "^(y|yes)$") { Write-Info "Aborted - nothing changed."; return }
    }
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = "$ConfigDir.bak-$stamp"
    Write-Step "Backing up existing config to $backup"
    Move-Item -LiteralPath $ConfigDir -Destination $backup
} else {
    $parent = Split-Path $ConfigDir -Parent
    if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
}

# ---- 4. Clone the template, then re-init as a fresh repo -----------------
Write-Step "Cloning the template into $ConfigDir"
git clone --quiet $TemplateRepo $ConfigDir
if ($LASTEXITCODE -ne 0) { throw "git clone failed" }

Write-Step "Re-initializing your config as a fresh git repo"
Remove-Item -Recurse -Force (Join-Path $ConfigDir ".git")
git -C $ConfigDir init -b main | Out-Null
git -C $ConfigDir add -A | Out-Null
$commit = git -C $ConfigDir commit -q -m "Initial config from the opencode-class-agents template"
if ($LASTEXITCODE -ne 0) {
    Write-Warn "Could not create the initial commit. Check git config user.name and user.email."
}

# ---- 5. Canvas credentials ----------------------------------------------
Write-Step "Setting up Canvas credentials"
$envPath = Join-Path $ConfigDir "canvas\.env"
$baseUrl = "https://your-school.instructure.com"
$cookie  = ""
if (-not $SkipPrompts) {
    $baseUrl = Read-Host "Canvas base URL (e.g. https://your-school.instructure.com) [$baseUrl]"
    if (-not $baseUrl) { $baseUrl = "https://your-school.instructure.com" }
    $cookie = Read-Host "Canvas session cookie  (paste now, or press Enter to add later)"
    $cookie = $cookie.Trim()
}
$envLines = @(
    "# Canvas credentials - generated by install.ps1"
    "# Get a fresh cookie: see docs/credentials.md in the template repo."
    "CANVAS_COOKIE=$cookie"
    "CANVAS_API_BASE=$baseUrl"
    ""
    "# Optional: use an API access token instead of a cookie (if your school allows it)."
    "# CANVAS_API_TOKEN="
)
Set-Content -LiteralPath $envPath -Value $envLines -Encoding ascii
Write-Info "Wrote $envPath"

# ---- 6. CONTEXT.md (auto-loaded session context) --------------------------
$ctxExample = Join-Path $ConfigDir "CONTEXT.example.md"
$ctxFile    = Join-Path $ConfigDir "CONTEXT.md"
if ((Test-Path $ctxExample) -and -not (Test-Path $ctxFile)) {
    Copy-Item -LiteralPath $ctxExample -Destination $ctxFile
    Write-Info "Wrote $ctxFile (edit it to match your setup)"
}

# ---- 7. Textbooks folder --------------------------------------------------
$textbooks = Join-Path $HOME "Documents\++Textbooks"
if (-not (Test-Path $textbooks)) {
    New-Item -ItemType Directory -Path $textbooks -Force | Out-Null
    Write-Info "Created $textbooks - drop your textbook PDFs here"
}

# ---- 8. Verify ------------------------------------------------------------
Write-Step "Verifying the Canvas helper"
Push-Location (Join-Path $ConfigDir "canvas")
try {
    if ($cookie) {
        node canvas.mjs whoami
        if ($LASTEXITCODE -ne 0) { Write-Warn "whoami failed - check $envPath and re-run." }
    } else {
        Write-Info "Skipping whoami until you paste your cookie into $envPath"
    }
}
finally { Pop-Location }

# ---- 9. Summary -----------------------------------------------------------
Write-Done "Install complete."
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Add your Canvas cookie if you skipped it: edit $envPath"
Write-Host "  2. List your courses: cd $ConfigDir\canvas ; node canvas.mjs courses"
Write-Host "     then copy the course ids into agents/*.md (see agents/template.md)"
Write-Host "  3. Drop your textbooks into $textbooks"
Write-Host "  4. (Recommended) Point this repo at your own private remote:"
Write-Host "       gh repo create opencode-config --private --source=$ConfigDir --push"
Write-Host "  5. Restart opencode so it picks up the new config."