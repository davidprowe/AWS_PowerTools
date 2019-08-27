<powershell>

$installdir = "C:\Bootstrap"
$filename = "filename.zip"
mkdir $installdir
set-location $installdir

#download file to the folder on local machine
$WebClient = New-object System.net.webclient
$FileURL = "Http://s3bucketlocation/Filurl/" + $filename
$localfile = $installdir + "\" + $filename
$WebClient.DownloadFile("$fileurl","$localfile")


#unzip file onto local machine
$NewShell = new-object -com shell.application
$zipFilePath = $newshell.namespace($localfile);
$dest = $NewShell.namespace((get-location).path)
$destionation.copyhere($zipfilepath.items(),0x14)




</powershell>