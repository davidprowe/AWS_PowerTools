#Show attached policies to user and other user info:
$profile = "level6"
$user = (Get-IAMAccountAuthorizationDetail -ProfileName $profile).UserDetailList|Where-Object -Property arn -eq ((Get-STSCallerIdentity -ProfileName $profile).Arn)

$user.attachedmanagedpolicies

Get-IAMPolicy -PolicyArn arn:aws:iam::975426262029:policy/list_apigateways

Get-IAMPolicyversion -PolicyArn arn:aws:iam::975426262029:policy/list_apigateways -VersionId v4

get-lmfunctionlist

$pol = Get-LMPolicy -FunctionName Level6  
$temp = (ConvertFrom-Json $pol.Policy).statement
$temp.condition 
<#
ArnLike                                                                            
-------                                                                            
@{AWS:SourceArn=arn:aws:execute-api:us-west-2:975426262029:s33ppypa75/*/GET/level6}
#>
get-agstagelist -RestApiId s33ppypa75

build url = 
htt[s://$lambdaname.$executeapi.$region.amazonaws.com/$stagelist.Stagename/