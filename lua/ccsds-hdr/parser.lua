local CcsdsHdr = {}
local bit = require("bit")
local utils = require("ccsds-hdr.utils")

local _lookup = {
    { str = "Packet Version: %d", rng = { 0, 0 } },
    { str = "Packet Type: %d", rng = { 0, 1 } },
    { str = "Secondary Header: %d", rng = { 0, 1 } },
    { str = "Application ID: %d", rng = { 0, ((2 ^ 11) - 1) } },
    { str = "Sequence Flag: %d", rng = { 0, ((2 ^ 2) - 1) } },
    { str = "Sequence Count: %d", rng = { 0, ((2 ^ 14) - 1) } },
    { str = "Data Length: %d", rng = { 0, ((2 ^ 16) - 1) } },
}

--- Decodes 6 CCSDS bytes from a primary header into fields
---@param bytes table The 6 bytes of primary CCSDS header
---@return table The 7 CCSDS fields decoded
---
---@usage >lua
---
---   parse = require('ccsds-hdr.parser')
---   local fields = parse._decode({0x0A, 0x0B, 0xC4, 0x01, 0x37, 0x9A})
--- <
function CcsdsHdr._decode(bytes)
    local word1 = bit.bor(bit.lshift(bytes[1], 8), bytes[2])
    local word2 = bit.bor(bit.lshift(bytes[3], 8), bytes[4])
    local word3 = bit.bor(bit.lshift(bytes[5], 8), bytes[6])
    return {
        bit.band(bit.rshift(word1, 13), 0x07),
        bit.band(bit.rshift(word1, 12), 0x01),
        bit.band(bit.rshift(word1, 11), 0x01),
        bit.band(bit.rshift(word1, 0), 0x7FF),
        bit.band(bit.rshift(word2, 14), 0x03),
        bit.band(bit.rshift(word2, 0), 0x3FFF),
        bit.band(bit.rshift(word3, 0), 0xFFFF),
    }
end

--- Encodes 7 CCSDS fields into a 6 byte primary header
---@param values table The 7 CCSDS fields
---@return table The 6 bytes CCSDS primary header
---
---@usage >lua
---
---   parse = require('ccsds-hdr.parser')
---   local bytes = parse._encode({0, 0, 1, 0x20B, 3, 1025, 14234})
--- <
function CcsdsHdr._encode(values)
    return {
        bit.bor(
            bit.lshift(values[1], 5),
            bit.lshift(values[2], 4),
            bit.lshift(values[3], 3),
            bit.rshift(values[4], 8)
        ),
        bit.band(values[4], 0xFF),
        bit.bor(bit.lshift(values[5], 6), bit.rshift(values[6], 8)),
        bit.band(values[6], 0xFF),
        bit.rshift(values[7], 8),
        bit.band(values[7], 0xFF),
    }
end

--- Sets up animation for errors/diffs during decoding
---
---@usage >lua
---
---   ccsds = require('ccsds-hdr')
---   -- Set a keymapping
---   vim.keymap.set("n", "<leader>cd", ccsds.parser.animate_decode, {
---     noremap = true,
---     silent = true,
---     desc = "ccsds-hdr decode",
---   })
---   -- Call setup
---   ccsds.setup({})
---   -- See readme for more info on passing in a user config
--- <
function CcsdsHdr.animate_decode()
    local ebuf = utils._get_buffer_handle_by_name("enc")
    local dbuf = utils._get_buffer_handle_by_name("dec")
    local prev = vim.api.nvim_buf_get_lines(dbuf, 0, -1, false)
    local buff = vim.api.nvim_buf_get_lines(ebuf, 0, 1, false)
    local vals = CcsdsHdr._decode(utils._process_encoded_input(buff))

    vim.api.nvim_buf_clear_namespace(dbuf, 0, 0, -1)
    vim.api.nvim_buf_clear_namespace(ebuf, 0, 0, -1)
    local found_errors, errors_are = utils._validate_field_values(_lookup, vals)

    local output = {}
    for i, v in ipairs(vals) do
        table.insert(output, string.format(_lookup[i].str, v))
    end

    vim.api.nvim_buf_set_lines(dbuf, 0, -1, false, {})
    vim.api.nvim_buf_set_lines(dbuf, 0, 6, false, output)

    if not found_errors then
        local found_diffs, diffs_are = utils._calculate_diffs_over_lines(prev, output)
        utils._apply_highlights_on_columns(dbuf, found_diffs, diffs_are)
    else
        vim.notify("Error in CCSDS packet, try again", vim.log.levels.ERROR)
        utils._apply_highlights_on_lines(dbuf, found_errors, errors_are)
    end
end

--- Sets up animation for errors/diffs during encoding
---
---@usage >lua
---
---   ccsds = require('ccsds-hdr')
---   -- Set a keymapping
---   vim.keymap.set("n", "<leader>ce", ccsds.parser.animate_encode, {
---     noremap = true,
---     silent = true,
---     desc = "ccsds-hdr encode",
---   })
---   -- Call setup
---   ccsds.setup({})
---   -- See readme for more info on passing in a user config
--- <
function CcsdsHdr.animate_encode()
    local dbuf = utils._get_buffer_handle_by_name("dec")
    local ebuf = utils._get_buffer_handle_by_name("enc")
    local prev = vim.api.nvim_buf_get_lines(ebuf, 0, 1, false)
    local buff = vim.api.nvim_buf_get_lines(dbuf, 0, -1, false)
    local vals = utils._process_decoded_input(buff)

    vim.api.nvim_buf_clear_namespace(dbuf, 0, 0, -1)
    vim.api.nvim_buf_clear_namespace(ebuf, 0, 0, -1)
    local found_errors, errors_are = utils._validate_field_values(_lookup, vals)

    if not found_errors then
        local byte_vals_as_str_tbl = {}
        for _, byte in ipairs(CcsdsHdr._encode(vals)) do
            table.insert(byte_vals_as_str_tbl, string.format("%02X", byte))
        end
        local curr = { table.concat(byte_vals_as_str_tbl, " ") }

        vim.api.nvim_buf_set_lines(ebuf, 0, -1, false, {})
        vim.api.nvim_buf_set_lines(ebuf, 0, -1, false, curr)

        local found_diffs, diffs_are = utils._calculate_diffs_over_lines(prev, curr)
        utils._apply_highlights_on_columns(ebuf, found_diffs, diffs_are)
        utils._reset_highlights_on_lines(dbuf, #_lookup)
    else
        vim.notify("Error in CCSDS packet, try again", vim.log.levels.ERROR)
        utils._apply_highlights_on_lines(dbuf, found_errors, errors_are)
    end
end

return CcsdsHdr
