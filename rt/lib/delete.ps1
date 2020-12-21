Using module ..\..\apps\cmdbase.psm1

class DeleteCommand : CommandBase {
  hidden [string] $repo;
  hidden [string] $user;
  
  hidden [ScriptBlock] $script = {
    param([DeleteCommand]$self, [string]$branchName)
    
    $curPath = Get-Loacation;
    Set-Location = $self.repo;
    $branchName = "$($self.user)/$branchName"
    git branch -D $branchName
    git push origin --delete $branchName
    Set-Location $curPath
  }
  
  DeleteCommand($config) : base(
    @(
      [ParameterBase]::new("branchName", 1, $true, { [CommandBase]::getBranches($config.repo, $config.user, $true) })
    ),
    $this.script
  )
  {
    $this.repo = $config.repo;
    $this.user = $config.user;
  }
}
