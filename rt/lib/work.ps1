Using module ..\..\apps\cmdbase.psm1

class WorkCommand : CommandBase {
  WorkCommand() : base(@(), $this.script) {
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
