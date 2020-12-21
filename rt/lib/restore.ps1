Using module ..\..\apps\cmdbase.psm1

class RestoreCommand : CommandBase {
  hidden [string] $nuget;
  hidden [string] $solution;
  
  hidden [ScriptBlock] $script = {
    param([RestoreCommand]$self)
    process{
      Write-Host "Restore NuGet packages ..." -ForegroundColor Yellow
      & $self.nuget restore $self.solution | Out-Default
      Write-Host "Restore NuGet packages done!" -ForegroundColor Green
    }
  }
  
  RestoreCommand($config):base(@(), $this.script)
  {
    $this.nuget = $config.nuget;
    $this.solution = $config.solutions['name']
  }
}
