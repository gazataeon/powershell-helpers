# Returns a date that is handy for filenames or anything that doesnt like weird chars. Pass it nothing and you get the current date.
function invoke-hotDate($date,$format)
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
    if($date)
    {
        #write-output "date has been passed"
        if ($date.GetType().name -eq "String") # User has not passed a DateTime Object
        {
        #write-output "date passed is a string: $($date.GetType().name)"
        try {
                if($date -match "^\d\d\d\d\d\d$") # Matches ddMMyy
                {
                    #write-output "date Matches ddMMyy"
                    $date = [DateTime]::ParseExact($date, "ddMMyy", $null).ToString($dateformat)
                    return $date
                }
                elseif($date -match "^\d\d-\d\d-\d\d$") # Matches dd-MM-yy
                {
                    #write-output "date Matches dd-MM-yy"
                    $date = [DateTime]::ParseExact($date, "dd-MM-yy", $null).ToString($dateformat)
                    return $date
                }
                elseif($date -match "^\d\d/\d\d/\d\d$") # Matches dd/MM/yy
                {
                    #write-output "date Matches dd/MM/yy"
                    $date = [DateTime]::ParseExact($date, "dd/MM/yy", $null).ToString($dateformat)
                    return $date
                }
                else 
                {
                    #write-output "date passed is in full date string format"
                    $date = (([dateTime]$date)).ToString($dateformat)
                    return $date
                }
                
            }
            catch {
                Write-Error "Must pass date in a format that is parsable, see README" 
            }
        }
        elseif ($date.GetType().name -eq "DateTime") # dateTime Object passed
        {
            #write-output "date passed is a DateTime Object"
            return (($date)).ToString($dateformat)
        }
    }
    elseif ($date -eq $null) # No Date Passed, use today's date
    {
        #"No date passed, will use current"
        return ((get-date)).ToString($dateformat)
    }
    else 
    {
        Write-Error "Must pass date in a format that is parsable, see README"
    }
}