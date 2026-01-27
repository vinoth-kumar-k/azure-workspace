#!/bin/bash
set -e

# Setup Mocks
mkdir -p tests/simulation/bin
ln -sf $(pwd)/tests/simulation/mock_msbuild.sh tests/simulation/bin/msbuild
ln -sf $(pwd)/tests/simulation/mock_nuget.sh tests/simulation/bin/nuget
ln -sf $(pwd)/tests/simulation/mock_az.sh tests/simulation/bin/az

export PATH=$(pwd)/tests/simulation/bin:$PATH

echo "=== STARTING PIPELINE SIMULATION ==="

echo ""
echo "--- Job: Build Legacy App ---"
SOLUTION="src/LegacyApp/LegacyApp.vbproj"

echo "Step: Setup MSBuild"
echo "Done."

echo "Step: Restore NuGet packages"
nuget restore "$SOLUTION"

echo "Step: Build Solution"
msbuild "$SOLUTION" /p:Configuration=Release

echo "Step: Zip Build Output"
# We need to manually zip because the yaml uses powershell Compress-Archive
# But here we are on linux simulation.
if [ -d "src/LegacyApp/bin/Release" ]; then
    zip -q -r LegacyApp.zip src/LegacyApp/bin/Release
    echo "Zipped LegacyApp.zip"
else
    echo "Error: Build output not found!"
    exit 1
fi

echo "Step: Upload Artifact"
echo "Uploaded LegacyApp.zip"
echo ""

echo "--- Job: Deploy VM (Run Command) ---"
ARTIFACT="LegacyApp.zip"
RG="rg-legacy-apps"
VM="vm-legacy-01"
STORAGE="stlegacyapps01"

echo "Step: Download Artifact"
# We already have LegacyApp.zip in current dir
ls -lh "$ARTIFACT"

echo "Step: Login to Azure"
az login --service-principal -u "mock" -p "mock" --tenant "mock"

echo "Step: Upload to Blob Storage"
EXISTS=$(az storage container exists --name deployments --account-name $STORAGE --auth-mode login --output tsv)
if [ "$EXISTS" == "False" ]; then
    az storage container create --name deployments --account-name $STORAGE --auth-mode login
fi

az storage blob upload --account-name $STORAGE --container-name deployments --name "$ARTIFACT" --file "$ARTIFACT" --auth-mode login --overwrite

echo "Step: Generate SAS"
SAS=$(az storage blob generate-sas --account-name $STORAGE --container-name deployments --name "$ARTIFACT" --permissions r --expiry "2025-01-01" --auth-mode login --as-user --output tsv)
SAS_URL="https://$STORAGE.blob.core.windows.net/deployments/$ARTIFACT?$SAS"
echo "Generated SAS URL: $SAS_URL"

echo "Step: Deploy via Run Command"
az vm run-command invoke \
  --resource-group $RG \
  --name $VM \
  --command-id RunPowerShellScript \
  --scripts @scripts/vm-install.ps1 \
  --parameters "PackageUrl=$SAS_URL"

echo ""
echo "=== SIMULATION COMPLETE ==="
