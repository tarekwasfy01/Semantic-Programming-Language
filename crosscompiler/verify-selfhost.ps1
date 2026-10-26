param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'proof/selfhost')
)

$ErrorActionPreference = 'Stop'
$compiler = Join-Path $PSScriptRoot 'bin/swc.exe'
$manifest = Join-Path $PSScriptRoot 'manifests/swc.smod'
$probe = Join-Path $PSScriptRoot 'source/windows/se/return42.se'
$null = New-Item -ItemType Directory -Force -Path $OutputDirectory
$OutputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).Path
$stage2 = Join-Path $OutputDirectory 'swc-stage2.exe'
$stage3 = Join-Path $OutputDirectory 'swc-stage3.exe'
$probeExe = Join-Path $OutputDirectory 'return42.exe'

Write-Host 'Building Stage 2...'
& $compiler compile $manifest -o $stage2 --embed-all
if ($LASTEXITCODE -ne 0) { throw "Stage 2 compilation failed: $LASTEXITCODE" }

Write-Host 'Building Stage 3...'
& $stage2 compile $manifest -o $stage3 --embed-all
if ($LASTEXITCODE -ne 0) { throw "Stage 3 compilation failed: $LASTEXITCODE" }

$hashes = @($compiler, $stage2, $stage3) | ForEach-Object {
    (Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash
}
if (($hashes | Select-Object -Unique | Measure-Object).Count -ne 1) {
    throw "Selfhost bytes differ: $($hashes -join ', ')"
}

Write-Host 'Compiling and executing return42 with Stage 3...'
& $stage3 compile $probe -o $probeExe
if ($LASTEXITCODE -ne 0) { throw "Probe compilation failed: $LASTEXITCODE" }
& $probeExe
$probeExit = $LASTEXITCODE
if ($probeExit -ne 42) { throw "Expected return42 exit 42, got $probeExit" }

$report = [ordered]@{
    schema = 'swc.local-selfhost.v1'
    verified_at = [DateTimeOffset]::Now.ToString('o')
    stage1_sha256 = $hashes[0]
    stage2_sha256 = $hashes[1]
    stage3_sha256 = $hashes[2]
    byte_stable = $true
    return42_exit = $probeExit
}
$report | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $OutputDirectory 'validation.json') -Encoding utf8
Write-Host "Selfhost verified: $($hashes[0])"
