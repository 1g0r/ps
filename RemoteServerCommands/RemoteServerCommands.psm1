$configFile = @"
{
    '172.16.252.38': {
        name: 'media.scheduler',
        user: '',
        password: '',
        apps:{}
    },
    '172.16.252.39': {
        name: 'media.bundle',
        user: '',
        password: '',
        apps:{}
    }
}
"@

$context = @{
    Config=@{};
    ConfigPath= Join-Path $PSScriptRoot '\config\servers.json';
};


function loadConfig([string] $path, [switch] $debug){
    if($debug){
        return prepareConfig ($configFile | ConvertFrom-Json | Convert-ToPSObject);
    } 
    
    if((Test-Path $path)){
        $local:config = (Get-Content $path -ErrorAction SilentlyContinue) -join "`n" | ConvertFrom-Json -ErrorAction SilentlyContinue| Convert-ToPSObject -ErrorAction SilentlyContinue
        if($local:config -ne $null){
            return prepareConfig $local:config;
        }
    } else {
        Write-Host "Config file $path not found."
    }
    return $null;
}


function prepareConfig($config){
    $config.Keys |%{ $item = $config[$_]
        $item["ip"] = $_
    }
    return $config;
}

function ensureWinRM(){
    if(-not (winRmEnabled)){
        Write-Host "WinRM is not enabled. Starting it"
        $winrm = Get-Service winrm
        if($winrm -eq $null){
            Write-Host "Enabling WinRm"
            Enable-PSRemoting -Force |out-null
        } else {
            Write-host "Starting WinRM service."
            $winrm.Start()
        }
    } else {
        Write-Host "WinRm is enabled."
    }
}

function winRmEnabled(){
    return [bool](Test-WSMan -ErrorAction SilentlyContinue)
}

function editConfig(){
    npp $context.ConfigPath
}

$commands = @{
    Rdp = @{
        getParams = {
            param($config)
            $params = New-DynamicParam -Name Ip -Position 1 -ValidateSet $config.Keys -Mandatory $True
                      New-DynamicParam -Name Name -Position 2 -ValidateSet ($config.Keys |%{$config[$_].name}) -DPDictionary $params -ParameterSetName "Name"
            return $params
        };
        invoke = {
            param($config, $boundParams)
            Begin{
                $ip = $boundParams['ip'];
                $server = if(-not [string]::IsNullOrEmpty($ip)){
                    $config[$ip]
                } else {
                    $name = $boundParams['name'];
                    $config |? {$_.name -eq $name}
                }
            }
            Process{
                cmdkey /generic:TERMSRV/($server.ip) /user:($server.user) /pass:($server.password)
	            mstsc /v:($server.ip) 
            }
        };
    };
    WinRM = @{
        getParams = {
            param($config)
            $params = New-DynamicParam -Name Ip -Position 1 -ValidateSet $config.Keys -Mandatory $True
                      New-DynamicParam -Name Name -Position 2 -ValidateSet ($config.Keys |%{$config[$_].name}) -DPDictionary $params -ParameterSetName "Name"
            return $params
        };
        invoke = {
            param($config, $boundParams)
            Begin{
                $ip = $boundParams['ip'];
                $server = if(-not [string]::IsNullOrEmpty($ip)){
                    $config[$ip]
                } else {
                    $name = $boundParams['name'];
                    #$config |? {$_.name -eq $name}
					$config.Keys |% { if($config.Item($_).name -eq $name) {$config.Item($_)}}
                }
            }
            Process{
                $pass = ConvertTo-SecureString $server.password -AsPlainText -Force
                $cred = New-Object System.Management.Automation.PSCredential ("$($server.user)", $pass)
                Enter-PSSession $server.ip -Credential $cred
            }
        };
    };
    Config = @{
        getParams = {}
        invoke = {
            npp $context.ConfigPath
        }
    }
}

function Server{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("Rdp", "WinRM", "Config")]
        [String]$Command
    )
    DynamicParam{ 
        if($commands.ContainsKey($Command)){
           return & $commands[$Command].getParams $context.Config
        }    
    }
    
    Begin
    {
        $cmd = $commands[$Command];
    }
    Process
    {
        if($cmd -ne $null){
            & $cmd.invoke $context.Config $PSBoundParameters
        }
    }
}

function main(){
    ensureWinRM
    #$config = loadConfig $configFile -debug
    $config = loadConfig $context.ConfigPath
    if($config -ne $null){
        $context.Config = $config;
    }
    #TODO: configure hosts
}


main;

Export-ModuleMember Server