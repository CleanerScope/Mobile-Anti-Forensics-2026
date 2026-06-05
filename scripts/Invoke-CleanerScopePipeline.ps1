[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath,

    [ValidateSet('Rooted', 'NonRoot')]
    [string]$Mode = 'Rooted',

    [ValidateSet('Full', 'Reset', 'PushData', 'Install', 'Launch', 'PhaseA', 'PhaseB', 'PhaseC', 'PhaseD')]
    [string]$Action = 'Full'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

function Load-Config {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        throw "Config file not found: $Path"
    }

    return Get-Content $Path -Raw | ConvertFrom-Json
}

function Write-Status {
    param([string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "[$timestamp] $Message"
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Convert-ToShellAccessiblePath {
    param([string]$Path)

    if ($Path -like '/storage/emulated/0*') {
        return $Path -replace '^/storage/emulated/0', '/sdcard'
    }
    return $Path
}

function Get-BranchRoot {
    param($Config, [string]$Branch)

    $appRoot = Join-Path $Config.captureRoot $Config.captureDirName
    $branchRoot = Join-Path $appRoot $Branch
    Ensure-Directory $appRoot
    Ensure-Directory $branchRoot
    return @{
        AppRoot = $appRoot
        BranchRoot = $branchRoot
        Findings = Join-Path $appRoot 'Findings.txt'
    }
}

function Initialize-Findings {
    param($Config, [hashtable]$Paths)

    if (-not (Test-Path $Paths.Findings)) {
        @(
            "$($Config.displayName) ($($Config.packageName)) Findings"
            ''
            'Structure'
            '- Rooted captures: Rooted\'
            '- Non-root captures: NonRoot\'
            ''
        ) | Set-Content $Paths.Findings
    }
}

function Append-Findings {
    param(
        [hashtable]$Paths,
        [string]$SectionTitle,
        [string[]]$Lines
    )

    Add-Content $Paths.Findings ''
    Add-Content $Paths.Findings $SectionTitle
    Add-Content $Paths.Findings ('=' * $SectionTitle.Length)
    foreach ($line in $Lines) {
        Add-Content $Paths.Findings $line
    }
}

function Get-AdbPrefix {
    param($Config)

    $prefix = @()
    if ($Config.adbPath -and $Config.adbPath.Trim()) {
        $prefix += $Config.adbPath
    } else {
        $prefix += 'adb'
    }

    if ($Config.deviceSerial -and $Config.deviceSerial.Trim()) {
        $prefix += @('-s', $Config.deviceSerial)
    }

    return ,$prefix
}

function Invoke-Adb {
    param(
        $Config,
        [string[]]$Arguments,
        [switch]$AllowFailure
    )

    $cmd = Get-AdbPrefix $Config
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        if ($cmd.Length -gt 1) {
            $output = & $cmd[0] $cmd[1..($cmd.Length - 1)] @Arguments 2>&1
        } else {
            $output = & $cmd[0] @Arguments 2>&1
        }
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    $exitCode = $LASTEXITCODE
    if (-not $AllowFailure -and $exitCode -ne 0) {
        throw "adb $($Arguments -join ' ') failed with exit code $exitCode.`n$output"
    }
    return ($output | Out-String).TrimEnd()
}

function Save-AdbOutput {
    param(
        $Config,
        [string]$FilePath,
        [string[]]$Arguments,
        [switch]$AllowFailure
    )

    $output = Invoke-Adb -Config $Config -Arguments $Arguments -AllowFailure:$AllowFailure
    $output | Set-Content $FilePath
    return $output
}

function Wait-For-DeviceReady {
    param($Config)

    Invoke-Adb -Config $Config -Arguments @('wait-for-device') | Out-Null
    for ($i = 0; $i -lt 30; $i++) {
        try {
            $whoami = Invoke-Adb -Config $Config -Arguments @('shell', 'whoami')
            if ($whoami) {
                return
            }
        } catch {
            Start-Sleep -Seconds 2
        }
    }
    throw 'Device did not become ready in time.'
}

function Wait-For-UserUnlocked {
    param($Config)

    Start-Sleep -Seconds 20
}

function Set-RootMode {
    param($Config, [bool]$EnableRoot)

    if ($EnableRoot) {
        Write-Status 'Switching adb to root mode.'
        Invoke-Adb -Config $Config -Arguments @('root') -AllowFailure | Out-Null
        Wait-For-DeviceReady -Config $Config
        Wait-For-UserUnlocked -Config $Config
    } else {
        Write-Status 'Switching adb to non-root mode.'
        Invoke-Adb -Config $Config -Arguments @('unroot') -AllowFailure | Out-Null
        Wait-For-DeviceReady -Config $Config
        Wait-For-UserUnlocked -Config $Config
    }
}

function Remove-RemoteContents {
    param($Config, [string]$RemotePath)

    Invoke-Adb -Config $Config -Arguments @('shell', 'sh', '-c', "rm -rf '$RemotePath'/* '$RemotePath'/.* 2>/dev/null || true") -AllowFailure | Out-Null
}

function Reset-Baseline {
    param($Config)

    Set-RootMode -Config $Config -EnableRoot $false
    Wait-For-DeviceReady -Config $Config
    Wait-For-UserUnlocked -Config $Config
    Write-Status 'Resetting package state.'
    Invoke-Adb -Config $Config -Arguments @('uninstall', $Config.packageName) -AllowFailure | Out-Null

    Write-Status 'Clearing shared storage test locations.'
    foreach ($path in $Config.sharedStorageTargets.PSObject.Properties.Value) {
        $shellPath = Convert-ToShellAccessiblePath $path
        Invoke-Adb -Config $Config -Arguments @('shell', 'mkdir', '-p', $shellPath) -AllowFailure | Out-Null
        Remove-RemoteContents -Config $Config -RemotePath $shellPath
    }

    foreach ($path in $Config.resetExtraSharedPaths) {
        Invoke-Adb -Config $Config -Arguments @('shell', 'rm', '-rf', $path) -AllowFailure | Out-Null
    }

    if ($Config.useRootForReset) {
        Set-RootMode -Config $Config -EnableRoot $true
        foreach ($sysPath in $Config.rootResetPaths) {
            Remove-RemoteContents -Config $Config -RemotePath $sysPath
        }
        Invoke-Adb -Config $Config -Arguments @('reboot') | Out-Null
        Wait-For-DeviceReady -Config $Config
        Wait-For-UserUnlocked -Config $Config
        if ($Mode -eq 'NonRoot') {
            Set-RootMode -Config $Config -EnableRoot $false
        }
    }
}

function Push-Dataset {
    param($Config)

    Set-RootMode -Config $Config -EnableRoot $false
    Write-Status 'Pushing test dataset.'
    foreach ($datasetEntry in $Config.datasetMap.PSObject.Properties) {
        $source = Join-Path $Config.datasetRoot $datasetEntry.Name
        $target = $datasetEntry.Value
        $shellTarget = Convert-ToShellAccessiblePath $target
        Invoke-Adb -Config $Config -Arguments @('shell', 'mkdir', '-p', $shellTarget) | Out-Null
        Invoke-Adb -Config $Config -Arguments @('push', $source, $shellTarget) | Out-Null
    }
}

function Install-App {
    param($Config)

    Set-RootMode -Config $Config -EnableRoot $false
    Write-Status "Installing APK: $($Config.apkPath)"
    Invoke-Adb -Config $Config -Arguments @('install', '-r', $Config.apkPath) | Out-Null
}

function Launch-App {
    param($Config)

    Set-RootMode -Config $Config -EnableRoot $false
    if (-not $Config.mainActivity) {
        Write-Status 'No mainActivity configured. Skipping direct launch.'
        return
    }

    $component = "$($Config.packageName)/$($Config.mainActivity)"
    Write-Status "Launching $component"
    Invoke-Adb -Config $Config -Arguments @('shell', 'am', 'start', '-n', $component) -AllowFailure | Out-Null
}

function New-PhaseFolder {
    param([hashtable]$Paths, [string]$Name)

    $phaseDir = Join-Path $Paths.BranchRoot $Name
    Ensure-Directory $phaseDir
    return $phaseDir
}

function Pull-RootedLogicalArtifacts {
    param(
        $Config,
        [string]$PhaseDir
    )

    Save-AdbOutput -Config $Config -FilePath (Join-Path $PhaseDir '00_shell_user.txt') -Arguments @('shell', 'whoami') | Out-Null
    Save-AdbOutput -Config $Config -FilePath (Join-Path $PhaseDir '01_package.txt') -Arguments @('shell', 'dumpsys', 'package', $Config.packageName) -AllowFailure | Out-Null
    Save-AdbOutput -Config $Config -FilePath (Join-Path $PhaseDir '02_app_files.txt') -Arguments @('shell', 'sh', '-c', "find '/data/data/$($Config.packageName)' -maxdepth 4 -type f 2>/dev/null | sort") -AllowFailure | Out-Null

    $appPrivateDir = Join-Path $PhaseDir 'app_private'
    Ensure-Directory $appPrivateDir
    foreach ($subDir in $Config.rootAppPrivateSubdirs) {
        $remote = "/data/data/$($Config.packageName)/$subDir"
        $local = Join-Path $appPrivateDir $subDir
        Invoke-Adb -Config $Config -Arguments @('pull', $remote, $local) -AllowFailure | Out-Null
    }

    $recentTasksDir = Join-Path $PhaseDir 'recent_tasks'
    $snapshotsDir = Join-Path $PhaseDir 'snapshots'
    $usageStatsDir = Join-Path $PhaseDir 'usage_stats'
    Ensure-Directory $recentTasksDir
    Ensure-Directory $snapshotsDir
    Ensure-Directory $usageStatsDir

    Invoke-Adb -Config $Config -Arguments @('pull', '/data/system_ce/0/recent_tasks', $recentTasksDir) -AllowFailure | Out-Null
    Invoke-Adb -Config $Config -Arguments @('pull', '/data/system_ce/0/snapshots', $snapshotsDir) -AllowFailure | Out-Null
    Invoke-Adb -Config $Config -Arguments @('pull', '/data/system/usagestats/0', $usageStatsDir) -AllowFailure | Out-Null

    foreach ($extraPull in $Config.additionalRootPulls) {
        $local = Join-Path $PhaseDir $extraPull.localName
        Ensure-Directory $local
        Invoke-Adb -Config $Config -Arguments @('pull', $extraPull.devicePath, $local) -AllowFailure | Out-Null
    }

    Save-AdbOutput -Config $Config -FilePath (Join-Path $PhaseDir '11_supplemental_dumpsys_usagestats.txt') -Arguments @('shell', 'dumpsys', 'usagestats') -AllowFailure | Out-Null
    Save-AppFilteredHits -InputPath (Join-Path $PhaseDir '11_supplemental_dumpsys_usagestats.txt') -OutputPath (Join-Path $PhaseDir '12_supplemental_dumpsys_usagestats_hits.txt') -Patterns @($Config.packageName, 'Shredding', 'shred', 'wipe')
}

function Save-AppFilteredHits {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [string[]]$Patterns
    )

    if (-not (Test-Path $InputPath)) {
        '' | Set-Content $OutputPath
        return
    }

    $regex = ($Patterns | ForEach-Object { [Regex]::Escape($_) }) -join '|'
    Select-String -Path $InputPath -Pattern $regex -SimpleMatch:$false | ForEach-Object {
        $_.Line
    } | Set-Content $OutputPath
}

function Capture-LogcatPhase {
    param(
        $Config,
        [hashtable]$Paths,
        [string]$PhaseFolderName
    )

    $phaseDir = New-PhaseFolder -Paths $Paths -Name $PhaseFolderName
    Write-Status "Capturing logcat into $phaseDir"
    Save-AdbOutput -Config $Config -FilePath (Join-Path $phaseDir '01_logcat_full_dump_afterwipe.txt') -Arguments @('logcat', '-d') -AllowFailure | Out-Null
    Save-AppFilteredHits -InputPath (Join-Path $phaseDir '01_logcat_full_dump_afterwipe.txt') -OutputPath (Join-Path $phaseDir '04_logcat_hits_afterwipe.txt') -Patterns @($Config.packageName, 'sdel', 'shred', 'wipe', 'Delete', 'dummy')
    return $phaseDir
}

function Capture-NonRootDumpsysPhase {
    param(
        $Config,
        [string]$PhaseDir
    )

    Save-AdbOutput -Config $Config -FilePath (Join-Path $PhaseDir '01_dumpsys_usagestats.txt') -Arguments @('shell', 'dumpsys', 'usagestats') -AllowFailure | Out-Null
    Save-AdbOutput -Config $Config -FilePath (Join-Path $PhaseDir '02_dumpsys_activity_recents.txt') -Arguments @('shell', 'dumpsys', 'activity', 'recents') -AllowFailure | Out-Null
    Save-AdbOutput -Config $Config -FilePath (Join-Path $PhaseDir '03_dumpsys_activity_activities.txt') -Arguments @('shell', 'dumpsys', 'activity', 'activities') -AllowFailure | Out-Null
    Save-AdbOutput -Config $Config -FilePath (Join-Path $PhaseDir '04_dumpsys_package.txt') -Arguments @('shell', 'dumpsys', 'package', $Config.packageName) -AllowFailure | Out-Null
    Save-AdbOutput -Config $Config -FilePath (Join-Path $PhaseDir '05_dumpsys_procstats.txt') -Arguments @('shell', 'dumpsys', 'procstats') -AllowFailure | Out-Null
    Save-AdbOutput -Config $Config -FilePath (Join-Path $PhaseDir '06_dumpsys_meminfo.txt') -Arguments @('shell', 'dumpsys', 'meminfo', $Config.packageName) -AllowFailure | Out-Null
    Save-AdbOutput -Config $Config -FilePath (Join-Path $PhaseDir '07_dumpsys_batterystats.txt') -Arguments @('shell', 'dumpsys', 'batterystats') -AllowFailure | Out-Null
    Save-AdbOutput -Config $Config -FilePath (Join-Path $PhaseDir '08_snapshots_probe.txt') -Arguments @('shell', 'ls', '/data/system_ce/0/snapshots') -AllowFailure | Out-Null

    Save-AppFilteredHits -InputPath (Join-Path $PhaseDir '01_dumpsys_usagestats.txt') -OutputPath (Join-Path $PhaseDir '20_hits_usagestats_app.txt') -Patterns @($Config.packageName, $Config.activityKeyword)
    Save-AppFilteredHits -InputPath (Join-Path $PhaseDir '02_dumpsys_activity_recents.txt') -OutputPath (Join-Path $PhaseDir '21_hits_recents_app.txt') -Patterns @($Config.packageName, $Config.activityKeyword)
    Save-AppFilteredHits -InputPath (Join-Path $PhaseDir '03_dumpsys_activity_activities.txt') -OutputPath (Join-Path $PhaseDir '22_hits_activities_app.txt') -Patterns @($Config.packageName, $Config.activityKeyword)
    Save-AppFilteredHits -InputPath (Join-Path $PhaseDir '04_dumpsys_package.txt') -OutputPath (Join-Path $PhaseDir '23_hits_package_app.txt') -Patterns @($Config.packageName, 'dataDir', 'versionName', 'versionCode', 'Unable to find package')
    Save-AppFilteredHits -InputPath (Join-Path $PhaseDir '05_dumpsys_procstats.txt') -OutputPath (Join-Path $PhaseDir '25_hits_procstats_app.txt') -Patterns @($Config.packageName)
    Save-AppFilteredHits -InputPath (Join-Path $PhaseDir '07_dumpsys_batterystats.txt') -OutputPath (Join-Path $PhaseDir '26_hits_batterystats_app.txt') -Patterns @($Config.packageName)
}

function Count-Dataset {
    param($Config)

    $results = @()
    foreach ($entry in $Config.sharedStorageTargets.PSObject.Properties) {
        $folder = Convert-ToShellAccessiblePath $entry.Value
        $count = Invoke-Adb -Config $Config -Arguments @('shell', 'sh', '-c', "find '$folder' -type f 2>/dev/null | wc -l") -AllowFailure
        $results += "- $($entry.Name) = $count"
    }
    return $results
}

function Run-PhaseA {
    param($Config, [hashtable]$Paths)

    $phaseDir = New-PhaseFolder -Paths $Paths -Name 'PhaseA_Baseline'
    if ($Mode -eq 'Rooted') {
        Set-RootMode -Config $Config -EnableRoot $true
        Pull-RootedLogicalArtifacts -Config $Config -PhaseDir $phaseDir
    } else {
        Set-RootMode -Config $Config -EnableRoot $false
        Capture-NonRootDumpsysPhase -Config $Config -PhaseDir $phaseDir
    }

    Append-Findings -Paths $Paths -SectionTitle "Phase A $Mode" -Lines @(
        "Capture folder: $phaseDir"
        "Package: $($Config.packageName)"
        "VersionName: $($Config.expectedVersionName)"
        "VersionCode: $($Config.expectedVersionCode)"
    )
}

function Run-PhaseB {
    param($Config, [hashtable]$Paths)

    $logcatDir = Capture-LogcatPhase -Config $Config -Paths $Paths -PhaseFolderName 'PhaseB_PostClean_Logcat'
    $phaseDir = New-PhaseFolder -Paths $Paths -Name 'PhaseB_PostClean'

    if ($Mode -eq 'Rooted') {
        Set-RootMode -Config $Config -EnableRoot $true
        Pull-RootedLogicalArtifacts -Config $Config -PhaseDir $phaseDir
    } else {
        Set-RootMode -Config $Config -EnableRoot $false
        Capture-NonRootDumpsysPhase -Config $Config -PhaseDir $phaseDir
    }

    Append-Findings -Paths $Paths -SectionTitle "Phase B $Mode" -Lines @(
        "Logcat folder: $logcatDir"
        "Capture folder: $phaseDir"
    )
}

function Run-PhaseC {
    param($Config, [hashtable]$Paths)

    Write-Status 'Uninstalling app for Phase C.'
    Invoke-Adb -Config $Config -Arguments @('uninstall', $Config.packageName) -AllowFailure | Out-Null
    $phaseDir = New-PhaseFolder -Paths $Paths -Name 'PhaseC_PostUninstall'

    if ($Mode -eq 'Rooted') {
        Set-RootMode -Config $Config -EnableRoot $true
        Pull-RootedLogicalArtifacts -Config $Config -PhaseDir $phaseDir
    } else {
        Set-RootMode -Config $Config -EnableRoot $false
        Capture-NonRootDumpsysPhase -Config $Config -PhaseDir $phaseDir
    }

    Append-Findings -Paths $Paths -SectionTitle "Phase C $Mode" -Lines @(
        "Capture folder: $phaseDir"
        "Package uninstall attempted for: $($Config.packageName)"
    )
}

function Run-PhaseD {
    param($Config, [hashtable]$Paths)

    Write-Status 'Rebooting device for Phase D.'
    Invoke-Adb -Config $Config -Arguments @('reboot') | Out-Null
    Wait-For-DeviceReady -Config $Config
    Wait-For-UserUnlocked -Config $Config

    if ($Mode -eq 'NonRoot') {
        Set-RootMode -Config $Config -EnableRoot $false
    } else {
        Set-RootMode -Config $Config -EnableRoot $true
    }

    $phaseDir = New-PhaseFolder -Paths $Paths -Name 'PhaseD_PostRestart'
    if ($Mode -eq 'Rooted') {
        Pull-RootedLogicalArtifacts -Config $Config -PhaseDir $phaseDir
    } else {
        Capture-NonRootDumpsysPhase -Config $Config -PhaseDir $phaseDir
    }

    Append-Findings -Paths $Paths -SectionTitle "Phase D $Mode" -Lines @(
        "Capture folder: $phaseDir"
        'Capture performed after reboot and device-ready wait.'
    )
}

function Run-FullPipeline {
    param($Config, [hashtable]$Paths)

    Reset-Baseline -Config $Config
    Push-Dataset -Config $Config
    Install-App -Config $Config
    Launch-App -Config $Config
    Run-PhaseA -Config $Config -Paths $Paths

    Invoke-Adb -Config $Config -Arguments @('logcat', '-c') -AllowFailure | Out-Null
    Read-Host 'Perform the wipe in the app, then press Enter to capture Phase B'

    Run-PhaseB -Config $Config -Paths $Paths
    Run-PhaseC -Config $Config -Paths $Paths
    Run-PhaseD -Config $Config -Paths $Paths
}

$config = Load-Config -Path $ConfigPath
$defaultArrayProps = @{
    resetExtraSharedPaths = @()
    rootResetPaths = @()
    rootAppPrivateSubdirs = @('shared_prefs', 'databases', 'files', 'cache')
    additionalRootPulls = @()
}
foreach ($prop in $defaultArrayProps.Keys) {
    if (-not $config.PSObject.Properties.Name.Contains($prop) -or $null -eq $config.$prop) {
        $config | Add-Member -NotePropertyName $prop -NotePropertyValue $defaultArrayProps[$prop] -Force
    }
}
$requiredRootAppPrivateSubdirs = @('shared_prefs', 'databases', 'files')
foreach ($subDir in $requiredRootAppPrivateSubdirs) {
    if ($config.rootAppPrivateSubdirs -notcontains $subDir) {
        $config.rootAppPrivateSubdirs += $subDir
    }
}
$optionalScalarProps = @{
    adbPath = 'adb'
    activityKeyword = 'Activity'
}
foreach ($key in $optionalScalarProps.Keys) {
    if (-not $config.PSObject.Properties.Name.Contains($key) -or [string]::IsNullOrWhiteSpace([string]$config.$key)) {
        $config | Add-Member -NotePropertyName $key -NotePropertyValue $optionalScalarProps[$key] -Force
    }
}
$branch = if ($Mode -eq 'Rooted') { 'Rooted' } else { 'NonRoot' }
$paths = Get-BranchRoot -Config $config -Branch $branch
Initialize-Findings -Config $config -Paths $paths

switch ($Action) {
    'Reset'   { Reset-Baseline -Config $config }
    'PushData'{ Push-Dataset -Config $config }
    'Install' { Install-App -Config $config }
    'Launch'  { Launch-App -Config $config }
    'PhaseA'  { Run-PhaseA -Config $config -Paths $paths }
    'PhaseB'  { Run-PhaseB -Config $config -Paths $paths }
    'PhaseC'  { Run-PhaseC -Config $config -Paths $paths }
    'PhaseD'  { Run-PhaseD -Config $config -Paths $paths }
    'Full'    { Run-FullPipeline -Config $config -Paths $paths }
    default   { throw "Unsupported action: $Action" }
}

Write-Status 'Done.'
