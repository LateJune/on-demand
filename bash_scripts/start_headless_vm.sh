#!/bin/bash

vm="Win 10 Ent"

i=0
while 

        (( $(vboxmanage showvminfo "Win 10 Ent" | grep "Guest Facilities" | wc --words) <=0 ))

do 

        printf "[+] Starting Virtual Machine: $vm\n"
        if (( $i == 0 ))
                then

                printf  "[+] Entered if statement, sending execution to the background and sleeping\n"
                vboxheadless --startvm "$vm" &
                sleep 3
        fi
        printf "[.] Exited if statement, setting index=1\n"
        i=1

done

