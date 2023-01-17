[ScriptBlock]$disableProxy = {
    $regKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
    while($true) {
        $enabled = Get-ItemPropertyValue -Path $regKey -Name ProxyEnable
        if ($enabled -eq 1) {
            Set-ItemProperty -path $regKey ProxyEnable -value 0
            Write-Host 'System proxy have been Disabled!'
        } else {
            Write-Host 'System proxy is Disabled'
        }

        Start-Sleep -s 5
    }
}

$jobName = 'StopProxyJob'

Start-Job -Name $jobName -ScriptBlock $disableProxy
