#get only machines with ownerid count is 1-5
#

Function Get-EC2Images_GroupByOwnerCount{

param (
    [Parameter(Mandatory=$true)][int]$MaxImages, 

)

$filter = @{
    Name   = 'Owner-id' 
    Values = '137112412989'
}
$CommonOwners = @('099720109477','137112412989')
get-date
$amilist = @()
    Get-AWSRegion|%{
    $amilist += Get-EC2Image -Region $_.Region| where {$_.ownerid -notmatch $CommonOwners}
    }
    get-date
       <#PS $amilist.count
            105431
            $amilist2 = get-ec2image -Region eu-west-1
            $amilist2.count
            85700
            #>


    $COmmonOwners|%{
    $amilist = $amilist|Where-Object -Property ownerid -NE $_
    }
     
 
    group-object



}