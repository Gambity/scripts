cd C:\Users\bublienko\MDT

write-host "Removing old install.wim" -foreground Yellow
rm install.wim

write-host "Search ESD image for Pro version" -foreground Yellow
Get-WindowsImage -imagepath .\W10\sources\install.esd -Name "Windows 10 Pro" -OutVariable out

$SIndex = $out.ImageIndex

write-host "Source Index [$SIndex]: " -Foreground Yellow -NoNewline

$UValue = Read-Host
if ($UValue) {$SIndex = $UValue}

write-host

write-host "Converting image ESD Pro - WIM Pro" -foreground Yellow
& 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\x86\DISM\dism.exe' /export-image /SourceImageFile:.\W10\sources\install.esd /SourceIndex:$SIndex /DestinationImageFile:install.wim /Compress:max /CheckIntegrity

Get-WindowsImage -imagepath install.wim -index 1

#$host.ui.RawUI.ReadKey(6)|out-null

write-host "Mounting image" -foreground Yellow
Mount-WindowsImage -imagepath install.wim -index 1 -path wim

write-host "Injecting updates" -foreground Yellow
Add-WindowsPackage -Path wim -PackagePath "00.W10UPDATES" -IgnoreCheck
Add-WindowsPackage -Path wim -PackagePath "01.W10UPDATES" -IgnoreCheck

write-host "Injecting default associations" -foreground Yellow
& 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\x86\DISM\dism.exe' /Image:wim /Import-DefaultAppAssociations:w10-ie-default.xml

write-host "Injecting default Start Menu Layout" -foreground Yellow
xcopy LayoutModification.xml wim\Users\Default\AppData\Local\Microsoft\Windows\Shell\ /Q /R /Y /H
xcopy LayoutModification.xml wim\Users\Default\AppData\Local\Microsoft\Windows\Shell\DefaultLayouts.xml /Q /R /Y /H

write-host "Removing subscribed content" -foreground Yellow
Reg Load HKLM\WIM_CU wim\users\Default\NTUSER.DAT

Reg Add "HKLM\WIM_CU\Software\Policies\Microsoft\Windows\Explorer" /v "ShowRunasDifferentUserInStart" /d 1 /f
Reg Add "HKLM\WIM_CU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /d 0 /f
Reg Add "HKLM\WIM_CU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-310093Enabled" /d 0 /f
Reg Add "HKLM\WIM_CU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /d 0 /f
Reg Add "HKLM\WIM_CU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /d 0 /f
Reg Add "HKLM\WIM_CU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /d 0 /f
Reg Add "HKLM\WIM_CU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /d 0 /f
Reg Add "HKLM\WIM_CU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSyncProviderNotifications" /d 0 /f
Reg Add "HKLM\WIM_CU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" /v "PeopleBand" /d 0 /f

Reg Unload HKLM\WIM_CU
Reg Load HKLM\WIM_Software wim\windows\system32\config\software

Reg Add "HKLM\WIM_Software\Policies\Microsoft\Windows\Cloud Content" /v "DisableWindowsConsumerFeatures" /d 1 /f
Reg Add "HKLM\WIM_Software\Policies\Microsoft\Windows\GameDVR" /v "AllowgameDVR" /d 0 /f

write-host "NEED TO CHANGE PERMISSIONS MANUALLY ON BELOW PATH" -foreground Yellow
write-host "HKLM\WIM_Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" -foreground Yellow
### NEED TO CHANGE PERMISSIONS MANUALLY ###
Start-Process regedit -Wait

Reg Add "HKLM\WIM_Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\Microsoft-Windows-OneDrive-Setup-Package~31bf3856ad364e35~amd64~~10.0.17134.1" /v "Visibility" /t REG_DWORD /d 1 /f
Reg Add "HKLM\WIM_Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\Microsoft-Windows-OneDrive-Setup-Package~31bf3856ad364e35~amd64~en-US~10.0.17134.1" /v "Visibility" /t REG_DWORD /d 1 /f
Reg Add "HKLM\WIM_Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\Microsoft-Windows-OneDrive-Setup-WOW64-Package~31bf3856ad364e35~amd64~~10.0.17134.1" /v "Visibility" /t REG_DWORD /d 1 /f

Reg Delete "HKLM\WIM_Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\Microsoft-Windows-OneDrive-Setup-Package~31bf3856ad364e35~amd64~~10.0.17134.1\Owners" /f
Reg Delete "HKLM\WIM_Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\Microsoft-Windows-OneDrive-Setup-Package~31bf3856ad364e35~amd64~en-US~10.0.17134.1\Owners" /f
Reg Delete "HKLM\WIM_Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\Microsoft-Windows-OneDrive-Setup-WOW64-Package~31bf3856ad364e35~amd64~~10.0.17134.1\Owners" /f

