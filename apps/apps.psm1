function toString($arr) {
  $result = ""
  $arr | % {
    $result += "'$_', "
  }
  return $result.Remove($result.Length - 2, 2);
}

function ConvertFrom-PSObject {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true,
               ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true,
               Position=0)]
    $object
  )

  $type = $object.GetType()
  if($type.Name.Equals('PSCustomObject', [System.StringCompartion]::InvariantCultureIgnoreCase)) {
    $result = @{};
    $object.psobject.properties | % {$result[$_.name] = (ConvertFrom-PSObject $_.value)}
    return $result;
  }
  if ($type.IsArray) {
    $arr = @();
    $object | % { $arr += ConvertFrom-PSObject $_ }
    return $arr;
  }
  return $object;
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
    `$tmp = `$PSBoundParameters.Remove('__name_of_command');
    `$command.Invoke(`$PSBoundParameters) | Out-Default
  }
}
"@
      #Write-Host $body
      Invoke-Expression $body
    }.GetNewCosure()
    & $closure
  }
}

Export-ModuleMember Create-Application
