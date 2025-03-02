local bit = require("bit")
local utils = require("ccsds-hdr.utils")
local parser = require("ccsds-hdr.parser")

describe("parser._decode", function()
    local _lookup = {
        { name = "Packet Version", idx = 1, shift = 13, mask = 0x07, rng = { 0, 0 } },
        { name = "Packet Type", idx = 2, shift = 12, mask = 0x01, rng = { 0, 1 } },
        { name = "Secondary Header", idx = 3, shift = 11, mask = 0x01, rng = { 0, 1 } },
        { name = "Application ID", idx = 4, shift = 0, mask = 0x7FF, rng = { 0, (2 ^ 11 - 1) } },
        { name = "Sequence Flag", idx = 5, shift = 14, mask = 0x03, rng = { 0, 3 } },
        { name = "Sequence Count", idx = 6, shift = 0, mask = 0x3FFF, rng = { 0, (2 ^ 14 - 1) } },
        { name = "Data Length", idx = 7, shift = 0, mask = 0xFFFF, rng = { 0, (2 ^ 16 - 1) } },
    }
    for _, field in ipairs(_lookup) do
        it("should correctly decode " .. field.name .. " for all valid values", function()
            local bytes = { 0, 0, 0, 0, 0, 0 }
            for val = field.rng[1], field.rng[2] do
                bytes = { unpack({ 0, 0, 0, 0, 0, 0 }) }
                if field.idx == 1 then
                    bytes[1] = bit.bor(bit.band(bytes[1], 0x1F), bit.lshift(val, 5))
                elseif field.idx == 2 then
                    bytes[1] = bit.bor(bit.band(bytes[1], 0xEF), bit.lshift(val, 4))
                elseif field.idx == 3 then
                    bytes[1] = bit.bor(bit.band(bytes[1], 0xF7), bit.lshift(val, 3))
                elseif field.idx == 4 then
                    bytes[1] = bit.bor(bit.band(bytes[1], 0xF8), bit.rshift(val, 8))
                    bytes[2] = bit.band(val, 0xFF)
                elseif field.idx == 5 then
                    bytes[3] = bit.bor(bit.band(bytes[3], 0x3F), bit.lshift(val, 6))
                elseif field.idx == 6 then
                    bytes[3] = bit.bor(bit.band(bytes[3], 0xC0), bit.rshift(val, 8))
                    bytes[4] = bit.band(val, 0xFF)
                elseif field.idx == 7 then
                    bytes[5] = bit.band(bit.rshift(val, 8), 0xFF)
                    bytes[6] = bit.band(val, 0xFF)
                end
                local decoded = parser._decode(bytes)
                assert.are.same(val, decoded[field.idx])
            end
        end)
    end
end)

describe("parser._encode", function()
    local _lookup = {
        { name = "Packet Version", idx = 1, shift = 13, mask = 0x07, rng = { 0, 0 } },
        { name = "Packet Type", idx = 2, shift = 12, mask = 0x01, rng = { 0, 1 } },
        { name = "Secondary Header", idx = 3, shift = 11, mask = 0x01, rng = { 0, 1 } },
        { name = "Application ID", idx = 4, shift = 0, mask = 0x7FF, rng = { 0, (2 ^ 11 - 1) } },
        { name = "Sequence Flag", idx = 5, shift = 14, mask = 0x03, rng = { 0, 3 } },
        { name = "Sequence Count", idx = 6, shift = 0, mask = 0x3FFF, rng = { 0, (2 ^ 14 - 1) } },
        { name = "Data Length", idx = 7, shift = 0, mask = 0xFFFF, rng = { 0, (2 ^ 16 - 1) } },
    }
    for _, field in ipairs(_lookup) do
        it("should correctly encode " .. field.name .. " for all valid values", function()
            local values = { 0, 0, 0, 0, 0, 0, 0 }
            for val = field.rng[1], field.rng[2] do
                values = { unpack({ 0, 0, 0, 0, 0, 0, 0 }) }
                values[field.idx] = val
                local encoded = parser._encode(values)
                local expected_bytes = { 0, 0, 0, 0, 0, 0 }
                if field.idx == 1 then
                    expected_bytes[1] = bit.bor(bit.lshift(val, 5))
                elseif field.idx == 2 then
                    expected_bytes[1] = bit.bor(bit.lshift(val, 4))
                elseif field.idx == 3 then
                    expected_bytes[1] = bit.bor(bit.lshift(val, 3))
                elseif field.idx == 4 then
                    expected_bytes[1] = bit.bor(expected_bytes[1], bit.rshift(val, 8))
                    expected_bytes[2] = bit.band(val, 0xFF)
                elseif field.idx == 5 then
                    expected_bytes[3] = bit.bor(bit.lshift(val, 6))
                elseif field.idx == 6 then
                    expected_bytes[3] = bit.bor(expected_bytes[3], bit.rshift(val, 8))
                    expected_bytes[4] = bit.band(val, 0xFF)
                elseif field.idx == 7 then
                    expected_bytes[5] = bit.rshift(val, 8)
                    expected_bytes[6] = bit.band(val, 0xFF)
                end
                assert.are.same(expected_bytes, encoded)
            end
        end)
    end
end)

