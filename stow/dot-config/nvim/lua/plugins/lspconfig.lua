local util = require("lspconfig.util")

local prettierd = {
    formatCommand = vim.fn.stdpath('data') .. '/mason/bin/prettierd --stdin-filepath "${INPUT}"',
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

local prettier_apex = {
    formatCommand = 'pnpx prettier --stdin-filepath "${INPUT}"',
    formatStdin = true
}

local alejandra = {formatCommand = "alejandra - ", formatStdin = true}
local nixfmt = {formatCommand = "nixfmt", formatStdin = true}

local sedTrailingSpace = {
    formatCommand = "sed -e 's/[ \t]*$//g'",
    formatStdin = true
}

local sqruff = {formatCommand = "sqruff fix - || true", formatStdin = true}

-- TODO: docker language server
-- TODO: compose language server
-- TODO: checkout dprint
-- TODO: digestif
-- TODO: html, css, json
-- TODO: xml
-- TODO: yaml
-- TODO: latex
-- TODO: bash
-- TODO: vue

return {
    {
        "neovim/nvim-lspconfig",
        ---@class PluginLspOpts
        init = function()
            -- tsgo (TypeScript native Go port) for TS/JS files
            -- vtsls is restricted to Vue files only (see below)
            vim.lsp.enable("tsgo")
            -- oxlint - only starts if project has oxlint configured
            -- (e.g., .oxlintrc.json, or oxlint in package.json dependencies)
            vim.lsp.enable("oxlint")
            -- oxfmt - only starts if project has oxfmt configured
            -- (e.g., .oxfmtrc.json, or oxfmt in package.json dependencies)
            vim.lsp.enable("oxfmt")
        end,
        opts = {
            servers = {
                -- tsgo is enabled via vim.lsp.enable above (installed via Mason)
                -- restrict vtsls to Vue files only so it doesn't overlap with tsgo on TS/JS
                vtsls = {
                    filetypes = { "vue" },
                },
                -- automatically installed with mason and loaded with lspconfig
                apex_ls = {
                    apex_jar_path = vim.fn.stdpath('data') ..
                        '/mason/share/apex-language-server/apex-jorje-lsp.jar',
                    apex_enable_semantic_errors = true, -- Whether to allow Apex Language Server to surface semantic errors
                    apex_enable_completion_statistics = false -- Disable telemetry
                },
                eslint = {settings = {codeActionOnSave = {enable = false}}},
                oxlint = {
                    settings = {
                        typeAware = true, -- Enable type-aware linting when tsgolint available
                    },
                    on_attach = function(client, bufnr)
                        -- LspOxlintFixAll command
                        vim.api.nvim_buf_create_user_command(bufnr, 'LspOxlintFixAll', function()
                            client:exec_cmd({
                                title = 'Apply Oxlint automatic fixes',
                                command = 'oxc.fixAll',
                                arguments = { { uri = vim.uri_from_bufnr(bufnr) } },
                            })
                        end, { desc = 'Apply Oxlint automatic fixes' })

                        -- Auto-fix on save
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            buffer = bufnr,
                            callback = function()
                                client:exec_cmd({
                                    title = 'Apply Oxlint automatic fixes',
                                    command = 'oxc.fixAll',
                                    arguments = { { uri = vim.uri_from_bufnr(bufnr) } },
                                })
                            end,
                        })
                    end,
                },
                jsonls = {init_options = {provideFormatter = false}},
                tailwindcss = {},
                oxfmt = {}, -- uses nvim-lspconfig defaults; only starts if project has oxfmt configured
                efm = {
                    init_options = {
                        documentFormatting = true,
                        documentRangeFormatting = true
                    },
                    filetypes = {
                        "lua", "apexcode", "typescript", "json", "jsonc",
                        "javascript", "html", "yaml", "nix", "sql", "vue", "css"
                    }, -- , "python"
                    settings = {
                        rootMarkers = {"package.json", ".git/"},
                        lintDebounce = "3s",
                        languages = {
                            lua = {
                                {
                                    formatCommand = "lua-format -i",
                                    formatStdin = true
                                }
                            },
                            apexcode = {
                                prettier_apex,
                                pmd
                            },
                            python = {mypy},
                            typescript = {prettierd},
                            json = {prettierd},
                            jsonc = {prettierd},
                            javascript = {prettierd},
                            html = {prettierd},
                            yaml = {actionlint},
                            nix = {nixfmt},
                            sql = {sqruff},
                            css = {prettierd},
                            vue = {prettierd}
                        }
                    }
                },
                jdtls = {
                    mason = false,
                    root_dir = function(fname)
                        if vim.g.disable_jdtls then return nil end
                        for _, patterns in ipairs({{"gradlew", ".git", "mvnw"}}) do
                            local root =
                                util.root_pattern(unpack(patterns))(fname)
                            if root then return root end
                        end
                    end
                }
            },
            setup = {
                oxfmt = function()
                    -- Register oxfmt as primary formatter with higher priority than efm
                    -- oxfmt will be used when available, efm/prettierd as fallback
                    local formatter = LazyVim.lsp.formatter({
                        name = "oxfmt: lsp",
                        primary = true,
                        priority = 1000,
                        filter = "oxfmt"
                    })
                    LazyVim.format.register(formatter)
                end,
                efm = function()
                    -- register efm formatting as fallback (lower priority than oxfmt)
                    local formatter = LazyVim.lsp.formatter({
                        name = "efm: lsp",
                        primary = true,
                        priority = 900,
                        filter = "efm"
                    })
                    LazyVim.format.register(formatter)
                end
            }
        }
    }, {"mason-org/mason.nvim", opts = {PATH = "append"}}, {
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
