local CcsdsHdr = {}

function CcsdsHdr._is_valid_ccsds_hdr_cfgkey(tbl, key)
    if type(tbl) ~= "table" or type(key) ~= "string" then
        error("TypeError, tbl must be a table and key must be a string")
    end
    for k in key:gmatch("[^.]+") do
        tbl = tbl[k]
        if tbl == nil then
            error("Error, key '" .. k .. "' does not exist.")
        end
    end
    return tbl
end

function CcsdsHdr._get_buffer_handle_by_name(buffer_name)
    if type(buffer_name) ~= "string" or buffer_name == "" then
        error("ValueError, buffer_name must be a non-empty string")
    end
    local buf = vim.fn.bufnr(buffer_name)
    if buf == -1 then
        error("Error, retrieving valid buffer")
    end
    return buf
end

function CcsdsHdr._get_window_handle_by_buffer(buffer_handle)
    if type(buffer_handle) ~= "number" or buffer_handle < 0 then
        error("ValueError, invalid buffer handle not a positive number")
    end
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == buffer_handle then
            return win
        end
    end
    error("No window found displaying buffer handle")
end

function CcsdsHdr._process_encoded_input(user_input, valid_length)
    if type(user_input) ~= "table" then
        error("TypeError, user_input must be a table")
    end
    if valid_length and type(valid_length) ~= "number" then
        error("TypeError, number must be a number")
    end
    if #user_input ~= 1 then
        error("ValueError, the encoded buffer should only be length of 1")
    end
    -- scrubbed:gsub only works on evens, also make arg optional
    valid_length = valid_length or 12
    if valid_length % 2 ~= 0 then
        error("ValueError, valid_length must be even for gsub to work")
    end

    -- ensure gsub produces expected length
    local scrubbed = user_input[1]:gsub("[,%s]", "")
    if #scrubbed ~= valid_length then
        error("ValueError, unexpected length mismatch from gsub, check input")
    end
    local hextable = {}
    scrubbed:gsub("%x%x", function(byte)
        table.insert(hextable, tonumber(byte, 16))
    end)
    -- ensuring that we got the expected number of bytes
    if #hextable ~= (valid_length / 2) then
        error("Error, failed to read buffer because you mucked it up")
    end
    return hextable
end

function CcsdsHdr._process_decoded_input(user_input, valid_length)
    if type(user_input) ~= "table" then
        error("TypeError, user_input must be a table")
    end
    if valid_length and type(valid_length) ~= "number" then
        error("TypeError, valid_length must be a number")
    end
    -- support different lengths so we can test this better
    valid_length = valid_length or 7
    if #user_input ~= valid_length then
        error("ValueError, valid_length does not match length of user_input")
    end
    local numtable = {}
    for _, line in ipairs(user_input) do
        local val = line:match("(0x[%da-fA-F]+)$") or line:match("(%d+)$")
        local tmp = val:find("^0x") and tonumber(val, 16) or tonumber(val)
        table.insert(numtable, tmp)
    end
    return numtable
end

function CcsdsHdr._validate_field_values(fields, values)
    if type(fields) ~= "table" or type(values) ~= "table" then
        error("TypeError, both args must be a table")
    end
    if #fields ~= #values then
        error("ValueError, both args must be tables of the same length")
    end
    local errors_are = {}
    local found_errors = false
    for i, v in ipairs(values) do
        local min = fields[i].rng[1]
        local max = fields[i].rng[2]
        if min > v or max < v then
            -- i relates to line of error, keep it all 0-based
            table.insert(errors_are, i)
            found_errors = true
        end
    end
    return found_errors, errors_are
end

function CcsdsHdr._calculate_diffs_over_lines(prev, curr)
    if type(prev) ~= "table" or type(curr) ~= "table" then
        error("TypeError, types of args must be of table")
    end
    if #prev ~= #curr then
        error("ValueError, tables must be of same length")
    end
    diffs = {}
    found = false
    for i, line in ipairs(prev) do
        local sub_table = {}
        local curr_line = curr[i]
        local smallest_line = math.min(#curr_line, #line)
        for j = 1, smallest_line do
            if curr_line:sub(j, j) ~= line:sub(j, j) then
                table.insert(sub_table, j)
                found = true
            end
        end
        table.insert(diffs, sub_table)
    end
    return found, diffs
end

function CcsdsHdr._apply_highlights_on_columns(buf, found_diffs, diffs_are)
    if type(found_diffs) ~= "boolean" then
        error("TypeError, found_diffs must be a boolean")
    end
    if found_diffs then
        if type(diffs_are) ~= "table" then
            error("TypeError, diffs_are must be a table")
        end
        for index, line in ipairs(diffs_are) do
            for _, col in ipairs(line) do
                vim.api.nvim_buf_add_highlight(buf, 0, "CCSDSUpdate", index - 1, col - 1, col)
            end
        end
    end
end

function CcsdsHdr._apply_highlights_on_lines(buf, found_errors, errors_are)
    if type(found_errors) ~= "boolean" then
        error("TypeError, found_errors must be a boolean")
    end
    if found_errors then
        if type(errors_are) ~= "table" then
            error("TypeError, errors_are must be a table")
        end
        for _, line in ipairs(errors_are) do
            -- ensure line is 0-based
            vim.api.nvim_buf_add_highlight(buf, 0, "CCSDSErrors", line - 1, 0, -1)
        end
    end
end

function CcsdsHdr._reset_highlights_on_lines(buf, number_of_lines)
    if type(number_of_lines) ~= "number" then
        error("TypeError, number_of_lines must be a integer")
    end
    for i = 0, 7 do
        vim.api.nvim_buf_add_highlight(buf, 0, "CCSDSNormal", i, 0, -1)
    end
end

return CcsdsHdr
