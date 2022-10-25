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

Write-Warning "Newly copied files will be logged here!!"
Write-Warning "Please close this Powershell window once you are finished!!"

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
                        Write-Host "[+] Decoding file: $createdFileName"
                        $base64Data = Get-Content "$createdFilePath"
                        # Convert bytes and write to file path
                        Write-Host "[+] Writing file to path: $newfilePath"
                        $bytes = [Convert]::FromBase64String($base64Data)
                        [IO.File]::WriteAllBytes($newfilePath, $bytes)
                        # Assign newly decoded data to a variable and write to console
                        $decodedData = ([System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($base64Data)))
                        #Write-Host "[+] Base64 data from file: $base64Data"
                        #Write-Host "[+] Decoded base64: $decodedData"
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

        #Write-Host "[.] End of loop, sleeping 5 seconds"
        Start-Sleep -Seconds 5
    }
}
finally{
    
    Write-Host "[+] Event handler stopped, writing unmount flag to fileshare"
    Set-Content -Path "$fileSharePath\flag" -Value ""
    exit
}