write-host $srcFile = $MyInvocation.MyCommand.Path
$srcFile = $MyInvocation.MyCommand.Path `
            -replace 'awesome-logging\\tests\\(.*?)\.Tests\.ps1','awesome-logging\functions\invoke-hotdate.ps1'
	    . $srcFile

Describe "invoke-hotdate" {
    It "Return default date format of ddMMyyyy_hhMMss" {
        invoke-hotdate | Should match "\d{8}_\d{6}"
    }
    It "Return with input date of dd/MM/yyyy" {
        invoke-hotdate -mydate "01/01/2001" | Should match "\d{8}_\d{6}"
    }
    It "Return with input date of dd/MM/yy" {
        invoke-hotdate -mydate "01/01/01" | Should match "\d{8}_\d{6}"
    }
    It "Return with input date of dd-MM-yyyy" {
        invoke-hotdate -mydate "01-01-2001" | Should match "\d{8}_\d{6}"
    }
    It "Return with input date of dd-MM-yy" {
        invoke-hotdate -mydate "01-01-01" | Should match "\d{8}_\d{6}"
    }
    It "Return with input date of ddMMyyyy" {
        invoke-hotdate -mydate "01012001" | Should match "\d{8}_\d{6}"
    }
    It "Return with input date of ddMMyy" {
        invoke-hotdate -mydate "010101" | Should match "\d{8}_\d{6}"
    }
    It "Return with input date of 01 January 1990 10:00:09" {
        invoke-hotdate -mydate "01 January 1990 10:00:09" | Should match "\d{8}_\d{6}"
    }
    It "Return with input date of 01 January 1990" {
        invoke-hotdate -mydate "01 January 1990" | Should match "\d{8}_\d{6}"
    }
    It "Fail with input date of 'Tomorrow'" {
        {invoke-hotdate -mydate "Tomorrow"} | Should throw 
    }
    It "Succeed with input date of '10 10 2001'" {
        invoke-hotdate -mydate "10 10 2001" | Should match "\d{8}_\d{6}"
    }

}
