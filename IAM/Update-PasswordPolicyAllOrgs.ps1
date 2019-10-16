Function Update-IAMAccountPasswordPolicyOrgs{
    [CmdletBinding()]

    param
    (
        [string]$Role,
        [object]$OrganizationList,
        [bool]$AllowUsersToChangePassword = $True,
        [bool]$ExpirePasswords = $True,
        [bool]$HardExpiry = $False,
        [int]$MaxPasswordAge = 90,
        [int]$MinimumPasswordLength = 15,
        [int]$PasswordReusePrevention  = 5,
        [bool]$RequireLowercaseCharacters = $True,
        [bool]$RequireNumbers =$True,
        [bool]$RequireSymbols =$True,
        [bool]$RequireUppercaseCharacters = $True
    )
    
    # set password policy from a list of orgs
    if (!$Role){if (!$OrganizationList){try{$organizationlist = Get-ORGAccountList}catch{}}
    if (!$OrganizationList){
        $a = (get-stscalleridentity).account
        Write-host "No org account members listed. setting PWD Policy only on account $a"
        Update-IAMAccountPasswordPolicy -AllowUsersToChangePassword $AllowUsersToChangePassword -MaxPasswordAge $MaxPasswordAge -MinimumPasswordLength $MinimumPasswordLength -PasswordReusePrevention $PasswordReusePrevention -RequireLowercaseCharacter $RequireLowercaseCharacters -RequireNumber $RequireNumbers -RequireSymbol $RequireSymbols -RequireUppercaseCharacters $RequireUppercaseCharacters -hardexpiry $false 
        Get-IAMAccountPasswordPolicy
        break
    }}
    
    foreach($org in $organizationlist){
        $credential = get-stscreds -OrganizationID $org.id -Role $Role
        $name = $org.name
        write-host "On $name"
        Update-IAMAccountPasswordPolicy -Credential $credential -AllowUsersToChangePassword $AllowUsersToChangePassword -MaxPasswordAge $MaxPasswordAge -MinimumPasswordLength $MinimumPasswordLength -PasswordReusePrevention $PasswordReusePrevention -RequireLowercaseCharacter $RequireLowercaseCharacters -RequireNumber $RequireNumbers -RequireSymbol $RequireSymbols -RequireUppercaseCharacters $RequireUppercaseCharacters -hardexpiry $false 
    
    }
}
