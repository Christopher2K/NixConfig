local lsp = {}

function lsp.init()
  local servers = {
    "astro",
    "biome",
    "clangd",
    "cssls",
    "docker_compose_language_service",
    "dockerls",
    "expert",
    "gopls",
    "html",
    "jsonls",
    "kotlin_lsp",
    "lua_ls",
    "pyright",
    "qmlls",
    "rust_analyzer",
    "svelte",
    "tailwindcss",
    "vtsls",
    "yamlls",
  }

  local unmanaged_servers = {
    "ocamllsp",
    "gleam",
  }

  require("mason").setup()
  require("mason-lspconfig").setup({
    automatic_enable = false,
    ensure_installed = servers,
  })
  require("blink.cmp").setup({
    keymap = {
      preset = "enter",
      ['<S-Tab>'] = { 'select_prev', 'fallback' },
      ['<Tab>'] = { 'select_next', 'fallback' },
    },
    completion = {
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 500,
      }
    },
    sources = {
      default = { 'lsp' }
    }
  })

  vim.diagnostic.config({
    float = {
      source = true,
      border = 'rounded'
    }
  })

  -- Config override
  vim.lsp.config("vtsls", {
    on_attach = function(client, _)
      client.server_capabilities.documentFormattingProvider = false
    end
  })


  vim.lsp.config("jsonls", {
    on_attach = function(client, _)
      client.server_capabilities.documentFormattingProvider = false
    end
  })

  -- Enable everything
  vim.lsp.enable(servers)
  vim.lsp.enable(unmanaged_servers)
end

return lsp
