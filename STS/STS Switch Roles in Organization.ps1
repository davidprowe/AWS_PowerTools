Function Get-STSCreds {
    [alias("Switch-AWSRoles")]
param(
    [Parameter(Mandatory=$true)][string]$OrganizationID, 
    [Parameter(Mandatory=$true)][string]$Role
    
)
        
        $region = (Get-AWSRegion|where-object -Property isshelldefault -eq $true)
       
        $RoleArn = "arn:aws:iam::${OrganizationID}:role/$role"
  
        #Request temporary credentials for each account and create a credential object

        $Response = (Use-STSRole -Region $Region -RoleArn $RoleArn -RoleSessionName 'CMDB').Credentials
        $Credentials = New-AWSCredentials -AccessKey $Response.AccessKeyId -SecretKey $Response.SecretAccessKey -SessionToken $Response.SessionToken

        $Credentials

}

Function Get-STSRoleToken {

param(
    [Parameter(Mandatory=$true)][string]$OrganizationID, 
    [Parameter(Mandatory=$true)][string]$Role,
    [int]$DurationInSeconds = 3600
    
)
        
        $region = (Get-AWSRegion|where-object -Property isshelldefault -eq $true)
       
        $RoleArn = "arn:aws:iam::${OrganizationID}:role/$role"
  
        #Request temporary credentials for each account and create a credential object

        $Response = (Use-STSRole -Region $Region -RoleArn $RoleArn -RoleSessionName 'CMDB' -DurationInSeconds $DurationInSeconds).Credentials
        $Response

}

Function Switch-AccessWithAWSKey {
param (
    [Parameter(Mandatory=$true)][string]$AccessKey, 
    [Parameter(Mandatory=$true)][string]$SecretKey,
    [string]$Profile = 'tempprofile'
    )
     
    Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs $Profile
    Set-AWSCredential -ProfileName $Profile
}
        
