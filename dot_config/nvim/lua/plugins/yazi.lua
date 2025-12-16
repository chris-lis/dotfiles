---@type LazySpec
return {
    'mikavilpas/yazi.nvim',
    version = '*',
    event = 'VeryLazy',
    dependencies = {
        { 'nvim-lua/plenary.nvim', lazy = true }
    },
    ---@type YaziConfig | {}
    opts = {
        open_for_directories = true,
        keymaps = {
            grep_in_directory = '<C-/>',
            open_file_in_horizontal_split = '<C-s>',
        },
        integrations = {
            grep_in_directory = 'fzf-lua',
            grep_in_selected_files = 'fzf-lua',
        },
    },
    keys = {
        { '\\', '<cmd>Yazi<CR>', desc = 'Open Yazi at the current file' },
        { '<leader>\\', '<cmd>Yazi cwd<CR>', desc = 'Open Yazi at the CWD' },
    },
    init = function ()
        vim.g.loaded_netrwPlugin = 1
    end
}
