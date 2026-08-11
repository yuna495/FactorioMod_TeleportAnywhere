local Constants = require("scripts.constants")
local Gui = require("scripts.gui")
local Planets = require("scripts.planets")
local State = require("scripts.state")
local Teleport = require("scripts.teleport")

local function is_valid(object)
  return object and object.valid
end

local function setup_player(player)
  if not is_valid(player) then
    return
  end

  State.get_player(player.index)
  Teleport.cancel_map_selection(player.index)
  Planets.mark_player_planet(player)
  Gui.ensure_button(player)
  Gui.refresh(player)
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
    Gui.destroy(player)
  end
  Teleport.cancel_map_selection(event.player_index)
end)

script.on_event(defines.events.on_player_removed, function(event)
  State.remove_player(event.player_index)
end)

script.on_event(defines.events.on_player_respawned, function(event)
  setup_player(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_player_changed_surface, function(event)
  setup_player(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_player_changed_force, function(event)
  setup_player(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_cargo_pod_finished_descending, function(event)
  if event.player_index then
    setup_player(game.get_player(event.player_index))
  end
end)

script.on_event(defines.events.on_forces_merged, function(event)
  Planets.merge_force_visits(event.source_name, event.destination)
  setup_all_players()
end)

script.on_event(defines.events.on_gui_click, Gui.handle_click)
script.on_event(defines.events.on_gui_closed, Gui.handle_closed)

script.on_event(defines.events.on_player_selected_area, Teleport.handle_map_selection)
script.on_event(defines.events.on_player_alt_selected_area, Teleport.handle_map_selection)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
  Teleport.cancel_map_selection_if_cursor_changed(game.get_player(event.player_index))
end)

script.on_event(Constants.inputs.toggle_gui, function(event)
  Gui.toggle(game.get_player(event.player_index))
end)
