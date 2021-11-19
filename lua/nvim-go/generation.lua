local ts = require'nvim-go.treesitter'
local ts_utils = require'nvim-treesitter.ts_utils'
local Job = require'plenary.job'
local go_utils = require'nvim-go.go_utils'
local api = vim.api

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
            -- TODO: Handle errors
            lines = j:result()
        end,
    }):sync()
    M.append_to_buffer(lines)
end

-- Insert text at the bottom of the current buffer
function M.append_to_buffer(text_lines)
    -- Only append if not empty
    if next(text_lines) ~= nil then
        table.insert(text_lines, 1, "")
        api.nvim_buf_set_lines(0, -1, -1, true, text_lines)
    end
end

-- TODO: Just use https://github.com/fatih/gomodifytags instead?
function M.add_struct_tag(tag_name)
    -- TODO: Configurable default?
    tag_name = tag_name or 'json'
    local struct_node = ts.get_outer_struct_node()
    local struct_fields = ts.get_struct_fields(struct_node)
    local struct_start_row, _, struct_end_row, _ = struct_node:range()
    local field_lines = api.nvim_buf_get_lines(0, struct_start_row + 1, struct_end_row, true)

    for idx, node in pairs(struct_fields) do
        local tag_node = node:field('tag')[1]
        -- TODO: De-camelcase
        local field_name = ts_utils.get_node_text(node:named_child('name'))[1]
        local field_text = field_lines[idx]
        if tag_node == nil then
            -- TODO: if ends in a comment, we can't append to the end
            -- TODO: omitempty?
            field_lines[idx] = field_text .. string.format(' `%s:"%s"`', tag_name, field_name)
        else
            -- TODO: check if tag already exists?
            local _, tag_start, _, tag_end = tag_node:range()
            local existing_tag = field_text:sub(tag_start, tag_end)
            local before_tag = field_text:sub(1, tag_start)
            local after_tag = field_text:sub(tag_end + 1, -1)
            field_lines[idx] = before_tag .. existing_tag:sub(1, -2) .. string.format(' %s:"%s"`', tag_name, field_name) .. after_tag
        end
    end
    -- TODO: Only set if something has changed
    api.nvim_buf_set_lines(0, struct_start_row + 1, struct_end_row, true, field_lines)
end

function M.remove_struct_tag(tag_name)
end

return M
