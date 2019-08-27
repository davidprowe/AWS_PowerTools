Function New-IAMAuditor {
[cmdletbinding()]
param(
    [string]$PolicyName = 'Rapid7-Security-Audit', 
    [parameter(Mandatory=$true)][string]$PolicyDocument,
    [string]$RoleName = $PolicyName, 
    [parameter(Mandatory=$true)][string]$RoleDocument,
    [object]$Credentials


)
#$PolicyName

try{$NewiamPol = New-IAMPolicy -PolicyName $PolicyName -PolicyDocument $PolicyDocument -Credential $Credentials}
catch{
    if ($error[0].Exception -like "*Duplicate*"){ 
            $OrganizationID = (Get-STSCallerIdentity -Credential $creds).account  
            $policyarn = "arn:aws:iam::${OrganizationID}:policy/$PolicyName"
            $newiampol = Get-IAMPolicy -PolicyArn $policyarn -Credential $Credentials
    
        }

}
$NewIAMRole = New-IAMRole -RoleName $RoleName -AssumeRolePolicyDocument $RoleDocument -Credential $Credentials

Register-IAMRolePolicy -PolicyArn $NewiamPol.Arn -RoleName $RoleName -Credential $Credentials

Register-IAMRolePolicy -PolicyArn 'arn:aws:iam::aws:policy/SecurityAudit' -RoleName $RoleName -Credential $Credentials

$NewIAMRole.Arn
}