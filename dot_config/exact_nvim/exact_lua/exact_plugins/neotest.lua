return {
    'nvim-neotest/neotest',
    dependencies = {
        'nvim-neotest/nvim-nio',
        'nvim-lua/plenary.nvim',
        'nvim-treesitter/nvim-treesitter',
        'rouge8/neotest-rust',
        'nvim-neotest/neotest-python',
    },
    keys = {
        { '<leader>Tr', function() require('neotest').run.run() end,                    desc = 'run nearest' },
        { '<leader>Tf', function() require('neotest').run.run(vim.fn.expand('%')) end,  desc = 'run file' },
        { '<leader>TS', function() require('neotest').run.run({ suite = true }) end,    desc = 'run suite' },
        { '<leader>Ts', function() require('neotest').summary.toggle() end,             desc = 'toggle summary' },
        { '<leader>To', function() require('neotest').output_panel.toggle() end,        desc = 'toggle output panel' },
        { '<leader>Td', function() require('neotest').run.run({ strategy = 'dap' }) end, desc = 'debug nearest' },
    },
    config = function()
        require('neotest').setup({
            adapters = {
                require('neotest-rust'),
                require('neotest-python'),
            },
        })
    end,
}
