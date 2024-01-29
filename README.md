## Base Software

- `stow` (symlink dotfiles)
- `fzf` (fuzzy finding)
- `eza` (better ls)
- `fd` (better find)
- `ripgrep` (better grep)
- `bat` (better cat)
- `sad` (better sed)
- `delta` (syntax highlighted diffs)
- `xplr` (file explorer)
  - don't want a file-tree in nvim, since fuzzy finding is more efficient and this is all about getting faster
  - for other cases, xplr seems great
- up to date `less` (`brew install less`)
- JetBrains Mono Font

## terminal

emulator: **WezTerm**

- lua configuration with excellent documentation
- friendly and responsive maintainer
- rust codebase :crab: :trollface:
- cross platform and very nice feature set (search, quick select mode, copy mode, ssh client, serial mode)
- alacritty has no ligatures :sob:
- kitty is python, high mem usage and maintainer is a d\*\*k
- no tmux, because i have to learn too much new stuff already and wezterm already has a multiplexer

shell: **fish**

- because it's nice
- `fisher install franciscolourenco/done` for system notifications on long running commands
  - `brew install terminal-notifier`
- `fisher install ilancosman/tide@v6` like the prompt
- `fisher install patrickf1/fzf.fish` useful as alternative to find/fd
- `fisher install catppuccin/fish` matching theme with nvim is nice
- `fisher install jorgebucaran/nvm.fish` fish friendly nvm

## dotfiles usage

- clone repo
- `stow --verbose --target=$HOME .`

## nvim plugins

- [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- [mason.nvim](https://github.com/williamboman/mason.nvim)
- [mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim)
- [lspkind.nvim](https://github.com/onsails/lspkind.nvim)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- [nvim-treesitter-context](https://github.com/nvim-treesitter/nvim-treesitter-context)
- [which-key.nvim](https://github.com/folke/which-key.nvim)
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
- [tailwindcss-colorizer-cmp](https://github.com/roobert/tailwindcss-colorizer-cmp.nvim)
- [rainbow-delimiters.nvim](https://github.com/hiphish/rainbow-delimiters.nvim)
- [nvim-surround](https://github.com/kylechui/nvim-surround)
- [surround-ui.nvim](https://github.com/roobert/surround-ui.nvim)
- [markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim)
- [otter.nvim](https://github.com/jmbuhr/otter.nvim)
- [copilot.lua](https://github.com/zbirenbaum/copilot.lua)
- [nvim-neoclip.lua](https://github.com/AckslD/nvim-neoclip.lua)
- [zen-mode.nvim](https://github.com/folke/zen-mode.nvim)
- [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)
- [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons)
- [nvim-nonicons](https://github.com/yamatsum/nvim-nonicons)

# considering

- https://github.com/sindrets/diffview.nvim
- https://github.com/folke/flash.nvim
- https://github.com/zbirenbaum/copilot-cmp
- Codewindow.nvim
- ssr.nvim
- hardtime.nvim
- goto-preview
- nvim-lspfuzzy
- rocks.nvim
- hop.nvim
- neodev.nvim
- vim-be-good
- follow-md-links
