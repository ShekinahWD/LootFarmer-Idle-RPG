[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('CreateKey', 'Check', 'Probe', 'Export', 'Install')]
    [string]$Action,
    [string]$Godot,
    [string]$JavaHome = 'D:\Programs\Eclipse Adoptium\jdk-17',
    [string]$AndroidSdk = 'D:\Android\Sdk',
    [string]$KeyStore = 'D:\OneDrive\GameDevolpment\AndroidKeyStores\LootFarmer-upload.keystore',
    [string]$DeviceSerial
)
$ErrorActionPreference = 'Stop'
$Project = Split-Path $PSScriptRoot -Parent
$Builds = Join-Path $Project 'builds'
$Apk = Join-Path $Builds 'LootFarmerIdleRPG.0.1.0.apk'
$AliasName = 'lootfarmer_upload'

function Require-File([string]$Path, [string]$Label) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Label missing: $Path"
    }
}
function Invoke-Checked([string]$Executable, [string[]]$Arguments) {
    # Do not pass signing passwords in Arguments. Native output is checked as well as exit status.
    $output = & $Executable @Arguments 2>&1
    $code = $LASTEXITCODE
    $output | ForEach-Object { Write-Host $_ }
    if ($code -ne 0 -or ($output | Select-String -Pattern 'SCRIPT ERROR:|Parse Error:|ERROR:')) {
        throw "Command failed validation (exit $code). Review output before continuing."
    }
}
function Get-SigningPassword {
    $secure = Read-Host 'Local keystore password (never saved in project)' -AsSecureString
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
}
if ($Action -eq 'CreateKey') {
    $keytool = Join-Path $JavaHome 'bin\keytool.exe'
    Require-File $keytool 'JDK keytool'
    if (Test-Path -LiteralPath $KeyStore) { throw 'Keystore already exists. It was not changed. Use Check next.' }
    $previousPassword = $env:LOOTFARMER_KEY_PASSWORD
    try {
        $env:LOOTFARMER_KEY_PASSWORD = Get-SigningPassword
        if ($env:LOOTFARMER_KEY_PASSWORD.Length -lt 8) { throw 'Choose a password of at least 8 characters.' }
        New-Item -ItemType Directory -Force -Path (Split-Path $KeyStore -Parent) | Out-Null
        Invoke-Checked $keytool @('-genkeypair', '-v', '-keystore', $KeyStore, '-alias', $AliasName,
            '-keyalg', 'RSA', '-keysize', '2048', '-validity', '10000',
            '-storepass:env', 'LOOTFARMER_KEY_PASSWORD', '-keypass:env', 'LOOTFARMER_KEY_PASSWORD',
            '-dname', 'CN=Yorki Oscar Bonilla Sanchez, OU=Game Development, O=Shekinah Weleful Designs, L=Santo Domingo Este, ST=Santo Domingo, C=DO')
        Write-Host 'Key created outside the project. Back it up securely. No signing material is included in the handoff.'
    } finally { $env:LOOTFARMER_KEY_PASSWORD = $previousPassword }
    exit 0
}
Require-File $Godot 'Godot console executable'
Invoke-Checked $Godot @('--version')
if ($Action -eq 'Check') {
    Require-File (Join-Path $JavaHome 'bin\java.exe') 'JDK'
    Require-File (Join-Path $AndroidSdk 'platform-tools\adb.exe') 'Android platform tools'
    Require-File $KeyStore 'Upload keystore (run CreateKey first)'
    Invoke-Checked (Join-Path $JavaHome 'bin\java.exe') @('-version')
    Invoke-Checked (Join-Path $AndroidSdk 'platform-tools\adb.exe') @('version')
    Write-Host 'Next: verify matching Godot export templates, configure JDK/SDK in Editor Settings, and install the Android Build Template. Check does not certify these steps.'
    exit 0
}
if ($Action -eq 'Probe') {
    Invoke-Checked $Godot @('--headless', '--path', $Project, '--editor', '--import', '--quit')
    Invoke-Checked $Godot @('--headless', '--path', $Project, 'res://tests/bootstrap_probe.tscn', '--', '--probe', '--no-autosave')
    Write-Host 'Probe completed. Next open the main scene for portrait/touch/layout inspection, then Export.'
    exit 0
}
if ($Action -eq 'Export') {
    Require-File $KeyStore 'Upload keystore'
    New-Item -ItemType Directory -Force -Path $Builds | Out-Null
    $previousPath = $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH
    $previousUser = $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER
    $previousPassword = $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
    try {
        $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $KeyStore
        $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $AliasName
        $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = Get-SigningPassword
        Invoke-Checked $Godot @('--headless', '--path', $Project, '--export-release', 'Android Bootstrap APK', $Apk)
        Require-File $Apk 'Exported APK'
        $signers = Get-ChildItem -Path (Join-Path $AndroidSdk 'build-tools') -Filter 'apksigner.bat' -Recurse |
            Sort-Object FullName -Descending | Select-Object -First 1
        if (-not $signers) { throw 'APK exported but apksigner not found; signature verification remains incomplete.' }
        Invoke-Checked $signers.FullName @('verify', '--verbose', '--print-certs', $Apk)
        Get-FileHash -Algorithm SHA256 -LiteralPath $Apk | Format-List
        Write-Host 'Export/signature checked. Physical installation and acceptance are still required.'
    } finally {
        $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $previousPath
        $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $previousUser
        $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $previousPassword
    }
    exit 0
}
if ($Action -eq 'Install') {
    Require-File $Apk 'Exported APK'
    $adb = Join-Path $AndroidSdk 'platform-tools\adb.exe'
    Require-File $adb 'ADB'
    if (-not $DeviceSerial) {
        & $adb devices
        throw 'Choose the intended device and rerun with -DeviceSerial. Nothing installed.'
    }
    Invoke-Checked $adb @('-s', $DeviceSerial, 'install', '-r', $Apk)
    Invoke-Checked $adb @('-s', $DeviceSerial, 'shell', 'monkey', '-p', 'com.shekinahwelefuldesigns.lootfarmeridlerpg', '-c', 'android.intent.category.LAUNCHER', '1')
    Write-Host 'Installed and launched. Complete the human device checklist; installation alone does not pass Checkpoint 0.'
}
