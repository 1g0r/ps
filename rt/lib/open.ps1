Using module ..\..\apps\cmdbase.psm1

class OpenCommand : CommandBase {
  hidden [ScriptBlock] $script = {
    param([OpenCommand]$self, [string]$solution)
    
    $path = $solution.path
    & $solution.ide $path
  }
  
  OpenCommand($config) : base(@(), $this.script, $config)
  {
  }
}
