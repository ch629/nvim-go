local ts = require'nvim-go.treesitter'
local Job = require'plenary.job'
local go_utils = require'nvim-go.go_utils'

local M = {}

-- Generate method stubs for implementing an interface https://github.com/josharian/impl
-- TODO: Interface name completion
-- TODO: Telescope interfaces - all interfaces in a package??
function M.impl(iface) 
    local struct_name = ts.get_outer_struct_name()
    if struct_name == '' or struct_name == nil then
        return
    end

    local go_bin = go_utils.get_go_bin()
    local receiver_name = struct_name:sub(1, 1):lower()

    local lines = {}
    Job:new({
        command = 'impl',
        args = {
            string.format("%s *%s", receiver_name, struct_name), 
            iface,
        },
        cwd = go_bin,
        on_exit = function(j, return_val)
            lines = j:result()
        end,
    }):sync()
    M.append_to_buffer(lines)
end

-- Insert text at the bottom of the current buffer
function M.append_to_buffer(text_lines)
    table.insert(text_lines, 1, "")
    vim.api.nvim_buf_set_lines(0, -1, -1, true, text_lines)
end

return M
