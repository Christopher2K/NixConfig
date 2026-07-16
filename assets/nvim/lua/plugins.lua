local plugins = {}

---@param tbl (string|vim.pack.Spec)[] Plugin specifications
function plugins.add(tbl)
  local prefix = "https://github.com/"

  local final_table = {}

  for _, plugin in ipairs(tbl) do
    if type(plugin) == "string" then
      table.insert(final_table, prefix .. plugin)
    elseif type(plugin) == "table" then
      plugin["src"] = prefix .. plugin["src"]
      table.insert(final_table, plugin)
    end
  end

  return vim.pack.add(final_table)
end

function plugins.init()
  plugins.add({
    -- Global dependencies
    "folke/snacks.nvim",                                                   -- UI library as well
    "nvim-lua/plenary.nvim",                                               -- Utilities
    "laytan/cloak.nvim",                                                   -- Cloak for streaming

    "ellisonleao/gruvbox.nvim",                                            -- Theme
    "nvim-tree/nvim-web-devicons",                                         -- Icons
    "stevearc/conform.nvim",                                               -- Format plugin
    "Bekaboo/dropbar.nvim",                                                -- Breadcrumbs plugin
    "lewis6991/gitsigns.nvim",                                             -- Git signs plugin

    "supermaven-inc/supermaven-nvim",                                      -- AI Completion plugin
    "neovim/nvim-lspconfig",                                               -- LSP base configurations
    "williamboman/mason.nvim",                                             -- LSP / Tools Installer
    "elixir-tools/elixir-tools.nvim",                                      -- Elixir LSP & Tools
    "williamboman/mason-lspconfig.nvim",                                   -- Helper for mason
    { src = "saghen/blink.cmp",        version = vim.version.range("*") }, -- LSP completion plugin
    { src = 'akinsho/bufferline.nvim', version = vim.version.range("*") }, -- Bufferline

    "nvim-lualine/lualine.nvim",                                           -- Status line plugin
    { src = "echasnovski/mini.comment",  version = "main" },               -- Comment plugin
    -- "JoosepAlviste/nvim-ts-context-commentstring",                             -- Contextual commentstring
    { src = "echasnovski/mini.pairs",    version = "main" },               -- Autopairs plugin
    { src = "echasnovski/mini.surround", version = "main" },               -- Symbol surround plugin
    "tpope/vim-sleuth",                                                    -- Auto indent detection
    "nvim-pack/nvim-spectre",                                              -- Search and replace
    { src = "nvim-treesitter/nvim-treesitter", version = "main" },         -- Treesitter
    "windwp/nvim-ts-autotag",                                              -- Treesitter extension for auto-tag
    "wakatime/vim-wakatime",                                               -- WakaTime
    "folke/which-key.nvim",                                                -- Bindings helpers
    "OXY2DEV/markview.nvim",                                               -- Markdown viewers
    "lervag/vimtex",
    "kevalin/mermaid.nvim"                                                 -- Mermaid diagrams
  })
end

