Add-Type -AssemblyName PresentationFramework

# Import the xaml file.

$xamlFile="C:\Git\Windows-Troubleshooting-App\App\MainWindow.xaml"
$inputXAML=Get-Content -Path $xamlFile -Raw
$inputXAML=$inputXAML -replace 'mc:Ignorable="d"','' -replace "x:N","N" -replace '^<Win.*','<Window'
[XML]$XAML=$inputXAML

# Load the Xaml File into the psform variable.
$reader = New-Object System.Xml.XmlNodeReader $XAML
try{
    $psform=[Windows.Markup.XamlReader]::Load($reader)
}catch{
    Write-Host $_.Exception
    throw
}

# Test the form loads properly, $psform.ShowDialog()

# Create the variables based on the objects that have names.
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    try{
        Set-Variable -Name "var_$($_.Name)" -Value $psform.FindName($_.Name) -ErrorAction Stop
    }catch{
        throw
    }
}

# Test the variables have imported correctly, Get-Variable var_*

# Logic

$var_txtStatus.Text = "Click Collect to begin."                                     # Set status text box text on tab 1.
$var_txtEventDisclaimer.Text = "Allow up to a minute to run, the app will freeze."  # Set disclaimer text to warn of freezing on tab 2.

# System info tab functions.
function CollectsystemInformation {
    <# 
        Function to collect the system info and passes it to the relevant text boxes.
    #>

    $var_txtStatus.Text = ""
    
    Start-Sleep 2
    $sysinfo = Get-ComputerInfo

    $var_txtHostname.Text = $sysinfo | Select-Object -ExpandProperty csCaption
    $var_txtOsName.Text = $sysinfo | Select-Object -ExpandProperty OsName
    $var_txtOsVersion.Text = $sysinfo | Select-Object -ExpandProperty OSDisplayVersion
    $var_txtOsInstallDate.Text = $sysinfo | Select-Object -ExpandProperty WindowsInstallDateFromRegistry
    $var_txtManufacturer.Text = $sysinfo | Select-Object -ExpandProperty CsManufacturer
    $var_txtModel.Text = $sysinfo | Select-Object -ExpandProperty CsModel
    $var_txtTimeZone.Text = $sysinfo | Select-Object -ExpandProperty TimeZone
    $var_txtMaxMem.Text = $sysinfo | Select-Object -ExpandProperty OsTotalVisibleMemorySize
    $var_txtAvailMem.Text = $sysinfo | Select-Object -ExpandProperty OsFreePhysicalMemory
     
    $var_txtStatus.Text = "Completed"
}

function ExportsystemInformation {
    <# 
        Function exports the system information values from the text boxes into a text file.
    #>

    $sysinfoExport = "C:\Temp\SysteminfoExport.txt"
    try {
        New-Item -Path $sysinfoExport -Force -ErrorAction Stop    
    }
    catch {
        throw
    }

    try {
        Add-Content -path $sysinfoExport -Value "Hostname: $($var_txtHostname.Text) " -ErrorAction Stop
        Add-Content -path $sysinfoExport -Value "Os Name: $($var_txtOsName.Text)" -ErrorAction Stop
        Add-Content -path $sysinfoExport -Value "OS Version: $($var_txtOsVersion.Text)" -ErrorAction Stop
        Add-Content -path $sysinfoExport -Value "OS Install Date: $($var_txtOsInstallDate.Text)" -ErrorAction Stop
        Add-Content -path $sysinfoExport -Value "Manufacturer: $($var_txtManufacturer.Text)" -ErrorAction Stop
        Add-Content -path $sysinfoExport -Value "Model: $($var_txtModel.Text)" -ErrorAction Stop
        Add-Content -path $sysinfoExport -Value "Timezone: $($var_txtTimeZone.Text)" -ErrorAction Stop
        Add-Content -path $sysinfoExport -Value "Total Memory: $($var_txtMaxMem.Text)" -ErrorAction Stop
        Add-Content -path $sysinfoExport -Value "Available Memory: $($var_txtAvailMem.Text)" -ErrorAction Stop
    }
    catch {
        $_.Exception
        Throw
    }
    
    $var_txtStatus.Text = "Export Completed"
}

# Events tab functions.
function GetSystemEvents {

    <#
        Function to collect system event logs for the past 2hrs.
    #>

    $sysEventTime = (Get-Date).AddHours(-2)
    $sysEventColumns = @(
        'TimeGenerated'
        'EntryType'
        'Source'
        'Message'
    )
    $sysEventsTable = New-Object System.Data.DataTable
    [void]$sysEventsTable.Columns.AddRange($sysEventColumns)
    $sysEvents = Get-EventLog -LogName System -After $sysEventTime | Select-Object $sysEventColumns
    
    foreach ($Event in $sysEvents){
        $sysEntry=@()
        foreach($column in $sysEventColumns){
            $sysEntry += $Event.$column
        }
        [void]$sysEventsTable.Rows.Add($sysEntry)
    }
    $var_dtgEvents.ItemsSource = $sysEventsTable.DefaultView
    # $sysEventsTable.Rows.Clear()
}

