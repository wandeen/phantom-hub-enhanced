local REPO_URL = "https://raw.githubusercontent.com/wandeen/phantom-hub-enhanced/main"

local function loadModule(filename)
    local url = REPO_URL .. "/" .. filename
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if ok then
        print("[Phantom] Loaded: " .. filename)
        return result
    else
        warn("[Phantom] Failed to load " .. filename .. ": " .. tostring(result))
        return nil
    end
end

-- Load main hub
loadstring(game:HttpGet(REPO_URL .. "/Hub_Enhanced.lua"))()

---
