return {
    'folke/which-key.nvim',
    -- event = 'VimEnter',
    opts = {
        delay = 0,
        spec = {
            { '<leader>f', group = 'find...' },
            { '<leader>t', group = 'toggle...' },
            { '<leader>h', group = 'git hunks...' },
            { '<leader>g', group = 'git...' },
            { '<leader>d', group = 'debug...' },
            { 'g',         group = 'global/go to...' },
            { 'gr',        group = 'LSP' },
        },
    },
}
