$daysold = 45
$lastusedDays = 90
$role = 'cross-account-access-role'
$iamkeys = Get-IAMAccessKeysAllOrgs -Role $role

$oldiamkeys = $iamkeys|Where-Object -Property keycreatedate -lt ((get-date).AddDays(-$daysold))|Where-Object -Property lastused -lt ((get-date).AddDays(-$lastusedDays))
$oldiamkeys |%{

    $creds = Get-STSCreds -OrganizationID $_.OrganizationID -Role $role
    $keyid = $_.accesskeyid
    Get-IAMUserList -Credential $creds|%{get-iamaccesskey -UserName $_.username -Credential $creds|where-object -Property accesskeyid -eq $keyid|Remove-IAMAccessKey -AccessKeyId $keyid -Credential $creds}

}