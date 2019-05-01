# Run this from a machine  with AD tools installed on
Import-Module GroupPolicy


#Backup GPOs
$gpos = Get-GPO -domain "aeon.local" -server "dc-vm1.aeon.local"
foreach($gpo in $gpos)
{
Backup-Gpo -Name $gpo.name -Path C:\temp\gpo_backups -Comment "Backup for $($gpo.name)"
}


#Restore GPOs
write-host "To restore a backup run the below:" -ForegroundColor Green
write-host "Import-Gpo -BackupGpoName gponame -TargetName gponame -path c:\temp\gpo_backups" -ForegroundColor Yellow