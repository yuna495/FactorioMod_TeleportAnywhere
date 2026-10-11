-- Runs only in the isolated copy made by run_engine.py, never in user saves.
local Gui = require("scripts.gui")
local State = require("scripts.state")
local Constants = require("scripts.constants")
local Planets = require("scripts.planets")
local mod_gui = require("__core__.lualib.mod-gui")
local Tests = {}

function Tests.run(setup_players)
  if storage.teleport_ui_test_completed then return end
  local count = 0
  local function check(value, label)
    assert(value, label)
    count = count + 1
    log("TA CHECK: " .. label)
  end
  local surface = game.surfaces[1]
  surface.request_to_generate_chunks({0, 0}, 2)
  surface.force_generate_chunk_requests()
  local p = game.players[1]
  if not p then
    log("TA ENGINE PASS: data/control load only (no player in generated map)")
    return
  end
  p.exit_remote_view()
  if not p.character then p.create_character() end
  p.driving = false
  p.clear_cursor()
  p.teleport(surface.find_non_colliding_position("character", {0, 0}, 64, 0.5), surface)
  local function state() return State.get_player(p.index) end
  local function closed()
    return not state().map_selecting and not state().gui_open and
      not state().origin_surface_index and not p.cursor_stack.valid_for_read and
      not p.is_shortcut_toggled(Constants.prototypes.shortcut)
  end
  local function frame() return mod_gui.get_frame_flow(p)[Constants.gui.frame] end
  local function key()
    script.get_event_handler(Constants.inputs.toggle_gui)({player_index = p.index})
  end
  local function shortcut(name)
    script.get_event_handler(defines.events.on_lua_shortcut)({player_index = p.index,
      prototype_name = name or Constants.prototypes.shortcut})
  end
  local function find(element, predicate)
    if predicate(element) then return element end
    for _, child in pairs(element.children) do
      local result = find(child, predicate)
      if result then return result end
    end
  end
  local function select(destination_surface)
    Gui.handle_map_selection({player_index = p.index, item = Constants.prototypes.map_tool,
      surface = destination_surface, area = {left_top = {0, 0}, right_bottom = {2, 2}}})
  end
  local top_frame = p.gui.top.mod_gui_top_frame or p.gui.top.add({type = "frame", name = "mod_gui_top_frame"})
  local flow = top_frame.mod_gui_inner_frame or top_frame.add({type = "flow", name = "mod_gui_inner_frame"})
  local legacy = p.gui.top.mod_gui_button_flow or p.gui.top.add({type = "flow", name = "mod_gui_button_flow"})
  local flows = {flow, legacy}
  for _, container in ipairs(flows) do
    if not container[Constants.gui.legacy_toggle_button] then
      container.add({type = "button", name = Constants.gui.legacy_toggle_button})
    end
    container.add({type = "button", name = "teleport_test_other_mod_button"})
  end
  setup_players()
  for _, container in ipairs(flows) do
    check(container.valid and container.teleport_test_other_mod_button.valid and
      not container[Constants.gui.legacy_toggle_button], "old icon removed; shared container and other button preserved")
  end
  check(p.is_shortcut_available(Constants.prototypes.shortcut), "shortcut available without research")
  check(not p.is_shortcut_toggled(Constants.prototypes.shortcut), "shortcut initially inactive")
  shortcut("teleport-test-other-shortcut")
  check(closed(), "other shortcut ignored")
  shortcut()
  check(p.is_shortcut_toggled(Constants.prototypes.shortcut), "shortcut click activates exactly once and highlights")
  shortcut("teleport-test-other-shortcut")
  check(state().map_selecting, "other shortcut does not cancel selection")
  check(state().map_selecting and p.controller_type == defines.controllers.remote, "immediate remote selection")
  check(p.cursor_stack.name == Constants.prototypes.map_tool, "selection tool prepared")
  if script.active_mods["space-age"] then
    check(frame() and state().gui_open, "planet panel with selection")
    check(p.opened ~= frame(), "panel is non-modal")
    local current = find(frame(), function(e) return e.tags.planet == "nauvis" end)
    check(current and not current.enabled, "current planet disabled")
  else
    check(not frame() and not state().gui_open, "base-only has no panel")
  end
  key()
  check(closed() and p.controller_type ~= defines.controllers.remote, "repeat activation cancels and restores")
  check(not p.is_shortcut_toggled(Constants.prototypes.shortcut), "key cancels shortcut activation and clears highlight")
  key()
  check(p.is_shortcut_toggled(Constants.prototypes.shortcut), "key activates exactly once and highlights")
  shortcut()
  check(closed(), "shortcut cancels key activation")
  check(not flow[Constants.gui.legacy_toggle_button] and not legacy[Constants.gui.legacy_toggle_button],
    "inputs do not recreate old icon")
  Gui.cancel(p)
  check(closed(), "repeat cleanup is safe")
  p.set_controller({type = defines.controllers.remote, surface = surface, position = p.physical_position})
  key()
  key()
  check(closed() and p.controller_type == defines.controllers.remote, "pre-existing remote view preserved")
  p.exit_remote_view()
  p.cursor_stack.set_stack({name = "iron-plate", count = 7})
  key()
  check(not state().map_selecting and p.cursor_stack.name == "iron-plate" and p.cursor_stack.count == 7,
    "busy cursor preserved")
  p.cursor_stack.clear()
  p.cursor_stack.set_stack({name = "blueprint", count = 1})
  shortcut()
  check(p.cursor_stack.valid_for_read and p.cursor_stack.name == "blueprint" and
    not p.is_shortcut_toggled(Constants.prototypes.shortcut), "blueprint protected and shortcut inactive")
  p.cursor_stack.clear()
  p.cursor_ghost = "iron-chest"
  shortcut()
  check(p.cursor_ghost ~= nil and not p.is_shortcut_toggled(Constants.prototypes.shortcut),
    "ghost protected and shortcut inactive")
  p.cursor_ghost = nil
  key()
  p.cursor_stack.clear()
  Gui.handle_cursor_changed({player_index = p.index})
  check(closed(), "tool release cancels panel and selection")
  key()
  select(surface)
  check(closed() and p.controller_type ~= defines.controllers.remote, "same-surface selection completes")
  local other = game.create_surface("teleport-test-non-planet", {width = 64, height = 64})
  key()
  p.set_controller({type = defines.controllers.remote, surface = other, position = {0, 0}})
  check(state().map_selecting, "browsing another surface preserves selection")
  select(other)
  check(closed() and p.physical_surface == surface, "cross-surface selection rejected")
  if script.active_mods["space-age"] then
    p.teleport({0, 0}, other)
    key()
    check(closed(), "non-planet origin rejected")
    p.teleport({0, 0}, surface)
    local target = game.planets.vulcanus.create_surface()
    Planets.mark_visited(p.force, "vulcanus")
    key()
    local button = find(frame(), function(e) return e.tags.planet == "vulcanus" end)
    State.get_force_planets(p.force.name).vulcanus = nil
    Gui.handle_click({player_index = p.index, element = button})
    check(state().gui_open and not state().map_selecting and not p.cursor_stack.valid_for_read and
      p.is_shortcut_toggled(Constants.prototypes.shortcut),
      "planet failure leaves panel without selection")
    Gui.handle_cursor_changed({player_index = p.index})
    check(state().gui_open, "late cursor event preserves failed planet panel")
    Planets.mark_visited(p.force, "vulcanus")
    Gui.handle_click({player_index = p.index, element = button})
    check(closed() and p.physical_surface == target, "planet retry succeeds and closes panel")
  end
  log("TA ENGINE PASS: " .. count)
  storage.teleport_ui_test_completed = true
end

return Tests
