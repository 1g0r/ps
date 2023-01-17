Using module ..\..\apps\cmdbase.psm1

class BranchCommand : CommandBase {
    hidden [string] $user;

    BranchCommand($config): base (
        @(
            [ParametersBase]::new("from", 1, $true, { $t = pwd; return [CommandBase]::getBranches($t.Path, $config.user, $false); });
            [ParametersBase]::("to", 2, $true)
        ),
        $this.script,
        $config)
    {
        $this.user = $config.user;
    }

    hidden [ScriptBlock] $script = {
        param([BranchCommand]$self, [hashtable]$solution, [string]$from, [string]$to)

        $exist = [CommandBase]::getBranches($solution.root, $self.user, $true) | where { $_ -eq $to }
        if ($exist.Length -gt 0) {
            Write-Host "Branch " -ForegroundColor Yellow -NoNewline;
            Write-Host $to -ForegroundColor Green -NoNewline;
            Write-Host " already exicts!" -ForegroundColor Yellow;
            return;
        }

        $curPath = Get-Location;
        Set-Location $solution.root;
        git checkout $from;
        git pull origin $from;
        $newBranch = "$($self.user)/$to";
        git branch $newBranch;

        git checkout $newBranch;
        git push -u origin $newBranch;
        Set-Location $curPath;
    }
}
