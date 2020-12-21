Using module ..\..\apps\cmdbase.psm1

class BuildCommand : CommandBase {
  hidden [string] $compiler;
  hidden [string] $currentConfig;
  
  hidden [ScriptBlock] $script = {
    param([Buildcommand]$self, [string]$solution, [string]$configuration)
    process {
      $self.currentConfig = ''
      Write-Host "Build solution '$solution' ... " -NoNewline
      # Where $config comes from?
      $sln = $config.solutions[$solution]
      & $self.compiler $sln /p:Platform='Any CPU' /p:Configuration=$configuration
      $self.currentConfig = $configuration;
      Write-Host "Build completed " -ForegroundColor Yellow -NoNewline
      Write-Host "[OK]" -ForegroundColor Green
    }
  }
  
  BuildCommand($config):base(
    @(
      [ParameterBase]::new("solution", 1, $true, $config.solutions.Keys),
      [ParameterBase]::new("configuration", 3, $true, @('Release', 'Debug'))
    ),
    $this.script)
  {
    $this.compiler = $config.compiler;
  }
  
  [string] getConfig() {
    return $this.currentConfig;
  }
  
  [void] clearConfig() {
    $this.currentConfig = ''
  }
}
