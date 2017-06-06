# Migrate Accounts

## SYNOPSIS

This set of scripts is used to export a tenant and import it into another subscription of the OMNIA platform.  

This document is updated to version 2.2 of the tool.

## DESCRIPTION

The account migration process is based on 2 moments. First, you export the Data from the origin account and second, you import it to the destination account.

These processes use azCopy, the Azure Powershell commands, and the BCP tool, to download all the necessary data to a local machine and then upload it to a different OMNIA subscription.

## REQUIREMENTS

Before executing the tool, ensure that:
  - you can access the SQL Database from your current network (i.e. exception in Azure Firewall).

  - you have Azure Powershell installed.

  - you have AzCopy (version 5.0.0.0) installed at: ```%programfiles(x86)%\Microsoft SDKs\Azure\AzCopy.```

  - you have administration rights in both origin and destination resource groups and subscriptions.

  - you are running Powershell as Admin.

  - you have access to an account with administration privileges in the destination subscription.

  - you either have your Powershell execution policy set to Unrestricted or Bypass (see https://technet.microsoft.com/en-us/library/ee176961.aspx), or you use the Unblock-File command to allow the files to run; Get-ChildItem -Recurse | Unblock-File will unblock all of the files in the folder.

## USAGE

### How to
Download the MoveTenantBetweenSubscriptions folder from GitHub, either by cloning the repository, or using a tool that downloads the folder only (such as [this](https://minhaskamal.github.io/DownGit/#/home?url=https://github.com/numbersbelieve/omnia-deployment/tree/master/MoveTenantBetweenSubscriptions)).


Execute export.ps1 to export the tenant data, and import.ps1 to import it to the destination. To understand the parameters, please consult the last sections of this readme file.

### Guidelines
- The migration should be scheduled previously – at the start of the process, the original tenant should be set to Inactive, and the connected connectors turned off.

- The migration should be performed on an Azure virtual machine, ideally on the same data center the subscriptions are in, as to save money and increase performance due to reduced latency.

- The infrastructure of the subscriptions can be scaled up temporarily - namely, the database - to improve performance.

- The Connectors won’t be imported. After moving the account, the tenant admin should:

    -	Recreate all the connectors in the tenant that existed in the original;

    -	Download the license file and connector code, and configure all installed Omnia Connectors to point to the new URL and use the new files.

- Only the users existing in the source application will have privileges in the destination account. Example: If the Master Account doesn’t exist in the source tenant, the master account won’t have privileges in the destination account.

- It is recommended that the Source and Destination systems should be in the same Platform Version.

    - If the Destination system has a **lower** version of the platform, migrations will not work. If it is **higher**, though, migrations will be possible, though it will be necessary to either restart the site, or use the Management area of the platform to edit the migrated tenant so that it is adjusted to that version of the platform.

- Ensure that the source tenant is in the tenant type you want the destination tenant to be! This is especially important with **Template** tenants.

    - When exporting, a Template tenant will not export any users that are marked as Inactive in the original tenant, to avoid bloat in destination subscriptions.

    - When importing, a Template tenant will not import the Commands blobs.

	- When importing, it is **mandatory** to provide a Customer ID and Customer Name for Full-type tenants.
	
### Installing templates
If you obtain a template (distributed as a zip that contains the **Exported** folder), you can import it using this tool into any subscription.

The importing process works exactly as any other import - the script in **Helpers\DeployTemplate.ps1** is an example of how to perform a deployment.

#### Extracting templates

The only step required to export a tenant that you wish to use as a template is saving the **Exported** folder from an export into a zip file, that should only contain that folder.

------------------------------

# EXPORT.PS1

Before executing, you should be authenticated via Azure RM:

```powershell
Login-AzureRmAccount
```

## PARAMETERS

### tenant (string)

The tenant code (GUID).

### WebsiteName (string)

The full URL of the Azure website (https:\\\\xxx.azurewebsites.net format).

### SubscriptionName (string)

The name of the Azure subscription (analogous to other -SubscriptionName in Azure Powershell).

### ResourceGroupName (string)

The name of the Azure resource group (analogous to other -ResourceGroupName in Azure Powershell).

### SubscriptionID (string)

The ID of the Azure subscription (analogous to other -SubscriptionID in Azure Powershell). Alternative to the SubscriptionName.

## Export example

```powershell
.\export.ps1 -tenant A0000000-B111-C222-D333-E44444444444 -WebsiteName https:\\waomnia12345.azurewebsites.net -SubscriptionName omnia12345 -ResourceGroupName omnia12345
```

------------------------------


# IMPORT.PS1

Before executing, you should be authenticated via Azure RM:

```powershell
Login-AzureRmAccount
```

## PARAMETERS

## _Azure information:_

### WebsiteName (string)

The full URL of the Azure website (https:\\\\xxx.azurewebsites.net format).

### SubscriptionName (string)

The name of the Azure subscription (analogous to other -SubscriptionName in Azure Powershell).

### ResourceGroupName (string)

The name of the Azure resource group (analogous to other -ResourceGroupName in Azure Powershell).

### SubscriptionID (string)

The ID of the Azure subscription (analogous to other -SubscriptionID in Azure Powershell). Alternative to the SubscriptionName.

### master (string)

A user with System Admin Role in the destination subscription

### masterpwd (string)

The password of the user with System Admin Role in the destination subscription

## _Tenant Information:_
### tenant (string)

The desired tenant code (GUID). Can be the same as the exported code, or altered.

### shortcode (string)

The Short Code of the tenant that will be created in the destination subscription.

### tenantname (string)

The display name of the tenant that will be created in the destination subscription.

### maxNumberOfUsers (int) (Optional – Default value 10)

The maximum number of users that can be created in the new account.

### subGroupCode (string) (Optional – Default value “DefaultSubGroup”)

The Sub Group Code that the tenant will be part of. The sub group should already exists in the destination account.

### tenantAdmin (string)

The email address of the user that will be used as the tenant Admin in the destination subscription.

### tenantAdminPwd (string)

The password for the user that will be used as the tenant Admin. If omitted, user will be associated to the tenant, if they exist; otherwise, the password will be randomly generated and sent to their email (should be a valid email, in this case).

### oem (string)

The code of the OEM the tenant will be part of. The OEM should already exist in the destination account.

### tenantType (string)

Template, Demonstration or Full. If left empty, will create a Demonstration tenant. The Template type has implications regarding the data that is transferred.

### customerName (string)

Name that identifies the customer. Mandatory in Full tenants.

### customerID (string)

ID that identifies the customer (fiscally). Mandatory in Full tenants.

## _Other parameters_
### overwriteIfExists (switch)

Attempt to delete the tenant with the given code, if it exists in the destination.

### ignoreCommands (switch)

Ignores the "Commands" folder when importing the blobs. Users will not be able to see command history.

## Import example

```powershell
.\import.ps1 -tenant A0000000-B111-C222-D333-E44444444444 -WebsiteName https:\\waomnia12345.azurewebsites.net -SubscriptionName omnia12345 -ResourceGroupName omnia12345 -shortcode tenantshortcode -tenantname 'My Tenant Name' -maxNumberOfUsers 10 -subGroupCode DefaultSubGroup -tenantAdmin admin@admin.com -tenantAdminPwd Password0 -oem omnia -master admin@admin.com -masterpwd Password0
```
