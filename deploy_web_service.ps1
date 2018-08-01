#Set-PSDebug -Trace 2
param(
	
  [string]$Archpath,
  [string]$Dpath,
  [string]$Dip,
  [string]$Username,
  [string]$Password,
  [string]$Sitename
)
######

$Darch = "C:\"+$SiteName+".zip"
$Dpathsite = $Dpath+"\"+$SiteName
Write-Host "------Archive "$Archpath 
Write-Host "------Dpath : "$Dpath 
Write-Host "------Dip : "$Dip 
Write-Host "------Username : "$Username 
Write-Host "------Password: "$Password
Write-Host "------Sitename: "$Sitename
Write-Host "------Dpathsite: "$Dpathsite
Write-Host "------Darch: "$Darch
$pw = convertto-securestring -AsPlainText -Force -String $Password
$credentials = new-object System.Management.Automation.PSCredential($Username,$pw)


Add-Type -AssemblyName System.IO.Compression.FileSystem


Try
{ 
 Write-Host "------Add host to trusted-hosts..." 
 $Dipstr = "'@{TrustedHosts=`""+"$Dip"+"`"}'"
 $str = "winrm s winrm/config/client "+$Dipstr
 Invoke-Expression $str
 
 Write-Host "------Connecting to session..." 
 $s = New-PSSession -ComputerName $Dip -Credential $credentials -ErrorAction Stop
}
catch
{
  Write-Host "------Error Add host to trusted-hosts!!!"
  Write-Host $error[0].Exception 
 # err $Spath $error[0].ToString()
 # exit 1
}

#$SiteName = "Admin"
$SitePath = $Dpath + $Sitename
Write-Host "------SitePath...$SitePath"

$TP = 
{
$Darch= $args[0]
 Remove-Item $Darch  -Force
}

invoke-command -session $s -ScriptBlock $TP -ArgumentList $Darch -ErrorAction SilentlyContinue
 
Copy-Item -ToSession $s -Path $Archpath -Destination $Darch -ErrorAction Stop

$CWS =
{

 $Archpath= $args[0]
 $Dpath= $args[1] 
 $SiteName= $args[2]
 $Dpathsite= $args[3]
 $Darch= $args[4]
 Add-Type -AssemblyName System.IO.Compression.FileSystem
 function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory("$zipfile", "$outpath")
}
 
try
{
 
 $poolCreated = Get-WebAppPoolState $SiteName 
 if ($poolCreated) {
 
 Write-Host "------PoolCerated"
 
 } else {
 
 Write-Host "------Pool Doesnt Cerated"
  New-WebAppPool -Name $SiteName -force
 Set-ItemProperty IIS:\AppPools\$SiteName managedRuntimeVersion v4.0
 }
 
}
catch
{
 # Assume it doesn't exist. Create it.
 exit 1
}
 
 if(!(Test-Path $Dpathsite)) {
 Write-Host "------Creating $Dpathsite"
 md $Dpathsite
}
else {
 Write-Host "------Cleaning $Dpathsite"
 Remove-Item "$Dpathsite\*" -recurse -Force
}

$site = Get-WebSite | where { $_.Name -eq $SiteName }

if($site -eq $null) {

 Write-Host "------Creating site: $SiteName $Dpathsite"
 
 # TODO:
 New-WebSite -Name $SiteName -PhysicalPath $Dpathsite
 
 Write-Host "------NewWebApplication $Dpathsite"
 New-WebApplication -Site $SiteName -Name $SiteName -PhysicalPath $Dpathsite -ApplicationPool $SiteName
 
}
Write-Host "------$env:UserName"
Write-Host "------Unziping from $Darch to $Dpathsite"
Unzip $Darch  $Dpathsite

}


invoke-command -session $s -ScriptBlock $CWS -ArgumentList $Archpath, $Dpath, $Sitename, $Dpathsite, $Darch  -ErrorAction Stop

