param(
    [Parameter(Mandatory=$true)]
    [string]$PackageUrl,

    [string]$InstallPath = "C:\Apps\LegacyApp"
)

try {
    Write-Output "Starting deployment..."
    Write-Output "Target Path: $InstallPath"

    # Ensure clean state (Best Practice)
    # In a real scenario, we should stop the service/process if it's running
    # Stop-Process -Name "LegacyApp" -ErrorAction SilentlyContinue

    # Create destination directory
    if (!(Test-Path -Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        Write-Output "Created directory: $InstallPath"
    }

    # Define temporary file path
    $tempZip = "$env:TEMP\LegacyApp.zip"

    # Download
    Write-Output "Downloading package from Blob Storage..."
    Invoke-WebRequest -Uri $PackageUrl -OutFile $tempZip

    # Unzip
    Write-Output "Extracting package..."
    Expand-Archive -Path $tempZip -DestinationPath $InstallPath -Force

    # Cleanup
    Remove-Item -Path $tempZip -Force

    Write-Output "Deployment completed successfully."

} catch {
    Write-Error "Deployment failed: $_"
    exit 1
}
