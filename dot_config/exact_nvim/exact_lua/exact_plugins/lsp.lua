return {
    -- Core LSP Config & Installation
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            { 'mason-org/mason.nvim', opts = {} },
            { 'mason-org/mason-lspconfig.nvim', opts = {
                automatic_enable = {
                    exclude = {
                        'rust_analyzer', -- already handled by rustaceanvim
                    }
                }
            }},
            {
                'WhoIsSethDaniel/mason-tool-installer.nvim',
                opts = {
                    ensure_installed = {
                        -- Language Servers
                        'lua-language-server',
                        'rust-analyzer',
                        -- 'ty',
                        'pyrefly',

                        -- Debuger Adapters
                        'codelldb',

                        -- Formatters
                        'ruff',

                        -- Others
                    },
                    auto_update = true,
                }
            },
            -- TODO: Do these need to be listed here?
            'saghen/blink.cmp', -- Completion engine, config in completion.lua
            'ibhagwan/fzf-lua', -- Fuzzy picker, config in fzf.lua
        },
        config = function()
            -- TODO: Mapping, config, etc.

            -- Configure Python linter/formatter and typechecker

            -- - Disable overlapping capabilities
            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup(
                    'lsp_attach_python', { clear = true }
                ),
                callback = function (args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client == nil then
                        return
                    end

                    if client.name == 'ruff' then
                        client.server_capabilities.hoverProvider = false
                    end
                    if client.name == 'pyrefly' then
                        -- TODO: Anything here? Consider adding basedpyright to the mix
                    end

                end
            })

            -- Configure showing diagnostic messages
            vim.diagnostic.config({
                severity_sort = true,
                float = { border = 'rounded', source = 'if_many' },
                underline = { severity = vim.diagnostic.severity.ERROR },
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = '󰅚 ',
                        [vim.diagnostic.severity.WARN] = '󰀪 ',
                        [vim.diagnostic.severity.INFO] = '󰋽 ',
                        [vim.diagnostic.severity.HINT] = '󰌶 ',
                    },
                },
                virtual_text = {
                    source = 'if_many',
                    spacing = 2,
                    -- TODO: figure it out; I don't understand why would this be needed???
                    format = function (diagnostic)
                        local diagnostic_message = {
                            [vim.diagnostic.severity.ERROR] = diagnostic.message,
                            [vim.diagnostic.severity.WARN]  = diagnostic.message,
                            [vim.diagnostic.severity.INFO]  = diagnostic.message,
                            [vim.diagnostic.severity.HINT]  = diagnostic.message,
                        }
                        return diagnostic_message[diagnostic.severity]
                    end
                },
            })

        end
    },
    -- LSP Plugins
    {
        -- Configure LuaLS for NeoVim config
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
          library = {
            -- See the configuration section for more details
            -- Load luvit types when the `vim.uv` word is found
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
    },
    {
        'mrcjkb/rustaceanvim',
        version = '^6',
        lazy = false,
    }
}
