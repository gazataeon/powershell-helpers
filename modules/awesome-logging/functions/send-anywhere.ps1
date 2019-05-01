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