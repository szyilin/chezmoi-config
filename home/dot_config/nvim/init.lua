require("core.bootstrap").setup()

local profile = require("utils.profile").detect()
require("profiles." .. profile).setup()
