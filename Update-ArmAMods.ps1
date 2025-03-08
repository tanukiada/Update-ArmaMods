<#
    .SYNOPSIS
    Update-ArmaMods.ps1 checks all mods in C:\Arma3\ for updates.
#>

<#
    TODO
    1. Silent Function
    2. Dryrun Function
#>

function main {
    $modList = Get-Mods
    $user = Read-Host "Input Steam username"
    $pass = Read-Host "Input Steam password"
    foreach ($mod in $modList) {
        $modID = Get-ModID($mod)
        $updateTimestampRemote = Get-UpdateTimestampRemote $modID
        $updateTimestampLocal = Get-UpdateTimestampLocal $modID
        $unixTimeLocal = ([DateTimeOffset]$updateTimestampLocal).ToUnixTimeSeconds()
        if ($updateTimestampRemote -gt $unixTimeLocal) {
            Write-Output "$mods needs updated. Updating Now."
            Update-Mod $modID $user $pass $name
        } elseif ($updateTimestampRemote -le $unixTimeLocal) {
            Write-Output "$mod is up to date. Continuing..."
        }
    }
    Set-Location "C:\Arma3\"
}

function Get-Mods {
    $mods = @(Get-ChildItem -Filter '@*' C:/Arma3/ | Select-Object -ExpandProperty Name)
    return $mods
}

# function Get-MetaFile($mod) {
#     Set-Location -Path "C:\Arma3\$mod"
#     $metaFileHash = Get-Content 'meta.cpp' -Raw | ConvertFrom-StringData -Delimiter '='
#     return $metaFileHash
# }

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
    $metaFileHash = Get-ItemPropertyValue -Path "C:\Arma3\$mod" -Name LastWriteTime
    return $metaFileHash
}

function Update-Mod($id, $user, $pass, $name) {
    &"C:\steamcmd\steamcmd" "+login" "$user" "$pass" "+workshop_download_item" "107410" "$id" "+quit"
    Move-Item -Path "C:\steamcmd\steamapps\workshop\content\$id" -Destination "C:\Arma3\$name"
}

main