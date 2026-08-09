-- https://github.com/sindrets/diffview.nvim
-- Standalone rather than a neogit dependency; neogit still loads it on demand
-- through its `diffview` integration.

local function toggle()
    if require('diffview.lib').get_current_view() then
        vim.cmd('DiffviewClose')
    else
        vim.cmd('DiffviewOpen')
    end
end

--- Accepts any :DiffviewOpen rev: `HEAD~2`, `d4a7b0d^!`, `main..feature`,
--- `origin/main...HEAD` (merge base).
local function open_rev()
    vim.ui.input({ prompt = 'DiffviewOpen ', default = 'origin/main...HEAD' }, function(rev)
        if rev and rev ~= '' then
            vim.cmd('DiffviewOpen ' .. rev)
        end
    end)
end

local function history_args()
    vim.ui.input({ prompt = 'DiffviewFileHistory ' }, function(args)
        if args and args ~= '' then
            vim.cmd('DiffviewFileHistory ' .. args)
        end
    end)
end

return {
    'sindrets/diffview.nvim',
    lazy = true,
    cmd = {
        'DiffviewOpen',
        'DiffviewClose',
        'DiffviewFileHistory',
        'DiffviewFocusFiles',
        'DiffviewToggleFiles',
        'DiffviewRefresh',
    },
    keys = {
        -- Do not add a bare `<leader>gd` entry: see the note in claudecode.lua.
        { '<leader>gdd', toggle,                                  desc = 'toggle [d]iffview (work tree)' },
        { '<leader>gdq', '<cmd>DiffviewClose<cr>',                desc = '[q]uit diffview' },
        { '<leader>gdr', open_rev,                                desc = 'open at [r]ev/range (prompt)' },
        { '<leader>gdm', '<cmd>DiffviewOpen origin/HEAD...HEAD<cr>', desc = 'diff vs [m]erge base' },
        { '<leader>gds', '<cmd>DiffviewOpen --cached<cr>',        desc = 'diff [s]taged (index vs HEAD)' },
        { '<leader>gdh', '<cmd>DiffviewFileHistory<cr>',          desc = '[h]istory (branch)' },
        { '<leader>gdf', '<cmd>DiffviewFileHistory %<cr>',        desc = 'history of current [f]ile' },
        -- Line-range history (git log -L) for the selection.
        { '<leader>gdf', ":'<,'>DiffviewFileHistory<cr>", mode = 'v', desc = 'history of selected [f]ile lines' },
        { '<leader>gdg', '<cmd>DiffviewFileHistory -g --range=stash<cr>', desc = 'browse stashes' },
        { '<leader>gda', history_args,                            desc = 'history with [a]rgs (prompt)' },
        { '<leader>gdt', '<cmd>DiffviewToggleFiles<cr>',          desc = '[t]oggle file panel' },
    },
    opts = {
        enhanced_diff_hl = true,
        view = {
            merge_tool = {
                layout = 'diff3_mixed',
                disable_diagnostics = true,
            },
        },
        file_panel = {
            listing_style = 'tree',
            win_config = { position = 'left', width = 35 },
        },
        -- Deliberately no `diff_buf_read` hook: diff buffers should inherit
        -- wrap/list/number from settings.lua. Forcing them here breaks wrapping.
    },
}
