return {
    'folke/snacks.nvim',
    priority = 999,
    lazy = false,
    ---@module 'snacks'
    ---@type snacks.Config
    opts = {
        picker = {
            enabled = true,
            matcher = {
                frecency = true,
            },
        },
        input = { enabled = true },
        notifier = {
            enabled = true,
            top_down = false,
            timeout = 2500,
            style = 'minimal',
            padding = true,
            config = function ()
                -- Fancy LSP loading notification
                -- Copied from https://github.com/folke/snacks.nvim/blob/bfe8c26dbd83f7c4fbc222787552e29b4eccfcc0/docs/notifier.md#-examples
                ---@type table<number, {token:lsp.ProgressToken, msg:string, done:boolean}[]>
                local progress = vim.defaulttable()
                vim.api.nvim_create_autocmd("LspProgress", {
                    ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
                    callback = function(ev)
                    local client = vim.lsp.get_client_by_id(ev.data.client_id)
                    local value = ev.data.params.value --[[@as {percentage?: number, title?: string, message?: string, kind: "begin" | "report" | "end"}]]
                    if not client or type(value) ~= "table" then
                        return
                    end
                    local p = progress[client.id]

                    for i = 1, #p + 1 do
                        if i == #p + 1 or p[i].token == ev.data.params.token then
                        p[i] = {
                            token = ev.data.params.token,
                            msg = ("[%3d%%] %s%s"):format(
                              value.kind == "end" and 100 or value.percentage or 100,
                                value.title or "",
                                value.message and (" **%s**"):format(value.message) or ""
                            ),
                            done = value.kind == "end",
                        }
                        break
                      end
                    end

                    local msg = {} ---@type string[]
                    progress[client.id] = vim.tbl_filter(function(v)
                        return table.insert(msg, v.msg) or not v.done
                    end, p)

                    local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
                    vim.notify(table.concat(msg, "\n"), "info", {
                        id = "lsp_progress",
                        title = client.name,
                        opts = function(notif)
                            notif.icon = #progress[client.id] == 0 and " "
                                or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
                        end,
                    })
                  end,
                })
            end
        }
    },
    keys = {
        -- { '<leader>fb', function() Snacks.picker.buffers() end, desc = "[b]uffers" },
        -- { '<leader>ff', function() Snacks.picker.files() end, desc = "[f]iles" },
        -- -- TODO: Reconsider - the picker is kinda meh...
        -- { '<leader>fz', function() Snacks.picker.zoxide() end, desc = "[z]oxide" }, -- TODO: Easier shortcut?
        -- { '<leader>fh', function() Snacks.picker.help() end, desc = "[h]elp" },
        -- { '<leader>/', function() Snacks.picker.grep() end, desc = "Grep" },
    },
}
