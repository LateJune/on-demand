# On Demand

A project to deliver a sandbox virtual machine that is isolated from your personal or corporate network

## Goals

Provide a simple GUI that allows users to 
- Easily create an ssh tunnel 
- Transfer files seamlessly 
- Open a RDP/VNC session to a fresh sandbox everytime 
- Provide forensic analysis and analysis automation of scp'd items (WIP)

## Components

### Bash Script - Sandbox Proctor
Shell script keeps tabs on 
- Active session
- Activating the VM
- Reseting the VM
- Mount and unmounting file share
- Writing files to file share
- Idle state
- Session timeouts

### Posh Scripts - Monitor & Decode b64
Montior scripts meant to watch & decode scp'd files as well as start unmount chain
- Monitor file directories for any changes and write to a log file
- Monitor log file, decode and write any new .b64 files to host for analysis
- Keep tabs on a timer as well as create flag file to force unmount of the guest's file share
- TBD - Updated or single script(s) to provide this functionality

### Python GUI 
Functionality for simple for based GUI interface
- Modular SSH Tunnel with a button click
- Modular Secure Copy function

## Files not included in the repo

A virtual machine image with the correct file share and login credentials must be provided. An environment file is not included in this repo, but is referenced in the bash script to provide correct directories will be mounted and moved too

## Dependencies
```
sudo apt install virtualbox
```
```
pip install sshtunnel, tkinter-page
```
---
*Note please retreive the most up to date version of the virtualbox*extension pack
```
wget --no-check-certificate https://download.virtualbox.org/virtualbox/6.1.34/Oracle_VM_VirtualBox_Extension_Pack-6.1.34.vbox-extpack 
```
```
sudo VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-6.1.34.vbox-extpack 
```
