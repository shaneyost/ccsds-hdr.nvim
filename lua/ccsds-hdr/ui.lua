local utils = require("ccsds-hdr.utils")
local M = {}

local _ui_elements = {
    {
        n = "enc",
        t = "Encoded (Base16)",
        w = 26,
        h = 1,
        i = {
            string.format("00 00 00 00 00 00"),
        },
    },
    {
        n = "dec",
        t = "Decoded (Base10)",
        w = 26,
        h = 7,
        i = {
            string.format("Packet Version: 0"),
            string.format("Packet Type: 0"),
            string.format("Secondary Header: 0"),
            string.format("Application ID: 0"),
            string.format("Sequence Flags: 0"),
            string.format("Sequence Count: 0"),
            string.format("Data Length: 0"),
        },
    },
}

local function calculate_relative_point(w, h)
    local even_w = (w % 2 ~= 0) and (w + 1) or w
    local even_h = (h % 2 ~= 0) and (h + 1) or h
    local x = (vim.o.columns / 2) - math.floor(even_w / 2)
    local y = (vim.o.lines / 4) + math.floor(even_h / 2)
    return x, y
end

function M.create_ccsds_buffers()
    for _, element in ipairs(_ui_elements) do
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(buf, element.n)
        -- initialize buffers w/ a template
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
        vim.api.nvim_buf_set_lines(buf, 0, (element.h - 1), false, element.i)
    end
end

function M.create_ccsds_windows()
    for _, element in ipairs(_ui_elements) do
        local buf = utils.get_buffer_handle_by_name(element.n)
        -- Calc. the relative point to place our ui
        local x, y = calculate_relative_point(element.w, element.h)
        vim.api.nvim_open_win(buf, true, {
            relative = "editor",
            width = element.w,
            height = element.h,
            row = y,
            col = x,
            style = "minimal",
            border = "rounded",
            title = element.t,
            title_pos = "center",
        })
    end
end

function M.focus_next_window()
    local curr = vim.api.nvim_get_current_win()
    for _, element in ipairs(_ui_elements) do
        local buf = utils.get_buffer_handle_by_name(element.n)
        local win = utils.get_window_handle_by_buffer(buf)
        if curr ~= win then
            vim.api.nvim_set_current_win(win)
        end
    end
end

function M.close_all_windows()
    for _, element in ipairs(_ui_elements) do
        local buf = utils.get_buffer_handle_by_name(element.n)
        local win = utils.get_window_handle_by_buffer(buf)
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
        if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
        end
    end
end

function M.setup()
    M.create_ccsds_buffers()
    M.create_ccsds_windows()
end

return M
