function Get-AWSCredentialReport {

    param(
    [string]$Role
    )
    $originID = (Get-STSCallerIdentity).account
    $objects = @()
    if(!$Role){
        Request-IAMCredentialReport |Out-Null
    $report = Get-iamCredentialReport -AsTextArray
    
    $columnnames = $report[0] -split ','
    $i = 1 #start above first line
    
    do {
        $values = $report[$i] -split ','

        $columnnum = 0
            $obj = new-object psobject
            foreach ($column in $columnnames){
                $obj |Add-member NoteProperty $column $values[$columnnum]
                $columnnum++
                }
                $objects += $obj
        
        $i++
    }
    while ($i -lt $report.count)
    }else{
        $OrgAccountList = Get-ORGAccountList
        $ocount = $OrgAccountList.count
        $orgProgress = 1
        
        foreach ($acct in $orgaccountlist){
            $orgid = $acct.ID
            $oname = $acct.Name
            if ($orgid -ne $originID){$Credentials = Get-STSCreds  -OrganizationID $orgid -role $role}
        Write-Progress -Activity "Searching Through Orgs: $oname" -id 1 -Status "$orgProgress complete of $ocount" -PercentComplete ($orgProgress/$ocount*100)
            ###Adding code here
            if ($orgid -ne $originID){Request-IAMCredentialReport -Credential $credentials|Out-Null
                $report = Get-iamCredentialReport -Credential $Credentials -AsTextArray 
            }else{
                Request-IAMCredentialReport|Out-Null
                $report = Get-iamCredentialReport -AsTextArray
            }
                
               
                $columnnames = $report[0] -split ','
                $i = 1 #start above first line
    
                    do {
                    $values = $report[$i] -split ','

                    $columnnum = 0
                        $obj = new-object psobject
                        $obj |Add-member NoteProperty AccountID $acct.id
                        $obj |Add-member NoteProperty AccountName $acct.Name
                        foreach ($column in $columnnames){
                            $obj |Add-member NoteProperty $column $values[$columnnum]
                            $columnnum++
                            }
                            $objects += $obj
                    
                    $i++
                    }
                    while ($i -lt $report.count)
            ###

            $orgProgress++
        }
    }
    


    $objects
}