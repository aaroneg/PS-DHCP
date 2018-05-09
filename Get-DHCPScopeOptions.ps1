#Requires -Version 4.0
#Get option values from a set of scopes
# Define option numbers you're looking for, and where the file is you'll be saving to. 
$OptionNumber1=186
$OptionNumber2=190
$CSVFile="$PSScriptRoot\ScopeInformation.csv"

try { Import-Module dhcpserver } catch {}
if (!(get-module dhcpserver)) {throw "Missing DHCP Server Module"}

$allServers=Get-DhcpServerInDC; $DHCPServers=@(); foreach($s in $allServers) { $DHCPServers+=$s.dnsname } # All DNS Servers
. $PSScriptRoot\DHCPHelperFunctions.ps1

# Empty array to store the results
$Results=@()
# Get all the IPv4 Scopes from the list of DHCP servers
$Scopes=Get-IPv4Scopes -Servers $DHCPServers
# Loop through
foreach ($Scope in $Scopes) {
    # Create some variables from the data
    $ServerName=$Scope.PSComputerName
    $ScopeID=$Scope.ScopeId.IPAddressToString
    # Attempt to get the value of the options defined above
    try {$value1=Get-DhcpServerv4OptionValue -ComputerName $ServerName -OptionId $OptionNumber1 -ScopeId $ScopeID -ErrorAction SilentlyContinue;$v1=$value1.Value[0]} catch {$v1=$false}
    try {$value2=Get-DhcpServerv4OptionValue -ComputerName $ServerName -OptionId $OptionNumber2 -ScopeId $ScopeID -ErrorAction SilentlyContinue;$v2=$value2.Value[0]} catch {$v2=$false}
    # Create a blank object
    $ret=New-Object -TypeName PSobject
    # Add members to it using the data generated above
    $ret|Add-Member -MemberType NoteProperty -Name ID -Value $ScopeID
    $ret|Add-Member -MemberType NoteProperty -Name ScopeName -Value $Scope.Name
    $ret|Add-Member -MemberType NoteProperty -Name Server -Value $Scope.PSComputerName
    $ret|Add-Member -MemberType NoteProperty -Name $OptionNumber1 -Value $v1
    $ret|Add-Member -MemberType NoteProperty -Name $OptionNumber2 -Value $v2
    # Add it to the results array
    $Results+=$ret
}
# Write the results as a table
$Results|format-table
$Results|Export-Csv -Path $CSVFile -NoTypeInformation
