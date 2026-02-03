#!/bin/bash

# Global variables
Import=0
storage="local"
FORCE_START=0


# Defining funtions

# Fuction to slow type
slow_type() {
    local text="$1"
    local delay=0.01

    for ((i = 0; i < ${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo
}

# Function to check if the virtual machine exists
check_vmid_exists() {
    local vmid="$1"
    if qm status "$vmid" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --export)
                action="export"
                shift
                ;;
            --import)
                action="import"
                shift
                ;;
            --create)
                action="create"
                shift
                ;;
            --name)
                VM_name=$2
                shift 2
                ;;
            --format)
                F1=$2
                shift 2
                ;;
            --source)
                IP=$2
                shift 2
                ;;
            --RAM)
                CRAM=$2
                shift 2
                ;;
            --ID)
                vmid=$2
                shift 2
                ;;
            --OS)
                COS=$2
                shift 2
                ;;
            --storage)
                storage=$2
                shift 2
                ;;
            --disk)
                disk=$2
                shift 2
                ;;
            --start)
                FORCE_START=1
                shift
                ;;
            *)
                echo "Invalid option: $1"
                exit 1
                ;;
        esac
    done
}


get_vm_name_from_vmid() {
    local vmid="$1"
    qm config "$vmid" | awk -F': ' '/^name:/ {print $2}'
}

# Add a function to display help information
display_help() {
    echo "Usage: Proxmox.sh [OPTION]..."
    echo "Manage your Proxmox server with this script."
    echo
    echo "GitHub: https://github.com/Rao-Pranava/Automation-Scripts.git"
    echo
    echo "Available options:"
    echo "  --help                 Display this help information"
    echo "  --export               Export a virtual machine"
    echo "  --import               Import a virtual machine"
    echo "  --create               Create a new virtual machine"
    echo "  --name NAME            Specify the virtual machine name"
    echo "  --format FORMAT        Specify the export file format (e.g., vmdk, qcow2, raw)"
    echo "  --source IP            Specify the source IP for importing a virtual machine"
    echo "  --RAM RAM              Specify the amount of RAM for a new virtual machine"
    echo "  --ID VMID              Specify the virtual machine ID"
    echo "  --OS OS                Specify the operating system type for a new virtual machine (Linux, Windows 10/11/7/8/Vista/XP)"
    echo "  --storage              Specify the Proxmox Storage for your VM"
    echo "  --disk DISK            Specify which disk(s) to handle:"
    echo "  --start                Force start VM after export, even if it was initially stopped"
    echo "                         e.g., 'sata0', 'scsi0' for a specific disk"
    echo "                         or 'all' to handle all disks"
    echo
    echo "Examples:"
    echo
    echo " Importing "
    echo " # Import VM (Linux → attach disks as scsi) "
    echo " bash Proxmox.sh --import --source 192.168.1.100 --name myLinuxVM --format vmdk --disk all --storage local --OS Linux"
    echo
    echo " # Import VM (Windows → attach disks as sata) "
    echo " bash Proxmox.sh --import --source 192.168.1.100 --name myWinVM --format vmdk --disk all --storage local --OS \"Windows 10\""
    echo
    echo " Exporting "
    echo " # Export only scsi0 "
    echo " bash Proxmox.sh --export --ID 101 --format qcow2 --disk scsi0"
    echo
    echo " # Export all disks of a VM "
    echo " bash Proxmox.sh --export --ID 101 --format qcow2 --disk all"
    echo
    echo "# Export all disks of a VM and then Force start them"
    echo " bash Proxmox.sh --export --ID 101 --format qcow2 --disk all --start"
    echo
    echo " Creating a VM "
    echo " bash Proxmox.sh --create --name newVM --OS Linux --RAM 2048 --ID 123"
}

