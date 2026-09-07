$ErrorActionPreference = 'Stop'

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$installerScript = Join-Path $PSScriptRoot 'hello_gallery.iss'
$compilerCandidates = @(
  (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 7\ISCC.exe'),
  (Join-Path $env:ProgramFiles 'Inno Setup 7\ISCC.exe'),
  (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 7\ISCC.exe'),
  (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe'),
  (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe')
)

$compiler = $compilerCandidates |
  Where-Object { Test-Path -LiteralPath $_ } |
  Select-Object -First 1

if ($null -eq $compiler) {
  throw 'Inno Setup was not found. Install Inno Setup 6 or 7, then run this script again.'
}

Push-Location $projectRoot
try {
  & flutter build windows --release
  if ($LASTEXITCODE -ne 0) {
    throw "Flutter Windows build failed with exit code $LASTEXITCODE."
  }

  & $compiler $installerScript
  if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup compilation failed with exit code $LASTEXITCODE."
  }
} finally {
  Pop-Location
}

Write-Host 'Installer created in the dist directory.'
