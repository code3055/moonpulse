param(
  [Parameter(Mandatory=$true, Position=0)]
  [string]$Path,
  [switch]$Json
)

if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
  Write-Error "MoonPulse: file not found: $Path"
  exit 2
}

$env:MOONPULSE_INPUT = Get-Content -LiteralPath $Path -Raw
if ($Json) { $env:MOONPULSE_FORMAT = "json" }
try {
  moon run cmd\moonpulse
  exit $LASTEXITCODE
} finally {
  Remove-Item Env:MOONPULSE_INPUT -ErrorAction SilentlyContinue
  Remove-Item Env:MOONPULSE_FORMAT -ErrorAction SilentlyContinue
}