# Main function
main() {
    echo "Welcome! I am a program built by Pranava Rao for managing your Virtual Machines."

    [ -f .Banner ] && cat .Banner

    # Check if --help is provided
    if [[ "$1" == "--help" ]]; then
        display_help
        exit 0
    fi

    # Parse command line arguments
    parse_arguments "$@"

    # If no arguments provided, prompt the user for action
    if [[ $# -eq 0 ]]; then
        display_help
        exit 1
    else
        perform_action
    fi
}


Export_vm() {

    if [ -z "$vmid" ]; then
        echo "❌ VMID is required. Use --ID <VMID>"
        exit 1
    fi

    if ! check_vmid_exists "$vmid"; then
        echo "❌ VMID $vmid does not exist."
        echo "👉 Run: qm list"
        exit 1
    fi

    # Auto-fetch name ONLY if user didn't pass --name
    if [ -z "$VM_name" ]; then
        VM_name=$(get_vm_name_from_vmid "$vmid")
    fi
    [ -z "$VM_name" ] && VM_name="vm-$vmid"

    supported_formats="alloc-track backup-dump-drive blkdebug blklogwrites blkverify bochs cloop compress copy-before-write copy-on-read dmg file ftp ftps gluster host_cdrom host_device http https iscsi iser luks nbd null-aio null-co nvme parallels pbs preallocate qcow qcow2 qed quorum raw rbd replication snapshot-access throttle vdi vhdx vmdk vpc vvfat zeroinit"

    if ! echo "$supported_formats" | grep -qw "$F1"; then
        slow_type "Unsupported format. Please choose from the following supported formats:"
        echo "$supported_formats"
        exit 1
    fi

    VMID1="$vmid"

    original_state=$(qm status "$VMID1" | awk '{print $2}')
    
    if [ "$original_state" == "running" ]; then
        echo "ℹ️ VM was running, stopping for export..."
        qm stop "$VMID1"
    fi

    # Gather all disks of this VM
    disk_info=$(qm config $VMID1 | grep -E "^(ide|sata|scsi|virtio)[0-9]+:")
    disk_names=$(echo "$disk_info" | awk -F ': ' '{print $1}')

    if [ -z "$disk_names" ]; then
        echo "❌ No disks found for VM $VMID1 on storage $storage"
        exit 1
    fi

    if [[ "$disk" == "all" ]]; then
        # Export all disks
        for disk_name in $disk_names; do
            echo "🔄 Exporting disk: $disk_name ..."
            VMDiskname=$(qm config $VMID1 | grep "$disk_name:" | awk '{print $3}' FS=: OFS=, | cut -d, -f1)
            Path="$storage:$VMDiskname"
            DiskPath=$(pvesm path $Path)
            VMF1=$(qemu-img info --output=json "$DiskPath" | jq -r .format)

            qemu-img convert -f "$VMF1" -O $F1 "$DiskPath" "./${VM_name}_${disk_name}.$F1"
            echo "✅ Exported $disk_name -> ${VM_name}_${disk_name}.$F1"
        done
    else
        # Export a single disk
        if ! echo "$disk_names" | grep -qw "$disk"; then
            echo "❌ Disk '$disk' not found for VM $VMID1. Available disks:"
            echo "$disk_names"
            exit 1
        fi

        VMDiskname=$(qm config $VMID1 | grep "$disk:" | awk '{print $3}' FS=: OFS=, | cut -d, -f1)
        Path="$storage:$VMDiskname"
        DiskPath=$(pvesm path $Path)
        VMF1=$(qemu-img info --output=json "$DiskPath" | jq -r .format)

        qemu-img convert -f "$VMF1" -O $F1 "$DiskPath" "./${VM_name}_${disk}.$F1"
        echo "✅ Exported $disk -> ${VM_name}_${disk}.$F1"
    fi

    if [ "$FORCE_START" -eq 1 ]; then
        echo "🚀 --start specified, starting VM $VMID1"
        qm start "$VMID1"
    elif [ "$original_state" == "running" ]; then
        echo "🔁 Restoring original state: starting VM $VMID1"
        qm start "$VMID1"
    else
        echo "⏸️ VM was originally stopped; leaving it stopped"
    fi
    
    echo "🎉 Export complete. Files created in:"
    pwd
}

Import_vm() {
    VM_FILE="./$VM_name.$F1"

    if [[ -n "$IP" ]]; then
        # Source provided → download into TEMP
        TEMP_FOLDER="TEMP"
        mkdir -p $TEMP_FOLDER
        cd $TEMP_FOLDER || exit

        echo "🌐 Downloading $VM_FILE from http://$IP/ ..."
        if ! wget "http://$IP/$VM_name.$F1"; then
            slow_type "❌ Failed to download $VM_FILE"
            exit 1
        fi

        # Move file back up after download
        mv "$VM_FILE" ..
        cd ..
        rm -rf "$TEMP_FOLDER"
    else
        # No source provided → expect local file
        echo "📂 Using local file $VM_FILE"
        if [[ ! -f "$VM_FILE" ]]; then
            echo "❌ $VM_FILE not found in current directory"
            exit 1
        fi
    fi

    if [ -z "$vmid" ]; then
        echo "❌ VMID is required. Use --ID <VMID>"
        exit 1
    fi

    if ! check_vmid_exists "$vmid"; then
        echo "❌ VMID $vmid does not exist."
        echo "👉 Run: qm list"
        exit 1
    fi

    # Auto-fetch name ONLY if user didn't pass --name
    if [ -z "$VM_name" ]; then
        VM_name=$(get_vm_name_from_vmid "$vmid")
    fi
    [ -z "$VM_name" ] && VM_name="vm-$vmid"

    VMID1="$vmid"

    # Import the disk into Proxmox storage (keep original format!)
    if ! qm importdisk $VMID "$VM_FILE" $storage --format "$F1"; then
        slow_type "❌ Failed to import the disk."
        exit 1
    fi

    # Detect imported but unused disks
    unused_disks=$(qm config "$VMID" | awk -F: '/^unused[0-9]+:/ {print $1}')
    if [ -z "$unused_disks" ]; then
        echo "⚠️  No unused disks found for VM $VMID."
        echo "👉 Check manually with: qm config $VMID"
        exit 1
    fi

    # Decide bus type based on OS
    if [[ "$COS" =~ [Ll]inux ]]; then
        bus="scsi"
    else
        bus="sata"
    fi

    # 🆕 Ensure the chosen controller exists, add if missing
    if [[ "$bus" == "scsi" ]]; then
        if ! qm config "$VMID" | grep -q "^scsihw"; then
            qm set "$VMID" --scsihw virtio-scsi-single
            echo "ℹ️ Added VirtIO SCSI controller to VM $VMID"
        fi
    elif [[ "$bus" == "sata" ]]; then
        if ! qm config "$VMID" | grep -q "sata[0-9]:"; then
            qm set "$VMID" --sata0 none
            echo "ℹ️ Added SATA controller to VM $VMID"
        fi
    fi

    # Attach disks
    if [[ "$disk" == "all" ]]; then
        index=0
        for unused in $unused_disks; do
            path=$(qm config "$VMID" | grep "^$unused:" | cut -d: -f2- | awk -F, '{print $1}' | xargs)
            qm set "$VMID" --${bus}${index} "$path"
            echo "✅ Attached $path to ${bus}${index}"
            if [ $index -eq 0 ]; then
                qm set "$VMID" --boot order=${bus}0
                echo "✅ Set ${bus}0 as boot disk"
            fi
            index=$((index+1))
        done
    else
        target=$disk
        first_unused=$(echo "$unused_disks" | head -n 1)
        path=$(qm config "$VMID" | grep "^$first_unused:" | cut -d: -f2- | awk -F, '{print $1}')
        qm set "$VMID" --$target "$path"
        qm set "$VMID" --boot order=$target
        echo "✅ Attached $path to $target (boot)"
    fi

    echo "🎉 Import completed for VM $VMID"
}

Create_vm() {

    local ram_mb=$(echo "$CRAM" | sed 's/[^0-9]*//g')
    local os_type
    
    case "$COS" in
        Linux)
            os_type=l26
            ;;
        "Windows 10")
            os_type=win10
            ;;
        "Windows 11")
            os_type=win11
            ;;
        "Windows 7" | "Windows 8" | "Windows Vista" | "Windows XP")
            os_type="win$(echo "$COS" | tr '[:upper:]' '[:lower:]' | sed 's/windows //')"
            ;;
        *)
            slow_type "Unsupported OS type. Please choose Linux or Windows 10/11/7/8/Vista/XP."
            exit 1
            ;;
    esac

    slow_type "Creating a new virtual machine with the following configuration:"
    echo "Name: $VM_name; VMID: $vmid; RAM: $ram_mb; OS: $os_type"

    qm create $vmid --name "$VM_name" --net0 model=virtio,bridge=vmbr0,firewall=1 --memory "$ram_mb" --ostype "$os_type" --storage $storage
    
    slow_type "New virtual machine created successfully"

}

# Function to perform the action based on the provided options
perform_action() {
    case $action in
        export)
            Export_vm
            ;;
        import)
            Import_vm
            ;;
        create)
            Create_vm
            ;;
        *)
            echo "Invalid action. Please choose --export, --import, or --create"
            exit 1
            ;;
    esac
}

main "$@"
