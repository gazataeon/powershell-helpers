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