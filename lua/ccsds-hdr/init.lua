local conf = require("ccsds-hdr.config")
local ui = require("ccsds-hdr.ui")
local parser = require("ccsds-hdr.parser")

local M = {}

function M.setup(user_cfg)
	conf.cfg.keymaps.decode.rhs = parser.decode_header
	conf.cfg.keymaps.encode.rhs = parser.encode_header
	conf.cfg.keymaps.open.rhs = ui.setup
	conf.cfg.keymaps.next.rhs = ui.focus_next_window
	conf.cfg.keymaps.close.rhs = ui.close_all_windows
    conf.cfg.keymaps.test.rhs = M.test
	conf.setup(user_cfg)
end

function M.test()
    print("hello")
end
return M
