function Get-AWSCredentialReport {
    Request-IAMCredentialReport
    $report = Get-iamCredentialReport -AsTextArray
    $report
}