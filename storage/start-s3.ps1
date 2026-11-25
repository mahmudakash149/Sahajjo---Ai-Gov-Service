$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$weed = Join-Path $root "weed.exe"
$dataDir = Join-Path $root "data"
$s3Config = Join-Path $root "s3.json"

if (-not (Test-Path $weed)) {
  Write-Error "weed.exe not found in $root. Download SeaweedFS windows_amd64.zip and extract weed.exe here."
}

New-Item -ItemType Directory -Force -Path $dataDir | Out-Null

Write-Host "Starting SeaweedFS S3 server on http://localhost:8333 ..."
& $weed server -dir="$dataDir" -s3 -s3.port=8333 -s3.config="$s3Config" -ip=127.0.0.1
