#Requires -Version 4.0
#Get option values from a set of scopes

try { Import-Module dhcpserver } catch {}
if (!(get-module dhcpserver)) {throw "Missing DHCP Server Module"}
$OptionNumber1=186
$OptionNumber2=190

$allServers=Get-DhcpServerInDC; $DHCPServers=@(); foreach($s in $allServers) { $DHCPServers+=$s.dnsname } # All DNS Servers

###### No user editable content below this line ######
. $PSScriptRoot\DHCPHelperFunctions.ps1

$Results=@()
$Scopes=Get-IPv4Scopes -Servers $DHCPServers
foreach ($Scope in $Scopes) {
    $ServerName=$Scope.PSComputerName
    $ScopeID=$Scope.ScopeId.IPAddressToString
    try {$value1=Get-DhcpServerv4OptionValue -ComputerName $ServerName -OptionId $OptionNumber1 -ScopeId $ScopeID -ErrorAction SilentlyContinue;$v1=$value1.Value[0]} catch {$v1=$false}
    try {$value2=Get-DhcpServerv4OptionValue -ComputerName $ServerName -OptionId $OptionNumber2 -ScopeId $ScopeID -ErrorAction SilentlyContinue;$v2=$value2.Value[0]} catch {$v2=$false}
    $ret=New-Object -TypeName PSobject
    $ret|Add-Member -MemberType NoteProperty -Name ID -Value $ScopeID
    $ret|Add-Member -MemberType NoteProperty -Name ScopeName -Value $Scope.Name
    $ret|Add-Member -MemberType NoteProperty -Name Server -Value $Scope.PSComputerName
    $ret|Add-Member -MemberType NoteProperty -Name $OptionNumber1 -Value $v1
    $ret|Add-Member -MemberType NoteProperty -Name $OptionNumber2 -Value $v2
    $Results+=$ret
}
$Results|ft
$Results|Export-Csv -Path $PSScriptRoot\ScopeInformation.csv -NoTypeInformation
