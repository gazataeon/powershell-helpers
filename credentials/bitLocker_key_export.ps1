#Script to export the recovery keys for the local machine and dump them in text files on the desktop for safe storage!

$ErrorActionPreference = "Stop"

#Change this if you like
$targetLocation = "~/Desktop/bitlockerKeys"

$encryptedVolumes = Get-BitLockerVolume | Where-Object "ProtectionStatus" -eq On

if (!(Test-Path $targetLocation)){mkdir $targetLocation}

foreach($bitVol in $encryptedVolumes)
{
    $driveLetter = $bitvol.MountPoint.chars(0)
    $keyinfo = (Get-BitLockerVolume -MountPoint $driveLetter).KeyProtector
    $keyinfo | Out-File -FilePath "$targetLocation\$($env:COMPUTERNAME)_Drive_$($driveLetter).txt"

}

#Open Export Folder
set-location $targetLocation
explorer .