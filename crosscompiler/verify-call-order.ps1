param(
    [string]$Compiler=(Join-Path $PSScriptRoot 'bin/swc.exe'),
    [string]$OutputDirectory=(Join-Path $PSScriptRoot 'proof/call-order-verification')
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
    foreach($case in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'source/windows/se/call-order-cases.json') -Raw | ConvertFrom-Json)) {
        $reference=$null
        foreach($worker in @(1,2,0)) {
            $env:SWC_THREADS=[string]$worker
            $output=Join-Path $directory "$($case.name)-$worker.exe"
            & $Compiler compile (Join-Path $PSScriptRoot "source/windows/se/call-order-$($case.name).se") -o $output
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
    [ordered]@{schema='swc.call-order-verification.v1';verified_at=[DateTimeOffset]::Now.ToString('o');compiler_sha256=(Get-FileHash -LiteralPath $Compiler -Algorithm SHA256).Hash;tests=@($results.ToArray())} | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $directory 'validation.json') -Encoding utf8
    Write-Host "Call order verification passed. Report: $directory/validation.json"
}
finally {$env:SWC_THREADS=$previousThreads}
