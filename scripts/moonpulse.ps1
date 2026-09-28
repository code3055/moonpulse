[CmdletBinding()]
param(
  [Parameter(Position=0)] [string]$Path,
  [switch]$Batch,
  [switch]$Recursive,
  [switch]$Stdin,
  [ValidateSet('text','json','markdown','csv')] [string]$Format,
  [string]$Config = "",
  [Parameter(ValueFromPipeline=$true)] [string]$PipelineText
)

$ErrorActionPreference = "Stop"

function Read-MoonPulseConfig([string]$ConfigPath) {
  $settings = @{}
  if ($ConfigPath -and (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
    foreach ($line in Get-Content -LiteralPath $ConfigPath) {
      $trimmed = $line.Trim()
      if ($trimmed -and -not $trimmed.StartsWith('#') -and $trimmed.Contains('=')) {
        $pair = $trimmed.Split('=', 2)
        $settings[$pair[0].Trim()] = $pair[1].Trim()
      }
    }
  }
  return $settings
}

$configValues = Read-MoonPulseConfig $Config
if (-not $Format -and $configValues.ContainsKey('format')) { $Format = $configValues['format'] }
if (-not $Recursive -and $configValues.ContainsKey('recursive')) { $Recursive = $configValues['recursive'] -in @('true','1','yes') }
if (-not $Path -and -not $Batch -and -not $Stdin) { $Path = "" }

function Invoke-MoonPulseText([string]$Text, [string]$Label) {
  $env:MOONPULSE_INPUT = $Text
  if ($Format) { $env:MOONPULSE_FORMAT = $Format }
  try {
    Write-Output "--- $Label ---"
    & moon run cmd\moonpulse
    if ($LASTEXITCODE -ne 0) { throw "MoonPulse failed for $Label" }
  } finally {
    Remove-Item Env:MOONPULSE_INPUT -ErrorAction SilentlyContinue
    Remove-Item Env:MOONPULSE_FORMAT -ErrorAction SilentlyContinue
  }
}

if ($Stdin -or $Path -eq '-') {
  $stdinText = if ($PipelineText) { $PipelineText } else { ($input | Out-String) }
  Invoke-MoonPulseText $stdinText 'stdin'
  exit 0
}

if ($Batch) {
  if (-not $Path) { throw 'Batch mode requires a directory path.' }
  if (-not (Test-Path -LiteralPath $Path -PathType Container)) { throw "Directory not found: $Path" }
  $files = if ($Recursive) { Get-ChildItem -LiteralPath $Path -File -Recurse } else { Get-ChildItem -LiteralPath $Path -File }
  $pattern = if ($configValues.ContainsKey('pattern')) { $configValues['pattern'] } else { '*.md' }
  $files = $files | Where-Object { $_.Name -like $pattern }
  if (-not $files) { Write-Warning "No files matched $pattern"; exit 0 }
  foreach ($file in $files) { Invoke-MoonPulseText (Get-Content -LiteralPath $file.FullName -Raw) $file.FullName }
  exit 0
}

if (-not $Path) {
  Invoke-MoonPulseText "# MoonBit report`n`nMoonBit makes tools. Tools help teams." 'sample'
  exit 0
}
if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "File not found: $Path" }
Invoke-MoonPulseText (Get-Content -LiteralPath $Path -Raw) $Path



