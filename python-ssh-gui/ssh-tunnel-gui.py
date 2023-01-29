#!/usr/bin/env python3

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

import tkinter as tk
import threading
import subprocess
import base64
import re
from sshtunnel import SSHTunnelForwarder
from tkinter import filedialog as tkFileDialog
global file_count
file_count = 0



def get_ssh_tunnel_form_data():
	print("[-] Begin get form items")
	global ssh_tunnel_server
	
	ssh_username = form_username.get()
	remote_ssh_ip = form_remote_ssh_ip.get()
	remote_ssh_port = form_remote_ssh_port.get()
	remote_bind_ip = form_remote_bind_ip.get()
	remote_bind_port = form_remote_bind_port.get()
	local_bind_ip = "127.0.0.1"
	local_bind_port = form_local_bind_port.get()

	print(f"[+] Printing values from form...\nssh_username: {ssh_username} \nremote_ssh_ip: {remote_ssh_ip}\nremote_ssh_port: {remote_ssh_port}\nremote_bind_ip: {remote_bind_ip}\nremote_bind_port: {remote_bind_port}\nlocal_bind_ip: {local_bind_ip}\nlocal_bind_port: {local_bind_port}\n")

	print(f"[+] Running create_server function to create ssh tunnel forwader")
	ssh_tunnel_server = create_server(ssh_username, remote_ssh_ip, remote_ssh_port, remote_bind_ip, remote_bind_port, local_bind_ip, local_bind_port)
	if ssh_tunnel_server != None:
		print(f"[+] Creating ssh tunnel thread")
		create_ssh_tunnel_thread(ssh_tunnel_server)
		print(f"[+] Finished ssh tunnel thread created")
	else: 
		print(f"[x] Tunnel server returned as 'None'. Please try again.")

	return None

def create_server(ssh_username,remote_ssh_ip, remote_ssh_port, remote_bind_ip, remote_bind_port, local_bind_ip, local_bind_port):
	try:
		server = SSHTunnelForwarder(
			(f'{remote_ssh_ip}', int(remote_ssh_port)),
			ssh_username=ssh_username,
			# Path of SSH Prviate Key
			# Windows
			ssh_pkey='C:\\Users\\USER\\.ssh\\id_rsa',
			# Linux 
			#ssh_pkey='/home/USER/.ssh/id_rsa', 
			remote_bind_address=(remote_bind_ip, int(remote_bind_port)),
			local_bind_address=(local_bind_ip, int(local_bind_port))
    	)
		#print(f"[-] Server status:\n{server}")
		return server
	
	except Exception as e:
		print(f"[x] Unable to create ssh tunnel server. Did you fill in all the values?\n[x] Printing exception...\n{e}\n")
		return None
	

def create_ssh_tunnel_thread(server):
	print(f"[-] Starting server thread")
	ssh_tunnel_thread = threading.Thread(target=server.start())
	print(f"[-] Server Thread:\n{ssh_tunnel_thread}\n{threading.current_thread}")
	# Create try fail, check to see if server thread is already created otherwise pass
	
	return None

def stop_ssh_tunnel():
	# Simpler try or fail log and continue
	# Unless the server has been started, the execption will always hit when trying to convert the value to a string
	global ssh_tunnel_server
	try:
		print(str(ssh_tunnel_server))
		ssh_tunnel_server.stop()
		ssh_tunnel_server=None
		print("[-] Server stopped")
	except Exception as e:
		print(f"[x] Server never started, printing exception...\n{e}\n")
	
	return None

def create_file_window():
	global file_count
	ssh_user = form_username.get()
	remote_ssh_ip = form_remote_ssh_ip.get()
	file_path = tkFileDialog.askopenfilename()
	file_name = (re.sub("[^\w\.]","_",file_path.split("/")[-1]))+f"_{file_count}"+".b64"
	file_count = file_count + 1
	print(f"[+] Given file path: {file_path}")
	file_handle = open(file_path, "rb")
	file_contents = file_handle.read()
	file_handle.close()
	print(f"[+] Closed file handle")

	enc_string = base64.b64encode(bytes(file_contents))
	# Windows Adaption
	print(f"[+] Opening and writing {file_name} to C:\Windows\Temp")
	with open(f"C:\\Windows\\Temp\\{file_name}","wb") as new_tmp_file:
		new_tmp_file.write(enc_string)
	# Linux Adaption
	#print(f"[+] Opening and writing {file_name} to /tmp")
	#with open(f"/tmp/{file_name}","wb") as new_tmp_file:
	#	new_tmp_file.write(enc_string)

	new_tmp_file.close()
	print(f"[+] Closed file handle")

	print(f"[+] Running secury copy subprocess function")
	secure_copy(ssh_user, remote_ssh_ip, file_name) 
	
	return None

