param(
    [string]$Mode = "both",
    [string]$Message = "Sync via opencode /sync-here"
)

# Pushes and/or pulls the CURRENT working directory's git repo.
# Use this when you want the /sync behavior but for whatever repo opencode is currently open in.
# Unlike git-sync.ps1 it does NOT know specific repo paths - it just acts on $PWD.

$repo = (Get-Location).Path

switch ($Mode.ToLower()) {
    "push" { $doPull = $false; $doPush = $true  }
    "pull" { $doPull = $true;  $doPush = $false }
    "both" { $doPull = $true;  $doPush = $true  }
    default {
        Write-Host "Unknown mode: $Mode (use push, pull, or both)"
        exit 2
    }
}

Write-Host "=== $repo ==="
if (-not (Test-Path (Join-Path $repo ".git"))) {
    Write-Host "SKIP (not a git repo): $repo"
    exit 0
}

Push-Location $repo
try {
    if ($doPull) {
        git pull --rebase --autostash
        if ($LASTEXITCODE -ne 0) {
            Write-Host "PULL FAILED in $repo - resolve the conflict before pushing."
            exit 1
        }
    }
    if ($doPush) {
        git add -A
        & git commit -m $Message 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Nothing new to commit in $repo."
        } else {
            Write-Host "Committed: $Message"
        }
        git push
        if ($LASTEXITCODE -ne 0) {
            Write-Host "PUSH FAILED in $repo - check your GitHub auth and remote."
            exit 1
        }
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "Sync complete."