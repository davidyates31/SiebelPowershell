[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentCode,
    [Parameter(Mandatory=$true)]
    [string]$Action
)

function Invoke-StartSiebelServers{
    $i = 0
    if(GetSiebelServers){
        foreach($server in $servers){
            $i++
            Write-Output "Starting server "$server.DisplayName
            # Invoke-OCIComputeInstanceAction -InstanceId $server.OCID -Action $Action.ToUpper()
            if ($i -ne $servers.Count){
                Write-Output "Waiting "$server.WaitBetween" seconds before next action"
                Start-Sleep -Seconds $server.WaitBetween
            }
        }
    }
}

function Invoke-StopSiebelServers{
    $i = 0
    if(GetSiebelServers){
        $servers = $servers | Sort-Object -Property "Priority" -Descending
        foreach($server in $servers){
            $i++
            Write-Output "Stopping server "$server.DisplayName
            # Invoke-OCIComputeInstanceAction -InstanceId $server.OCID -Action $Action.ToUpper()
            if ($i -ne $servers.Count){
                Write-Output "Waiting "$server.WaitBetween" seconds before next action"
                Start-Sleep -Seconds $server.WaitBetween
            }
        }
    }
}

function GetSiebelServers{
    $ServerList=Import-Csv -Path "C:\VSCode\OCI\servers.csv" 
    $servers = $ServerList.where({$_.EnvCode -eq $EnvironmentCode})
    # List of OCIDs for known OCI servers
    if($servers.Count -eq 0) {
        Write-Error "Environment $EnvironmentCode is not currently supported" -Category InvalidArgument
        return $false
    } else {
        return $true
    }
}
