
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