function plugins.configure()
  require("gruvbox").setup({
    transparent_mode = true,
  })
  vim.cmd("colorscheme gruvbox")

  require("which-key").setup()
  require("mini.pairs").setup()
  require("mini.surround").setup()

  local gitsigns = require("gitsigns")
  gitsigns.setup({
    signs = {
      add = {
        text = "",
      },
      change = {
        text = "~",
      },
      delete = {
        text = "",
      },
      topdelete = {
        text = "",
      },
      changedelete = {
        text = "~",
      },
    },
  })

  --#region Lualine
  local lualine = require("lualine")
  lualine.setup({
    options = {
      icons_enabled = true,
      theme = "gruvbox",
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
      disabled_filetypes = { "lazygit" },
      always_show_tabline = true,
      always_divide_middle = true,
      globalstatus = true,
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diff", "diagnostics" },
      lualine_c = { 'filename' },
      lualine_x = {},
      lualine_y = { 'progress', 'encoding', 'fileformat', 'filetype' },
      lualine_z = {},
    }
  })
  --#endregion

  --#region Treesitter
  local treesitter = require("nvim-treesitter")
  treesitter.install({
    "css",
    "elixir",
    "gleam",
    "go",
    "html",
    "javascript",
    "jsdoc",
    "json",
    "lua",
    "markdown",
    "markdown_inline",
    "nix",
    "php",
    "rust",
    "sql",
    "svelte",
    "swift",
    "toml",
    "tsx",
    "typescript",
    "vue",
    "yaml",
    "zig",
  })
  local comments = require("mini.comment")
  comments.setup({})
  --#endregion

  --#region UI stuff
  local snacks = require("snacks")
  local cloak = require("cloak")

  snacks.setup({
    input = { enabled = true },
    terminal = { enabled = true },
    picker = { enabled = true },
    notifier = { enabled = true },
    lazygit = { enabled = true },
    explorer = {
      enabled = true,
      replace_netrw = true,
      layout = { preset = "default", preview = false },
    },

    dashboard = {
      enabled = true,
      preset = {
        header = "Neovim :: by LLCoolChris",
        keys = {},
      },
      sections = {
        { section = "header" },
      },
    },

    styles = {
      dashboard = {
        wo = {
          fillchars = "eob: ",
        },
      },
      terminal = {
        border = "rounded",
      },
    },
  })

  cloak.setup()

  --#endregion

  --#region AI Stuff
  local supermaven = require("supermaven-nvim")
  supermaven.setup({
    keymaps = {
      accept_suggestion = '<C-j>',
      accept_word = '<C-l>'
    },
    ignore_filetypes = {
      TelescopePrompt = true,
    },
  })
  --#endregion

  --#region Tools
  local spectre = require("spectre")
  spectre.setup({
    replace_engine = {
      ["sed"] = {
        cmd = "sed",
        args = {
          "-i",
          "",
          "-E",
        },
      },
    },
  })

  --#endregion

  --#region Editor
  local conform = require("conform")
  local util = require("conform.util")

  -- Custom formatters
  local formatters = {
    eslint_c = {
      command = util.from_node_modules("eslint_d"),
      args = { "--fix-to-stdout", "--stdin", "--stdin-filename", "$FILENAME" },
      cwd = util.root_file({
        "eslist.config.mjs",
        ".eslintrc",
        ".eslintrc.js",
      }),
      condition = function(self, ctx)
        return util.root_file({ ".eslintrc", ".eslintrc.js", "eslint.config.mjs" })(self, ctx) ~= nil
      end
    },

    biome_c = {
      command = util.from_node_modules("biome"),
      stdin = true,
      args = {
        "check",
        "--stdin-file-path",
        "$FILENAME",
        "--fix",
      },
      cwd = util.root_file({
        "biome.json",
        "biome.jsonc",
      }),
      condition = function(self, ctx)
        return util.root_file({ "biome.json", "biome.jsonc" })(self, ctx) ~= nil
      end
    }
  }

  conform.setup({
    formatters = formatters,
    formatters_by_ft = {
      python = { "autopep8" },
      javascript = { "biome_c", "eslint_c", "prettier", stop_after_first = true },
      javascriptreact = { "biome_c", "eslint_c", "prettier", stop_after_first = true },
      typescript = { "biome_c", "eslint_c", "prettier", stop_after_first = true },
      typescriptreact = { "biome_c", "eslint_c", "prettier", stop_after_first = true },
      mdx = { "prettier" },
      markdown = { "prettier" },
      json = { "biome_c", "prettier", stop_after_first = true },
      astro = { "prettier" },
      css = { "prettier" },
      html = { "prettier" },
      jsonc = { "biome_c", "prettier", stop_after_first = true },
      nix = { "nixfmt", stop_after_first = true },
      ocaml = { "ocamlformat", stop_after_first = true },
      kotlin = { "ktlint", stop_after_first = true },
      qlm = {},
    },
    format_on_save = {
      quiet = true,
      timeout_ms = 500,
      lsp_fallback = "fallback",
    },
  })
  --#endregion

  --#region Bufferline
  local bufferline = require("bufferline")
  bufferline.setup({
    options = {
      mode = "tabs",
    },
  })
  --#endregion

  --#region Mermaid
  local mermaid = require("mermaid")
  mermaid.setup({
    format = {
      shift_width = 4, -- Indentation size (spaces)
    },
    lint = {
      enabled = true,   -- Enable diagnostics via mmdc
      command = "mmdc", -- Path to mermaid-cli executable
    },
    preview = {
      renderer = "mermaid.js", -- "mermaid.js" or "beautiful-mermaid"
      theme = "default",       -- Theme name (renderer-specific)
    },
  })
  --#endregion
end

return plugins
