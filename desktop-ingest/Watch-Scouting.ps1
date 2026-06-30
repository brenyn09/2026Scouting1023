<#
  Scout1023 USB auto-ingest  ->  master.csv (for Tableau)
  -------------------------------------------------------------------------
  Leave this running on the scouting laptop. Then just plug in scouter USB
  drives one after another. For every drive it:
    1. finds every Scout1023_*.csv on it (any folder),
    2. copies new ones into .\inbox,
    3. merges EVERY row from EVERY file, removes duplicates,
    4. writes one tidy .\master.csv that Tableau reads.

  No internet and no installs needed - this is built-in Windows PowerShell.
  Stop it any time with Ctrl+C.

  Run a single pass instead of looping (for testing):  -Once
#>
param([switch]$Once)

$ErrorActionPreference = 'Stop'
$Root   = Split-Path -Parent $MyInvocation.MyCommand.Path
$Inbox  = Join-Path $Root 'inbox'
$Master = Join-Path $Root 'master.csv'
$IntervalSeconds = 5

# Column order the tablet app exports (keeps master.csv tidy & stable).
$Columns = @('Initials','Match','Team','Alliance','A Fuel Scored','A Fuel Fed',
  'Climb','Pick up location?','T Fuel Scored','T Fuel Fed','Defense','Climb Level',
  'Broke','Permanently Immobilized','Temporarily Immobilized','Was defended',
  'Robot Role','notes','Source File')

New-Item -ItemType Directory -Force -Path $Inbox | Out-Null

# A scouting record = one scouter's view of one robot in one match.
# Re-exports from the same tablet repeat earlier rows; this collapses them.
function Get-Key($row) {
  '{0}|{1}|{2}|{3}' -f $row.Initials, $row.Match, $row.Team, $row.Alliance
}

# Every drive that could be a plugged-in USB: removable (type 2) AND
# "local disk" (type 3 - what many USB sticks/SSDs report as), but NEVER the
# laptop's own system drive, and only drives that actually have media ready.
function Get-CandidateDrives {
  $sys = $env:SystemDrive  # e.g. "C:"
  Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue |
    Where-Object { ($_.DriveType -eq 2 -or $_.DriveType -eq 3) -and
                   $_.DeviceID -ne $sys -and $_.Size -gt 0 }
}

function Update-Master {
  # 1) Pull Scout1023_*.csv off every candidate drive into the inbox.
  foreach ($d in Get-CandidateDrives) {
    $drive = "$($d.DeviceID)\"
    try {
      Get-ChildItem -Path $drive -Filter 'Scout1023_*.csv' -File -Recurse -Depth 6 -ErrorAction SilentlyContinue |
        ForEach-Object {
          $dest = Join-Path $Inbox $_.Name
          if (-not (Test-Path $dest) -or (Get-Item $dest).Length -ne $_.Length) {
            Copy-Item $_.FullName -Destination $dest -Force
            Write-Host ("  + imported {0} from {1}" -f $_.Name, $drive) -ForegroundColor Cyan
          }
        }
    } catch {}
  }

  # 2) Merge + de-duplicate every CSV in the inbox (oldest first, newest wins).
  $byKey = [ordered]@{}
  $files = @(Get-ChildItem -Path $Inbox -Filter '*.csv' -File | Sort-Object LastWriteTime)
  foreach ($f in $files) {
    try {
      Import-Csv $f.FullName | ForEach-Object {
        $_ | Add-Member -NotePropertyName 'Source File' -NotePropertyValue $f.Name -Force
        $byKey[(Get-Key $_)] = $_
      }
    } catch {
      Write-Host ("  ! skipped unreadable file {0}" -f $f.Name) -ForegroundColor Yellow
    }
  }

  # 3) Write master.csv only when the data actually changed. Write IN PLACE
  #    (not Move-Item, which fails if the file is open elsewhere) and retry a
  #    few times in case a reader has it momentarily. If it's truly locked
  #    (e.g. open in Excel) we say so clearly and try again next cycle - the
  #    data is never lost, it just lands as soon as the file is free.
  $rows = @($byKey.Values)
  if ($rows.Count -eq 0) { return 0 }
  $new = ($rows | Select-Object $Columns | ConvertTo-Csv -NoTypeInformation) -join "`r`n"
  # Read the current file to see if anything changed. If it's locked we can't
  # read it either - treat that as "needs writing" so we fall through to the
  # write-retry below (which reports the lock clearly).
  $old = ''
  $readable = $true
  if (Test-Path $Master) {
    try { $old = Get-Content $Master -Raw -ErrorAction Stop } catch { $readable = $false }
  }
  $changed = (-not $readable) -or ($new.TrimEnd() -ne $old.TrimEnd())
  if ($changed) {
    $utf8 = [System.Text.UTF8Encoding]::new($false)  # no BOM (clean for Tableau)
    $written = $false
    for ($i = 1; $i -le 10; $i++) {
      try {
        [System.IO.File]::WriteAllText($Master, $new, $utf8)
        $written = $true
        break
      } catch {
        Start-Sleep -Milliseconds 300
      }
    }
    if ($written) {
      Write-Host ("  = master.csv updated: {0} records from {1} source files" -f $rows.Count, $files.Count) -ForegroundColor Green
    } else {
      Write-Host ("  ! master.csv is OPEN in another program - close it in Excel/Notepad (Tableau is fine). {0} records are ready and will be written as soon as the file is free." -f $rows.Count) -ForegroundColor Yellow
    }
  }
  return $rows.Count
}

Write-Host '==================================================================='
Write-Host ' Scout1023 USB watcher'
Write-Host ("   inbox : {0}" -f $Inbox)
Write-Host ("   master: {0}" -f $Master)
Write-Host '   Plug in scouter USB drives. Point Tableau at master.csv.'
Write-Host '   Press Ctrl+C to stop.'
Write-Host '==================================================================='

if ($Once) {
  $n = Update-Master
  Write-Host ("Single pass complete. {0} records in master." -f $n)
  return
}

while ($true) {
  try { Update-Master | Out-Null }
  catch { Write-Host ("WARN: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
  Start-Sleep -Seconds $IntervalSeconds
}
