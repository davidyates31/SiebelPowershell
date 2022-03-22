<#
    .SYNOPSIS
        Starts Siebel servers for a Siebel enterprise
    .DESCRIPTION
        Starts Siebel servers for a Siebel enterprise using an enterprise code index.  Enterprise servers need to be defined in file C:\VSCode\OCI\servers.csv
        CSV file format:
            1. EnterpriseCode (unique code identifying the Siebel enterprise)
            2. ServerName (server alias name in OCI)
            3. ServerDescription (description of the Siebel server function)
            4. OCID (unique identifier in OCI)
            5. Priority (order of starting)
            6. WaitBetween (time to wait before starting/stopping the next server, if not the last server in the enterprise list)
    .EXAMPLE
        Invoke-StartSiebelServers 'Dev'
    .PARAMETER EnterpriseCode
        enterprise code defined in the 1st column of the servers.csv file.  Case-insensitive
    .NOTES
        Name            Date        Ver     Comments
        D Yates         22/03/2022  1.0     Created
#>
function Invoke-StartSiebelServers{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, 
            HelpMessage='Enter a Siebel enterprise code - e.g. Dev, Test, Prod',
            ValueFromPipeline=$true,
            Position=0)]
        [ValidateLength(3,5)]
        [string]$EnterpriseCode,
        [switch]$ErrorLog,
        [string]$LogFile = 'C:\VBCode\Error.log'
    )
    begin {
        if($ErrorLog){
            Write-Verbose "Error logging is switched on"
        }
        $server = GetSiebelServers($EnterpriseCode)
    }
    process {
        $i = 0
        if($server.Count -gt 0){
            $server = $server | Sort-Object -Property "Priority"
            foreach($s in $server){
                $i++
                Write-Output "Starting $($s.ServerDescription)"
                Invoke-OCIComputeInstanceAction -InstanceId $s.OCID -Action START
                if ($i -ne $server.Count){
                    Write-Output "Waiting $($s.WaitBetween) seconds before next action"
                    Start-Sleep -Seconds $s.WaitBetween
                }
            }
            Write-Output "Invoke-StartSiebelServers for enterprise $EnterpriseCode completed"
        } else {
            Write-Error "Cannot find any servers for enterprise $EnterpriseCode" -Category ResourceUnavailable
        }
    }
    end {

    }

}

<#
    .SYNOPSIS
        Stops Siebel servers in a Siebel enterprise
    .DESCRIPTION
        Stops Siebel servers for a Siebel enterprise using an enterprise code index.  Enterprise servers need to be defined in file C:\VSCode\OCI\servers.csv
        CSV file format:
            1. EnterpriseCode (unique code identifying the Siebel enterprise)
            2. ServerName (server alias name in OCI)
            3. ServerDescription (description of the Siebel server function)
            4. OCID (unique identifier in OCI)
            5. Priority (order of starting)
            6. WaitBetween (time to wait before starting/stopping the next server, if not the last server in the enterprise list).  Order is reversed for stoppoing servers
    .EXAMPLE
        Invoke-StopSiebelServers 'Dev'
    .PARAMETER EnterpriseCode
        Enterprise code defined in the 1st column of the servers.csv file.  Case-insensitive
    .NOTES
        Name            Date        Ver     Comments
        D Yates         22/03/2022  1.0     Created
#>
function Invoke-StopSiebelServers{
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact="Medium"
    )]
    param(
        [Parameter(
            Mandatory, 
            HelpMessage = "Enter a Siebel enterprise code - e.g. Dev, Test, Prod",
            Position = 0
        )]
        [ValidateLength(3,5)]
        [string]$EnterpriseCode
    )
    begin {
        if($ErrorLog){
            Write-Verbose "Error logging is switched on"
        }
        $server = GetSiebelServers($EnterpriseCode)
    }
    process {
        $i = 0
        if($server.Count -gt 0){
            $server = $server | Sort-Object -Property "Priority" -Descending
            foreach($s in $server){
                $i++
                Write-Output "Stopping $($s.ServerDescription)"
                Invoke-OCIComputeInstanceAction -InstanceId $s.OCID -Action STOP
                if ($i -ne $server.Count){
                    Write-Output "Waiting $($s.WaitBetween) seconds before next action"
                    Start-Sleep -Seconds $s.WaitBetween
                }
            }
            Write-Output "Invoke-StopSiebelServers for enterprise $EnterpriseCode completed"
        } else {
            Write-Error "Cannot find any servers for enterprise $EnterpriseCode" -Category ResourceUnavailable
        }
    }
    end {

    }
}

function GetSiebelServers($EnterpriseCode){
    $ServerList = Import-Csv -Path "C:\VSCode\OCI\servers.csv" 
    $server = $ServerList.where({$_.EnterpriseCode -eq $EnterpriseCode})
    # List of OCIDs for known OCI servers
    if($server.Count -eq 0) {
        Write-Error "enterprise $EnterpriseCode is not currently supported" -Category InvalidArgument
    } else {
        return $server
    }
}
