
<# 
.NAME
    Detour
#>

Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'

If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
}

if ($MyInvocation.InvocationName -eq '&') { 
    [Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 0)
}


Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$window                          = New-Object system.Windows.Forms.Form
$window.ClientSize               = New-Object System.Drawing.Point(500,250)
$window.text                     = "Detour"
$window.TopMost                  = $false

$BackupRestoreButton             = New-Object system.Windows.Forms.Button
$BackupRestoreButton.text        = "Backup Registry && Settings"
$BackupRestoreButton.width       = 225
$BackupRestoreButton.height      = 30
$BackupRestoreButton.location    = New-Object System.Drawing.Point(9,11)
$BackupRestoreButton.Font        = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$AutoconfigButton                = New-Object system.Windows.Forms.Button
$AutoconfigButton.text           = "Autoconfig Registry && Settings"
$AutoconfigButton.width          = 235
$AutoconfigButton.height         = 30
$AutoconfigButton.location       = New-Object System.Drawing.Point(257,11)
$AutoconfigButton.Font           = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$ConnectionButton                = New-Object system.Windows.Forms.Button
$ConnectionButton.text           = "Turn On"
$ConnectionButton.width          = 80
$ConnectionButton.height         = 30
$ConnectionButton.location       = New-Object System.Drawing.Point(210,200)
$ConnectionButton.Font           = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$DownlinkListBox                 = New-Object system.Windows.Forms.ListBox
$DownlinkListBox.text            = "listBox"
$DownlinkListBox.width           = 146
$DownlinkListBox.height          = 137
$DownlinkListBox.location        = New-Object System.Drawing.Point(9,88)

$UplinkListBox                   = New-Object system.Windows.Forms.ListBox
$UplinkListBox.text              = "listBox"
$UplinkListBox.width             = 146
$UplinkListBox.height            = 137
$UplinkListBox.location          = New-Object System.Drawing.Point(346,88)

$window.controls.AddRange(@($BackupRestoreButton,$AutoconfigButton,$ConnectionButton,$DownlinkListBox,$UplinkListBox))

$DownlinksLabel                  = New-Object system.Windows.Forms.Label
$DownlinksLabel.text             = "Downlinks"
$DownlinksLabel.AutoSize         = $true
$DownlinksLabel.width            = 25
$DownlinksLabel.height           = 10
$DownlinksLabel.location         = New-Object System.Drawing.Point(47,70)
$DownlinksLabel.Font             = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$UplinksLabel                    = New-Object system.Windows.Forms.Label
$UplinksLabel.text               = "Uplinks"
$UplinksLabel.AutoSize           = $true
$UplinksLabel.width              = 25
$UplinksLabel.height             = 10
$UplinksLabel.location           = New-Object System.Drawing.Point(390,70)
$UplinksLabel.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$UptimeLabel                      = New-Object system.Windows.Forms.Label
$UptimeLabel.Text                 = 'Uptime: ' + "00:00:00"
$UptimeLabel.AutoSize             = $false
$UptimeLabel.width                = 165
$UptimeLabel.height               = 20
$UptimeLabel.location             = New-Object System.Drawing.Point(161,85)
$UptimeLabel.Font                 = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$DownlinkInfoLabel                = New-Object system.Windows.Forms.Label
$DownlinkInfoLabel.Text           = "Downlink Info`r`n" + 'IP: ' + "0.0.0.0/0`r`n"
$DownlinkInfoLabel.AutoSize       = $false
$DownlinkInfoLabel.width          = 165
$DownlinkInfoLabel.height         = 100
$DownlinkInfoLabel.location       = New-Object System.Drawing.Point(161,130)
$DownlinkInfoLabel.Font           = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$window.controls.AddRange(@($DownlinksLabel,$UplinksLabel,$UptimeLabel,$DownlinkInfoLabel))

$ConnectionButton.Add_Click({ ConnectionButtonHandler })
$BackupRestoreButton.Add_Click({ BackupRestoreButtonHandler })
$AutoconfigButton.Add_Click({ AutoconfigButtonHandler })
$DownlinkListBox.Add_SelectedValueChanged({ SelectDownlink })
$UplinkListBox.Add_SelectedValueChanged({ SelectUplink })

