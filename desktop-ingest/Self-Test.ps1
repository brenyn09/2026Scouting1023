<#
  Scout1023 watcher SELF-TEST.
  Seeds two FAKE scouter exports (with a deliberate duplicate match), runs one
  real merge pass, and shows the resulting master.csv so you can confirm the
  whole pipeline works on this laptop WITHOUT needing a real USB.

  These are sample rows (initials TEST / DEMO). Before a real event, delete the
  "inbox" folder and "master.csv" in this folder to start clean.
#>
$ErrorActionPreference = 'Stop'
$Root  = Split-Path -Parent $MyInvocation.MyCommand.Path
$Inbox = Join-Path $Root 'inbox'
New-Item -ItemType Directory -Force -Path $Inbox | Out-Null

$h = 'Initials,Match,Team,Alliance,A Fuel Scored,A Fuel Fed,Climb,Pick up location?,T Fuel Scored,T Fuel Fed,Defense,Climb Level,Broke,Permanently Immobilized,Temporarily Immobilized,Was defended,Robot Role,notes'

# Tablet 1, first export
"$h`nTEST,1,1023,Blue2,5,2,1,Depot,10,3,0,20,0,0,0,1,Scorer,SAMPLE-first" |
  Set-Content "$Inbox\Scout1023_Blue2_m1_SELFTEST.csv" -Encoding UTF8
Start-Sleep -Milliseconds 1100
# Tablet 1, second export: repeats match 1 (corrected) + adds another robot
"$h`nTEST,1,1023,Blue2,9,2,1,Depot,10,3,0,20,0,0,0,1,Scorer,SAMPLE-corrected`nDEMO,2,858,Red1,3,1,0,Depot,7,0,0,0,0,0,0,0,Feeder,SAMPLE" |
  Set-Content "$Inbox\Scout1023_Blue2_m2_SELFTEST.csv" -Encoding UTF8

Write-Host "Seeded 2 sample exports (match 1 appears twice to prove de-dup)...`n" -ForegroundColor Cyan
& (Join-Path $Root 'Watch-Scouting.ps1') -Once

$master = Join-Path $Root 'master.csv'
Write-Host "`n----------------------- master.csv -----------------------" -ForegroundColor Magenta
if (Test-Path $master) {
  $rows = @(Import-Csv $master)
  # Verify THIS test's own rows, regardless of any real data also present.
  $t1   = $rows | Where-Object { $_.Initials -eq 'TEST' -and $_.Match -eq '1' }
  $demo = $rows | Where-Object { $_.Initials -eq 'DEMO' }
  ($rows | Where-Object { $_.Initials -in @('TEST','DEMO') } |
    Format-Table Initials,Match,Team,Alliance,'A Fuel Scored',notes -AutoSize | Out-String) | Write-Host
  if ($t1 -and $t1.'A Fuel Scored' -eq '9' -and $demo) {
    Write-Host "PASS: de-dup works - the duplicated test match kept the NEWEST value (9, not 5)." -ForegroundColor Green
    Write-Host ("PASS: master.csv has {0} total records (test rows + any real data) at:`n  {1}" -f $rows.Count, $master) -ForegroundColor Green
    if ($rows.Count -gt 2) {
      Write-Host ("NOTE: {0} of those are REAL files the watcher pulled off a plugged-in USB - the pipeline works end to end." -f ($rows.Count - 2)) -ForegroundColor Cyan
    }
  } else {
    Write-Host "UNEXPECTED: the test rows didn't merge as expected - send Claude this output." -ForegroundColor Red
  }
} else {
  Write-Host "FAIL: no master.csv was produced." -ForegroundColor Red
}
Write-Host "`nNOTE: these are TEST rows. Before a real event, delete the 'inbox'" -ForegroundColor Yellow
Write-Host "folder and 'master.csv' in this folder to start clean." -ForegroundColor Yellow
