local Constants = require("scripts.constants")
local PlanetTeleport = require("scripts.planet_teleport")
local Planets = require("scripts.planets")
local Runtime = require("scripts.runtime")
local State = require("scripts.state")
local Teleport = require("scripts.teleport")
local mod_gui = require("__core__.lualib.mod-gui")

local Gui = {}

local function is_valid(object)
  return object and object.valid
end

local function get_button_flow(player)
  return mod_gui.get_button_flow(player)
end

local function get_frame_flow(player)
  return mod_gui.get_frame_flow(player)
end

local function get_frame(player)
  local frame_flow = get_frame_flow(player)
  return frame_flow and frame_flow[Constants.gui.frame]
end

function Gui.ensure_button(player)
  if not is_valid(player) then
    return
  end

  local button_flow = get_button_flow(player)
  if button_flow[Constants.gui.toggle_button] then
    return
  end

  button_flow.add({
    type = "sprite-button",
    name = Constants.gui.toggle_button,
    sprite = "item/" .. Constants.prototypes.map_tool,
    style = mod_gui.button_style,
    tooltip = { "teleport-anywhere.open-tooltip" }
  })
end

function Gui.destroy(player)
  if not is_valid(player) then
    return
  end

  local frame = get_frame(player)
  if frame then
    frame.destroy()
  end

  State.get_player(player.index).gui_open = false
end

local function add_titlebar(frame)
  local titlebar = frame.add({ type = "flow", direction = "horizontal" })

  local title = titlebar.add({
    type = "label",
    caption = { "teleport-anywhere.title" }
  })

  local spacer = titlebar.add({
    type = "empty-widget"
  })
  spacer.style.horizontally_stretchable = true
  spacer.style.height = 24

  titlebar.add({
    type = "button",
    name = Constants.gui.close_button,
    caption = { "teleport-anywhere.close" },
    tooltip = { "teleport-anywhere.close-tooltip" }
  })
end

local function add_current_label(content, current_planet)
  local current_display_name = current_planet and Planets.get_display_name(current_planet)
  if current_display_name then
    content.add({
      type = "label",
      caption = { "teleport-anywhere.current", current_display_name }
    })
  else
    content.add({
      type = "label",
      caption = { "teleport-anywhere.current-none" }
    })
  end
end

local function add_map_button(content, current_planet)
  content.add({
    type = "button",
    name = Constants.gui.map_button,
    caption = { "teleport-anywhere.map-teleport" },
    tooltip = { "teleport-anywhere.map-teleport-tooltip" },
    enabled = current_planet ~= nil
  })
end

local function add_planet_button(list, entry, current_planet)
  local is_current = current_planet and current_planet.name == entry.name
  local caption = entry.display_name

  if is_current then
    caption = { "teleport-anywhere.planet-current", entry.display_name }
  end

  list.add({
    type = "button",
    caption = caption,
    enabled = not is_current,
    tags = {
      teleport_anywhere_action = "planet",
      planet = entry.name
    }
  })
end

local function add_space_age_planets(content, player, current_planet)
  content.add({
    type = "line",
    direction = "horizontal"
  })

  content.add({
    type = "label",
    caption = { "teleport-anywhere.planets" }
  })

  local list = content.add({
    type = "flow",
    name = Constants.gui.planet_list,
    direction = "vertical"
  })
  list.style.vertical_spacing = 4

  local visited_planets = Planets.list_visited(player.force)
  if #visited_planets == 0 then
    list.add({
      type = "label",
      caption = { "teleport-anywhere.no-visited-planets" }
    })
  else
    for _, entry in ipairs(visited_planets) do
      add_planet_button(list, entry, current_planet)
    end
  end
end

function Gui.build(player)
  if not is_valid(player) then
    return
  end

  Gui.destroy(player)
  if Runtime.is_space_age_enabled() then
    Planets.mark_player_planet(player)
  end

  local player_state = State.get_player(player.index)
  player_state.gui_open = true

  local frame = get_frame_flow(player).add({
    type = "frame",
    name = Constants.gui.frame,
    direction = "vertical",
    style = mod_gui.frame_style
  })

  add_titlebar(frame)

  local content = frame.add({
    type = "flow",
    direction = "vertical"
  })
  content.style.padding = 8
  content.style.vertical_spacing = 6
  content.style.minimal_width = 220

  if Runtime.is_space_age_enabled() then
    local current_planet = Planets.get_current_planet(player)
    add_current_label(content, current_planet)
    add_map_button(content, true)
    add_space_age_planets(content, player, current_planet)
  else
    add_map_button(content, true)
  end

  player.opened = frame
end

function Gui.refresh(player)
  if not is_valid(player) then
    return
  end

  if State.get_player(player.index).gui_open then
    Gui.build(player)
  end
end

function Gui.toggle(player)
  if not is_valid(player) then
    return
  end

  Gui.ensure_button(player)

  if get_frame(player) then
    Gui.destroy(player)
  else
    Gui.build(player)
  end
end

function Gui.handle_click(event)
  local player = game.get_player(event.player_index)
  local element = event.element

  if not is_valid(player) or not is_valid(element) then
    return
  end

  if element.name == Constants.gui.toggle_button then
    Gui.toggle(player)
    return
  end

  if element.name == Constants.gui.close_button then
    Gui.destroy(player)
    return
  end

  if element.name == Constants.gui.map_button then
    Gui.destroy(player)
    Teleport.begin_map_selection(player)
    return
  end

  local tags = element.tags or {}
  if tags.teleport_anywhere_action == "planet" and tags.planet then
    if Runtime.is_space_age_enabled() then
      PlanetTeleport.teleport_to_planet(player, tags.planet)
    end
    Gui.refresh(player)
  end
end

function Gui.handle_closed(event)
  if not is_valid(event.element) or event.element.name ~= Constants.gui.frame then
    return
  end

  local player = game.get_player(event.player_index)
  Gui.destroy(player)
end

return Gui
