CHALLENGE MAKER EXPORTER 0.8.143

0.8.143 fixes {damage multiplier} in exported challenges by calculating the
actual vanilla player multiplier instead of calling a laser-only API.

This package includes the rebuilt Windows executable (0. 1. 0).
It reads empty Lua map fields stored as [], {}, or null without rejecting
the save slot. Invalid challenges are reported separately; valid ones remain
available for export. Your save files are read only and do not need editing.
Verified by loading and generating a pack from the original 29-challenge save.
The Windows interface and the generated pack have not been tested in-game.

Run ChallengeMakerExporter.exe after saving challenges in Isaac.
Select challenges, click EXPORT, and enter the pack folder name.
The exporter creates mods/NAME/ directly beside the other installed mods.
Each pack contains its own main.lua, metadata.xml, content/challenges.xml,
challenges.json and scripts/cm_pack_<identifier>/ Lua modules for conditions,
rewards and bans. All runtime includes point into that pack's script folder.
Enable the pack in Isaac's Mods menu, then restart Isaac.
The editor and challenge_maker_exported are not required to play the pack.
REPENTOGON and content mods referenced by a challenge must remain enabled.

Exporting the same pack name replaces that pack's selected challenges.
Other packs are not scanned, combined or modified. Existing unrelated mod
folders are protected: choose another name if the folder is already in use.
Challenge names get a [pack name] suffix to avoid collisions between packs.
Keep the whole pack folder together when sharing or moving it.
Re-export after changing settings; JSON is retained as a settings snapshot,
but the game loads content/challenges.xml and the generated Lua scripts.

UPGRADING FROM 0.8.78
Old groups inside challenge_maker_exported/content are left untouched.
Re-export each desired pack from the editor using this new exporter.
Disable the old Challenge Maker Exported mod to avoid duplicate old entries.

Source: tools/source/main.go (Go standard library, Windows amd64).
Build from tools/source:
  set GOOS=windows
  set GOARCH=amd64
  go build -ldflags="-H windowsgui" -o ../ChallengeMakerExporter.exe main.go

0.8.137 - MULTIPLE THENS, VARIABLES AND CLOTTIES
- Updated the embedded runtime to match the current Challenge Maker version.
- Exported IF / ELSE IF branches preserve all THEN effects and the independent
  repeat, chance, cooldown and delay options of every THEN.
- Exported challenges now include text, number and boolean variables used by
  VARIABLE IS and CHANGE VARIABLE TO.
- Added the current clot creation, destruction and retrieval conditions/effects.

0.8.139 - SINGLE-BRACE VARIABLE REFERENCES
- Variable references use {variable}; typing { opens matching suggestions.

0.8.140 - VANILLA STAT REFERENCES
- MATH and SHOW MESSAGE support {damage}, {damage multiplier}, {range},
  {tears}, {fire rate}, {fire delay}, {speed}, {shot speed} and {luck}.

0.8.141 - MATH MULTIPLICATION
- MATH accepts both x and * as multiplication operators.

0.8.142 - DAMAGE MULTIPLIER
- Fixed {damage multiplier} reading REPENTOGON's current multiplier as 1.

0.8.138 - MATH AND VARIABLE MESSAGES
- Added MATH conditions and effects using numeric expressions and {variable}
  references.
- SHOW MESSAGE now replaces {variable} references with their current values.

0.8.80 - DESCRIPTION
DESCRIPTION is the first parameter. SAVE replaces the existing description;
saving empty text removes it. Enter adds a line break. Mouse wheel / arrows
scroll the text area. The editor stores up to 16000 bytes of description text.
Descriptions are retained in saved challenges, exported JSON and runtime Lua.
Each pack includes its own cm_description.lua module.
Entering a described challenge (including Continue or Retry) opens a nearly
full-screen panel. Click its red X to close. While open the game update is
paused and gameplay input is blocked. Long text wraps and scrolls; the right
scrollbar also accepts clicking/dragging. No description means no popup.

HOW TO SET UP:
1. Enter the isaac folder.
2. Go to mods and search challenge_maker.
3. Put all files from this into tools.
4. Now you can use it freely

HOW TO USE:
1. Execute the .exe.
2. Select the challenges you want to export.
3. Click the button in the top right that says "EXPORT".
4. Introduce a name for the folder of the mod pack with all the selected challenges.
5. Click "EXPORT" again.
6. The folder will be created in the mods folder inside of isaac and it will appear in the custom challenges isaac native section.
7. If you want to upload it to Steam just use the mod uploader inside isaac tools and select the folder.

Thanks for using this mod
