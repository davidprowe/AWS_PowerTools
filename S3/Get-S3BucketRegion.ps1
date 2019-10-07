
Function Get-S3BucketRegion {
    [cmdletbinding()]
    param(
        [string]$BucketName,  
        [object]$Regions,     #Supply region list you want to test against
        [object]$Credentials # use for organization testing for all buckets and regions
    )
    #standardize bucketname string to an object
    if (!$BucketName -and !$Credentials){
        $S3 = get-s3bucket
    }
    if (!$BucketName -and $Credentials){
        $s3 = get-s3bucket -credential $credentials
    }
    if ($bucketname -and !$Credentials){$S3 = Get-S3Bucket |where-object {$_.bucketname -eq  $bucketname}}
    if ($bucketname -and $Credentials){$S3 = Get-S3Bucket -Credential $credentials|where-object {$_.bucketname -eq  $bucketname}}
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
                            
                            if (!$credentials) {$region = Get-S3BucketInventoryConfiguration  -BucketName $bname.BucketName -Region $r.region}else{
                                $region = Get-S3BucketInventoryConfiguration  -BucketName $bname.BucketName -Region $r.region -Credential $credentials
                            }
                            

                            $region = $r
                            $obj = new-object psobject
                        
                            $obj |Add-member NoteProperty BucketName $bname.BucketName
                            $obj |Add-member NoteProperty Region $r
                            $objarray += $obj
                        }Catch{
                        
                    }
                    }

                }
            } #
            $objarray  
                    
        }
    

