Using module ..\..\apps\cmdbase.psm1

class RunCommand : CommandBase {
  hidden [System.Management.Automation.PSMethod] $slnConfigReader;
  
  hidden [ScriptBlock] $script = {
    param([RunCommand]$self, [string[]]$projects, [switch]$stop)
    process {
      if ($projects.Count -eq 1 -and $projects[0] -eq 'all') {
        $projects = $self.projectsToRun.all;
      }
      $word = if ($stop.IsPresent) { "Stopping" } else { "Starting" }
      
      $slnConfig = $self.slnConfigReader.Invoke();
      foreach($projectName in $projects) {
        $project = $this.projectsToRun[$projectName];
        if ($null -ne $project -and $project -is [ScriptBlock]) {
          Write-Host "$word " -NoNewline -ForegroundColor Yellow
          Write-Host "'$projectName'" -NoNewline -ForegroundColor Green
          Write-Host " app ... " -NoNewline -ForegroundColor Yellow
          Invoke-Command -ScriptBlock $project -ArgumentList @($slnConfig, $stop)
          Write-Host "[OK]" -ForegroundColor Green
        }
      }
    }
  }
  
  RunCommand($config, [System.Management.Automation.PSMethod]$slnConfigReader) : base(
    @(
      [ParameterBase]::new("projects", 1, $true, $this.projectsToRun.Keys, [string[]]),
      [ParameterBase]::new("stop", 2, $false, [switch])
    ),
    $this.script)
  {
    $this.slnConfigReader = $slnconfigReader;
  }
  
  hidden [void] checkConfig([string]$slnConfig) {
    if ([string]::IsNullOrEmpty($slnConfig)) {
      throw "You must build solution before run command!"
    }
  }
  
  hidden [bool] shouldDelete([System.IO.DirectoryInfo]$dir) {
    return $true;
  }
  
  hidden $projectsToRun = @{
    all = @('proj1', 'proj2', 'proj3');
    
  }
}
