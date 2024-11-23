# install My SQL Connector 9.1
# https://dev.mysql.com/downloads/connector/net/

# install protobuf (required by MySQL Connector)
# https://github.com/protocolbuffers/protobuf/releases/download/v29.0-rc3/protoc-29.0-rc-3-win64.zip


param(
    [string]$dbServer="localhost",
    [string]$dbDatabase="",
    [string]$dbUser="",
    [string]$dbUserPwd=""  
)

# if you are using newer than 9.1 version, you need change path here
try {
    Add-Type -Path 'C:\Program Files (x86)\MySQL\MySQL Connector Net 8.0.21\Assemblies\v4.5.2\MySql.Data.dll' -ReferencedAssemblies 'System.Data.dll'
} catch {
    $_.Exception.LoaderExceptions | ForEach-Object { Write-Host $_.Message }
}

if ($dbUserPwd -like '') {
    $connectionString = Get-Content -path 'dbConnectionString'
} else {
	$connectionString = "Server=$dbServer;Database=$dbDatabase;User ID=$dbUser;Password=$dbUserPwd"
}

$connection = New-Object MySql.Data.MySqlClient.MySqlConnection($connectionString)

try {
    # Open the connection
    $connection.Open()
    Write-Host "Connection successful!"

    # Create a query and command object
    $query = "SELECT * FROM new_schema.files;"
    $command = $connection.CreateCommand()
    $command.CommandText = $query

    # Execute the query and get a data reader
    $reader = $command.ExecuteReader()

    # Read the data from the query result
    while ($reader.Read()) {
        Write-Host "ID: $($reader['id']), Name: $($reader['name'])"
    }

    $reader.Close()

}
catch {
    Write-Host "Error: $_"
}

$connection.Close()
