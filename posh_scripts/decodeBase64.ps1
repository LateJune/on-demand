# Decode base64 from any newly detected files that are created from the folder location

$logFilePath = "C:\Users\June\Desktop\Landfill\Log\log_output.log"


if (Test-Path $logFilePath) {
    # Get the log file contents for a newly created file
    $logFileContents = Get-Content $logFilePath
    $createdFile = (echo $logFileContents | Select-String -pattern "Created")
    $splitContents  = ($createdFile -split ", ")
    $newlyCreatedFilePath = $splitContents[2]
    $newlyCreatedFileName = $splitContents[3]
    #Append the file name to the path that we want to write too
    $newFileWritePath = "C:\Users\June\Documents\Projects\$newlyCreatedFileName"
    Write-Host "Retrieved file path: $newlyCreatedFilePath" 
    Write-Host "Writing a new fil to the location: $newFileWritePath"

    try {
        # Get b64, decode and Write to file
        $base64Data = Get-Content "$newlyCreatedFilePath" 
        $bytes = [Convert]::FromBase64String($base64Data)
        [IO.File]::WriteAllBytes($newFileWritePath, $bytes)
        # Write to console
        $decodedData = ([System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($base64Data)))
        Write-Host $decodedData

    }
    catch {
        throw "Unable to decode b64"

    }
    
    if (Test-Path $newFileWritePath){
        wsl.exe bash -c /mnt/c/Users/June/Documents/Projects/exit.sh

    }
    else {
        Write-Host "File path for $newFileWritePath, does not exist. Exiting program"
        exit
    }

}

else {
    Write-Host "Log file location does not exist"
}