if not package.loaded["mini.doc"] then
    require("mini.doc").setup()
end
require("mini.doc").generate({
    "lua/ccsds-hdr/init.lua",
    "lua/ccsds-hdr/config.lua",
    "lua/ccsds-hdr/parser.lua",
    "lua/ccsds-hdr/ui.lua",
    "lua/ccsds-hdr/utils.lua",
})
