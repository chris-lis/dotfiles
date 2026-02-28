return {
    'ibhagwan/fzf-lua',
    dependencies = {
        'nvim-mini/mini.nvim', -- Icons
    },
    opts = {
        'borderless-full',
        fzf_colors = true,
        winopts = {
            preview = {
                wrap = true,
            },
        },
        zoxide = {
            actions = {
                -- Open files picker after changing directory
                ['enter'] = function (selected)
                    FzfLua.actions.zoxide_cd(selected, {})
                    FzfLua.files()
                end
            },
        },
    },
    keys = {
        { '<leader>ff', function () FzfLua.global() end, desc = 'files, buffers, symbols' },
        { '<leader>fd', function () FzfLua.zoxide() end, desc = 'directories with zoxide' },
        { '<leader>fb', function () FzfLua.buffers() end, desc = 'buffers' },
        { '<leader>f.', function () FzfLua.oldfiles() end, desc = 'recent files' },
        -- Managed by chezmoi.nvim
        -- { '<leader>fn', function () FzfLua.files({ cwd = '~/.config/nvim/' }) end, desc = 'Neovim configuration files' },
        { '<leader>fh', function () FzfLua.helptags() end, desc = 'help' },
        { '<leader>fk', function () FzfLua.keymaps() end, desc = 'keymaps' },
        { '<leader>fz', function () FzfLua.builtin() end, desc = 'fzf-lua pickers' },

        -- Grep
        { '<leader>f/', function () FzfLua.live_grep() end, desc = 'Grep project files' },
        { '<leader>f/', function () FzfLua.grep_visual() end, mode = 'v', desc = 'Grep selection' },
        { '<leader>fw', function () FzfLua.grep_cword() end, desc = 'Grep word under cursor' },
        { '<leader>fW', function () FzfLua.grep_cWORD() end, desc = 'Grep WORD under cursor' },

        -- Fuzzy search
        { '<leader>/', function () FzfLua.blines() end, desc = 'Fuzzy search current buffer' },

        -- LSP Pickers
        { 'gra', function () FzfLua.lsp_code_actions() end, mode = {'n','v'}, desc = 'LSP: Code Actions' },
        { 'grn', vim.lsp.buf.rename, desc = 'LSP: Rename' }, -- builtin
        { 'grr', function () FzfLua.lsp_references() end, desc = 'LSP: References' },
        { 'gri', function () FzfLua.lsp_implementations() end, desc = 'LSP: Implementations' },
        { 'grd', function () FzfLua.lsp_definitions() end, desc = 'LSP: Definitions' },
        { 'grD', function () FzfLua.lsp_declarations() end, desc = 'LSP: Declarations' },
        { 'grt', function () FzfLua.lsp_typedefs() end, desc = 'LSP: Type Definitions' },
        { 'gO', function () FzfLua.lsp_document_symbols() end, desc = 'LSP: Document Symbols' },
        { 'gW', function () FzfLua.lsp_workspace_symbols() end, desc = 'LSP: Workspace Symbols' },
        { 'grf', function () FzfLua.lsp_finder() end, desc = 'LSP: Finder' },
        { 'grq', function () FzfLua.diagnostics_document() end, desc = 'LSP: Document Diagnostics' },
        { 'grQ', function () FzfLua.diagnostics_workspace() end, desc = 'LSP: Workspace Diagnostics' },

        -- TODO: DAP keymap (after I figure oyt how to configure it and use it)

        -- TODO: Git (once I setup more git functionality)
    },
    config = function (_, opts)
        require('fzf-lua').setup(opts)
        -- TODO: Is this really necessary? Is there not better way?
        FzfLua.register_ui_select()
    end,
}
