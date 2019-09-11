Function Get-IAMUsersInRoleAllOrgs {
    [alias("Get-AWSRoleUserList")]
#This function currently lists all IAM user accounts specified in an instance under the policy titled: AdministratorAccess
param(
    [Parameter(Mandatory=$true)]$Role, #where $role is the role you want to assume to authenticate to another organization.
    [string]$PolicyName = "AdministratorAccess" 
)
$orgs = Get-ORGAccountList|select id, name, email
$adminlist = @()

foreach ($org in $orgs){
        $id =$org.Id
        $nm = $org.name
        #write-host "On account $id $nm"
        $obj = new-object psobject
        $obj |Add-member NoteProperty OrganizationID $id
        $obj |Add-member NoteProperty Arn $org.arn
        $obj | Add-Member NoteProperty OrganizationName $nm
        $account = $org.id
        #$RoleArn = "arn:aws:iam::${Account}:role/$role"
  
        #Request temporary credentials for each account and create a credential object
        try {
        #$Response = (Use-STSRole -Region $Region -RoleArn $RoleArn -RoleSessionName 'CMDB').Credentials
        $Credentials = Switch-AWSRoles -OrganizationID $id -Role $role
        #New-AWSCredentials -AccessKey $Response.AccessKeyId -SecretKey $Response.SecretAccessKey -SessionToken $Response.SessionToken
        
            #List all policies, get all entities on policy
                $admins = ""
                $admins = Get-IAMEntitiesForPolicy -PolicyArn "arn:aws:iam::aws:policy/$PolicyName" -Credential $Credentials
                $obj | add-member NoteProperty PolicyGroups $admins.policygroups
                    if ($admins.policygroups.count -gt 0){
                    $i = 0
                        foreach ($grp in $admins.policygroups){
                        $grpmembers = get-iamgroup -GroupName $admins.PolicyGroups[$i].groupname -Credential $Credentials
                        $obj |add-member NoteProperty PolGroupMembers $grpmembers.users
                        $i++
                        $grpmembers = $null
                        }
                    
                    }
                    else{
                    
                    }
                }
                catch {$admins = Get-IAMEntitiesForPolicy -PolicyArn "arn:aws:iam::aws:policy/$PolicyName" 
                $obj | add-member NoteProperty PolicyGroups $admins.policygroups
                    if ($admins.policygroups.count -gt 0){
                    $i = 0
                        foreach ($grp in $admins.policygroups){
                        $grpmembers = get-iamgroup -GroupName $admins.PolicyGroups[$i].groupname
                        $obj |add-member NoteProperty PolGroupMembers $grpmembers.users
                        $i++
                        }
                    
                    }
                    else{
                    
                    }
                    }
                
                
                $obj | add-member NoteProperty PolicyRoles $admins.PolicyRoles
                $obj | add-member NoteProperty PolicyUsers $admins.PolicyUsers
                $adminlist += $obj
                

}

$adminlist 
}
