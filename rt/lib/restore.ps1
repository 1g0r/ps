Using module ..\..\apps\cmdbase.psm1

class RestoreCommand : CommandBase {
  hidden [ScriptBlock] $script = {
    param([RestoreCommand]$self, [hashtable]$solution)
    process{
      if ($solution.ContainsKey("nugetPath")) {
        Write-Host "Restore NuGet packages..." -ForegroundColor Yellow
        & $solution.nugetPath restore $solution.path | Out-Default
        Write-Host "Restore NuGet packages done!" -ForegroundColor Green
      } else {
        dotnet restore $solution.path | Out-Default
      }
    }
  }
  
  RestoreCommand($config):base(@(), $this.script, $config)
  { }
}
