local bit = require("bit")
local utils = require("ccsds-hdr.utils")
local M = {}

function M.decode_header()
	local header = {}
	local fields = utils.new_ccsds_header_tbl()

	local ebuf = utils.get_buffer_handle_by_name("enc")
	local dbuf = utils.get_buffer_handle_by_name("dec")

	-- Remove unwanted characters, makes parsing w/ gmatch simple
	local raw_input = vim.api.nvim_buf_get_lines(ebuf, 0, 1, false)
	local raw_bytes = raw_input[1]:gsub("[,%s]", "")

	-- Protect user entering invalid length. If valid, create our table of bytes
	if #raw_bytes == 12 then
		for every_two_chars in raw_bytes:gmatch("%x%x") do
			table.insert(header, tonumber(every_two_chars, 16))
		end
	else
		return vim.notify("Error: invalid length critiera, check input", vim.log.levels.ERROR)
	end

	-- tonumber creates nils on invalid hex digits, so validate good header table
	if #header == 6 then
		local word1 = bit.bor(bit.lshift(header[1], 8), header[2])
		local word2 = bit.bor(bit.lshift(header[3], 8), header[4])
		local word3 = bit.bor(bit.lshift(header[5], 8), header[6])
		fields.packet_version = bit.rshift(word1, 13)
		fields.packet_type = bit.band(bit.rshift(word1, 12), 0x01)
		fields.secondary_header = bit.band(bit.rshift(word1, 11), 0x01)
		fields.application_id = bit.band(word1, 0x07FF)
		fields.sequence_flags = bit.rshift(word2, 14)
		fields.sequence_count = bit.band(word2, 0x3FFF)
		fields.data_length = word3
	else
		return vim.notify("Error: invalid characters, check input", vim.log.levels.ERROR)
	end

	-- format our output nicely then flush and write to buffer
	local output = {
		string.format("Packet Version: %d", fields.packet_version),
		string.format("Packet Type: %d", fields.packet_type),
		string.format("Secondary Header: %d", fields.secondary_header),
		string.format("Application ID: %d", fields.application_id),
		string.format("Sequence Flags: %d", fields.sequence_flags),
		string.format("Sequence Count: %d", fields.sequence_count),
		string.format("Data Length: %d", fields.data_length),
	}
	vim.api.nvim_buf_set_lines(dbuf, 0, -1, false, {})
	vim.api.nvim_buf_set_lines(dbuf, 0, 6, false, output)
end

function M.encode_header()
	local fields = {}
	local ebuf = utils.get_buffer_handle_by_name("enc")
	local dbuf = utils.get_buffer_handle_by_name("dec")

	local raw_input = vim.api.nvim_buf_get_lines(dbuf, 0, -1, false)
	for _, line in ipairs(raw_input) do
		-- pull out key/value pairs w/ : as delimiter, update fields table
		local key, val = line:match("([^:]+):%s*(.+)")
		if key and val then
			fields[key:lower():gsub(" ", "_")] = tonumber(val)
		else
			return vim.notify("Error: invalid char check input", vim.log.levels.ERROR)
		end
	end

	-- 0-based indexes, refer to CCSDS 133.0-B-1, section 4.1.2.2 for details
	local header = bit.bor(
		bit.lshift(fields.packet_version, 29),
		bit.lshift(fields.packet_type, 28),
		bit.lshift(fields.secondary_header, 27),
		bit.lshift(fields.application_id, 16),
		bit.lshift(fields.sequence_flags, 14),
		fields.sequence_count
	)

	-- Reorder bytes for correct endianess, helps with processing
	local bytes = {}
	for i = 3, 0, -1 do
		table.insert(bytes, bit.band(bit.rshift(header, i * 8), 0xff))
	end
	local header2 = fields.data_length
	for i = 1, 0, -1 do
		table.insert(bytes, bit.band(bit.rshift(header2, i * 8), 0xff))
	end

	-- format our output nicely then flush and write to buffer
	local hex_string = table.concat(
		vim.tbl_map(function(byte)
			return string.format("%02X", byte)
		end, bytes),
		" "
	)
	vim.api.nvim_buf_set_lines(ebuf, 0, -1, false, {})
	vim.api.nvim_buf_set_lines(ebuf, 0, -1, false, { hex_string })
end

return M
