$procz = Get-Process
$procz = $procz | Select-Object -Unique

$procArray = @()

foreach ($proc in $procz)
{
    $procObject = New-Object System.Object
    $procname = $proc.ProcessName
    $procNum =get-counter "\Process($($proc.ProcessName)*)\IO Read Bytes/sec"  | ForEach-Object {
        [math]::round((($_.countersamples.cookedvalue | Measure-Object -sum).sum / 1KB), 2)}
    Write-Output "Process: $procname ------ Total IO: $procNum"
    $procObject | Add-Member -type NoteProperty -name procName -Value $procname
    $procObject | Add-Member -type NoteProperty -name ioValue -Value $procNum
    $procArray += $procObject
}

$procArray | Where-Object ioValue -gt 0 |Sort-Object ioValue


