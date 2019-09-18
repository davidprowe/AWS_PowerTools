Function Get-IAMOrgOUList{

<#
    .SYNOPSIS
        Displays a formatted table of AWS Organization OUs on the console
    
    .DESCRIPTION
        Starting at the root OU, this function displays a formatted list of OUs in an AWS Organization. The user MUST be a user with admin access to the Organization's root account and this function MUST be run in that root account
    
    .PARAMETER AWSStoredProfile
        A stored profile containing the AWS credentials providing admin access to the AWS Organization's master account
    
    .PARAMETER CSV
        This parameter allows you to send the output of the function in CSV format to a file in your home directory. Specify $true; defaults to $false
    
    .EXAMPLE
        PS C:\> ./AddNewOrgAccounToMFSMaster.ps1 -AWSStoredProfile <AWSStoredProfile> # Displays OUs as table on console
        PS C:\> ./AddNewOrgAccounToMFSMaster.ps1 -AWSStoredProfile <AWSStoredProfile> | Out-File <path> # Writes text to file
        PS C:\> ./AddNewOrgAccounToMFSMaster.ps1 -AWSStoredProfile <AWSStoredProfile> -CSV $true 
 
    
    .NOTES
        Updates 9/12/2019 - DRowe - Updated output to remove format-table.  Allows script to be exported into variable with ease
        
    
        Alex Neihaus 2019-07-15
        (c) 2019 Air11 Technology LLC -- licensed under the Apache OpenSource 2.0 license, https://opensource.org/licenses/Apache-2.0
        Licensed under the Apache License, Version 2.0 (the "License");
        you may not use this file except in compliance with the License.
        You may obtain a copy of the License at
        http://www.apache.org/licenses/LICENSE-2.0
        
        Unless required by applicable law or agreed to in writing, software
        distributed under the License is distributed on an "AS IS" BASIS,
        WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        See the License for the specific language governing permissions and
        limitations under the License.
        
        Author's blog: https://www.yobyot.com

    
#>
[CmdletBinding()]

param
(
    [Parameter(Mandatory = $false,
        Position = 1,
        HelpMessage = 'Supply a stored AWS credential profile authorized in the master account to create new accounts')]
    [Alias('creds')]
    [System.String]$AWSStoredProfile,
    [Parameter(Position = 2,
        HelpMessage = 'Enter TRUE to pipe output to a file in .csv format')]
    [ValidateSet($true, $false, IgnoreCase = $true)]
    [boolean]$CSV = $false,
    [Parameter(Mandatory = $false,
        Position = 2,
        HelpMessage = 'Use if you want to list accounts instead of OUs')]
    [switch]$ListAccounts
)
<# This function recursively lists all OUs starting from the root and places the ARN, ID and name 
    of the OU into an array to be presented to the user as a formatted table
#>
function Get-OrgChildOUs {
    param(
    [Parameter(Mandatory = $false,
        Position = 1)]
    [System.String]$ParentOUId,
    [Parameter(Mandatory = $false,
        Position = 2)]
    [System.String]$ParentName,
    [System.String]$ChildType = 'ORGANIZATIONAL_UNIT'
)


    $childouids = Get-ORGChild -ParentId $ParentOUId -ChildType $ChildType
    foreach ($childouid in $childouids.Id) {
        $obj = New-Object -TypeName PSObject -Property @{
            "Arn"    = "";
            "Id"     = "";
            "Name"   = "";
            "Parent" = "";
        }
        $t = Get-ORGOrganizationalUnit -OrganizationalUnitId $childouid
        # If we assign output of Get-ORGOrganizationUnit to a variable, it becomes type Amazon.Organizations.Model.OrganizationalUnit which we cannot modify
        # So, we manually copy the properties into our object, which is then added to the array of all OUs
        $obj.Arn = $t.Arn
        $obj.Id = $t.Id
        $obj.Name = $t.Name
        $obj.Parent = $ParentName
        $Script:AllOUs += $obj
        Start-Sleep -Seconds 2 # For some reason, AWS cmdlet Get-OrgOrganizationalUnit fails if lots of IDs are passed via pipeline, so this foreach loop slows it down
        # Using the current OU id, see if there are any child OUs and recursively call this function.
        do {
                if(!$PSBoundParameters.ContainsKey('ListAccounts')){Get-OrgChildOUs -ParentOUId $obj.Id -ParentName $obj.Name}
                else{Get-OrgChildOUs -ParentOUId $obj.Id -ParentName $obj.Name -ChildType ACCOUNT}
            
        }
        until ($null -eq $($AWSHistory.LastServiceResponse.Children)) # $AWSHistory contains $null when there are no more child OUs
        
    }
}               
function Get-AllOrgOus {
    Begin {
        switch ($PSVersionTable.PSEdition) {
            # Find out which version of pwsh is running and load the proper AWS cmdlet module
            "Core" {
                Import-Module AWSPowerShell.NetCore
            }
            "Desktop" {
                Import-Module AWSPowerShell
            }
            default {
                "There's a big problem; this version of PowerShell is unknown"
                "Returned edition of PowerShell is: $PSVersionTable.PSEdition"
                exit
            }
        }
        $error.clear() # Reset the error variable
        # On macOS using the VSCode debugger as of 2019-07-19, a simple Set-AWSCredential causes an error
        # If so, Initialize-AWSDefaultConfiguration works. See https://github.com/PowerShell/vscode-powershell/issues/2050
        switch (Test-Path Variable:PSDebugContext -IsValid) {
            $true {
                if ($PSBoundParameters.ContainsKey('AWSStoredProfile')){Initialize-AWSDefaultConfiguration -ProfileName $AWSStoredProfile}
                else{}
            }
            $false {
                if ($PSBoundParameters.ContainsKey('AWSStoredProfile')){
                    Set-AWSCredential -ProfileName $AWSStoredProfile -ErrorAction SilentlyContinue # Set the profile to be used
                if ($null -ne $error[0]) {
                    # Profile was NOT set correctly; Set-AWSCredentals does NOT store errors in $AWSHistory variable, so check $error array varaiable
                    "Your AWS stored profile was incorrect in some way"
                    "Set-AWSCredential returned: $error[0].Exception"
                    exit
                }
                }
                
            }
        }
    }
    Process {
        # Start by getting the OUs off the root.
        $Script:AllOUs = @()
        $RootOUId = (Get-ORGRoot).Id # Get the four-character root OU ID
        Get-OrgChildOUs -ParentOUId $RootOUId -ParentName "Root" # Get the OU IDs at level one below the root
    }
    End {
        $objarray = @()
        foreach ($id in $Script:AllOUs.id) {
            $obj = new-object psobject
            
                $obj |Add-member NoteProperty Parent $($Script:AllOUs.Parent[($Script:AllOUs.id).IndexOf($id)])
                $obj |Add-member NoteProperty OUName $($Script:AllOUs.Name[($Script:AllOUs.id).IndexOf($id)])
                $obj |Add-member NoteProperty OUId $($Script:AllOUs.Id[($Script:AllOUs.id).IndexOf($id)]) 
                $obj |Add-member NoteProperty Arn $($Script:AllOUs.Arn[($Script:AllOUs.id).IndexOf($id)])
                <#"OUName" = "$($Script:AllOUs.Name[($Script:AllOUs.id).IndexOf($id)])";
                "OUId"   = "$($Script:AllOUs.Id[($Script:AllOUs.id).IndexOf($id)])";
                "Parent" = "$($Script:AllOUs.Parent[($Script:AllOUs.id).IndexOf($id)])";
                "Arn"    = "$($Script:AllOUs.Arn[($Script:AllOUs.id).IndexOf($id)])";#>
            
            $objarray += $obj
        }
        switch ($CSV) {
            $false {
                Write-Host -ForegroundColor Yellow "Displaying all OUs in this AWS Organization"
                $objarray | Sort-Object -Property "OUName" #| Format-Table Parent, OUName, OUId, Arn -AutoSize
            }
            $true {
                $csvfile = "$HOME/AWSOUs-$(Get-Date -Format "yyyy-mm-dd-THH-MM-ss").csv"
                Write-Host -ForegroundColor Yellow "Writing a CSV file to $csvfile with all OUs in this AWS Organization"
                $objarray | Sort-Object -Property "OUName" | Export-Csv -Path $csvfile
            }
        }
        
    }
}
Get-AllOrgOus
}