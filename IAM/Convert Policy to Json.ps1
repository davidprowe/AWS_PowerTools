Function Convert-PolicyToJson {

param (
    $Policy
)
    if (($Policy|gm).name -contains 'document'){
    [System.Reflection.Assembly]::LoadWithPartialName("System.Web.HttpUtility")
    $policy = [System.Web.HttpUtility]::UrlDecode($Policy.Document)
    $policy
    }

}