#source https://aws.amazon.com/blogs/developer/cross-account-iam-roles-in-windows-powershell/
$orgs = Get-ORGAccountList|select id, name, email
foreach ($org in $orgs){
        $id =$org.Id
        $nm = $org.name
        write-host "On account $id $nm"
        
        $account = $org.id
        $RoleArn = "arn:aws:iam::${Account}:role/$role"
  
        #Request temporary credentials for each account and create a credential object
        $Response = (Use-STSRole -Region $Region -RoleArn $RoleArn -RoleSessionName 'CMDB').Credentials
        $Credentials = New-AWSCredentials -AccessKey $Response.AccessKeyId -SecretKey $Response.SecretAccessKey -SessionToken $Response.SessionToken
  
        #Iterate over all regions and list instances
        Get-AWSRegion | % {
            ListInstances -Credential $Credentials -Account $Account -Region $_.Region
        }


}
