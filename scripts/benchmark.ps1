param([int]$Iterations = 25, [string]$Path = "README.md")
$ErrorActionPreference = "Stop"
if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "File not found: $Path" }
$elapsed = Measure-Command {
  1..$Iterations | ForEach-Object {
    .\scripts\moonpulse.ps1 $Path -Format json | Out-Null
  }
}
[pscustomobject]@{
  iterations = $Iterations
  file = (Resolve-Path $Path).Path
  total_ms = [math]::Round($elapsed.TotalMilliseconds, 2)
  average_ms = [math]::Round($elapsed.TotalMilliseconds / $Iterations, 2)
}
