
<#
.SYNOPSIS
Start all VMs in the current subscription.

.REQUIREMENTS
- Automation Account has System Assigned Managed Identity enabled
- MI has at least: Virtual Machine Contributor (or Contributor) on the subscription
- Az.Accounts + Az.Compute modules available in the Automation account
#>

param(
    # Optional: set a specific subscription if your MI has access to multiple subs
    [Parameter(Mandatory = $false)]
    [string] $SubscriptionId
)

Write-Output "Logging in with Managed Identity..."
Connect-AzAccount -Identity | Out-Null

if ($SubscriptionId) {
    Write-Output "Setting context to subscription: $SubscriptionId"
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}

# Get VMs + power state
Write-Output "Retrieving VMs in subscription..."
$vms = Get-AzVM -ResourceGroupName "ubuntu-old_group" -Status

if (-not $vms) {
    Write-Output "No VMs found in this subscription."
    return
}

$toStart = $vms | Where-Object {
    $_.PowerState -in @("VM deallocated","VM stopped")
}

Write-Output "Total VMs found: $($vms.Count)"
Write-Output "VMs to start (currently stopped/deallocated): $($toStart.Count)"

foreach ($vm in $toStart) {
    try {
        Write-Output "Starting VM: $($vm.Name) (RG: $($vm.ResourceGroupName)) | CurrentState: $($vm.PowerState)"
        Start-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -ErrorAction Stop | Out-Null
        Write-Output "Started: $($vm.Name)"
    }
    catch {
        Write-Output "FAILED to start: $($vm.Name) | Error: $($_.Exception.Message)"
    }
}

Write-Output "Runbook completed."