-- Run several tests on our util functions

describe("utils._is_valid_ccsds_hdr_cfgkey", function()
    it("should return valid k/v", function()
        local config = { foo = 1, bar = 2 }
        local result = utils._is_valid_ccsds_hdr_cfgkey(config, "foo")
        assert.are.equal(result, config.foo)
    end)
    it("should not return valid k/v", function()
        local config = { foo = 1, bar = 2 }
        assert.has.error(function()
            utils._is_valid_ccsds_hdr_cfgkey(config, "foobar")
        end, "Error, key 'foobar' does not exist.")
    end)
end)

describe("utils._get_buffer_handle_by_name", function()
    it("should return valid handle", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(buf, "foobuff")
        local buf_handle = utils._get_buffer_handle_by_name("foobuff")
        assert(buf, buf_handle)
        vim.api.nvim_buf_delete(buf, { force = true })
    end)
    it("should not return handle", function()
        assert.has.error(function()
            utils._get_buffer_handle_by_name(123)
        end, "ValueError, buffer_name must be a non-empty string")
    end)
    it("should not return handle", function()
        assert.has.error(function()
            utils._get_buffer_handle_by_name("")
        end, "ValueError, buffer_name must be a non-empty string")
    end)
    it("should not return handle", function()
        assert.has.error(function()
            utils._get_buffer_handle_by_name("NonExistentBuffer")
        end, "Error, retrieving valid buffer")
    end)
end)

describe("utils._process_encoded_input", function()
    it("should return valid table", function()
        local strtable = { "00, 01, 02 0a 0b 0c" }
        local hextable = utils._process_encoded_input(strtable)
        assert.are.same(hextable, { 0x00, 0x01, 0x02, 0x0a, 0x0b, 0x0c })
    end)
    it("should return valid table", function()
        local strtable = { "00, 01, 02" }
        local hextable = utils._process_encoded_input(strtable, 6)
        assert.are.same(hextable, { 0x00, 0x01, 0x02 })
    end)
    it("should not return valid table", function()
        assert.has.error(function()
            local strtable = { "1" }
            utils._process_encoded_input(strtable, 1)
        end, "ValueError, valid_length must be even for gsub to work")
    end)
    it("should not return valid table", function()
        assert.has.error(function()
            local strtable = { "01" }
            utils._process_encoded_input(strtable, "2")
        end, "TypeError, number must be a number")
    end)
    it("should not return valid table", function()
        assert.has.error(function()
            utils._process_encoded_input(1)
        end, "TypeError, user_input must be a table")
    end)
end)

