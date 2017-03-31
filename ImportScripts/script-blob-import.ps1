param([string]$resourceGroupName = "", [string]$storageAccountName = "", [string]$tenant = "", [string] $storageAccessKey = "")

function importFiles([string]$localFolder, [string]$destFolder, [string] $storageAccessKey){
    if (Test-Path $localFolder){
        $blobContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccessKey
        Get-ChildItem $localFolder  | %{
          $fileName = "$localFolder\$_"
          $blobName = "$destfolder/$_"
          write-host "copying $fileName to $blobName"
          Set-AzureStorageBlobContent -File $filename -Container $containerName -Blob $blobName -Context $blobContext -Force
        } 
        write-host "All files in $localFolder uploaded to $containerName!"
    }
    else{
        write-host "No files to upload for $localFolder"
    }
}

$containerName = $tenant.Replace('-','').ToLower()

# Find the local folder where this PowerShell script is stored.
$currentLocation = Get-location
$thisfolder = $PSScriptRoot

# Upload files
$folder = (Get-Item $thisfolder).Parent.FullName + "\Exported\blobfiles"
$localfolder = "$folder\scripts"
$destfolder = "Scripts"
importFiles $localfolder $destfolder $storageAccessKey


$localfolder = "$folder\Report-Container"
$destfolder = "Report-Container"
importFiles $localfolder $destfolder $storageAccessKey


$localfolder = "$folder\Commands"
$destfolder = "Commands"
importFiles $localfolder $destfolder $storageAccessKey


$localfolder = "$folder\Binary"
$destfolder = "Binary"
importFiles $localfolder $destfolder $storageAccessKey

# Public blobs
$folder = (Get-Item $thisfolder).Parent.FullName + "\Exported\blobfilespublic"

$containerName = $tenant.Replace('-','').ToLower() + "public"

if (Test-Path "$folder\webcomponents"){
    $localfolder = "$folder\webcomponents"
    $destfolder = "webcomponents"
    importFiles $localfolder $destfolder $storageAccessKey
}