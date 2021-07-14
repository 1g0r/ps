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
        $project = $self.projectsToRun[$projectName];
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
      [ParameterBase]::new("stop", 2, $false, [Switch])
    ),
    $this.script, $config)
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
    
    proj1 = {
      param([string]$slnConfig, [switch]$stop)
      
      if (-not $stop.IsPresent) {
        $this.checkConfig($slnConfig)
      }
      $existing = gps proj1 -ErrorAction SilentlyContinue
      if ($existing -ne $null) {
        $existing.Kill();
      }
      if (-not $stop.IsPresent) {
        Write-Host "c:\..\bin\$slnConfig\proj1.exe"
        Start-Process -FilePath "c:\..\bin\$slnConfig\proj1.exe" -WindowStyle Minimized
      }
    };
    
    webApi = {
      param ([string]$slnConfig, [switch]$stop)
      
      gps iisexpress -ErrorAction SilentlyContinue | Kill -ErrorAction SilentlyContinue;
      if ($stop.IsPresent) {
        return;
      }
      $this.checkConfig($slnConfig)
      $deleted = [CommandBase]::removeFolder("$env:USERPROFILE\AppData\Local\Temp\Temporary ASP.NET Files\", $this.shouldDelete, $false);
      if ($deleted -ne 0) {
        Write-Host "$deleted folders were found" -ForegroundColor Yellow
      }
      if (-not $stop.IsPresent) {
        Start-Process 'c:\Program Files\IIS Express\iisexpress.exe' '/port:8080 /path:c:\...\ /trace:i' -WindowStyle Hidden 
      }
    };
    
    w3svc = {
      Set-Service -Name W3SVC -StartupType Automatic
      Start-Service -Name W3SVC
    };
  }
}