function ExportSystemEvents {
    $sysEventsTable | Export-Csv -Path C:\Temp\SysEventsExports.csv -NoTypeInformation -Force
    explorer.exe C:\Temp
    
}

function GetAppEvents {
    <#
        Function to collect system event logs for the past 2hrs.
    #>

    $appEventTime = (Get-Date).AddHours(-2)
    $appEventsColumns = @(
        'TimeGenerated'
        'EntryType'
        'Source'
        'Message'
    )
    $appEventsTable = New-Object System.Data.DataTable
    [void]$appEventsTable.Columns.AddRange($appEventsColumns)
    $appEvents = Get-EventLog -LogName Application -After $appEventTime | Select-Object $appEventColumns
    
    foreach ($Event in $appEvents){
        $appEntry=@()
        foreach($column in $appEventsColumns){
            $appEntry += $Event.$column
        }
        [void]$appEventsTable.Rows.Add($appEntry)
    }
    $var_dtgEvents.ItemsSource = $appEventsTable.DefaultView
    # $sysEventsTable.Rows.Clear()
}

function ExportAppEvents {
    $appEventsTable | Export-Csv -Path C:\Temp\AppEventsExports.csv -NoTypeInformation -Force
    explorer.exe C:\Temp
}
# Network tab functions.

function NetworkPingtest {

    $networkPingColumns = @(
        'TimeStamp'
        'SourceAddress'
        'DestinationAddress'
        'ResponseTime'
    )
    $pingtestResult = Test-Connection $var_txtPingTest.Text -count 10 | Select-Object @{n='TimeStamp';e={Get-Date}}, @{l='SourceAddress';e={$_.__Server}},@{l='DestinationAddress';e={$_.Address}}, ResponseTime

    $pingEventsTable = New-Object System.Data.DataTable
    [void]$pingEventsTable.Columns.AddRange($networkPingColumns)
    
    foreach ($Event in $pingtestResult){
        $pingEntry=@()
        foreach($column in $networkPingColumns){
            $pingEntry += $Event.$column
        }
        [void]$pingEventsTable.Rows.Add($pingEntry)
    }
    $var_dtgNetwork.ItemsSource = $pingEventsTable.DefaultView
    # Left here for testing purposes, this clears the table $pingEventsTable.Rows.Clear()
}

function NetworkDNSLookup {
    
    $networkLookupColumns = @(
        'Name'
        'Type'
        'TTL'
        'Section'
        'NameHost'
    )

    $LookuptestResult = Resolve-DnsName -Name $var_txtNsLookup.Text
    $lookupEventsTable = New-Object System.Data.DataTable
    [void]$lookupEventsTable.Columns.AddRange($networkLookupColumns)
    
    foreach ($Event in $LookuptestResult){
        $lookupEntry=@()
        foreach($column in $networkLookupColumns){
            $lookupEntry += $Event.$column
        }
        [void]$lookupEventsTable.Rows.Add($lookupEntry)
    }
    $var_dtgNetwork.ItemsSource = $lookupEventsTable.DefaultView
    # Left here for testing purposes, this clears the table $pingEventsTable.Rows.Clear()
}

function NetworkIPConfig {
    $netIPConfig = Get-NetIPConfiguration -All | Select-Object -ExpandProperty NetAdapter | Select-Object name,interfacedescription,status,macaddress,linkspeed
    $netIPAddresses = Get-NetIPAddress | Select-Object InterfaceAlias, IPAddress| Sort-Object interfacealias

    $netIPConfig | Select-Object *, @{ l='itemName';e={$netIPAddresses | Where-Object  InterfaceAlias -Match $_.Name | Select-Object -ExpandProperty IPAddress}} -ExcludeProperty InterfaceAlias



}

$var_btnGetSysinfo.Add_Click({CollectsystemInformation})    # This adds the function to the click of the button btnhellow.
$var_btnExportInfo.Add_Click({ExportsystemInformation})     # Exports data collected to C:\Temp to the click of the button btnExportInfo.
$var_btnGetSysEvntLogs.Add_Click({GetSystemEvents})         # Gets the last 2hrs worth of system Events to the click of the button btnGetSysEvntLogs.
$var_btnGetAppEvntLogs.Add_Click({GetAppEvents})            # Gets the last 2hrs worth of application events to the click of the button btnGetAppEvntLogs.
$var_btnExportSysEvntLogs.Add_Click({ExportSystemEvents})   # Gets the system events and exports to C:\Temp to the click of th button btnExportSysEvntLogs.
$var_btnExportAppEvntLogs.Add_Click({ExportAppEvents})      # Gets the app events and exports to C:\Temp to the click of th button btnExportAppEvntLogs.
$var_btnGetPing.Add_Click({NetworkPingtest})                # Intiates the ping function and prints to the output Grid Object.
$var_btnGetNsLookup.Add_Click({NetworkDNSLookup})           # Initiates the resolve dns function and prints to the output Grid Object.


$psform.ShowDialog()                                        # Create window, put all forms, buttons etc before this line.
