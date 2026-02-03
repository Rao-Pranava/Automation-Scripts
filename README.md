# Proxmox Automation Scripts

![AI Images](https://github.com/Rao-Pranava/Automation-Scripts/assets/93928268/a3c8a0c6-2795-4953-af57-44e558460204)

All these scripts are to be run on the Proxmox Server

```
git clone https://github.com/Rao-Pranava/Proxmox-Scripts.git
```

## Proxmox.sh
This file automates the process of exporting and importing Virtual machine Disk files

### Useage

```
bash Proxmox.sh --help
```
<img width="1147" height="786" alt="image" src="https://github.com/user-attachments/assets/45f9233e-a332-4bf8-a3a6-ff27b802b89c" />

## export_all_vms.sh
This script is a part of automating the process of backing up all the power offed systems in your Proxmox Server.

You can find the Detailed Blog about reasons and Motives about this tool [Here]([https://pranavarao.tech](https://pranavarao.tech/Blogs/Tech/backing-up-virtual-machines-in-promox/index.html))

### Setup

1. Make the `export_all_vms.sh` script executable

```
chmod +x export_all_vms.sh
```

2. Add the followign cron job to the cron of your proxmox server.

```
crontab -e
```

Enter the following content:

```
5 0 * * 0 /home/export_all_vms.sh >> /var/log/vm_backup.log 2>&1
```
*This will run the `export_all_vms.sh` script at 00:05 hours on all Sundays*

![image](https://github.com/user-attachments/assets/4e21a58a-8b47-443a-9b9d-8f61aa11e9d0)

Now, exit the editor

3. That is it, if you want to have a test run, you can run the following command

```
./export_all_vms.sh
```

![image](https://github.com/user-attachments/assets/a37766a2-7680-4454-b020-99e4244feebc)

-----------------

# Useful Commands

Install `jq` for the `Proxmox.sh` Script to work:

```
apt install jq
```

<img width="642" height="212" alt="image" src="https://github.com/user-attachments/assets/2c7f7388-c2dc-4a37-8092-b5cf28f3fbff" />


If you want to download the file from your server to the local computer, you can use this command:
```
scp root@<IP Address>:<File Location> .
```
