$configFile = @"
{
    Servers: {
        '172.16.252.38': {
            user: 'trustsys',
            password: 'cYZ7WNm#Qu'
        },
        '172.16.252.39': {
		    user: 'trustsys',
		    password: 'cYZ7WNm#Qu'
	    },
	    '172.16.252.30': {
		    user: 'trustsys',
		    password: 'cYZ7WNm#Qu'
		}
    },
	
	Components: {
		AngleSharp: {
            Name: 'Mindscan.Media.Hosts.AngleSharp',
            Servers: ['172.16.252.30', '172.16.252.38', '172.16.252.39']
		},
		BoardParser: {
            Name: 'Mindscan.Media.BoardParser.Host',
            Servers: ['172.16.252.39']
		},
        PageParser: {
            Name: 'Mindscan.Media.PageParser.Host',
            Servers: ['172.16.252.30', '172.16.252.39']
        }
	}
}
"@

$context = @{
    Config=@{};
    ConfigPath= Join-Path $PSScriptRoot '\config\mediaConfig.json';
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
    $config.servers.Keys |%{ $item = $config.servers[$_]
        $item["ip"] = $_
    }
    return $config;
}

function getSession($server){
    $pass = ConvertTo-SecureString $server.password -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ($server.user, $pass)
    return New-PSSession -ComputerName ($server.ip) -Credential $cred
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

function cleanRabbitQueues($vhost){
	$rabbitCmd = "d:\RabbitMQ Server\rabbitmq_server-3.6.15\sbin\rabbitmqctl.bat";
    & $rabbitCmd list_queues -p $vhost messages name | %{
        Write-host $_;
        $arr = $_.Split("`t")
        if($arr.Length -eq 2){
            $count = [System.Int32]::Parse($arr[0])
            if($count -gt 0){
                & $rabbitCmd purge_queue -p $vhost $arr[1]
            }
        }
    }
}

$commands = @{
    Start = @{
        invoke = {
            param($component, $servers, $serversConfig)
            begin{}
            process{
                if($servers -eq $null -or $servers.Length -eq 0){
                    return
                } 
                $servers |% {
                    $session = getSession ($serversConfig[$_])
                    Invoke-Command -Session $session -ScriptBlock {
                        param($name)
                        $service = Get-service -Name $name
                        if($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Stopped){
                            $service.Start()
                            $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Running)
                            Write-Host 'Ash was started'
                        }
                    } -ArgumentList $component.Name

                    Remove-PSSession $session
                    Write-Host "Service '$($component.Name)' was started on '$_'"
                }
            }
        };
    };

    Stop = @{
        invoke = {
            param($component, $servers, $serversConfig)
            begin{}
            process{
                if($servers -eq $null -or $servers.Length -eq 0){
                    return
                } 
                $servers |% {
                    $session = getSession ($serversConfig[$_])
                    Invoke-Command -Session $session -ScriptBlock {
                        param($name)
                        $service = Get-service -Name $name
                        if($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running){
                            $service.Stop()
                            $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Stopped)
                            Write-Host 'Ash was stopped'
                        }
                    } -ArgumentList $component.Name

                    Remove-PSSession $session
                    Write-Host "Service '$($component.Name)' was stopped on '$_'"
                }
            }
        };
    };

    Config = @{
	    invoke = {
		    npp $context.ConfigPath
	    }
    };

    Delete = @{
        invoke = {
            param($component, $servers, $serversConfig)
            begin {}
            process{
                if($servers -eq $null -or $servers.Length -eq 0){
                    return
                } 
                $servers |%{
                    $session = getSession ($serversConfig[$_])
                    Invoke-Command -Session $session -ScriptBlock {
                        param($name)
                        $service = Get-service -Name $name
                        if($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running){
                            $service.Stop()
                            $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Stopped)
                            Write-Host 'Ash was stopped'
                        }
                        $service = Get-WmiObject -Class Win32_Service -Filter "Name='$name'"
                        $service.Delete()
                    } -ArgumentList $component.Name
                    Remove-PSSession $session
                    Write-Host "Service '$($component.Name)' was removed from '$_'"
                }
            }
        }
    };
	
	CleanBin = @{
		invoke = {
			Write-Host "Cleam bin..." -ForegroundColor Yellow
			Get-ChildItem c:\__Repo\trustsys\cr-media\ -include bin,obj -Recurse | % { 
				Write-Host "Remove $($_.fullname)..." -NoNewline
				Write-Host "[OK]" -ForegroundColor Green
				remove-item $_.fullname -Force -Recurse 
			}
			Write-Host "Clean bin done!" -ForegroundColor Green
		}
	};
	
	CleanQueue = @{
		invoke = {
			Write-Host "Clear Rabbit Queues..." -ForegroundColor Yellow
			cleanRabbitQueues '/'
			cleanRabbitQueues Media 
			cleanRabbitQueues Smi
			cleanRabbitQueues Prizma 
			cleanRabbitQueues Scheduler 
			Write-Host "Clean Queues done!" -ForegroundColor Green
		}
	};
	
	CleanDb = @{
		invoke = {
			Write-Host "Clean DB..." -ForegroundColor Yellow
			& 'C:\Program Files\PostgreSQL\9.6\bin\psql.exe' -h localhost -d cr_media -U postgres -c "delete from integration.materials;"
			& 'C:\Program Files\PostgreSQL\9.6\bin\psql.exe' -h localhost -d cr_media -U postgres -c "delete from integration.last_by_published_at;"
			& 'C:\Program Files\PostgreSQL\9.6\bin\psql.exe' -h localhost -d cr_media -U postgres -c "delete from availability.available_sources;"
			& 'C:\Program Files\PostgreSQL\9.6\bin\psql.exe' -h localhost -d media -U postgres -c "DELETE FROM collector.materials;"
			Write-Host "Clean DB done!" -ForegroundColor Green
		}
	};
	
	CleanAll = @{
		invoke = {
			Media CleanQueue
			Media CleanDb
			Media CleanBin
		}
	};
	
	Restore = @{
		invoke = {
			Write-Host "Restore NuGet packages..." -ForegroundColor Yellow
			if (Test-Path "C:\__Repo\trustsys\cr-media\packages\") {
				Remove-Item C:\__Repo\trustsys\cr-media\packages\ -Recurse -Force
			}
			& 'c:\__Repo\trustsys\cr-media\.nuget\NuGet.exe' restore c:\__Repo\trustsys\cr-media\Mindscan.Media.sln
			Write-Host "Restore NuGet packages done!" -ForegroundColor Green
		}
	};

	Build = @{
		invoke = {
			& 'C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe' c:\__Repo\trustsys\cr-media\Mindscan.Media.sln /t:Rebuild /p:Configuration=Release /p:Platform="x64"
		}
	};
	
	Run = @{
		invoke = {
			Start-Process 'c:\__Repo\trustsys\cr-media\BRIDGE\Mindscan.Media.Hosts.Bridge\bin\x64\Debug\Mindscan.Media.Hosts.Bridge.exe' -WindowStyle Minimized
			Start-Process 'c:\__Repo\trustsys\cr-media\Mindscan.Media.Hosts.CollectorsIntegration\bin\x64\Debug\Mindscan.Media.Hosts.CollectorsIntegration.exe' -WindowStyle Minimized
			Start-Process 'c:\__Repo\trustsys\cr-media\Mindscan.Media.Hosts.CrawlController\bin\x64\Debug\Mindscan.Media.Hosts.CrawlController.exe' -WindowStyle Minimized
			Start-Process 'c:\__Repo\trustsys\cr-media\ANGLESHARP\Mindscan.Media.Hosts.AngleSharp\bin\x64\Debug\Mindscan.Media.Hosts.AngleSharp.exe'
			Start-Process 'c:\__Repo\trustsys\cr-media\BUNDLE4\Mindscan.Media.PageParser.Host\bin\x64\Debug\Mindscan.Media.PageParser.Host.exe'
			Start-Process 'c:\__Repo\trustsys\cr-media\BUNDLE4\Mindscan.Media.BoardParser.Host\bin\x64\Debug\Mindscan.Media.BoardParser.Host.exe'
		}
	};
	
	Kill = @{
		invoke = {
			gps Mindscan.Media* |kill
		}
	};
	
	UI = @{
		invoke = {
			& 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe' http://localhost:5000/sources
		}
	};
	
	Rmq = @{
		invoke = {
			& 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe' http://localhost:15672/#/queues
		}
	};
	
	PR = @{
		invoke = {
			& 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe' https://bitbucket.org/trustsys/cr-media/pull-requests/
		}
	};

    Merge = @{
        invoke = {
            git checkout master;
            git fetch -p -a;
            git pull;
            git checkout fixes;
            git merge master --no-ff;
            git branch;
        }
    };
}

