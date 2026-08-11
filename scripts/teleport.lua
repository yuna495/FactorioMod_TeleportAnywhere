local Constants = require("scripts.constants")
local Planets = require("scripts.planets")
local State = require("scripts.state")

local Teleport = {}

local function is_valid(object)
  return object and object.valid
end

local function print_player(player, message)
  if is_valid(player) then
    player.print(message)
  end
end

local function get_character_name(player)
  if is_valid(player) and is_valid(player.character) then
    return player.character.name
  end

  return nil
end

local function get_position_component(position, key, index)
  if position[key] ~= nil then
    return position[key]
  end

  return position[index]
end

local function area_center(area)
  local left_top = area.left_top or area[1]
  local right_bottom = area.right_bottom or area[2]

  return {
    x = (get_position_component(left_top, "x", 1) + get_position_component(right_bottom, "x", 1)) / 2,
    y = (get_position_component(left_top, "y", 2) + get_position_component(right_bottom, "y", 2)) / 2
  }
end

local function distance_squared(left, right)
  local dx = get_position_component(left, "x", 1) - get_position_component(right, "x", 1)
  local dy = get_position_component(left, "y", 2) - get_position_component(right, "y", 2)

  return dx * dx + dy * dy
end

local function has_blocking_vehicle(player)
  if not is_valid(player) then
    return false
  end

  local vehicle = player.physical_vehicle
  return is_valid(vehicle) or player.driving == true
end

local function can_use_player_character(player)
  if not is_valid(player) or not is_valid(player.character) then
    print_player(player, { "teleport-anywhere.error-no-character" })
    return false
  end

  if has_blocking_vehicle(player) then
    print_player(player, { "teleport-anywhere.error-in-vehicle" })
    return false
  end

  return true
end

local function ensure_chunks(surface, position)
  surface.request_to_generate_chunks(position, Constants.search.chunk_generation_radius)
  surface.force_generate_chunk_requests()
end

local function find_safe_position(player, surface, position, generate_chunks)
  if generate_chunks then
    ensure_chunks(surface, position)
  end

  local character_name = get_character_name(player)
  if not character_name then
    return nil
  end

  return surface.find_non_colliding_position(
    character_name,
    position,
    Constants.search.radius,
    Constants.search.precision,
    false
  )
end

local function clear_map_tool_from_cursor(player)
  local cursor_stack = player.cursor_stack
  if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == Constants.prototypes.map_tool then
    cursor_stack.clear()
  end
end

local function exit_remote_view(player)
  if player.controller_type == defines.controllers.remote then
    player.exit_remote_view()
  end

  if player.controller_type == defines.controllers.remote then
    print_player(player, { "teleport-anywhere.error-remote-view" })
    return false
  end

  return true
end

local function print_unsupported_current_surface(player)
  local surface = Planets.get_physical_surface(player)
  if is_valid(surface) and is_valid(surface.platform) then
    print_player(player, { "teleport-anywhere.error-space-platform" })
  else
    print_player(player, { "teleport-anywhere.error-not-planet" })
  end
end

local function teleport_player_to(player, surface, position, generate_chunks)
  if not can_use_player_character(player) then
    return false
  end

  if not is_valid(surface) then
    print_player(player, { "teleport-anywhere.error-not-planet" })
    return false
  end

  local destination = find_safe_position(player, surface, position, generate_chunks)
  if not destination then
    print_player(player, { "teleport-anywhere.error-no-safe-destination" })
    return false
  end

  if not exit_remote_view(player) then
    return false
  end

  local teleported = player.teleport(destination, surface, true, false)
  if not teleported then
    print_player(player, { "teleport-anywhere.error-teleport-failed" })
    return false
  end

  Planets.mark_player_planet(player)
  print_player(player, { "teleport-anywhere.teleported" })
  return true
end

local function find_cargo_landing_pad(surface, force)
  local spawn = force.get_spawn_position(surface)
  local pads = surface.find_entities_filtered({
    type = Constants.entity_types.cargo_landing_pad,
    force = force
  })

  local best_pad = nil
  local best_distance = nil

  for _, pad in pairs(pads) do
    if is_valid(pad) then
      local distance = distance_squared(spawn, pad.position)
      if not best_distance or distance < best_distance then
        best_pad = pad
        best_distance = distance
      end
    end
  end

  return best_pad
