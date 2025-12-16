-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- TODO: Move lines up/down
--
-- TODO: Remap J/K to something less annoying, esp. J

-- Copy, Paste, Delete, etc.
vim.keymap.set('n', 'x', '"_x', { desc = 'Delete char (w/o copying)' })
vim.keymap.set('v', 'p', '"_d"+Pl', { desc = 'Paste over selection (w/o copying)' })

-- Use Mac Shortcuts (al least in Neovide)
vim.keymap.set({'n','v','i'}, '<D-s>', '<cmd>w<CR>') -- save changes

vim.keymap.set('v', '<D-c>', '"+y')         -- copy selection
vim.keymap.set('n', '<D-c>', '"+yy')        -- copy line
vim.keymap.set('n', '<D-v>', '"+p')         -- paste in normal mode
vim.keymap.set('v', '<D-v>', '"_d"+Pl')     -- paste in visual mode
vim.keymap.set('c', '<D-v>', '<C-R>+')      -- paste in command mode
vim.keymap.set('i', '<D-v>', '<ESC>"+pa')   -- paste in insert mode

-- TODO add Cmd-A for select all. Can it be context aware?

vim.keymap.set({'n','i'}, '<D-z>', '<cmd>undo<CR>')   -- undo
vim.keymap.set({'n','i'}, '<D-Z>', '<cmd>redo<CR>')   -- redo
