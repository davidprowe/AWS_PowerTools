Function Get-IAMAccessKeysAllOrgs{ 

param(
    [Parameter(Mandatory=$true)]$Role
    
)

    $orgs = Get-ORGAccountList|select id, name, email
    $AKDetails = @()
    
    $accesskeys = @()

    foreach ($org in $orgs){
        $id =$org.Id
        $nm = $org.name
        $userlist = @()
        $accesskeys = @()
        if ((Get-STSCallerIdentity).account -ne $id){
    
            $id = $null
            $credentials = $null
            $rolearn = $null

                $id= $org.id
                $RoleArn = "arn:aws:iam::${Orgid}:role/$role"
                $Credentials = Switch-AWSRoles -OrganizationID $id -Role $role
                $userlist = get-iamuserlist -Credential $Credentials 
                $userlist |% { 
                    $uarn = $_.arn
                    $uorg = ($uarn -split ":")[4]
                    $accesskeys += Get-IAMAccessKey -UserName $_.UserName -Credential $credentials
                   }
                $accesskeys |% {
                        $lastused = Get-IAMAccessKeyLastUsed -AccessKeyId $_.AccessKeyId -Credential $credentials
                        
                        $obj = new-object psobject
                        $obj |Add-member NoteProperty OrganizationID $uorg
                        $obj |Add-member NoteProperty OrganizationName $nm
                        $obj |Add-member NoteProperty UserName $lastused.UserName 
                            $obj |Add-member Noteproperty AccessKeyID $_.AccessKeyId
                            $obj |Add-Member NoteProperty KeyCreateDate $_.CreateDate
                            $obj |Add-Member NoteProperty KeyStatus $_.Status
                                $obj |Add-member Noteproperty LastUsed $lastused.AccessKeyLastUsed.LastUsedDate
                                $obj |Add-member Noteproperty Region $lastused.AccessKeyLastUsed.Region
                                $obj |Add-member Noteproperty Service $lastused.AccessKeyLastUsed.ServiceName
                                $akdetails += $obj
                        }
        }

        else {


         $id = $null
            $credentials = $null
            $rolearn = $null

                $id= $org.id
                $userlist = get-iamuserlist 
                $userlist |% { 
                    $uarn = $_.arn
                    $uorg = ($uarn -split ":")[4]
                    $accesskeys += Get-IAMAccessKey -UserName $_.UserName
                   }
                $accesskeys |% {
                        $lastused = Get-IAMAccessKeyLastUsed -AccessKeyId $_.AccessKeyId
                        
                        $obj = new-object psobject
                        $obj |Add-member NoteProperty OrganizationID $uorg
                        $obj |Add-member NoteProperty OrganizationName $nm
                        $obj |Add-member NoteProperty UserName $lastused.UserName 
                            $obj |Add-member Noteproperty AccessKeyID $_.AccessKeyId
                            $obj |Add-Member NoteProperty KeyCreateDate $_.CreateDate
                            $obj |Add-Member NoteProperty KeyStatus $_.Status
                                $obj |Add-member Noteproperty LastUsed $lastused.AccessKeyLastUsed.LastUsedDate
                                $obj |Add-member Noteproperty Region $lastused.AccessKeyLastUsed.Region
                                $obj |Add-member Noteproperty Service $lastused.AccessKeyLastUsed.ServiceName
                                $akdetails += $obj
                        }
        }
        
        }
        $akdetails |sort-object organizationid,LastUsed
            
            }

           

                      

                
               