describe("utils._process_decoded_input", function()
    it("should return valid table", function()
        local test_data = {
            "Packet Version: 0",
            "Packet Type: 0",
            "Secondary Header: 1",
            "Application ID: 523",
            "Sequence Flags: 3",
            "Sequence Count: 1025",
            "Data Length: 14234",
        }
        local numtable = utils._process_decoded_input(test_data)
        assert.are.same({ 0, 0, 1, 523, 3, 1025, 14234 }, numtable)
    end)
    it("should return valid table", function()
        local test_data = {
            "Packet Version: 0",
            "Packet Type: 0",
            "Secondary Header: 1",
            "Application ID: 0x20b",
            "Sequence Flags: 3",
            "Sequence Count: 1025",
            "Data Length: 14234",
        }
        local numtable = utils._process_decoded_input(test_data)
        assert.are.same({ 0, 0, 1, 523, 3, 1025, 14234 }, numtable)
    end)
    it("should not return valid table", function()
        assert.has.error(function()
            utils._process_decoded_input("foo")
        end, "TypeError, user_input must be a table")
    end)
    it("should not return valid table", function()
        assert.has.error(function()
            utils._process_decoded_input({ "Packet Version: 0" }, 2)
        end, "ValueError, valid_length does not match length of user_input")
    end)
end)

describe("utils._validate_field_values", function()
    it("should eval fields with no errors", function()
        local fields = { { rng = { 1, 1 } }, { rng = { 3, 3 } } }
        local values = { 1, 3 }
        local found_errors, errors_are = utils._validate_field_values(fields, values)
        assert.are.same(false, found_errors)
        assert.are.same(0, #errors_are)
    end)
    it("should eval fields with errors", function()
        local fields = { { rng = { 2, 2 } }, { rng = { 4, 4 } } }
        local values = { 1, 3 }
        local found_errors, errors_are = utils._validate_field_values(fields, values)
        assert.are.same(true, found_errors)
        assert.are.same(2, #errors_are)
    end)
    it("should eval fields with errors", function()
        assert.has.error(function()
            utils._validate_field_values({}, 2)
        end, "TypeError, both args must be a table")
    end)
    it("should eval fields with errors", function()
        assert.has.error(function()
            utils._validate_field_values({ 1 }, { 1, 2 })
        end, "ValueError, both args must be tables of the same length")
    end)
end)

describe("utils._calculate_diffs_over_lines", function()
    it("should find no diffs", function()
        --        0000000000111111
        --        1234567890123456
        prev = { "This is a string" }
        curr = { "This is a string" }
        found_diffs, diffs_are = utils._calculate_diffs_over_lines(prev, curr)
        assert.are.same(found_diffs, false)
        -- check outer table
        assert.are.same(1, #diffs_are)
        -- check inner table
        assert.are.same(0, #diffs_are[1])
    end)
    it("should find diffs", function()
        --        0000000000111111
        --        1234567890123456
        prev = { "This is a string" }
        curr = { "This is a number" }
        found_diffs, diffs_are = utils._calculate_diffs_over_lines(prev, curr)
        assert.are.same(found_diffs, true)
        assert.are.same({ { 11, 12, 13, 14, 15, 16 } }, diffs_are)
    end)
    it("should find diffs and check against smaller string", function()
        --        0000000000111111
        --        1234567890123456
        prev = { "This is a string", "foobar" }
        curr = { "This is a number", "foo" }
        found_diffs, diffs_are = utils._calculate_diffs_over_lines(prev, curr)
        assert.are.same(found_diffs, true)
        assert.are.same({ { 11, 12, 13, 14, 15, 16 }, {} }, diffs_are)
    end)
    it("should find diffs across several lines", function()
        --        0000000000111111    000000
        --        1234567890123456    123456
        prev = { "This is a string", "foobar" }
        curr = { "This is a number", "barfoo" }
        found_diffs, diffs_are = utils._calculate_diffs_over_lines(prev, curr)
        assert.are.same(found_diffs, true)
        assert.are.same({ { 11, 12, 13, 14, 15, 16 }, { 1, 2, 3, 4, 5, 6 } }, diffs_are)
    end)
    it("should encounter errors", function()
        assert.has.error(function()
            utils._calculate_diffs_over_lines(1, { 1, 2 })
        end, "TypeError, types of args must be of table")
    end)
    it("should encounter errors", function()
        assert.has.error(function()
            utils._calculate_diffs_over_lines({ 1 }, { 1, 2 })
        end, "ValueError, tables must be of same length")
    end)
end)
