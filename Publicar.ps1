param(
    [string]$Mensagem = 'Atualiza Machidoku',
    [string]$Repositorio = 'vinicinotti/Machidoku',
    [switch]$Preparar
)
$ErrorActionPreference = 'Stop'
$taskPython = Join-Path $PSScriptRoot '.venv/Scripts/python.exe'
if (-not (Test-Path -LiteralPath $taskPython)) {
    $taskPython = (Get-Command python -ErrorAction Stop).Source
}
$taskArgs = @((Join-Path $PSScriptRoot 'tools/publish/publish.py'), '--repository', $Repositorio, '--message', $Mensagem)
if ($Preparar) { $taskArgs += '--prepare-only' }
& $taskPython @taskArgs
exit $LASTEXITCODE
