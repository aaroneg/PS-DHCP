# PURPOSE: Find all leases likely to belong to a wyse thin client

# Commonly Modified options
$DHCPServers="Server1.contoso.com","Server2.contoso.com"

$ThisDir=$PSScriptRoot
. $PSScriptRoot\DHCPHelperFunctions.ps1

if (!$Scopes) {$Scopes=Get-IPv4Scopes -Servers $DHCPServers -Unique $false}
if (!$Leases) {$Leases=Get-IPv4Leases -Scopes $Scopes}
$ThinClientLeases=$Leases|Where-Object {$_.ClientId -like "00-80-64-*"}

$Leases|Export-Csv -Path "$PSScriptRoot\AllLeases.csv" -NoTypeInformation
$ThinClientLeases|Export-Csv -Path "$PSScriptRoot\WyseLeases.csv" -NoTypeInformation