#region Logic 
function ConnectionButtonHandler { 
    if ($state.running -eq $false) {
        Connect
        $state.running = $true
    }
    else {
        Disconnect
        $state.running = $false
    }
    UpdateWindow
}
function AutoconfigButtonHandler {
    Autoconfig
}
function BackupRestoreButtonHandler { 
    if ($state.computer_settings -eq 'restored') {
        BackupComputerSettings
        $state.computer_settings = 'backedup'
    } else {
        RestoreComputerSettings
        $state.computer_settings = 'restored'
    }
    UpdateWindow
}
function SelectDownlink {
    $state.downlink = (Get-NetAdapter -name $DownlinkListBox.SelectedItem).ifIndex
    UpdateWindow
}
function SelectUplink { 
    $state.uplink = (Get-NetAdapter -name $UplinkListBox.SelectedItem).ifIndex
    UpdateWindow
}
function UpdateWindow {
    if ($state.running -eq $false) {
        $ConnectionButton.Text = 'Turn On'
        $UplinkListBox.Enabled = $true
        $DownlinkListBox.Enabled = $true
        $BackupRestoreButton.Enabled = $true
    }
    if ($state.running -eq $true) {
        $ConnectionButton.Text = 'Turn Off'
        $UplinkListBox.Enabled = $false
        $DownlinkListBox.Enabled = $false
        $BackupRestoreButton.Enabled = $false
    }
    if ($state.computer_settings -eq 'restored') {
        $BackupRestoreButton.Text = 'Backup Registry && Settings'
    }
    if ($state.computer_settings -eq 'backedup') {
        $BackupRestoreButton.Text = 'Restore Registry && Settings'
    }
    if ($state.uplink -eq $false -or $state.downlink -eq $false) {
        $ConnectionButton.Enabled = $false
    } else {
        $ConnectionButton.Enabled = $true
    }
}

#maintain state
#   running or not running
#   uplink and downlink selection

$state = [PSCustomObject]@{
    running = $false
    computer_settings = 'restored'
    uplink = $false
    downlink = $false
    uptime = 0
}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    $state.uptime += 1
    $UptimeLabel.Text = 'Uptime: ' + ("{0:hh\:mm\:ss}`r`n`r`n" -f [timespan]::FromSeconds($state.uptime))
})

Get-NetAdapter | ForEach-Object {
    $UplinkListBox.Items.Add($_.Name)
    $DownlinkListBox.Items.Add($_.Name)
}

# Register the HNetCfg library (once)
regsvr32 /s hnetcfg.dll

# Create a NetSharingManager object
$m = New-Object -ComObject HNetCfg.HNetShare

if ((Test-Path './restore.json') -eq $true) {
    $state.computer_settings = 'backedup'
}

