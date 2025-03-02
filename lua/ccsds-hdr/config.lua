local CcsdsHdr = {}
local utils = require("ccsds-hdr.utils")

--- The default configuration table
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
CcsdsHdr._cfg = {
    -- Title of the Encoder window (shows up in top center)
    encoder_title = "Encoded",
    -- Title of the Decoder window (shows up in top center)
    decoder_title = "Decoded",
    -- Initial values for encoder
    initial_encoder_vals = { string.format("0A 0B C4 01 37 9A") },
    -- Initial values for decoder
    initial_decoder_vals = {
        string.format("Packet Version: 0"),
        string.format("Packet Type: 0"),
        string.format("Secondary Header: 1"),
        string.format("Application ID: 0x20B"),
        string.format("Sequence Flag: 3"),
        string.format("Sequence Count: 1025"),
        string.format("Data Length: 14234"),
    },
    -- Highlights applied for bytes/fields updated after decoding/encoding
    hl_update_color = { fg = "#2E3440", bg = "#88C0D0", bold = false },
    -- Highlights applied for bytes/fields that are invalid after decoding/encoding
    hl_errors_color = { fg = "#2E3440", bg = "#D08770", bold = false },
    -- Highlights applied for bytes/fields overall
    hl_normal_color = { fg = "#D8DEE9", bg = "#2E3440", bold = false },
    -- Highlights applied for all borders of encoder/decoder windows
    hl_border_color = { fg = "#88C0D0", bold = false },
}
--minidoc_afterlines_end

function CcsdsHdr._get(key)
    return utils._is_valid_ccsds_hdr_cfgkey(CcsdsHdr._cfg, key)
end

function CcsdsHdr._mrg(cfg)
    CcsdsHdr._cfg = vim.tbl_deep_extend("force", CcsdsHdr._cfg, cfg or {})
    return CcsdsHdr._cfg
end

function CcsdsHdr._setup(user_config)
    CcsdsHdr._mrg(user_config)
end

return CcsdsHdr
