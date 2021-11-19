local query = require'nvim-treesitter.query'
local ts_utils = require'nvim-treesitter.ts_utils'
local lsp = require'nvim-go.lsp'

local M = {}

function M.get_current_parser() 
    return vim.treesitter.get_parser(bufnr, 'go'):parse()[1]
end

-- TODO: Are these actually needed for anything?
function M.get_import_nodes(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local ImportArgument = 'definition.import_path'
    local ImportNamedArgument = 'definition.pkg_identifier'
    local go_query = query.get_query('go', 'nvim-go')

    local nodes = {}
    for id, node in go_query:iter_captures(M.get_current_parser():root(), bufnr) do
        local capture_name = go_query.captures[id]
        if capture_name == ImportArgument or capture_name == ImportNamedArgument then
            table.insert(nodes, node)
        end
    end
    return nodes
end

function M.get_import_package_names(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local nodes = M.get_import_nodes(bufnr)

    local packages = {}
    -- TODO: Named imports
    -- TODO: Remove underscore imports
    -- TODO: dot imports?
    for _, node in pairs(nodes) do
            local import_text = ts_utils.get_node_text(node, bufnr)[1]
            -- Remove quotes
            import_text = import_text:sub(2, #import_text - 1)
            local splits = vim.split(import_text, '/')
            -- get final value
            import_text = splits[#splits]
            table.insert(packages, import_text)
    end
    return packages
end

function M.get_doc()
    local def = lsp.definition_under_cursor()

    vim.api.nvim_command(':vnew')
    lsp.jump(def.range.start.line, def.uri)
end

-- Climbs parents until a specific node type is found, if no node is provided it uses the one at the cursor
function M.climb_until_type(type, node) 
    local cur_node = node or ts_utils.get_node_at_cursor()
    while cur_node ~= nil and cur_node:type() ~= type do
        cur_node = cur_node:parent()
    end
    return cur_node
end

-- Gets the name of the struct that the cursor is in
function M.get_outer_struct_name()
    local node = ts_utils.get_node_at_cursor()
    -- Get the child if we're highlighting on 'type'
    if node:type() == 'type_declaration' then
        if node:child_count() == 2 then
            node = node:child(1)
            if node:type() ~= 'type_spec' then
                return nil
            end
        else
            -- TODO: Should we still just get the first?
            return nil 
        end
    else
        node = M.climb_until_type('type_spec', node)
        if node == nil then
            return nil
        end
    end

    -- TODO: Check for node:named_child('type'):type() == 'struct_type'?
    local name_node = node:named_child('name')
    return ts_utils.get_node_text(name_node)[1]
end

return M
