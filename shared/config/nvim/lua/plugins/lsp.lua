return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "pyright",
        "json-lsp",
        "html-lsp",
        "lemminx",
        "yaml-language-server",
        "ansible-language-server",
        "marksman",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {},
        jsonls = {},
        html = {},
        lemminx = {},
        yamlls = {},
        ansiblels = {},
        marksman = {},
      },
    },
  },
}
