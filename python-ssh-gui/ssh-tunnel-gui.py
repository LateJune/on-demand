#!/usr/bin/env python3

import tkinter as tk
import threading
import os
import base64
from sshtunnel import SSHTunnelForwarder
from tkinter import filedialog as tkFileDialog
from time import sleep


def get_ssh_tunnel_form_data():
	print("[-] Begin get form items")
	global ssh_tunnel_server

	ssh_username = form_username.get()
	ssh_password = form_password.get()
	remote_ssh_ip=form_remote_ssh_ip.get()
	remote_ssh_port=form_remote_ssh_port.get()
	remote_bind_ip=form_remote_bind_ip.get()
	remote_bind_port=form_remote_bind_port.get()
	local_bind_ip=form_local_bind_ip.get()
	local_bind_port=form_local_bind_port.get()

	print(f"[+] Printing values from form...\nssh_username: {ssh_username}\nssh_password: {ssh_password}\nremote_ssh_ip: {remote_ssh_ip}\nremote_ssh_port: {remote_ssh_port}\nremote_bind_ip: {remote_bind_ip}\nremote_bind_port: {remote_bind_port}\nlocal_bind_ip: {local_bind_ip}\nlocal_bind_port: {local_bind_port}\n")

	print(f"[+] Running create_server function to create ssh tunnel forwader")
	ssh_tunnel_server = create_server(ssh_username, ssh_password, remote_ssh_ip, remote_ssh_port, remote_bind_ip, remote_bind_port, local_bind_ip, local_bind_port)
	if ssh_tunnel_server != None:
		print(f"[+] Creating ssh tunnel thread")
		create_ssh_tunnel_thread(ssh_tunnel_server)
		print(f"[+] Finished, thread ssh tunnel created")
	else: 
		print(f"[x] Tunnel server returned as 'None'. Please try again.")

	return None

def create_server(ssh_username, ssh_password, remote_ssh_ip, remote_ssh_port, remote_bind_ip, remote_bind_port, local_bind_ip, local_bind_port):
	try:
		server = SSHTunnelForwarder(
			(f'{remote_ssh_ip}', int(remote_ssh_port)),
			ssh_username=ssh_username,
			ssh_password=ssh_password,
			remote_bind_address=(remote_bind_ip, int(remote_bind_port)),
			local_bind_address=(local_bind_ip, int(local_bind_port))
    	)
		print(f"[-] Server status:\n{server}")
		return server
	
	except Exception as e:
		print(f"[x] Unable to create ssh tunnel server. Did you fill in all the values?\n[x] Printing exception...\n{e}\n")
		return None
	

def create_ssh_tunnel_thread(server):
	print(f"[-] Starting server thread")
	ssh_tunnel_thread = threading.Thread(target=server.start())
	print(f"[-] Server Thread:\n{ssh_tunnel_thread}\n{threading.current_thread}")
	
	return None

def stop_ssh_tunnel():
	try:
		server_stats_list = str(ssh_tunnel_server).split("\n")
		server_run_status = None

		for entry in server_stats_list:
			if "status:" in entry:
				server_run_status = entry

		if server_run_status == "status: started":
			print(f"[+] Attempting to stop, printing stats")
			ssh_tunnel_server.stop()
			if "status: not started" in str(ssh_tunnel_server):
				print("[-] Server stopped")
			else:
				print(f"[-] Unable to stop ssh tunnel server, printing server stats\n{ssh_tunnel_server}")
		else:
			print("[x] Server is not running")
	except Exception as e:
		print(f"[x] Server never started, printing exception...\n{e}\n")
	
	return None

def create_file_window():
	filename = tkFileDialog.askopenfilename()
	print(filename)  
	file_handle = open(filename, "rb")
	filebytes= file_handle.read()
	print(type(filebytes))
	enc = base64.b64encode(bytes(filebytes))
	file_handle.close()

	print(enc)

	return None

def secure_copy(enc_string):

	return None


### GUI ### 

window = tk.Tk()
window.title("SSH Tunnel")
window.geometry("400x200")


master_frame = tk.Frame(padx=20, pady=20)
master_frame.pack()

### Username Password Info ###

lable_username = tk.Label(master=master_frame, text="Username")
lable_username.grid(row=0, column=0)


form_username = tk.Entry(master=master_frame, width=14)
form_username.grid(row=0, column=1)
form_username.insert(1,"jonathan")

lable_password = tk.Label(master=master_frame, text="Password")
lable_password.grid(row=1, column=0)

form_password = tk.Entry(master=master_frame, width=14)
form_password.config(show="*")
form_password.grid(row=1, column=1)

### Remote SSH Info ###
label_remote_ssh_ip = tk.Label(master=master_frame, text="Remote SSH IP")
label_remote_ssh_ip.grid(row=2, column=0,pady=(10,0))

form_remote_ssh_ip = tk.Entry(master=master_frame, width=14)
form_remote_ssh_ip.grid(row=2, column=1,pady=(10,0))
form_remote_ssh_ip.insert(1,"192.168.1.174")

label_colon = tk.Label(master=master_frame, text=":")
label_colon.grid(row=2, column=2,pady=(10,0))

form_remote_ssh_port = tk.Entry(master=master_frame, width=5)
form_remote_ssh_port.grid(row=2, column=3,pady=(10,0))
form_remote_ssh_port.insert(1,"22")


### Remote IP bind Info ###
lable_remote_bind_ip = tk.Label(master=master_frame,text="Remote Bind IP")
lable_remote_bind_ip.grid(row=3,column=0)

form_remote_bind_ip = tk.Entry(master=master_frame, width=14)
form_remote_bind_ip.grid(row=3, column=1)
form_remote_bind_ip.insert(0,"127.0.0.1")

lable_colon = tk.Label(master=master_frame,text=":")
lable_colon.grid(row=3, column=2)

form_remote_bind_port = tk.Entry(master=master_frame,width=5)
form_remote_bind_port.grid(row=3, column=3)
form_remote_bind_port.insert(1,"5900")

### Local IP Bind Info ###
local_bind_ip = tk.Label(master=master_frame,text="Local Bind IP")
local_bind_ip.grid(row=4,column=0)

form_local_bind_ip = tk.Entry(master=master_frame, width=14)
form_local_bind_ip.grid(row=4, column=1)
form_local_bind_ip.insert(0,"127.0.0.1")

colon = tk.Label(master=master_frame,text=":")
colon.grid(row=4, column=2)

form_local_bind_port = tk.Entry(master=master_frame,width=5)
form_local_bind_port.grid(row=4, column=3)
form_local_bind_port.insert(1,"5900")

# Submit
btn_submit = tk.Button(master=master_frame,text="Submit", command=get_ssh_tunnel_form_data, width=5)
btn_submit.grid(row=5,column=3,pady=5,sticky="se")

# Stop
btn_stop = tk.Button(master=master_frame,text="Stop", command=stop_ssh_tunnel, width=5)
btn_stop.grid(row=5,column=1,pady=5,sticky="s")

# File Window
btn_activate = tk.Button(master=master_frame,text="Activate", command=create_file_window, width=5)
btn_activate.grid(row=5,column=0,pady=5,sticky="sw")

### START LOOP ###

window.mainloop()
