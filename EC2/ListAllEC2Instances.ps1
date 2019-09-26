Function Get-EC2InstanceList {
    [CmdletBinding()]

param
(
    [Parameter(Mandatory = $true,
        Position = 1,
        HelpMessage = 'Supply a stored AWS credential role authorized across accounts')]
    [Alias('creds')]
    [System.String]$Role
)
    
    $orgs = Get-ORGAccountList
    $regions = Get-AWSRegion
    $ec2Array = @()
    $orgProgress = 1
    $ocount = $orgs.count
    $rcount = $Regions.count
    $orgs|%{
        $org = $_
        $oname = $org.name
        Write-Progress -Activity "Searching Through Org: $oname" -id 1 -Status "$orgProgress complete of $ocount" -PercentComplete ($orgProgress/$ocount*100)
        
        $regionProgress = 1
            try{
                try{$Credentials = Get-STSCreds  -OrganizationID $_.Id -role $role
                    $regions | % {
                        $oname = $org.name
                        $region = $_
                        $rname = $_.name
                        Write-Progress -Activity "Searching Through REGION: $rname on ORG: $oname" -id 2 -Status "$regionProgress complete of $Rcount"  -PercentComplete ($regionProgress/$Rcount*100) -CurrentOperation "Looking for EC2s in all regions for All Orgs"
                        
                        try{$ec2 = Get-EC2Instance -Credential $Credentials -Region $_.Region
                            $EC2|%{
                                Clear-Variable -Name status
                                $status = Get-ec2instancestatus -InstanceId $_.instances.instanceid -Region $region.Region -Credential $Credentials
                                $Pemkey = $ec2 |select instances
                                $obj = new-object psobject
                
                                $obj |Add-member NoteProperty OrganizationID $org.id
                                $obj |Add-member NoteProperty OrganizationName $org.Name
                                $obj |Add-member NoteProperty EC2InstanceID $_.instances.instanceid
                                $obj |Add-member NoteProperty InstanceType $_.instances.InstanceType
                                $obj |Add-member NoteProperty Region $region.Region
                                if($status){
                                    $obj |Add-member NoteProperty InstanceState $status.instancestate.name
                                    $obj |Add-member NoteProperty Reachability $status.status.status
                                    $obj |Add-member NoteProperty InstanceStatus $status

                                }
                                else{
                                    $obj |Add-member NoteProperty InstanceState "NoStateFound"
                                    $obj |Add-member NoteProperty Reachability "NoStateFound"
                                    $obj |Add-member NoteProperty InstanceStatus "NoStateFound"
                                }
                                $obj |Add-member NoteProperty KeyPem $_.instances
                                $ec2Array += $obj

                            }
                            
                        }
                        catch{}
                        $regionProgress++
                    }
                    }
                catch{}
            #Iterate over all regions and list instances
            
                 }
                 catch{$regions | % {
                     $region = $_
                     Write-Progress -Activity "Searching Through Orgs" -Status "$regionProgress complete of $Regions.count"  -PercentComplete ($regionProgress/$Regions.count*100) -CurrentOperation InnerLoop
                    try{$ec2 = Get-EC2Instance -Region $_.Region
                        $EC2|%{
                            Clear-Variable -Name status
                            $status = Get-ec2instancestatus -InstanceId $_.instances.instanceid -Region $region.Region
                            $Pemkey = $_ |select instances
                            $obj = new-object psobject
            
                            $obj |Add-member NoteProperty OrganizationID $org.id
                            $obj |Add-member NoteProperty OrganizationName $org.Name
                            $obj |Add-member NoteProperty EC2InstanceID $_.instances.instanceid
                            $obj |Add-member NoteProperty InstanceType $_.instances.InstanceType
                            $obj |Add-member NoteProperty Region $region.Region
                            if($status){
                                $obj |Add-member NoteProperty InstanceState $status.instancestate.name
                                $obj |Add-member NoteProperty Reachability $status.status.status
                                $obj |Add-member NoteProperty InstanceStatus $status

                            }
                            else{
                                $obj |Add-member NoteProperty InstanceState "NoStateFound"
                                $obj |Add-member NoteProperty Reachability "NoStateFound"
                                $obj |Add-member NoteProperty InstanceStatus "NoStateFound"
                            }
                            $obj |Add-member NoteProperty Instances $ec2.instances
                            $ec2Array += $obj

                        }
                        
                    }
                    catch{}
                    $regionProgress++
                }
            }
            $orgProgress++
        }
        
    $ec2Array
    
    }
    


