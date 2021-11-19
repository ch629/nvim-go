local lsp = vim.lsp

local M = {}

function M.jump(row, file)
    lsp.util.jump_to_location({
        range = {
            start = {
                character = 0,
                line = row,
            },
        },
        uri = file,
    })
end


-- Returns:
-- {
--     range = {
--         end = {
--             character = 19,
--             line = 105
--         },
--         start = {
--             character = 5,
--             line = 105
--         }
--     },
--     uri = "file:///home/charlie/go/pkg/mod/go.uber.org/zap@v1.19.1/logger.go"
-- }
function M.definition_under_cursor(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    return lsp.buf_request_sync(bufnr, "textDocument/definition", lsp.util.make_position_params(), 1000)[1].result[1]
end

return M