function toString($arr){
    $result = ""
    $arr |%{
        $result += "'$_', "
    }
    return $result.Remove($result.Length - 2, 2)
}

function Execute($commandName, $component, $servers){
    $cmd = $commands[$commandName]
    $compConfig = $context.Config.Components[$component]

    if($servers -eq $null -or $servers.Length -eq 0){
        $servers = $compConfig.Servers
    }
    
    if($cmd -ne $null){
        & $cmd.invoke $compConfig $servers $context.Config.servers
    }
}



function main(){
    ensureWinRM
    #$config = loadConfig $configFile -debug $true
    $config = loadConfig $context.ConfigPath
    if($config -ne $null){
        $context.Config = $config;
    }
    #TODO: configure hosts
}


main;

# API
$componentSet = toString ($context.Config.Components.Keys)
$commandSet = toString $commands.Keys

$body = @"
function Media{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=`$true, Position=0)]
        [ValidateSet($commandSet)]
        [String]`$Command,
        [Parameter(Position=1)]
        [ValidateSet($componentSet)]
        [String]`$Component
    )

    DynamicParam{ 
        if(-not(`$Component -eq `$null) -and `$context.Config.Components.ContainsKey(`$Component)){
             `$params = New-DynamicParam -Name Server -Position 2 -ValidateSet (`$context.Config.Components[`$Component].Servers) -Type ([string[]])  
            return `$params 
        }
    }
      
    Process
    {
        Execute `$Command `$Component `$PSBoundParameters['Server']
    }
}
"@

Invoke-Expression $body

Export-ModuleMember Media