-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
    callback = function()
        vim.hl.on_yank()
    end,
})

-- Pick up files edited outside Neovim (Claude Code, git checkouts, rebases).
-- `autoread` doesn't notice changes while you sit in a buffer, so poll with
-- `checktime` -- otherwise the buffer goes stale while the LSP reports
-- diagnostics against the new on-disk contents.
local autoread = vim.api.nvim_create_augroup('auto-read-changed', { clear = true })
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI', 'TermLeave' }, {
    desc = 'Check for external file changes',
    group = autoread,
    callback = function(ctx)
        -- Skip special buffers (terminals, pickers, diffview panels) and the
        -- command-line window, where :checktime is invalid.
        if vim.bo[ctx.buf].buftype ~= '' or vim.fn.getcmdwintype() ~= '' then
            return
        end
        vim.cmd.checktime({ mods = { emsg_silent = true } })
    end,
})

vim.api.nvim_create_autocmd('FileChangedShellPost', {
    desc = 'Report when a buffer was reloaded from disk',
    group = autoread,
    callback = function()
        vim.notify('Buffer reloaded (changed on disk)', vim.log.levels.INFO)
    end,
})
