# Uncomment to run script manually
#$PSScriptRoot = 'c:\....'
. $PSScriptRoot\lib\dreq.ps1

$dbConfigPath = Join-Path $PSScriptRoot '\config\db.json'
$config = (Get-Content $dbConfigPath) -join "`n" | ConvertFrom-Json | ConvertTo-HashTable;

$commands = @{
  delRequest = [DelRequestCommand]::new($config)
};

Create-Application 'db' $commands
Export-ModuleMember db
