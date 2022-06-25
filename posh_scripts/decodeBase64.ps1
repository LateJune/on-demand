# Decode base64 from any newly detected files that are created from the folder location
. .\variables.ps1

try{
    while ($true) {
        if (Test-Path $tempLogFilePath) {
            foreach ($createdFileLine in Get-Content $tempLogFilePath){
                if ($createdFileLine -match "Created"){
                    Write-Host "[+] Given Log Line: $createdFileLine"

                    # Split the logged contents by comma and grab the path & name
                    $splitLineContents  = ($createdFileLine -split ", ")
                    $createdFilePath = $splitLineContents[2]
                    $createdFileName = $splitLineContents[3]

                    # Remove the .b64 file type and create file path var for decoded files
                    $newFileName = $createdFileName.replace(".b64","")
                    $newfilePath = "$decodedFilePath\$newFileName"

                    try {
                        # Get b64, decode and Write to file
                        Write-Host "[+] Attmpting to decode the file: $createdFileName"
                        $base64Data = Get-Content "$createdFilePath"
                        # Convert bytes and write to file path
                        Write-Host "[+] Attempting to write file to path: $newfilePath"
                        $bytes = [Convert]::FromBase64String($base64Data)
                        [IO.File]::WriteAllBytes($newfilePath, $bytes)
                        # Assign newly decoded data to a variable and write to console
                        $decodedData = ([System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($base64Data)))
                        #Write-Host "[+] Base64 data from file: $base64Data"
                        #Write-Host "[+] Decoded base64: $decodedData"
                        Write-Host "[+] Writing temp line to new log file"
                        Add-Content -path $finishedLogFilePath -Value $createdFileLine
               
    
                    }
                    catch {
                        throw "[x] Unable to decode b64 for file: $createdFileName"
                        continue
                    }
                }
        
            }

            Set-Content -Path $tempLogFilePath -Value ""

        }
        else {
            Write-Host "[x] Log file location does not exist"
        }

        Write-Host "[.] End of loop, sleeping 5 seconds"
        Start-Sleep -Seconds 5
    }
}
finally{
    
    Write-Host "[+] Ctrl-C detected, writing unmount flag to fileshare"
    Set-Content -Path "$fileSharePath\flag" -Value ""
    exit
}