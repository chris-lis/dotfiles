return {
    'nvim-mini/mini.nvim',
    version = false,
    config = function ()
        require('mini.icons').setup()
        -- # Text Editing
        -- ## Autopairs
        -- TODO: there are some annoyances with it; can you alleviate them?
        require('mini.pairs').setup()

        -- GOAT: Text objects and operations for inside/arround/surround
        -- These were clashing with each other and now they don't
        -- For some reason; I didn't change anything & there was no update?
        require('mini.ai').setup()
        require('mini.surround').setup()

        -- TODO: actually learn and remmeber what are those extra objects
        require('mini.extra').setup() -- who doesn't like more text objects

        -- GOAT: gS to toggle arguments inline or each on its own line
        require('mini.splitjoin').setup()

        -- Trial it out: f,F,t,T across lines & repeatable
        require('mini.jump').setup()
        -- Trial it out: movement using [ and ]
        require('mini.bracketed').setup()

        -- GOAT: Move lines and visual selection
        -- TODO: add keymaps for replicating lines
        require('mini.move').setup()

        -- Trial it out: preserve window layout on buffer remove
        require('mini.bufremove').setup()


        require('mini.statusline').setup({
            content = {
                active = function()
                    local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
                    local git           = MiniStatusline.section_git({ trunc_width = 75 })
                    local diagnostics   = vim.diagnostic.status(0)
                    local filename      = MiniStatusline.section_filename({ trunc_width = 140 })
                    local fileinfo      = MiniStatusline.section_fileinfo({ trunc_width = 120 })
                    local location      = MiniStatusline.section_location({ trunc_width = 75 })

                    return MiniStatusline.combine_groups({
                        { hl = mode_hl,                    strings = { mode } },
                        { hl = 'MiniStatuslineDevinfo',    strings = { git, diagnostics } },
                        '%<',
                        { hl = 'MiniStatuslineFilename',   strings = { filename } },
                        '%=',
                        { hl = 'MiniStatuslineFileinfo',   strings = { fileinfo } },
                        { hl = mode_hl,                    strings = { location } },
                    })
                end,
            },
        })

        -- Replace with Oil or Yazi or something else?
        -- require('mini.files').setup()
        -- vim.keymap.set('n', '\\', MiniFiles.open, { desc = 'Open files explorer' })
        -- TODO: Keymaps!

    end
}
