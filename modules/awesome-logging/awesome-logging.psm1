# Dot source the functions in here
Get-ChildItem -Path $PSScriptRoot\functions | 
  ForEach-Object -Process { . $PSItem.FullName }

 # Export-ModuleMember -Function         