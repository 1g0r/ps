Using module ..\..\apps\CommandBase.psm1

class DelRequestCommand : CommandBase {
  hidden $profiles;
  
  DelRequestCommand($config):base(
    @(
      [ParameterBase]::new("profile", 1, $true, $config.profiles.Keys),
      [ParameterBase]::new("phone", 2, $true, @('+7916...', '+7916...', '+7916...'))
    ),
    $this.script) 
  {
    $this.profiles = $config.profiles;
  }
  
  hidden [ScriptBlock] $script = {
    param([DelRequestCommand]$self, [string]$profileName, [string]$phone)
    
    $server = $self.profiles[$profileName]
    $query = "use $($server.database); go select...from..."
    
    Invoke-Sqlcmd -ServerInstance $server.server -Database $server.database -Username $server.user -Password $server.password -Query $query
  }
}
