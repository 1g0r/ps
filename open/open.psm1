#$PSScriptRoot = '~\Documents\WindowsPowerShell\Modules\open\'
$openConfigPath = Join-Path $PSScriptRoot '\config\open.json'
$config = (Get-Content $openConfigPath) -join "`n" | ConvertFrom-Json | ConvertTo-HashTable
