$password = Read-Host -Prompt "Enter a string to encrypt"

##Write encrypted Creds to file
Write-Host "String to encrypt: $($password)" -ForegroundColor red
$encryptionKey_secure = $password | ConvertTo-SecureString -AsPlainText -Force
Write-Host "String Encrypted as $($encryptionKey_secure)" -ForegroundColor Green
$encryptionKey_secure = $encryptionKey_secure | ConvertFrom-SecureString 
Write-Host "Encrypted String ready to save as: $($encryptionKey_secure)" -ForegroundColor green
Set-Content "C:\temp\encryptionKey_secure.txt" $encryptionKey_secure
Write-Host "String saved to C:\temp\encryptionKey_secure.txt" -ForegroundColor Yellow
Write-Host "Contents of file: $(Get-Content "C:\temp\encryptionKey_secure.txt")" -ForegroundColor Green

# Read Creds in as an ecnrypted string
Write-Host "Reading in C:\temp\encryptionKey_secure.txt" -ForegroundColor Yellow
$encryptionKey_secure = Get-Content "C:\temp\encryptionKey_secure.txt"
Write-Host "Converting to SecureString" -ForegroundColor Yellow
$encryptionKey_secure = $encryptionKey_secure | ConvertTo-SecureString 


# Test Output
Write-Host "Converting Plain Text!" -ForegroundColor Yellow
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encryptionKey_secure)
$UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
Write-Host "The string below is now unsecure!" -ForegroundColor Yellow
Write-Host $UnsecurePassword -ForegroundColor red
