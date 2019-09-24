$buckets = get-s3bucket
$region = 'us-east-1'
$objects = $buckets| %{Get-S3Object -BucketName $_.bucketName -region $region|%{get-s3objectmetadata -bucketName $_.bucketName -key $_.key -Region $region }}