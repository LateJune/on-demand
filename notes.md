# On demand vm - windows

## Vision 

1) Home network GUI --> ssh to external host
2) On login, run vbox headless internally only
	- only ssh exposed to internet
		- port knock?

3) Smbclient scan for shared folder
4) Mount the share
5) Scp b64 encoded email/file to external host
	- drop in /mnt/SHAREDFOLDER
6) Unmount the share

7) ssh tunnel vnc from external host to home network
	- open vncviewer on 0.0.0.0:5900 on home workstation
	- box is opened from paused state

8) Perfrom analysis scripts
	- open process hacker
	- pull any links, files, embedded scripts

9) pack analysis together and drop into the file share again?
	- TODO: Need to understand how to move analysis back to host

X) FUTURE - vboxheadless command has a record option
	- record all vm activies as webm and report back to home workstation  

### Old Vison Process- may 28th
### Keeping for now
---

1) start using virtual box cmdline
	- box starts from a paused state with share folder already in place
2) host linux machine miunts the share
	- drops base 64 encoded file
3) windows box monitors the share folder 
4) upon new file created, windows decodes the payload and sends off to wsl

---

# TODO:
DONE - linux host vbox start script - in the works

DONE - mount script - in the works
	- needs to wait for folder to be available
	- rather than hard coding a pass should allow anoymous login?

wsl email analysis commands
client app connector to linux host
	- Needs to be nonspecific to os
	- python qt window
b64 encoder and send file to mnt point
scp file transfer from host to external host


DONE - confirm ssh tunnel
DONE - confirm localhost vnc after ssh tunnel


## Setup and important commands within virtualbox

vboxmanage showvminfo "Win 10 Ent"

vboxmanage modifyvm "Win 10 Ent" --vrde on --vrdeauthtype null --vrdeport 3389 --vrdeaddress "0.0.0.0"

vboxmanage startvm "Win 10 Ent" --type headless

vboxmanage closesession "Win 10 Ent"


### NEEED to set a password despite setting auth to null. Need to work out some more kinks around this. VNC is odd
VBoxManage modifyvm "Win 10 Ent" --vrdeproperty VNCPassword=password

## IMPORTANT

You need to install the virtualbox extension pack in order for vrde to work 

The extension can be added in the preferences and locally installed

https://www.virtualbox.org/wiki/Downloads

## SSH tunnel vnc to local host

ssh -L 5900:127.0.0.1:5900 user@x.x.x.x

