#!/bin/bash

# Parse command
CMD="$1"
SUB="$2"

if [ "$CMD" == "login" ]; then
    echo "Simulating Azure Login..."
    echo "Login successful."
    exit 0
fi

if [ "$CMD" == "storage" ]; then
    if [ "$SUB" == "container" ]; then
        if [ "$3" == "exists" ]; then
            echo "False"
        elif [ "$3" == "create" ]; then
            echo "Container created."
        fi
    elif [ "$SUB" == "blob" ]; then
        if [ "$3" == "upload" ]; then
            echo "Uploading to Blob Storage..."
            echo "Finished[#############################################################]  100.0000%"
        elif [ "$3" == "generate-sas" ]; then
            # Return a fake SAS token
            echo "sv=2022-11-02&ss=b&srt=sco&sp=r&se=2025-01-01T00:00:00Z&st=2024-01-01T00:00:00Z&spr=https&sig=mock_signature"
        fi
    fi
fi

if [ "$CMD" == "vm" ]; then
    if [ "$SUB" == "run-command" ]; then
         if [ "$3" == "invoke" ]; then
             echo "Invoking Run Command on VM..."
             # Output JSON simulating success
             echo '{
               "value": [
                 {
                   "code": "ComponentStatus/StdOut/succeeded",
                   "displayStatus": "Provisioning succeeded",
                   "level": "Info",
                   "message": "Deployment completed successfully.",
                   "time": null
                 },
                 {
                   "code": "ComponentStatus/StdErr/succeeded",
                   "displayStatus": "Provisioning succeeded",
                   "level": "Info",
                   "message": "",
                   "time": null
                 }
               ]
             }'
         fi
    elif [ "$SUB" == "extension" ]; then
        if [ "$3" == "set" ]; then
            echo "Setting VM Extension..."
             echo '{
               "name": "CustomScriptExtension",
               "resourceGroup": "rg-legacy-apps",
               "status": "Succeeded"
             }'
        fi
    fi
fi
