<#
    Create a class C IPv4 DHCP subnet split between 2 DHCP servers Starting at .5 and going up to 254.
    If you specify more than one scope to create, they will all share the same name.
    See https://technet.microsoft.com/en-us/library/jj590728%28v=wps.630%29.aspx?f=255&MSPPError=-2147217396 for more information.
    This script may have errors. Use a testing environment to validate that it does what you want.
#>
# Commonly Changed per run
$ScopeName="" # "Subnet 000"
$DHCPServers="","" # "Server1","Server2" (This script expects exactly 2 servers)
$Scopes="","" # "10.2.8.0","10.2.9.0","10.2.10.0","10.2.11.0","10.2.13.0","10.2.14.0","10.2.15.0"
$DNSServers='','' # "8.8.8.8","8.8.4.4"

# Less Commonly Changed
$RouterLastOctet=1   # 10.2.4.1

# Define the function we'll use later
Function Add-ClassCIPV4SplitScope {
    [CmdletBinding()]
    PARAM(
        [parameter(Mandatory=$true)][string]$Scope,
        [parameter(Mandatory=$true)][string]$Name,
        [parameter(Mandatory=$true)][int]$RouterLastOctet,
        [parameter(Mandatory=$true)][string[]]$DNSServers,
        [parameter(Mandatory=$true)][string[]]$DHCPServers
    )
    # This script expects exactly 2 dhcp servers
    if ($DHCPServers.Count -ne 2) { throw "Incorrect number of DHCP servers. Expecting exactly 2" }
    if ($Name.Length -lt 1 ) { throw "Missing scope name" }

    #Split the scope into an array to get a usable string
    $ScopeArray=$Scope.Split('.')
    # Should return something like '10.2.8'
    $ScopePrefix=($ScopeArray[0],$ScopeArray[1],$ScopeArray[2]) -join '.'
    # Add the last octect to the prefix to specify the router like 10.2.8.1
    $RouterAddress=($ScopePrefix,$RouterLastOctet) -join '.'
    # Create empty array of the scopes we've created
    $CreatedScopes=@()
    try {
        <#
        # Add a scope with some default options. Range starts at .5, ends at .128, 
        # has a class "C"(/24) subnet mask, and a lease duration of 8 hours.
        # It then sets the options on the scope for the router and DNS servers.
        # We do not define domain suffixes - domain joined windows computers know what their domain is,
        # but you may wish to set them if you're using some other OS.
        #>
        $ThisScope=Add-DHCPServerv4Scope -ComputerName $DHCPServers[0] -Name $Name -StartRange ($ScopePrefix+".5") -EndRange ($ScopePrefix+".128") -SubnetMask '255.255.255.0' -LeaseDuration 0.08:00:00 -PassThru  #-whatif 
        $ThisScope|Set-DhcpServerv4OptionValue -ComputerName $DHCPServers[0] -OptionId 003 -Value $RouterAddress 
        $ThisScope|Set-DhcpServerv4OptionValue -ComputerName $DHCPServers[0] -OptionId 006 -Value $DNSServers
        $CreatedScopes+=$ThisScope
        # Lazily write whatever the hell went wrong if something did:
    } catch { $_|Write-Warning } 
    try {
        $ThisScope=Add-DHCPServerv4Scope -ComputerName $DHCPServers[1] -Name $Name -StartRange ($ScopePrefix+".129") -EndRange ($ScopePrefix+".254") -SubnetMask '255.255.255.0' -LeaseDuration 0.08:00:00 -PassThru #-whatif
        $ThisScope|Set-DhcpServerv4OptionValue -ComputerName $DHCPServers[1] -OptionId 003 -Value $RouterAddress 
        $ThisScope|Set-DhcpServerv4OptionValue -ComputerName $DHCPServers[1] -OptionId 006 -Value $DNSServers
        $CreatedScopes+=$ThisScope
    } catch { $_|Write-Warning } 
    # Write the list of scopes we've created to the host console
    $CreatedScopes
}
# Write a message to the screen and prompt for confirmation
$StatusMessage=@"
Will create new class C scopes.
Scope Name: $ScopeName
On Servers: $DHCPServers
For Address patterns: $Scopes
With DNS Servers: $DNSServers
And router last octect : $RouterLastOctet
"@
Write-Host $StatusMessage
read-host -Prompt "Press [Enter] To proceed if everything looks ok, or Control+C to cancel"
# Process the list of scopes
foreach ($Item in $Scopes) {
    Add-ClassCIPV4SplitScope -Scope $Item -Name $ScopeName -RouterLastOctet '1' -DHCPServers $DHCPServers -DNSServers $DNSServers
}
