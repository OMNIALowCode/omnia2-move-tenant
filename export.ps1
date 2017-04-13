param(
    [string] [Parameter(Mandatory=$true)] $tenant = "", 
    [string] [Parameter(Mandatory=$true)] $WebsiteName, #http or https://*.azurewebsites.netv
    [string] $SubscriptionName, #as in -subscriptionname param elsewhere
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName, #as in -resourcegroupname param elsewhere
    [string] $SubscriptionID #as in -subscriptionID param elsewhere
    )

$ErrorActionPreference = "Stop"

if ($SubscriptionName){
    Set-AzureRmContext -SubscriptionName $SubscriptionName
}
elseif ($SubscriptionID){
    Set-AzureRmContext -SubscriptionId $SubscriptionID
}
else{
    throw "Process does not work without an Azure Subscription!"
}
$workingFolder = $PSScriptRoot

$siteName = (($WebsiteName -split "://")[1] -split ".azurewebsites.net")[0]
$webApp = Get-AzureRMWebAppSlot -ResourceGroupName $ResourceGroupName -Name $siteName -Slot "Production"

foreach ($setting in $webApp.SiteConfig.ConnectionStrings){
    if ($setting.Name -eq "MyMis.Storage.ConnectionString"){
        $storageAccountName = (($setting.ConnectionString -split ";AccountName=")[1] -split ";AccountKey=")[0]
        $storageAccessKey = ($setting.ConnectionString -split ";AccountKey=")[1]
    }
    elseif ($setting.Name -eq "MyMis.SQL.Core.ConnectionString"){
        $builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder -argumentlist ($setting.ConnectionString);
        $server = $builder.DataSource
        $database = $builder.InitialCatalog
        $user = $builder.UserID + "@" + (($builder.DataSource -split (".database.windows.net")).Get(0))
        $passwd = $builder.Password
    }
}

#Preflight checks
if ($storageAccountName -eq $null -or $storageAccessKey -eq $null){
    throw "Invalid Storage configuration!"
}

if ($server -eq $null -or $database -eq $null -or $user -eq $null -or $passwd -eq $null){
    throw "Invalid SQL Database configuration!"
}

#Export process
WRITE-HOST "$(Get-Date -format 'u') - Starting export process..."

Write-Progress -id 1 -activity "Exporting Data" -Status "Exporting Blobs"
cd $workingFolder\ExportScripts
& .\script-blob-export.ps1 -storageAccountName $storageAccountName -storageAccessKey $storageAccessKey -tenant $tenant
cd $workingFolder

WRITE-HOST "$(Get-Date -format 'u') - Blobs exported..."

Write-Progress -id 1 -activity "Exporting Data" -Status "Exporting Tables" -PercentComplete 16.66
cd $workingFolder\ExportScripts
& .\script-table-export.ps1 -storageAccountName $storageAccountName -storageAccessKey $storageAccessKey -tenant $tenant
cd $workingFolder

WRITE-HOST "$(Get-Date -format 'u') - Tables exported..."

Write-Progress -id 1 -activity "Exporting Data" -Status "Exporting Tenant Image" -PercentComplete 33.33
cd $workingFolder\ExportScripts
& .\script-tenant-image-export.ps1 -storageAccountName $storageAccountName -storageAccessKey $storageAccessKey -tenant $tenant
cd $workingFolder

WRITE-HOST "$(Get-Date -format 'u') - Tenant image exported..."

Write-Progress -id 1 -activity "Exporting Data" -Status "Exporting User Images" -PercentComplete 50
cd $workingFolder\ExportScripts
& .\script-users-image-export.ps1 -storageAccountName $storageAccountName -storageAccessKey $storageAccessKey -server $server -database $database -user $user -passwd $passwd -tenant $tenant
cd $workingFolder

WRITE-HOST "$(Get-Date -format 'u') - users image exported..."

Write-Progress -id 1 -activity "Exporting Data" -Status "Exporting Users" -PercentComplete 66.66
cd $workingFolder\ExportScripts
& .\script-users-export.ps1 -server $server -database $database -user $user -passwd $passwd -tenant $tenant
cd $workingFolder

WRITE-HOST "$(Get-Date -format 'u') - users exported..."

Write-Progress -id 1 -activity "Exporting Data" -Status "Exporting Database" -PercentComplete 83.33
cd $workingFolder\ExportScripts
& .\script-export.ps1 -server $server -database $database -user $user -passwd $passwd -tenant $tenant
cd $workingFolder

Write-Progress -id 1 -activity "Exporting Data" -Status "Completed" -Completed

WRITE-HOST "$(Get-Date -format 'u') - data exported..."

Write-Host "Data exported sucessfully. Please execute import.ps1 to import the data to the destination subscription. Make sure you read the README before importing!"

$datFolder = (Get-Item $PSScriptRoot).FullName + "\Exported\datfiles"
$tenantInfo = Import-Csv $datFolder/'tenantInfo.csv'

Write-Host ("`nInformation from the original tenant that may be used in the import step:
Tenant = "+$tenantInfo.Code+"`nShortCode = "+$tenantInfo.ShortCode+
"`nName = "+$tenantInfo.Name+"`nOEMBrand = "+$tenantInfo.OEMBrand+
"`nSubGroup = "+$tenantInfo.SubGroup+"`nMaxNumberOfUsers = "+$tenantInfo.MaxNumberOfUsers+"`nDatabaseVersion = "+$tenantInfo.DatabaseVersion)

