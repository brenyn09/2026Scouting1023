<#
  Scout1023 TBA live ripper  ->  tba_*.csv (for Tableau)
  -------------------------------------------------------------------------
  Leave this running on the scouting laptop (needs internet). Every minute
  it pulls the WHOLE event from The Blue Alliance and writes four CSVs next
  to master.csv, so Tableau can blend official data with our scouting:

    tba_matches.csv   full schedule + live scores (+ score breakdown fields)
    tba_rankings.csv  live event rankings (rank, W-L-T, ranking points)
    tba_oprs.csv      OPR / DPR / CCWM per team
    tba_teams.csv     every team at the event (number, name, home town)

  Built for IRI 2026 (event key 2026iri, July 16-18) - pass -EventKey to use
  it at any other event, e.g.:  Get-TBALive.ps1 -EventKey 2026mibed

  Files only rewrite when the data actually changed, so Tableau refreshes
  are cheap. Offline / TBA hiccups are retried on the next cycle.
  Stop it any time with Ctrl+C.

  Run a single pass instead of looping (for testing):  -Once
#>
param(
  [string]$EventKey = '2026iri',
  [switch]$Once,
  [int]$IntervalSeconds = 60
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

# TBA read key: from the TBA_AUTH_KEY environment variable, or from a
# tbakey.txt file next to this script (one line, just the key). The key is
# free - any team member can make one at thebluealliance.com/account.
$KeyFile = Join-Path $Root 'tbakey.txt'
$AuthKey = if ($env:TBA_AUTH_KEY) { $env:TBA_AUTH_KEY }
           elseif (Test-Path $KeyFile) { (Get-Content $KeyFile -Raw).Trim() }
           else { '' }
if (-not $AuthKey) {
  Write-Host 'No TBA key found. Two-minute fix:' -ForegroundColor Yellow
  Write-Host '  1. Sign in at  https://www.thebluealliance.com/account'
  Write-Host '  2. Under "Read API Keys" click Add New Key (any description).'
  Write-Host '  3. Paste the key into a file named  tbakey.txt  in this folder.'
  Write-Host 'Then start this again.'
  return
}
$Api = 'https://www.thebluealliance.com/api/v3'

function Get-TBA($path) {
  # PS 5.1 hands back an empty JSON array as one un-enumerated Object[] item;
  # piping the parenthesized result flattens it so callers can count records.
  (Invoke-RestMethod -Uri "$Api$path" -Headers @{ 'X-TBA-Auth-Key' = $AuthKey } -TimeoutSec 20) |
    Where-Object { $null -ne $_ }
}

# "frc1023" -> "1023" (Tableau joins on plain team numbers)
function Get-TeamNumber($key) { [string]$key -replace '^frc', '' }

# Same write rules as the USB watcher: only when changed, in place, UTF-8
# without BOM, retrying briefly if a reader has the file open.
function Write-IfChanged($file, $rows) {
  if (-not $rows -or @($rows).Count -eq 0) { return $false }
  $new = (@($rows) | ConvertTo-Csv -NoTypeInformation) -join "`r`n"
  $old = ''
  $readable = $true
  if (Test-Path $file) {
    try { $old = Get-Content $file -Raw -ErrorAction Stop } catch { $readable = $false }
  }
  if ($readable -and $new.TrimEnd() -eq $old.TrimEnd()) { return $false }
  $utf8 = [System.Text.UTF8Encoding]::new($false)
  for ($i = 1; $i -le 10; $i++) {
    try {
      [System.IO.File]::WriteAllText($file, $new, $utf8)
      return $true
    } catch { Start-Sleep -Milliseconds 300 }
  }
  Write-Host ("  ! {0} is OPEN in another program - close it and it will be written next cycle." -f (Split-Path $file -Leaf)) -ForegroundColor Yellow
  return $false
}

function ConvertTo-LocalTime($unix) {
  if (-not $unix) { return '' }
  ([DateTimeOffset]::FromUnixTimeSeconds([long]$unix)).ToLocalTime().ToString('yyyy-MM-dd HH:mm')
}

# --- tba_matches.csv ------------------------------------------------------
# One row per match. The game-specific score breakdown (auto points, fuel,
# climb, fouls... whatever this year's API exposes) is flattened into
# "Red <field>" / "Blue <field>" columns automatically, so we rip EVERYTHING
# TBA publishes without hard-coding this year's game.
function Update-Matches {
  $matches = @(Get-TBA "/event/$EventKey/matches")
  if ($matches.Count -eq 0) {
    Write-Host ("  . no matches posted yet for {0} (schedule usually appears the night before)" -f $EventKey) -ForegroundColor DarkGray
    return
  }

  # Union of scalar breakdown fields across all played matches -> stable columns.
  $breakdownCols = [ordered]@{}
  foreach ($m in $matches) {
    if ($m.score_breakdown) {
      foreach ($side in 'red', 'blue') {
        foreach ($p in $m.score_breakdown.$side.PSObject.Properties) {
          if ($p.Value -is [System.ValueType] -or $p.Value -is [string]) {
            $breakdownCols[$p.Name] = $true
          }
        }
      }
    }
  }

  $order = @{ qm = 1; ef = 2; qf = 3; sf = 4; f = 5 }
  $rows = $matches | Sort-Object { $order[$_.comp_level] }, set_number, match_number | ForEach-Object {
    $m = $_
    $row = [ordered]@{
      'Match Key'   = $m.key
      'Level'       = $m.comp_level
      'Set'         = $m.set_number
      'Match'       = $m.match_number
      'Red 1'       = Get-TeamNumber $m.alliances.red.team_keys[0]
      'Red 2'       = Get-TeamNumber $m.alliances.red.team_keys[1]
      'Red 3'       = Get-TeamNumber $m.alliances.red.team_keys[2]
      'Blue 1'      = Get-TeamNumber $m.alliances.blue.team_keys[0]
      'Blue 2'      = Get-TeamNumber $m.alliances.blue.team_keys[1]
      'Blue 3'      = Get-TeamNumber $m.alliances.blue.team_keys[2]
      'Red Score'   = $m.alliances.red.score
      'Blue Score'  = $m.alliances.blue.score
      'Winner'      = $m.winning_alliance
      'Scheduled'   = ConvertTo-LocalTime $m.time
      'Predicted'   = ConvertTo-LocalTime $m.predicted_time
      'Actual'      = ConvertTo-LocalTime $m.actual_time
    }
    foreach ($col in $breakdownCols.Keys) {
      $row["Red $col"]  = if ($m.score_breakdown) { $m.score_breakdown.red.$col }  else { '' }
      $row["Blue $col"] = if ($m.score_breakdown) { $m.score_breakdown.blue.$col } else { '' }
    }
    [pscustomobject]$row
  }

  if (Write-IfChanged (Join-Path $Root 'tba_matches.csv') $rows) {
    $played = @($matches | Where-Object { $_.actual_time }).Count
    Write-Host ("  = tba_matches.csv updated: {0} matches ({1} played)" -f $matches.Count, $played) -ForegroundColor Green
  }
}

# --- tba_rankings.csv -----------------------------------------------------
function Update-Rankings {
  $r = Get-TBA "/event/$EventKey/rankings"
  if (-not $r -or -not $r.rankings) { return }
  $sortNames = @($r.sort_order_info | ForEach-Object { $_.name })
  $rows = $r.rankings | ForEach-Object {
    $row = [ordered]@{
      'Rank'           = $_.rank
      'Team'           = Get-TeamNumber $_.team_key
      'Wins'           = $_.record.wins
      'Losses'         = $_.record.losses
      'Ties'           = $_.record.ties
      'Matches Played' = $_.matches_played
      'DQ'             = $_.dq
    }
    for ($i = 0; $i -lt $sortNames.Count; $i++) { $row[$sortNames[$i]] = $_.sort_orders[$i] }
    [pscustomobject]$row
  }
  if (Write-IfChanged (Join-Path $Root 'tba_rankings.csv') $rows) {
    Write-Host ("  = tba_rankings.csv updated: {0} teams ranked" -f @($rows).Count) -ForegroundColor Green
  }
}

# --- tba_oprs.csv ---------------------------------------------------------
function Update-OPRs {
  $o = Get-TBA "/event/$EventKey/oprs"
  if (-not $o -or -not $o.oprs) { return }
  $rows = $o.oprs.PSObject.Properties.Name | Sort-Object { [int](Get-TeamNumber $_) } | ForEach-Object {
    [pscustomobject]@{
      'Team' = Get-TeamNumber $_
      'OPR'  = [math]::Round($o.oprs.$_, 2)
      'DPR'  = [math]::Round($o.dprs.$_, 2)
      'CCWM' = [math]::Round($o.ccwms.$_, 2)
    }
  }
  if (Write-IfChanged (Join-Path $Root 'tba_oprs.csv') $rows) {
    Write-Host ("  = tba_oprs.csv updated: {0} teams" -f @($rows).Count) -ForegroundColor Green
  }
}

# --- tba_teams.csv --------------------------------------------------------
function Update-Teams {
  $teams = @(Get-TBA "/event/$EventKey/teams/simple")
  if ($teams.Count -eq 0) { return }
  $rows = $teams | Sort-Object team_number | ForEach-Object {
    [pscustomobject]@{
      'Team'     = $_.team_number
      'Name'     = $_.nickname
      'City'     = $_.city
      'State'    = $_.state_prov
      'Country'  = $_.country
    }
  }
  if (Write-IfChanged (Join-Path $Root 'tba_teams.csv') $rows) {
    Write-Host ("  = tba_teams.csv updated: {0} teams at {1}" -f @($rows).Count, $EventKey) -ForegroundColor Green
  }
}

function Update-All {
  Update-Teams
  Update-Matches
  Update-Rankings
  Update-OPRs
}

Write-Host '==================================================================='
Write-Host ' Scout1023 TBA live ripper'
Write-Host ("   event : {0}" -f $EventKey)
Write-Host ("   output: {0}\tba_*.csv" -f $Root)
Write-Host '   Point Tableau at the tba_*.csv files (join on Team / Match).'
Write-Host '   Press Ctrl+C to stop.'
Write-Host '==================================================================='

if ($Once) {
  Update-All
  Write-Host 'Single pass complete.'
  return
}

while ($true) {
  try { Update-All }
  catch {
    Write-Host ("WARN (will retry in {0}s): {1}" -f $IntervalSeconds, $_.Exception.Message) -ForegroundColor Yellow
  }
  Start-Sleep -Seconds $IntervalSeconds
}
