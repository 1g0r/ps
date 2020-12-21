#$PSScriptRoot = '~\Documents\WindowsPowerShell\Modules\open\'
$openConfigPath = Join-Path $PSScriptRoot '\config\open.json'
$config = (Get-Content $openConfigPath) -join "`n" | ConvertFrom-Json | ConvertTo-HashTable

function toString($arr) {
  $result = ""
  $arr | %{
    $result += "'$_', "
  }
  return $result.Remove($result.Length - 2, 2);
}

function __openSingle([string] $name) {
  $app = $config | ?{ $_.code -eq $name }
  if ([string]::IsNullOrEmpty($app.params)) {
    Start-Process $app.path -RedirectStandardOutput 0
  } else {
    Start-Process $app.path $app.params -RedirectStandardOutput 0
  }
}

$appNames = toString ($config | %{$_.code})

$openBody = @"
function open {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=`$true, Position=0)]
    [ValidateSet($appNames)]
    [string[]]`$names
  )
  begin {}
  process {
    `$names | %{
      __openSungle `$_
    }
  }
}
"@;

function run() {
  $config | %{
    if ($null -ne $_['start'] -and $_.start -eq $true) {
      open $_.code
    }
  }
}

Invoke-Expression $openBody
Export-ModuleMember open, run
