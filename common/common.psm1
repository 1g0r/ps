function lock() {
    rundll32.exe user32.dll LockWorkStation;
}

function reboot() {
    shutdown /r /f /t 0;
}

function off() {
    shutdown /p /f;
}

function iis() {
    & "$env:windir\system32\inetsrv\InetMgr.exe";
}

function gac {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Path
        [switch]$Install
    )
    begin {
        [System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a");
        $publish = New-Object System.EnterpriseServices.Internal.Publish;
    }
    process {
        if (-not (Test-Path $Path)){
            Write-Error "File '$Path' Not Found!";
            return;
        }
        if ($Install){
            $publish.GacInstall($path);
        } else {
            $publish.GacRemove($path);
        }
    }
}

function npp {
    param(
        [string]$path,
        [switch]$systemTray,
        [switch]$noSession
    )

    $expr = "c:\Program Files (x86)\Notepad++\notepad++.exe";
    & $expr $(if($systemTray.IsPresent) {'-systemtray'} else {''}) `;
    $(if($noSession.IsPresent) {'-nosession'} else {''}) `;
    $path;
}

function hosts() {
    c:\windows\system32\notepad.exe c:\windows\system32\drivers\etc\hosts;
}

function ConvertTo-HashTable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
        $object
    )
    $type = $object.GetType();
    if ($type.Name.Equals('PSCustomObject', [System.StringComparison]::InvariantCultureIgnoreCase)){
        $result = @{};
        $object.psobject.properties | %{ $result[$_.name] = (Convetr-ToHashTable $_.value) };
        return $result;
    }
    if ($type.IsArray){
        $arr = @();
        $object | %{ $arr += (Convert-ToHashTable $_) };
        return $arr;
    }

    return $object;
}

Export-ModuleMember ConvertTo-HashTable, hosts, npp, gac, iis, off, reboot, lock;