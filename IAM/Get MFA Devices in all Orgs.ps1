Function Get-MFADevicesAllOrgs {
param (

[Parameter(Mandatory=$true)][string]$Role

)
    $mfadevices = @()
    $orgs = Get-ORGAccountList|select id, name, email
    foreach ($org in $orgs){
        $orgid = $null
        $credentials = $null
        $rolearn = $null

     $Orgid= $org.id
     $RoleArn = "arn:aws:iam::${Orgid}:role/$role"
        if ((Get-STSCallerIdentity).account -ne $Orgid){
        write-verbose "On $orgID"
        try{$credentials = Switch-AWSRoles -OrganizationID $Orgid -Role $Role   
        #Get-IAMVirtualMFADevice -Credential $Credentials 
        $mfadevices += Get-IAMVirtualMFADevice -Credential $Credentials
        }
        Catch{write-verbose $error[0]}
        }

        else{
        $mfadevices += Get-IAMVirtualMFADevice
        }

    }
    $MFAreadable = @()

    foreach ($device in $mfadevices){
        $obj = new-object psobject
        $obj |Add-member NoteProperty SerialNumber $device.serialnumber
        $obj |Add-member NoteProperty DevOrganizationID $(($device.serialnumber -split ":")[4])
        $obj | Add-member NoteProperty UserARN $device.user.Arn
        $obj | Add-member NoteProperty UserName $device.user.UserName
        $obj |Add-member NoteProperty UserOrganizationID $(($device.user.Arn -split ":")[4])
        $MFAreadable += $obj
    }
    $mfareadable
}