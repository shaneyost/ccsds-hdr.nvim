-- NOTE
-- lua require("plenary.test_harness").test_file("tests/test_ccsds.lua")
local util = require("ccsds-hdr.utils")
local conf = require("ccsds-hdr.config")

describe("Module: utils.lua, Function: is_valid_ccsds_hdr_cfgkey", function()
    it("should return valid k/v", function()
        local result = util.is_valid_ccsds_hdr_cfgkey(conf.cfg, "keymaps.encode.mode")
        assert.are.equal(result, conf.cfg.keymaps.encode.mode)
    end)
    it("should not return valid k/v", function()
        assert.has.error(function()
            util.is_valid_ccsds_hdr_cfgkey(conf.cfg, "test1.mode")
        end, "Invalid key: Key 'test1' does not exist.")
    end)
    it("should not return k/v", function()
        assert.has.error(function()
            util.is_valid_ccsds_hdr_cfgkey(conf.cfg, "this.is.a.bad.key")
        end, "Invalid key: Key 'this' does not exist.")
    end)
end)

describe("Module: utils.lua, Function: is_valid_ccsds_hdr_keymap", function()
    local map = { mode = "n", lhs = "<leader>ct99", opt = { desc = "foobar" } }
    vim.keymap.set(map.mode, map.lhs, "", map.opt)
    it("should return valid mapping", function()
        local result = util.is_valid_ccsds_hdr_keymap(map.mode, map.lhs, map.opt.desc)
        assert.are.same(type(result), "table")
        assert.are.equal(#result, 1)
    end)
    it("should not return mapping", function()
        vim.keymap.del(map.mode, map.lhs)
        assert.has.error(function()
            util.is_valid_ccsds_hdr_keymap(map.mode, map.lhs, map.opt.desc)
        end, "Invalid map: Map not found")
    end)
end)

describe("Module: utils.lua, Function: get_buffer_handle_by_name", function()
    it("should return valid handle", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(buf, "foobuff")
        local buf_handle = util.get_buffer_handle_by_name("foobuff")
        assert(buf, buf_handle)
        vim.api.nvim_buf_delete(buf, { force = true })
    end)
    it("should not return handle", function()
        assert.has.error(function()
            util.get_buffer_handle_by_name(123)
        end, "Invalid buffer name: expected a non-empty string")
    end)
    it("should not return handle", function()
        assert.has.error(function()
            util.get_buffer_handle_by_name("")
        end, "Invalid buffer name: expected a non-empty string")
    end)
    it("should not return handle", function()
        assert.has.error(function()
            util.get_buffer_handle_by_name("NonExistentBuffer")
        end, "Error, in retrieving valid buffer")
    end)
end)

describe("Module: utils.lua, Function: process_encoded_input", function()
    it("should return valid table", function()
        local strtable = { "00, 01, 02 0a 0b 0c" }
        local hextable = util.process_encoded_input(strtable[1])
        assert.are.same(hextable, { 0x00, 0x01, 0x02, 0x0a, 0x0b, 0x0c })
    end)
    it("should return valid table", function()
        local strtable = { "00, 01, 02" }
        local hextable = util.process_encoded_input(strtable[1], 6)
        assert.are.same(hextable, { 0x00, 0x01, 0x02 })
    end)
    it("should not return valid table", function()
        assert.has.error(function()
            local strtable = { "1" }
            util.process_encoded_input(strtable[1], 1)
        end, "Invalid argument, arg must be even")
    end)
    it("should not return valid table", function()
        assert.has.error(function()
            local strtable = { "01" }
            util.process_encoded_input(strtable[1], "2")
        end, "Invalid argument, arg must be a number")
    end)
    it("should not return valid table", function()
        assert.has.error(function()
            util.process_encoded_input(1)
        end, "Invalid argument, arg must be a string")
    end)
end)

describe("Module: utils.lua, Function: process_decoded_input", function()
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
        local numtable = util.process_decoded_input(test_data)
        assert.are.same({0, 0, 1, 523, 3, 1025, 14234}, numtable)
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
        local numtable = util.process_decoded_input(test_data)
        assert.are.same({0, 0, 1, 523, 3, 1025, 14234}, numtable)
    end)
    it("should return valid table", function()
        assert.has.error(function()
            util.process_decoded_input("foo")
        end, "Invalid argument, arg must be a table of strings")
    end)
    it("should return valid table", function()
        assert.has.error(function()
            util.process_decoded_input({"Packet Version: 0"})
        end, "Invalid argument, only 7 fields in a CCSDS header")
    end)
end)

describe("Module: utils.lua, Function: validate_range_on_field", function()
    it("should validate a valid field", function()
        util.validate_range_on_field(2, {0, 3})
    end)
    it("should validate a invalid field", function()
        assert.has.error(function()
            util.validate_range_on_field(2, {0, 1})
        end, "2 out of range, {0, 1}")
    end)
end)
