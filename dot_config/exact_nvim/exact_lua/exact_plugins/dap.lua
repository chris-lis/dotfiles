return {
    {
        'mfussenegger/nvim-dap',
        dependencies = {
            -- UI for DAP (variables, stack, breakpoints panes)
            {
                'rcarriga/nvim-dap-ui',
                dependencies = { 'nvim-neotest/nvim-nio' },
                config = function()
                    local dap, dapui = require('dap'), require('dapui')
                    dapui.setup()
                    -- Auto open/close UI with sessions
                    dap.listeners.after.event_initialized['dapui'] = dapui.open
                    dap.listeners.before.event_terminated['dapui'] = dapui.close
                    dap.listeners.before.event_exited['dapui'] = dapui.close
                end,
            },
            -- Inline variable values while debugging
            {
                'theHamsta/nvim-dap-virtual-text',
                opts = {},
            },
        },
        keys = {
            { '<F5>',       function() require('dap').continue() end,          desc = 'DAP: Continue' },
            { '<F10>',      function() require('dap').step_over() end,         desc = 'DAP: Step Over' },
            { '<F11>',      function() require('dap').step_into() end,         desc = 'DAP: Step Into' },
            { '<F12>',      function() require('dap').step_out() end,          desc = 'DAP: Step Out' },
            { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'toggle [b]reakpoint' },
            { '<leader>dB', function()
                require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))
            end, desc = 'conditional [B]reakpoint' },
            { '<leader>dr', function() require('dap').repl.open() end,         desc = 'open [r]epl' },
            { '<leader>dl', function() require('dap').run_last() end,          desc = 'run [l]ast' },
            { '<leader>du', function() require('dapui').toggle() end,          desc = 'toggle [u]i' },
        },
        config = function()
            local dap = require('dap')

            -- codelldb adapter (installed via mason-tool-installer)
            local codelldb = vim.fn.stdpath('data') .. '/mason/packages/codelldb/extension/adapter/codelldb'
            dap.adapters.codelldb = {
                type = 'server',
                port = '${port}',
                executable = {
                    command = codelldb,
                    args = { '--port', '${port}' },
                },
            }

            -- C / C++ configurations
            -- Rust uses rustaceanvim's :RustLsp debuggables — no manual config needed
            dap.configurations.c = {
                {
                    name = 'Launch executable',
                    type = 'codelldb',
                    request = 'launch',
                    program = function()
                        return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
                    end,
                    cwd = '${workspaceFolder}',
                    stopOnEntry = false,
                },
            }
            dap.configurations.cpp = dap.configurations.c

            -- Sign column icons
            vim.fn.sign_define('DapBreakpoint',          { text = '●', texthl = 'DiagnosticError' })
            vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DiagnosticWarn' })
            vim.fn.sign_define('DapStopped',             { text = '▶', texthl = 'DiagnosticOk', linehl = 'CursorLine' })
        end,
    },
}
