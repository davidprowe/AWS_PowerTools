Function Get-AllFilesInS3Bucket {
param(
    
    [parameter(Mandatory=$true)][string]$BucketName,
    [switch]$OpenInChrome,
    [Switch]$Sync,
    [Switch]$FindKeys
    
)

#Bucket
#$s3 = "level3-9afd3927f195e10225021a578e6f78df.flaws.cloud"
$s3 = $BucketName

#region
$region = (resolve-dnsname  ((resolve-dnsname $s3).ipaddress)).namehost
$regionsplit = ($region.Split("-.")[2]+"-"+$region.Split("-.")[3]+"-"+$region.Split("-.")[4])


#All Files
#$files = aws s3 ls s3://$s3 --no-sign-request --region ($region.Split("-.")[2]+"-"+$region.Split("-.")[3]+"-"+$region.Split("-.")[4])
$files = Get-S3Object -BucketName $s3 -Region $regionsplit

#HTTP URL For all files
    $output = @()
        $files|%{
        $output += "http://" + $s3 +"."+ $region +'/'+$_.key
    }
        $output
        
        if($PSBoundParameters.ContainsKey('OpenInChrome')){
            $output | % {
            & 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe' $_
            }

            }

        if($PSBoundParameters.ContainsKey('Sync')){
                #if (-not (test-path -literalpath (((Get-location).path) + "\ListAllFilesInBucket"))) {New-Item -Path $path -ItemType Directory -ErrorAction Stop | Out-Null }
            $syncvar = "aws s3 sync s3://$s3/ . --no-sign-request --region $regionsplit"
            aws s3 sync s3://$s3/ . --no-sign-request --region $regionsplit
            
        }
        $cd = (get-location)
        if ($PSBoundParameters.ContainsKey('FindKeys')){
                if ($output -like "*/.git/*"){
                Get-AccessKeysInS3 -GitFolder $cd}
                else{write-host "Couldnt find a /.git/ folder"}
            }


}