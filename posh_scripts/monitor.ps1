# Copyright (C) 2022 Jonathan Soler
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see https://www.gnu.org/licenses/.

. .\variables.ps1
$loopCounter=0
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

        Add-Content -Path "C:\Users\Dom\Desktop\FileShare\Log\temp_file_create.log" -Value $logLine
        
    }

    Register-ObjectEvent $watcher "Created" -Action $writelog

    do {
        Wait-Event -Timeout 2
        $loopCounter=$loopCounter+1
        Write-Host "." -NoNewline
		$currentEpochTime=$(Get-Date (Get-Date).ToUniversalTime() -UFormat %s) -as [double]
		$poshProcesses=$(get-process -name powershell).count		
		
		if ($(Test-Path $fileSharePath) -eq $true){
			$isMountFlagPresent=$(Test-Path "$fileSharePath/flag")	
		}
		
		if ($poshProcesses -lt 2 -and $isMountFlagPresent -eq $false){
			Write-Host "[+] Powershell processes less than two, writing unmoun flag to FileShare"
			Set-Content -Path "$fileSharePath\flag" -Value ""
			exit
		}
		
		if ($loopCounter -gt  300){
			Write-Host "[+] Ten minute timeout, writing unmount flag to FileShare"
			Set-Content -Path "$fileSharePath\flag" -Value ""
			exit
		}
		
    }
    while ($true)

}
finally {

    Write-Host "Exception hit, removing job"

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