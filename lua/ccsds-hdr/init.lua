local CcsdsHdr = {}
local conf = require("ccsds-hdr.config")
CcsdsHdr.ui = require("ccsds-hdr.ui")
CcsdsHdr.parser = require("ccsds-hdr.parser")

--- Merges the user's config table with default config table
---@param user_cfg table|nil Module config table.
---
---@usage >lua
---
---   require('ccsds-hdr').setup() -- use default config
---   -- OR
---   require('ccsds-hdr').setup({}) -- replace {} with your config table
--- <
function CcsdsHdr.setup(user_cfg)
    conf._setup(user_cfg)
end

return CcsdsHdr
