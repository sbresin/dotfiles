from typing import Optional, cast, Protocol, Any
from xonsh.aliases import Aliases
from xonsh.built_ins import XSH
from xonsh.environ import Env
from xonsh.events import events
from xonsh.xontribs import xontribs_load
import subprocess


class Builtins(Protocol):
    def execx(
        self,
        input: str,
        mode: Optional[str],
        glbs: Optional[Any] = None,
        locs: Optional[Any] = None,
        stacklevel: Optional[int] = 2,
        filename: Optional[str] = None,
        transform: Optional[bool] = False,
    ) -> None: ...


builtins = cast(Builtins, XSH.builtins)
aliases = cast(Aliases, XSH.aliases)
ctx = XSH.ctx
env = cast(Env, XSH.env)

if env["XONSH_INTERACTIVE"]:
    # The SQLite history backend:
    # * Saves command immediately unlike JSON backend.
    # * Allows to do `history pull` to get commands from another parallel session.
    env["XONSH_HISTORY_BACKEND"] = "sqlite"

    # What commands are saved to the history list. By default all commands are saved.
    # * The option ‘ignoredups’ will not save the command if it matches the previous command.
    # * The option `erasedups` will remove all previous commands that matches and updates the command frequency.
    #   The minus of `erasedups` is that the history of every session becomes unrepeatable
    #   because it will have a lack of the command you repeat in another session.
    # Docs: https://xonsh.github.io/envvars.html#histcontrol
    env["HISTCONTROL"] = "ignoredups"

    # Set regex to avoid saving unwanted commands
    # Do not write the command to the history if it was ended by `###`
    env["XONSH_HISTORY_IGNORE_REGEX"] = ".*(\\#\\#\\#\\s*)$"

    # Adding aliases from dict.
    aliases |= {
        # cd-ing shortcuts.
        "-": "cd -",
        "..": "cd ..",
        ",": "cd ..",
        ",,": "cd ../..",
        ",,,": "cd ../../..",
        ",,,,": "cd ../../../..",
        # eza instead of ls
        "ls": "eza",
        "la": "eza -a",
        "ll": "eza -l",
        "lla": "eza -la",
        "lt": "eza -lt",
    }

    # Avoid typing cd just directory path.
    # Docs: https://xonsh.github.io/envvars.html#auto-cd
    env["AUTO_CD"] = True

    # Whether Xonsh will auto-insert matching parentheses, brackets, and quotes.
    # Only available under the prompt-toolkit shell.
    env["XONSH_AUTOPAIRS"] = True

    # Delete a word on CTRL-Backspace (like ALT-Backspace).
    env["XONSH_CTRL_BKSP_DELETION"] = True

    # completions settings
    env["COMPLETIONS_CONFIRM"] = True
    env["COMPLETIONS_MENU_ROWS"] = 10
    env["COMPLETIONS_DISPLAY"] = "single"  # 'multi'
    env["AUTO_SUGGEST_IN_COMPLETIONS"] = False

    env["PROMPT_TOOLKIT_COLOR_DEPTH"] = "DEPTH_24_BIT"

    env["XONTRIB_PROMPT_BAR_THEME"] = {
        "left": "{user}@{hostname}{cwd_abs#accent}",
        "right": "{hist_status#section}{curr_branch#section}{env_name#strip_brackets#section}{date_time_tz}",
        "bar_bg": "{BACKGROUND_#1F1D2E}",
        "bar_fg": "{#AAA}",
        "section_bg": "{BACKGROUND_#444}",
        "section_fg": "{#CCC}",
        "accent_fg": "{BOLD_#DDD}",
    }

    env["STARSHIP_CONFIG"] = "~/.config/xonsh/starship.toml"
    # env['XONTRIB_PROMPT_STARSHIP_RIGHT_CONFIG'] = f"{env['XDG_CONFIG_HOME']}/xonsh/starship_right.toml"
    # env['XONTRIB_PROMPT_STARSHIP_REPLACE_PROMPT'] = False
    # env['XONTRIB_PROMPT_BAR_RIGHT'] = '{starship_right#nonl#strip}'

    # fzf xontrib settings
    env["fzf_history_binding"] = "c-r"  # Ctrl+R
    env["fzf_ssh_binding"] = "c-s"  # Ctrl+S
    env["fzf_file_binding"] = "c-t"  # Ctrl+T
    env["fzf_dir_binding"] = "c-g"  # Ctrl+G

    # initalize zoxide
    zoxide_init = subprocess.run(
        ["zoxide", "init", "xonsh"], capture_output=True, encoding="UTF-8"
    ).stdout
    builtins.execx(zoxide_init, "exec", ctx, filename="zoxide")

    # initialize carapace
    env["CARAPACE_BRIDGES"] = "zsh,fish,bash,inshellisense"  # optional
    carapace_init = subprocess.run(
        ["carapace", "_carapace", "xonsh"], capture_output=True, encoding="UTF-8"
    ).stdout
    builtins.execx(carapace_init, "exec", ctx, filename="carapace")

    # initialize mise
    mise_init = subprocess.run(
        ["mise", "activate", "xonsh"], capture_output=True, encoding="UTF-8"
    ).stdout
    builtins.execx(mise_init, "exec", ctx, filename="mise")

    # initialize nix-your-shell
    aliases["nix-shell"] = "nix-your-shell  xonsh nix-shell -- @($args)"
    aliases["nix"] = "nix-your-shell  xonsh nix -- @($args)"

    # GPG agent
    env["GPG_TTY"] = subprocess.run(
        ["tty"], capture_output=True, encoding="UTF-8"
    ).stdout

    # If found, the env name is searched inside the $VIRTUALENV_HOME
    # rather than invoking `poetry env info -p` command every time `cd` happens
    # It is faster setting this variable. It will also be used by poetry.
    env["VIRTUALENV_HOME"] = f"{env['HOME']}/.virtualenvs"

    # name of the venv folder. If found will activate it.
    # if set to None then local folder activation will not work.
    env["XSH_AVOX_VENV_NAME"] = ".venv"

    @events.autovox_policy
    def dotvenv_policy(path, **_):
        venv = path / ".venv"
        if venv.exists():
            return venv

    #
    # Xontribs - https://github.com/topics/xontrib
    #
    # Note! Because of xonsh read ~/.xonshrc on every start and can be executed from any virtual environment
    # with the different set of installed packages it's a highly recommended approach to use `-s` to avoid errors.
    # Read more: https://github.com/anki-code/xonsh-cheatsheet/blob/main/README.md#install-xonsh-with-package-and-environment-management-system
    #
    _xontribs_to_load = (
        "argcomplete",
        "fzf-completions",
        # 'dalias',             # Library of decorator aliases (daliases) e.g. `$(@json echo '{}')`.
        # 'jump_to_dir',        # Jump to used before directory by part of the path. Lightweight zero-dependency implementation of autojump or zoxide projects functionality.
        # 'prompt_bar',         # The bar prompt for xonsh shell with customizable sections. URL: https://github.com/anki-code/xontrib-prompt-bar
        "whole_word_jumping",  # Jumping across whole words (non-whitespace) with Ctrl+Left/Right and Alt+Left/Right on Linux or Option+Left/Right on macOS.
        # 'back2dir',           # Back to the latest used directory when starting xonsh shell. URL: https://github.com/anki-code/xontrib-back2dir
        # 'pipeliner',          # Let your pipe lines flow thru the Python code. URL: https://github.com/anki-code/xontrib-pipeliner
        # 'cmd_done',           # Show long running commands durations in prompt with option to send notification when terminal is not focused. URL: https://github.com/jnoortheen/xontrib-cmd-durations
        "jedi",  # Jedi - an awesome autocompletion, static analysis and refactoring library for Python. URL: https://github.com/xonsh/xontrib-jedi
        "clp",  # Copy output to clipboard. URL: https://github.com/anki-code/xontrib-clp
        "sh",  # Paste and run commands from bash, zsh, fish, tcsh in xonsh shell. URL: https://github.com/anki-code/xontrib-sh
        "term_integration",
        # 'readable-traceback',
        "direnv",
        "abbrevs",
        # 'prompt_bar',
        "prompt_starship",
        "voxapi",
        "vox",
        "autovox",
    )
    xontribs_load(_xontribs_to_load, suppress_warnings=True)
    # xontrib load -s @(_xontribs_to_load)
