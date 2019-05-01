function send-toLogs($logLevel,$inputData, $logLocation)
{
    $dateStamp = invoke-hotDate
    Write-Output "$($dateStamp): $($inputData)"
}