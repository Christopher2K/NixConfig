local helpers = {}

function helpers.toggle_opencode_terminal()
  Snacks.terminal.toggle("opencode", {
    cwd = vim.fn.getcwd(),
    start_insert = true,
  })
end

function helpers.toggle_terminal()
  Snacks.terminal.toggle(nil, {
    cwd = vim.fn.getcwd(),
    start_insert = true,
  })
end

-- Set the current relative filepath in the clipboard
function helpers.copy_relative_filepath()
  local filepath = vim.fn.fnamemodify(vim.fn.expand('%'), ':~:.')
  vim.fn.setreg('+', filepath)
  print('Copied relative filepath: ' .. filepath)
end

--- Delete all installed packs
function helpers.delete_all_pack()
  local pack_specs = vim.pack.get()
  local pack_name_tbl = {}
  for _, pack in ipairs(pack_specs) do
    table.insert(pack_name_tbl, pack.spec.name)
  end
  vim.pack.del(pack_name_tbl)
end

--- Update all managed plugins to the latest revision matching their spec.
-- Opens vim.pack's interactive confirmation buffer by default.
function helpers.update_all_packs(opts)
  opts = opts or {}
  vim.pack.update(nil, { force = opts.force == true })
end

--- Delete plugins that are installed but no longer listed in the config.
function helpers.clean_packs()
  local inactive = {}
  for _, pack in ipairs(vim.pack.get()) do
    if not pack.active then
      table.insert(inactive, pack.spec.name)
    end
  end
  if #inactive == 0 then
    print("No inactive plugins to clean up")
    return
  end
  vim.pack.del(inactive)
end

--- Update all plugins, then remove any that are no longer in the config.
function helpers.update_and_clean_packs(opts)
  helpers.update_all_packs(opts)
  helpers.clean_packs()
end

return helpers
