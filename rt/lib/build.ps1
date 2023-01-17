Using module ..\..\apps\cmdbase.psm1

class BuildCommand : CommandBase {
    hidden [string] $currentConfig;

    hidden [ScriptBlock] $script = {
        param([Buildcommand]$self, [string]$solution, [string]$configuration)
        process {
            if ($solution.ContainsKey("compiler")) {
                $self.currentConfig = '';
                Write-Host "Build solution '${$solution.path}' ... " -NoNewline;
                $slnPath = $solution.path;
                & $solution.compiler $slnPath /p:Platform='Any CPU' /p:Configuration=$Configuration;
                $self.currentConfig = $configuration;
                Write-Host "Build completed " -ForegroundColor Yellow -NoNewline;
                Write-Host "[OK]" -ForegroundColor Green;
            } else {
                dotnet build ($solution.path);
            }
        }
    }

    BuildCommand($config):base(
        @([ParameterBase]::new("configuration", 1, $true, @('Release', 'Debug'))),
        $this.script, $config)
    { }

    [string] getConfig() {
        return $this.currentConfig;
    }

    [void] clearConfig() {
        $this.currentConfig = '';
    }
}
