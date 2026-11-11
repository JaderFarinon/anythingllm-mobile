[CmdletBinding()]
param(
    [ValidateSet('iniciar', 'parar', 'status')]
    [string]$Acao = 'iniciar'
)

$ErrorActionPreference = 'Stop'
$runtimeDir = Join-Path $env:TEMP 'anythingllm-mobile'
$pidFile = Join-Path $runtimeDir 'metro.pid'
$stdoutFile = Join-Path $runtimeDir 'metro.stdout.log'
$stderrFile = Join-Path $runtimeDir 'metro.stderr.log'

function Test-MetroRunning {
    $connection = Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort 8081 -State Listen -ErrorAction SilentlyContinue |
        Select-Object -First 1
    return $null -ne $connection
}

switch ($Acao) {
    'status' {
        if (Test-MetroRunning) {
            Write-Host 'Metro esta ativo em http://localhost:8081'
        } else {
            Write-Host 'Metro esta parado.'
        }
    }
    'parar' {
        if (Test-Path -LiteralPath $pidFile) {
            $metroPid = [int](Get-Content -LiteralPath $pidFile -Raw)
            $process = Get-Process -Id $metroPid -ErrorAction SilentlyContinue
            if ($process) { Stop-Process -Id $metroPid -Force }
            Remove-Item -LiteralPath $pidFile -Force
        }
        if (Test-MetroRunning) {
            Write-Host 'A porta 8081 continua ocupada por outro processo Metro.' -ForegroundColor Yellow
        } else {
            Write-Host 'Metro parado.'
        }
    }
    'iniciar' {
        if (Test-MetroRunning) {
            Write-Host 'Metro ja esta ativo em http://localhost:8081'
            break
        }

        $node = Get-Command node.exe -ErrorAction SilentlyContinue
        if (-not $node) { throw 'Node.js nao encontrado no PATH.' }
        $cli = Join-Path $PSScriptRoot 'node_modules/react-native/cli.js'
        if (-not (Test-Path -LiteralPath $cli)) { throw 'Dependencias ausentes. Execute yarn install nesta pasta.' }

        New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null
        $metro = Start-Process -FilePath $node.Source `
            -ArgumentList @($cli, 'start') `
            -WorkingDirectory $PSScriptRoot `
            -WindowStyle Hidden `
            -RedirectStandardOutput $stdoutFile `
            -RedirectStandardError $stderrFile `
            -PassThru
        Set-Content -LiteralPath $pidFile -Value $metro.Id -NoNewline

        Start-Sleep -Seconds 3
        if (Test-MetroRunning) {
            Write-Host 'Metro iniciado em http://localhost:8081'
            Write-Host 'Conecte um dispositivo Android via USB (depuracao USB ativada) ou inicie um emulador.'
        } else {
            $details = if (Test-Path -LiteralPath $stderrFile) { Get-Content -LiteralPath $stderrFile -Tail 20 } else { @() }
            $process = Get-Process -Id $metro.Id -ErrorAction SilentlyContinue
            if ($process) { Stop-Process -Id $metro.Id -Force }
            Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
            throw "Metro nao iniciou. Consulte $stderrFile`n$($details -join "`n")"
        }
    }
}
