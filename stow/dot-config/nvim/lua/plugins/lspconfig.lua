local util = require("lspconfig.util")

local prettierd = {
    formatCommand = '~/.local/share/nvim/mason/bin/prettierd --stdin-filepath "${INPUT}"',
    formatStdin = true
    -- env = {
    --   string.format('PRETTIERD_DEFAULT_CONFIG=%s', vim.fn.expand('~/.config/nvim/utils/linter-config/.prettierrc.json')),
    -- },
}

local pmd = {
    lintCommand = 'pmd check --no-progress --stdin-filepath "${INPUT}" --cache ~/.pmd-cache.bin --rulesets ./pmd-apex-ruleset.xml --format json' ..
        ' | jq --raw-output \'.files[] | .filename + ":" + (.violations[] | (.beginline | tostring) + ":" + (.begincolumn | tostring) + ":" + (.endline | tostring) + ":" + (.endcolumn | tostring) + ":" + (.priority | tostring) + ": " + .description + " (" + .ruleset + ": " + .rule + ")")\'',
    lintFormats = {"%f:%l:%c:%e:%k:%t: %m"},
    lintStdin = true,
    lintIgnoreExitCode = true,
    -- lintOnSave = true,
    lintAfterOpen = true,
    lintSource = "pmd",
    rootMarkers = {"sfdx-project.json"},
    lintCategoryMap = {
        ["1"] = "E",
        ["2"] = "W",
        ["3"] = "I",
        ["4"] = "I",
        ["5"] = "I"
    }
}

local mypy = {
    lintCommand = 'poetry run mypy --show-column-numbers',
    lintStdin = true,
    lintAfterOpen = true,
    lintFormats = {
        '%f:%l:%c: %trror: %m', '%f:%l:%c: %tarning: %m', '%f:%l:%c: %tote: %m'
    }
}

local actionlint = {
    prefix = "actionlint",
    lintCommand = "bash -c \"[[ '${INPUT}' =~ \\\\.github/workflows/ ]]\" && ~/.local/share/nvim/mason/bin/actionlint -oneline -no-color -",
    lintStdin = true,
    lintAfterOpen = true,
    lintSource = "actionlint",
    lintFormats = {"%f:%l:%c: %m"},
    rootMarkers = {".git/", ".github/"}
}

local afmt = {
    formatCommand = '~/workspace/afmt/result/bin/afmt',
    formatStdin = true
}

local alejandra = {formatCommand = "alejandra - ", formatStdin = true}

local sedTrailingSpace = {
    formatCommand = "sed -e 's/[ \t]*$//g'",
    formatStdin = true
}

local sqruff = {formatCommand = "sqruff fix - || true", formatStdin = true}

-- TODO: docker language server
-- TODO: compose language server
-- TODO: checkout dprint
-- TODO: digestif
-- TODO: eslint, html, css, json
-- TODO: xml
-- TODO: yaml
-- TODO: latex
-- TODO: bash
-- TODO: vue

return {
    {
        "neovim/nvim-lspconfig",
        ---@class PluginLspOpts
        opts = {
            servers = {
                -- automatically installed with mason and loaded with lspconfig
                apex_ls = {
                    apex_enable_semantic_errors = true, -- Whether to allow Apex Language Server to surface semantic errors
                    apex_enable_completion_statistics = false -- Disable telemetry
                },
                eslint = {settings = {codeActionOnSave = {enable = false}}},
                jsonls = {init_options = {provideFormatter = false}},
                tailwindcss = {},
                efm = {
                    init_options = {
                        documentFormatting = true,
                        documentRangeFormatting = true
                    },
                    filetypes = {
                        "lua", "apexcode", "typescript", "json", "jsonc",
                        "javascript", "html", "yaml", "nix", "sql"
                    }, -- , "python"
                    settings = {
                        rootMarkers = {".git/"},
                        lintDebounce = "3s",
                        languages = {
                            lua = {
                                {
                                    formatCommand = "lua-format -i",
                                    formatStdin = true
                                }
                            },
                            apexcode = {
                                prettierd, -- sedTrailingSpace,
                                -- afmt,
                                pmd
                            },
                            python = {mypy},
                            typescript = {prettierd},
                            json = {prettierd},
                            jsonc = {prettierd},
                            javascript = {prettierd},
                            html = {prettierd},
                            yaml = {actionlint},
                            nix = {alejandra},
                            sql = {sqruff}
                        }
                    }
                },
                jdtls = {
                    mason = false,
                    root_dir = function(fname)
                        for _, patterns in ipairs({{"gradlew", ".git", "mvnw"}}) do
                            local root =
                                util.root_pattern(unpack(patterns))(fname)
                            if root then return root end
                        end
                    end
                }
            },
            setup = {
                efm = function()
                    -- register efm formatting and override eslint formatting (no FixAll on save)
                    local formatter = LazyVim.lsp.formatter({
                        name = "efm: lsp",
                        primary = true,
                        priority = 900,
                        filter = "efm"
                    })

                    -- register the formatter with LazyVim
                    LazyVim.format.register(formatter)
                end
            }
        }
    }, {"williamboman/mason.nvim", opts = {PATH = "append"}}, {
        "mrcjkb/rustaceanvim",
        opts = {
            server = {
                default_settings = {
                    ["rust-analyzer"] = {
                        cargo = {
                            allFeatures = true,
                            loadOutDirsFromCheck = true,
                            buildScripts = {enable = true},
                            -- fixes tauri incremental compilation
                            targetDir = './target-analyzer'
                        }
                    }
                }
            }
        }
    }

}
