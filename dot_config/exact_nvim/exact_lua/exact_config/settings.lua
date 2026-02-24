-- Neovide GUI config
if vim.g.neovide then
    -- Set font 
    vim.o.guifont = 'JetBrainsMono Nerd Font:h14'

    -- Disable animations
    vim.g.neovide_position_animation_length = 0
    vim.g.neovide_scroll_animation_length = 0
    vim.g.neovide_cursor_animation_length = 0
    vim.g.neovide_cursor_short_animation_length = 0

    -- TODO: Decide if you like opacity or not
    --
    -- vim.g.neovide_opacity = 0.9
    -- vim.g.neovide_window_blurred = true

    -- Proposed temp fix for high GPU usage
    vim.g.neovide_show_border = true

    -- Set left option key to meta (keep right one for special character input)
    vim.g.neovide_input_macos_option_key_is_meta = 'only_left'
end

-- Loosely based on kickstart.nvim

-- Enable line numbers
vim.o.number = true
vim.o.relativenumber = true

-- Always show sign column
vim.o.signcolumn = 'yes'

-- Highlight the current line
vim.o.cursorline = true

-- Keep at least this many lines from edge
vim.o.scrolloff = 10

-- Don't show mode in cmd line
vim.o.showmode = false

-- Enable mouse
vim.o.mouse = 'a'

-- Configure tab width
vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4

-- Show whitespace 
vim.o.list = true
vim.opt.listchars = { tab = '» ', space = '·', nbsp = '␣' }

-- Indent wrapped lines
vim.o.breakindent = true
vim.o.showbreak = ' '
vim.opt.breakindentopt = { list = -1, sbr = true }

-- Default window splits: below & right
vim.o.splitbelow = true
vim.o.splitright = true

-- Smart-case search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Preview substitutions incrementally
vim.o.inccommand = 'split'

-- Sync with system clipboard
vim.o.clipboard = "unnamedplus"

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Raise dialog to confirm insdead of failing
vim.o.confirm = true
