Connect-AzAccount -Identity

$count = (Get-AzResourceGroup).Count
Write-Output "Number of resource groups: $count"
