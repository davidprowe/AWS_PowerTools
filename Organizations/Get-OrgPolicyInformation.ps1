Function Get-OrgPolicyInformation{
    
    <#
        .SYNOPSIS
            Displays a formatted table of AWS Organization SCPs applied to OUs
        
        .DESCRIPTION
            Pulls SCP information from the Ous provided and generates output of all attached scps to OUs. The user MUST be a user with admin access to the Organization's root account and this function MUST be run in that root account
        
        .PARAMETER OrgList
            A parameter containing the AWS OUs. Currently only set to work from the output of get-allorgous.ps1
        
        .EXAMPLE
            Get-OrgPolicyInformation -OrgList $OUs #WHere OUs is $ous = Get-OrgOUList
            Get-OrgPolicyInformation -OrgList (Get-OrgOUList)
        
        .NOTES
            v1 - Created script and output data - Generates SCP attached to OUs.  Made to work with the input from Get-AllOrgOus.ps1
            
        
            David Rowe 2019-09-19
            (c) 2019 SecFrame - licensed under the Apache OpenSource 2.0 license, https://opensource.org/licenses/Apache-2.0
            Licensed under the Apache License, Version 2.0 (the "License");
            you may not use this file except in compliance with the License.
            You may obtain a copy of the License at
            http://www.apache.org/licenses/LICENSE-2.0
            
            Unless required by applicable law or agreed to in writing, software
            distributed under the License is distributed on an "AS IS" BASIS,
            WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            See the License for the specific language governing permissions and
            limitations under the License.
            
            Author's blog: https://www.secframe.com
    
        
    #>
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory = $false,
            Position = 1,
            HelpMessage = 'A parameter containing the AWS OUs. Currently only set to work from the output of get-allorgous.ps1')]
        [object]$OrgList,
        [validateset('OUId','AccountID')][string]$TargetID
    )
$objarray = @()
$OrgList | %{
            $ou = $_
            if (!$targetid){$targetid = 'OUId'}
            $targetid
                $policyfortarget = Get-ORGPolicyForTarget -TargetId $ou.$TargetID -Filter SERVICE_CONTROL_POLICY 
                $policyfortarget |%{
                        $pol = Get-ORGPolicy -PolicyId $_.Id
                        $obj = new-object psobject
                        $json = ($pol.content |ConvertFrom-Json).statement
                        
                        $obj |Add-member NoteProperty PolicyName $pol.PolicySummary.name
                        $obj |Add-member NoteProperty PolicyID $pol.PolicySummary.id
                        $obj |Add-member NoteProperty PolicyDesc $pol.PolicySummary.Description
                        $obj |Add-member NoteProperty Parent $ou.Parent
                        if ($targetid -eq 'OUID'){
                            $obj |Add-member NoteProperty AttachedToName $ou.OUName
                            $obj |Add-member NoteProperty AttachedToId $ou.ouId
                            $obj |Add-member NoteProperty AttachedToArn $ou.Arn
                            $obj |Add-member Noteproperty AttachedToType 'OU'
                        
                        }
                        if ($targetid -eq 'AccountID'){
                            $obj |Add-member NoteProperty AttachedToName $ou.AccountName
                            $obj |Add-member NoteProperty AttachedToId $ou.AccountID
                            $obj |Add-member NoteProperty AttachedToArn $ou.AccountArn
                            $obj |Add-member Noteproperty AttachedToType 'Account'
                        
                        }
                        $obj |Add-member NoteProperty Content $json
                        $obj |Add-member NoteProperty PolicySummary $pol.PolicySummary
                        
                        $objarray += $obj
                        Start-Sleep .6
                    }
                    
                    
                    }
                    
                    $objarray 
}                
                
Function Convert-RoleToJson {
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory = $false,
            Position = 1,
            HelpMessage = 'A parameter containing the PolList. Currently only set to work from the output of Get-OrgPolicyInformation')]
        [object]$PolList,
        [string]$DestFolder
    )
    $uniquePols = $PolList|select policyname, content -unique
$poljson = @()
$uniquePols |%{
    $obj = new-object psobject
    $obj |add-member NoteProperty Name $_.policyname
    $obj |Add-member NoteProperty Content ($_.content|convertto-json)
    $poljson += $obj
}
$poljson
if($DestFolder){
    $poljson |%{
        
        $n = $_.name
        $filename = ($DestFolder +'\' + $_.name + ".json")
        $_.content |Out-File $filename
        write-host "File saved for $n at $filename"
    }

}
}
                

