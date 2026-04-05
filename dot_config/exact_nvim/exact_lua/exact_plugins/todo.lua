return {
    'folke/todo-comments.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {},
    keys = {
        { '<leader>ft', '<cmd>TodoFzfLua<cr>',                                       desc = 'todos' },
        { ']t',         function() require('todo-comments').jump_next() end,          desc = 'Next todo' },
        { '[t',         function() require('todo-comments').jump_prev() end,          desc = 'Prev todo' },
    },
}
