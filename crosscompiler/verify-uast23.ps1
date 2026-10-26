param(
    [string]$Compiler=(Join-Path $PSScriptRoot 'bin/swc.exe'),
    [string]$OutputDirectory=(Join-Path $PSScriptRoot 'proof/uast23-verification')
)
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$Compiler=(Resolve-Path -LiteralPath $Compiler).Path
$directory=Join-Path $OutputDirectory (Get-Date -Format 'yyyyMMdd-HHmmss-fff')
$null=New-Item -ItemType Directory -Force -Path $directory
$directory=(Resolve-Path -LiteralPath $directory).Path
$previous=$env:SWC_THREADS
$results=[Collections.Generic.List[object]]::new()
try {
    $cases=@(
        @{name='archive-smoke';source='source/windows/se/uast23-archive-smoke.se';exit=0},
        @{name='runtime-vectors';source='source/windows/se/uast23-runtime_vectors.se';exit=0}
    )
    foreach($case in $cases){
        $reference=$null
        foreach($worker in @(1,2,0)){
            $env:SWC_THREADS=[string]$worker
            $output=Join-Path $directory "$($case.name)-$worker.exe"
            & $Compiler compile (Join-Path $PSScriptRoot $case.source) -o $output
            if($LASTEXITCODE -ne 0){throw "$($case.name) compile exit $LASTEXITCODE"}
            $p=Start-Process -FilePath $output -WindowStyle Hidden -PassThru
            if(-not $p.WaitForExit(10000)){$p.Kill();throw "$($case.name) timed out"}
            if($p.ExitCode -ne $case.exit){throw "$($case.name) returned $($p.ExitCode); expected $($case.exit)"}
            $hash=(Get-FileHash $output -Algorithm SHA256).Hash
            if($reference -and $reference -ne $hash){throw "$($case.name) differs between worker counts"};$reference=$hash
            $results.Add([ordered]@{test=$case.name;requested_workers=$worker;exit=$p.ExitCode;sha256=$hash})
        }
    }
    [ordered]@{schema='swc.uast23-verification.v1';verified_at=[DateTimeOffset]::Now.ToString('o');compiler_sha256=(Get-FileHash $Compiler -Algorithm SHA256).Hash;tests=@($results.ToArray());archive_vector_assertions=90;extra_full_i64_assertions=3;group_selftest_assertions=1;full_uast_lowerable=$false} | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $directory 'validation.json') -Encoding utf8
    Write-Host "V23 native verification passed: $directory/validation.json"
} finally {$env:SWC_THREADS=$previous}
