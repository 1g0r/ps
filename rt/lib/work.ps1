Using module ..\..\apps\cmdbase.psm1

class WorkCommand : CommandBase {
  WorkCommand($config) : base(@(), $this.script, $config) {
  }
  
  hidden [ScriptBlock] $script = {
    $myshell = New-Object -com "Wscript.Shell"
    npp
    for ($i=0; $i -lt 120; $i++) {
      Start-Sleep -Seconds 60
      $myshell.sendkeys(".")
      Write-Host "count $i"
    }
  }
}
