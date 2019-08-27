Function Get-AccessKeysInS3 {
param(

#[parameter(Mandatory=$true)][string]$BucketName,
[parameter(Mandatory=$true)][string]$GitFolder

)



if (-not (test-path -literalpath $GitFolder) ){
    
    write-warning -Message "$GitFolder Does not exist. Exiting Script"
    break
    }

Import-Module posh-git
    cd $GitFolder
    #get to git master branch to list all commits
    if ((git branch) -ne '* master') {

        git checkout master
        }

    $gitHist = (git log --format="%ai`t%H`t%an`t%ae`t%s" -n 100) | ConvertFrom-Csv -Delimiter "`t" -Header ("Date","CommitId","Author","Email","Subject")
    $showall = @()
    
    $gitHist|% {
        $showall += git show $_.commitid
        }
        
        $AccessKeyRegEx =  "(^|[^A-Z0-9])[A-Z0-9]{20}(?![A-Z0-9])"
        $SecretKeyRegEx = "(^|[^A-Za-z0-9/+=])[A-Za-z0-9/+=]{40}(?![A-Za-z0-9/+=])"
       
        $accesskeys = $showall|Select-String -Pattern $AccessKeyRegEx
        $secretkeys = $showall|Select-String -Pattern $SecretKeyRegEx|where-object {($_ -notlike "commit*")}|where-object {($_ -notlike "+git checkout*")}
        
        
        $secretslist = @()
        $i=0
        $accesskeys |% {
            $Key = $_ # -split ""|Select-String -Pattern $AccessKeyRegEx
            
            $obj = new-object psobject
            $obj |Add-member NoteProperty AccessKeyMatch $_
            $obj |Add-member NoteProperty SecretKeyMatch ""
            $githist | %{ if(git show $_.commitid|Select-String -simplematch -Pattern $key){
                            $obj |Add-member Noteproperty CommitID $_.commitid}
                          else{} 
                          }
                            
                          $secretslist += $obj
                          $i++
        }
        
        $secretkeys |% {
            $key = $_
            $obj = new-object psobject
            $obj |Add-member NoteProperty AccessKeyMatch ""
            $obj |Add-member NoteProperty SecretKeyMatch $_
            $githist | %{ if(git show $_.commitid|Select-String -simplematch -Pattern $key){
                            $obj |Add-member Noteproperty CommitID $_.commitid}
                          else{} }
                            
                          $secretslist += $obj
        }
       #$secretslist

       $formattedSecrets = @()
       $accesskeys | %{
        $ak = [regex]::match($_,$AccessKeyRegEx).value
        $ak = $Ak -replace '[\W]',''
                    $secretkeys |%{
            $sk = [regex]::match($_,$SecretKeyRegEx).value
            $sk = $sk -replace ' ',''
            $sk = $sk -replace '`',''
            $obj = new-object psobject
            $obj |Add-Member NoteProperty AccessKey $ak
            $obj |Add-member NoteProperty Secret $sk
            $formattedSecrets += $obj
            }
       
       }
       remove-Module posh-git
       $secretsunique =  $formattedSecrets |sort-object accesskey,secret |Get-Unique -AsString
       $secretsunique | % {
       Switch-AccessWithAWSKey -AccessKey $_.accesskey -SecretKey $_.secret -Profile GITTest
                $temp = $_
       try {Get-STSCallerIdentity -ProfileName GITTest|Out-Null
       }
       catch {$secretsunique = $secretsunique -ne $temp
       }


       }

        

$secretsunique 
}