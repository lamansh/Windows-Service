# Delete "*.*" from $Spath
$len = $Spath.length 
$errpath = $Spath.Substring(0,$len - 3)
Remove-Item $errpath\error.txt 
#Remove-Item $errpath\error.txt 


$GS =
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
{
  Write-Host "------Error while verify $Service--Status!!!"
  Write-Host $error[0].Exception 
  err $Spath $error[0].ToString()
  exit 1
}
 
{
  Write-Host "Error While Stopping Service...$Service!!!"
  Write-Host $error[0].Exception 
  err $Spath
  
  exit 1
}

{
  Write-Host "Error While Archiving existing service..to..$Dpath..$Archpath..!!!"
  Write-Host $error[0].Exception 
  err $Spath $error[0].ToString() 
  exit 1
}
}
{
  Write-Host "------Cleaning Service folder..Error!!!"
  Write-Host $error[0].Exception 
  err $Spath $error[0].ToString() 
  exit 1
}
Try
  Write-Host "---------------Error while Coping from..$Dpath..to..$SCopypath!"
  
  Write-Host $error[0].Exception 
  err $Spath 
  exit 1
}

{
  Write-Host "Error!!!"
  Write-Host $error[0].Exception 
  err $Spath $error[0].ToString() 
  exit 1
}

{
  Write-Host "Error!!!  Copyng exec files to Server"
  Write-Host $error[0].Exception 
  err $Spath $error[0].ToString() 
  exit 1
}
Try
{
  Write-Host "Error!!!"
  Write-Host $error[0].Exception 
  err $Spath $error[0].ToString() 
  exit 1
}

{
  Write-Host "Error!!!"
  Write-Host $error[0].Exception 
  err $Spath $error[0].ToString() 
  exit 1
}
