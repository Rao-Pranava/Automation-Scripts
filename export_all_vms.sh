#!/bin/bash
export PATH=/usr/sbin:/usr/bin:/bin

# Timestamp and backup dir
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
BACKUP_DIR="/backups/vm_export_$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

cd /home || exit 1

# Get list of powered-off VMIDs
POWERED_OFF_VMIDS=$(/usr/sbin/qm list | awk '$3 == "stopped" {print $1}')

if [ -z "$POWERED_OFF_VMIDS" ]; then
    echo "No VMs are powered off. Nothing to backup."
    exit 0
fi

echo "Starting backup for powered-off VMs..."

for VMID in $POWERED_OFF_VMIDS; do

    # Fetch VM name (for display + filenames only)
    VM_NAME=$(qm config "$VMID" | awk -F': ' '/^name:/ {print $2}')
    [ -z "$VM_NAME" ] && VM_NAME="vm-$VMID"

    echo "🔄 Backing up VMID=$VMID ($VM_NAME)"

    # Run Proxmox.sh export (VMID-based)
    bash /home/Proxmox.sh \
        --export \
        --ID "$VMID" \
        --format qcow2 \
        --disk all

    # Wait until all export files are available and unlocked
    while true; do
        FILES=$(ls /home/${VM_NAME}_*.qcow2 2>/dev/null)

        if [ -n "$FILES" ]; then
            BUSY=0
            for f in $FILES; do
                lsof "$f" &>/dev/null && BUSY=1
            done

            if [ "$BUSY" -eq 0 ]; then
                break
            fi
        fi

        sleep 5
    done

    # Move all exported disks for this VM
    mv /home/${VM_NAME}_*.qcow2 "$BACKUP_DIR/"
    echo "✅ Backup complete: VMID=$VMID ($VM_NAME)"

done

# Compress the backup folder
cd /backups || exit 1
tar -czvf "vm_exports_$TIMESTAMP.tar.gz" "vm_export_$TIMESTAMP"
rm -rf "vm_export_$TIMESTAMP"

echo "🎉 All exports complete. Zipped and cleaned up."
