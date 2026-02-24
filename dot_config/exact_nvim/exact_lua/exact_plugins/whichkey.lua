return {
    'folke/which-key.nvim',
    -- event = 'VimEnter',
    opts = {
        delay = 0,
        spec = {
            { '<leader>f', group = 'find...' },
            { 'g', group = 'global/go to...' },
            { 'gr', group = 'LSP' },
            { 'o', group = 'Orgmode' },
        },
    },
}
