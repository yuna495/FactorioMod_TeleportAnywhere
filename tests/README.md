# Teleport UI verification

Run from the mod root:

```text
lua -E tests/unit.lua
python -I tests/run_engine.py <path-to-factorio.exe> --save <path-to-save.zip>
python -I tests/run_engine.py <path-to-factorio.exe> --space-age --save <path-to-save.zip>
```

The engine runner copies only selected Lua/JSON/locale files and the existing
PNG (never environment-variable files), plus the supplied save into a unique directory under
`dist/`. It uses isolated config, mod-list, logs and output paths. The original
save, installed mod-list and normal Factorio config are never written. Test
instrumentation exists only in the copy. Without `--save`, the runner creates a
new map and checks loading only (there is no player to exercise player APIs).
Use a Factorio 2.0 or 2.1 save with a player; scripts in the copied save and its removed
mods may affect whether a particular source save can load.

## Results (2026-10-25, version 1.1.0)

- Target: Factorio 2.1 (`base >= 2.1.0`), with Space Age optional. No production
  Lua, prototypes, identifiers, assets or storage structures changed.
- Existing Lua regression harness: **42 cases passed**; all production and test
  Lua files passed syntax checks.
- Factorio **2.1.23** engine, using isolated copies of the existing test save:
  **24 base-only assertions and 30 Space Age assertions passed**. Both runs load
  the data/runtime stages and exercise player APIs through scripted handlers.
  Original saves and installed configuration were not modified.
- Checked the [official 2.1 change history](https://wiki.factorio.com/Version_history/2.1.0)
  and [2.1.23 API documentation](https://lua-api.factorio.com/2.1.23/).
  `LuaPlayer.teleport()` no longer implicitly exits Remote View in 2.1; the
  existing implementation explicitly exits before its player fallback and
  after successful character movement, so no runtime change was needed.
  Selection events retain the existing `area`, `surface` and `item` fields;
  new preselection events are not needed for the existing workflow.
- Interactive input, a real 1.0.3 save upgrade with visited-planet records,
  Cargo Landing Pad/spawn arrival coverage in the engine, modded planets and
  live multiplayer still need the checks below. The unit harness covers pad
  selection and spawn fallback with fake objects.

## Previous results (2026-10-12, version 1.0.3)

- Lua 5.4 regression harness: **42 cases passed**. It loads the actual modules,
  control handlers and data definitions with fake Factorio objects. Both base-only
  and Space Age cover shortcut/key start and cancel, ignoring other shortcuts,
  removal of old buttons from both known mod-gui layouts without deleting shared
  containers or other mods' buttons, no launcher recreation during setup/key
  input, highlighting through success/failure/cancellation/lifecycle cleanup,
  blueprint/item/ghost preservation, player isolation, and the earlier teleport
  state transitions. Cursor and surface callbacks fire synchronously to exercise
  reentrancy; late selection/cursor events preserve the planet retry panel.
- Factorio **2.0.77**, headless, using a disposable copy of a 2.0.77 save:
  **24 base-only assertions and 30 Space Age assertions passed**. This includes
  loading data/runtime stages, actual shortcut availability/toggled APIs,
  registered shortcut and custom-input handlers, removing synthetic legacy GUI
  buttons using the production setup function, preserving adjacent buttons,
  same-surface movement, blueprint/ghost protection and planet failure/retry.
  Each handler invocation performs one transition; no input is forwarded to the
  other handler. These are scripted handler calls, not mouse or keyboard input.
- Lua syntax, locale references/key parity, local require paths, version and task
  diff were checked. The existing PNG is byte-for-byte unchanged from Git HEAD.
- The definition follows the installed Factorio 2.0.77
  `base/prototypes/shortcuts.lua` format (`icon`, `icon_size`, `small_icon`,
  `small_icon_size`). The [official ShortcutPrototype documentation](https://lua-api.factorio.com/latest/prototypes/ShortcutPrototype.html#associated_control_input)
  describes `associated_control_input` as tooltip keybind metadata; it does not
  forward a second activation. Online latest documentation may describe a newer
  version; compatibility of the used fields and runtime APIs was checked by the
  2.0.77 engine runs above.

## Interactive checks still required

1. In base-only and Space Age, press Alt+M and click the actual bottom shortcut-bar icon.
   Drag a selection on the map, pan/zoom, and check that there is no extra mode
   step. Verify the customized key binding survives an actual 1.0.2 upgrade. Confirm that one physical keypress/click
   makes one transition, including clicking again in Remote View. Change the
   shortcut bar visibility/order and UI scale; confirm the icon remains usable
   alongside other mods and respects the standard bar settings.
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
6. Load a **copy** of a 1.0.2 save with the old launcher/GUI/tool active. Verify cleanup and
   visited-planet retention, including enabling/disabling Space Age. Automated
   old-state tests use synthetic storage, not an actual 1.0.2 save upgrade.
7. With two connected players, operate independently and test death/respawn,
   leaving/rejoining, player removal, force change/merge and configuration
   changes. The automated isolation test uses fake players, not a live network.

No interactive GUI or live multiplayer tests have been performed.
