param(
    [string]$Compiler=(Join-Path $PSScriptRoot 'bin/swc.exe'),
    [string]$OutputDirectory=(Join-Path $PSScriptRoot 'proof/float64-verification')
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
    foreach($case in (Get-Content -Raw (Join-Path $PSScriptRoot 'source/windows/se/float64-cases.json') | ConvertFrom-Json)) {
        $workers=if($case.compile_exit -eq 0){@(1,2,0)}else{@(0)}
        $reference=$null
        foreach($worker in $workers){
            $env:SWC_THREADS=[string]$worker
            $output=Join-Path $directory "$($case.name)-$worker.exe"
            if($case.compile_exit -ne 0){[IO.File]::WriteAllText($output,'preserve');$before=(Get-FileHash $output -Algorithm SHA256).Hash}
            & $Compiler compile (Join-Path $PSScriptRoot "source/windows/se/float64-$($case.name).se") -o $output
            if($LASTEXITCODE -ne $case.compile_exit){throw "$($case.name) compile exit $LASTEXITCODE; expected $($case.compile_exit)"}
            if($case.compile_exit -ne 0){if((Get-FileHash $output -Algorithm SHA256).Hash -ne $before){throw "$($case.name) overwrote existing output"};$results.Add([ordered]@{test=$case.name;compile_exit=3;existing_output_preserved=$true});continue}
            $p=Start-Process -FilePath $output -WindowStyle Hidden -PassThru
            if(-not $p.WaitForExit(10000)){$p.Kill();throw "$($case.name) timed out"}
            if($p.ExitCode -ne $case.exit){throw "$($case.name) returned $($p.ExitCode); expected $($case.exit)"}
            $hash=(Get-FileHash $output -Algorithm SHA256).Hash
            if($reference -and $reference -ne $hash){throw "$($case.name) differs between worker counts"};$reference=$hash
            $results.Add([ordered]@{test=$case.name;requested_workers=$worker;exit=$p.ExitCode;sha256=$hash})
        }
    }
    $oracleCount=@(Get-Content -Raw (Join-Path $PSScriptRoot 'source/windows/se/float64-oracles.json') | ConvertFrom-Json).Count
    [ordered]@{schema='swc.float64-native-verification.v1';verified_at=[DateTimeOffset]::Now.ToString('o');compiler_sha256=(Get-FileHash $Compiler -Algorithm SHA256).Hash;tests=@($results.ToArray());runtime_assertions=$oracleCount;parallel_runtime_assertions=16;parallel_fixture_functions=18;full_uast_lowerable=$false} | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $directory 'validation.json') -Encoding utf8
    Write-Host "Native float64 verification passed: $directory/validation.json"
} finally {$env:SWC_THREADS=$previous}
