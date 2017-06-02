Param(
	$TenantMoveToolLocation,
	$templateZip,
	$Tenant,
	$ShortCode,
	$TenantName,
	$subGroupCode,
	$tenantAdmin,
	$tenantAdminPwd,
	$oem,
	$master,
	$masterPwd,
	$websiteName,  #http or https://*.azurewebsites.net
	$ResourceGroupName,
	$subscriptionName
)

Add-Type -assembly "system.io.compression.filesystem"
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

## Load template tenant
Remove-Item "$TenantMoveToolLocation/Exported/" -Recurse
Unzip "$TemplateZip" "$TenantMoveToolLocation"

cd $TenantMoveToolLocation

. ".\import.ps1" -tenant $Tenant `
-ShortCode $ShortCode `
-TenantName $TenantName `
-MaxNumberOfUsers "10" `
-SubGroupCode $subGroupCode `
-TenantAdmin $tenantAdmin `
-TenantAdminPwd $tenantAdminPwd `
-OEM $oem `
-Master $master `
-MasterPwd $masterPwd `
-WebsiteName $websiteName `
-ResourceGroupName $ResourceGroupName `
-SubscriptionName $SubscriptionName `
-TenantType 'Template' `
-OverwriteIfExists