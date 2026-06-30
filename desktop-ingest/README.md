# Scout1023 USB Watcher → Tableau

A tiny, self-contained Windows program for the **scouting laptop**. It watches
for USB drives, pulls every `Scout1023_*.csv` off them, merges all 6 tablets'
rows into one de-duplicated **`master.csv`**, and keeps it up to date as you
plug drives in. Tableau reads that one file.

- **No internet** needed (built for offline events).
- **No installs** — it's built-in Windows PowerShell.
- **No manual work** — just plug USB drives in, one after another.

---

## Put it on a laptop (one-time, ~1 minute)

1. Copy the whole **`desktop-ingest`** folder onto the scouting laptop
   (Desktop is fine).
2. Done. There's nothing to install.

> The folder is fully portable — copy it to any Windows 10/11 laptop.

## Run it (every event)

1. Double-click **`START-SCOUTING-WATCHER.bat`**.
   - A black window opens and says it's watching. Leave it open.
   - If Windows SmartScreen warns about the `.bat`, click **More info → Run anyway**
     (it only runs the script next to it).
2. Plug in a scouter's USB drive. Within ~5 seconds you'll see lines like:
   ```
   + imported Scout1023_Blue2_m12_2026-04-05_1430.csv from E:\
   = master.csv updated: 64 records, 6 source files
   ```
3. Unplug, plug in the next tablet's USB, repeat. Order doesn't matter, and you
   can re-plug the same drive later — duplicates are handled automatically.

`master.csv` appears right inside this folder. Imported files are kept in the
`inbox\` subfolder (so you have every original, and re-plugging is instant).

## Connect Tableau (one-time)

1. Open Tableau → **Connect → To a File → Text file**.
2. Pick **`master.csv`** in this folder.
3. Build your dashboard. Suggested fields:
   - *Dimensions:* Team, Match, Alliance, Initials, Robot Role
   - *Measures:* A/T Fuel Scored & Fed, Defense, Climb Level
4. **To pull in new data while scouting:** select the `master.csv` data source
   and press **F5** (or **Data → master.csv → Refresh**). Each refresh re-reads
   the latest merged file. (See "Auto-refresh" below for hands-off options.)

### Auto-refresh (optional)

Tableau **Desktop/Public** don't auto-reload a file on a timer by themselves —
you press **F5** to pull the latest (one key, takes a second). Two ways to make
it hands-off:

- **Tableau Cloud/Server:** publish the data source and set a refresh schedule.
  (Needs the laptop online, so usually for back-at-school analysis.)
- **Keep pressing F5:** if you want, I can add a small helper that sends F5 to
  Tableau every 30s so the dashboard updates on its own. Ask and I'll drop it in.

The **merge/`master.csv` side is always automatic** — it updates within seconds
of plugging in a drive no matter what. Only Tableau's on-screen refresh is the
manual F5.

---

## How duplicates are handled

Each tablet's export is **cumulative** — every export contains all of that
scouter's matches so far. So plugging in 6 tablets gives lots of repeated rows.

The watcher treats **one record = one scouter's view of one robot in one match**
(`Initials` + `Match` + `Team` + `Alliance`). Repeats collapse to a single row,
and the **most recent export wins** (so a corrected re-scout replaces the old
one). A `Source File` column is added so you can trace any row back to its file.

## Troubleshooting

- **Nothing imports:** confirm the files on the USB are named `Scout1023_*.csv`
  (that's what the tablet app produces). The watcher searches all folders on the
  drive, including `Android/...` backup copies.
- **Tableau shows old numbers:** press **F5** to refresh the data source.
- **"running scripts is disabled" error:** use the `.bat` (it already bypasses
  that). Don't run the `.ps1` directly.
- **Start clean for a new event:** close the window, delete `master.csv` and the
  `inbox\` folder, and start the watcher again.
