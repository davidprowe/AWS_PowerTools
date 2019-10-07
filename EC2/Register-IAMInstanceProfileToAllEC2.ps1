#REFERENCE https://gist.github.com/lantrix/6d4935c934230df4a0d0348417128a48
Function Register-EC2IamInstanceProfileAll {
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory = $true,
            Position = 1,
            HelpMessage = 'List of EC2s to attach IAM Role onto')]
        [object]$EC2List,
        [Parameter(Mandatory = $true,
            Position = 2,
            HelpMessage = 'The EC2 IAM Role to be attached to EC2 in list')]
        [System.String]$InstanceProfileName,
        [Parameter(Mandatory = $false,
            Position = 3,
            HelpMessage = 'Cross account role with access to set ec2 instance profiles')]
        [System.String]$Role
        )
    $ec2array = @()
    if($Role){

    }else{
        $EC2Profile = Get-IAMInstanceProfile -InstanceProfileName $InstanceProfileName
        if (!$EC2Profile){Write-Warning "$InstanceProfileName Does not exist. Exiting Script"}
        $EC2List |%{
            clear-variable -name attached
            $ec2id = $_.instanceid
            $ec2region = $_.region
            $attached = Get-EC2IamInstanceProfileAssociation -Filter @{name='instance-id'; values=$ec2id} -Region $ec2region
            if ($attached.IamInstanceProfile.id -contains $EC2Profile.InstanceProfileId){
                #do nothing, already attached
                $profileinfo = Get-EC2IamInstanceProfileAssociation -Region $ec2region |where {($_.instanceid -eq $ec2id) -and ($_.iaminstanceprofile.id -eq $EC2Profile.instanceprofileid)}
                $obj = new-object psobject
        
                        $obj |Add-member NoteProperty InstanceID $ec2id
                        $obj |Add-member NoteProperty Region $ec2region
                        $obj |Add-member NoteProperty ProfileName $InstanceProfileName
                        $obj |Add-Member Noteproperty AttachedStatus $profileinfo
               $ec2array += $obj
            }else{
                $iamec2arn = $ec2profile.arn
                Register-EC2IamInstanceProfile -InstanceId $ec2id -region $ec2region -IamInstanceProfile_Arn $iamec2arn
                $profileinfo = Get-EC2IamInstanceProfileAssociation -Region $ec2region |where {($_.instanceid -eq $ec2id) -and ($_.iaminstanceprofile.id -eq $EC2Profile.instanceprofileid)}
                
                $obj = new-object psobject
        
                        $obj |Add-member NoteProperty InstanceID $ec2id
                        $obj |Add-member NoteProperty Region $ec2region
                        $obj |Add-member NoteProperty ProfileName $InstanceProfileName
                        $obj |Add-Member Noteproperty AttachedStatus $profileinfo
               $ec2array += $obj
            }
        }
    }
    $ec2array
}