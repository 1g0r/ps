Using module ..\..\apps\cmdbase.psm1;

class  MergeCommand : CommandBase {
    hidden [string] $user;

    hidden [ScriptBlock] $script = {
        param([MergeCommand]$self, [hashtable]$solution, [string]$from, [string]$to)
        process {
            $curPath = Get-Location;

            cd $solution.root;
            git checkout $from;
            git pull;
            git checkout "$($self.user)/$to";
            git merge $from;
            cd $curPath;
        }
    }

    MergeCommand($config) : base(
        @(
        [ParameterBase]::new("from", 1, $true, { $t = pwd; return [CommandBase]::getBranches($t.Path, $config.user, $false); });
        [ParameterBase]::new("to", 2, $true, { $t = pwd; return [CommandBase]::getBranches($t.Path, $config.user, $true); })
        ),
        $this.script, $config
    )
    {
        $this.user = $config.user;
    }
}
