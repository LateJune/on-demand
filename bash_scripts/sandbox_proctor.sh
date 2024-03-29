#!/bin/bash

# Copyright (C) 2023 Jonathan Soler
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

source .env 

function mountShare {
    printf "\n$(date "+%F %X %Z") [+] Mounting Share VM\n"
    sudo mount -v -t cifs -o username=$user,password=$share_pass,port=$port //$share_ip/$mount_folder $mount_path 
}

function unmountShare {
    printf "$(date "+%F %X %Z") [-] Unmounting Share VM\n"
    sudo umount $mount_path
    sleep 5
}

function startVMAndMount {
    vboxheadless --startvm "$vm" &
    sleep 5
    mountShare
    printf "$(date "+%F %X %Z") [+] Creating active session flag in /tmp/flag\n"
    touch /tmp/flag
    sleep 5
}

function powerOffAndRestoreVM {
    printf "$(date "+%F %X %Z") [-] Turning off VM\n"
    vboxmanage controlvm "$vm" poweroff
    sleep 5
    printf "$(date "+%F %X %Z") [+] Restoring VM\n"
    vboxmanage snapshot "$vm" restore "Sandbox Running Snapshot" 
    sleep 5
}


function resetVMSession {
    # Remove active session flag
    rm /tmp/flag 

    if [[ is_file_share_mounted -eq 1 ]] 
    then         
        powerOffAndRestoreVM
    else 
        unmountShare       
        powerOffAndRestoreVM
    fi
}

function writeBase64FilesToShare {
    printf "$(date "+%F %X %Z") [+] $(ls /tmp | grep .b64| wc --words) New .b64 files in /tmp. Moving to $final_path\n"
    ls /tmp | grep .b64 | sudo xargs -r -I{} mv /tmp/{} $final_path
    sleep 5 
}

function sessionTimeout {
    # Find all open and hung sessions, kill all of them using a pid
    open_sessions=$(pgrep ssh -a | grep pts)
    printf "$(date "+%F %X %Z") [+] Killing Open Sessions:\n $open_sessions\n"
    pgrep ssh -a | grep pts | cut -d " " -f 1 | xargs -r -I{} kill -9 {}
    resetVMSession
    sleep 5 
}

function checkIPSshed {
    ssh_sessions=$(last | grep "still logged in" | grep "pts"| wc -l )
    if [[ "$ssh_sessions" -gt 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Initialize start of session variable for numerical comparison errors
start_session_time=0

while
    # 0 == True
    # 1 == False
    checkIPSshed
    is_user_sshed=$?
    is_file_share_mounted=$( [[ $(ss  |  grep 127.0.0.1:445 | wc --lines) -ne 0 ]]; printf $?)
    is_b64_file_present=$( [[ $(ls /tmp | grep .b64| wc --words) -gt 0 ]]; printf $?)
    is_unmount_flag_present=$( test -f "$mount_path/flag"; printf $?)
    is_active_session=$( test -f "/tmp/flag"; printf $?)
    current_run_time=$(date +%s)

    printf "\nis_user_sshed: $is_user_sshed\n"
    printf "is_file_share_mounted: $is_file_share_mounted\n"
    printf "is_b64_file_present: $is_b64_file_present\n"
    printf "is_unmount_flag_present: $is_unmount_flag_present\n"
    printf "is_active_session: $is_active_session\n"

do
    if [[ is_user_sshed -eq 0 ]] 
        then
        currnet_time_difference=$(( $current_run_time - $start_session_time ))
        # If sshed, not active session, and file share is not mounted
        if [[ $is_active_session -eq 1 && $is_file_share_mounted -eq 1 ]]
            then
            startVMAndMount
            start_session_time=$(date +%s)
            if [[ is_idle -eq 1 ]]
                then
                is_idle=0
            fi  

        # If is active session and file share is monuted
        elif [[ $is_active_session -eq 0 && $is_file_share_mounted -eq 0 && $(( $current_run_time - $start_session_time )) -lt 300 ]]
            then
            # If is active session, .b64 files are present, and no unmount flag present
            if [[ $is_active_session -eq 0 && $is_b64_file_present -eq 0 && $is_unmount_flag_present -eq 1 ]]
                then
                writeBase64FilesToShare

            # If unmount flag is present in file share 
            elif [[ $is_unmount_flag_present -eq 0 ]]
                then 
                unmountShare

            else
                sleep 5
            fi

        elif [[ $(( $current_run_time - $start_session_time )) -gt 500 ]]
            then
                sessionTimeout
        else
            # If reached this point, take a breath, and continue looping
            sleep 2
        fi

    # If user is not sshed and active session flag is present
    elif [[ $is_user_sshed -eq 1 && $is_active_session -eq 0 ]]
        then
            resetVMSession
    else
        if [[ is_idle -eq 1 ]]
            then
            sleep 5
            printf "."
        else
            is_idle=1
            printf "$(date "+%F %X %Z") [+] Idling...\n"
        fi
    fi
done
