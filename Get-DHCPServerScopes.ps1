#Requires -Version 4.0

## Set to $true if you want only a single instance of each scope
$Unique=$true # {$false|$true} 
$CSVFile="$PSScriptRoot\ScopeList.csv"

if (!(get-module dhcpserver)) {
    try {Import-Module dhcpserver}
    catch {throw "Missing DHCP Server Module"}
}

$allServers=Get-DhcpServerInDC; $DHCPServers=@(); foreach($s in $allServers) { $DHCPServers+=$s.dnsname }

. $PSScriptRoot\DHCPHelperFunctions.ps1

$Scopes=Get-IPv4Scopes -Servers $DHCPServers -Unique $Unique
$shortList=$Scopes|Select ScopeId,Description,Name,State
$shortList|Export-Csv -Path $CSVFile -NoTypeInformation
