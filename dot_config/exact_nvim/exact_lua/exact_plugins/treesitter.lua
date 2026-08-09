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
            'swift',

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

        -- Parser names are not filetypes: `bash` highlights `sh`, `vimdoc` covers
        -- `help`/`checkhealth`, `diff` covers `gitdiff`. Using the parser list as
        -- the autocmd pattern silently skips those filetypes.
        local filetypes = {}
        for _, parser in ipairs(ensure_installed) do
            for _, ft in ipairs(vim.treesitter.language.get_filetypes(parser)) do
                filetypes[ft] = true
            end
        end

        -- Setup autocmds to launch TreeSitter on supported file open
        local group = vim.api.nvim_create_augroup('treesitter-start', { clear = true })
        vim.api.nvim_create_autocmd('FileType', {
            desc = 'Activate TreeSitter for supported file types.',
            group = group,
            pattern = vim.tbl_keys(filetypes),
            callback = function(ctx)
                vim.treesitter.start()

                if not vim.list_contains(exclude_indent, ctx.match) then
                    vim.bo[ctx.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end

                -- Fold options are window-local, so guard on the buffer being
                -- displayed: FileType also fires for buffers loaded without a
                -- window (:bufdo, quickfix, picker previews), where `vim.wo`
                -- would leak onto an unrelated window.
                if not vim.list_contains(exclude_fold, ctx.match)
                    and vim.api.nvim_win_get_buf(0) == ctx.buf then
                    vim.wo.foldmethod = 'expr'
                    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
                    vim.wo.foldlevel = 99
                end
            end,
        })
    end
}
