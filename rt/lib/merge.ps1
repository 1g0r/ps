Using module ..\..\apps\cmdbase.psm1

class  MergeCommand : CommandBase {
  hidden [string] $user;
  hidden [string] $repo;
  
  hidden [ScriptBlock] $script = {
    param([MergeCommand]$self, [string]$from, [string]$to)
    process {
      $curPath = Get-Location
      
      cd $self.repo
      git checkout $from
      git pull
      git checkout "$($self.user)/$to"
      git merge $from
      cd $curPath
    }
  }
  
  MergeCommand($config) : base(
    @(
      [ParameterBase]::new("from", 1, $true, { [CommandBase]::getBranches($config.repo, $config.user, $false) }),
      [ParameterBase]::new("to", 2, $true, { [CommandBase]::getBranches($config.repo, $config.user, $true) })
    ),
    $this.script
  )
  {}
}
