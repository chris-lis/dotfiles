return {
    'folke/snacks.nvim',
    priority = 999,
    lazy = false,
    ---@module 'snacks'
    ---@type snacks.Config
    opts = {
        picker = { enabled = false },
        input = { enabled = true },
        notifier = {
            enabled = true,
            top_down = false,
            timeout = 2500,
            style = 'minimal',
            padding = true,
        }
    },
    config = function(_, opts)
        require('snacks').setup(opts)

        -- LSP progress notifications (from snacks notifier docs)
        vim.api.nvim_create_autocmd('LspProgress', {
            ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
            callback = function(ev)
                local spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
                vim.notify(vim.lsp.status(), 'info', {
                    id = 'lsp_progress',
                    title = 'LSP Progress',
                    opts = function(notif)
                        notif.icon = ev.data.params.value.kind == 'end' and ' '
                            or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
                    end,
                })
            end,
        })
    end,
    keys = {
        -- { '<leader>fb', function() Snacks.picker.buffers() end, desc = "[b]uffers" },
        -- { '<leader>ff', function() Snacks.picker.files() end, desc = "[f]iles" },
        -- -- TODO: Reconsider - the picker is kinda meh...
        -- { '<leader>fz', function() Snacks.picker.zoxide() end, desc = "[z]oxide" }, -- TODO: Easier shortcut?
        -- { '<leader>fh', function() Snacks.picker.help() end, desc = "[h]elp" },
        -- { '<leader>/', function() Snacks.picker.grep() end, desc = "Grep" },
    },
}
