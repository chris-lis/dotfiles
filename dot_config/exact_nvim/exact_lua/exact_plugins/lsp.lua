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
                        'stylua',

                        -- Others
                    },
                    -- Off deliberately: auto-updating pulled rust-analyzer ahead
                    -- of the installed rust toolchain, which RA then refuses to
                    -- work with. Update via :MasonToolsUpdate alongside `rustup`.
                    auto_update = false,
                }
            },
            -- TODO: Do these need to be listed here?
            'saghen/blink.cmp', -- Completion engine, config in completion.lua
            'ibhagwan/fzf-lua', -- Fuzzy picker, config in fzf.lua
        },
        config = function()
            -- TODO: Mapping, config, etc.

            -- sourcekit-lsp is bundled with Xcode/CLI tools, not available via mason
            -- macOS only; guarded by SDK availability check
            if vim.fn.has('mac') == 1 then
                vim.fn.system('xcrun --find sourcekit-lsp 2>/dev/null')
                if vim.v.shell_error == 0 then
                    vim.lsp.config('sourcekit', {
                        cmd = {
                            'xcrun', 'sourcekit-lsp',
                            '--experimental-feature', 'background-indexing',
                        },
                        filetypes = { 'swift', 'objective-c', 'objective-cpp' },
                        root_markers = { 'Package.swift', '.git' },
                    })
                    vim.lsp.enable('sourcekit')
                end
            end

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
                        -- client.server_capabilities.codeActionProvider = false
                    elseif client.name == 'ty' then
                        -- TODO:
                    elseif client.name == 'pyrefly' then
                        -- doesn't really work
                        -- client.server_capabilities.diagnosticProvider = false
                        client.server_capabilities.documentFormattingProvider = false
                        client.server_capabilities.documentRangeFormattingProvider = false
                        -- client.server_capabilities.inlayHintProvider = false
                    end

                end
            })

            -- Enable inlay hints and code lenses on attach
            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup('lsp_attach_features', { clear = true }),
                callback = function(args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if not client then return end
                    local bufnr = args.buf

                    if client:supports_method('textDocument/inlayHint') then
                        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                        vim.keymap.set('n', '<leader>ti', function()
                            vim.lsp.inlay_hint.enable(
                                not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }),
                                { bufnr = bufnr }
                            )
                        end, { buffer = bufnr, desc = 'toggle [i]nlay hints' })
                    end

                    if client:supports_method('textDocument/codeLens') then
                        vim.lsp.codelens.enable(true, { bufnr = bufnr })
                        vim.keymap.set('n', 'grl', vim.lsp.codelens.run,
                            { buffer = bufnr, desc = 'LSP: Run code [l]ens' })
                    end

                    -- Fold options are window-local, so guard on the buffer being
                    -- displayed: LspAttach also fires for background buffers and
                    -- would otherwise set folding on an unrelated window.
                    -- Deliberately overrides treesitter folding where available.
                    if client:supports_method('textDocument/foldingRange')
                        and vim.api.nvim_win_get_buf(0) == bufnr then
                        vim.wo.foldmethod = 'expr'
                        vim.wo.foldexpr = 'v:lua.vim.lsp.foldexpr()'
                        vim.wo.foldlevel = 99
                    end
                end
            })

            -- Without this, a server that stops (crash, :LspStop) leaves the
            -- window on vim.lsp.foldexpr, which then reports no folds at all.
            vim.api.nvim_create_autocmd('LspDetach', {
                group = vim.api.nvim_create_augroup('lsp_detach_folding', { clear = true }),
                callback = function(args)
                    if vim.api.nvim_win_get_buf(0) ~= args.buf then return end
                    if vim.wo.foldexpr ~= 'v:lua.vim.lsp.foldexpr()' then return end

                    for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
                        if client.id ~= args.data.client_id
                            and client:supports_method('textDocument/foldingRange') then
                            return
                        end
                    end

                    if vim.treesitter.highlighter.active[args.buf] then
                        vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
                    else
                        vim.wo.foldmethod = 'manual'
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
                virtual_lines = { only_current_line = true },
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
        version = '^9',
        lazy = false,
    }
}
