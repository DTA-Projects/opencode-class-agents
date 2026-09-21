param(
    [string]$Mode = "both",
    [string]$Message = "Sync via opencode /sync"
)

# Pushes and/or pulls the two repos the user keeps in sync:
#   opencode-config   -> ~/.config/opencode
#   study-materials   -> ~/Documents/Study Materials
# Uses HOME-relative paths so it works on any machine regardless of username.

switch ($Mode.ToLower()) {
    "push" { $doPull = $false; $doPush = $true  }
    "pull" { $doPull = $true;  $doPush = $false }
    "both" { $doPull = $true;  $doPush = $true  }
    default {
        Write-Host "Unknown mode: $Mode (use push, pull, or both)"
        exit 2
    }
}

$repos = @(
    "$HOME\.config\opencode",
    "$HOME\Documents\Study Materials"
)

foreach ($repo in $repos) {
    if (-not (Test-Path (Join-Path $repo ".git"))) {
        Write-Host "SKIP (not a git repo): $repo"
        continue
    }
    Write-Host ""
    Write-Host "=== $repo ==="
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
}

Write-Host ""
Write-Host "Sync complete."