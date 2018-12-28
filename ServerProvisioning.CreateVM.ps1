# Variable Declarations
. "$PSScriptRoot\ServerProvisioning.GlobalVariables.ps1"

# Prompt the user for Login Credentials
    Write-Host "READ ME! Authentication: Enter your privileged user account. Example; jdoe" -ForegroundColor Yellow
        $DomainUser = Read-Host -Prompt "Privileged User Account"     
        $DomainLogin = $DomainSuffix + $DomainUser    
    Write-Host "READ ME! Authentication: Enter your privileged user account password." -ForegroundColor Yellow
        $DomainPassword = Read-Host -AsSecureString "Privileged User Account Password"                
         
# Create credential sets                
    $DomainCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DomainLogin,$DomainPassword

# Connect to vCenter
    Connect-VIServer -Server $vCenterServer -Credential $DomainCredentials
    
#Prompt for Server information
    $VMname = Read-Host -Prompt "Enter VM Name"
        $VMname = $VMname.ToUpper().Trim()
    $IPAddress = Read-Host -Prompt "Enter VM IP Address"
    $VMDescription = Read-Host -Prompt "Enter VM Description"

# Set the VM IP Address
    Get-OSCustomizationSpec $OSCusSpec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIp -IpAddress $IPAddress -SubnetMask $SubnetMask -DefaultGateway $DefaultGateway -DNS $DNS01,$DNS02

# VM Placement conditions (cluster, folder location, and datastore)
    if ($VMname -like $ProdVMConvention) 
     {
      $Cluster = $ProdCluster
      $FolderLocation = $ProdFolder
      $DSname = $ProdStorage
     }
    if ($VMname -like $DevVMConvention) 
     {
      $Cluster = $DevCluster
      $FolderLocation = $DevFolder
      $DSname = $DevStorage
     }
    $Datastore = Get-Datastore -Name $DSname | Sort-Object -Property FreeSpaceGB -Descending | Select -First 1

# Deploy Virtual Machine and remove temp custom spec
    New-VM -Name $VMName -Template $Template -ResourcePool $Cluster -location $FolderLocation -DiskStorageFormat thin -Datastore $Datastore -OSCustomizationSpec $OSCusSpec

# Set VM Notes 
    Set-vm -vm $VMName -Notes $VMDescription -Confirm:$false

#Start the VM to continue the customization process
    Start-VM -VM $VMname
