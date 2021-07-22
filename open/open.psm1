#$PSScriptRoot = '~\Documents\PowerShell\Modules\open\'
$openConfigPath = Join-Path $PSScriptRoot '\config\open.json'
$config = @(,(Get-Content $openConfigPath | ConvertFrom-Json)) | ConvertTo-HashTable

function toString($arr) {
  $result = ""
  $arr | ForEach-Object{
    $result += "'$_', "
  }
  return $result.Remove($result.Length - 2, 2);
}

function getAppConfig([string]$name) {
  return $config | Where-Object { $_.code -eq $name }
}

function getParent([string] $name){
  return (Get-Process -Name $name -ErrorAction SilentlyContinue | Where-Object MainWindowHandle -ne 0)
}

function isMultipleApp($appConfig) {
  return $appConfig.ContainsKey("multiple") -and $appConfig["multiple"];
}

function showWindow($process)
{
  $sig = '
    [DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern int SetForegroundWindow(IntPtr hwnd);
  '
  #if ($Maximize) { $Mode = 3 } else { $Mode = 4 }
  $type = Add-Type -MemberDefinition $sig -Name WindowAPI -PassThru
  $hwnd = $process.MainWindowHandle
  $null = $type::ShowWindowAsync($hwnd, 3)
  $null = $type::SetForegroundWindow($hwnd) 
}

function startProcess($appConfig){
  $out = $appConfig.ContainsKey("out") -and $appConfig["out"];

  $workDir = Split-Path $appConfig["path"] -Parent
  if ($out) {
    $path = $appConfig.path;
    $params = if ($appConfig.ContainsKey("params")) { $appConfig.params } else { "" }
    $command = "Start-Process '$path' $params -LoadUserProfile -WorkingDirectory '$workDir' -WindowStyle Maximized";

    pwsh.exe -Command $command
  } else {
    Start-Process $appConfig.path $appConfig.params -LoadUserProfile -WorkingDirectory $workDir| Out-Null
  }
}

function startSingleProcess($appConfig) {
  $process = getParent($appConfig.code);
  if ($null -eq $process) {
    startProcess($appConfig);
  } else {
    showWindow($process);
  }
}

function __openSingle([string] $name) {
  $appConfig = getAppConfig($name);

  if (isMultipleApp($appConfig)) {
    startProcess($appConfig);
  } else {
    startSingleProcess($appConfig);
  }
}

$appNames = toString ($config | ForEach-Object{$_.code})

$openBody = @"
function o {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=`$true, Position=0)]
    [ValidateSet($appNames)]
    [string[]]`$names
  )
  begin {}
  process {
    `$names | %{
      __openSingle `$_
    }
  }
}
"@;

function run() {
  $config | ForEach-Object{
    if ($null -ne $_['start'] -and $_.start -eq $true) {
      o $_.code
    }
  }
}

Invoke-Expression $openBody
Export-ModuleMember o, run
