return {{
    'rebelot/kanagawa.nvim',
    priority = 1000,
    config = function ()
        require('kanagawa').setup({
            -- Color Scheme config
            colors = {
                theme = {
                    all = {
                        ui = {
                            -- No ugly gutter background
                            bg_gutter = "none"
                        }
                    }
                }
            },
            overrides = function(colors)
                local theme = colors.theme
                return {
                    -- Transparent Floating Windows
                    NormalFloat = { bg = "none" },
                    FloatBorder = { bg = "none" },
                    FloatTitle = { bg = "none" },

                    -- Save an hlgroup with dark background and dimmed foreground
                    -- so that you can use it where your still want darker windows.
                    -- E.g.: autocmd TermOpen * setlocal winhighlight=Normal:NormalDark
                    NormalDark = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },

                    -- Popular plugins that open floats will link to NormalFloat by default;
                    -- set their background accordingly if you wish to keep them dark and borderless
                    LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
                    MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },

                    -- Borderless Telescope
                    TelescopeTitle = { fg = theme.ui.special, bold = true },
                    TelescopePromptNormal = { bg = theme.ui.bg_p1 },
                    TelescopePromptBorder = { fg = theme.ui.bg_p1, bg = theme.ui.bg_p1 },
                    TelescopeResultsNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
                    TelescopeResultsBorder = { fg = theme.ui.bg_m1, bg = theme.ui.bg_m1 },
                    TelescopePreviewNormal = { bg = theme.ui.bg_dim },
                    TelescopePreviewBorder = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },

                    -- Dark completion (popup) menu
                    Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1 },  -- add `blend = vim.o.pumblend` to enable transparency
                    PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
                    PmenuSbar = { bg = theme.ui.bg_m1 },
                    PmenuThumb = { bg = theme.ui.bg_p2 },
                }
            end,
        })

        vim.cmd.colorscheme 'kanagawa'
    end,
},
{
    'ramojus/mellifluous.nvim',
    lazy = false,
    priority = 1000,
    config = function ()
        require('mellifluous').setup({
            flat_background = {
                line_numbers = true,
            },
            dim_inactive = true,
        })

        -- vim.cmd.colorscheme 'mellifluous'
    end
},
    -- Overall, pretty, but has issues, e.g., autocompletion has selection that's invisible
    {
        'rose-pine/neovim',
        name = 'rose-pine',
        priority = 999,
        config = function ()

            -- require('rose-pine.utilities')

            require('rose-pine').setup({
                variant = 'moon',

                dim_inactive_windows = true,

                palette = {
                    moon = {
                        base = '#191724',
                        surface = '#1f1d2e',
                        overlay = '#26233a',


                    }
                }
            })

            -- vim.cmd.colorscheme 'rose-pine'
        end
    },
    {'EdenEast/nightfox.nvim'},
    {'sainnhe/sonokai'},
    {'sainnhe/gruvbox-material'},
}
