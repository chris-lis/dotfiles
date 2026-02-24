return {
    -- Autocompletion Engine
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
        -- TODO: Add a snippet engine

        'folke/lazydev.nvim',
    },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
        -- TODO: customize this?
        keymap = { preset = 'super-tab' },

        completion = {
            keyword = {
                range = 'full',
            },
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 0,
            },
            ghost_text = {
                enabled = true,
            },
            list = {
                selection = {
                    -- When cycling through completions only show ghost text
                    -- and insert only on a TAB press
                    auto_insert = false,
                }
            }
        },

        sources = {
            default = { 'lsp', 'path', 'snippets', 'lazydev' },
            per_filetype = {
                org = { 'orgmode' },
            },
            providers = {
                orgmode = {
                    name = 'Orgmode',
                    module = 'orgmode.org.autocompletion.blink',
                    fallbacks = { 'buffer' }
                },
                lazydev = {
                    module = 'lazydev.integrations.blink',
                    score_offset = 100,
                }
            },
        },

        signature = { enabled = true },

        cmdline = {
            keymap = {
                ['<Tab>']   = { 'show', 'accept' },
                -- ['<S-Tab>'] = { 'show_and_insert', 'select_prev' },
                ['<CR>']    = { 'accept_and_enter', 'fallback' },
                ['<Up>']    = { 'select_prev', 'fallback' },
                ['<Down>']  = { 'select_next', 'fallback' },
                -- ['<Esc>']   = { 'cancel', 'fallback' } -- TODO: how to make the fallback not accept the cmd?
            },
            completion = {
                menu = {
                    -- Auto-show only in command (and input?) modes and only when 3+ characters were typed
                    -- This prevents from accidentally accepting a completion when short cmd was typed
                    -- Completion won't auto-show until 4+ characters if there's no match
                    auto_show = function (ctx)
                        local cmdtype = vim.fn.getcmdtype()
                        return string.len(ctx.line) > 2 and ( cmdtype == ':' )-- or cmdtype == '@' -- TODO: enable for inputs?
                    end,
                },
                ghost_text = { enabled = true },
            },
        },
    }
}
