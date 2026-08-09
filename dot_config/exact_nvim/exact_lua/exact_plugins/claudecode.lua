-- Claude Code IDE integration: nvim runs the server, the external `claude` CLI
-- connects to it. https://github.com/coder/claudecode.nvim

-- Global because 'operatorfunc' takes a Vimscript expression string.
function _G.ClaudeCodeSendOperator()
    local file = vim.api.nvim_buf_get_name(0)
    if file == '' then
        vim.notify('ClaudeCode: buffer has no file to reference', vim.log.levels.WARN)
        return
    end
    local first = vim.api.nvim_buf_get_mark(0, '[')[1]
    local last = vim.api.nvim_buf_get_mark(0, ']')[1]
    -- send_at_mention takes 0-indexed lines.
    local ok = require('claudecode').send_at_mention(file, first - 1, last - 1, 'operator')
    if ok then
        vim.notify(('Claude: @%s#%d-%d'):format(vim.fn.fnamemodify(file, ':t'), first, last))
    end
end

-- Must be used with `expr = true`. Feeding `g@` via nvim_feedkeys appends it
-- after the already-typed motion, which silently swallows the motion.
local function start_operator(keys)
    return function()
        vim.o.operatorfunc = 'v:lua.ClaudeCodeSendOperator'
        return keys
    end
end

return {
    'coder/claudecode.nvim',
    -- Must not be lazy-loaded on cmd/keys: an external CLI can only discover
    -- this instance if the server is already running.
    event = 'VeryLazy',
    cmd = {
        'ClaudeCodeStart',
        'ClaudeCodeStop',
        'ClaudeCodeStatus',
        'ClaudeCodeSend',
        'ClaudeCodeAdd',
        'ClaudeCodeTreeAdd',
        'ClaudeCodeDiffAccept',
        'ClaudeCodeDiffDeny',
        'ClaudeCodeCloseAllDiffs',
    },
    keys = {
        -- Do not add a bare `<leader>a` entry: a `keys` entry without a rhs still
        -- registers a lazy-load mapping on the prefix, costing a `timeoutlen`
        -- pause on every `<leader>a…` sequence. Group label is in whichkey.lua.
        { '<leader>as', '<cmd>ClaudeCodeSend<cr>',          mode = 'v', desc = '[s]end selection to Claude' },
        { '<leader>as',  start_operator('g@'),  expr = true, desc = '[s]end {motion} to Claude' },
        { '<leader>ass', start_operator('g@_'), expr = true, desc = '[s]end current line to Claude' },
        { '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>',         desc = 'add current [b]uffer' },
        { '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>',    desc = '[a]ccept diff' },
        { '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>',      desc = '[d]eny diff' },
        { '<leader>ax', '<cmd>ClaudeCodeCloseAllDiffs<cr>', desc = 'close all diffs' },
        { '<leader>ai', '<cmd>ClaudeCodeStatus<cr>',        desc = 'connection [i]nfo' },
        { '<leader>aS', '<cmd>ClaudeCodeStart<cr>',         desc = '[S]tart server' },
        { '<leader>aQ', '<cmd>ClaudeCodeStop<cr>',          desc = '[Q]uit server' },
    },
    opts = {
        terminal = {
            -- Makes :ClaudeCode/Open/Close/Focus no-ops, hence unmapped above.
            provider = 'none',
        },
        focus_after_send = false,
        -- Every instance advertises a lock file; `claude --ide` only auto-connects
        -- when exactly one is up. Set false to start manually (<leader>aS).
        auto_start = true,
        diff_opts = {
            layout = 'vertical',
            auto_resize_terminal = false,
        },
    },
}
