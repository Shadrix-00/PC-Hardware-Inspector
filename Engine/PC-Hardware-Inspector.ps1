param([string]$OutDir)
$ErrorActionPreference = 'SilentlyContinue'
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }
$root = Split-Path -Parent $scriptDir

$out = New-Object System.Collections.Generic.List[string]
$width = 60

function Add-Line($t = '') { $script:out.Add([string]$t) }
function Add-Section($t) {
    Add-Line ''
    Add-Line ('[ ' + $t + ' ]')
    Add-Line ('-' * $script:width)
}
function Add-Field($label, $value) {
    if ($null -ne $value -and "$value" -ne '') { Add-Line ('  {0,-14}: {1}' -f $label, $value) }
}
function Fmt-GB($b) { [math]::Round($b / 1GB, 2) }
function Fmt-Date($d) { if ($d) { $d.ToString('yyyy-MM-dd') } }
function Clean($s) { if ($s) { ($s -replace '\s+', ' ').Trim() } }

$memTypes = @{ 20 = 'DDR'; 21 = 'DDR2'; 24 = 'DDR3'; 26 = 'DDR4'; 34 = 'DDR5'; 35 = 'LPDDR5' }

$cs   = Get-CimInstance Win32_ComputerSystem
$os   = Get-CimInstance Win32_OperatingSystem
$bb   = Get-CimInstance Win32_BaseBoard
$bios = Get-CimInstance Win32_BIOS
$cpus = @(Get-CimInstance Win32_Processor)
$ram  = @(Get-CimInstance Win32_PhysicalMemory)
$gpus = @(Get-CimInstance Win32_VideoController)

Add-Line ('=' * $width)
Add-Line '  PC HARDWARE REPORT'
Add-Line ('  Generated: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Add-Line ('=' * $width)

Add-Section 'SYSTEM'
Add-Field 'Manufacturer' $cs.Manufacturer
Add-Field 'Model' $cs.Model
Add-Field 'Type' $cs.SystemType
Add-Field 'Motherboard' ((Clean $bb.Manufacturer) + ' ' + (Clean $bb.Product))
Add-Field 'BIOS' ((Clean $bios.Manufacturer) + ' ' + (Clean $bios.SMBIOSBIOSVersion) + ' (' + (Fmt-Date $bios.ReleaseDate) + ')')

Add-Section 'OPERATING SYSTEM'
Add-Field 'OS' $os.Caption
Add-Field 'Version' ($os.Version + ' (Build ' + $os.BuildNumber + ')')
Add-Field 'Architecture' $os.OSArchitecture
Add-Field 'Installed' (Fmt-Date $os.InstallDate)
$up = (Get-Date) - $os.LastBootUpTime
Add-Field 'Uptime' ('{0}d {1}h {2}m' -f $up.Days, $up.Hours, $up.Minutes)

Add-Section 'CPU'
$ci = 1
foreach ($c in $cpus) {
    if ($cpus.Count -gt 1) { Add-Line ('  CPU ' + $ci) }
    Add-Field 'Name' (Clean $c.Name)
    Add-Field 'Manufacturer' $c.Manufacturer
    Add-Field 'Cores' $c.NumberOfCores
    Add-Field 'Threads' $c.NumberOfLogicalProcessors
    Add-Field 'Base Clock' ($c.MaxClockSpeed.ToString() + ' MHz')
    Add-Field 'L2 Cache' ($c.L2CacheSize.ToString() + ' KB')
    Add-Field 'L3 Cache' ($c.L3CacheSize.ToString() + ' KB')
    Add-Field 'Socket' $c.SocketDesignation
    $ci++
}

Add-Section 'RAM'
Add-Field 'Total' ((Fmt-GB $cs.TotalPhysicalMemory).ToString() + ' GB')
Add-Field 'Available' (([math]::Round($os.FreePhysicalMemory / 1MB, 2)).ToString() + ' GB')
Add-Field 'Slots Used' $ram.Count
$i = 1
foreach ($m in $ram) {
    $type = $memTypes[[int]$m.SMBIOSMemoryType]
    if (-not $type) { $type = 'Unknown' }
    $speed = $m.ConfiguredClockSpeed
    if (-not $speed) { $speed = $m.Speed }
    $desc = '{0} GB {1} @ {2} MHz' -f (Fmt-GB $m.Capacity), $type, $speed
    $extra = (@((Clean $m.Manufacturer), (Clean $m.PartNumber)) | Where-Object { $_ }) -join ' '
    if ($extra) { $desc += ' (' + $extra + ')' }
    Add-Field ('Module ' + $i) $desc
    $i++
}

Add-Section 'GPU'
$classKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11cd-bfc1-08002be10318}'
$regGpus = @(Get-ChildItem $classKey | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { Get-ItemProperty $_.PSPath })
$gi = 1
foreach ($g in $gpus) {
    $vram = $null
    $match = $regGpus | Where-Object { $_.DriverDesc -eq $g.Name -and $_.'HardwareInformation.qwMemorySize' } | Select-Object -First 1
    if ($match) {
        $vram = (Fmt-GB ([int64]$match.'HardwareInformation.qwMemorySize')).ToString() + ' GB'
    } elseif ($g.AdapterRAM -and $g.AdapterRAM -ge 4293000000) {
        $vram = '4 GB or more'
    } elseif ($g.AdapterRAM) {
        $vram = (Fmt-GB $g.AdapterRAM).ToString() + ' GB'
    } else {
        $vram = 'Shared with system RAM'
    }
    if ($gpus.Count -gt 1) { Add-Line ('  GPU ' + $gi) }
    Add-Field 'Name' $g.Name
    Add-Field 'VRAM' $vram
    Add-Field 'Driver' $g.DriverVersion
    Add-Field 'Driver Date' (Fmt-Date $g.DriverDate)
    if ($g.CurrentHorizontalResolution) {
        Add-Field 'Resolution' ('{0}x{1} @ {2} Hz' -f $g.CurrentHorizontalResolution, $g.CurrentVerticalResolution, $g.CurrentRefreshRate)
    }
    $gi++
}