function Connect {
    # List connections
    $m.EnumEveryConnection | ForEach-Object { $m.NetConnectionProps.Invoke($_) }

    # Find Uplink
    $c = $m.EnumEveryConnection | Where-Object { $m.NetConnectionProps.Invoke($_).Name -eq $UplinkListBox.SelectedItem }

    # Get sharing configuration
    $config = $m.INetSharingConfigurationForINetConnection.Invoke($c)

    # 0 - public, 1 - private
    # Enable sharing (0 - public, 1 - private)
    $config.EnableSharing(0)

    # Find Downlink
    $c = $m.EnumEveryConnection | Where-Object { $m.NetConnectionProps.Invoke($_).Name -eq $DownlinkListBox.SelectedItem }

    # Get sharing configuration
    $config = $m.INetSharingConfigurationForINetConnection.Invoke($c)

    # 0 - public, 1 - private
    # Enable sharing (0 - public, 1 - private)
    $config.EnableSharing(1)

    $timer.Start()
    $DownlinkInfoLabel.Text = "Downlink Info`r`n" + 'IP: ' + (Get-NetIPConfiguration -InterfaceIndex $state.downlink).IPv4Address + '/' + (Get-NetIPConfiguration -InterfaceIndex $state.downlink).IPv4Address.PrefixLength

    Write-Host 'Connected!'
}
function Disconnect {
    # List connections
    $m.EnumEveryConnection | ForEach-Object { $m.NetConnectionProps.Invoke($_) }

    # Find Uplink
    $c = $m.EnumEveryConnection | Where-Object { $m.NetConnectionProps.Invoke($_).Name -eq $UplinkListBox.SelectedItem }

    # Get sharing configuration
    $config = $m.INetSharingConfigurationForINetConnection.Invoke($c)

    $config.DisableSharing()

    # Find Downlink
    $c = $m.EnumEveryConnection | Where-Object { $m.NetConnectionProps.Invoke($_).Name -eq $DownlinkListBox.SelectedItem }

    # Get sharing configuration
    $config = $m.INetSharingConfigurationForINetConnection.Invoke($c)

    $config.DisableSharing()

    $timer.Stop()
    $state.uptime = 0

    Write-Host 'Disconnected!'
}
function Autoconfig {
    function CreateOrChangeReg {
        param($path, $name, $value, $property_type)

        if(-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        New-ItemProperty -Path $path -Name $name -Value $value -PropertyType $property_type -Force
    }

    CreateOrChangeReg -Path 'HKLM:\Software\Policies\Microsoft\Windows\Network Connections' -Name 'NC_ShowSharedAccessUI' -Value 1 -PropertyType DWORD
    CreateOrChangeReg -Path 'HKLM:\Software\Policies\Microsoft\Windows\Network Connections' -Name 'NC_PersonalFirewallConfig' -Value 1 -PropertyType DWORD

    #set ICS to start automatically
    Set-Service -name 'SharedAccess' -StartupType Automatic
    Start-Service -name 'Internet Connection Sharing (ICS)'

    #set ICS dependancies to start automatically
    $ICS_dependencies = @(
        'PlugPlay',
        'ALG',
        'Netman',
        'NlaSvc',
        'TapiSrv',
        'RasMan'
    )
    Foreach ($service_name in $ICS_dependencies) {
        Set-Service -name $service_name -StartupType Automatic
        Start-Service -name $service_name
    }
    Write-Host 'Computer Settings Autoconfigured!'
}
function BackupComputerSettings {
    #save all interfaces
    $reg_and_settings = @{
        'interfaces' = @()
        'registry' = @()
        'services' = @()
    }

    Get-NetAdapter | ForEach-Object {
        $index = $_.InterfaceIndex
        $guid = $_.InterfaceGUID

        $net_conf = Get-NetIPConfiguration -InterfaceIndex $index
        $dhcp = $net_conf.NetIPv4Interface.DHCP
        $ip = $net_conf.IPv4Address.IPAddress
        $mask = $net_conf.IPv4Address.PrefixLength
        $gateway = $net_conf.IPv4DefaultGateway.NextHop
        $dns_servers = ($net_conf.DNSServer | Where-Object AddressFamily -eq 2).ServerAddresses

        $reg_and_settings.interfaces += @{
            'guid' = $guid
            'dhcp' = $dhcp 
            'ip' = $ip 
            'mask' = $mask 
            'gateway' = $gateway 
            'dns_servers' = $dns_servers 
        }
    }

    @(
        @{
            'path' = 'HKLM:\Software\Policies\Microsoft\Windows\Network Connections'
            'name' = 'NC_ShowSharedAccessUI'
        },
        @{
            'path' = 'HKLM:\Software\Policies\Microsoft\Windows\Network Connections'
            'name' = 'NC_PersonalFirewallConfig'
        }

    ) | ForEach-Object {
        $exists = $null -ne (Get-Item -Path $_.path).GetValue($_.name)
        if ($exists -eq $true) {
            $value = Get-ItemPropertyValue -Path $_.path -Name $_.name
        } else {
            $value = $null
        }

        $reg_and_settings.registry += @{
            'name' = $_.name
            'path' = $_.path
            'exists' = $exists
            'value' = $value
        }
    }

    @(
        'PlugPlay',
        'ALG',
        'Netman',
        'NlaSvc',
        'TapiSrv',
        'RasMan'
    ) | ForEach-Object {
        $service = Get-Service -Name $_
        
        $reg_and_settings.services += @{
            'name' = $_
            'start_type' = $service.StartType
        }
    }

    $reg_and_settings.services += @{
        'name' = 'SharedAccess'
        'start_type' = (Get-Service -Name 'Internet Connection Sharing (ICS)').StartType
    }


    $reg_and_settings | ConvertTo-Json | Out-File './restore.json'
    Write-Host 'Computer Settings Backed Up!'
}
function RestoreComputerSettings {
    #restore
    $reg_and_settings = (Get-Content './restore.json' | Out-String | ConvertFrom-Json)

    #restore registry
    $reg_and_settings.registry | ForEach-Object {
        if ($_.exists -eq $false) {
            Remove-ItemProperty -Path $_.path -Name $_.name
        } else {
            Set-ItemProperty -Path $_.path -Name $_.name -Value $_.value
        }
    }

    $reg_and_settings.interfaces | ForEach-Object {
        $index = (Get-NetAdapter | Where-Object InterfaceGuid -eq $_.guid).ifIndex

        Set-NetIPAddress -InterfaceIndex $index -IPAddress $_.ip -PrefixLength $_.mask
        Set-DnsClientServerAddress -InterfaceIndex $index -ServerAddresses $_.dns_servers.Split(' ')
        if ($_.dhcp -eq 1) {
            Set-NetIPAddress -InterfaceIndex $index -PrefixOrigin Dhcp -SuffixOrigin Dhcp
        }
    }

    $reg_and_settings.services | ForEach-Object {
        Set-Service -Name $_.name -StartupType $_.start_type
    }
    Remove-Item './restore.json'
    Write-Host 'Computer Settings Restored!'
}

UpdateWindow
#grey out link selection if state is running
#endregion

[void]$window.ShowDialog()
$timer.Stop()
$timer.Dispose()