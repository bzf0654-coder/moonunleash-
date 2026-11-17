param()
$ErrorActionPreference = 'Stop'
# Windows PowerShell 5.1 otherwise negotiates obsolete TLS defaults.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$revision = '9ef6efa01feabeb699857192ad8106fd7d990235'
$root = Split-Path -Parent $PSScriptRoot
$destination = Join-Path $root 'tests/fixtures/upstream'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
$base = "https://raw.githubusercontent.com/Unleash/client-specification/$revision"
Invoke-WebRequest "$base/specifications/index.json" -OutFile (Join-Path $destination 'index.json')
$files = Get-Content -LiteralPath (Join-Path $destination 'index.json') -Raw | ConvertFrom-Json
foreach ($file in $files) {
    if ($file -notmatch '^\d{2}-[a-z0-9-]+\.json$') { throw "Unexpected upstream filename: $file" }
    Invoke-WebRequest "$base/specifications/$file" -OutFile (Join-Path $destination $file)
}
Invoke-WebRequest "$base/LICENSE" -OutFile (Join-Path $destination 'LICENSE')
$manifest = [ordered]@{ repository = 'https://github.com/Unleash/client-specification'; revision = $revision; files = @() }
foreach ($file in @('index.json', 'LICENSE') + $files) {
    $manifest.files += [ordered]@{ name = $file; sha256 = (Get-FileHash -LiteralPath (Join-Path $destination $file) -Algorithm SHA256).Hash.ToLowerInvariant() }
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $destination 'manifest.json') -Encoding utf8
Write-Output "Fetched $($files.Count) specification files at $revision"
