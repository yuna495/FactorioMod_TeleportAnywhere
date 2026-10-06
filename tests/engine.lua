-- Runs only in the isolated copy made by run_engine.py, never in user saves.
local Gui = require("scripts.gui")
local State = require("scripts.state")
local Constants = require("scripts.constants")
local Planets = require("scripts.planets")
local mod_gui = require("__core__.lualib.mod-gui")
local Tests = {}

function Tests.run()
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
      not state().origin_surface_index and not p.cursor_stack.valid_for_read
  end
  local function frame() return mod_gui.get_frame_flow(p)[Constants.gui.frame] end
  local function icon_visible()
    local button = mod_gui.get_button_flow(p)[Constants.gui.toggle_button]
    if not button or not button.valid or button.sprite ~= "item/" .. Constants.prototypes.map_tool then
      return false
    end
    local element = button
    while element do
      if not element.visible then return false end
      element = element.parent
    end
    return true
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
  check(icon_visible(), "icon and ancestors visible before activation")
  Gui.toggle(p)
  check(icon_visible(), "icon and ancestors visible in Remote View")
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
  Gui.toggle(p)
  check(closed() and p.controller_type ~= defines.controllers.remote, "repeat activation cancels and restores")
  check(icon_visible(), "icon and ancestors visible after cancellation")
  Gui.cancel(p)
  check(closed(), "repeat cleanup is safe")
  p.set_controller({type = defines.controllers.remote, surface = surface, position = p.physical_position})
  Gui.toggle(p)
  Gui.toggle(p)
  check(closed() and p.controller_type == defines.controllers.remote, "pre-existing remote view preserved")
  p.exit_remote_view()
  p.cursor_stack.set_stack({name = "iron-plate", count = 7})
  Gui.toggle(p)
  check(not state().map_selecting and p.cursor_stack.name == "iron-plate" and p.cursor_stack.count == 7,
    "busy cursor preserved")
  p.cursor_stack.clear()
  Gui.toggle(p)
  p.cursor_stack.clear()
  Gui.handle_cursor_changed({player_index = p.index})
  check(closed(), "tool release cancels panel and selection")
  Gui.toggle(p)
  select(surface)
  check(closed() and p.controller_type ~= defines.controllers.remote, "same-surface selection completes")
  local other = game.create_surface("teleport-test-non-planet", {width = 64, height = 64})
  Gui.toggle(p)
  p.set_controller({type = defines.controllers.remote, surface = other, position = {0, 0}})
  check(state().map_selecting, "browsing another surface preserves selection")
  select(other)
  check(closed() and p.physical_surface == surface, "cross-surface selection rejected")
  if script.active_mods["space-age"] then
    p.teleport({0, 0}, other)
    Gui.toggle(p)
    check(closed(), "non-planet origin rejected")
    p.teleport({0, 0}, surface)
    local target = game.planets.vulcanus.create_surface()
    Planets.mark_visited(p.force, "vulcanus")
    Gui.toggle(p)
    local button = find(frame(), function(e) return e.tags.planet == "vulcanus" end)
    State.get_force_planets(p.force.name).vulcanus = nil
    Gui.handle_click({player_index = p.index, element = button})
    check(state().gui_open and not state().map_selecting and not p.cursor_stack.valid_for_read,
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
