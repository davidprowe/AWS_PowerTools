

function Get-AWSIAMUsersNoMFADevice {
#used in conjunction with list all admins output
param (
    [parameter(Mandatory=$true)][object]$UserList,
    [parameter(Mandatory=$true)][string]$Role
    
)

$mfadevices = @()
$MFAreadable = @()
$MFAListAll = @()
foreach ($org in $userlist){
    $orgid = $null
    $polgroupmembers = $null
    $policyusers = $null
    $orgid = $org.organizationid
    $polgroupmembers = $org.polgroupmembers
    $policyusers = $org.policyusers
    
                  
        $account = $orgid
        #$RoleArn = "arn:aws:iam::${Account}:role/$role"
        if ((Get-STSCallerIdentity).account -ne $orgid){
        #$Response = (Use-STSRole -Region $Region -RoleArn $RoleArn -RoleSessionName 'CMDB').Credentials
        $Credentials = Switch-AWSRoles -OrganizationID $orgid -Role $role
        #New-AWSCredentials -AccessKey $Response.AccessKeyId -SecretKey $Response.SecretAccessKey -SessionToken $Response.SessionToken
        $mfadevices += Get-IAMVirtualMFADevice -Credential $Credentials
        } else {
        $mfadevices += Get-IAMVirtualMFADevice
        }
            
        #
    foreach ($device in $mfadevices){
        $obj = new-object psobject
        $obj |Add-member NoteProperty SerialNumber $device.serialnumber
        $obj | Add-member NoteProperty UserARN $device.user.Arn
        $obj |Add-member NoteProperty OrganizationID $(($device.serialnumber -split ":")[4])
        $obj | Add-member NoteProperty UserName $device.user.UserName
        $MFAreadable += $obj
    }

    
    
    #check for root in mfareadable
        $obj = new-object psobject
        $obj |Add-member NoteProperty OrganizationID $org.OrganizationID
        $obj |Add-member NoteProperty OrganizationName $org.OrganizationName
        $obj |Add-member Noteproperty Username "Root"
        $orgID = $org.OrganizationID
        $rootarn = "arn:aws:iam::${orgid}:root"
        $rootmfaexists = $null
        $rootmfaexists = ($mfadevices.user.arn -contains $rootarn) 
            if ($rootmfaexists -eq $true){
            #this if shows that an mfa device is created for the root account
            $obj |Add-member NoteProperty MFAEnabled "YES"
                }
            else {
            #this else shows there is no MFA device created for the root accoutn
            $obj |Add-member NoteProperty MFAEnabled "NO"
                }
            $mfalistall += $obj
        if($org.polgroupmembers.count -gt 0){
            foreach ($u in $org.polgroupmembers){
            $obj = new-object psobject
            $orgID = $org.OrganizationID
            $uname = $u.username
            
                $obj |Add-member NoteProperty OrganizationID $orgID
                $obj |Add-member NoteProperty OrganizationName $org.OrganizationName
                $obj |Add-member Noteproperty Username $uname
            
                $arn = "arn:aws:iam::${orgid}:user/${Uname}"
                
                $rootmfaexists = $null
                $rootmfaexists = ($MFAreadable.userarn -eq $arn)
                    if ($rootmfaexists){
                    #this if shows that an mfa device is created for the root account
                    $obj |Add-member NoteProperty MFAEnabled "YES"
                        }
                    else {
                    #this else shows there is no MFA device created for the root accoutn
                    $obj |Add-member NoteProperty MFAEnabled "NO"
                        }
            $mfalistall += $obj    
            }
        
            }
        if($org.policyusers.count -gt 0){
            foreach ($u in $org.policyusers){
            $obj = new-object psobject
            $orgID = $org.OrganizationID
            $uname = $u.username
                $obj |Add-member NoteProperty OrganizationID $org.OrganizationID
                $obj |Add-member NoteProperty OrganizationName $org.OrganizationName
                $obj |Add-member Noteproperty Username $uname
        
                $arn = "arn:aws:iam::${orgid}:user/${Uname}"
                $rootmfaexists = $null
                $rootmfaexists = ($MFAreadable.userarn -eq $arn)
                    if ($rootmfaexists){
                    #this if shows that an mfa device is created for the root account
                    $obj |Add-member NoteProperty MFAEnabled "YES"
                        }
                    else {
                    #this else shows there is no MFA device created for the root accoutn
                    $obj |Add-member NoteProperty MFAEnabled "NO"
                        }
            $mfalistall += $obj    
            }
        
        }
            }

    
    #now i have all the mfa devices in an entire org, split the $mfadevices into an object that is org id/ user
    
    $MFALISTALL |Sort-Object -Property organizationid,username -Unique
    
}

