-- Deterministic state-machine regression tests, including synchronous reentrant events.
package.path = './?.lua;' .. package.path
local handlers, init, configure = {}, nil, nil
defines = {controllers = {character = 1, remote = 2}, events = setmetatable({}, {__index = function(_, k) return k end})}
script = {active_mods = {}, on_event = function(id, fn) handlers[id] = fn end,
  on_init = function(fn) init = fn end, on_configuration_changed = function(fn) configure = fn end}
local function event(id, p)
  if handlers[id] then handlers[id]({player_index = p.index}) end
end
local function element(spec, parent)
  local e = {valid = true, name = spec.name or '', tags = spec.tags or {}, enabled = spec.enabled ~= false,
    children = {}, style = {}, parent = parent, caption = spec.caption}
  e.add = function(child)
    local v = element(child, e)
    e.children[#e.children + 1] = v
    if child.name then e[child.name] = v end
    return v
  end
  e.destroy = function()
    e.valid = false
    if parent then parent[e.name] = nil end
  end
  return e
end
package.preload['__core__.lualib.mod-gui'] = function()
  return {button_style = 'button', frame_style = 'frame',
    get_button_flow = function(p) return p.buttons end, get_frame_flow = function(p) return p.frames end}
end
local C = require('scripts.constants')
local State = require('scripts.state')
local Gui = require('scripts.gui')
require('control')
local surface1, surface2, force
local function surface(index, planet)
  local s = {valid = true, index = index, planet = planet, pads = {}}
  s.find_non_colliding_position = function(_, position)
    if s.blocked then return nil end
    s.last_target = position
    return position
  end
  s.request_to_generate_chunks = function() end
  s.force_generate_chunk_requests = function() end
  s.find_entities_filtered = function(filter) assert(filter.type == 'cargo-landing-pad'); return s.pads end
  return s
end
local function player(index)
  local p = {valid = true, index = index, physical_surface = surface1, surface = surface1,
    physical_position = {x = 0, y = 0}, controller_type = defines.controllers.character,
    force = force, buttons = element({}), frames = element({}), messages = {}}
  p.print = function(msg) p.messages[#p.messages + 1] = msg[1] end
  local stack = {valid_for_read = false}
  stack.clear = function() stack.valid_for_read = false; stack.name = nil; event('on_player_cursor_stack_changed', p) end
  stack.set_stack = function(v)
    if p.throw_tool then error('tool preparation error') end
    if p.fail_tool then return false end
    stack.name = v.name; stack.count = v.count; stack.valid_for_read = true
    event('on_player_cursor_stack_changed', p)
    return true
  end
  p.cursor_stack = stack
  p.set_controller = function(v)
    if p.throw_remote then error('controller error') end
    if p.fail_remote then return end
    p.controller_type = v.type; p.surface = v.surface
    event('on_player_changed_surface', p)
    if p.lose_cursor then p.cursor_stack = nil end
  end
  p.exit_remote_view = function()
    p.controller_type = defines.controllers.character; p.surface = p.physical_surface
    event('on_player_changed_surface', p)
  end
  local function teleport(position, target)
    if p.fail_move then return false end
    p.physical_position = position; p.physical_surface = target
    if p.controller_type ~= defines.controllers.remote then p.surface = target end
    event('on_player_changed_surface', p)
    return true
  end
  p.character = {valid = true, name = 'character', teleport = teleport}
  p.teleport = teleport
  return p
end
local function reset(sa)
  storage = {}
  script.active_mods = sa and {['space-age'] = '2.0.77'} or {}
  local a = {valid = true, name = 'nauvis'}
  local b = {valid = true, name = 'mod-planet'}
  surface1, surface2 = surface(1, a), surface(2, b)
  a.surface, b.surface = surface1, surface2
  force = {valid = true, name = 'player', get_spawn_position = function() return {x = 10, y = 20} end}
  game = {players = {}, planets = {nauvis = a, ['mod-planet'] = b}}
  game.get_player = function(i) return game.players[i] end
  local p = player(1); game.players[1] = p
  init()
  if sa then State.get_force_planets(force.name)['mod-planet'] = true end
  return p
end
local function state(p) return State.get_player(p.index) end
local function frame(p) return p.frames[C.gui.frame] end
local function closed(p)
  assert(not state(p).map_selecting and not state(p).gui_open and not state(p).origin_surface_index)
  assert(not frame(p))
  assert(not p.cursor_stack or not p.cursor_stack.valid_for_read or p.cursor_stack.name ~= C.prototypes.map_tool)
end
local function click_planet(p)
  Gui.handle_click({player_index = p.index, element = {valid = true, name = '',
    tags = {teleport_anywhere_action = 'planet', planet = 'mod-planet'}}})
end
local function select(p, s)
  handlers.on_player_selected_area({player_index = p.index, item = C.prototypes.map_tool, surface = s,
    area = {left_top = {x = 10, y = 20}, right_bottom = {x = 14, y = 28}}})
end
local count = 0
local function test(name, run)
  run(); count = count + 1; print('PASS ' .. name)
end
for _, sa in ipairs({false, true}) do
  local suffix = sa and ' SA' or ' base'
  test('start and repeat key cancel' .. suffix, function()
    local p = reset(sa); handlers[C.inputs.toggle_gui]({player_index = 1})
    assert(state(p).map_selecting and p.controller_type == defines.controllers.remote)
    assert((frame(p) ~= nil) == sa and not p.opened)
    handlers[C.inputs.toggle_gui]({player_index = 1}); closed(p)
    assert(p.controller_type == defines.controllers.character)
    Gui.cancel(p); closed(p)
  end)
  test('icon start and cancel' .. suffix, function()
    local p = reset(sa); local e = {player_index = 1, element = p.buttons[C.gui.toggle_button]}
    Gui.handle_click(e); assert(state(p).map_selecting); Gui.handle_click(e); closed(p)
  end)
  test('same-surface center and completion' .. suffix, function()
    local p = reset(sa); Gui.toggle(p); select(p, surface1); closed(p)
    assert(p.physical_position.x == 12 and p.physical_position.y == 24)
  end)
  test('selection failure cleanup' .. suffix, function()
    local p = reset(sa); surface1.blocked = true; Gui.toggle(p); select(p, surface1); closed(p)
    assert(p.messages[#p.messages] == 'teleport-anywhere.error-no-safe-destination')
  end)
  test('cross-surface view and selection' .. suffix, function()
    local p = reset(sa); Gui.toggle(p); p.surface = surface2; event('on_player_changed_surface', p)
    assert(state(p).map_selecting); select(p, surface2); closed(p); assert(p.physical_surface == surface1)
  end)
  test('prior remote preserved on cancel' .. suffix, function()
    local p = reset(sa); p.controller_type = defines.controllers.remote; p.surface = surface2
    Gui.toggle(p); assert(p.surface == surface1); Gui.cancel(p); closed(p)
    assert(p.controller_type == defines.controllers.remote)
  end)
  test('tool release' .. suffix, function()
    local p = reset(sa); Gui.toggle(p); p.cursor_stack.clear(); closed(p)
  end)
  test('busy cursor and ghost preserved' .. suffix, function()
    local p = reset(sa); p.cursor_stack.set_stack({name = 'iron-plate', count = 7}); Gui.toggle(p)
    assert(p.cursor_stack.name == 'iron-plate' and p.cursor_stack.count == 7); closed(p)
    p.cursor_stack.clear(); p.cursor_ghost = 'iron-chest'; Gui.toggle(p); closed(p); assert(p.cursor_ghost)
  end)
  test('missing character and vehicle rejected' .. suffix, function()
    local p = reset(sa); p.character = nil; Gui.toggle(p); closed(p)
    p = reset(sa); p.physical_vehicle = {valid = true}; Gui.toggle(p); closed(p)
  end)
  test('startup rollback' .. suffix, function()
    for _, failure in ipairs({'fail_remote', 'fail_tool', 'lose_cursor', 'throw_remote', 'throw_tool'}) do
      local p = reset(sa); p[failure] = true; Gui.toggle(p); closed(p)
      assert(p.controller_type == defines.controllers.character)
    end
  end)
  test('physical surface change cancels' .. suffix, function()
    local p = reset(sa); Gui.toggle(p); p.physical_surface = surface2; event('on_player_changed_surface', p); closed(p)
  end)
  test('lifecycle cleanup' .. suffix, function()
    for _, id in ipairs({'on_player_left_game', 'on_player_died', 'on_player_respawned',
        'on_player_changed_force', 'on_runtime_mod_setting_changed', 'on_player_joined_game'}) do
      local p = reset(sa); Gui.toggle(p); event(id, p); closed(p)
    end
    local p = reset(sa); Gui.toggle(p); event('on_player_removed', p)
    assert(storage.teleport_anywhere.players[1] == nil)
  end)
  test('legacy state migration' .. suffix, function()
    local p = reset(sa); p.controller_type = defines.controllers.remote
    state(p).map_selecting = true; state(p).map_surface_index = 1; state(p).gui_open = true
    p.frames.add({name = C.gui.frame}); p.cursor_stack.set_stack({name = C.prototypes.map_tool, count = 1})
    State.get_force_planets('player')['saved-planet'] = true
    configure(); closed(p); assert(State.get_force_planets('player')['saved-planet'])
    assert(p.controller_type == defines.controllers.remote)
    assert(p.buttons[C.gui.toggle_button].tooltip[1] == 'teleport-anywhere.open-tooltip')
  end)
  test('two player isolation' .. suffix, function()
    local p = reset(sa); local q = player(2); game.players[2] = q
    Gui.toggle(p); Gui.toggle(q); Gui.cancel(p); closed(p)
    assert(state(q).map_selecting and q.cursor_stack.valid_for_read); Gui.cancel(q); closed(q)
  end)
end
 test('Space Age platform and non-planet rejected', function()
  for _, platform in ipairs({false, true}) do
    local p = reset(true); surface1.planet = nil; surface1.platform = platform and {valid = true} or nil
    Gui.toggle(p); closed(p)
    assert(p.messages[#p.messages] == (platform and 'teleport-anywhere.error-space-platform' or 'teleport-anywhere.error-not-planet'))
  end
end)
test('planet failure preserves panel, retry uses nearest pad', function()
  local p = reset(true); surface2.blocked = true; Gui.toggle(p); click_planet(p)
  assert(state(p).gui_open and not state(p).map_selecting and not p.cursor_stack.valid_for_read)
  event('on_player_cursor_stack_changed', p); assert(frame(p))
  select(p, surface1); assert(frame(p) and not state(p).map_selecting)
  surface2.blocked = false
  surface2.pads = {{valid = true, position = {x = 100, y = 100}}, {valid = true, position = {x = 12, y = 20}}}
  click_planet(p); closed(p); assert(p.physical_surface == surface2 and surface2.last_target.x == 12)
end)
test('planet failure cancel then restart', function()
  local p = reset(true); p.fail_move = true; Gui.toggle(p); click_planet(p)
  assert(state(p).gui_open and not state(p).map_selecting); Gui.toggle(p); closed(p)
  p.fail_move = false; Gui.toggle(p); assert(state(p).map_selecting)
end)
test('planet spawn fallback', function()
  local p = reset(true); Gui.toggle(p); click_planet(p); closed(p)
  assert(surface2.last_target.x == 10 and surface2.last_target.y == 20)
end)
test('close and gui-closed cancel', function()
  local p = reset(true); Gui.toggle(p)
  Gui.handle_closed({player_index = 1, element = frame(p)}); closed(p)
  Gui.toggle(p); Gui.handle_click({player_index = 1, element = {valid = true, name = C.gui.close_button}}); closed(p)
end)
print('PASS ' .. count .. ' regression cases')
