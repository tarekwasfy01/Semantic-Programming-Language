param([string]$Compiler=(Join-Path $PSScriptRoot 'bin/swc.exe'),[string]$OutputDirectory=(Join-Path $PSScriptRoot 'proof/uast24-verification'))
$ErrorActionPreference='Stop'
$Compiler=(Resolve-Path $Compiler).Path
$directory=Join-Path $OutputDirectory (Get-Date -Format 'yyyyMMdd-HHmmss-fff')
$null=New-Item -ItemType Directory -Force $directory
$directory=(Resolve-Path $directory).Path
$previous=$env:SWC_THREADS
$results=[Collections.Generic.List[object]]::new()
$expected=@(255,255,99,42,0,99,7,255,255,255,0,255,0,0,0,255,42,3,3,2,2,255,0,8,0)
try {
 foreach($i in 0..24){
  $name='test_{0:00}' -f $i
  $reference=$null
  foreach($worker in @(1,2,0)){
   $env:SWC_THREADS=[string]$worker
   $output=Join-Path $directory "$name-$worker.exe"
   & $Compiler compile (Join-Path $PSScriptRoot "source/windows/se/uast24-$name.se") -o $output
   if($LASTEXITCODE -ne 0){throw "$name compile exit $LASTEXITCODE"}
   $p=Start-Process -FilePath $output -WindowStyle Hidden -PassThru
   if(-not $p.WaitForExit(10000)){$p.Kill();throw "$name timeout"}
   # The archive reports Linux process exits modulo 256; Windows preserves the low 32 bits.
   $exit=$p.ExitCode -band 255
   if($exit -ne $expected[$i]){throw "$name returned $($p.ExitCode), expected low byte $($expected[$i])"}
   $hash=(Get-FileHash $output -Algorithm SHA256).Hash
   if($reference -and $reference -ne $hash){throw "$name differs between workers"}
   $reference=$hash
   $results.Add([ordered]@{test=$name;requested_workers=$worker;exit=$p.ExitCode;sha256=$hash})
  }
 }

 foreach($case in @(@{name='aliased-index-and-slice';exit=8},@{name='aliased-index-write';exit=42},@{name='evaluation-order';exit=42})){
  $reference=$null
  foreach($worker in @(1,2,0)){
   $env:SWC_THREADS=[string]$worker
   $output=Join-Path $directory "$($case.name)-$worker.exe"
   & $Compiler compile (Join-Path $PSScriptRoot "source/windows/se/uast24-$($case.name).se") -o $output
   if($LASTEXITCODE -ne 0){throw "$($case.name) compile exit $LASTEXITCODE"}
   $p=Start-Process $output -WindowStyle Hidden -PassThru
   if(-not $p.WaitForExit(10000)){$p.Kill();throw 'raw V24 timeout'}
   if($p.ExitCode -ne $case.exit){throw "$($case.name) exit $($p.ExitCode)"}
   $hash=(Get-FileHash $output -Algorithm SHA256).Hash
   if($reference -and $reference -ne $hash){throw 'raw V24 differs between workers'}
   $reference=$hash
   $results.Add([ordered]@{test=$case.name;requested_workers=$worker;exit=$p.ExitCode;sha256=$hash})
  }
 }
 foreach($name in @('missing-write-order','wrong-write-effect','wrong-write-policy','wrong-view-proof','missing-alias-proof','wrong-slice-policy','wrong-slice-type','missing-load-argument','missing-store-argument','unknown-intrinsic','wrong-pointer-width')){
  $output=Join-Path $directory "$name.exe"
  [IO.File]::WriteAllText($output,'preserve existing output')
  $before=(Get-FileHash $output).Hash
  & $Compiler compile (Join-Path $PSScriptRoot "source/windows/se/uast24-$name.se") -o $output
  if($LASTEXITCODE -eq 0){throw "$name accepted"}
  if((Get-FileHash $output).Hash -ne $before){throw "$name overwrote output"}
  $results.Add([ordered]@{test=$name;rejected=$true;output_preserved=$true})
 }
 [ordered]@{schema='swc.uast24-runtime.v1';compiler_sha256=(Get-FileHash $Compiler -Algorithm SHA256).Hash;tests=@($results.ToArray());full_uast_lowerable=$false;raw_uast24_lowering=$true;full_i64_runtime_assertions=25;archive_sha256='549B3F37D0AC4381453DA995604E400BE2ABBD2FA021019EE4FAA13612C9276C'} | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $directory 'validation.json')
 Write-Host "V24 runtime verification passed: $directory/validation.json"
} finally {$env:SWC_THREADS=$previous}
