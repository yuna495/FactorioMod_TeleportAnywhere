local State = require("scripts.state")

local Planets = {}

local function is_valid(object)
  return object and object.valid
end

function Planets.get_surface_planet(surface)
  if not is_valid(surface) then
    return nil
  end

  local planet = surface.planet
  if is_valid(planet) then
    return planet
  end

  return nil
end

function Planets.get_physical_surface(player)
  if not is_valid(player) then
    return nil
  end

  local surface = player.physical_surface
  if is_valid(surface) then
    return surface
  end

  return nil
end

function Planets.get_current_planet(player)
  return Planets.get_surface_planet(Planets.get_physical_surface(player))
end

function Planets.get_planet(name)
  if not name then
    return nil
  end

  local planet = game.planets[name]
  if is_valid(planet) then
    return planet
  end

  return nil
end

function Planets.get_planet_surface(name)
  local planet = Planets.get_planet(name)
  if not planet then
    return nil
  end

  local surface = planet.surface
  if is_valid(surface) then
    return surface
  end

  return nil
end

function Planets.mark_visited(force, planet_name)
  if not is_valid(force) or not planet_name then
    return false
  end

  local force_planets = State.get_force_planets(force.name)
  force_planets[planet_name] = true
  return true
end

function Planets.mark_player_planet(player)
  if not is_valid(player) or not is_valid(player.force) then
    return false
  end

  local planet = Planets.get_current_planet(player)
  if not planet then
    return false
  end

  return Planets.mark_visited(player.force, planet.name)
end

function Planets.is_visited(force, planet_name)
  if not is_valid(force) or not planet_name then
    return false
  end

  return State.get_force_planets(force.name)[planet_name] == true
end

function Planets.merge_force_visits(source_name, destination_force)
  if not source_name or not is_valid(destination_force) then
    return
  end

  local mod_state = State.ensure()
  local source_planets = mod_state.force_planets[source_name]
  if not source_planets then
    return
  end

  local destination_planets = State.get_force_planets(destination_force.name)
  for planet_name, visited in pairs(source_planets) do
    if visited == true then
      destination_planets[planet_name] = true
    end
  end

  mod_state.force_planets[source_name] = nil
end

local function planet_order(planet)
  local prototype = planet.prototype
  if prototype and prototype.order then
    return prototype.order
  end

  return planet.name
end

function Planets.get_display_name(planet)
  if not is_valid(planet) then
    return nil
  end

  local prototype = planet.prototype
  if prototype and prototype.localised_name then
    return prototype.localised_name
  end

  return planet.name
end

function Planets.list_visited(force)
  local planets = {}
  if not is_valid(force) then
    return planets
  end

  local visited = State.get_force_planets(force.name)
  for name, planet in pairs(game.planets) do
    if visited[name] == true and is_valid(planet) then
      local surface = planet.surface
      if is_valid(surface) then
        planets[#planets + 1] = {
          name = name,
          planet = planet,
          surface = surface,
          order = planet_order(planet),
          display_name = Planets.get_display_name(planet)
        }
      end
    end
  end

  table.sort(planets, function(left, right)
    if left.order == right.order then
      return left.name < right.name
    end

    return left.order < right.order
  end)

  return planets
end

return Planets
