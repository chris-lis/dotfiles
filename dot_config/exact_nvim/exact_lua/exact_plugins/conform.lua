return {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    cmd = 'ConformInfo',
    opts = {
        format_on_save = {
            timeout_ms = 500,
            -- Use LSP formatting for filetypes with no conform formatter (Rust, Swift)
            lsp_format = 'fallback',
        },
        formatters_by_ft = {
            lua    = { 'stylua' },
            python = { 'ruff_format' },
        },
    },
    keys = {
        { '<leader>cf', function() require('conform').format({ async = true }) end, desc = 'format buffer' },
    },
}
