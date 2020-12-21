Using module ..\..\apps\cmdbase.psm1

class OpenCommand : CommandBase {
  hidden [string] $ide
  hidden [System.Collections.Hashtable] $solutions
  
  hidden [ScriptBlock] $script = {
    param([OpenCommand]$self, [string]$solution)
    
    $path = $self.solutions[$solution];
    & $self.ide $path
  }
  
  OpenCommand($config) : base(
    @(
      [ParameterBase]::new("solution", 1, $true, $config.solutions.Keys)
    ),
    $this.script
  )
  {
    $this.ide = $config.ide;
    $this.solutions = $config.solutions;
  }
}
