function Get-VMToolsStatus
    {
        [CmdletBinding()] 
        Param (
            [AllowEmptyString()][string]$VMName ,
			[AllowEmptyString()][string]$VMLocation ,
            [ValidateSet('NeedUpgrade','NotInstalled','Unsupported')][string]$Filter
            )
			
    if ($VMName -eq "") { $VMName = "*"}
    if ($VMLocation -eq "") { $VMLocation = "*"}

	$GetVMs = $null
	if ($VMLocation -ne "*") {
		Write-Host "Get VMs from Location: [$VMLocation]"
		$GetVMs = Get-VM -Location $VMLocation
	}
	
    $VMs = Get-View -ViewType VirtualMachine -Property name,guest,config.version,runtime.PowerState
    $report = @()
    $progress = 1
	
    foreach ($VM in $VMs) {
	
		[bool] $VMToReturn = $false
		$i = 0
	    if ($VM.Name -like $VMName) {
			if ($VMLocation -ne "*") { 
				foreach ($GetVM in $GetVMs) { 
					if ($VM.Name -eq $GetVM.Name) { 
						$VMToReturn = $true 
						} 
					}
				} 
			else { $VMToReturn = $true }
		}
		
		Write-Progress -Activity "Checking vmware tools status" -Status "Working on $($VM.Name)" -PercentComplete ($progress/$VMs.count*100) -ErrorAction SilentlyContinue

		if ($VMToReturn) {
			$object = New-Object PSObject
			Add-Member -InputObject $object NoteProperty VM $VM.Name
			Add-Member -InputObject $object NoteProperty PowerState $VM.runtime.powerstate
			Add-Member -InputObject $object NoteProperty ToolsStatus $VM.guest.ToolsStatus
			Add-Member -InputObject $object NoteProperty ToolsVersionStatus ($VM.Guest.ToolsVersionStatus).Substring(10)
			Add-Member -InputObject $object NoteProperty SupportState ($VM.Guest.ToolsVersionStatus2).Substring(10)
			if ($object.ToolsStatus -eq "NotInstalled") {Add-Member -InputObject $object NoteProperty Version ""}
			else {Add-Member -InputObject $object NoteProperty Version $VM.Guest.ToolsVersion}
			Add-Member -InputObject $object NoteProperty HWVersion $VM.config.version
			$report += $object
			$progress++
		}
		
		Write-Progress -Activity "Checking vmware tools" -Status "All done" -Completed -ErrorAction SilentlyContinue
	}

	if ($Filter -eq 'NeedUpgrade') {
			$report | Sort-Object vm | Where-Object {$_.ToolsVersionStatus -eq "NeedUpgrade"}
			}
	elseif ($Filter -eq 'NotInstalled') {
			$report | Sort-Object vm | Where-Object {$_.ToolsVersionStatus -eq "NotInstalled"}
			}
	elseif ($Filter -eq 'Unsupported') {
			$report | Sort-Object vm | Where-Object {($_.SupportState -eq "Blacklisted") -or ($_.SupportState -eq "TooNew") -or ($_.SupportState -eq "TooOld") -or ($_.SupportState -eq "Unmanaged")}
			}
	else {$report | Sort-Object vm}

	<#
 .Synopsis
  List vm tools status for all VMs
 .Description
  Lists the status and version for all VMs, also tells whether the version is supported and also the vm version
 .Parameter VMName
  Specify VMs by Name
 .Parameter Filter
  Filters the list based on if the VMware tools "NeedUpgrade", is "NotInstalled" or if they are "Unsupported"
 .Example
  Get-VMToolsStatus
  List vm tools status for all VMs
  .Example
  Get-VMToolsStatus -VMName Win7*
  List vm tools status for all VMs which name like Win7*
  .Example
  Get-VMToolsStatus -VMLocation *58.1
  List vm tools status for all VMs which location like *58.1
  .Example
  Get-VMToolsStatus -Filter NeedUpgrade
  Show only VMs needing update of vm tools
 .Link
  http://www.vmware.com
 #>
}