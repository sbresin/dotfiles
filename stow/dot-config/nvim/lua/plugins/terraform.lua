-- Fix for terraform-ls freezing nvim 0.12+
--
-- Root cause: terraform-ls emits negative deltaStartChar values for multiline
-- semantic tokens (e.g., heredocs), causing nvim's semantic token handler to freeze.
--
-- Issue: https://github.com/hashicorp/terraform-ls/issues/2108
-- Fix PR: https://github.com/hashicorp/terraform-ls/pull/2122 (pending merge)
--
-- Workaround: disable semantic tokens until terraform-ls releases the fix.
-- Remove this file once terraform-ls > 0.38.6 is released with the fix.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        terraformls = {
          on_attach = function(client, bufnr)
            -- Disable semantic tokens to prevent freeze (terraform-ls bug #2108)
            client.server_capabilities.semanticTokensProvider = nil
          end,
        },
      },
    },
  },
}
