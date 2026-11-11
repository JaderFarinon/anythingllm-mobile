[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:USERPROFILE 'AppData\Local\Android\Sdk' }
$microsoftJdks = if (Test-Path 'C:\Program Files\Microsoft') {
    Get-ChildItem 'C:\Program Files\Microsoft' -Directory -Filter 'jdk-17*' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
}
$jdkCandidates = @(
    $env:JAVA_HOME,
    $microsoftJdks,
    'C:\Program Files\Android\Android Studio\jbr'
) | Where-Object { $_ -and (Test-Path (Join-Path $_ 'bin\javac.exe')) }

$jdk = $null
foreach ($candidate in $jdkCandidates) {
    $version = (& (Join-Path $candidate 'bin\javac.exe') -version 2>&1 | Out-String)
    if ($version -match '17\.') { $jdk = $candidate; break }
}
if (-not $jdk) {
    throw 'JDK 17 nao encontrado. Instale um JDK 17 e configure JAVA_HOME.'
}

$env:JAVA_HOME = $jdk
$env:ANDROID_HOME = $sdk
$env:ANDROID_SDK_ROOT = $sdk
$env:PATH = "$jdk\bin;$sdk\platform-tools;$sdk\emulator;$env:PATH"

$required = @(
    (Join-Path $sdk 'platform-tools\adb.exe'),
    (Join-Path $sdk 'platforms\android-36\android.jar'),
    (Join-Path $sdk 'build-tools\36.0.0\aapt.exe'),
    (Join-Path $sdk 'ndk\27.1.12297006\source.properties')
)
$missing = $required | Where-Object { -not (Test-Path -LiteralPath $_) }
if ($missing) {
    Write-Host 'Faltam componentes do Android SDK. No Android Studio, abra Tools > SDK Manager > SDK Platforms e instale Android API 36.' -ForegroundColor Yellow
    Write-Host 'Na aba SDK Tools, marque Android SDK Build-Tools 36.0.0, Android SDK Platform-Tools, Android Emulator e NDK (Side by side) 27.1.12297006.' -ForegroundColor Yellow
    Write-Host 'Caminho do SDK esperado: ' $sdk
    Write-Host 'Itens ainda ausentes:'
    $missing | ForEach-Object { Write-Host " - $_" }
    throw 'Instale os componentes listados no Android Studio e execute este script novamente.'
}

$adb = Join-Path $sdk 'platform-tools\adb.exe'
$emulator = Join-Path $sdk 'emulator\emulator.exe'
$devices = @(& $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\sdevice$' })
if (-not $devices) {
    $avds = @(& $emulator -list-avds 2>$null | Where-Object { $_.Trim() })
    if (-not $avds) {
        throw 'Nenhum dispositivo Android conectado e nenhum AVD configurado. Crie um em Tools > Device Manager no Android Studio ou conecte o telefone com depuracao USB.'
    }
    $avd = $avds[0].Trim()
    Write-Host "Iniciando emulador $avd..."
    Start-Process -FilePath $emulator -ArgumentList @('-avd', $avd) -WindowStyle Hidden
    $ready = $false
    for ($i = 0; $i -lt 90; $i++) {
        Start-Sleep -Seconds 2
        $devices = @(& $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\sdevice$' })
        if ($devices) {
            $serial = ($devices[0] -split '\s+')[0]
            if ((& $adb -s $serial shell getprop sys.boot_completed 2>$null | Out-String).Trim() -eq '1') { $ready = $true; break }
        }
    }
    if (-not $ready) { throw 'O emulador nao terminou de iniciar em 3 minutos. Verifique o Device Manager e tente novamente.' }
}

Set-Location $PSScriptRoot
yarn android
