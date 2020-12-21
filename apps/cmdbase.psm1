class ParameterBase{
  [string] $name;
  [Type] $type;
  [int] $position;
  [bool] $mandatory;
  [string[]] $validateSet;
  [ScriptBlock] $getValidateSet;
  
  hidden [void] setFields(
    [string]$name, 
    [int]$position, 
    [bool]$mandatory, 
    [string[]]$validateSet=$null,
    [ScriptBlock]$getValidateSet=$null,
    [Type]$type)
  {
    if ([string]::IsNullOrEmpty($name)){
      throw "Parameter must have name!"
    }
    $this.name = $name;

    if ($position -eq $null -or $position -eq 0){
      $this.position = 1
    } else {
      $this.position = $position
    }

    $this.mandatory = if ($null -ne $mandatory) { $mandatory } else { $false }
    $this.validateSet = $validateSet
    $this.getValidateSet = $getValidateSet
    $this.type = if ($null -eq $type) { [string] } else { $type }
  }
  
  ParameterBase([string]$name){
    $this.setFields($name, 1, $false, $null, $null, [string])
  }
  
  ParameterBase([string]$name, [int]$position, [bool]$mandatory){
    $this.setFields($name, $position, $mandatory, $null, $null, [string])
  }
  
  ParameterBase([string]$name, [int]$position, [bool]$mandatory, [string[]]$validateSet){
    $this.setFields($name, $position, $mandatory, $validateSet, $null, [string])
  }
  
  ParameterBase([string]$name, [int]$position, [bool]$mandatory, [ScriptBlock]$getValidateSet){
    $this.setFields($name, $position, $mandatory, $null, $getValidateSet, [string])
  }
  
  ParameterBase([string]$name, [int]$position, [bool]$mandatory, [Type]$type){
    $this.setFields($name, $position, $mandatory, $null, $null, $type)
  }
  
  [System.Management.Automation.RunTimeDefinedParameter] Build(){
    $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
    
    $attribute = New-Object System.Management.Automation.ParameterAttribute;
    $attribute.Position = $this.position;
    $attribute.Mandatory = $this.mandatory;
    $attributeCollection.Add($attribute)
    
    if ($null -ne $this.validateSet -and $this.validateSet.Lengh -ge 0) {
      $attribute = New-Object System.Management.Automation.ValidateSetAttribute($this.validateSet)
      $attributeCollection.Add($attribute)
    }
    if ($null -ne $this.getValidateSet) {
      $setOfValues = Invoke-Command -ScriptBlock $this.getValidateSet
      $attribute = New-Object System.Management.Automation.ValidateSetAttribute($setOfValues)
      $attributeCollection.Add($attribute)
    }
    $dynParam = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter($this.name, $this.type, $attributeCollection)
    return $dynParam    
  }
}

class CommandBase{
  [ParameterBase[]] $parameters;
  [ScriptBlock] $body;
  
  CommandBase([ParameterBase[]]$parameters, [ScriptBlock]$body) {
    $this.parameters = $parameters;
    
    if ($null -eq $body) {
      throw "Command body can not be null."
    }
    $this.body = $body
  }
  
  [System.Management.Automation.RuntimeDefinedParameterDictionary] BuildParameters() {
    $result = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
    foreach ($param in $this.parameters) {
      $result.Add($param.name, $param.Build())
    }
    return $result;
  }
  
  [void] Invoke([object[]]$argv) {
    Invoke-Command -ScriptBlock $this.body -ArgumentList $argv | Out-Default # To display colors
  }
  
  static [string[]] getBranches([string]$repoPath, [string]$user, [bool]$mine = $false) {
    $curPath = Get-Location;
    Set-Location $repoPath
    $result = git branch |
    Where-Object { if ($mine) { $_.Contains($user) } else { -not $_.Contains($user) } } |
    ForEach-Object { $_.Trim("*", " ").Replace("$($user)/", "") } |
    Sort-Object
    Set-Location $curPath
    return $result;
  }
  
  static [int] removeFolder([string]$path, [System.Management.Automation.PSMethod]$shouldDelete, [bool]$recurse) {
    if (-not (Test-Path $path)) {
      return 0;
    }
    $count = 0
    $items = if ($recurse) { Get-ChildItem $path -Recurse -Directory } else { Get-ChildItem $path -Directory }
    foreach ($dit in $items) {
      if ($shouldDelete.Invoke($dir)) {
        Write-Host $dir.FullName -NoNewline
        Write-Host ('.' * (120 - $dir.FullName.Length)) -NoNewline
        rm $dir.FullName -Resurse -force
        Write-Host ' DELETED' -ForegroundColor Green
        $count++
      }
    }
    return $count;
  }
}














