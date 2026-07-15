local autocmds = {}

function autocmds.execute_on_all_tabs(command)
  local current_tab = vim.fn.tabpagenr()
  vim.cmd('tabdo ' .. command)
  vim.cmd('tabnext ' .. current_tab)
end

local function augroup(name)
  return vim.api.nvim_create_augroup("custom_au_" .. name, { clear = true })
end

function autocmds.init()
  local keymaps = require("keymaps")

  vim.api.nvim_create_autocmd({ "VimResized" }, {
    group = augroup("resize_splits"),
    callback = function()
      autocmds.execute_on_all_tabs("wincmd =")
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePre", {
    group = augroup("format_on_save"),
    pattern = "*",
    callback = function(args)
      require("conform").format({ bufnr = args.buf, lsp_fallback = true, async = false })
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "snacks_terminal",
    callback = keymaps.set_terminal_keymaps,
  })

  vim.api.nvim_create_autocmd('FileType', {
    pattern = {
      'python',
      'javascript',
      'typescript',
      'javascriptreact',
      'typescriptreact',
      'elixir',
      'html',
      'css',
      'heex',
      'go',
      'rust',
      'nix',
      'bash'
    },
    callback = function()
      vim.treesitter.start()

      -- Folds
      -- vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      -- vim.wo[0][0].foldmethod = 'expr'

      -- Identation
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
  })
end

return autocmds
