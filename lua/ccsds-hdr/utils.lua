local M = {}
function M.is_valid_ccsds_hdr_cfgkey(tbl, key)
    if type(tbl) ~= "table" or type(key) ~= "string" then
        error("Invalid arguments detected, check args")
    end
    for k in key:gmatch("[^.]+") do
        tbl = tbl[k]
        if tbl == nil then
            error("Invalid key: Key '" .. k .. "' does not exist.")
        end
    end
    return tbl
end

function M.is_valid_ccsds_hdr_keymap(mode, lhs, desc)
    if type(mode) ~= "string" or type(lhs) ~= "string" or type(desc) ~= "string" then
        error("Invalid arguments detected, args must be strings")
    end
    local registered = {}
    local maps = vim.api.nvim_get_keymap(mode)
    local converted_lhs = vim.api.nvim_replace_termcodes(lhs, true, true, true)
    for _, map in pairs(maps) do
        if map.lhs == converted_lhs and map.desc == desc then
            table.insert(registered, map)
        end
    end
    if #registered == 0 then
        error("Invalid map: Map not found")
    end
    return registered
end

function M.get_buffer_handle_by_name(buffer_name)
    if type(buffer_name) ~= "string" or buffer_name == "" then
        error("Invalid buffer name: expected a non-empty string")
    end
    local buf = vim.fn.bufnr(buffer_name)
    if buf == -1 then
        error("Error, in retrieving valid buffer")
    end
    return buf
end

function M.get_window_handle_by_buffer(buffer_handle)
    if type(buffer_handle) ~= "number" or buffer_handle < 0 then
        error("Invalid buffer handle: expected a positive number")
    end
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == buffer_handle then
            return win
        end
    end
    error("No window found displaying buffer handle")
end

function M.process_encoded_input(user_input, valid_length)
    if type(user_input) ~= "string" then
        error("Invalid argument, arg must be a string")
    end
    if valid_length and type(valid_length) ~= "number" then
        error("Invalid argument, arg must be a number")
    end
    -- scrubbed:gsub only works on evens, also make arg optional
    valid_length = valid_length or 12
    if valid_length % 2 ~= 0 then
        error("Invalid argument, arg must be even")
    end
    -- ensure gsub produces expected length
    local scrubbed = user_input:gsub("[,%s]", "")
    if #scrubbed ~= valid_length then
        error("Unexpected length mismatch, check input")
    end
    local hextable = {}
    scrubbed:gsub("%x%x", function(byte)
        table.insert(hextable, tonumber(byte, 16))
    end)
    -- ensuring that we got the expected number of bytes
    if #hextable ~= (valid_length / 2) then
        error("Error, failed to convert input to hex")
    end
    return hextable
end

function M.process_decoded_input(user_input)
    if type(user_input) ~= "table" then
        error("Invalid argument, arg must be a table of strings")
    end
    if #user_input ~= 7 then
        error("Invalid argument, only 7 fields in a CCSDS header")
    end
    local numtable = {}
    for _, line in ipairs(user_input) do
        local val = line:match("(0x[%da-fA-F]+)$") or line:match("(%d+)$")
        local tmp = val:find("^0x") and tonumber(val, 16) or tonumber(val)
        table.insert(numtable, tmp)
    end
    return numtable
end

function M.validate_range_on_field(value, range, fieldstr)
    if type(value) ~= "number" then
        error("Invalid argument, arg must be a number")
    end
    if type(range) ~= "table" or #range ~= 2 then
        error("Invalid argument, arg must be a table of size 2")
    end
    fieldstr = fieldstr or "%d"
    local min = range[1]
    local max = range[2]
    if min > value or max < value then
        local message = fieldstr .. " out of range, {%d, %d}"
        error(string.format(message, value, min, max))
    end
end

return M
