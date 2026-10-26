param(
    [string]$Compiler = (Join-Path $PSScriptRoot 'bin/swc.exe'),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'proof/boolean-verification')
)
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$Compiler=(Resolve-Path -LiteralPath $Compiler).Path
$sources=Join-Path $PSScriptRoot 'source/windows/se/boolean'
$directory=Join-Path $OutputDirectory (Get-Date -Format 'yyyyMMdd-HHmmss-fff')
$null=New-Item -ItemType Directory -Force -Path $directory
$directory=(Resolve-Path -LiteralPath $directory).Path
$priorThreads=$env:SWC_THREADS
$priorTrace=$env:SWC_PARALLEL_TRACE
$results=[Collections.Generic.List[object]]::new()
try {
    $env:SWC_PARALLEL_TRACE='1'
    foreach($case in (Get-Content -LiteralPath (Join-Path $sources 'cases.json') -Raw | ConvertFrom-Json)) {
        $workers=if($case.name -eq 'parallel_boolean'){@(1,2,0)}else{@(0)}
        $reference=$null
        foreach($worker in $workers){
            $env:SWC_THREADS=[string]$worker
            $output=Join-Path $directory "$($case.name)-$worker.exe"
            if($case.compile_exit -ne 0){[IO.File]::WriteAllText($output,'preserve existing output');$before=(Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash}
            & $Compiler compile (Join-Path $sources "$($case.name).se") -o $output
            if($LASTEXITCODE -ne $case.compile_exit){throw "$($case.name) compile exit $LASTEXITCODE; expected $($case.compile_exit)"}
            if($case.compile_exit -ne 0){
                if((Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash -ne $before){throw "$($case.name) changed an existing output"}
                $results.Add([ordered]@{test=$case.name;compile_exit=3;existing_output_preserved=$true})
                continue
            }
            $process=Start-Process -FilePath $output -WindowStyle Hidden -PassThru
            if(-not $process.WaitForExit(10000)){$process.Kill();throw "$($case.name) timed out"}
            if($process.ExitCode -ne $case.exit){throw "$($case.name) returned $($process.ExitCode); expected $($case.exit)"}
            $hash=(Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash
            if($reference -and $hash -ne $reference){throw 'Boolean output differs between worker counts'}
            $reference=$hash
            $results.Add([ordered]@{test=$case.name;requested_workers=$worker;exit=$process.ExitCode;sha256=$hash})
        }
    }
    [ordered]@{schema='swc.typed-boolean-native-verification.v1';verified_at=[DateTimeOffset]::Now.ToString('o');compiler_sha256=(Get-FileHash -LiteralPath $Compiler -Algorithm SHA256).Hash;tests=@($results.ToArray());full_go_frontend_native_ready=$false} | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $directory 'validation.json') -Encoding utf8
    Write-Host "Typed Boolean native verification passed. Report: $directory/validation.json"
}
finally {$env:SWC_THREADS=$priorThreads;$env:SWC_PARALLEL_TRACE=$priorTrace}
