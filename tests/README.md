# Teleport UI verification

Run from the mod root:

```text
lua tests/unit.lua
python tests/run_engine.py <path-to-factorio.exe> --save <path-to-save.zip>
python tests/run_engine.py <path-to-factorio.exe> --space-age --save <path-to-save.zip>
```

The engine runner copies the mod and supplied save into a unique directory under
`dist/`. It uses isolated config, mod-list, logs and output paths. The original
save, installed mod-list and normal Factorio config are never written. Test
instrumentation exists only in the copy. Without `--save`, the runner creates a
new map and checks loading only (there is no player to exercise player APIs).
Use a Factorio 2.0 save with a player; scripts in the copied save and its removed
mods may affect whether a particular source save can load.

## Results (2026-10-06)

- Lua 5.4 regression harness: **33 cases passed**. The harness loads the actual
  modules and control handlers with fake Factorio objects. It exercises base-only
  and Space Age startup, key/icon cancellation, selection center, safe-position
  failure, other-surface rejection, pre-existing Remote View, tool release,
  item/ghost preservation, prohibited origins, startup rollback (including API
  exceptions), lifecycle cleanup, old storage cleanup, visited-record retention,
  two-player isolation, planet failure/retry, nearest-pad/spawn choice and close
  events. Cursor and surface events fire synchronously in the harness to stress
  reentrancy. Late selection/cursor events do not close the planet retry panel.
- Factorio **2.0.77**, headless, using a copy of an existing 2.0.77 save:
  **14 base-only assertions and 20 Space Age assertions passed**. Actual player,
  cursor, controller, surface and GUI APIs were exercised, including same-surface
  movement, cross-surface rejection, non-modal panel creation, current-planet
  disabling, planet failure and successful retry. Follow-up checks confirm that the
  icon and all its ancestors have `visible = true` before activation, in Remote
  View and after cancellation. The Space Age follow-up also loaded a copy of the
  latest user save, with unrelated mods disabled; this does not reproduce its full
  GUI layout or rule out interactions with those mods. Area and button handlers were
  invoked by the test script; this is not mouse/keyboard interaction testing.
- Lua syntax, local require paths, locale references and complete task diff were
  checked. The engine also loaded the data stage and runtime event registrations.

## Interactive checks still required

1. In base-only and Space Age, press Alt+M and click the actual upper-left icon.
   Drag a selection on the map, pan/zoom, and check that there is no extra mode
   step. Verify the customized key binding survives an actual 1.0.1 upgrade.
2. While holding the tool in Remote View, click planet buttons. Confirm the
   panel stays visible/clickable, does not capture map input outside its bounds,
   and fits different resolutions/UI scales and long modded planet lists.
3. Test successful and obstructed destinations; after a failed planet move,
   retry another planet, close with the key/icon, then restart. Check real
   Cargo Landing Pad and spawn arrivals, including modded planets.
4. Repeat cancellation using key, icon, close button and putting down the tool,
   both from character view and from a pre-existing Remote View. Browse another
   surface and verify selection cannot teleport there.
5. Check no-character, vehicle, Space Platform and special non-planet origins;
   preserve actual inventory items/ghosts when the cursor is busy.
6. Load a **copy** of a 1.0.1 save with the old GUI/tool active. Verify cleanup and
   visited-planet retention, including enabling/disabling Space Age. Automated
   old-state tests use synthetic storage, not an actual 1.0.1 save upgrade.
7. With two connected players, operate independently and test death/respawn,
   leaving/rejoining, player removal, force change/merge and configuration
   changes. The automated isolation test uses fake players, not a live network.

No interactive GUI or live multiplayer tests have been performed.
