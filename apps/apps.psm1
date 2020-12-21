function toString($arr) {
  $result = ""
  $arr | % {
    $result += "'$_', "
  }
  return $result.Remove($result.Length - 2, 2);
}

function Create-Application {
  [CmdletBinding()]
  param(
    [Parameter(Position=0, Manatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $name,
    
    [Parameter(Position=1, Mandatory=$true)]
    [Hashtable]$commands
  )
  
  begin {
    if ([string]::IsNullOrWhiteSpace($name)) {
      throw "Name ot the application can not be empty!"
    }
    if ($null -eq $commands -or $commands.Keys.Count -eq 0) {
      throw "Commands of the application $name can not be empty!"
    }
  }
  process {
    $componentSet = toString($commands.Keys)
    $closure = {
      $body = @"
function global:$name {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory='$true, Position=0)]
    [ValidateSet($componentSet)]
    [string]`$__name_of_command
  )
  DynamicParam {
    if (`$commands.Contains(`$__name_of_command)) {
      `$params = `$commands[`$__name_of_command].BuildParameters()
      return `$params
    }
  }
  begin {
    `$command = `$commands[`$__name_of_command];
  }
  process {
    `$argv = @(, `$command);
    foreach (`$key in `$params.Keys) {
      if (`$PSBoundParameters.ContainsKey(`$key) -and `$key -ne '__name_of_command') {
        `$argv += @(, `$PSBoundParameters[`$key]);
      }
    }
    `$command.Invoke(`$argv) | Out-Default
  }
}
"@
      Write-Host $body
      Invoke-Expression $body
    }.GetNewCosure()
    & $closure
  }
}

Export-ModuleMember Create-Application
