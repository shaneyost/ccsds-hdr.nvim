local utils = require("ccsds-hdr.utils")
local M = {}

M.cfg = {
    keymaps = {
        encode = {
            mode = "n",
            lhs = "<leader>ce",
            rhs = nil,
            opts = {
                noremap = true,
                silent = true,
                desc = "ccsds-hdr encode",
            },
        },
        decode = {
            mode = "n",
            lhs = "<leader>cd",
            rhs = nil,
            opts = {
                noremap = true,
                silent = true,
                desc = "ccsds-hdr decode",
            },
        },
        open = {
            mode = "n",
            lhs = "<leader>co",
            rhs = nil,
            opts = {
                noremap = true,
                silent = true,
                desc = "ccsds-hdr open",
            },
        },
        next = {
            mode = "n",
            lhs = "<leader>cn",
            rhs = nil,
            opts = {
                noremap = true,
                silent = true,
                desc = "ccsds-hdr next",
            },
        },
        close = {
            mode = "n",
            lhs = "<leader>cc",
            rhs = nil,
            opts = {
                noremap = true,
                silent = true,
                desc = "ccsds-hdr close",
            },
        },
    },
}

function M.get_map(mode, lhs, desc)
    return utils.is_valid_ccsds_hdr_keymap(mode, lhs, desc)
end

function M.set_map(mode, lhs, rhs, opts)
    opts = opts or { noremap = true, silent = true, desc = "ccsds-hdr keymap" }
    vim.keymap.set(mode, lhs, rhs, opts)
end

function M.get(key)
    return utils.is_valid_ccsds_hdr_cfgkey(M.cfg, key)
end

function M.mrg(cfg)
    assert(type(cfg) == "table", "Invalid arg: 'cfg' must be table")
    M.cfg = vim.tbl_deep_extend("force", M.cfg, cfg or {})
    return M.cfg
end

function M.setup(user_config)
    M.mrg(user_config)
    for _, map in pairs(M.cfg.keymaps) do
        M.set_map(map.mode, map.lhs, map.rhs, map.opts)
    end
end

return M
