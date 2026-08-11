local Planets = require("scripts.planets")
local Runtime = require("scripts.runtime")
local Teleport = require("scripts.teleport")

local PlanetTeleport = {}

local CARGO_LANDING_PAD_TYPE = "cargo-landing-pad"

local function is_valid(object)
  return object and object.valid
end

local function print_player(player, message)
  if is_valid(player) then
    player.print(message)
  end
end

local function get_position_component(position, key, index)
  if position[key] ~= nil then
    return position[key]
  end

  return position[index]
end

local function distance_squared(left, right)
  local dx = get_position_component(left, "x", 1) - get_position_component(right, "x", 1)
  local dy = get_position_component(left, "y", 2) - get_position_component(right, "y", 2)

  return dx * dx + dy * dy
end

local function find_cargo_landing_pad(surface, force)
  local spawn = force.get_spawn_position(surface)
  local pads = surface.find_entities_filtered({
    type = CARGO_LANDING_PAD_TYPE,
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

function PlanetTeleport.teleport_to_planet(player, planet_name)
  if not Runtime.is_space_age_enabled() then
    return false
  end

  local current_planet = Planets.get_current_planet(player)
  if not current_planet then
    print_player(player, { "teleport-anywhere.error-space-platform" })
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
  local teleported = Teleport.teleport_player_to_surface(player, surface, base_position, true)

  if teleported then
    Planets.mark_player_planet(player)
  end

  return teleported
end

return PlanetTeleport
