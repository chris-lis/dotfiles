return {
    {
        'nvim-orgmode/orgmode',
        event = 'VeryLazy',
        ft = { 'org' },
        config = function ()
            require('orgmode').setup({
                org_agenda_files = '',
                org_hide_leading_stars = true,
                org_hide_emphasis_markers = true,
                org_startup_indented = true,

                mappings = {
                    org = {
                    }
                },
            })

            -- ---KEYMAPPINGS---

            -- Helper function
            local orgmode_action = function (action)
                return string.format(
                    '<cmd>lua require("orgmode").action("%s")<CR>',
                    action
                )
            end

            -- Autocmd setting the mapping for org files only
            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'org',
                group = vim.api.nvim_create_augroup('orgmode-keymappings', {}),
                callback = function ()
                    -- Use <S-CR> to add headings, list items, etc.
                    vim.keymap.set(
                        {'n', 'i'},
                        '<S-CR>',
                        orgmode_action('org_mappings.meta_return'),
                        { silent = true, buffer = true }
                    )

                end
            })

        end
    },
    {
        'chipsenkbeil/org-roam.nvim',
        dependencies = {
            'nvim-orgmode/orgmode',
        },
        opts = {
            directory = '~/org-roam-test/',
        }
    }
}
