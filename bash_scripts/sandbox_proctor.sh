#!/bin/bash

source .env

function mountShare {
    printf "[+] Mounting Share VM\n"
    sudo mount -v -t cifs -o username=$user,password=$share_pass,port=$port //$share_ip/$mount_folder $mount_path 
}

function unmountShare {
    printf "[-] Unmounting Share VM\n"
    sudo umount $mount_path
    sleep 5
}

function startVMAndMount {
    vboxheadless --startvm "$vm" &
    sleep 5
    mountShare
    printf "[+] Creating active session flag in /tmp/flag\n"
    touch /tmp/flag
    sleep 5
}

function powerOffAndRestoreVM {
    printf "[-] Turning off VM\n"
    vboxmanage controlvm "$vm" poweroff
    sleep 5
    printf "[+] Restoring VM\n"
    vboxmanage snapshot "$vm" restore "Updated Posh Scripts" 
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
    printf "[+] $(ls /tmp | grep .b64| wc --words) New .b64 files in /tmp. Moving to $final_path\n"
    ls /tmp | grep .b64 | sudo xargs -r -I{} mv /tmp/{} $final_path
    sleep 5 
}

function sessionTimeout {
    if [[ is_user_active_session -eq 0 ]]
    then
        resetVMSession 
        # Check time sshed & boot users who are in ghost sessions
    fi
}

while
    # 0 == True
    # 1 == False
    is_user_sshed=$( [[ $(ss | grep ssh | wc --lines) -ne 0 ]]; printf $?)    
    is_file_share_mounted=$( [[ $(ss  |  grep 127.0.0.1:445 | wc --lines) -ne 0 ]]; printf $?)
    is_b64_file_present=$( [[ $(ls /tmp | grep .b64| wc --words) -gt 0 ]]; printf $?)
    is_unmount_flag_present=$( test -f "$mount_path/flag"; printf $?)
    is_active_session=$( test -f "/tmp/flag"; printf $?)

    printf "\nis_user_sshed: $is_user_sshed\n"
    printf "is_file_share_mounted: $is_file_share_mounted\n"
    printf "is_b64_file_present: $is_b64_file_present\n"
    printf "is_unmount_flag_present: $is_unmount_flag_present\n"
    printf "is_active_session: $is_active_session\n"

do
    if [[ is_user_sshed -eq 0 ]] 
        then
        # If sshed, not active session, and file share is not mounted
        if [[ $is_active_session -eq 1 && $is_file_share_mounted -eq 1 ]]
            then
            startVMAndMount
            if [[ is_idle -eq 1 ]]
                then
                is_idle=0
            fi  

        # If is active session and file share is monuted
        elif [[ $is_active_session -eq 0 && $is_file_share_mounted -eq 0 ]]
            then
            # If is active session, .b64 files are present, and no unmount flag present
            if [[ $is_active_session -eq 0 && $is_b64_file_present -eq 0 && $is_unmount_flag_present -eq 1 ]]
                then
                writeBase64FilesToShare

            # If unmount flag is present in file share 
            elif [[ $is_unmount_flag_present -eq 0 ]]
                then 
                ls /mnt/FileShare
                unmountShare

            else
                sleep 5
            fi

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
            printf "[+] Idling...\n"
        fi
    fi
done
