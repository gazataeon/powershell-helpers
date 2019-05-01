$features = get-windowsfeature | where-object {$_.InstallState -eq "Installed"}

$features | select-object name
