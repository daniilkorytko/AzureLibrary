$ResourceGroup = "DaniilK"
$LOcation = "westeurope"

New-AzureRmResourceGroup -Name $ResourceGroup -Location $LOcation -Force

$deployment = New-AzureRmResourceGroupDeployment  -ResourceGroupName $ResourceGroup `
   -TemplateFile "C:\Work\Azure Part 2\Create-VM\OnlyARM\Create-ResourceVM.jsonc" `
   -TemplateParameterFile "C:\Work\Azure Part 2\Create-VM\OnlyARM\Create-ResourceVMParametrs.json" -Verbose

