-- Treesitter
-- https://github.com/nvim-treesitter/nvim-treesitter/tree/main
return {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    branch = 'main',
    build = ':TSUpdate',
    config = function()
        -- List of parsers to install
        local ensure_installed = {
            'rust',
            'python',

            'bash',
            'diff',

            'html',

             -- These should always be installed
            'markdown',
            'markdown_inline',
            'lua',
            'vim',
            'vimdoc',
            'c',
            'query',
        }
        local exclude_indent = { }
        local exclude_fold = { }

        -- Adapted from: https://old.reddit.com/r/neovim/comments/1kuj9xm/has_anyone_successfully_switched_to_the_new/mu6acjr/
        -- Installs only new parsers from the list above (thus getting rid of an info message when they are already installed)
        local already_installed = require("nvim-treesitter.config").get_installed()
        require('nvim-treesitter').install(
            vim.iter(ensure_installed)
            :filter(function(parser)
                return not vim.tbl_contains(already_installed, parser)
            end)
            :totable()
        )

        -- Setup autocmds to launch TreeSitter on supported file open
        local group = vim.api.nvim_create_augroup('treesitter-start', { clear = true })
        vim.api.nvim_create_autocmd('FileType', {
            desc = 'Activate TreeSitter for supported file types.',
            group = group,
            pattern = ensure_installed,
            callback = function(ctx)
                vim.treesitter.start()

                if not vim.list_contains(exclude_indent, ctx.match) then
                    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end

                if not vim.list_contains(exclude_fold, ctx.match) then
                    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
                end
            end,
        })
    end
}
