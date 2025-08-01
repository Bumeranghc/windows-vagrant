Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
trap {
    Write-Host
    Write-Output "ERROR: $_"
    Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Write-Host 'Sleeping for 60m to give you time to look around the virtual machine before self-destruction...'
    Start-Sleep -Seconds (60*60)
    Exit 1
}

$systemVendor = (Get-CimInstance -ClassName Win32_ComputerSystemProduct -Property Vendor).Vendor
if ($systemVendor -eq 'VMware, Inc.') {
    Write-Output 'Installing VMware Tools...'
    # silent install without rebooting.
    E:\setup.exe /s /v '/qn reboot=r' `
        | Out-String -Stream
}
elseif ($systemVendor -eq 'innotek GmbH') {
    Write-Output 'Installing VirtualBox Guest Additions...'
    # silent install without rebooting.
    E:\VBoxWindowsAdditions.exe /S `
        | Out-String -Stream
}
