local Runtime = {}

function Runtime.is_space_age_enabled()
  return script.active_mods["space-age"] ~= nil
end

return Runtime
