param(
    [string]$Compiler = (Join-Path $PSScriptRoot 'bin/swc.exe'),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'proof/parallel-verification')
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$Compiler = (Resolve-Path -LiteralPath $Compiler).Path
$runDirectory = Join-Path $OutputDirectory (Get-Date -Format 'yyyyMMdd-HHmmss-fff')
$null = New-Item -ItemType Directory -Force -Path $runDirectory
$runDirectory = (Resolve-Path -LiteralPath $runDirectory).Path
$sourceDirectory = Join-Path $PSScriptRoot 'source/windows/se'
$previousThreads = $env:SWC_THREADS
$previousTrace = $env:SWC_PARALLEL_TRACE
$results = [Collections.Generic.List[object]]::new()

function Invoke-Compile([string]$Source, [string]$Output, [int]$Expected = 0) {
    & $Compiler compile $Source -o $Output
    $compileExit = $LASTEXITCODE
    if ($compileExit -ne $Expected) {
        throw "Compilation of $Source exited $compileExit; expected $Expected."
    }
    return $compileExit
}

try {
    $env:SWC_PARALLEL_TRACE = '1'
    $referenceHash = $null
    foreach ($workers in @(1, 2, 0)) {
        $env:SWC_THREADS = [string]$workers
        $output = Join-Path $runDirectory "functions-$workers.exe"
        $null = Invoke-Compile (Join-Path $sourceDirectory 'parallel-functions.se') $output
        & $output
        $runExit = $LASTEXITCODE
        if ($runExit -ne 44) { throw "Functions fixture exited $runExit; expected 44." }
        $hash = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash
        if ($null -eq $referenceHash) { $referenceHash = $hash }
        if ($hash -ne $referenceHash) { throw "Output bytes differ with SWC_THREADS=$workers." }
        $results.Add([ordered]@{ test='functions'; requested_workers=$workers; sha256=$hash; exit=$runExit })
    }

    $env:SWC_THREADS = '0'
    $addressOutput = Join-Path $runDirectory 'address-valid.exe'
    $null = Invoke-Compile (Join-Path $sourceDirectory 'parallel-address-valid.se') $addressOutput
    & $addressOutput
    $addressExit = $LASTEXITCODE
    if ($addressExit -ne 42) { throw "Native function-address fixture exited $addressExit; expected 42." }
    $results.Add([ordered]@{ test='function-address'; exit=$addressExit })

    foreach ($name in @('parallel-address-missing', 'parallel-address-arity')) {
        $output = Join-Path $runDirectory "$name.exe"
        $null = Invoke-Compile (Join-Path $sourceDirectory "$name.se") $output 3
        if (Test-Path -LiteralPath $output) { throw "Rejected input created an executable: $name" }
        $results.Add([ordered]@{ test=$name; compile_exit=3; output_created=$false })
    }

    # A failing task must not publish partial output or overwrite an existing file.
    $invalidSource = [IO.File]::ReadAllText((Join-Path $sourceDirectory 'parallel-functions.se'))
    $callee = '"structural_kind":"SymbolRef","fields":{"kind":"identifier","name":"parallel_seed"}'
    $position = $invalidSource.IndexOf($callee, [StringComparison]::Ordinal)
    if ($position -lt 0) { throw 'Parallel fixture no longer contains the expected cross-function call.' }
    $replacement = $callee.Replace('parallel_seed', 'missing_parallel_target')
    $invalidSource = $invalidSource.Substring(0, $position) + $replacement + $invalidSource.Substring($position + $callee.Length)
    $invalidPath = Join-Path $runDirectory 'invalid-worker.se'
    [IO.File]::WriteAllText($invalidPath, $invalidSource, [Text.UTF8Encoding]::new($false))
    $preservedOutput = Join-Path $runDirectory 'preserved-output.exe'
    [IO.File]::WriteAllBytes($preservedOutput, [Text.Encoding]::UTF8.GetBytes('preserve existing output'))
    $beforeHash = (Get-FileHash -LiteralPath $preservedOutput -Algorithm SHA256).Hash
    $null = Invoke-Compile $invalidPath $preservedOutput 3
    if ((Get-FileHash -LiteralPath $preservedOutput -Algorithm SHA256).Hash -ne $beforeHash) {
        throw 'A failed parallel worker changed the existing output file.'
    }
    $results.Add([ordered]@{ test='failed-worker'; compile_exit=3; existing_output_preserved=$true })

    $report = [ordered]@{
        schema='swc.parallel-verification.v1'
        verified_at=[DateTimeOffset]::Now.ToString('o')
        compiler_sha256=(Get-FileHash -LiteralPath $Compiler -Algorithm SHA256).Hash
        logical_processors=[Environment]::ProcessorCount
        tests=@($results.ToArray())
    }
    $reportPath = Join-Path $runDirectory 'validation.json'
    $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding utf8
    Write-Host "Parallel compilation verified. Report: $reportPath"
}
finally {
    $env:SWC_THREADS = $previousThreads
    $env:SWC_PARALLEL_TRACE = $previousTrace
}
