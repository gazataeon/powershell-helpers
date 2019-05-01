#Function to take input text based data and send it out to multiple destinations
function send-anywhere($inputData, $logLevel, $sendDests, $logLocation, $postUri, $slackUri, $slackChan)
{
    if ($sendDests -like "*slack*")
    {
        send-toSlack -slackUri $slackUri -inputData $inputData -logLevel $logLevel `
        -slackChan $slackChan -slackWebhook $slackWebhook
    }

    if ($sendDests -like "*log*")
    {
        send-toLogs -logLevel $logLevel -inputData $inputData -logLocation $logLocation
    }

    if ($sendDests -like "*console*")
    {
        send-toConsole -logLevel $logLevel -inputData $inputData
    }



}

# Returns a date that is handy for filenames or anything that doesnt like weird chars
function invoke-hotDate()
{
    return ((get-date).ToUniversalTime()).ToString("ddMMyyyy_hhmmss")
}

function send-toSlack($slackUri, $inputData, $logLevel, $slackChan, $slackWebhook)
{
    Set-StrictMode -Version Latest

    if ($type -eq "failure")
      {
      $icon_url =  "http://orig13.deviantart.net/d447/f/2011/073/f/d/a_rare_red_mudkip_appeared_by_srbarker-d3bnkes.png"
      $username = "Failkip"
      }
      else
      {
      $icon_url =  "http://orig12.deviantart.net/89ff/f/2011/266/f/3/mudkip_by_fawfuldude11-d4apyis.jpg"
      $username = "SlackKip"
      }

    $payload = @{
        "channel" = $slackchan
        "icon_url" = $icon_url
        "text" = $inputData
        "username" = $username }

    Invoke-WebRequest -UseBasicParsing `
    -Body (ConvertTo-Json -Compress -InputObject $payload) `
    -Method Post `
    -Uri "$($slackWebhook)" | Out-Null
}

function send-toLogs($logLevel,$inputData, $logLocation)
{
    $dateStamp = invoke-hotDate
    Write-Output "$($dateStamp): $($inputData)"
}

function send-toConsole($logLevel,$inputData)
{
    switch ($logLevel) {
        "error" { $fgColour = "Red" }
        "info" { $fgColour = "Yellow" }
        "success" { $fgColour = "Green" }
        Default {$fgColour = "White"}
    }
    write-host "$($dateStamp): $($inputData)" -ForegroundColor $fgColour
}

function send-toPost($postUri, $inputData)
{
    $postBody = @{'message' = $inputData}
    Invoke-WebRequest -Uri $postUri -Method POST -Body $postBody
}