end

function Teleport.teleport_to_planet(player, planet_name)
  if not can_use_player_character(player) then
    return false
  end

  local current_planet = Planets.get_current_planet(player)
  if not current_planet then
    print_unsupported_current_surface(player)
    return false
  end

  if current_planet.name == planet_name then
    print_player(player, { "teleport-anywhere.error-current-planet" })
    return false
  end

  if not Planets.is_visited(player.force, planet_name) then
    print_player(player, { "teleport-anywhere.error-unvisited-planet" })
    return false
  end

  local surface = Planets.get_planet_surface(planet_name)
  if not surface then
    print_player(player, { "teleport-anywhere.error-no-planet-surface" })
    return false
  end

  local cargo_landing_pad = find_cargo_landing_pad(surface, player.force)
  local base_position = cargo_landing_pad and cargo_landing_pad.position or player.force.get_spawn_position(surface)

  return teleport_player_to(player, surface, base_position, true)
end

function Teleport.begin_map_selection(player)
  if not can_use_player_character(player) then
    return false
  end

  local current_surface = Planets.get_physical_surface(player)
  local current_planet = Planets.get_surface_planet(current_surface)
  if not current_planet then
    print_unsupported_current_surface(player)
    return false
  end

  local cursor_stack = player.cursor_stack
  if not cursor_stack then
    print_player(player, { "teleport-anywhere.error-cursor-unavailable" })
    return false
  end

  if cursor_stack.valid_for_read and cursor_stack.name ~= Constants.prototypes.map_tool then
    print_player(player, { "teleport-anywhere.error-cursor-busy" })
    return false
  end

  if not cursor_stack.valid_for_read then
    cursor_stack.set_stack({ name = Constants.prototypes.map_tool, count = 1 })
  end

  if not cursor_stack.valid_for_read or cursor_stack.name ~= Constants.prototypes.map_tool then
    print_player(player, { "teleport-anywhere.error-cursor-busy" })
    return false
  end

  local player_state = State.get_player(player.index)
  player_state.map_selecting = true
  player_state.map_surface_index = current_surface.index

  print_player(player, { "teleport-anywhere.select-map-destination" })
  return true
end

function Teleport.cancel_map_selection_if_cursor_changed(player)
  if not is_valid(player) then
    return
  end

  local player_state = State.get_player(player.index)
  if not player_state.map_selecting then
    return
  end

  local cursor_stack = player.cursor_stack
  if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == Constants.prototypes.map_tool then
    return
  end

  player_state.map_selecting = false
  player_state.map_surface_index = nil
end

function Teleport.cancel_map_selection(player_index)
  local player_state = State.get_player(player_index)
  player_state.map_selecting = false
  player_state.map_surface_index = nil

  local player = game.get_player(player_index)
  if is_valid(player) then
    clear_map_tool_from_cursor(player)
  end
end

function Teleport.handle_map_selection(event)
  if event.item ~= Constants.prototypes.map_tool then
    return false
  end

  local player = game.get_player(event.player_index)
  if not is_valid(player) then
    return true
  end

  local player_state = State.get_player(player.index)
  local expected_surface_index = player_state.map_surface_index
  local current_surface = Planets.get_physical_surface(player)

  player_state.map_selecting = false
  player_state.map_surface_index = nil
  clear_map_tool_from_cursor(player)

  if not expected_surface_index then
    return true
  end

  if not is_valid(current_surface) or current_surface.index ~= expected_surface_index then
    print_player(player, { "teleport-anywhere.error-map-different-surface" })
    return true
  end

  if not is_valid(event.surface) or event.surface.index ~= expected_surface_index then
    print_player(player, { "teleport-anywhere.error-map-different-surface" })
    return true
  end

  if not Planets.get_surface_planet(event.surface) then
    print_player(player, { "teleport-anywhere.error-not-planet" })
    return true
  end

  teleport_player_to(player, event.surface, area_center(event.area), false)
  return true
end

return Teleport
