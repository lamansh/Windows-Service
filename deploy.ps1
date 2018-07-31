#Set-PSDebug -Trace 2
param(
	
  [string]$Spath,
  [string]$Dpath,
  [string]$Archpath,
  [string]$Dip,
  [string]$Exec,
  [string]$Service,
  [string]$Username,
  [string]$Password
)
######

$SCopypath = $Spath
$RMpath = "$Dpath" +"\*"

# Delete "*.*" from $Spath
$len = $Spath.length 
$errpath = $Spath.Substring(0,$len - 3)
Remove-Item $errpath\error.txt 


$GS =
{
$nm = $args[0]
Get-Service $nm
}

$SA =
{
<#$Dp= $args[0]
$ar = $Dp.Split("\""")
$ar= $ar[0..($ar.Count-1)]
$Archpath=[string]::Join("\",$ar)
$Svc =  $args[1]
$Dp1= $Dp+"*.*"
#>
$Dp= $args[0]
$Archpath= $args[1]
$Svc =  $args[2]
$Dp1= $Dp+"*"
$Dt= Get-Date -Format o  | foreach {$_ -replace ":", "."}
$Archpath  = $Archpath+"$Svc"+"$Dt"+".zip"

Write-Host "Spath-------------------$Spath"
Write-Host "DP-------------------$DP"
Write-Host "Archive path-------------------$ArchPath"

Compress-Archive -Path $Dp1 -CompressionLevel Fastest -DestinationPath $Archpath 


}

$SS =
{
$nm = $args[0]
 If ((Get-Service $nm).Status -eq 'Running') {

        Stop-Service $nm
		Start-Sleep -s 5
        Write-Host "------Stopping $nm"

  
  
 
}  Else {

        Write-Host "------$nm found, but it is not running."

    }

}

$SC = 
{
$Dip = $args[0]
$Service = $args[1]
$Exec = $args[2]

sc.exe \\$Dip create $Service  binPath= $Exec  DisplayName=$Service depend= tcpip start= auto


}

#Write-Host "------Sourcepath exec "$Runservice 
Write-Host "------Spath "$Spath 
Write-Host "------Artifacts From: "$Dpath 

$pw = convertto-securestring -AsPlainText -Force -String $Password
$credentials = new-object System.Management.Automation.PSCredential($Username,$pw)

function err {
 
 $len = $args[0].length 
 $errpath = $args[0].Substring(0,$len - 3)
 fsutil file createnew $errpath\error.txt 1000
 Write-Host "------$errpath------Error File Path"
 #echo $args[1] >  $errpath\error.txt
 exit 1
}

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

Try
{ 
$Service1exist = Invoke-Command -Session $s -ScriptBlock $GS -ArgumentList $Service
Write-Host "------Serice Status: - $Service1exist "
}

catch
{
  Write-Host "------Error while verify $Service--Status!!!"
  Write-Host $error[0].Exception 
  err $Spath $error[0].ToString()
  exit 1
}
 
if ($Service1exist){

Write-Host "------$Service Exists..."

Try
{ 
 Write-Host "------Stopping Service..."
 $wait = Invoke-Command -Session $s -ScriptBlock $SS -ArgumentList $Service -ErrorAction Stop
 Write-Host "------Wait $wait"
 
}
catch
{
  Write-Host "Error While Stopping Service...$Service!!!"
  Write-Host $error[0].Exception 
  err $Spath
  exit 1
}


if( Invoke-Command -Session $s -Command {Test-Path -Path $Using:Dpath} ) {
Try
{ 
  Write-Host "------Archiving existing service..."
  
   if(!(Invoke-Command -Session $s -Command {Test-Path -Path $Using:Archpath}) ){
	Invoke-Command -Session $s -Command {New-Item -ItemType directory -Path $Using:Archpath}
   }
  Invoke-Command -Session $s -ScriptBlock $SA -ArgumentList $Dpath, $Archpath, $Service   -ErrorAction  Stop

}

catch
{
  Write-Host "Error While Archiving existing service..to..$Dpath..$Archpath..!!!"
  Write-Host $error[0].Exception 
  err $Spath $error[0].ToString() 
  exit 1
}
}

Try
{ 
 Write-Host "------Cleaning Service folder..."
 Invoke-Command -Session $s -Command {Remove-Item $Using:RMpath -Force -Recurse -Confirm:$false -Exclude *.zip} -ErrorAction SilentlyContinue
}
catch
{
  Write-Host "------Cleaning Service folder..Error!!!"
  Write-Host $error[0].Exception 
  err $Spath $error[0].ToString() 
  exit 1
}
Try
{ 
 Write-Host "---------------Copyng files to Server..."
 Write-Host "---------------Creating Dir For Service...$Dpath"  

if(!(Invoke-Command -Session $s -Command {Test-Path -Path $Using:Dpath} )){

   Invoke-Command -Session $s -Command { New-Item -ItemType directory -Path $Using:Dpath} -ErrorAction Stop
   Write-Host "---------------Creating Dirs For Service..."   
}
 Copy-Item -ToSession $s -Path $SCopypath -Destination $Dpath -Recurse -ErrorAction Stop
}
catch
{
  Write-Host "---------------Error while Coping from..$Dpath..to..$SCopypath!"
  
  Write-Host $error[0].Exception 
  err $Spath 
  exit 1
}

#& $Runservice 
Try
{ 
 Write-Host "------Starting Service with new executables..."
 Invoke-Command -Session $s -Command {Start-Service -Name $Using:Service} -ErrorAction Stop
}
catch
{
  Write-Host "Error!!!"
  Write-Host $error[0].Exception 
  err $Spath $error[0].ToString() 
  exit 1
}


} 
else {

Write-Host "---------------$Service Doesn't Exists...$Dpath"




Try
{
if(!(Invoke-Command -Session $s -Command {Test-Path -Path $Using:Dpath} )){
   Invoke-Command -Session $s -Command { New-Item -ItemType directory -Path $Using:Dpath} -ErrorAction Stop
   Write-Host "---------------Creating Dir For Service..."   
}
 Write-Host "---------------Copyng exec files to Server..."
 Copy-Item -ToSession $s -Path $SCopypath -Destination $Dpath -Recurse -ErrorAction Stop

}
catch
{
  Write-Host "Error!!!  Copyng exec files to Server"
  Write-Host $error[0].Exception 
  err $Spath $error[0].ToString() 
  exit 1
}
Try
{
  Write-Host "---------------Installing Service - "
 Invoke-Command -Session $s -ScriptBlock $SC -ArgumentList $Dip, $Service, $Exec
}
catch
{
  Write-Host "Error!!!"
  Write-Host $error[0].Exception 
  err $Spath $error[0].ToString() 
  exit 1
}

Try
{ 
 Write-Host "---------------Starting Service with new executables..."
 Invoke-Command -Session $s -Command {Start-Service -Name $Using:Service} -ErrorAction Stop
}
catch
{
  Write-Host "Error!!!"
  Write-Host $error[0].Exception 
  err $Spath $error[0].ToString() 
  exit 1
}

}
#Start-Process $Runservice -Verb Open