Reg Unload HKLM\WIM_Software

write-host "Removing Apps (including Windows Store)" -foreground Yellow

Remove-WindowsPackage -Path wim -Packagename:Microsoft-Windows-OneDrive-Setup-Package~31bf3856ad364e35~amd64~en-US~10.0.17134.1
Remove-WindowsPackage -Path wim -Packagename:Microsoft-Windows-OneDrive-Setup-Package~31bf3856ad364e35~amd64~~10.0.17134.1
Remove-WindowsPackage -Path wim -Packagename:Microsoft-Windows-OneDrive-Setup-WOW64-Package~31bf3856ad364e35~amd64~~10.0.17134.1

Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.DesktopAppInstaller_1.8.15011.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.GetHelp_10.1706.10441.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.Getstarted_6.9.10602.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.Messaging_2018.222.2231.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.MicrosoftOfficeHub_2017.1219.520.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.MicrosoftSolitaireCollection_4.0.1301.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.Office.OneNote_2015.8827.20991.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.OneConnect_4.1801.521.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.People_2018.215.110.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.Print3D_2.0.3621.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.SkypeApp_12.13.274.0_neutral_~_kzf8qxf38zg5c
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.WindowsAlarms_2018.302.1846.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.WindowsCamera_2017.1117.80.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName microsoft.windowscommunicationsapps_2015.8827.22055.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.WindowsFeedbackHub_2018.302.2011.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.WindowsMaps_2018.209.2206.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.WindowsSoundRecorder_2018.302.1842.0_neutral_~_8wekyb3d8bbwe
#Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.WindowsStore_11712.1001.2313.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.XboxApp_38.38.14002.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.XboxGameOverlay_1.26.6001.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.XboxGamingOverlay_1.15.1001.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.XboxIdentityProvider_12.36.15002.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.ZuneMusic_2019.17112.19011.0_neutral_~_8wekyb3d8bbwe
Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.ZuneVideo_2019.17112.19011.0_neutral_~_8wekyb3d8bbwe

write-host "Dismounting image" -foreground Yellow
Dismount-WindowsImage -Path wim -Save

write-host "DONE" -foreground Yellow

### ADDING COMAND PROMPT TO FOLDER ###

