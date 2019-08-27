function New-MFADevice {
param(
    
    [parameter(Mandatory=$true)][string]$DeviceName,
    $OpenInChrome,
    [Switch]$Credential,
    [string]$CSVImport,
    [Switch]$FindKeys
    
)

$Device = New-IAMVirtualMFADevice -VirtualMFADeviceName $devicename -Credential $creds
$BR = New-Object System.IO.BinaryReader($Device.QRCodePNG)
$BR.ReadBytes($BR.BaseStream.Length) | Set-Content -Encoding Byte -Path "c:\reports\QRCode.png"


}