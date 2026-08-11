local Constants = require("scripts.constants")

local function selection_mode()
  return {
    border_color = { r = 0.2, g = 0.8, b = 1.0, a = 1.0 },
    chart_color = { r = 0.2, g = 0.8, b = 1.0, a = 0.6 },
    cursor_box_type = "copy",
    mode = { "nothing" }
  }
end

data:extend({
  {
    type = "custom-input",
    name = Constants.inputs.toggle_gui,
    key_sequence = "ALT + M",
    consuming = "none",
    action = "lua"
  },
  {
    type = "selection-tool",
    name = Constants.prototypes.map_tool,
    icon = "__TeleportAnywhere__/data/GUI_icon.png",
    icon_size = 128,
    flags = { "only-in-cursor", "not-stackable", "spawnable" },
    hidden = true,
    hidden_in_factoriopedia = true,
    stack_size = 1,
    select = selection_mode(),
    alt_select = selection_mode(),
    skip_fog_of_war = false
  }
})
