local State = {}

function State.ensure()
  storage.teleport_anywhere = storage.teleport_anywhere or {}

  local mod_state = storage.teleport_anywhere
  mod_state.force_planets = mod_state.force_planets or {}
  mod_state.players = mod_state.players or {}

  return mod_state
end

function State.get_force_planets(force_name)
  local mod_state = State.ensure()
  mod_state.force_planets[force_name] = mod_state.force_planets[force_name] or {}
  return mod_state.force_planets[force_name]
end

function State.get_player(player_index)
  local mod_state = State.ensure()
  mod_state.players[player_index] = mod_state.players[player_index] or {}
  return mod_state.players[player_index]
end

function State.remove_player(player_index)
  local mod_state = State.ensure()
  mod_state.players[player_index] = nil
end

return State
