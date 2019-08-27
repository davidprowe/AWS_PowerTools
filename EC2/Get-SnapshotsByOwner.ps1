Function Get-SnapshotsByOwner{

param (
    [Parameter(Mandatory=$true)][string]$OrganizationID, 
    [Parameter(Mandatory=$true)][string]$Profile

)
$snapshotlist = @()
Get-AWSRegion|%{
    $rn = $_.Region
    try{$snapshotlist += Get-EC2Snapshot -ProfileName $Profile -Region $_.region -OwnerId $OrganizationID}
    catch{write-host "Error on Region $rn"}

}
$snapshotlist
}