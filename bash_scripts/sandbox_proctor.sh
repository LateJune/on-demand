#!/bin/bash

source .env

function mountShare {
    printf "[+] Mounting Share VM\n"
    sudo mount -v -t cifs -o username=$user,password=$share_pass,port=$port //$share_ip/$mount_folder $mount_path 
}

function unmountShare {
    printf "[-] Unmounting Share VM\n"
    sudo umount $mount_path
}

function startVMAndMount {
    vboxheadless --startvm "$vm" &
    sleep 5
    printf "[+] Mounting\n"
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
    vboxmanage snapshot "$vm" restore "Sandbox Ready Snapshot" 
    sleep 5
}


function resetVMSession {
    # Remove active session flag
    rm /tmp/flag 

    # if is mounted is true
    if [[ is_file_share_mounted -eq 0 ]] 
    then        
        unmountShare
        powerOffAndRestoreVM
    # Otherwise power off and restore
    else        
        powerOffAndRestoreVM
    fi
}

function writeBase64FilestToShare {
    if [[ is_b64_file_present -gt 0 && is_file_share_mounted -eq 0 ]]
    then
        printf "[+] $(ls /tmp | grep .b64| wc --words) New .b64 files in /tmp. Moving to $final_path\n"
        ls /tmp | grep .b64 | sudo xargs -r -I{} mv /tmp/{} $final_path
    else
        printf "[x] No new files in /tmp\n"
        continue
    fi
}

function sessionTimeout {
    if [[ is_user_active_session -eq 0 ]]
    then
        resetVMSession 
        # Check time sshed & boot users who are in ghost sessions
    else
        continue
    fi
}

while
    # 0 == True
    # 1 == False
    is_user_sshed=$( [[ $(ss | grep ssh | wc --lines) -eq 0 ]]; printf $?)    
    is_file_share_mounted=$( [[ $(ss  |  grep 127.0.0.1:445 | wc --lines) -ne 0 ]]; printf $?)
    is_b64_file_present=$( [[ $(ls /tmp | grep .b64| wc --words) -gt 0 ]]; printf $?)
    is_unmount_flag_present=$( test -f "$mount_path/flag"; printf $?)
    is_user_active_session=$( test -f "/tmp/flag"; printf $?)

do
    if [[ ssh_value -eq 0 ]] 
    then
        continue
    else
        continue
    fi
done
