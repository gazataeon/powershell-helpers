##
# Description : Enable Encrypted backups in SQL 2016
# Interactive script, can be modded easy for automation.
##

# No Room for error here!
$ErrorActionPreference = "stop"

# Import SQL Module 
Install-Module -Name SqlServer #skips if already there
#Import-Module "sqlps" -DisableNameChecking

write-host "About to request info." -ForegroundColor Yellow
# Get Credentials
$targetServer = read-host -Prompt "Primary Server name"
$secondaryServer = read-host -Prompt "Secondary Server name - Hit enter to skip if not needed"
$smKeyPass = read-host -Prompt "Enter Service master Encryption Key"
$dbKeyPass = read-host -Prompt "Enter database master Encryption Key"
$certPriKeyPass = read-host -Prompt "Backup Cert pass"
$backupCertName = read-host -Prompt "Enter Cert Name. Default:'AzureBackupCertificate'"
if (!$backupCertName){$backupCertName = "AzureBackupCertificate"}

write-host "Checking Backup dir for certs" -ForegroundColor Yellow
# Create Cert Backup Dir
if (!(Test-Path -Path "\\$($targetServer)\c$\temp\certs\") )
{
        New-Item -ItemType Directory "\\$($targetServer)\c$\temp\certs\"
        write-host "Created '\\$($targetServer)\c$\temp\certs\'" -ForegroundColor green
}

# Check For Master Key, and create one if not there
write-host "Checking for MS_DatabaseMasterKey" -ForegroundColor Yellow
$masterkeyCheck = Invoke-Sqlcmd -ServerInstance $targetServer -Query "SELECT * FROM master.sys.symmetric_keys `
where name = '##MS_DatabaseMasterKey##'"  -Database "master" 
if (!$masterkeyCheck)
{
    Invoke-Sqlcmd -ServerInstance $targetServer -Query "CREATE MASTER KEY ENCRYPTION BY PASSWORD=`'$dbKeyPass`'"  -Database "master" 
    write-host "Created MS_DatabaseMasterKey" -ForegroundColor Green
}

# Create Cert
write-host "Creating Backup Cert $($backupCertName)" -ForegroundColor Yellow
Invoke-Sqlcmd -ServerInstance $targetServer -Query "CREATE CERTIFICATE $($backupCertName) `
WITH SUBJECT = 'SQL Server Backup'" -Database "master"     

# Backup the Service Master Key
write-host "Backup the Service Master Key" -ForegroundColor Yellow
Invoke-Sqlcmd -ServerInstance $targetServer -Query "BACKUP SERVICE MASTER KEY `
TO FILE = 'c:\temp\certs\_SMK.key' `
ENCRYPTION BY PASSWORD = `'$($smKeyPass)`';;" -Database "master"   

# Backup the Database Master Key
write-host "Backup the Database Master Key" -ForegroundColor Yellow
Invoke-Sqlcmd -ServerInstance $targetServer -Query "BACKUP MASTER KEY `
TO FILE = 'c:\temp\certs\_DMK.key' `
ENCRYPTION BY PASSWORD = `'$($dbKeyPass)`';;" -Database "master"   

# cert backup
write-host "Backup new Cert" -ForegroundColor Yellow
Invoke-Sqlcmd -ServerInstance $targetServer -Query "BACKUP CERTIFICATE AzureBackupCertificate `
TO FILE = 'c:\temp\certs\_AzureBackupCertificate.cer' `
WITH PRIVATE KEY `
(FILE = 'c:\temp\certs\_AzureBackupCertificate.key', `
ENCRYPTION BY PASSWORD = `'$($certPriKeyPass)`');"


## Do only if 2 node cluster
if ($secondaryServer) 
{
        write-host "Running Secondary Node tasks" -ForegroundColor Yellow
        # Create Cert Backup Dir
        if (!(Test-Path -Path "\\$($secondaryServer)\c$\temp\certs\") )
        {
                New-Item -ItemType Directory "\\$($secondaryServer)\c$\temp\certs\"
                write-host "Backup Cert directory created" -ForegroundColor Yellow
        }
        # Copying Cert Backup to Secondary node
        write-host "Copying Cert Backup to Secondary node" -ForegroundColor Yellow
        Copy-Item "\\$($targetServer)\c$\temp\certs\" -Recurse -Destination "\\$($secondaryServer)\c$\temp\" -Force

        # Check For Master Key on secondary server, if not, then restore this one
        write-host "Checking for MS_DatabaseMasterKey" -ForegroundColor Yellow
        $masterkeyCheck = Invoke-Sqlcmd -ServerInstance $targetServer -Query "SELECT * FROM master.sys.symmetric_keys `
        where name = '##MS_DatabaseMasterKey##'"  -Database "master" 
        if (!$masterkeyCheck)
        {
            Invoke-Sqlcmd -ServerInstance $secondaryServer -Query "drop master key"  -Database "master" 
            Invoke-Sqlcmd -ServerInstance $secondaryServer -Query "create master key encryption by password = `'$($dbKeyPass)`'"  -Database "master" 
            write-host "Created MS_DatabaseMasterKey" -ForegroundColor Green
        }

        # "Restore" create Certifcate from backup (You do this on your other nodes)
        Write-Host "Restoring cert to node 2" -ForegroundColor Yellow
        Invoke-Sqlcmd -ServerInstance $secondaryServer -Database "master" `
        -Query "CREATE CERTIFICATE AzureBackupCertificate `
        FROM FILE = 'c:\temp\certs\_AzureBackupCertificate.cer' `
        WITH PRIVATE KEY (FILE = 'c:\temp\certs\_AzureBackupCertificate.key', `
        DECRYPTION BY PASSWORD = `'$($certPriKeyPass)`');"
        write-host "Imported Cert to Secondary Node" -ForegroundColor green
}

write-host "Your cert has now been created." -ForegroundColor Green
$createExample = read-host -Prompt "Would you like me to create an example encrypted backup? - hit enter to skip"

if (!$createExample){write-host "All done then!" -ForegroundColor Green}

## Create Example Backup
if ($createExample)
{
        write-host "I will now create a job named 'BackupMasterDB' to backup the master DB to c:\temp\master.bak using the above encrypted cert. " -ForegroundColor Yellow

        $instanceName = $targetServer
        write-host "Connecting to $($targetServer)... " -ForegroundColor Yellow
        $sqlSvrCon = new-object ('Microsoft.SqlServer.Management.Smo.Server') $instanceName

        $job = new-object ('Microsoft.SqlServer.Management.Smo.Agent.Job') ($sqlSvrCon.JobServer, 'BackupMasterDB')
        $job.Description = 'Backup Master DB'
        $job.OwnerLoginName = 'sa'
        write-host "Creating job 'BackupMasterDB'... " -ForegroundColor Yellow
        $job.Create()

        $jobStep = new-object ('Microsoft.SqlServer.Management.Smo.Agent.JobStep') ($job, 'Step 01')
        $jobStep.SubSystem = 'TransactSql'
        $jobStep.Command = "BACKUP DATABASE [master] TO  DISK = N'c:\temp\master.bak' WITH NOFORMAT, NOINIT,  NAME = N'master-Full Database Backup',`
        SKIP, NOREWIND, NOUNLOAD,  STATS = 10, ENCRYPTION  (ALGORITHM = AES_256, SERVER CERTIFICATE = $($backupCertName))"
        $jobStep.OnSuccessAction = 'QuitWithSuccess'
        $jobStep.OnFailAction = 'QuitWithFailure'
        write-host "Creating jobStep 'Step 01'... " -ForegroundColor Yellow
        $jobStep.Create()

        $jobStepid = $jobStep.ID
        $job.ApplyToTargetServer($s.Name)
        $job.StartStepID = $jobStepid
        write-host "Applying jobStep 'Step 01' to Job... " -ForegroundColor Yellow
        $job.Alter()

        $schedulename = "Daily at 2:15 am"
        $now = Get-Date -format "MM/dd/yyyy"
        $schedule = New-Object Microsoft.SqlServer.Management.SMO.Agent.JobSchedule($job, $schedulename)
        $schedule.FrequencyTypes = [Microsoft.SqlServer.Management.SMO.Agent.FrequencyTypes]::Daily
        $schedule.FrequencyInterval = 1
        $timespan = New-TimeSpan -hours 2 -minutes 15
        $schedule.ActiveStartTimeofDay = $timespan
        $schedule.ActiveStartDate = $now
        write-host "Appying Schedule to job... " -ForegroundColor Yellow
        $schedule.Create()
        write-host "All done! Check out the job 'BackupMasterDB'! " -ForegroundColor Green
}