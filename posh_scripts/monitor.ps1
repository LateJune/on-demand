# March 12th 2022 - monitor.ps1
# Watch folder location for file changes and log changes to file
. .\variables.ps1
$startEpochTimeInSeconds = $(Get-Date (Get-Date).ToUniversalTime() -UFormat %s) -as [double]
$threeMinutesPastEpoch=$($startEpochTimeInSeconds+180.0)

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

        Add-Content -Path "C:\Users\USER\Desktop\FileShare\Log\temp_file_create.log" -Value $logLine
        
    }

    Register-ObjectEvent $watcher "Created" -Action $writelog

    do {
        Wait-Event -Timeout 2
        Write-Host "." -NoNewline
		$currentEpochTime=$(Get-Date (Get-Date).ToUniversalTime() -UFormat %s) -as [double]
		$poshProcesses=$(get-process -name powershell).count
		
		
		if ($(Test-Path $fileSharePath) -eq $true){
			$isMountFlagPresent=$(Test-Path "$fileSharePath/flag")
		}
		
		if ($poshProcesses -lt 2 -and $isMountFlagPresent -eq $false){
			Set-Content -Path "$fileSharePath\flag" -Value ""
			exit
		}
		
		if ($currentEpochTime -gt  $fifteenSecondsPastEpoch){
			Set-Content -Path "$fileSharePath\flag" -Value ""
			exit
		}
		
    }
    while ($true)

}
finally {

    Write-Host "Ctrl-C detected: Entered final block and removing jobs"

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
