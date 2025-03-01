<#
    .SYNOPSIS
    Update-ArmaMods.ps1 checks all mods in C:\Arma3\ for updates.
#>

function main {
    $modList = Get-Mods
    $username = Read-Host "Input Steam username"
    $password = Read-Host "Input Steam password"
    foreach ($mod in $modList) {
        $modID = Get-ModID($mod)
        $updateTimestampRemote = Get-UpdateTimestampRemote($modID)
        $updateTimestampLocal = Get-UpdateTimestampLocal($modID)
        $dateTimeLocal = [datetime]::FromBinary($updateTimestampLocal)
        $unixTimeLocal = [DateTimeOffset]::new($dateTimeLocal).ToUnixTimeSeconds()
        $status = Compare-Times($unixTimeLocal, $updateTimestampRemote, $mod)
        if ($status) {
            Write-Output "$mods needs updated. Updating Now."
            Update-Mod($modID, $username, $password, $name)
        } elseif (!$status) {
            Write-Output "$mod is up to date. Continuing..."
        }
    }
    Set-Location "C:\Users\james\Documents\Coding\powershell\Update-ArmAMods"
}

function Get-Mods {
    $mods = @(Get-ChildItem -Filter '@*' C:/Arma3/ | Select-Object -ExpandProperty Name)
    return $mods
}

function Get-MetaFile($mod) {
    Set-Location -Path "C:\Arma3\$mod"
    $metaFileHash = Get-Content 'meta.cpp' -Raw | ConvertFrom-StringData -Delimiter '='
    return $metaFileHash
}

function Get-ModID($mod) {
    Set-Location -Path "C:\Arma3\$mod"
    $metaFileHash = Get-Content 'meta.cpp' -Raw | ConvertFrom-StringData -Delimiter '='
    return $metaFileHash['publishedid'].TrimEnd(";")
    
}

function Get-UpdateTimestampRemote($id) {
    $body = @{
        itemcount = 1
        'publishedfileids[0]' = $id
    }
    $request = Invoke-WebRequest -Method 'POST' -Uri "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/" -Headers @{charset="utf-8"} -Body $body | Select-Object -Expand "Content" | ConvertFrom-Json
    $request = $request.response | Select-Object -Expand "publishedfiledetails"
    $updateTimestamp = $request | Select-Object -Expand "time_updated"
    return $updateTimestamp
}

function Get-UpdateTimestampLocal($id) {
    Set-Location -Path "C:\Arma3\$mod"
    $metaFileHash = Get-Content 'meta.cpp' -Raw | ConvertFrom-StringData -Delimiter '='
    return $metaFileHash['timestamp'].TrimEnd(";")
}

function Compare-Times($localTime, $remoteTime, $mod) {

    if ($remoteTime -gt $localTime) {
        return $true
    } elseif ($remoteTime -le $localTime) {
        return $false
    }
}

function Update-Mod($id, $username, $password, $name) {
    ./steamcmd +force_install_dir C:\Arma3\ +login $username, $password +workshop_download_item 107410 $id +quit
    Move-Item -Path $id -Destination $name
}

main