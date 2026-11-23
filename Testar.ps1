param([switch]$Render)
$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$pythonPath = Join-Path $projectRoot '.venv\Scripts\python.exe'
$godotPath = Join-Path $projectRoot 'engine\godot\Godot.exe'
$gamePath = Join-Path $projectRoot 'game'
$artifactPath = Join-Path $projectRoot 'artifacts'
New-Item -ItemType Directory -Force -Path $artifactPath | Out-Null
Push-Location $projectRoot
try {
    & $pythonPath tools\solver\validate.py
    if ($LASTEXITCODE -ne 0) { throw 'Falha na validacao de fases.' }
    & $pythonPath -m unittest discover -s tests -v
    if ($LASTEXITCODE -ne 0) { throw 'Falha nos testes Python.' }
    $importLog = Join-Path $artifactPath 'import.log'
    $importArgs = @('--headless', '--path', ('"' + $gamePath + '"'), '--editor', '--import', '--quit', '--log-file', ('"' + $importLog + '"'))
    $importProcess = Start-Process -FilePath $godotPath -ArgumentList $importArgs -WindowStyle Hidden -Wait -PassThru
    if ($importProcess.ExitCode -ne 0 -or (Select-String -Path $importLog -Pattern 'SCRIPT ERROR:|^ERROR:' -Quiet)) {
        Get-Content -LiteralPath $importLog
        throw 'Falha na importacao Godot.'
    }
    $testLog = Join-Path $artifactPath $(if ($Render) { 'godot-tests-rendered.log' } else { 'godot-tests.log' })
    $testArgs = @('--path', ('"' + $gamePath + '"'), '--script', 'res://tests/test_mvp.gd', '--log-file', ('"' + $testLog + '"'))
    if (-not $Render) { $testArgs = @('--headless') + $testArgs }
    $testProcess = Start-Process -FilePath $godotPath -ArgumentList $testArgs -WindowStyle Hidden -Wait -PassThru
    Get-Content -LiteralPath $testLog
    if ($testProcess.ExitCode -ne 0 -or (Select-String -Path $testLog -Pattern 'SCRIPT ERROR:|^ERROR:|^FAIL |TEST TIMEOUT' -Quiet)) {
        throw 'Falha nos testes Godot.'
    }
    foreach ($mode in @('write', 'read')) {
        $saveLog = Join-Path $artifactPath ('persistence-' + $mode + '.log')
        $saveArgs = @('--headless', '--path', ('"' + $gamePath + '"'), '--script', 'res://tests/test_persistence.gd', '--log-file', ('"' + $saveLog + '"'), '--', ('--' + $mode))
        $saveProcess = Start-Process -FilePath $godotPath -ArgumentList $saveArgs -WindowStyle Hidden -Wait -PassThru
        Get-Content -LiteralPath $saveLog
        if ($saveProcess.ExitCode -ne 0 -or (Select-String -Path $saveLog -Pattern 'SCRIPT ERROR:|^ERROR:|^FAIL |TEST TIMEOUT' -Quiet)) {
            throw ('Falha no teste de persistencia: ' + $mode)
        }
    }
    $visualLog = Join-Path $artifactPath 'visual-tests.log'
    $visualArgs = @('--path', ('"' + $gamePath + '"'), '--script', 'res://tests/test_visual_preview.gd', '--log-file', ('"' + $visualLog + '"'))
    if (-not $Render) { $visualArgs = @('--headless') + $visualArgs }
    $visualProcess = Start-Process -FilePath $godotPath -ArgumentList $visualArgs -WindowStyle Hidden -Wait -PassThru
    Get-Content -LiteralPath $visualLog
    if ($visualProcess.ExitCode -ne 0 -or (Select-String -Path $visualLog -Pattern 'SCRIPT ERROR:|^ERROR:|^FAIL |TEST TIMEOUT' -Quiet)) {
        throw 'Falha no preview ou layout visual.'
    }
    $campaignLog = Join-Path $artifactPath 'campaign-tests.log'
    $campaignArgs = @('--path', ('"' + $gamePath + '"'), '--script', 'res://tests/test_campaign.gd', '--log-file', ('"' + $campaignLog + '"'))
    if (-not $Render) { $campaignArgs = @('--headless') + $campaignArgs }
    $campaignProcess = Start-Process -FilePath $godotPath -ArgumentList $campaignArgs -WindowStyle Hidden -Wait -PassThru
    Get-Content -LiteralPath $campaignLog
    if ($campaignProcess.ExitCode -ne 0 -or (Select-String -Path $campaignLog -Pattern 'SCRIPT ERROR:|^ERROR:|^FAIL |TEST TIMEOUT' -Quiet)) {
        throw 'Falha nos testes da campanha.'
    }
    $scoringLog = Join-Path $artifactPath 'scoring-tests.log'
    $scoringArgs = @('--path', ('"' + $gamePath + '"'), '--script', 'res://tests/test_scoring.gd', '--log-file', ('"' + $scoringLog + '"'))
    if (-not $Render) { $scoringArgs = @('--headless') + $scoringArgs }
    $scoringProcess = Start-Process -FilePath $godotPath -ArgumentList $scoringArgs -WindowStyle Hidden -Wait -PassThru
    Get-Content -LiteralPath $scoringLog
    if ($scoringProcess.ExitCode -ne 0 -or (Select-String -Path $scoringLog -Pattern 'SCRIPT ERROR:|^ERROR:|^FAIL |TEST TIMEOUT' -Quiet)) {
        throw 'Falha nos testes de pontuacao, carteira ou seasons.'
    }
    $v2Log = Join-Path $artifactPath 'visual-v2-tests.log'
    $v2Args = @('--path', ('"' + $gamePath + '"'), '--script', 'res://tests/test_visual_v2.gd', '--log-file', ('"' + $v2Log + '"'))
    if (-not $Render) { $v2Args = @('--headless') + $v2Args }
    $v2Process = Start-Process -FilePath $godotPath -ArgumentList $v2Args -WindowStyle Hidden -Wait -PassThru
    Get-Content -LiteralPath $v2Log
    if ($v2Process.ExitCode -ne 0 -or (Select-String -Path $v2Log -Pattern 'SCRIPT ERROR:|^ERROR:|^FAIL |TEST TIMEOUT' -Quiet)) {
        throw 'Falha nos testes de apresentacao v2.'
    }
    $referenceLog = Join-Path $artifactPath 'reference-ui-tests.log'
    $referenceArgs = @('--path', ('"' + $gamePath + '"'), '--script', 'res://tests/test_ui_reference.gd', '--log-file', ('"' + $referenceLog + '"'))
    if (-not $Render) { $referenceArgs = @('--headless') + $referenceArgs }
    $referenceProcess = Start-Process -FilePath $godotPath -ArgumentList $referenceArgs -WindowStyle Hidden -Wait -PassThru
    Get-Content -LiteralPath $referenceLog
    if ($referenceProcess.ExitCode -ne 0 -or (Select-String -Path $referenceLog -Pattern 'SCRIPT ERROR:|^ERROR:|^FAIL |REFERENCE TEST TIMEOUT' -Quiet)) {
        throw 'Falha na galeria, cores ou integracao da referencia visual.'
    }
    $shellLog = Join-Path $artifactPath 'shell-ui-tests.log'
    $shellArgs = @('--path', ('"' + $gamePath + '"'), '--script', 'res://tests/test_ui_shell.gd', '--log-file', ('"' + $shellLog + '"'))
    if (-not $Render) { $shellArgs = @('--headless') + $shellArgs }
    $shellProcess = Start-Process -FilePath $godotPath -ArgumentList $shellArgs -WindowStyle Hidden -Wait -PassThru
    Get-Content -LiteralPath $shellLog
    if ($shellProcess.ExitCode -ne 0 -or (Select-String -Path $shellLog -Pattern 'SCRIPT ERROR:|^ERROR:|^FAIL |SHELL TEST TIMEOUT' -Quiet)) {
        throw 'Falha na Home, Results ou sequencia de conclusao.'
    }
    Write-Host 'Validacao concluida. Relatorios em artifacts/.'
}
finally {
    Pop-Location
}
