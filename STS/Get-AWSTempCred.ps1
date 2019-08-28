#original source https://gist.github.com/jgard/17262e0fc073c82bc7930db2f5603446
#Thanks to the work of jgard.  Some stuff didnt work, but a bit of debugging got it going!

Function Get-Choice {
    [cmdletbinding()]
    param(
        [parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [string[]]$Options,
        [string]$Property,
        [string]$Message="Make a selection"
    )
    Begin {
        $i=0
        $array = @()
    }
    Process {
        $i++
        $array += $_
        write-host "  $i. " -NoNewline -ForegroundColor 'Green'
        if ($Property) {
            write-host $_.$Property
        } else {
            write-host $_
        }
    }
    End {
        Do {
            $answer=Read-Host -Prompt $message            
            try{
                $Chosen = $array[[int]$answer-1]                
            } catch {                
            }
            if (!$Chosen) { 
                Write-Host "Invalid choice '$answer'.  Please try again or press Ctrl+C to quit." -ForegroundColor Yellow
            } else {
                $Chosen
            }
        } While (!$Chosen)
    } 
}

Function Get-STSSAMLCred {
[CmdletBinding()]
[alias("Get-AWSTempCred")]
    param (
        [string]$ADFSHost='adfs.domain.com', ##Change for environment-appropriate default if desired
        [string]$RelyingParty = 'urn:amazon:webservices',
        [switch]$SetHost,
        [pscredential]$Credential
    )
     $WebRequestParams=@{ #Initialize parameters object
        Uri = "https://$ADFSHost/adfs/ls/IdpInitiatedSignon.aspx?LoginToRP=$RelyingParty"
        Method = 'POST'
        ContentType = 'application/x-www-form-urlencoded'
        SessionVariable = 'WebSession'
        UseBasicParsing = $true
    }
    if ($Credential) {
        $WebRequestParams.Add('Body',@{UserName=$Credential.UserName;Password=$Credential.GetNetworkCredential().Password})
    } else {
        $Credential = Get-Credential -Message "Enter the domain credentials for the SAML Provider"
        $WebRequestParams.Add('Body',@{UserName=$Credential.UserName;Password=$Credential.GetNetworkCredential().Password})
    }

    #Initial post to ADFS
    $InitialResponse=Invoke-WebRequest @WebRequestParams
    $SAMLResponseEncoded=$InitialResponse.InputFields.FindByName('SAMLResponse').value
    if (!$SAMLResponseEncoded) { #Initial result from ADFS didn't have assertion
        if ($InitialResponse.InputFields.FindByName('AuthMethod').value -eq 'SecurIDv2Authentication') { #Handle RSA SecurID
            $SAMLResponseEncoded = Read-SecurIDv2Authentication -WebRequestParams $WebRequestParams -InitialResponse $InitialResponse
        }
    }
    if (!$SAMLResponseEncoded) {
        Throw "No valid ADFS assertion received.  Suggestion: Supply alternate credentials, use different ADFSHost, or a new MFA method is not yet supported by this module."
    }
    
    #Evaluate SAML Response
    $SAMLResponseDecoded=[xml]([System.Text.Encoding]::utf8.GetString([System.Convert]::FromBase64String($SAMLResponseEncoded))) | select -ExpandProperty response
    $AvailableRoles = $SAMLResponseDecoded.Assertion.AttributeStatement.Attribute |?{$_.name -eq 'https://aws.amazon.com/SAML/Attributes/Role'}  | %{
        $_.AttributeValue |%{
            [PSCustomObject]@{"Role" = ($_ -split ",")[0];"SAMLProvider" = ($_ -split ",")[1]}
        }
    }
    $AvailableRoles = @($AvailableRoles) #Force to be an array to simplfy role count assessment
    if ($AvailableRoles.count -eq 0) {
        Throw "No available AWS roles found in ADFS response."
    }
    If ($AvailableRoles.count -gt 1) { #Choose role logic
        $ChosenRole= $AvailableRoles | Get-Choice -Message "Choose which role to assume" -Property 'Role'
    } else {
        $ChosenRole=$AvailableRoles[0]
    }
    
    #Send token to AWS STS
    try {
        Write-Host "Using role $($ChosenRole.Role)"
       $AssumedRole=Use-STSRoleWithSAML -SAMLAssertion $SAMLResponseEncoded -PrincipalArn $ChosenRole.SAMLProvider -RoleArn $ChosenRole.Role -ErrorAction Stop
        
        
    } catch{
        Write-Warning "STS error: $($_.Exception.Message)"
        Throw "Failure calling AWS STS service.  Likely issues: a) Outgoing internet connectivity or proxy issue, or b) Problem with ADFS trust, claims, or role."
    }
    write-host ""
    #Write-Host "New access key: $($AssumedRole.Credentials.AccessKeyId), expires $($AssumedRole.Credentials.Expiration)"
    #Write-Host "Setting as default AWSCredential for future AWSPowershell usage, by exporting to `$Global:StoredAWSCredentials"
    #write-host ""
   

    if ($SetHost){
    Write-Host "Setting as default AWSCredential for future AWSPowershell usage, by exporting to `$Global:StoredAWSCredentials"
    Set-AWSCredential -AccessKey $AssumedRole.Credentials.AccessKeyId -SecretKey $AssumedRole.Credentials.SecretAccessKey -SessionToken $AssumedRole.Credentials.SessionToken
    $Global:StoredAWSCredentials = $StoredAWSCredentials
    }
    else{
     #Commented out printing of sensitive information:
    #Sensitive information - i want this because I'm using this for aws-vault and cloudmapper
    Write-host "AccessKey=$($AssumedRole.Credentials.AccessKeyId)"
    write-host ""
    Write-host "SecretKey=$($AssumedRole.Credentials.SecretAccessKey)"
    write-host ""
    Write-host "SessionToken=$($AssumedRole.Credentials.SessionToken)"
    }
    #Set-AWSCredential -AccessKey $AssumedRole.Credentials.AccessKeyId -SecretKey $AssumedRole.Credentials.SecretAccessKey -SessionToken $AssumedRole.Credentials.SessionToken
    #$Global:StoredAWSCredentials = $StoredAWSCredentials
}

function Read-SecurIDv2Authentication {
    [CmdletBinding()]
    param (
        [hashtable]$WebRequestParams,
        $InitialResponse
    )

    $WebRequestParams.Remove('SessionVariable')
    $WebRequestParams.Add('WebSession',$WebSession)
    $WebRequestParams['Body'] = @{AuthMethod=$InitialResponse.InputFields.FindByName('AuthMethod').value;Context=$InitialResponse.InputFields.FindByName('Context').value;InitStatus='true'}
    if ($InitialResponse.BaseResponse.ResponseUri.AbsoluteUri) {
        $WebRequestParams['Uri'] = $InitialResponse.BaseResponse.ResponseUri.AbsoluteUri
    } else {
        $WebRequestParams['Uri'] = $InitialResponse.BaseResponse.RequestMessage.RequestUri.AbsoluteUri
    }
    $RSAInitResponse=Invoke-WebRequest @WebRequestParams

    if ($RSAInitResponse.InputFields.FindById('passcodeInput')) {
        $passcode = Read-Host 'Enter RSA SecurID passcode' -AsSecureString
        $WebRequestParams['Body'] =  @{AuthMethod=$RSAInitResponse.InputFields.FindByName('AuthMethod').value;Context=$RSAInitResponse.InputFields.FindByName('Context').value;Passcode=(New-Object PSCredential "user",$passcode).GetNetworkCredential().Password}
        if ($RSAInitResponse.BaseResponse.ResponseUri.AbsoluteUri) {
            $WebRequestParams['Uri'] = $RSAInitResponse.BaseResponse.ResponseUri.AbsoluteUri
        } else {
            $WebRequestParams['Uri'] = $RSAInitResponse.BaseResponse.RequestMessage.RequestUri.AbsoluteUri
        }
        $RSAResponse = Invoke-WebRequest @WebRequestParams
        $RSAResponse.InputFields.FindByName('SAMLResponse').value
    }
}

