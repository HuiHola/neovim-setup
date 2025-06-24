#!/bin/bash

set -e

echo "🔧 Setting up Neovim LSP & Plugin environment..."

# Install Neovim if not present
if ! command -v nvim &> /dev/null; then
  echo "🚀 Installing Neovim..."
  if [[ -f /etc/debian_version ]]; then
    sudo apt update && sudo apt install -y neovim
  elif [[ -f /etc/redhat-release ]]; then
    sudo dnf install -y neovim
  elif command -v pacman &> /dev/null; then
    sudo pacman -Syu --noconfirm neovim
  else
    echo "❌ Unsupported distro. Please install Neovim manually."
    exit 1
  fi
fi

# Install Node.js + npm
if ! command -v npm &> /dev/null; then
  echo "📦 Installing Node.js + npm..."
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt install -y nodejs
fi

# Install Python and pip
if ! command -v pip &> /dev/null; then
  echo "🐍 Installing Python and pip..."
  sudo apt install -y python3 python3-pip
fi

# Install vim-plug
if [ ! -f ~/.local/share/nvim/site/autoload/plug.vim ]; then
  echo "🔌 Installing vim-plug..."
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# Install global LSPs
echo "📦 Installing global LSPs via npm..."
npm install -g \
  pyright \
  typescript \
  typescript-language-server \
  vscode-langservers-extracted \
  yaml-language-server \
  bash-language-server

# Install python linting tools (optional)
pip install --user pylint

# Setup Neovim config directory
mkdir -p ~/.config/nvim

# Write init.lua
cat > ~/.config/nvim/init.lua << 'EOF'
-- PLUGIN MANAGEMENT (vim-plug)
vim.cmd [[
  call plug#begin('~/.vim/plugged')

  Plug 'nvim-tree/nvim-tree.lua'
  Plug 'nvim-tree/nvim-web-devicons'
  Plug 'tpope/vim-fugitive'
  Plug 'lewis6991/gitsigns.nvim'
  Plug 'kdheepak/lazygit.nvim'
  Plug 'nvim-lualine/lualine.nvim'
  Plug 'nvim-telescope/telescope.nvim'
  Plug 'nvim-lua/plenary.nvim'
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  Plug 'folke/tokyonight.nvim'
  Plug 'neovim/nvim-lspconfig'
  Plug 'hrsh7th/nvim-cmp'
  Plug 'hrsh7th/cmp-nvim-lsp'
  Plug 'hrsh7th/cmp-buffer'
  Plug 'hrsh7th/cmp-path'
  Plug 'hrsh7th/cmp-cmdline'
  Plug 'L3MON4D3/LuaSnip'
  Plug 'saadparwaiz1/cmp_luasnip'

  call plug#end()
]]

vim.o.number = true
vim.o.termguicolors = true
vim.o.clipboard = 'unnamedplus'
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true

vim.cmd [[colorscheme tokyonight-night]]

vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>')
vim.keymap.set('n', '<leader>ff', ':Telescope find_files<CR>')
vim.keymap.set('n', '<leader>fg', ':Telescope live_grep<CR>')
vim.keymap.set('n', '<leader>gs', ':G<CR>')
vim.keymap.set('n', '<leader>lg', ':LazyGit<CR>')
vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
vim.keymap.set('n', 'K', vim.lsp.buf.hover)
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename)
vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end)

require('nvim-treesitter.configs').setup {
  highlight = { enable = true },
}
require('nvim-tree').setup()
require('gitsigns').setup()
require('lualine').setup {
  options = {
    theme = 'nord',
    section_separators = '',
    component_separators = '',
  },
}
vim.g.lazygit_floating_window_winblend = 0
vim.g.lazygit_floating_window_scaling_factor = 0.9
vim.g.lazygit_use_neovim_remote = 1

local cmp = require'cmp'
local luasnip = require'luasnip'

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer' },
    { name = 'path' }
  })
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()
local lspconfig = require('lspconfig')

lspconfig.pyright.setup { capabilities = capabilities }
lspconfig.tsserver.setup { capabilities = capabilities }
lspconfig.html.setup { capabilities = capabilities }
lspconfig.cssls.setup { capabilities = capabilities }
lspconfig.jsonls.setup { capabilities = capabilities }
lspconfig.yamlls.setup { capabilities = capabilities }
lspconfig.bashls.setup { capabilities = capabilities }
lspconfig.lua_ls.setup {
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' },
      }
    }
  }
}
EOF

echo "✅ Neovim setup completed!"
echo "➡️  Now open Neovim and run:  :PlugInstall"