Add-Section 'STORAGE'
$di = 1
foreach ($d in @(Get-PhysicalDisk)) {
    Add-Field ('Drive ' + $di) ('{0} | {1} | {2} | {3} GB | {4}' -f (Clean $d.FriendlyName), $d.MediaType, $d.BusType, [math]::Round($d.Size / 1GB), $d.HealthStatus)
    $di++
}
foreach ($v in @(Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 })) {
    Add-Field ('Volume ' + $v.DeviceID) ('{0} GB total, {1} GB free ({2})' -f (Fmt-GB $v.Size), (Fmt-GB $v.FreeSpace), $v.FileSystem)
}

Add-Section 'DISPLAYS'
$mi = 1
foreach ($mon in @(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID)) {
    $name = ($mon.UserFriendlyName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ }) -join ''
    $mfr  = ($mon.ManufacturerName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ }) -join ''
    if (-not $name) { $name = 'Unknown' }
    Add-Field ('Monitor ' + $mi) ((Clean ($mfr + ' ' + $name)))
    $mi++
}

Add-Section 'NETWORK'
$ni = 1
foreach ($n in @(Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true -and $_.NetEnabled -eq $true })) {
    $spd = ''
    if ($n.Speed) { $spd = ' @ ' + [math]::Round($n.Speed / 1MB) + ' Mbps' }
    Add-Field ('Adapter ' + $ni) ($n.Name + $spd)
    $ni++
}

Add-Section 'AUDIO'
$ai = 1
foreach ($a in @(Get-CimInstance Win32_SoundDevice)) {
    Add-Field ('Device ' + $ai) $a.Name
    $ai++
}

$bat = @(Get-CimInstance Win32_Battery)
if ($bat.Count -gt 0) {
    Add-Section 'BATTERY'
    foreach ($b in $bat) {
        Add-Field 'Name' $b.Name
        Add-Field 'Charge' ($b.EstimatedChargeRemaining.ToString() + ' %')
    }
}

Add-Line ''
Add-Line ('=' * $width)

$report = $out -join [Environment]::NewLine
Write-Host $report

$exports = $OutDir
if (-not $exports) { $exports = Join-Path $root 'Exports' }
if (-not (Test-Path $exports)) { New-Item -ItemType Directory -Path $exports -Force | Out-Null }
$file = Join-Path $exports ('PC-Hardware-Report_' + (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss') + '.txt')
try {
    $report | Out-File -FilePath $file -Encoding UTF8 -ErrorAction Stop
} catch {
    $file = Join-Path $env:TEMP 'PC-Hardware-Report.txt'
    $report | Out-File -FilePath $file -Encoding UTF8
}
$report | Set-Clipboard

Write-Host ''
Write-Host 'Report copied to clipboard - just paste it (Ctrl+V).'
Write-Host ('Also saved to: ' + $file)
