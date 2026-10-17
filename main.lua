local Arachnophobia = require("arachnophobia")
local SettingsPane = require("interface/settings")

Arachnophobia.Start()
SettingsPane.Start()

function PluginShutdown()
    SettingsPane.Shutdown()
    Arachnophobia.Shutdown()
end
