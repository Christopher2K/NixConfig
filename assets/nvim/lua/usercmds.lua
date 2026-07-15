local usercmd = {}

function usercmd.init()
  local fns = require('fns')


  vim.api.nvim_create_user_command('CopyRelativeFilepath', fns.copy_relative_filepath, {})
  vim.api.nvim_create_user_command('DelAllPack', fns.delete_all_pack, {})
  vim.api.nvim_create_user_command('ToggleOpenCode', fns.toggle_opencode_terminal, {})

  vim.api.nvim_create_user_command('UpdatePacks',
    function(opts)
      fns.update_all_packs({ force = opts.bang })
    end,
    { bang = true, desc = "Update all plugins (force with !)" })

  vim.api.nvim_create_user_command('CleanPacks', fns.clean_packs,
    { desc = "Remove inactive plugins" })

  vim.api.nvim_create_user_command('UpdateAndCleanPacks',
    function(opts)
      fns.update_and_clean_packs({ force = opts.bang })
    end,
    { bang = true, desc = "Update all plugins and remove inactive ones (force with !)" })
end

return usercmd
