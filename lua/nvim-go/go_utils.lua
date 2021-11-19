local M = {}

function M.get_go_bin()
    local go_bin = vim.fn.system('go env GOBIN')
    if #go_bin == 1 then
        local go_path = vim.fn.system('go env GOPATH')
        go_bin = go_path:sub(1, #go_path - 1) .. '/bin'
    end
    return go_bin
end

return M
