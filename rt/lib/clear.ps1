Using module ..\..\apps\cmdbase.psm1

class ClearCommand : CommandBase {
  hidden [System.Collections.Generic.HashSet[string]] $excludeBin;
  hidden [System.Collections.Generic.HashSet[string]] $excludePackages;
  hidden [System.Management.Automation.PSMethod] $cleaner;
  
  hidden [ScriptBlock] $script = {
    param ($me, $solution, $what)
    process {
      if ($this.cleaner -ne $null) {
        $this.cleaner.Invoke()
      }
      #rt run all -stop
      if ($what -eq 'all' -or $what -eq 'bin') {
        Write-Host 'Start deleting ' -ForegroundColor Yellow -NoNewline
        Write-Host '"bin"' -ForegroundColor Green -NoNewline
        Write-Host ' and ' -ForegroundColor Yellow -NoNewline
        Write-Host '"obj" ' -ForegroundColor Green -NoNewline
        Write-Host 'folders ...' -ForegroundColor Yellow
        $deleted = [CommandBase]::removeFolder($solution.root, $me.shouldDeleteBin, $true)
        Write-Host "$deleted " -ForegroundColor Green -NoNewline
        Write-Host "folders were found. " -ForegroundColor Yellow -NoNewline
        Write-Host "Done!" -ForegroundColor Yellow
      }
      if ($what -eq 'all' -or $what -eq 'nuget' -and $solution.ContainsKey('packages')) {
        Write-Host "Clean nuget packages ..." -ForegroundColor Yellow
        $deleted = [CommandBase]::removeFolder($solution.packages, $self.shouldDeletePackage, $false)
        Write-Host "$deleted " -ForegroundColor Green -NoNewline
        Write-Host "folders were found. " -ForegroundColor Yellow -NoNewline
        Write-Host "Done!" -ForegroundColor Yellow
      }
      if ($what -eq 'all' -or $what -eq 'log') {
        Write-Host 'Clear logs not implemented yet!' -ForegroundColor Red
      }
    }
  }
  
  ClearCommand($config, [System.Management.Automation.PSMethod]$cleaner): base(
    @(
      [ParameterBase]::new("what", 1, $true, @('all', 'bin', 'nuget', 'log'))
    ),
    $this.script, $config
  )
  {
    $this.excludeBin = New-Object System.Collections.Generic.HashSet[string]::new(@(, [string[]]$config.excludeBin))
    $this.excludePackages = New-Object System.Collections.Generic.HashSet[string]::new(@(, [string[]]$config.excludePackages))
    $this.cleaner = $cleaner;
  }
  
  hidden [bool] shouldDeleteBin($dir) {
    $name = $dir.Name.ToLower();
    return ($name -eq 'bin' or $name -eq 'obj') -and -not $this.excludeBin.Contains($dir.FullName.LoLower())
  }
  
  hidden [bool] shouldDeletePackage($dir) {
    return -not $this.excludePackage.Contains($dir.Name);
  }
}
