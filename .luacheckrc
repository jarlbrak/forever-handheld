-- luacheck configuration for ForeverHandheld (https://github.com/lunarmodules/luacheck)
-- Run from the repository root: luacheck ForeverHandheld
std = "lua51"
max_line_length = false
codes = true
exclude_files = { "tests/**", ".release/**" }

-- The addon talks to the WoW client through hundreds of global API functions, frames and
-- Blizzard mixins, and every module publishes its table as a global for the others. Global
-- access is therefore not checked; everything else is.
allow_defined_top = true
ignore = {
    "11.",  -- setting/accessing undefined globals (WoW API surface)
    "131",  -- unused global (SLASH_* command names are read by the client)
    "212",  -- unused argument (frame script signatures such as self, event, elapsed)
}

-- Baseline: warnings present in the 3.7.180 import. Remove an entry once its file is clean;
-- new files get the strict defaults above.
files["ForeverHandheld/Comms.lua"] = { ignore = { "211", "431" } }
files["ForeverHandheld/ForeverHandheld.lua"] = { ignore = { "211", "213" } }
files["ForeverHandheld/ItemDetails.lua"] = { ignore = { "213" } }
files["ForeverHandheld/JourneyControls.lua"] = { ignore = { "431" } }
files["ForeverHandheld/NativeSettings.lua"] = { ignore = { "421" } }
files["ForeverHandheld/Panels.lua"] = { ignore = { "211", "421", "431" } }
files["ForeverHandheld/ProfessionMenus.lua"] = { ignore = { "421" } }
files["ForeverHandheld/Progress.lua"] = { ignore = { "231", "411" } }
files["ForeverHandheld/RareReader.lua"] = { ignore = { "432" } }
files["ForeverHandheld/Windows.lua"] = { ignore = { "542" } }
