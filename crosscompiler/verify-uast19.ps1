param(
    [string]$Compiler = (Join-Path $PSScriptRoot 'bin/swc.exe'),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'proof/uast19-verification')
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$Compiler = (Resolve-Path -LiteralPath $Compiler).Path
$directory = Join-Path $OutputDirectory (Get-Date -Format 'yyyyMMdd-HHmmss-fff')
$null = New-Item -ItemType Directory -Force -Path $directory
$directory = (Resolve-Path -LiteralPath $directory).Path
$sources = Join-Path $PSScriptRoot 'source/windows/se/uast19'
$oldThreads = $env:SWC_THREADS
$oldTrace = $env:SWC_PARALLEL_TRACE
$results = [Collections.Generic.List[object]]::new()
function Read-Graph([string]$Path) {
    $source = [IO.File]::ReadAllText($Path)
    $nodes = [regex]::Match($source, '(?s)nodes=\[(.*?)\]\s*relations=\[').Groups[1].Value.Trim().TrimEnd(',')
    $relations = [regex]::Match($source, '(?s)relations=\[(.*?)\]\s*(?:extensions=|metadata=|\})').Groups[1].Value.Trim().TrimEnd(',')
    return @{ nodes=@(('['+$nodes+']' | ConvertFrom-Json)); relations=@(('['+$relations+']' | ConvertFrom-Json)) }
}
function Write-Graph($Graph, [string]$Path) {
    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add("# Semantic Programming Language`nse 1`nprogram {`nschema=1`nprojection=`"semantic_document.v1`"`norigin={`"source_language`":`"semantic`",`"entry_point`":`"main`",`"modules`":[]}`nevaluation=`"eager_left_to_right`"`nindex_base=0`nvalue_model=`"explicit`"`nnodes=[")
    $lines.Add(($Graph.nodes | ForEach-Object {
        $fields = [ordered]@{kind=$_.fields.kind}
        foreach ($property in $_.fields.PSObject.Properties) {
            if ($property.Name -ne 'kind') { $fields[$property.Name] = $property.Value }
        }
        if ($_.fields -is [Collections.IDictionary]) {
            foreach ($key in $_.fields.Keys) { if ($key -ne 'kind') { $fields[$key] = $_.fields[$key] } }
        }
        ConvertTo-Json -InputObject ([ordered]@{id=$_.id;structural_kind=$_.structural_kind;fields=$fields}) -Depth 100 -Compress
    }) -join ",`n")
    $lines.Add("]`nrelations=[")
    $lines.Add(($Graph.relations | ForEach-Object {
        ConvertTo-Json -InputObject ([ordered]@{kind=$_.kind;from=$_.from;to=[ordered]@{domain=$_.to.domain;id=$_.to.id};attributes=$_.attributes}) -Depth 100 -Compress
    }) -join ",`n")
    $lines.Add("]`n}")
    [IO.File]::WriteAllText($Path, ($lines -join "`n")+"`n", [Text.UTF8Encoding]::new($false))
}
function Reject-Graph([string]$Name, $Graph) {
    $source = Join-Path $directory "$Name.se"
    $output = Join-Path $directory "$Name.exe"
    Write-Graph $Graph $source
    [IO.File]::WriteAllText($output, 'preserve existing output')
    $before = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash
    & $Compiler compile $source -o $output
    if ($LASTEXITCODE -ne 3) { throw "$Name was not rejected with compile exit 3: $LASTEXITCODE" }
    if ((Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash -ne $before) { throw "$Name overwrote existing output" }
    $results.Add([ordered]@{test=$Name;compile_exit=3;existing_output_preserved=$true})
}
try {
    $env:SWC_THREADS = '0'
    $env:SWC_PARALLEL_TRACE = '1'
    $cases = [ordered]@{continue_then_break=4;nested_loops=5;while_true_break=6;fixed_literal_foreach=10;contracts=6;raw_static_foreach=7;parallel_loops=38;bool_andand_0_1_1=0;bool_andand_1_0_0=0;bool_andand_1_0_1=1;bool_oror_0_0_0=0;bool_oror_0_0_1=1;bool_oror_1_1_1=1}
    foreach ($name in $cases.Keys) {
        $reference = $null
        $workers = if ($name -eq 'parallel_loops') { @(1,2,0) } else { @(0) }
        foreach ($worker in $workers) {
            $env:SWC_THREADS = [string]$worker
            $output = Join-Path $directory "$name-$worker.exe"
            & $Compiler compile (Join-Path $sources "$name.se") -o $output
            if ($LASTEXITCODE -ne 0) { throw "$name failed compilation: $LASTEXITCODE" }
            $process = Start-Process -FilePath $output -WindowStyle Hidden -PassThru
            if (-not $process.WaitForExit(10000)) { $process.Kill(); throw "$name timed out" }
            if ($process.ExitCode -ne $cases[$name]) { throw "$name returned $($process.ExitCode); expected $($cases[$name])" }
            $hash = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash
            if ($reference -and $hash -ne $reference) { throw "$name differs between worker counts" }
            $reference = $hash
            $results.Add([ordered]@{test=$name;requested_workers=$worker;exit=$process.ExitCode;sha256=$hash})
        }
    }
    $env:SWC_THREADS = '0'
    $loopSource = Join-Path $sources 'nested_loops.se'
    $graph = Read-Graph $loopSource
    $control = @($graph.nodes | Where-Object structural_kind -eq 'ContinueStmt')[0]
    $control.fields.operation.control.target_loop_id = 999999
    Reject-Graph 'mismatched-field-target' $graph

    $graph = Read-Graph $loopSource
    $edge = @($graph.relations | Where-Object kind -eq 'semantic.control_target')[0]
    $otherLoop = @($graph.nodes | Where-Object { $_.structural_kind -eq 'LoopStmt' -and [string]$_.id -ne $edge.to.id })[0]
    $edge.to.id = [string]$otherLoop.id
    Reject-Graph 'mismatched-edge-target' $graph

    $graph = Read-Graph $loopSource
    $edge = @($graph.relations | Where-Object kind -eq 'semantic.control_target')[0]
    $graph.relations = @($graph.relations | Where-Object { $_ -ne $edge })
    Reject-Graph 'missing-explicit-edge' $graph

    $graph = Read-Graph $loopSource
    $graph.relations += @($graph.relations | Where-Object kind -eq 'semantic.control_target')[0]
    Reject-Graph 'duplicate-control-edge' $graph

    $graph = Read-Graph $loopSource
    $edge = @($graph.relations | Where-Object kind -eq 'semantic.control_target')[0]
    $edge.attributes.role = 'wrong_transfer_role'
    Reject-Graph 'invalid-control-role' $graph

    $graph = Read-Graph $loopSource
    $edge = @($graph.relations | Where-Object { $_.kind -eq 'syntax.child' -and $_.attributes.role -eq 'condition' })[0]
    $graph.relations += $edge
    Reject-Graph 'duplicate-loop-condition' $graph

    $graph = Read-Graph (Join-Path $sources 'raw_static_foreach.se')
    $aggregate = @($graph.nodes | Where-Object structural_kind -eq 'AggregateExpr')[0]
    $aggregate.structural_kind = 'SymbolRef'
    $aggregate.fields = [pscustomobject]@{kind='identifier';name='dynamic_sequence'}
    Reject-Graph 'dynamic-foreach-sequence' $graph

    $graph = Read-Graph (Join-Path $sources 'while_true_break.se')
    $function = @($graph.nodes | Where-Object structural_kind -eq 'ClosureExpr')[0]
    $bodyId = @($graph.relations | Where-Object { $_.from -eq $function.id -and $_.attributes.role -eq 'body' })[0].to.id
    $control = @($graph.nodes | Where-Object structural_kind -eq 'BreakStmt')[0]
    $control.fields = [pscustomobject]@{kind='break'}
    $graph.relations = @($graph.relations | Where-Object { $_.kind -ne 'semantic.control_target' -and $_.from -ne [int]$bodyId })
    $graph.relations += [pscustomobject]@{kind='syntax.child';from=[int]$bodyId;to=@{domain='node';id=[string]$control.id};attributes=@{role='statement';ordinal=0}}
    Reject-Graph 'break-outside-loop' $graph

    # A closure structurally nested inside a loop may not jump into that loop.
    $graph = Read-Graph (Join-Path $sources 'while_true_break.se')
    $loop = @($graph.nodes | Where-Object structural_kind -eq 'LoopStmt')[0]
    $loopBody = @($graph.relations | Where-Object { $_.from -eq $loop.id -and $_.attributes.role -eq 'body' })[0].to.id
    $next = [int](($graph.nodes.id | Measure-Object -Maximum).Maximum) + 1
    $graph.nodes += [pscustomobject]@{id=$next;structural_kind='ClosureExpr';fields=@{kind='function';name='v19_nested_closure';operation=@{function_binding='v19_nested_closure'}}}
    $graph.nodes += [pscustomobject]@{id=($next+1);structural_kind='Scope';fields=@{kind='block'}}
    $graph.nodes += [pscustomobject]@{id=($next+2);structural_kind='BreakStmt';fields=@{kind='break';operation=@{control=@{target_loop_id=$loop.id;transfer='loop_break'}}}}
    $graph.relations += [pscustomobject]@{kind='syntax.child';from=[int]$loopBody;to=@{domain='node';id=[string]$next};attributes=@{role='statement';ordinal=999}}
    $graph.relations += [pscustomobject]@{kind='syntax.child';from=$next;to=@{domain='node';id=[string]($next+1)};attributes=@{role='body';ordinal=0}}
    $graph.relations += [pscustomobject]@{kind='syntax.child';from=($next+1);to=@{domain='node';id=[string]($next+2)};attributes=@{role='statement';ordinal=0}}
    $graph.relations += [pscustomobject]@{kind='semantic.control_target';from=($next+2);to=@{domain='node';id=[string]$loop.id};attributes=@{role='exit';ordinal=0}}
    Reject-Graph 'cross-closure-control-target' $graph

    $report = [ordered]@{schema='swc.uast19-native-verification.v1';verified_at=[DateTimeOffset]::Now.ToString('o');compiler_sha256=(Get-FileHash -LiteralPath $Compiler -Algorithm SHA256).Hash;logical_processors=[Environment]::ProcessorCount;tests=@($results.ToArray());full_go_frontend_native_ready=$false}
    $report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $directory 'validation.json') -Encoding utf8
    Write-Host "V19 native verification passed. Report: $directory/validation.json"
}
finally {
    $env:SWC_THREADS = $oldThreads
    $env:SWC_PARALLEL_TRACE = $oldTrace
}
