return {
    {
        "saghen/blink.cmp",
        opts = function(_, opts)
            opts.signature = opts.signature or {}
            opts.signature.enabled = true -- enable experimental signature help
            opts.sources.providers.copilot.score_offset = -1 -- put copilot below LSP
        end
    }
}
