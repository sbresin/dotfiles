# sebes dotfiles + nix config

this is only for myself and not yet documented and really usable for others.
you can look around, but it may be better to just asks me. :smile:

this is using nix for things where it makes sense and just stow symlinks for the rest,
especially things where the nix abstractions don't really add value.
theres lots of devenv setup, some nix derivations (packages), etc.

## todo

### dev env

- nixOS virtual machine and utm as better dev setup
- fzf shell integration for xonsh
  - plus modal like menu to choose picker
- xonsh transient prompt

### laptop

- pipewire + bluetooth (codec setup, tweaks etc.)
- autoEq things
- xwayland hidpi patch (if still needed)
- hyprland or niri setup?
- stylix ?

## terminal

emulator: **WezTerm**

- lua configuration with excellent documentation
- friendly and responsive maintainer
- rust codebase :crab: :trollface:
- cross platform and very nice feature set (search, quick select mode, copy mode, ssh client)
- kitty maintainer is a d\*\*k
- no tmux, because i have to learn too much new stuff already and wezterm already has a multiplexer

shell: **xonsh**

- because it's kinda cool
- interactive features matter more to me than scripting
- extending with python is powerful

## usage

- `nh os switch -a ~/workspace/dotfiles/ -- --accept-flake-config`
- `nh home switch -a ~/workspace/dotfiles/ -- --accept-flake-config`
- `cd stow && stow --verbose --dotfiles --restow --target=$HOME .`

## efiboot secureboot setup

### add OpenCore to boot menu

`sudo efibootmgr --create --disk /dev/nvme0n1p1 --loader "\\EFI\\OC\\OpenCore.efi" --label "OpenCore"`

### hack razer bios

TODO: document bios hack for unlocking secure boot key management

### enroll secureboot keys using sbctl

TODO: document for future reference

### enroll tpm to auto unlock LUKS volume using systemd-cryptenroll

TODO: document for future reference

## nvim plugins i need to checkout

- [lspkind.nvim](https://github.com/onsails/lspkind.nvim)
- [tailwindcss-colorizer-cmp](https://github.com/roobert/tailwindcss-colorizer-cmp.nvim)
- [rainbow-delimiters.nvim](https://github.com/hiphish/rainbow-delimiters.nvim)
- [markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim)
- [otter.nvim](https://github.com/jmbuhr/otter.nvim)
- [nvim-neoclip.lua](https://github.com/AckslD/nvim-neoclip.lua)
- [zen-mode.nvim](https://github.com/folke/zen-mode.nvim)
- [nvim-nonicons](https://github.com/yamatsum/nvim-nonicons)
- [diffview](https://github.com/sindrets/diffview.nvim)
- Codewindow.nvim
- ssr.nvim
- hardtime.nvim
- goto-preview
- nvim-lspfuzzy
- rocks.nvim
- hop.nvim
- vim-be-good
- follow-md-links
