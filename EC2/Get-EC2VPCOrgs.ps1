Function Get-EC2VpcOrgs {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Role, #role used for cross account access 
        [object]$OrganizationList,   #Supply region list you want to test against
        [switch]$SkipDefault #if specified, do not list any default VPCs in output
    )
    if (!$OrganizationList){$OrganizationList = Get-ORGAccountList }else{}
    $regions = Get-AWSRegion |Where-Object {
        $_.Region -ne 'me-south-1' -and 
        $_.region -ne 'ap-east-1'}
    $orgProgress = 1
    $ocount = $organizationlist.count
    $originID = (Get-STSCallerIdentity).account
    $vpcArray = @()
    $OrganizationList |%{
        
        $orgid = $_.ID
        $oname = $_.Name
        if ($orgid -ne $originID){$Credentials = Get-STSCreds  -OrganizationID $orgid -role $role}
        Write-Progress -Activity "Searching Through Orgs: $oname" -id 1 -Status "$orgProgress complete of $ocount" -PercentComplete ($orgProgress/$ocount*100)
            
           $regionProgress = 1
           $rcount = $regions.count
            $Regions |%{
            
            $region = $_
            $rname = $_.name
            Write-Progress -Activity "Searching Through REGION: $rname on ORG: $oname" -id 2 -Status "$regionProgress complete of $Rcount"  -PercentComplete ($regionProgress/$Rcount*100) -CurrentOperation "Looking for VPCs in all regions for All Orgs"
            if ($orgid -ne $originID){$VPCs = get-ec2vpc -Region $_.Region -Credential $Credentials}else{
                $VPCs = get-ec2vpc -Region $_.Region
            }
            
                    $VPCs |%{
                        if($SkipDefault -and $_.IsDefault -eq $true){}Else{
                        $obj = new-object psobject
                        $obj |Add-member NoteProperty OrganizationID $orgid
                        $obj |Add-member NoteProperty OrganizationName $oName
                        $obj |Add-member NoteProperty Region $rname
                        $obj |Add-member NoteProperty VPC $VPCs
                        $obj |Add-member NoteProperty CidrBlock $_.CidrBlock
                        $obj |Add-member NoteProperty IsDefault $_.IsDefault
                        if($_.tags.key -contains 'Name'){
                            $n = ($_.tags|where-object {$_.key -eq 'Name'}).value
                        }else{
                            $n = 'NoTagName'
                        }
                        $obj |Add-member NoteProperty Name $n
                        $obj |Add-member NoteProperty OwnerID $_.OwnerId
                        $obj |Add-member NoteProperty VPCID $_.VpcId
                        $obj |Add-member NoteProperty State $_.State
                    
                        $VPCArray += $obj
                    }
                    }
            



            $regionProgress++
        }

        $orgProgress++
    }
    $VPCArray 
}

#list all orgs, foreach org, get all regions, foreach region get ec2vpcs, 