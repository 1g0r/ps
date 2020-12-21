Using module ..\..\apps\cmdbase.psm1

class BranchCommand : CommandBase {
  hidden [string] $repo;
  hidden [string] $user;
  
  BranchCommand($config): base (
    @(
      [ParametersBase]::new("from", 1, $true, { [CommandBase]::getBranches($config.repo, $config.user, $false) }),
      [ParametersBase]::("to", 2, $true)
    ),
    $this.script)
  {
    $this.repo = $config.repo;
    $this.user = $config.user;
  }
  
  hidden [ScriptBlock] $script = {
    param([BranchCommand]$self, [string]$from, [string]$to)
    
    $exist = [CommandBase]::getBranches($self.repo, $self.user, $true) | where { $_ -eq $to }
    if ($exist.Length -gt 0) {
      Write-Host "Branch " -ForegroundColor Yellow -NoNewline
      Write-Host $to -ForegroundColor Green -NoNewline
      Write-Host " already exicts!" -ForegroundColor Yellow
      return
    }
    
    $curPath = Get-Location;
    Set-Location $self.repo;
    git checkout $from;
    git pull origin $from;
    $newBranch = "$($self.user)/$to";
    git branch $newBranch;
    
    git checkout $newBranch
    git push -u origin $newBranch
    Set-Location $curBranch
  }
}
