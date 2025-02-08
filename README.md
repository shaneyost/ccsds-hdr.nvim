<div align="center">
  <h1>✨ CCSDS (Decoder/Encoder)</h1>
</div>

<p align="center">
  <a href="https://github.com/rogueWookie/ccsds-hdr.nvim/actions/workflows/ci.yaml">
    <img src="https://github.com/rogueWookie/ccsds-hdr.nvim/actions/workflows/ci.yaml/badge.svg" alt="CI Status">
  </a>
  <a href="https://github.com/rogueWookie/ccsds-hdr.nvim/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/rogueWookie/ccsds-hdr.nvim" alt="License">
  </a>
  <a href="https://github.com/rogueWookie/ccsds-hdr.nvim/issues">
    <img src="https://img.shields.io/github/issues/rogueWookie/ccsds-hdr.nvim" alt="GitHub Issues">
  </a>
</p>

---

## About  

**ccsds-hdr.nvim** is a Neovim plugin designed for working with **CCSDS Space Packet Protocol** headers. This tool provides an intuitive floating window interface that allows users to:  

- **Decode a 6-byte primary header** into its individual CCSDS fields
- **Encode a 6-byte primary header** from user-inputted field values

## Default Configuration

```lua
return {
    "rogueWookie/ccsds-hdr.nvim",
    dependencies = { "nvim-lua/plenary.nvim" }, -- for running the unit tests
    config = function()
        local ccsds = require("ccsds-hdr")
        ccsds.setup()
    end,
}
```

## Full Configuration
```lua
return {
    "rogueWookie/ccsds-hdr.nvim",
    dependencies = { "nvim-lua/plenary.nvim" }, -- for running the unit tests
    config = function()
        local ccsds = require("ccsds-hdr")
        local config = {
            keymaps = {
                encode={
                    mode="n",
                    lhs="<leader>ce",
                    rhs=nil,
                    opts={
                        noremap=true,
                        silent=true,
                        desc="ccsds-hdr encode"
                    }
                },
                decode={
                    mode="n",
                    lhs="<leader>cd",
                    rhs=nil,
                    opts={
                        noremap=true,
                        silent=true,
                        desc="ccsds-hdr decode"
                    }
                },
                open={
                    mode="n",
                    lhs="<leader>co",
                    rhs=nil,
                    opts={
                        noremap=true,
                        silent=true,
                        desc="ccsds-hdr open"
                    }
                },
                next={
                    mode="n",
                    lhs="<leader>cn",
                    rhs=nil,
                    opts={
                        noremap=true,
                        silent=true,
                        desc="ccsds-hdr next"
                    }
                },
                close={
                    mode="n",
                    lhs="<leader>cc",
                    rhs=nil,
                    opts={
                        noremap=true,
                        silent=true,
                        desc="ccsds-hdr close"
                    }
                },
            }
        }
        ccsds.setup(confg)
    end,
}
```
