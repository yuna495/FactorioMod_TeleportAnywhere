local Constants = require("scripts.constants")
local Gui = require("scripts.gui")
local Planets = require("scripts.planets")
local Runtime = require("scripts.runtime")
local State = require("scripts.state")

local function is_valid(object)
  return object and object.valid
end

local function setup_player(player)
  if not is_valid(player) then
    return
  end

  State.get_player(player.index)
  Gui.cancel(player)
  if Runtime.is_space_age_enabled() then
    Planets.mark_player_planet(player)
  end
  Gui.ensure_button(player)
end

local function setup_all_players()
  State.ensure()

  for _, player in pairs(game.players) do
    setup_player(player)
  end
end

script.on_init(setup_all_players)
script.on_configuration_changed(setup_all_players)

script.on_event(defines.events.on_player_created, function(event)
  setup_player(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  setup_player(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_player_left_game, function(event)
  local player = game.get_player(event.player_index)
  if is_valid(player) then
    Gui.cancel(player)
  end
end)

script.on_event(defines.events.on_player_removed, function(event)
  State.remove_player(event.player_index)
end)

script.on_event(defines.events.on_player_respawned, function(event)
  setup_player(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_player_changed_surface, function(event)
  local player = game.get_player(event.player_index)
  if not is_valid(player) then return end
  local player_state = State.get_player(player.index)
  -- This event also fires when only the Remote View surface changes.
  if player_state.origin_surface_index and
      player.physical_surface.index ~= player_state.origin_surface_index then
    Gui.cancel(player)
  end
  if Runtime.is_space_age_enabled() then
    Planets.mark_player_planet(player)
  end
end)

script.on_event(defines.events.on_player_died, function(event)
  Gui.cancel(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.player_index then
    Gui.cancel(game.get_player(event.player_index))
  else
    setup_all_players()
  end
end)

script.on_event(defines.events.on_player_changed_force, function(event)
  setup_player(game.get_player(event.player_index))
end)

if Runtime.is_space_age_enabled() then
  script.on_event(defines.events.on_cargo_pod_finished_descending, function(event)
    if event.player_index then
      setup_player(game.get_player(event.player_index))
    end
  end)
end

script.on_event(defines.events.on_forces_merged, function(event)
  Planets.merge_force_visits(event.source_name, event.destination)
  setup_all_players()
end)

script.on_event(defines.events.on_gui_click, Gui.handle_click)
script.on_event(defines.events.on_gui_closed, Gui.handle_closed)

script.on_event(defines.events.on_player_selected_area, Gui.handle_map_selection)
script.on_event(defines.events.on_player_alt_selected_area, Gui.handle_map_selection)

script.on_event(defines.events.on_player_cursor_stack_changed, Gui.handle_cursor_changed)

script.on_event(Constants.inputs.toggle_gui, function(event)
  Gui.toggle(game.get_player(event.player_index))
end)
