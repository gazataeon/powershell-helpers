# Maybe a better solution to Type1


# Read Password
$password = read-host -Prompt "Password me!"  -AsSecureString
Write-host "Your password is stored as a: $($password)" -ForegroundColor Green

$passwordStr = $password | ConvertFrom-SecureString
Write-host "Your password is now: $($passwordStr)" -ForegroundColor Green

# Decrypt Using .NET
[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

# Save to File
$password | Export-Clixml -Path 'C:\temp\encryptoPassword.xml'
Write-host "Saved the password in C:\temp\encryptoPassword.xml" -ForegroundColor yellow
Write-host "Contents of file:" -ForegroundColor yellow
Write-host "$(Get-Content C:\temp\encryptoPassword.xml)" -ForegroundColor Green

#Read From file
$importedPassword = Import-CliXml -Path 'C:\temp\encryptoPassword.xml'
$plainTextPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($importedPassword))
Write-host "Password file now read in and decrypted:" -ForegroundColor yellow
Write-host "$($plainTextPass)" -ForegroundColor red

# fin