class ParameterBase {
    [string] $name;
    [Type] $type;
    [int] $position;
    [bool] $mandatory;
    [string[]] $validateSet;
    [ScriptBlock] $getValidateSet;
    $defaultValue;

    hidden [void] setFields(
        [string]$name, 
        [int]$position, 
        [bool]$mandatory, 
        [string[]]$validateSet = $null,
        [ScriptBlock]$getValidateSet = $null,
        [Type]$type) {
        if ([string]::IsNullOrEmpty($name)) {
            throw "Parameter must have name!"
        }
        $this.name = $name;

        if ($null -eq $position -or $position -eq 0) {
            $this.position = 1
        } else {
            $this.position = $position
        }

        $this.mandatory = if ($null -ne $mandatory) { $mandatory } else { $false }
        $this.validateSet = $validateSet
        $this.getValidateSet = $getValidateSet
        $this.type = if ($null -eq $type) { [string] } else { $type }
        if ($this.type -eq [bool]) {
            $this.defaultValue = $false;
        } elseif ($this.type -eq [datetime]) {
            $this.defaultValue = Get-Date;
        } else {
            $this.defaultValue = $null;
        }
    }

    ParameterBase([string]$name) {
        $this.setFields($name, 1, $false, $null, $null, [string]);
    }

    ParameterBase([string]$name, [int]$position, [bool]$mandatory) {
        $this.setFields($name, $position, $mandatory, $null, $null, [string]);
    }

    ParameterBase([string]$name, [int]$position, [bool]$mandatory, [string[]]$validateSet) {
        $this.setFields($name, $position, $mandatory, $validateSet, $null, [string]);
    }

    ParameterBase([string]$name, [int]$position, [bool]$mandatory, [string[]]$validateSet, [type]$type) {
        $this.setFields($name, $position, $mandatory, $validateSet, $null, $type);
    }

    ParameterBase([string]$name, [int]$position, [bool]$mandatory, [ScriptBlock]$getValidateSet) {
        $this.setFields($name, $position, $mandatory, $null, $getValidateSet, [string]);
    }

    ParameterBase([string]$name, [int]$position, [bool]$mandatory, [Type]$type) {
        $this.setFields($name, $position, $mandatory, $null, $null, $type);
    }

    [System.Management.Automation.RunTimeDefinedParameter] Build([string] $paramName) {
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
            if ($null -ne $setOfValues -and $setOfValues.Lengh -ge 0) {
                $attribute = New-Object System.Management.Automation.ValidateSetAttribute($setOfValues)
                $attributeCollection.Add($attribute)
            }
        }
        $dynParam = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter($this.name, $this.type, $attributeCollection)
        return $dynParam    
    }
}

class CommandBase {
    [ParameterBase[]] $parameters;
    [ScriptBlock] $body;
    [hashtable] $solutions;

    CommandBase([ParameterBase[]]$parameters, [ScriptBlock]$body, [hashtable]$config) {
        if ($this.shouldAddSlnParameter($parameters, $config)) {
            $this.parameters = $parameters + @(, [ParameterBase]::new("sln", $parameters.Length + 1, $false, $config.solutions.Keys));
        } else {
            $this.parameters = $parameters;
        }

        if ($null -eq $body) {
            throw "Command body can not be null";
        }
        $this.body = $body;
        $this.solutions = $config.solutions;
    }

    [System.Management.Automation.RuntimeDefinedParameterDictionary] BuildParameters() {
        $result = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
        foreach ($param in $this.parameters) {
            $result.Add($param.name, $param.Build($param.name))
        }
        return $result;
    }

    [void] Invoke([hashtable] $psParams) {
        $argv = @($this);
        $solution = $this.fetchSolution($psParams);
        if ($null -ne $solution) {
            $argv += @(, $solution);
        }

        $paramsMeta = $this.BuildParameters();
        foreach($key in $paramsMeta.Keys) {
            if ($psParams.ContainsKey($key)) {
                $argv += @(, $psParams[$key]);
            } else {
                $defaultValue = $this.parameters | Where-Object {$_.name -eq $key};
                $argv += @(, $defaultValue.defaultValue);
            }
        }
        Invoke-Command -ScriptBlock $this.body -ArgumentList $argv | Out-Default
    }

    static [string[]] getBranches([string]$repoPath, [string]$user, [bool]$mine = $false) {
        $curPath = Get-Location;
        Set-Location $repoPath
        $result = if ((Test-Path .\.git)) {
            git branch |
            Where-Object { if ($mine) { $_.Contains($user) } else { -not $_.Contains($user) } } |
            ForEach-Object { $_.Trim("*", " ").Replace("$($user)/", "") } |
            Sort-Object
        } else {
            @()
        }
        Set-Location $curPath
        return $result;
    }

    static [int] removeFolder([string]$path, [System.Management.Automation.PSMethod]$shouldDelete, [bool]$recurse) {
        if (-not (Test-Path $path)) {
            return 0;
        }
        $count = 0
        $items = if ($recurse) { Get-ChildItem $path -Recurse -Directory } else { Get-ChildItem $path -Directory }
        foreach ($dir in $items) {
            if ($shouldDelete.Invoke($dir)) {
                Write-Host $dir.FullName -NoNewline
                Write-Host ('.' * (120 - $dir.FullName.Length)) -NoNewline
                Remove-Item $dir.FullName -Resurse -Force
                Write-Host ' DELETED' -ForegroundColor Green
                $count++
            }
        }
        return $count;
    }

    hidden [bool] shouldAddSlnParameter([ParameterBase[]] $parameters, [hashtable] $config) {
        return $null -ne $parameters -and
        $null -ne $config -and $null -ne $config.solutions -and $config.solutions.count -gt 0;
    }

    hidden [hashtable] fetchSolution([hashtable] $psParams) {
        $key = $psParams['sln'];
        if ([string]::IsNullOrEmpty($key)) {
            return $this.fetchSolutionFromCurrentDir();
        }
        $psParams.Remove($key);
        $result = $this.solutions[$key];
        if ($null -ne $result) {
            $result['key'] = $key;
        }
        return $result;
    }

    hidden [hashtable] fetchSolutionFromCurrentDir() {
        $sln = if ((Test-Path .\src)) {
            Get-Item .\src\*.sln
        } else {
            Get-Item .\*.sln
        }
        if ($null -ne $sln) {
            $slnRoot = $sln.fullname.ToLower();
            foreach($key in $this.solutions.Keys) {
                $solution = $this.solutions[$key];
                if ($slnRoot -eq $solution.path.ToLower()) {
                    $solution['key'] = $key;
                    return $solution;
                }
            }
        }
        return $null;
    }
}