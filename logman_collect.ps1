####################################################################
# Script to create/start/collect custom set of counters in PerfMon #
####################################################################

# SCRIPT FUNCTIONS

# Final output and jump to logs
function End-Script {
		Write-Host -ForegroundColor Yellow "The script execution is completed. Please see logs, located in $rootlogpath for session results"		
		Explorer.exe $rootlogpath
}

# SCRIPT BODY

# Show Info
Start-Sleep 1
Write-Warning -Message "This script is provided as is as a courtesy for automated collection of PerfMon counters.
There is no support provided for this script. `nIf it fails, please proceed to run collection manually as instructed by your Support Engineer."

# Checking elevation rights
Start-Sleep 1
Write-Host "`nChecking elevation rights"
Start-Sleep 1
if (!(New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  Write-Host -ForegroundColor Yellow "You're running PowerShell without elevated rights. Please open a PowerShell window as an Administrator. `nScript will be stopped in 5 seconds automatically."
  Start-Sleep 5
  Break
}
else {Write-Host -ForegroundColor Green "You're running PowerShell as an Administrator."}

# Variables
$rootlogpath = "C:\temp\"
$countname = "$env:COMPUTERNAME-Perf-Counter-Log"
$fulllogpath = $rootlogpath + $countname
$duration = "00:01:00"
$interval = "00:00:01"
$timespan = [System.TimeSpan]::Parse($duration)

# Checking for $rootlogpath presence
if(!(Test-Path $rootlogpath)){
   Write-Host -ForegroundColor Red "$rootlogpath folder is not found. Creating it to store temporary files"
   [System.IO.Directory]::CreateDirectory($rootlogpath) | Out-Null
}

# Create counter
logman.exe create counter $countname -cnf 0 -f bincirc -v mmddhhmm -max 250 -o $fulllogpath `
 -c "\LogicalDisk(*)\*" "\Memory\*" "\PhysicalDisk(*)\*" "\Process(*)\*" "\Processor(*)\*" `
 -si $interval -rf $duration

# Execution
Start-Sleep 1
if (logman.exe start $countname){
    $starttime = (Get-Date -Format "MM.dd.yyyy HH:mm:ss").ToString()
	Write-Host -ForegroundColor Yellow "Started: $starttime, duration HH:mm:ss: $duration."
}


# Start-Sleep for the 'duration' time
Start-Sleep -Seconds ([int]([System.Math]::Round($TimeSpan.TotalSeconds,0)))

# Check collection status, if still running - attempt a force stop
Start-Sleep 1
$status = logman.exe query $countname
if ($status.Item(2).ToString() | select-string "Running") {
    Write-Host -ForegroundColor Yellow `
    "Collection is still running, forcing stop..."
	logman.exe stop $countname
}
elseif ($status.Item(2).ToString() | select-string "Stopped") {
	Write-Host -ForegroundColor Green `
    "Collection has been stopped, preparing capture file..."
}
else {
    Write-Host -ForegroundColor Red `
    "Unexpected result, please re-run 'logman.exe query' command to check data collection status."
    Break
}

# Remove the data collection counter
Start-Sleep 1
logman.exe delete $countname

End-Script