##Reg Add "HKLM\WIM_Software\Classes\Directory\shell\cmd2" /ve /d "@shell32.dll,-8506" /f
##Reg Delete "HKLM\WIM_Software\Classes\Directory\shell\cmd2" /v "Extended"
##Reg Add "HKLM\WIM_Software\Classes\Directory\shell\cmd2" /v "Icon" /t REG_SZ /d "imageres.dll,-5323" /f
##Reg Add "HKLM\WIM_Software\Classes\Directory\shell\cmd2" /v "NoWorkingDirectory" /t REG_SZ /d "" /f
##Reg Add "HKLM\WIM_Software\Classes\Directory\shell\cmd2\command" /ve /d "cmd.exe /s /k pushd \"%V\"" /f
##
##Reg Add "HKLM\WIM_Software\Classes\Directory\Background\shell\cmd2" /ve /d "@shell32.dll,-8506" /f
##Reg Delete "HKLM\WIM_Software\Classes\Directory\Background\shell\cmd2" /v "Extended"
##Reg Add "HKLM\WIM_Software\Classes\Directory\Background\shell\cmd2" /v "Icon" /t REG_SZ /d "imageres.dll,-5323" /f
##Reg Add "HKLM\WIM_Software\Classes\Directory\Background\shell\cmd2" /v "NoWorkingDirectory" /t REG_SZ /d "" /f
##Reg Add "HKLM\WIM_Software\Classes\Directory\Background\shell\cmd2\command" /ve /d "cmd.exe /s /k pushd \"%V\"" /f
##
##Reg Add "HKLM\WIM_Software\Classes\Drive\Background\shell\cmd2" /ve /d "@shell32.dll,-8506" /f
##Reg Delete "HKLM\WIM_Software\Classes\Drive\Background\shell\cmd2" /v "Extended"
##Reg Add "HKLM\WIM_Software\Classes\Drive\Background\shell\cmd2" /v "Icon" /t REG_SZ /d "imageres.dll,-5323" /f
##Reg Add "HKLM\WIM_Software\Classes\Drive\Background\shell\cmd2" /v "NoWorkingDirectory" /t REG_SZ /d "" /f
##Reg Add "HKLM\WIM_Software\Classes\Drive\Background\shell\cmd2\command" /ve /d "cmd.exe /s /k pushd \"%V\"" /f
##
##Reg Add "HKLM\WIM_Software\Classes\LibraryFolder\Background\shell\cmd2" /ve /d "@shell32.dll,-8506" /f
##Reg Delete "HKLM\WIM_Software\Classes\LibraryFolder\Background\shell\cmd2" /v "Extended"
##Reg Add "HKLM\WIM_Software\Classes\LibraryFolder\Background\shell\cmd2" /v "Icon" /t REG_SZ /d "imageres.dll,-5323" /f
##Reg Add "HKLM\WIM_Software\Classes\LibraryFolder\Background\shell\cmd2" /v "NoWorkingDirectory" /t REG_SZ /d "" /f
##Reg Add "HKLM\WIM_Software\Classes\LibraryFolder\Background\shell\cmd2\command" /ve /d "cmd.exe /s /k pushd \"%V\"" /f
##
####### BREAKING WINDOWS FEATURES #####
##
##Reg Add "HKLM\WIM_Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\Microsoft-Windows-Cortana-Package~31bf3856ad364e35~amd64~~10.0.16299.15" /v "Visibility" /t REG_DWORD /d 1 /f
##Reg Add "HKLM\WIM_Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\Microsoft-Windows-Cortana-Package~31bf3856ad364e35~amd64~en-US~10.0.16299.15" /v "Visibility" /t REG_DWORD /d 1 /f
##Reg Add "HKLM\WIM_Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\Microsoft-Windows-Cortana-PAL-Desktop-Package~31bf3856ad364e35~amd64~~10.0.16299.15" /v "Visibility" /t REG_DWORD /d 1 /f
##Reg Add "HKLM\WIM_Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\Microsoft-Windows-Cortana-PAL-Desktop-Package~31bf3856ad364e35~amd64~en-US~10.0.16299.15" /v "Visibility" /t REG_DWORD /d 1 /f
##
##Reg Delete "HKLM\WIM_Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\Microsoft-Windows-Cortana-Package~31bf3856ad364e35~amd64~~10.0.16299.15\Owners" /f
##Reg Delete "HKLM\WIM_Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\Microsoft-Windows-Cortana-Package~31bf3856ad364e35~amd64~en-US~10.0.16299.15\Owners" /f
##Reg Delete "HKLM\WIM_Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\Microsoft-Windows-Cortana-PAL-Desktop-Package~31bf3856ad364e35~amd64~~10.0.16299.15\Owners" /f
##Reg Delete "HKLM\WIM_Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\Microsoft-Windows-Cortana-PAL-Desktop-Package~31bf3856ad364e35~amd64~en-US~10.0.16299.15\Owners" /f
##
##Remove-WindowsPackage -Path wim -Packagename:Microsoft-OneCore-ApplicationModel-Sync-Desktop-FOD-Package~31bf3856ad364e35~amd64~~10.0.16299.15
##Remove-WindowsPackage -Path wim -Packagename:Microsoft-Windows-Cortana-Package~31bf3856ad364e35~amd64~en-US~10.0.16299.15
##Remove-WindowsPackage -Path wim -Packagename:Microsoft-Windows-Cortana-Package~31bf3856ad364e35~amd64~~10.0.16299.15
##Remove-WindowsPackage -Path wim -Packagename:Microsoft-Windows-Cortana-PAL-Desktop-Package~31bf3856ad364e35~amd64~en-US~10.0.16299.15
##Remove-WindowsPackage -Path wim -Packagename:Microsoft-Windows-Cortana-PAL-Desktop-Package~31bf3856ad364e35~amd64~~10.0.16299.15
##Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.StorePurchaseApp_11706.1707.7104.0_neutral_~_8wekyb3d8bbwe
##Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.WindowsStore_11706.1002.94.0_neutral_~_8wekyb3d8bbwe
##Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.Wallet_1.0.16328.0_neutral_~_8wekyb3d8bbwe
##Remove-AppxProvisionedPackage -Path wim -PackageName Microsoft.Xbox.TCUI_1.8.24001.0_neutral_~_8wekyb3d8bbwe

##Remove-WindowsImage -ImagePath install.wim -Name "Windows 10 Education" -CheckIntegrity
##Remove-WindowsImage -ImagePath install.wim -Name "Windows 10 Education N" -CheckIntegrity
##Remove-WindowsImage -ImagePath install.wim -Name "Windows 10 Enterprise" -CheckIntegrity
##Remove-WindowsImage -ImagePath install.wim -Name "Windows 10 Enterprise N" -CheckIntegrity
##Remove-WindowsImage -ImagePath install.wim -Name "Windows 10 Pro N" -CheckIntegrity

