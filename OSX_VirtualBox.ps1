cls
Write-Host 'Creating OSX Virtual Machine' -ForegroundColor Green
#region Variables
    $OSXVMPath = 'B:\OSXAuto\'
    $OSXVMName = 'OSXAuto'
    # dmg file from Apple and utilities to convert to vmdk
    $prerequisites = @('http://swcdn.apple.com/content/downloads/10/62/091-76233/v27a64q1zvxd2lbw4gbej9c2s5gxk6zb1l/BaseSystem.dmg',
                       'http://vu1tur.eu.org/tools/dmg2img-1.6.6-win32.zip',
                       'https://cloudbase.it/downloads/qemu-img-win-x64-2_3_0.zip')
    $VirtualBoxManage = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
    # CPUs should be 2 or more
    $NumberofCPUs = 2
    # Memory should be at least 4GB
    $VMMemory = 4096
    # Size of main OS disk
    $VMDisk = 51200
    $VirtualBoxExePath = 'C:\Program Files\Oracle\VirtualBox\VirtualBox.exe'
#endregion
#region Create VM Path
    if ( -Not (Test-Path $OSXVMPath)) {
        Write-Host "Directory doesn't exist attempting to create..." -ForegroundColor Yellow
        New-Item -Path $OSXVMPath `
                 -ItemType Directory | out-null
        Write-Host 'Directory created' -ForegroundColor Green
        cd $OSXVMPath
    }
#endregion
#region Download Prerequisites
    Write-Host 'Downloading Prerequisites...' -ForegroundColor Green
    foreach ($prerequisite in $prerequisites) {
        $Matches = $null
        $prerequisite -match '(?:.+\/)(.+)' | Out-Null
        $OutPutFileName = $Matches[1]
        Write-Host "Downloading $OutPutFileName" -ForegroundColor Green
        Invoke-WebRequest -Uri $prerequisite `
                          -OutFile $OutputFileName
    }
#endregion
#region Configure Prerequisites
    # Uncompress zip files
    Write-Host 'Extracting .zip files' -ForegroundColor Green
    Get-ChildItem -Path *.zip | Expand-Archive -DestinationPath $OSXVMPath
    # Find the DMG File and get info
    Write-Host 'Finding the .dmg file' -ForegroundColor Green
    $OSXImage = Get-ChildItem -Path *.dmg
    # Convert DMG file to ISO
    Write-host 'Converting the .dmg file to .img' -ForegroundColor Green
    .\dmg2img.exe $OSXImage.Name ($OSXImage.BaseName+'.img') | Out-Null
    # Convert IMG File to VMDK
    Write-Host 'Converting the .img file to .vmdk' -ForegroundColor Green | Out-Null
    .\qemu-img.exe convert BaseSystem.img -O vmdk ($OSXVMPath+$OSXVMName+'.vmdk')
#endregion
#region Configure VirtualMachine
    Write-Host 'Configuring VirtualBox VM' -ForegroundColor Green
    & $VirtualBoxManage createvm --name $OSXVMName --ostype MacOS1011_64 --register | Out-Null
    & $VirtualBoxManage modifyvm $OSXVMName --cpuidset 00000001 000106e5 00100800 0098e3fd bfebfbff
    & $VirtualBoxManage setextradata $OSXVMName "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct" "iMac11,3"
    & $VirtualBoxManage setextradata $OSXVMName "VBoxInternal/Devices/efi/0/Config/DmiSystemVersion" "1.0"
    & $VirtualBoxManage setextradata $OSXVMName "VBoxInternal/Devices/efi/0/Config/DmiBoardProduct" "Iloveapple"
    & $VirtualBoxManage setextradata $OSXVMName "VBoxInternal/Devices/smc/0/Config/DeviceKey" "ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
    & $VirtualBoxManage setextradata $OSXVMName "VBoxInternal/Devices/smc/0/Config/GetKeyFromRealSMC" 1
    & $VirtualBoxManage modifyvm $OSXVMName --memory $VMMemory --vram 128 --usb on --pae on --hwvirtex on --nestedpaging on --vtxvpid on --vtxvpid on --chipset ich9 --vram 128 --cpus $NumberofCPUs --usb on --pae on --hwvirtex on --nestedpaging on --vtxvpid on --chipset ich9 --rtcuseutc on --firmware efi --boot1 disk --boot2 none --boot3 none --boot4 none --mouse usbtablet --keyboard usb --usbehci on --hpet on
    & $VirtualBoxManage storagectl $OSXVMName --name “SATA Controller” --add sata --controller IntelAHCI
    & $VirtualBoxManage storageattach $OSXVMName --storagectl “SATA Controller” --type hdd --port 0 --device 0 --medium ($OSXVMName+'.vmdk')
    & $VirtualBoxManage createhd --filename OSX.vmdk --size 51200 | Out-Null
    & $VirtualBoxManage storageattach $OSXVMName --storagectl “SATA Controller” --type hdd --port 1 --device 0 --medium OSX.vmdk
    & $VirtualBoxExePath
    & $VirtualBoxManage startvm $OSXVMName
#endregion