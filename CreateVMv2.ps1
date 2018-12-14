Param(

    [string]$AdminUsername = "Administrator1",
    [string][ValidatePattern("^[a-zA-Z0-9-]{3,24}")]$KeyVautName = "DaniilKeyVault",
    [SecureString]$AdminPassword = $(ConvertTo-SecureString -String "Administrator1" -AsPlainText -Force ),
    [string][ValidateLength(3,19)]$VirtualMachineName = "DaniilKVM",
    [string]$Location = "westeurope",
    [string]$ResourceGroupVM = "DaniilK",
    [string]$SubnetFrontEndAddressPrefix = "10.0.0.0/24",
    [string]$AddressPrefix = "10.0.0.0/16",
    [string]$SubnetFrontEnd = "MySubnet",
    [string]$VirtualMachineSize = "Standard_D2s_v3",
    [hashtable[]]$DataDisks = @(`
    @{DiskSizeGB=32;AccountType="Premium_LRS";},
    @{DiskSizeGB=128;AccountType="Premium_LRS";}),
    [hashtable[]]$NetInterfaces = @(@{},@{})#???
)


#Creation variables
$oSDiskName = "$VirtualMachineName`OSDisk"
$vnetName = "$VirtualMachineName`_Vnet"
$networkSecurityGroupName = "$VirtualMachineName`_networkSecurityGroup"
$publicIpAddressName = "$VirtualMachineName`_publicIpAddress"
$networkInterfaceName = "$VirtualMachineName`_networkInterface"
$availabilitySetName = "$VirtualMachineName`_AvailabilitySet"
$diagnosticsStorageAccountName = "$VirtualMachineName`stacc"
$diagnosticsStorageAccountName = $diagnosticsStorageAccountName.ToLower()
$dataDiskName = "$VirtualMachineName`_dataDisk"
$secretName = "$VirtualMachineName`secret"


$rdpRule = New-AzureRmNetworkSecurityRuleConfig -Name "rdp-rule" -Description "Allow RDP" `
   -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
   -SourceAddressPrefix Internet -SourcePortRange * `
   -DestinationAddressPrefix * -DestinationPortRange 3389 

#check keyVault
$keyVaut = Get-AzureRmKeyVault -VaultName $KeyVautName -ResourceGroupName $ResourceGroupVM
if($keyVaut -eq $null){
    $keyVaut = New-AzureRmKeyVault -VaultName $KeyVautName -ResourceGroupName $ResourceGroupVM -Location $Location -EnabledForDeployment
    Write-Host "KeyVaut $KeyVautName` has been created." -ForegroundColor Green
}
else{   Write-Host "KeyVaut $KeyVautName` has already been created." -ForegroundColor Yellow}


#check Secret
$keyVautSecret = Get-AzureKeyVaultSecret -VaultName $keyVaut.VaultName -Name $secretName
if($keyVautSecret -eq $null){
    $keyVautSecret = Set-AzureKeyVaultSecret -VaultName $keyVaut.VaultName -Name $secretName -SecretValue $AdminPassword 
    Write-Host "KeyVautSecret $secretName` has been created." -ForegroundColor Green
}
else{   Write-Host "KeyVautSecret $secretName` has already been created." -ForegroundColor Yellow}


#check networkSecurityGroup
$networkSecurityGroup = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupVM -Name $networkSecurityGroupName -ErrorAction SilentlyContinue
if($networkSecurityGroup -eq $null){
    $networkSecurityGroup = New-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupVM -Location $Location -Name $networkSecurityGroupName -SecurityRules $rdpRule
    Write-Host "NetworkSecurityGroup $networkSecurityGroupName` has been created." -ForegroundColor Green
}
else{   Write-Host "NetworkSecurityGroup $networkSecurityGroupName` has already been created." -ForegroundColor Yellow}


#check network
$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $ResourceGroupVM -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
if($vnet -eq $null){
    $subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetFrontEnd -AddressPrefix $SubnetFrontEndAddressPrefix -NetworkSecurityGroup $networkSecurityGroup
    $vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $ResourceGroupVM -Location $Location -AddressPrefix $AddressPrefix -Subnet $subnet -WarningAction SilentlyContinue
    Write-Host "VirtualNetwork $vnetName` has been created." -ForegroundColor Green
}
else{   Write-Host "VirtualNetwork $vnetName` has already been created." -ForegroundColor Yellow}


#check publicIP
$publicIP = Get-AzureRmPublicIpAddress -Name $publicIpAddressName -ResourceGroupName $ResourceGroupVM -ErrorAction SilentlyContinue
if($publicIP -eq $null){
    $publicIP = New-AzureRmPublicIpAddress -Name $publicIpAddressName -ResourceGroupName $ResourceGroupVM -Location $Location -AllocationMethod Dynamic
    Write-Host "PublicIpAddress $publicIpAddressName` has been created." -ForegroundColor Green
}
else{   Write-Host "PublicIpAddress $publicIpAddressName` has already been created." -ForegroundColor Yellow}


#check networkInterface
$networkInterface = Get-AzureRmNetworkInterface -Name $networkInterfaceName -ResourceGroupName $ResourceGroupVM -ErrorAction SilentlyContinue
if($networkInterface -eq $null){
    $networkInterface = New-AzureRmNetworkInterface -Name $networkInterfaceName -ResourceGroupName $ResourceGroupVM -Location $Location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIP.Id
    Write-Host "NetworkInterface $networkInterfaceName` has been created." -ForegroundColor Green
}
else{   Write-Host "NetworkInterface $networkInterfaceName` has already been created." -ForegroundColor Yellow}


#check AvailabilitySet
$availabilitySet = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupVM -Name $availabilitySetName -ErrorAction SilentlyContinue
if($availabilitySet -eq $null){
    $availabilitySet = New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupVM -Name $availabilitySetName -Location $Location -Sku "Aligned" -PlatformFaultDomainCount 2
    Write-Host "AvailabilitySet $availabilitySetName` has been created." -ForegroundColor Green
}
else{   Write-Host "AvailabilitySet $availabilitySetName` has already been created." -ForegroundColor Yellow}


#check diagnosticsStorageAccount

$diagnosticsStorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupVM -AccountName $diagnosticsStorageAccountName 
if($diagnosticsStorageAccount -eq $null){
    $diagnosticsStorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupVM -AccountName $diagnosticsStorageAccountName -Location $Location -SkuName Standard_GRS
    Write-Host "DiagnosticsStorageAccount $diagnosticsStorageAccount` has been created." -ForegroundColor Green
}
else{   Write-Host "DiagnosticsStorageAccount $diagnosticsStorageAccount` has already been created." -ForegroundColor Yellow}

$credential = New-Object System.Management.Automation.PSCredential($AdminUsername, (Get-AzureKeyVaultSecret -VaultName $KeyVautName -Name $secretName).SecretValue)
$virtualMachine = New-AzureRmVMConfig -VMName $VirtualMachineName -VMSize $VirtualMachineSize -AvailabilitySetId $availabilitySet.Id


#check Datadisk
$dataDiskNumber=0;
Foreach($dataDisk in $DataDisks){
    
    $datadiskResource = Get-AzureRmDisk -ResourceGroupName $ResourceGroupVM -DiskName "$dataDiskName$dataDiskNumber" -ErrorAction SilentlyContinue
    if($datadiskResource -eq $null){
        #creation disk
        $diskconfig = New-AzureRmDiskConfig -Location $Location -CreateOption Empty -OsType Windows -EncryptionSettingsEnabled $false @dataDisk 
        $dataDiskResource = New-AzureRmDisk -ResourceGroupName $ResourceGroupVM -DiskName "$dataDiskName$dataDiskNumber" -Disk $diskconfig

        Write-Host "Datadisk $dataDiskName$dataDiskNumber` has been created." -ForegroundColor Green
    }
    else{   Write-Host "Datadisk $dataDiskName$dataDiskNumber` has already been created." -ForegroundColor Yellow}

    #attach disk to vm
    $virtualMachine = Add-AzureRmVMDataDisk -VM $virtualMachine -Name "$dataDiskName$dataDiskNumber" -Caching 'ReadWrite' `
    -DiskSizeInGB $dataDisk.DiskSizeGB -Lun $dataDiskNumber -CreateOption Attach -ManagedDiskId $dataDiskResource.Id -StorageAccountType $dataDisk.AccountType

    $dataDiskNumber++;
}

Write-Host "All resources has been created." -ForegroundColor Yellow

$virtualMachine = Set-AzureRmVMSourceImage -VM $virtualMachine -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2012-R2-Datacenter" -Version "latest" #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

$virtualMachine = Set-AzureRmVMOperatingSystem -VM $virtualMachine -Windows -ComputerName $VirtualMachineName -Credential $credential -ProvisionVMAgent -EnableAutoUpdate

$virtualMachine = Add-AzureRmVMNetworkInterface -VM $virtualMachine -Id $networkInterface.Id

$virtualMachine = Set-AzureRmVMOSDisk -VM $virtualMachine -Name $oSDiskName -Caching "ReadWrite" -CreateOption "FromImage" -Windows

$virtualMachine = Set-AzureRmVMBootDiagnostics -VM $virtualMachine -Enable -ResourceGroupName $ResourceGroupVM -StorageAccountName $diagnosticsStorageAccount.StorageAccountName



$vM = New-AzureRmVM -ResourceGroupName $ResourceGroupVM -Location $Location -VM $virtualMachine -Verbose 
Write-Host "VirtualMachine $VirtualMachineName` has been created." -ForegroundColor Green
