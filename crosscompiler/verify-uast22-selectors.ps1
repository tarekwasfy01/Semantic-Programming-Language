param(
    [string]$Compiler=(Join-Path $PSScriptRoot 'bin/swc.exe'),
    [string]$OutputDirectory=(Join-Path $PSScriptRoot 'proof/uast22-selectors-verification')
)
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$Compiler=(Resolve-Path -LiteralPath $Compiler).Path
$directory=Join-Path $OutputDirectory (Get-Date -Format 'yyyyMMdd-HHmmss-fff')
$null=New-Item -ItemType Directory -Force -Path $directory
$directory=(Resolve-Path -LiteralPath $directory).Path
$previousThreads=$env:SWC_THREADS
$results=[Collections.Generic.List[object]]::new()
try {
    $cases=@(
        @{name='supplied-selftest';source='source/shared/se/units/uast22-u22_select_selftest.se';exit=25},
        @{name='selector-boundaries';source='source/windows/se/uast22-selector-boundaries.se';exit=42}
    )
    foreach($case in $cases) {
        $reference=$null
        foreach($worker in @(1,2,0)) {
            $env:SWC_THREADS=[string]$worker
            $output=Join-Path $directory "$($case.name)-$worker.exe"
            & $Compiler compile (Join-Path $PSScriptRoot $case.source) -o $output
            if($LASTEXITCODE -ne 0){throw "$($case.name) compilation failed: $LASTEXITCODE"}
            $process=Start-Process -FilePath $output -WindowStyle Hidden -PassThru
            if(-not $process.WaitForExit(10000)){$process.Kill();throw "$($case.name) timed out"}
            if($process.ExitCode -ne $case.exit){throw "$($case.name) returned $($process.ExitCode); expected $($case.exit)"}
            $hash=(Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash
            if($reference -and $reference -ne $hash){throw "$($case.name) differs between worker counts"}
            $reference=$hash
            $results.Add([ordered]@{test=$case.name;requested_workers=$worker;exit=$process.ExitCode;sha256=$hash})
        }
    }
    [ordered]@{schema='swc.uast22-selector-verification.v1';verified_at=[DateTimeOffset]::Now.ToString('o');compiler_sha256=(Get-FileHash -LiteralPath $Compiler -Algorithm SHA256).Hash;tests=@($results.ToArray());boundary_assertions=25;full_uast_lowerable=$false} | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $directory 'validation.json') -Encoding utf8
    Write-Host "V22 selector verification passed. Report: $directory/validation.json"
}
finally {$env:SWC_THREADS=$previousThreads}
