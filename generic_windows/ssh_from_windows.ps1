$SSHadminUsername = "gaz"
$SSHadminPassword = "totallyMyPassword"

$sshSession = New-SSHSession -ComputerName "kenobi1" -Port 22 -Credential (New-Object PSCredential $SSHadminUsername, ($SSHadminPassword | ConvertTo-SecureString -AsPlainText -Force)) -Force

Install-Module -Name SSHSessions
Import-Module -Name SSHSessions

Invoke-SshCommand -SSHSession $sshSession -Command "cd app ; cat helloThere.txt" -Verbose