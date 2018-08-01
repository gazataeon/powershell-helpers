#Populate all users in domain
$users = Get-ADUser -LDAPFilter '(&(!userAccountControl:1.2.840.113556.1.4.803:=2)(!userAccountControl:1.2.840.113556.1.4.803:=65536))'`
–Properties "Name", "SamAccountName","EmailAddress","msDS-UserPasswordExpiryTimeComputed" |
Select-Object -Property  "Name", "SamAccountName","EmailAddress", @{Name="Password_Expiry_Date";`
Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}} 

#alert on accounts expiring within 14 days
$date = Get-Date
$dateadd = $date.adddays(14) -as [datetime]

#SMTP Details
$SMTPServer = "<MAIL SERVER HERE>"
$SMTPPort = "25"
$Username = "<SMTP USER>"
$Password = "<Password Here>"

#Subject for Mail
$subject = "Account expiring soon for <ENV HERE>"

#Mail for catch all
$infrateam = "OPSTEAM@WHEREVER.COM"


$smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort);
$smtp.EnableSSL = $False
$smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password);


#Check each user to see if they expire in the next 14 days, if true then mail them, if they dont have email address set up mail the infra team
foreach ($user in $users)
{
    if ($user.Password_Expiry_Date -lt $dateadd)
    {
    Write-Output "Hi $($user.name) your account is due to expire on $($user.Password_Expiry_Date)"
 
        
        if ($user.EmailAddress -ne $null )
        {
        Write-Host "mailing $($user.EmailAddress)"
        $body = "Hi $($user.name)! Your account on <ENV HERE> is due to expire on $($user.Password_Expiry_Date). 
        Log in and reset it before this date!!"
        $message.body = $body
        $message.to.add("$($user.EmailAddress)")
        $smtp.send($message)
        
        
        }
        else
        #If no email is found then mail the Infra team
        {
        $body = "Hi the user account for '$($user.name)'  on <ENV HERE> is due to expire on $($user.Password_Expiry_Date).
        They don't have an email address set up so this is why you got this mail.
        Add an email address to their account and get them to log in and reset it before this date!!"
        $message.body = $body
        Write-Host "mailing $($infrateam)"
        $message.to.add("$($infrateam)")
        $smtp.send($message)
        
        }

    }
    #Clear and reset Message
    $message = $null
    $message = New-Object System.Net.Mail.MailMessage
    $message.subject = $subject
    $message.from = $username

}
