# Proxmox
This file automates the process of exporting and importing Virtual machine Disk files

## Useage

There are two ways to use the script, `Interactive` mood and the `Automated` mood.

### Interactive
```
bash Automation.sh
```

#### Importing the VM
![image](https://github.com/Rao-Pranava/Automation-Scripts/assets/93928268/5ae6ea7b-d2cd-4685-9c75-94ef9f722167)

![image](https://github.com/Rao-Pranava/Automation-Scripts/assets/93928268/ee3a977c-4b6d-4202-be6f-fa7a496f2588)

#### Exporting the VM
![image](https://github.com/Rao-Pranava/Automation-Scripts/assets/93928268/2e971203-7f3d-40fd-a204-ccb40fb40ef2)

#### Create a VM
![image](https://github.com/Rao-Pranava/Automation-Scripts/assets/93928268/6c2a996f-4b8b-476f-a68f-a159eacc022f)


### Automated mood.

#### Help

```
bash Proxmox.sh --help
```
![image](https://github.com/Rao-Pranava/Automation-Scripts/assets/93928268/afb2e504-fb03-4815-b8a5-e3ee7e5b78ad)

#### Importing a VM

```
bash Proxmox.sh --import --source <IP-Address> --name <name> --format <format>
```
![image](https://github.com/Rao-Pranava/Automation-Scripts/assets/93928268/8eb5b7c0-f1f8-4487-907b-2e7c0266b10c)

![image](https://github.com/Rao-Pranava/Automation-Scripts/assets/93928268/ee3a977c-4b6d-4202-be6f-fa7a496f2588)


#### Exporting the VM

```
bash Proxmox.sh --export --name <name> --format <format>
```
![image](https://github.com/Rao-Pranava/Automation-Scripts/assets/93928268/77003e79-1875-46d0-8e23-e3a9999798b5)

#### Creating a VM

```
bash Proxmox.sh --create --name <name> --OS <OS> --RAM 2048 --ID <ID>
```
![image](https://github.com/Rao-Pranava/Automation-Scripts/assets/93928268/76a055f8-7a48-4b06-8c64-a804335849e4)
