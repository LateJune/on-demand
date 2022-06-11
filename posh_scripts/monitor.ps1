# March 12th 2022 - monitor.ps1
# Watch folder location for file changes and log changes to file

$path = "C:\Users\June\Desktop\Landfill"
$filter =  "*.*" 

try {   

    if (Test-Path $path){
        Write-Host "A folder already exists at $path"
    }
    
    else {
        Write-Host "Creating folder: $path"
        New-Item $path -ItemType Directory
    }    

    $watcher = New-Object System.IO.FileSystemWatcher

    $watcher.Filter = $filter
    $watcher.Path = $path
    $watcher.IncludeSubdirectories = $false
    $watcher.EnableRaisingEvents = $true

    $writelog = {

        $fileDetails = $event.SourceEventArgs

        $name = $fileDetails.Name
        $eventPath = $fileDetails.FullPath
        $changeType = $fileDetails.ChangeType
        $logLine="$(Get-Date), $changeType, $eventPath, $name"
        Add-Content "C:\Users\June\Desktop\Landfill\Log\log_output.log"  $logLine
    }

    Register-ObjectEvent $watcher "Created" -Action $writelog
    #Register-ObjectEvent $watcher "Deleted" -Action $writelog
    #Register-ObjectEvent $watcher "Changed" -Action $writelog
    #Register-ObjectEvent $watcher "Renamed" -Action $writelog

    do {
        Wait-Event -Timeout 5
        Write-Host "." -NoNewline
    }
    while ($true)

}
finally {

    Write-Host "Ctrl-C deteted: Entered final block and removing jobs"

    $watcher.EnableRaisingEvents = $false

    $currentJobs = get-job 
    foreach ( $job in $currentJobs ) {
        Write-Host $job.Id, $job.Name
        Stop-Job $job.Id
        Remove-Job $job.Id
    }

    $watcher.Dispose()    

    Write-Warning "Event handler disabled, monitoring ended"
}

