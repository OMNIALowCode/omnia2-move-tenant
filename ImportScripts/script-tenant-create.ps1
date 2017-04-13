param([string]$code = "",[string]$shortcode = "",[string]$name = "",[string]$maxNumberOfUsers = "",[string]$subGroupCode = "",[string]$tenantAdmin = "",[string]$tenantAdminPwd = "",[string]$oem = "",[string]$apiID = "",[string]$apiEndpoint = "",[string]$master = "" ,[string]$masterpwd = "",[string]$desiredVersion="",[string]$tenantType="2")

$thisfolder = $PSScriptRoot
$datFolder = (Get-Item $thisfolder).Parent.FullName + "\Exported\datfiles"

if (-not $desiredVersion -or $desiredVersion -eq ""){
    $tenantInfo = Import-Csv $datFolder/'tenantInfo.csv'
    $desiredVersion = $tenantInfo.DatabaseVersion
}

$jsonRepresentation = @"
{
  "Code": "$code",
  "ShortCode": "$shortcode",
  "Name": "$name",
  "MaxNumberOfUsers": "$maxNumberOfUsers",
  "SubGroupCode": "$subGroupCode",
  "Email": "$tenantAdmin",
  "AdminEmail": "$tenantAdmin",
  "TenantTemplate": "",
  "TenantType": "$tenantType",
  "Password": "$tenantAdminPwd",
  "TenantImage": null,
  "OEMBrand": "$oem",
  "Language": "en-US",
  "Parameters": "",
  "DesiredVersion": "$desiredVersion"
}
"@

function ObtainToken{
param([string] $apiUser, [string]$apiID, [string] $apiPassword, [string] $apiEndpoint)
    #GET Authentication
    $oAuthURL = $apiEndpoint + 'OAuth/Token'

    $grantString = "grant_type=password&client_id=$apiID&username=$apiUser&password=$apiPassword"

    $oauthdata = Invoke-RestMethod -Method Post -uri $oAuthURL -Body $grantString -ContentType "application/x-www-form-urlencoded"

    $accessToken = $oauthdata.access_token 
    $refreshToken = $oauthdata.refresh_token

    return $accessToken
}


$accessToken = ObtainToken $master $apiID $masterpwd $apiEndpoint

$uri = $apiEndpoint + "v1/tenant/create"

Write-host "Sending creation request for tenant $tenant to $uri"

$Authorization = "Bearer $accessToken"
try {
    Write-Host $jsonRepresentation
    $createResults = Invoke-WebRequest -Uri $uri -Method POST -Body $jsonRepresentation -ContentType "application/json" -Headers @{"Authorization" = "$Authorization"} 
}
catch {
    $createResults = $_.Exception;
    $modelState = (ConvertFrom-Json $_.ErrorDetails.Message)
    Write-Host $createResults;
    if ($modelState){
        Write-Host "Additional details about model validity:"
        $modelState | Format-List | Out-String
    }
}
$operationId = $createResults.Headers.'mymis-operation';
$commandId = $createResults.Headers.'mymis-command';

try{
    $uri = "$apiEndpoint"+"v1/00000000-0000-0000-0000-000000000000/operation/TrackingCommand?operation=$operationId&command=$commandId"
    $tracking = Invoke-WebRequest -Uri $Uri -Method GET -ContentType "application/json" -Headers @{"Authorization" = "$Authorization"} 
    $status = (ConvertFrom-Json $tracking.Content).CommandStatus
    while (($status = (ConvertFrom-Json $tracking.Content).CommandStatus) -ne "Completed"){
        if ($status -eq "Error"){
            $msg = "Error creating tenant:"+(ConvertFrom-Json $tracking.Content).CommandStatusMessage
            throw $msg
        }
        $msg = "Current status for operation "+ $operationId+ " : " +$status
        Write-Host $msg
        Start-Sleep -s 10
        $tracking = Invoke-WebRequest -Uri $Uri -Method GET -ContentType "application/json" -Headers @{"Authorization" = "$Authorization"} 
    }
	Write-Host "Tenant created successfully with code $code"
}
catch{
    $tracking = $_.Exception;
    Write-Host $tracking;
    throw $_.Exception;
}
cd $PSScriptRoot
