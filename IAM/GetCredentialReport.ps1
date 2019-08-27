function Get-AWSCredentialReport {
$string = aws iam get-credential-report --output text --query Content
$sDecodedString=[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($string))
$sDecodedString
}