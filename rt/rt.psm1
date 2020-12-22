#Uncomment to run script manually
#$PSScriptRoot = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\rt"
. $PSScriptRoot\lib\branch.ps1
. $PSScriptRoot\lib\build.ps1
. $PSScriptRoot\lib\clear.ps1
. $PSScriptRoot\lib\delete.ps1
. $PSScriptRoot\lib\merge.ps1
. $PSScriptRoot\lib\open.ps1
. $PSScriptRoot\lib\restore.ps1
. $PSScriptRoot\lib\run.ps1
. $PSScriptRoot\lib\work.ps1

$rtConfigPath = Join-Path $PSScriptRoot '\config\rt.json';
$config = (Get-Content $rtConfigPath) -join "`n" | ConvertFrom-Json | ConvertTo-HashTable;

$build = [BuildCommand]::new($config);
$commands = @{
  branch = [BranchCommand]::new($config);
  build = $build;
  clear = [ClearCommand]::new($config, $build.clearConfig);
  delete = [DeleteCommand]::new($config);
  merge = [MergeCommand]::new($config);
  open = [OpenCommand]::new($config);
  restore = [RestoreCommand]::new($config);
  run = [RunCommand]::new($config, $build.getConfig);
  work = [WorkCommand]::new($config);
};

Create-Application 'rt' $commands
Export-ModuleMember rt
