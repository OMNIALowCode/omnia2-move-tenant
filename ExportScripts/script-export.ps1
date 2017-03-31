param([string]$server = "", [string]$database = "",[string]$user = "", [string]$passwd = "", [string]$tenant = "")


$connectionString = "Server=$server;uid=$user;pwd=$passwd;Database=$database;Integrated Security=False;"

$thisfolder = $PSScriptRoot

$datFolder = (Get-Item $thisfolder).Parent.FullName + "\Exported\datfiles"

If (Test-Path $datFolder){
    REMOVE-ITEM $datFolder\* -Force -Recurse
}
Else{
    New-Item -ItemType Directory -Force $datFolder
}

$query = "SELECT TABLE_NAME 'Table'
	FROM INFORMATION_SCHEMA.TABLES
	WHERE TABLE_SCHEMA =  '"+ $tenant +"' AND TABLE_TYPE = 'BASE TABLE'"


$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()
$command = $connection.CreateCommand()
$command.CommandText  = $query

$result = $command.ExecuteReader()

$table = new-object "System.Data.DataTable"

$table.Load($result)


 Write-Progress -id 2 -activity "Copying Database Tables" -Status "Beginning Export"
$i = 0;
foreach ($Row in $table.Rows)
{ 
  $i++;
  $percent = 100*($i)/($table.Rows.Count)
  Write-Progress -id 2 -activity "Copying Database Tables" -Status "Copying Table $($Row[0])" -PercentComplete $percent

  WRITE-HOST "Copy of $($Row[0])..."
  
  bcp [$($database)].[$($tenant)].[$($Row[0])] format nul  -N  -x -f $datFolder\$($Row[0]).xml -E -S $($server) -U $($user) -P $($passwd)
  bcp [$($database)].[$($tenant)].[$($Row[0])] out $datFolder\$($Row[0]).dat -S $($server) -U $($user) -P $($passwd) -N
  
  
}
  Write-Progress -id 2 -activity "Copying Database Tables" -Status "Completed" -Completed

$tenantInfoCommand = $connection.CreateCommand()
$tenantInfoCommand.CommandText = "SELECT at.Code, at.ShortCode, at.Name, at.MaxNumberOfUsers,
     at.DatabaseVersion, at.Version, at.CustomerName, at.CustomerContactName, at.VATNumber, at.CustomerAddress, at.CustomerCountry,
     ob.Code 'OEMBrand', sg.Code 'SubGroup' 
FROM Auth.Tenants at
INNER JOIN Branding.OEMBrands ob ON at.OEMBrandID = ob.ID
INNER JOIN Auth.SubGroups sg ON at.SubGroupID = sg.ID
WHERE at.Code='$tenant'"

$result = $tenantInfoCommand.ExecuteReader()

$table = new-object "System.Data.DataTable"

$table.Load($result)
if ($table.Rows.Count -eq 1){
    $table.Rows[0] | Select-Object * | Export-Csv -Path $datFolder/'tenantInfo.csv' -Encoding UTF8
}
else{
    throw "Error: tenant not found in Auth.Tenants"
}
$connection.Close()


WRITE-HOST "Data export completed!"