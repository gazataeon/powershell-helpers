function send-toPost($postUri, $inputData)
{
    $postBody = @{'message' = $inputData}
    Invoke-WebRequest -Uri $postUri -Method POST -Body $postBody
}