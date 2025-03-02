local CcsdsHdr = {}
local utils = require("ccsds-hdr.utils")
local cfg = require("ccsds-hdr.config")

local _ui_elements = {
    {
        n = "enc",
        t = cfg._get("encoder_title"),
        w = 26,
        h = 1,
        i = cfg._get("initial_encoder_vals"),
    },
    {
        n = "dec",
        t = cfg._get("decoder_title"),
        w = 26,
        h = 7,
        i = cfg._get("initial_decoder_vals"),
    },
}

local function create_highlight_group()
    vim.api.nvim_set_hl(0, "CCSDSUpdate", cfg._get("hl_update_color"))
    vim.api.nvim_set_hl(0, "CCSDSErrors", cfg._get("hl_errors_color"))
    vim.api.nvim_set_hl(0, "CCSDSNormal", cfg._get("hl_normal_color"))
    vim.api.nvim_set_hl(0, "CCSDSBorder", cfg._get("hl_border_color"))
end

local function calculate_relative_point(w, h)
    local even_w = (w % 2 ~= 0) and (w + 1) or w
    local even_h = (h % 2 ~= 0) and (h + 1) or h
    local x = (vim.o.columns / 2) - math.floor(even_w / 2)
    local y = (vim.o.lines / 4) + math.floor(even_h / 2)
    return x, y
end

local function create_ccsds_buffers()
    for _, element in ipairs(_ui_elements) do
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(buf, element.n)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
        vim.api.nvim_buf_set_lines(buf, 0, (element.h - 1), false, element.i)
    end
end

local function create_ccsds_windows()
    for _, element in ipairs(_ui_elements) do
        local buf = utils._get_buffer_handle_by_name(element.n)
        -- Calculate the relative point to place the UI
        local x, y = calculate_relative_point(element.w, element.h)
        local win_id = vim.api.nvim_open_win(buf, true, {
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
        vim.api.nvim_win_set_option(win_id, "winhighlight", "FloatBorder:CCSDSBorder")
    end
end

--- Helper function to switch between the encoder buffer or decoder buffer
---
---@usage >lua
---
---   ccsds = require('ccsds-hdr')
---   -- Set a keymapping
---   vim.keymap.set("n", "<leader>cn", ccsds.parser.swap, {
---     noremap = true,
---     silent = true,
---     desc = "ccsds-hdr encode",
---   })
---   -- Call setup
---   ccsds.setup({})
---   -- See readme for more info on passing in a user config
--- <
function CcsdsHdr.swap()
    local curr = vim.api.nvim_get_current_win()
    for _, element in ipairs(_ui_elements) do
        local buf = utils._get_buffer_handle_by_name(element.n)
        local win = utils._get_window_handle_by_buffer(buf)
        if curr ~= win then
            vim.api.nvim_set_current_win(win)
        end
    end
end

--- Helper function to close the tool vs exiting each buffer manually :q!
---
---@usage >lua
---
---   ccsds = require('ccsds-hdr')
---   -- Set a keymapping
---   vim.keymap.set("n", "<leader>cc", ccsds.parser.close, {
---     noremap = true,
---     silent = true,
---     desc = "ccsds-hdr encode",
---   })
---   -- Call setup
---   ccsds.setup({})
---   -- See readme for more info on passing in a user config
--- <
function CcsdsHdr.close()
    for _, element in ipairs(_ui_elements) do
        local buf = utils._get_buffer_handle_by_name(element.n)
        local win = utils._get_window_handle_by_buffer(buf)
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
        if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
        end
    end
end

--- Helper function to pop open the tool.
---
---@usage >lua
---
---   ccsds = require('ccsds-hdr')
---   -- Set a keymapping
---   vim.keymap.set("n", "<leader>co", ccsds.parser.open, {
---     noremap = true,
---     silent = true,
---     desc = "ccsds-hdr encode",
---   })
---   -- Call setup
---   ccsds.setup({})
---   -- See readme for more info on passing in a user config
--- <
function CcsdsHdr.open()
    create_highlight_group()
    create_ccsds_buffers()
    create_ccsds_windows()
    vim.notify("CcsdsHdr initialized, happy encoding/decoding", vim.log.levels.INFO)
end

return CcsdsHdr
