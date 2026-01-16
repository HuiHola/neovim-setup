#!/bin/bash
set -e

echo "🔧 Setting up Neovim with config"

# ---------- Install Neovim ----------
if ! command -v nvim &> /dev/null; then
  echo "🚀 Installing Neovim..."
  if command -v pacman &> /dev/null; then
    sudo pacman -Syu --noconfirm neovim
  elif [[ -f /etc/debian_version ]]; then
    sudo apt update && sudo apt install -y neovim
  else
    echo "❌ Unsupported distro"
    exit 1
  fi
fi

# ---------- Install Node ----------
if ! command -v npm &> /dev/null; then
  echo "📦 Installing Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt install -y nodejs
fi

# ---------- Install Python ----------
if ! command -v pip &> /dev/null; then
  echo "🐍 Installing Python + pip..."
  sudo apt install -y python3 python3-pip
fi

# ---------- Install vim-plug ----------
if [ ! -f ~/.local/share/nvim/site/autoload/plug.vim ]; then
  echo "🔌 Installing vim-plug..."
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# ---------- Install LSPs ----------
echo "📦 Installing LSP servers..."
npm install -g \
  pyright \
  typescript \
  typescript-language-server \
  vscode-langservers-extracted \
  yaml-language-server \
  bash-language-server

pip install --user pylint

# ---------- Create config ----------
mkdir -p ~/.config/nvim

cat > ~/.config/nvim/init.lua << 'EOF'
-- ==============================
-- PLUGIN MANAGEMENT (vim-plug)
-- ==============================
vim.cmd [[
  call plug#begin('~/.vim/plugged')

  Plug 'mustache/vim-mustache-handlebars'
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

  " Floating terminal (NvChad-like)
  Plug 'voldikss/vim-floaterm'

  call plug#end()
]]

-- ==============================
-- BASIC OPTIONS
-- ==============================
vim.o.number = true
vim.o.termguicolors = true
vim.o.clipboard = 'unnamedplus'
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true

vim.cmd [[colorscheme tokyonight-night]]

-- ==============================
-- KEYMAPS (UNCHANGED)
-- ==============================
vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>')
vim.keymap.set('n', '<leader>ff', ':Telescope find_files<CR>')
vim.keymap.set('n', '<leader>fg', ':Telescope live_grep<CR>')
vim.keymap.set('n', '<leader>gs', ':G<CR>')
vim.keymap.set('n', '<leader>lg', ':LazyGit<CR>')
vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
vim.keymap.set('n', 'K', vim.lsp.buf.hover)
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename)
vim.keymap.set('n', '<leader>f', function()
  vim.lsp.buf.format { async = true }
end)

-- ==============================
-- FLOATING TERMINAL CONFIG
-- ==============================
vim.g.floaterm_width = 0.9
vim.g.floaterm_height = 0.85
vim.g.floaterm_borderchars = '─│─│╭╮╯╰'
vim.g.floaterm_title = ' Terminal '
vim.g.floaterm_autoclose = 0

-- SAFE keybindings (no conflict)
vim.keymap.set('n', '<leader>tt', ':FloatermToggle<CR>')
vim.keymap.set('t', '<leader>tt', '<C-\\><C-n>:FloatermToggle<CR>')

-- ==============================
-- PLUGIN SETUPS
-- ==============================
require('nvim-tree').setup()
require('gitsigns').setup()
require('lualine').setup { options = { theme = 'nord' } }

require('nvim-treesitter.configs').setup {
  highlight = { enable = true },
}

-- ==============================
-- CMP + LSP
-- ==============================
local cmp = require'cmp'
local luasnip = require'luasnip'

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = {
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    { name = 'path' },
  }
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
    Lua = { diagnostics = { globals = { 'vim' } } }
  }
}
EOF

echo "✅ Setup complete!"
echo "➡ Open Neovim and run:  :PlugInstall"
echo "➡ Floating terminal:  SPACE tt"
