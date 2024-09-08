local util = require("lspconfig.util")

local prettierd = {
	formatCommand = '~/.local/share/nvim/mason/bin/prettierd --apex-standalone-parser=built-in --stdin-filepath "${INPUT}"',
	formatStdin = true,
	-- env = {
	--   string.format('PRETTIERD_DEFAULT_CONFIG=%s', vim.fn.expand('~/.config/nvim/utils/linter-config/.prettierrc.json')),
	-- },
}

local pmd = {
	lintCommand = 'pmd check --no-progress --stdin-filepath "${INPUT}" --cache ~/.pmd-cache.bin --rulesets ./pmd-apex-ruleset.xml --format json'
		.. ' | jq --raw-output \'.files[] | .filename + ":" + (.violations[] | (.beginline | tostring) + ":" + (.begincolumn | tostring) + ":" + (.endline | tostring) + ":" + (.endcolumn | tostring) + ":" + (.priority | tostring) + ": " + .description + " (" + .ruleset + ": " + .rule + ")")\'',
	lintFormats = { "%f:%l:%c:%e:%k:%t: %m" },
	lintStdin = true,
	lintIgnoreExitCode = true,
	-- lintOnSave = true,
	lintAfterOpen = true,
	lintSource = "pmd",
	rootMarkers = { "sfdx-project.json" },
	lintCategoryMap = {
		["1"] = "E",
		["2"] = "W",
		["3"] = "I",
		["4"] = "I",
		["5"] = "I",
	},
}

local actionlint = {
	prefix = "actionlint",
	lintCommand = "bash -c \"[[ '${INPUT}' =~ \\\\.github/workflows/ ]]\" && ~/.local/share/nvim/mason/bin/actionlint -oneline -no-color -",
	lintStdin = true,
	lintAfterOpen = true,
	lintSource = "actionlint",
	lintFormats = {
		"%f:%l:%c: %m",
	},
	rootMarkers = { ".git/", ".github/" },
}

local alejandra = {
  formatCommand = "alejandra - ",
  formatStdin = true,
}

local sedTrailingSpace = {
	formatCommand = "sed -e 's/[ \t]*$//g'",
	formatStdin = true,
}

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
					apex_enable_completion_statistics = false, -- Disable telemetry
				},
				eslint = {
					settings = {
						codeActionOnSave = {
							enable = false,
						},
					},
				},
				jsonls = {
					init_options = {
						provideFormatter = false,
					},
				},
				efm = {
					init_options = {
						documentFormatting = true,
						documentRangeFormatting = true,
					},
					filetypes = { "lua", "apexcode", "typescript", "json", "jsonc", "javascript", "html", "yaml", "nix" },
					settings = {
						rootMarkers = { ".git/" },
						lintDebounce = "3s",
						languages = {
							lua = {
								{
									formatCommand = "lua-format -i",
									formatStdin = true,
								},
							},
							apexcode = {
								prettierd,
								-- sedTrailingSpace,
								pmd,
							},
							typescript = {
								prettierd,
							},
							json = {
								prettierd,
							},
							jsonc = {
								prettierd,
							},
							javascript = {
								prettierd,
							},
							html = {
								prettierd,
							},
							yaml = {
								actionlint,
							},
              nix = {
                alejandra,
              }
						},
					},
				},
				jdtls = {
					mason = false,
					root_dir = function(fname)
						for _, patterns in ipairs({ { "gradlew", ".git", "mvnw" } }) do
							local root = util.root_pattern(unpack(patterns))(fname)
							if root then
								return root
							end
						end
					end,
				},
			},
			setup = {
				efm = function()
					-- register efm formatting and override eslint formatting (no FixAll on save)
					local formatter = LazyVim.lsp.formatter({
						name = "efm: lsp",
						primary = true,
						priority = 900,
						filter = "efm",
					})

					-- register the formatter with LazyVim
					LazyVim.format.register(formatter)
				end,
			},
		},
	},
  {
    "williamboman/mason.nvim",
    opts = {
       PATH = "append",
    }
  }
}
