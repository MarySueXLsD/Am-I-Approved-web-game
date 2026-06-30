$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "Building HTML5 release..."
lime clean html5
lime build html5 -release

$bin = Join-Path $PWD "export\html5\bin"
$index = Join-Path $bin "index.html"
$gameJs = Join-Path $bin "BreakTheBank.js"

if (-not (Test-Path $gameJs)) {
    throw "HTML5 build failed: missing $gameJs"
}

Write-Host "Patching index.html for itch.io..."
$html = [System.IO.File]::ReadAllText($index)
if ($html -notmatch 'rootPath') {
    $html = $html -replace 'lime\.embed \("BreakTheBank", "openfl-content", 800, 600, \{ parameters: \{\} \}\);', 'lime.embed ("BreakTheBank", "openfl-content", 800, 600, { rootPath: "./", parameters: {} });'
}
[System.IO.File]::WriteAllText($index, $html)

$dist = Join-Path $PWD "dist"
if (-not (Test-Path $dist)) { New-Item -ItemType Directory -Path $dist | Out-Null }
$zip = Join-Path $dist "BreakTheBank-itchio.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }

Write-Host "Creating zip..."
python -c "import shutil, pathlib; root=pathlib.Path(r'$bin'); out=pathlib.Path(r'$zip'); shutil.make_archive(str(out.with_suffix('')), 'zip', root); print(f'{out.stat().st_size/1024/1024:.2f} MB')"

Write-Host "Created $zip"
