get orgs
sift through, foreach do assume role, and then new iamauditor

$STSRole = 'Credential-role'
#=====================================
$policyjson = '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "acm:ListTagsForCertificate",
                "cloudtrail:ListPublicKeys",
                "cloudtrail:ListTags",
                "cloudtrail:GetTrailStatus",
                "cloudtrail:GetEventSelectors",
                "ecr:DescribeRepositories",
                "ecr:GetLifecyclePolicy",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "iam:GenerateServiceLastAccessedDetails",
                "lambda:GetFunction",
                "lambda:GetLayerVersion",
                "lambda:GetLayerVersionPolicy",
                "lambda:GetPolicy",
                "lambda:ListFunctions",
                "lambda:ListLayerVersions",
                "sqs:ListQueues",
                "sqs:ListDeadLetterSourceQueues",
                "sqs:ListQueueTags",
                "sqs:GetQueueUrl",
                "sqs:GetQueueAttributes",
                "states:DescribeStateMachineForExecution",
                "states:DescribeActivity",
                "states:DescribeStateMachine",
                "states:DescribeExecution",
                "states:ListExecutions",
                "states:GetExecutionHistory"
            ],
            "Resource": "*"
        }
    ]
}'
#supplied by rapid7
#=====================================
$rolejson = '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::012345678910:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "51f6f3c1-bd77-aaaa-aaaa-88884f42cccc"
        }
      }
    }
  ]
}'
#======================================

$orgs = Get-ORGAccountList

$orgs |%{

$creds = Switch-AWSRoles -OrganizationID $_.id -Role $STSRole
    New-IAMAuditor -PolicyDocument $policyjson -RoleDocument $rolejson -Credentials $creds

}


