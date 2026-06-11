[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CapturePath,

    [string]$OutputPath,

    [switch]$Pretty
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-PackageRoot {
    param([string]$ScriptPath)
    return Split-Path -Parent $ScriptPath
}

function Get-RepoRoot {
    param([string]$ScriptPath)
    return Split-Path -Parent (Get-PackageRoot -ScriptPath $ScriptPath)
}

function Read-Csv {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        throw "Required CSV not found: $Path"
    }
    return Import-Csv -Path $Path
}

function Get-RelativePathSafe {
    param(
        [string]$BasePath,
        [string]$TargetPath
    )

    try {
        $baseResolved = (Resolve-Path $BasePath).Path
        $targetResolved = (Resolve-Path $TargetPath).Path
        $uriBase = New-Object System.Uri(($baseResolved.TrimEnd('\') + '\'))
        $uriTarget = New-Object System.Uri($targetResolved)
        return [System.Uri]::UnescapeDataString($uriBase.MakeRelativeUri($uriTarget).ToString()) -replace '/', '\'
    } catch {
        return $TargetPath
    }
}

function Get-XmlPreferenceValues {
    param(
        [string]$Path,
        [string[]]$Keys
    )

    $result = @{}
    if (-not (Test-Path $Path)) {
        return $result
    }

    try {
        [xml]$xml = Get-Content -Path $Path -Raw
        foreach ($node in $xml.map.ChildNodes) {
            if ($null -eq $node.Attributes) { continue }
            $nameAttr = $node.Attributes['name']
            if ($null -eq $nameAttr) { continue }
            $name = $nameAttr.Value
            if ($Keys -contains $name) {
                $valueAttr = $node.Attributes['value']
                if ($null -ne $valueAttr) {
                    $result[$name] = $valueAttr.Value
                } else {
                    $result[$name] = $node.InnerText
                }
            }
        }
    } catch {
        throw "Failed to parse XML preferences file: $Path`n$($_.Exception.Message)"
    }

    return $result
}

function Find-ArtifactFile {
    param(
        [string]$Root,
        [string[]]$CandidateNames
    )

    foreach ($name in $CandidateNames) {
        $match = Get-ChildItem -Path $Root -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -eq $name } |
            Select-Object -First 1
        if ($null -ne $match) {
            return $match.FullName
        }
    }
    return $null
}

function New-Record {
    param(
        [string]$App,
        [string]$Package,
        [string]$VersionName,
        [string]$VersionCode,
        [string]$ArtifactPath,
        [object]$RawValue,
        [string]$EvidenceClass,
        [string]$MappedLabel,
        [string]$ImplementationNote,
        [hashtable]$AdditionalFields
    )

    $ordered = [ordered]@{
        app = $App
        package = $Package
        version_name = $VersionName
        version_code = $VersionCode
        artifact_path = $ArtifactPath
        raw_value = $RawValue
        evidence_class = $EvidenceClass
        mapped_label = $MappedLabel
        implementation_note = $ImplementationNote
    }

    if ($null -ne $AdditionalFields) {
        foreach ($key in $AdditionalFields.Keys) {
            $ordered[$key] = $AdditionalFields[$key]
        }
    }

    return [pscustomobject]$ordered
}

function Get-MappingLabel {
    param(
        [object[]]$Mappings,
        [string]$AppName,
        [string]$RecoveredKey,
        [string]$RecoveredValue
    )

    $row = $Mappings |
        Where-Object {
            $_.app_name -eq $AppName -and
            $_.recovered_key -eq $RecoveredKey -and
            $_.recovered_value -eq $RecoveredValue
        } |
        Select-Object -First 1

    if ($null -eq $row) {
        return $null
    }

    return @{
        Label = $row.mapped_method_or_configuration
        EvidenceClass = $row.evidence_class
        ImplementationNote = $row.implementation_note
    }
}

function Get-FallbackValue {
    param(
        [AllowNull()]$Primary,
        $Fallback
    )

    if ($null -ne $Primary -and "$Primary" -ne '') {
        return $Primary
    }
    return $Fallback
}

function Normalize-StudyToken {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) { return '' }
    return (($Value -replace '[^A-Za-z0-9]', '')).ToLowerInvariant()
}

function Get-CaptureHintRow {
    param(
        [string]$CapturePath,
        [object[]]$Manifest
    )

    $normalizedPath = Normalize-StudyToken -Value $CapturePath
    if (-not $normalizedPath) { return $null }

    $scored = foreach ($row in $Manifest) {
        $appToken = Normalize-StudyToken -Value $row.app_name
        $packageToken = Normalize-StudyToken -Value $row.package_name

        $score = 0
        if ($appToken -and $normalizedPath.Contains($appToken)) {
            $score = [Math]::Max($score, $appToken.Length)
        }
        if ($packageToken -and $normalizedPath.Contains($packageToken)) {
            $score = [Math]::Max($score, $packageToken.Length)
        }

        if ($score -gt 0) {
            [pscustomobject]@{
                score = $score
                row = $row
            }
        }
    }

    return $scored |
        Sort-Object -Property score -Descending |
        Select-Object -ExpandProperty row -First 1
}

function Extract-AndroidEraser {
    param($ManifestRow, [string]$Root, [object[]]$Mappings)
    $file = Find-ArtifactFile -Root $Root -CandidateNames @('com.cbinnovations.androideraser.xml')
    if (-not $file) { return $null }

    $values = Get-XmlPreferenceValues -Path $file -Keys @('cb_default_method', 'savekey_reports')
    $rawValue = $null
    $methodLabel = $null

    if ($values.ContainsKey('savekey_reports')) {
        $rawValue = 'savekey_reports.method'
        if ($values['savekey_reports'] -match '"mValue"\s*:\s*"([^"]+)"') {
            $methodLabel = $Matches[1]
        }
    } elseif ($values.ContainsKey('cb_default_method')) {
        $rawValue = 'cb_default_method'
        if ($values['cb_default_method'] -match '"mValue"\s*:\s*"([^"]+)"') {
            $methodLabel = $Matches[1]
        }
    } else {
        return $null
    }

    return New-Record `
        -App $ManifestRow.app_name `
        -Package $ManifestRow.package_name `
        -VersionName $ManifestRow.version_name `
        -VersionCode $ManifestRow.version_code `
        -ArtifactPath (Get-RelativePathSafe -BasePath $Root -TargetPath $file) `
        -RawValue $rawValue `
        -EvidenceClass 'direct_dynamic_method_evidence' `
        -MappedLabel $methodLabel `
        -ImplementationNote 'Direct stored method object or report field; no selector mapping required' `
        -AdditionalFields @{
            extracted_from = @($values.Keys)
        }
}

function Extract-AndroShredder {
    param($ManifestRow, [string]$Root, [object[]]$Mappings)
    $file = Find-ArtifactFile -Root $Root -CandidateNames @('MainActivity.xml')
    if (-not $file) { return $null }

    $values = Get-XmlPreferenceValues -Path $file -Keys @('shredIntensity', 'wipeIntensity')
    if (-not $values.ContainsKey('shredIntensity')) { return $null }
    $rawValue = [string]$values['shredIntensity']
    $mapped = Get-MappingLabel -Mappings $Mappings -AppName $ManifestRow.app_name -RecoveredKey 'shredIntensity' -RecoveredValue $rawValue
    $evidenceClass = Get-FallbackValue -Primary ($mapped.EvidenceClass) -Fallback 'mapped_dynamic_method_evidence'
    $mappedLabel = Get-FallbackValue -Primary ($mapped.Label) -Fallback $null
    $implementationNote = Get-FallbackValue -Primary ($mapped.ImplementationNote) -Fallback 'Selector requires static mapping'

    return New-Record `
        -App $ManifestRow.app_name `
        -Package $ManifestRow.package_name `
        -VersionName $ManifestRow.version_name `
        -VersionCode $ManifestRow.version_code `
        -ArtifactPath (Get-RelativePathSafe -BasePath $Root -TargetPath $file) `
        -RawValue $rawValue `
        -EvidenceClass $evidenceClass `
        -MappedLabel $mappedLabel `
        -ImplementationNote $implementationNote `
        -AdditionalFields @{
            recovered_key = 'shredIntensity'
            wipe_intensity = $values['wipeIntensity']
        }
}

function Extract-IShredder {
    param($ManifestRow, [string]$Root, [object[]]$Mappings)
    $file = Find-ArtifactFile -Root $Root -CandidateNames @('com.projectstar.ishredder.android.standard_preferences.xml','Reports.xml')
    if (-not $file) { return $null }

    $raw = Get-Content -Path $file -Raw
    $rawValue = $null
    if ($raw -match 'ishredder_default_method') {
        $rawValue = 'ishredder_default_method'
    } elseif ($raw -match 'reports_v2' -or $raw -match 'savekey_reports') {
        $rawValue = 'report artifact present'
    } else {
        $rawValue = 'method artifact present'
    }

    $mappedLabel = $null
    if ($raw -match 'mValue[^A-Za-z0-9_]*([A-Za-z0-9_]+)') {
        $mappedLabel = $Matches[1]
    }

    return New-Record `
        -App $ManifestRow.app_name `
        -Package $ManifestRow.package_name `
        -VersionName $ManifestRow.version_name `
        -VersionCode $ManifestRow.version_code `
        -ArtifactPath (Get-RelativePathSafe -BasePath $Root -TargetPath $file) `
        -RawValue $rawValue `
        -EvidenceClass 'direct_dynamic_method_evidence' `
        -MappedLabel $mappedLabel `
        -ImplementationNote 'Direct stored method object or report-bearing artifact; no selector mapping required' `
        -AdditionalFields @{
            artifact_type = [System.IO.Path]::GetFileName($file)
        }
}

function Extract-Shredder {
    param($ManifestRow, [string]$Root, [object[]]$Mappings)
    $file = Find-ArtifactFile -Root $Root -CandidateNames @('com.trictech.shred_preferences.xml')
    if (-not $file) { return $null }
    $values = Get-XmlPreferenceValues -Path $file -Keys @('algorithm','type')
    if (-not $values.ContainsKey('algorithm')) { return $null }
    $rawValue = [string]$values['algorithm']
    $mapped = Get-MappingLabel -Mappings $Mappings -AppName $ManifestRow.app_name -RecoveredKey 'algorithm' -RecoveredValue $rawValue
    $evidenceClass = Get-FallbackValue -Primary ($mapped.EvidenceClass) -Fallback 'direct_dynamic_method_evidence'
    $mappedLabel = Get-FallbackValue -Primary ($mapped.Label) -Fallback $rawValue
    $implementationNote = Get-FallbackValue -Primary ($mapped.ImplementationNote) -Fallback 'Direct stored algorithm label'

    return New-Record `
        -App $ManifestRow.app_name `
        -Package $ManifestRow.package_name `
        -VersionName $ManifestRow.version_name `
        -VersionCode $ManifestRow.version_code `
        -ArtifactPath (Get-RelativePathSafe -BasePath $Root -TargetPath $file) `
        -RawValue $rawValue `
        -EvidenceClass $evidenceClass `
        -MappedLabel $mappedLabel `
        -ImplementationNote $implementationNote `
        -AdditionalFields @{
            mode_type = $values['type']
        }
}

function Extract-Shreddit {
    param($ManifestRow, [string]$Root, [object[]]$Mappings)
    $file = Find-ArtifactFile -Root $Root -CandidateNames @('com.palmtronix.shreddit.v1_preferences.xml')
    if (-not $file) { return $null }
    $values = Get-XmlPreferenceValues -Path $file -Keys @('shred.algo','number_of_passes','secureDeletedMode')
    if (-not $values.ContainsKey('shred.algo')) { return $null }
    $rawValue = [string]$values['shred.algo']
    $mapped = Get-MappingLabel -Mappings $Mappings -AppName $ManifestRow.app_name -RecoveredKey 'shred.algo' -RecoveredValue $rawValue
    $evidenceClass = Get-FallbackValue -Primary ($mapped.EvidenceClass) -Fallback 'direct_dynamic_method_evidence'
    $mappedLabel = Get-FallbackValue -Primary ($mapped.Label) -Fallback $rawValue
    $implementationNote = Get-FallbackValue -Primary ($mapped.ImplementationNote) -Fallback 'Direct stored method label'

    return New-Record `
        -App $ManifestRow.app_name `
        -Package $ManifestRow.package_name `
        -VersionName $ManifestRow.version_name `
        -VersionCode $ManifestRow.version_code `
        -ArtifactPath (Get-RelativePathSafe -BasePath $Root -TargetPath $file) `
        -RawValue $rawValue `
        -EvidenceClass $evidenceClass `
        -MappedLabel $mappedLabel `
        -ImplementationNote $implementationNote `
        -AdditionalFields @{
            number_of_passes = $values['number_of_passes']
            secure_delete_mode = $values['secureDeletedMode']
        }
}

function Extract-SafeDelete {
    param($ManifestRow, [string]$Root, [object[]]$Mappings)
    $file = Find-ArtifactFile -Root $Root -CandidateNames @('com.seeroo.safedeleteApp_preferences.xml')
    if (-not $file) {
        $pathHint = Normalize-StudyToken -Value $Root
        $appHint = Normalize-StudyToken -Value $ManifestRow.app_name
        $packageHint = Normalize-StudyToken -Value $ManifestRow.package_name
        if ((-not $appHint -or -not $pathHint.Contains($appHint)) -and
            (-not $packageHint -or -not $pathHint.Contains($packageHint))) {
            return $null
        }
    }
    $artifactPath = if ($file) { Get-RelativePathSafe -BasePath $Root -TargetPath $file } else { $null }
    $rootMode = $null
    if ($file) {
        $values = Get-XmlPreferenceValues -Path $file -Keys @('rootmode','URI')
        $rootMode = $values['rootmode']
    }

    return New-Record `
        -App $ManifestRow.app_name `
        -Package $ManifestRow.package_name `
        -VersionName $ManifestRow.version_name `
        -VersionCode $ManifestRow.version_code `
        -ArtifactPath (Get-FallbackValue -Primary $artifactPath -Fallback 'N/A') `
        -RawValue 'code_only=true' `
        -EvidenceClass 'code_only_reconstruction' `
        -MappedLabel 'Fixed one-pass zero overwrite' `
        -ImplementationNote 'No user-selectable method artifact exists; overwrite model derived directly from PermanentDeleteTask' `
        -AdditionalFields @{
            rootmode = $rootMode
        }
}

function Extract-WipeFiles {
    param($ManifestRow, [string]$Root, [object[]]$Mappings)
    $file = Find-ArtifactFile -Root $Root -CandidateNames @('uk.org.platitudes.wipefiles_preferences.xml')
    if (-not $file) { return $null }
    $values = Get-XmlPreferenceValues -Path $file -Keys @('number_passes','zero_wipe','block_size')
    if ($values.Count -eq 0) { return $null }

    $rawValue = [ordered]@{
        number_passes = $values['number_passes']
        zero_wipe = $values['zero_wipe']
        block_size = $values['block_size']
    }

    return New-Record `
        -App $ManifestRow.app_name `
        -Package $ManifestRow.package_name `
        -VersionName $ManifestRow.version_name `
        -VersionCode $ManifestRow.version_code `
        -ArtifactPath (Get-RelativePathSafe -BasePath $Root -TargetPath $file) `
        -RawValue $rawValue `
        -EvidenceClass 'direct_configuration_evidence' `
        -MappedLabel 'Configuration-driven wipe method' `
        -ImplementationNote 'No named standard algorithms; effective behavior is derived from number_passes, zero_wipe, and block_size' `
        -AdditionalFields @{}
}

function Extract-ZERDAVA {
    param($ManifestRow, [string]$Root, [object[]]$Mappings)
    $file = Find-ArtifactFile -Root $Root -CandidateNames @('ZerdavaAndroidFileShredderPreferenceHelper.xml')
    if (-not $file) { return $null }
    $values = Get-XmlPreferenceValues -Path $file -Keys @('KEY_SELECTED_SHRED_TYPE')
    if (-not $values.ContainsKey('KEY_SELECTED_SHRED_TYPE')) { return $null }
    $rawValue = [string]$values['KEY_SELECTED_SHRED_TYPE']
    $mapped = Get-MappingLabel -Mappings $Mappings -AppName $ManifestRow.app_name -RecoveredKey 'KEY_SELECTED_SHRED_TYPE' -RecoveredValue $rawValue
    $evidenceClass = Get-FallbackValue -Primary ($mapped.EvidenceClass) -Fallback 'mapped_dynamic_method_evidence'
    $mappedLabel = Get-FallbackValue -Primary ($mapped.Label) -Fallback $null
    $implementationNote = Get-FallbackValue -Primary ($mapped.ImplementationNote) -Fallback 'Selector requires static mapping'

    return New-Record `
        -App $ManifestRow.app_name `
        -Package $ManifestRow.package_name `
        -VersionName $ManifestRow.version_name `
        -VersionCode $ManifestRow.version_code `
        -ArtifactPath (Get-RelativePathSafe -BasePath $Root -TargetPath $file) `
        -RawValue $rawValue `
        -EvidenceClass $evidenceClass `
        -MappedLabel $mappedLabel `
        -ImplementationNote $implementationNote `
        -AdditionalFields @{
            recovered_key = 'KEY_SELECTED_SHRED_TYPE'
        }
}

function Extract-ZeroFill {
    param($ManifestRow, [string]$Root, [object[]]$Mappings)
    $file = Find-ArtifactFile -Root $Root -CandidateNames @('shred_prefs.preferences_pb')
    if (-not $file) { return $null }
    $raw = Get-Content -Path $file -Raw
    if ($raw -notmatch 'last_algorithm_id') { return $null }

    $algorithmId = $null
    if ($raw -match 'last_algorithm_id.*?([a-z0-9_]{3,})') {
        $candidates = [regex]::Matches($raw, '[a-z][a-z0-9_]{2,}') | ForEach-Object { $_.Value }
        $algorithmId = $candidates | Where-Object { $_ -ne 'last_algorithm_id' } | Select-Object -First 1
    }
    if (-not $algorithmId) { $algorithmId = 'unknown' }
    $mapped = Get-MappingLabel -Mappings $Mappings -AppName $ManifestRow.app_name -RecoveredKey 'last_algorithm_id' -RecoveredValue $algorithmId
    $evidenceClass = Get-FallbackValue -Primary ($mapped.EvidenceClass) -Fallback 'direct_dynamic_method_evidence'
    $mappedLabel = Get-FallbackValue -Primary ($mapped.Label) -Fallback $algorithmId
    $implementationNote = Get-FallbackValue -Primary ($mapped.ImplementationNote) -Fallback 'Direct stored algorithm ID in DataStore artifact'

    return New-Record `
        -App $ManifestRow.app_name `
        -Package $ManifestRow.package_name `
        -VersionName $ManifestRow.version_name `
        -VersionCode $ManifestRow.version_code `
        -ArtifactPath (Get-RelativePathSafe -BasePath $Root -TargetPath $file) `
        -RawValue $algorithmId `
        -EvidenceClass $evidenceClass `
        -MappedLabel $mappedLabel `
        -ImplementationNote $implementationNote `
        -AdditionalFields @{
            recovered_key = 'last_algorithm_id'
        }
}

function Get-ExtractorMap {
    return @{
        'Android Eraser' = ${function:Extract-AndroidEraser}
        'Andro Shredder' = ${function:Extract-AndroShredder}
        'iShredder' = ${function:Extract-IShredder}
        'Shredder' = ${function:Extract-Shredder}
        'Shreddit' = ${function:Extract-Shreddit}
        'Safe Delete' = ${function:Extract-SafeDelete}
        'Wipe Files' = ${function:Extract-WipeFiles}
        'ZERDAVA' = ${function:Extract-ZERDAVA}
        'ZeroFill' = ${function:Extract-ZeroFill}
    }
}

if (-not (Test-Path $CapturePath)) {
    throw "Capture path not found: $CapturePath"
}

$scriptPath = $MyInvocation.MyCommand.Path
$repoRoot = Get-RepoRoot -ScriptPath $scriptPath
$mappingsPath = Join-Path $repoRoot 'mappings\selector_method_mappings.csv'
$manifestPath = Join-Path $repoRoot 'docs\manifests\tested_apps_manifest.csv'
$artifactPathsPath = Join-Path $repoRoot 'mappings\app_artifact_paths.csv'

$null = Read-Csv -Path $artifactPathsPath
$mappings = Read-Csv -Path $mappingsPath
$manifest = Read-Csv -Path $manifestPath
$extractorMap = Get-ExtractorMap

$result = $null
$hintRow = Get-CaptureHintRow -CapturePath $CapturePath -Manifest $manifest

if ($null -ne $hintRow -and $extractorMap.ContainsKey($hintRow.app_name)) {
    $hintExtractor = $extractorMap[$hintRow.app_name]
    $result = & $hintExtractor $hintRow $CapturePath $mappings
}

if ($null -eq $result) {
    foreach ($row in $manifest) {
        if ($null -ne $hintRow -and $row.app_name -eq $hintRow.app_name) { continue }
        if (-not $extractorMap.ContainsKey($row.app_name)) { continue }
        $extractor = $extractorMap[$row.app_name]
        $candidate = & $extractor $row $CapturePath $mappings
        if ($null -ne $candidate) {
            $result = $candidate
            break
        }
    }
}

if ($null -eq $result) {
    throw "No supported study-bounded artifact could be extracted from: $CapturePath"
}

$jsonDepth = 6
$json = if ($Pretty) {
    $result | ConvertTo-Json -Depth $jsonDepth
} else {
    $result | ConvertTo-Json -Depth $jsonDepth -Compress
}

if ($OutputPath) {
    $json | Set-Content -Path $OutputPath
}

$json
