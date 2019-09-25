Function Set-S3ACLEasy{
    [CmdletBinding()]
    param (
    [Parameter(Mandatory=$true)][string]$BucketName,
    [Parameter(Mandatory=$true)][string]$Region,
    [Parameter(Mandatory=$true)][object]$Credential,
    [Parameter(Mandatory=$true)]
    [ValidateSet("READ","FULL_CONTROL","WRITE","READ_ACP","WRITE_ACP","RESTORE_OBJECT")]
    [string]$Permission,
    [Object]$CanonicalID
        )

<# <member name="F:Amazon.S3.S3Permission.READ">
            <summary>
            When applied to a bucket, grants permission to list the bucket.
            When applied to an object, this grants permission to read the
            object data and/or metadata.
            </summary>
        </member>
        <member name="F:Amazon.S3.S3Permission.WRITE">
            <summary>
            When applied to a bucket, grants permission to create, overwrite,
            and delete any object in the bucket. This permission is not
            supported for objects.
            </summary>
        </member>
        <member name="F:Amazon.S3.S3Permission.READ_ACP">
            <summary>
            Grants permission to read the ACL for the applicable bucket or object.
            The owner of a bucket or object always has this permission implicitly.
            </summary>
        </member>
        <member name="F:Amazon.S3.S3Permission.WRITE_ACP">
            <summary>
            Gives permission to overwrite the ACP for the applicable bucket or object.
            The owner of a bucket or object always has this permission implicitly.
            Granting this permission is equivalent to granting FULL_CONTROL because
            the grant recipient can make any changes to the ACP.
            </summary>
        </member>
        <member name="F:Amazon.S3.S3Permission.FULL_CONTROL">
            <summary>
            Provides READ, WRITE, READ_ACP, and WRITE_ACP permissions.
            It does not convey additional rights and is provided only for convenience.
            </summary>
        </member>
        <member name="F:Amazon.S3.S3Permission.RESTORE_OBJECT">
            <summary>
            Gives permission to restore an object that is currently stored in Amazon Glacier
            for archival storage.
            </summary>
        </member>
        #>
    #$grants = Get-S3acl -BucketName $bucketname -Region $Region -Credential $Credential
    $ACL = Get-S3ACL -BucketName $BucketName -Region $Region -Credential $Credential
    $grants = @()
    $acl.grants |%{
        $grants += $_
    }
$CanonicalID|%{
    $grantee = New-Object -TypeName Amazon.S3.Model.S3Grantee
    $grantee.DisplayName = get-iamaccountalias -Credential $Credential
    $grantee.CanonicalUser = $_.CanonicalID
    
    
    $grant = New-Object -TypeName Amazon.S3.Model.S3Grant
    $grant.Grantee = $grantee
    $grant.Permission = [Amazon.S3.S3Permission]::$Permission
    $grants += $grant
}
        Set-S3ACL -BucketName $BucketName -Region $region -Credential $Credential -Grant $grants -OwnerId $acl.owner.id

}