local bit = require("bit")
local utils = require("ccsds-hdr.utils")
local M = {}

local _fields = {
    {
        str = "Packet Version: %d",
        val = 0,
        rng = { 0, 0 },
        word_to_field = function(self, w)
            self.val = bit.band(bit.rshift(w, 13), 0x07)
        end,
    },
    {
        str = "Packet Type: %d",
        val = 0,
        rng = { 0, 1 },
        word_to_field = function(self, w)
            self.val = bit.band(bit.rshift(w, 12), 0x01)
        end,
    },
    {
        str = "Secondary Header: %d",
        val = 0,
        rng = { 0, 1 },
        word_to_field = function(self, w)
            self.val = bit.band(bit.rshift(w, 11), 0x01)
        end,
    },
    {
        str = "Application ID: %d",
        val = 0,
        rng = { 0, ((2 ^ 11) - 1) },
        word_to_field = function(self, w)
            self.val = bit.band(bit.rshift(w, 0), 0x7FF)
        end,
    },
    {
        str = "Sequence Flag: %d",
        sft = 14,
        msk = 0x0003,
        val = 0,
        rng = { 0, ((2 ^ 2) - 1) },
        word_to_field = function(self, w)
            self.val = bit.band(bit.rshift(w, 14), 0x03)
        end,
    },
    {
        str = "Sequence Count: %d",
        val = 0,
        rng = { 0, ((2 ^ 14) - 1) },
        word_to_field = function(self, w)
            self.val = bit.band(bit.rshift(w, 0), 0x3FFF)
        end,
    },
    {
        str = "Data Length: %d",
        val = 0,
        rng = { 0, ((2 ^ 16) - 1) },
        word_to_field = function(self, w)
            self.val = bit.band(bit.rshift(w, 0), 0xFFFF)
        end,
    },
}

function M.decode_header()
    local ebuf = utils.get_buffer_handle_by_name("enc")
    local dbuf = utils.get_buffer_handle_by_name("dec")

    local buff = vim.api.nvim_buf_get_lines(ebuf, 0, 1, false)
    local bytes = utils.process_encoded_input(buff[1])

    -- CCSDS fields are word aligned, easier to convert words to fields than bytes to fields
    local word1 = bit.bor(bit.lshift(bytes[1], 8), bytes[2])
    local word2 = bit.bor(bit.lshift(bytes[3], 8), bytes[4])
    local word3 = bit.bor(bit.lshift(bytes[5], 8), bytes[6])

    -- Create array of words that map to each field then extract field from word and validate
    local words = { word1, word1, word1, word1, word2, word2, word3 }
    for i, f in ipairs(_fields) do
        f:word_to_field(words[i])
        utils.validate_range_on_field(f.val, f.rng, f.str)
    end

    local output = {}
    for i, _ in ipairs(_fields) do
        table.insert(output, string.format(_fields[i].str, _fields[i].val))
    end
    vim.api.nvim_buf_set_lines(dbuf, 0, -1, false, {})
    vim.api.nvim_buf_set_lines(dbuf, 0, 6, false, output)
end

function M.encode_header()
    local ebuf = utils.get_buffer_handle_by_name("enc")
    local dbuf = utils.get_buffer_handle_by_name("dec")

    local buff = vim.api.nvim_buf_get_lines(dbuf, 0, -1, false)
    local vals = utils.process_decoded_input(buff)

    -- Initialize all fields first then validate (consistency w/ decode_header())
    for i, f in ipairs(_fields) do
        f.val = vals[i]
        utils.validate_range_on_field(f.val, f.rng, f.str)
    end

    -- Quicker/Easier to convert fields -> bytes versus fields -> words -> bytes
    local bytes = {
        -- byte 1
        bit.bor(
            bit.lshift(_fields[1].val, 5),
            bit.lshift(_fields[2].val, 4),
            bit.lshift(_fields[3].val, 3),
            bit.rshift(_fields[4].val, 8)
        ),
        -- byte 2
        bit.band(_fields[4].val, 0xFF),
        -- byte 3
        bit.bor(bit.lshift(_fields[5].val, 6), bit.rshift(_fields[6].val, 8)),
        -- byte 4
        bit.band(_fields[6].val, 0xFF),
        -- byte 5
        bit.rshift(_fields[7].val, 8),
        -- byte 6
        bit.band(_fields[7].val, 0xFF),
    }

    local output = {}
    for _, v in ipairs(bytes) do
        table.insert(output, string.format("%02X", v))
    end
    vim.api.nvim_buf_set_lines(ebuf, 0, -1, false, {})
    vim.api.nvim_buf_set_lines(ebuf, 0, -1, false, { table.concat(output, " ") })
end

return M
