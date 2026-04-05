return {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {
        highlight = { backdrop = false },
        modes = {
            char = { highlight = { backdrop = false } },
        },
    },
    keys = {
        { 's',         function() require('flash').jump() end,              mode = { 'n', 'x', 'o' }, desc = 'Flash jump' },
        { 'S',         function() require('flash').treesitter() end,        mode = { 'n', 'x', 'o' }, desc = 'Flash treesitter select' },
        { 'r',         function() require('flash').remote() end,            mode = 'o',               desc = 'Flash remote' },
        { 'R',         function() require('flash').treesitter_search() end, mode = { 'o', 'x' },      desc = 'Flash treesitter search' },
        { '<C-s>',     function() require('flash').toggle() end,            mode = 'c',               desc = 'Toggle flash search' },
    },
}
