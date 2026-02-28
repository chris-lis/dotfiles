return {
    {
        -- Support for Python's uv package manager
        'benomahony/uv.nvim',
        opts = {
            picker_integration = true,
        },
    },
    {
        'xvzc/chezmoi.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = {
            edit = {
                watch = true,
            },
        },
        keys = {
            {
                '<leader>fc',
                function () require("chezmoi.pick").fzf() end,
                desc = 'config files (chezmoi-managed)'
            },
            {
                '<leader>fn',
                function () require("chezmoi.pick").fzf(vim.fn.stdpath("config")) end,
                desc = 'Neovim config files (chezmoi-managed)'
            },
        },
    },
}