def secure_copy(ssh_user, remote_ssh_ip, file_name):
	
	try:
		print(f"[-] Running scp on {file_name} as {ssh_user} to {remote_ssh_ip}")
		# Windows
		#sub_process = subprocess.run(["wsl.exe", "bash","-c",f"scp -i '/home/USER/.ssh/id_rsa' '/mnt/c/Windows/Temp/{file_name}' '{ssh_user}@{remote_ssh_ip}:/tmp/{file_name}'"])
		
		# Linux
		sub_process = subprocess.run(["scp", "-i","/home/jonathan/.ssh/id_rsa.pub",f"/tmp/{file_name}",f"{ssh_user}@{remote_ssh_ip}:/tmp/{file_name}"])
		if sub_process.returncode == 0:
			print("[+] Action finished sucessfully!")
		else:
			print(f"[x] Failed to copy file to remote host. Subprocess Return Code: {sub_process.returncode}")
	except Exception as e:
		print(f"[x] Error occured on subprocess creation, printing exception\n{e}\n")
		
	return None

### GUI ### 
window = tk.Tk()
window.title("SSH Tunnel")
window.geometry("400x220")

master_frame = tk.Frame(padx=20, pady=20)
master_frame.pack()

### Username Password Info ###
lable_username = tk.Label(master=master_frame, text="Username")
lable_username.grid(row=0, column=0)

form_username = tk.Entry(master=master_frame, width=14)
form_username.grid(row=0, column=1)
form_username.insert(1,"jonathan")

### Remote SSH Info ###
label_remote_ssh_ip = tk.Label(master=master_frame, text="Remote SSH IP")
label_remote_ssh_ip.grid(row=1, column=0,pady=(10,0))

form_remote_ssh_ip = tk.Entry(master=master_frame, width=14)
form_remote_ssh_ip.grid(row=1, column=1,pady=(10,0))
form_remote_ssh_ip.insert(1,"127.0.0.1")

label_colon = tk.Label(master=master_frame, text=":")
label_colon.grid(row=1, column=2,pady=(10,0))

form_remote_ssh_port = tk.Entry(master=master_frame, width=5)
form_remote_ssh_port.grid(row=1, column=3,pady=(10,0))
form_remote_ssh_port.insert(1,"22")

### Remote IP bind Info ###
lable_remote_bind_ip = tk.Label(master=master_frame,text="Remote Bind IP")
lable_remote_bind_ip.grid(row=2,column=0)

form_remote_bind_ip = tk.Entry(master=master_frame, width=14)
form_remote_bind_ip.grid(row=2, column=1)
form_remote_bind_ip.insert(0,"127.0.0.1")

lable_colon = tk.Label(master=master_frame,text=":")
lable_colon.grid(row=2, column=2)

form_remote_bind_port = tk.Entry(master=master_frame,width=5)
form_remote_bind_port.grid(row=2, column=3)
form_remote_bind_port.insert(1,"5900")

### Local IP Bind Info ###
local_bind_ip = tk.Label(master=master_frame,text="Local Bind IP")
local_bind_ip.grid(row=3,column=0)

form_local_bind_ip = tk.Label(master=master_frame,text="127.0.0.1")
form_local_bind_ip.grid(row=3, column=1)

colon = tk.Label(master=master_frame,text=":")
colon.grid(row=3, column=2)

form_local_bind_port = tk.Entry(master=master_frame,width=5)
form_local_bind_port.grid(row=3, column=3)
form_local_bind_port.insert(1,"4444")

# File Window
btn_activate = tk.Button(master=master_frame,text="SCP File", command=create_file_window, width=5, bg="green")
btn_activate.grid(row=4,column=0,pady=(10,0),sticky="s")

# Submit
btn_submit = tk.Button(master=master_frame,text="Tunnel", command=get_ssh_tunnel_form_data, width=5, bg="cyan")
btn_submit.grid(row=4,column=1,pady=(10,0),sticky="s")

# Stop
btn_stop = tk.Button(master=master_frame,text="Stop", command=stop_ssh_tunnel, width=5, bg="cyan")
btn_stop.grid(row=4,column=3,pady=(10,0),sticky="s")

### START LOOP ###
window.mainloop()