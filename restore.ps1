param(

  [string]$archivefolder,
  [string]$restorefolder,
  [string]$Service,
  [string]$Dip,
  [string]$Dpath,
  [string]$Username,
  [string]$Password,
  [string]$Builddir

 )

$RST = 
{
$Dip = $args[0]
$archivefolder = $args[1]
$resotefolder = $args[2]
$Service1 = $args[3]+".*zip"
Write-Host "------Service1...$Service1"
$archivefile = Get-ChildItem $archivefolder | Where-Object { $_.Name -Match $Service1} | Sort-Object -Property @{Expression={$_.LastWriteTime }; Ascending = $False} | Select-Object -first 1 |   %{ $_.FullName }
Write-Host "------Archiving-File...$archivefile" 
Add-Type -AssemblyName System.IO.Compression.FileSystem
function unzip {
    param( [string]$ziparchive, [string]$extractpath )
    [System.IO.Compression.ZipFile]::ExtractToDirectory( $ziparchive, $extractpath )
}
unzip $archivefile $resotefolder

}

$SS =
{

$nm = $args[0]

 If ((Get-Service $nm).Status -eq 'Running') {

        Stop-Service $nm
		Start-Sleep -s 5
        Write-Host "------Stopping $serviceName"

    } Else {

        Write-Host "------$nm found, but it is not running."

    }


}


#$Dip="10.1.227.144"
$pw = convertto-securestring -AsPlainText -Force -String $Password
$credentials = new-object System.Management.Automation.PSCredential($Username,$pw)
$RMpath = $Dpath+"*"
#$Service = "Kernel.GrainFlowService"

if (Test-Path $Builddir\error.txt) {

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
  Write-Host "Error Add host to trusted-hosts!!!"
  Write-Host $error[0].Exception
  exit 1
}

Try
{ 
 Write-Host "------Stopping Service..."
 Invoke-Command -Session $s -ScriptBlock $SS -ArgumentList $Service -ErrorAction SilentlyContinue
}
catch
{
  Write-Host "Error While Stopping Service...!!!"
  Write-Host $error[0].Exception
  exit 1
}

Try
{ 
 Write-Host "------Cleaning Service folder..."+"$RMpath"
 Invoke-Command -Session $s -Command {Remove-Item $Using:RMpath -Force -Recurse -Confirm:$false -Exclude *.zip} -ErrorAction SilentlyContinue
}
catch
{
  Write-Host "Error!!!"
  Write-Host $error[0].Exception
  exit 1
}

Invoke-Command -Session $s -ScriptBlock $RST -ArgumentList $Dip, $archivefolder, $restorefolder, $Service  -ErrorAction  Stop
Try
{ 
 Write-Host "------Starting Service with new executables..."
 Invoke-Command -Session $s -Command {Start-Service -Name $Using:Service} -ErrorAction Stop
}
catch
{
  Write-Host "Error!!!"
  Write-Host $error[0].Exception
  exit 1
}
} else {
   
   Write-Host "------------------------------------------I dont need Restore-----------------------------" 
    
}
