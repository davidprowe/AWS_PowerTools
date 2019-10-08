
Function Get-S3BucketRegion {
    [cmdletbinding()]
    param(
        [string]$BucketName,  
        [object]$Regions,     #Supply region list you want to test against
        [object]$Credential # use for organization testing for all buckets and regions
    )
    #standardize bucketname string to an object
    if (!$BucketName -and !$Credential){
        $S3 = get-s3bucket
    }
    if (!$BucketName -and $Credential){
        $s3 = get-s3bucket -credential $credential
    }
    if ($bucketname -and !$Credential){$S3 = Get-S3Bucket |where-object {$_.bucketname -eq  $bucketname}}
    if ($bucketname -and $Credential){$S3 = Get-S3Bucket -Credential $credential|where-object {$_.bucketname -eq  $bucketname}}
    if (!$S3){
        write-warning "No Bucket found with name $bucketname. Aborting script"
        break
    }
   

    if(!$Regions){$Regions = Get-AWSRegion|Sort-Object name -Descending}
$objarray = @()



            $S3|%{
                
                $bname = $_
                Clear-Variable -Name Region
                $Regions | %{
                    if (!$region) {
                        $r = $_
                        try {
                            
                            if (!$credential) {$region = Get-s3bucketversioning  -BucketName $bname.BucketName -Region $r.region}else{
                                $region = Get-s3bucketversioning  -BucketName $bname.BucketName -Region $r.region -Credential $credential
                                #if ($region.status -ne 'Enabled'){write-error -message 'wrong region'}
                            }
                            
                            try{
                                if ($credential){get-s3publicaccessblock -BucketName $_.bucketname -credential $creds -Region $_.Region}else{
                                    $publicaccess = get-s3publicaccessblock -BucketName $_.bucketname -Region $_.Region}catch{}
                                }
                                
                            $region = $r
                            $obj = new-object psobject
                        
                            $obj |Add-member NoteProperty BucketName $bname.BucketName
                            $obj |Add-member NoteProperty Region $r
                            if($publicaccess){
                                $obj |Add-member NoteProperty BlockPublicAcls $publicaccess.BlockPublicAcls
                                $obj |Add-member NoteProperty IgnorePublicAcls  $publicaccess.IgnorePublicAcls
                                $obj |Add-member NoteProperty BlockPublicPolicy $publicaccess.BlockPublicPolicy
                                $obj |Add-member NoteProperty RestrictPublicBuckets $publicaccess.RestrictPublicBuckets
                                }else{
                                    $obj |Add-member NoteProperty BlockPublicAcls "No Configuration Found"
                                    $obj |Add-member NoteProperty IgnorePublicAcls  "No Configuration Found"
                                    $obj |Add-member NoteProperty BlockPublicPolicy "No Configuration Found"
                                    $obj |Add-member NoteProperty RestrictPublicBuckets "No Configuration Found"
                                }
                            $objarray += $obj
                        }Catch{
                        
                    }
                    }

                }
            } #
            $objarray  
                    
        }
    

Function Get-S3BucketRegionOrgs {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true,
        Position = 1,
        HelpMessage = 'Role used to authenticate and read into sub accounts')]
    [string]$Role
    )
    try {$orgs = Get-ORGAccountList }catch {break}
    $s3array = @()
    $callerID = (Get-STSCallerIdentity).account
    $orgcount = $orgs.count
    $orgprogress = 1
    $orgs |%{
        $org = $_
        Write-Progress -Activity "Searching Through Accounts in Organization" -id 1 -Status "$orgProgress complete of $orgcount" -PercentComplete ($orgProgress/$orgcount*100)
        if ($_.id -ne $callerID){
            $creds = get-stscreds -organizationid $_.id -role $role
            $s3 = get-s3bucketregion -Credentials $creds}else{
                $s3 = get-s3bucketregion
            }
            $s3count = $s3.count
            $s3progress = 1
        $s3 |%{
            if($s3count -gt 0){Write-Progress -Activity "Searching Through S3 Buckets in Account" -id 2 -Status "$s3progress complete of $s3count" -PercentComplete ($s3progress/$s3count*100)}
            Clear-Variable -Name publicaccess
            if ($org.id -ne $callerid){
                
                try{$publicaccess = get-s3publicaccessblock -BucketName $_.bucketname -credential $creds -Region $_.Region}catch{}}Else{
                    try{$publicaccess = get-s3publicaccessblock -BucketName $_.bucketname -Region $_.Region}catch{}
                }
            
                            $obj = new-object psobject
                            $obj |Add-member NoteProperty AccountID $org.Id
                            $obj |Add-member Noteproperty AccountName $org.Name
                            $obj |Add-member NoteProperty BucketName $_.BucketName
                            $obj |Add-member NoteProperty Region $_.Region
                            if($publicaccess){
                                $obj |Add-member NoteProperty BlockPublicAcls $publicaccess.BlockPublicAcls
                                $obj |Add-member NoteProperty IgnorePublicAcls  $publicaccess.IgnorePublicAcls
                                $obj |Add-member NoteProperty BlockPublicPolicy $publicaccess.BlockPublicPolicy
                                $obj |Add-member NoteProperty RestrictPublicBuckets $publicaccess.RestrictPublicBuckets
                                }else{
                                    $obj |Add-member NoteProperty BlockPublicAcls "No Configuration Found"
                                    $obj |Add-member NoteProperty IgnorePublicAcls  "No Configuration Found"
                                    $obj |Add-member NoteProperty BlockPublicPolicy "No Configuration Found"
                                    $obj |Add-member NoteProperty RestrictPublicBuckets "No Configuration Found"
                                }

                            $s3array += $obj
            $s3progress++
        }
        $orgProgress++
    }
    $s3array
}