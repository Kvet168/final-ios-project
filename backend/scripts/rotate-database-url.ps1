<#
  Finishes a Neon password rotation in one step.

  1. In the Neon console: Project -> Roles -> your role -> "Reset password" (or Connection details -> copy the new connection string).
  2. Run this script from the backend folder:   powershell -ExecutionPolicy Bypass -File scripts\rotate-database-url.ps1
  3. Paste the NEW connection string when asked (input is hidden, nothing is echoed or logged).

  It updates backend\.env, replaces DATABASE_URL in the Vercel production environment, redeploys the API
  and checks /api/health. The old password stops working the moment Neon resets it.
#>
$ErrorActionPreference = "Stop"
$backend = Split-Path -Parent $PSScriptRoot
Set-Location $backend

$secure = Read-Host "New Neon connection string (postgresql://...)" -AsSecureString
$url = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
if ($url -notmatch '^postgres(ql)?://') { throw "That does not look like a PostgreSQL connection string." }

# 1) local .env (quoted so characters such as # survive)
$envFile = Join-Path $backend ".env"
$lines = @()
if (Test-Path $envFile) { $lines = Get-Content $envFile | Where-Object { $_ -notmatch '^\s*DATABASE_URL=' } }
$lines = @("DATABASE_URL=`"$url`"") + $lines
Set-Content -Path $envFile -Value $lines -Encoding utf8
Write-Host "Updated backend\.env"

# 2) Vercel production environment
try { vercel env rm DATABASE_URL production --yes | Out-Null } catch { }
$url | vercel env add DATABASE_URL production | Out-Null
Write-Host "Updated Vercel DATABASE_URL (production)"

# 3) redeploy and verify
vercel deploy --prod --yes | Out-Null
Start-Sleep -Seconds 5
$h = Invoke-RestMethod "https://wayfarer-api-liart.vercel.app/api/health"
Write-Host "Health:" ($h | ConvertTo-Json -Compress)
if ($h.status -ne "ok") { throw "API is not healthy after rotation; check the connection string." }
Write-Host "Rotation complete. Delete any chat/notes that contain the old password."
