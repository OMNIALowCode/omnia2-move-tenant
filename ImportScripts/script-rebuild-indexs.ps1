param([string]$server = "", [string]$database = "",[string]$user = "", [string]$passwd = "", [string]$tenant = "")

$connectionString = "Server=$server;uid=$user; pwd=$passwd;Database=$database;Integrated Security=False;"


$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()

$query = "
BEGIN TRY
BEGIN TRANSACTION FIX_TRANSLATIONS

create table #temp
(
	Code nvarchar(255),
	OrigID BIGINT,
	DestID BIGINT
)

ALTER TABLE [$tenant].[ProcessInteractionTypeReports] NOCHECK CONSTRAINT [FK_dbo.ProcessInteractionTypeReports_dbo.Languages_LanguageID]

ALTER TABLE [$tenant].[TranslationTexts] NOCHECK CONSTRAINT [FK_dbo.TranslationTexts_dbo.Languages_LanguageID]

SET IDENTITY_INSERT [$tenant].Languages ON

INSERT INTO #temp SELECT tl.Code,tl.ID,l.ID FROM [$tenant].Languages tl INNER JOIN [Resources].Languages l ON tl.Code = l.Code

DELETE FROM [$tenant].Languages

INSERT INTO [$tenant].Languages (ID,Code,[Name],[Description])
    SELECT l.ID,l.Code,l.[Name],l.[Description] FROM (Resources.Languages l INNER JOIN #temp t ON t.DestID = l.ID)

UPDATE [$tenant].[ProcessInteractionTypeReports] SET LanguageID=t.DestID 
	FROM [$tenant].[ProcessInteractionTypeReports] p INNER JOIN #temp t ON p.LanguageID = t.OrigID

UPDATE [$tenant].[TranslationTexts] SET LanguageID=t.DestID 
	FROM [$tenant].[TranslationTexts] p INNER JOIN #temp t ON p.LanguageID = t.OrigID

SET IDENTITY_INSERT [$tenant].Languages OFF

ALTER TABLE [$tenant].[ProcessInteractionTypeReports] CHECK CONSTRAINT [FK_dbo.ProcessInteractionTypeReports_dbo.Languages_LanguageID]

ALTER TABLE [$tenant].[TranslationTexts] CHECK CONSTRAINT [FK_dbo.TranslationTexts_dbo.Languages_LanguageID]

If(OBJECT_ID('tempdb..#temp') Is Not Null)
Begin
    Drop Table #temp
End

COMMIT TRANSACTION FIX_TRANSLATIONS
END TRY

BEGIN CATCH
	ROLLBACK TRANSACTION FIX_TRANSLATIONS
END CATCH
"

#run script
$command = $connection.CreateCommand()
$command.CommandText  = $query
$command.CommandTimeout = 600
$command.ExecuteReader()

WRITE-HOST "Recalculated translations."

$query ="
DECLARE @TableName varchar(255) 
DECLARE TableCursor CURSOR FOR
SELECT '[' + table_schema + '].[' + table_name + ']' FROM information_schema.tables
WHERE table_type = 'base table' AND table_schema = '$tenant'

OPEN TableCursor 
FETCH NEXT FROM TableCursor INTO @TableName 
WHILE @@FETCH_STATUS = 0 
BEGIN
exec('ALTER INDEX ALL ON ' + @TableName + ' REBUILD')
FETCH NEXT FROM TableCursor INTO @TableName 
END
CLOSE TableCursor 
DEALLOCATE TableCursor
";

#run script
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()
$command = $connection.CreateCommand()
$command.CommandText  = $query

$connection.Close()



WRITE-HOST "Indexs rebuild!"