# Ensure elevated

# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
 
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole))
   {
   # We are running "as Administrator" - so change the title and background color to indicate this
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   $Host.UI.RawUI.BackgroundColor = "DarkBlue"
   clear-host
   }
else
   {
   # We are not running "as Administrator" - so relaunch as administrator
   
   # Create a new process object that starts PowerShell
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   
   # Specify the current script path and name as a parameter
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   
   # Indicate that the process should be elevated
   $newProcess.Verb = "runas";
   
   # Start the new process
   [System.Diagnostics.Process]::Start($newProcess);
   
   # Exit from the current, unelevated, process
   exit
   }
 
# Run your code that needs to be elevated here
Write-Host -NoNewLine "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
cls
##############

function remove-host([string]$hostname) {
    $rplaceStr = ""
    $rHost = "C:\Windows\System32\drivers\etc\hosts"
    $items = Get-Content $rHost | Select-String $hostname
    foreach( $item in $items)
        {
        (Get-Content $rHost) -replace $item, $rplaceStr| Set-Content $rHost
        }
}


function Resolve-AkamaiStageIp($hostname)
    {
    $result = resolve-dnsname $hostname -NoHostsFile
    $result = $result | ? {$_.namehost -like "*edgekey*"}
    if ($result -notlike "*edgekey*")
        {
        $result = $result.namehost.insert(($result.namehost.Length)-4, "-staging")
        write-host "stage record is" $result "! Adding host file entry.."
        $stage = Resolve-DnsName -Name $result
        "$($stage.IP4Address) $hostname"| add-content "$env:windir\system32\drivers\etc\hosts"
        }
    else{write-host "thing was an ip instead" $result.namehost}
    }

function Get-Hostname
    {
    $hostname = read-host "What's the hostname? order.domain.com.au for e.g."
    if ($hostname -match "(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63}$)")
        {
        Resolve-AkamaiStageIp -hostname $hostname
        read-host "do your testing, once done, press enter to restore host file"
        remove-host -hostname $hostname 
        exit
        }
    else {write-host -ForegroundColor red "Hostname was incorrect! Try again"
    get-hostname
    }
}
get-hostname