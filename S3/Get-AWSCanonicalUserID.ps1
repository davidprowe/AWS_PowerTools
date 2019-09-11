function Get-AWSCanonicalUserID {
    $buckets = get-s3bucket
$region = 'us-east-1'
$objects = $buckets| %{Get-S3Object -BucketName $_.bucketName -region $region}
($objects |select-object -property owner -unique).owner.id
}