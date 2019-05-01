# Returns a date that is handy for filenames or anything that doesnt like weird chars. Pass it nothing and you get the current date.
function invoke-hotDate($myDate,$format)
{

    # Check Format
    switch ($format) {
        "a" { $dateformat = "ddMMyyyy_hhmmss" }
        "b" { $dateformat = "dd-MM-yyyy_hhmmss" }
        "c" { $dateformat = "dd-MM-yyyy" }
        "d" { $dateformat = "ddMMyyyy" }
        Default {$dateformat = "ddMMyyyy_hhmmss"}
    }

    # Validate date
    if($myDate)
    {
        #write-output "date has been passed"
        if ($myDate.GetType().name -eq "String") # User has not passed a DateTime Object
        {
        #write-output "date passed is a string: $($myDate.GetType().name)"
        try {
                switch -Regex ($myDate) 
                {
                    "^\d\d\d\d\d\d$" { $parseFormat = "ddMMyy" } # Matches ddMMyy
                    "^\d\d\d\d\d\d\d\d$" { $parseFormat = "ddMMyyyy" } # Matches ddMMyyyy
                    "^\d\d-\d\d-\d\d$" { $parseFormat = "dd-MM-yy" } # Matches dd-MM-yy
                    "^\d\d-\d\d-\d\d\d\d$" { $parseFormat = "dd-MM-yyyy" } # Matches dd-MM-yyyy
                    "^\d\d/\d\d/\d\d$" { $parseFormat = "dd/MM/yy" } # Matches dd/MM/yy
                    "^\d\d/\d\d/\d\d\d\d$" { $parseFormat = "dd/MM/yyyy" } # Matches dd/MM/yyyy
                    Default {$parseFormat = "fullString"}
                }
                
                if($parseFormat -eq "fullString")
                {
                    #write-output "date passed is in full date string format"
                    $myDate = (([dateTime]$myDate)).ToString($dateformat)
                    return $myDate
                }
                else 
                {
                    # Hopefully matches the regex above
                    $myDate = [DateTime]::ParseExact($myDate, $parseFormat, $null).ToString($dateformat)
                    return $myDate
                }
                
            }
            catch {
                Write-Error "Must pass date in a format that is parsable, see README" 
            }
        }
        elseif ($myDate.GetType().name -eq "DateTime") # dateTime Object passed
        {
            #write-output "date passed is a DateTime Object"
            return (($myDate)).ToString($dateformat)
        }
    }
    elseif ($myDate -eq $null) # No Date Passed, use today's date
    {
        #"No date passed, will use current"
        return ((get-date)).ToString($dateformat)
    }
    else 
    {
        Write-Error "Must pass date in a format that is parsable, see README"
    }
}