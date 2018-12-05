$ResourceGroup = "DaniilK"
$MyLOcation = "westeurope"
$adminUsername = 'Administrator1'
$Secure_String_Pwd = ConvertTo-SecureString "Administrator1" -AsPlainText -Force


$TemplateParametersCreateVM = "https://raw.githubusercontent.com/daniilkorytko/AzureLibrary/master/Create-ResourceVMParametrs.json"
$TemplateUriCreateVM = "https://raw.githubusercontent.com/daniilkorytko/AzureLibrary/master/Create-ResourceVM.json"


$FileParametersCreateVM = "$env:TEMP\FileParametersCreateVM.json"
$FileCreateVM  = "$env:TEMP\FileCreateVM.json"


Invoke-WebRequest -Uri $TemplateParametersCreateVM -OutFile $FileParametersCreateVM
Invoke-WebRequest -Uri $TemplateUriCreateVM -OutFile $FileCreateVM


New-AzureRmResourceGroupDeployment  -ResourceGroupName $ResourceGroup `
   -TemplateFile $FileCreateVM `
   -TemplateParameterFile $FileParametersCreateVM `
   -AdminPassword $Secure_String_Pwd -adminUsername $adminUsername -Verbose `
   -virtualMachineName 'DaniilK-VM1' 


