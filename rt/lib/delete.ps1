Using module ..\..\apps\cmdbase.psm1

class DeleteCommand : CommandBase {
  hidden [string] $user;
  
  hidden [ScriptBlock] $script = {
    param([DeleteCommand]$self, [hashtable]$solution, [string]$branchName)
    
    $curPath = Get-Loacation;
    Set-Location = $solution.root;
    $branchName = "$($self.user)/$branchName"
    git branch -D $branchName
    git push origin --delete $branchName
    Set-Location $curPath
  }
  
  DeleteCommand($config) : base(
    @(
      [ParameterBase]::new("branchName", 1, $true, { $t = pwd; return [CommandBase]::getBranches($t.Path, $config.user, $true); })
    ),
    $this.script, $config
  )
  {
    $this.user = $config.user;
  }
}
