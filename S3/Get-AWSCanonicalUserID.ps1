function Get-AWSCanonicalUserID {
    [CmdletBinding()]

    $buckets = get-s3bucket
$region = 'us-east-1'
$objects = $buckets| %{Get-S3Object -BucketName $_.bucketName -region $region -MaxKey 10}
($objects |select-object -property owner -unique).owner.id
}

Function Get-AWSCanonicalUserIDOrgs {
    [CmdletBinding()]
    param (
    #[Parameter(Mandatory=$true)][object]$OrgList,
    [Parameter(Mandatory=$true)][string]$Role
    
    )
    $CanIDList = @()
    get-orgaccountlist -ProfileName default |%{
        Set-AWSCredential -ProfileName Default
        try {$creds = Get-STSCreds -OrganizationID $_.id -role $Role
        Set-AWSCredential -Credential $creds -storeas TempProfile
        set-awscredential -ProfileName tempprofile
        }
        catch{}
        $CanID = Get-AWSCanonicalUserID
        $obj = new-object psobject
        $obj |add-member NoteProperty OrgID $_.id
        $Obj | Add-member NoteProperty OrgName $_.name
        $Obj | Add-member NoteProperty CanonicalID $CanID
        $canidlist += $obj
    }
    $CanIDList
}

