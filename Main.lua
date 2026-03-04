local REPO_URL = "https://raw.githubusercontent.com/YOUR_USERNAME/phantom-hub-enhanced/main"

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

TO USE:

Copy this and paste in your executor:
loadstring(game:HttpGet("https://raw.githubusercontent.com/wandeen/phantom-hub-enhanced/main/Hub_Enhanced.lua"))()

Replace YOUR_USERNAME with your actual GitHub username!

═══════════════════════════════════════════════════════════════════════════════════

STEP 5: UPDATE HUB_ENHANCED.LUA FOR GITHUB LOADING
───────────────────────────────────────────────────────────────────────────────────

YOUR CURRENT Hub_Enhanced.lua tries to load modules via readfile() (local files).

TO MAKE IT LOAD FROM GITHUB:

Find this section near the top:

    local function loadModules()
        local modules = {
            EventHooks = "1_EventHooks.lua",
            Noclip = "2_NoclipSystem.lua",
            ...
        }
        
        for name, filename in pairs(modules) do
            local ok, result = pcall(function()
                local content = readfile(filename)    ← THIS LINE
                return loadstring(content)()
            end)
        end
    end

CHANGE IT TO:

    local GITHUB_URL = "https://raw.githubusercontent.com/wandeen/phantom-hub-enhanced/main"
    
    local function loadModules()
        local modules = {
            EventHooks = "1_EventHooks.lua",
            Noclip = "2_NoclipSystem.lua",
            ...
        }
        
        for name, filename in pairs(modules) do
            local ok, result = pcall(function()
                local url = GITHUB_URL .. "/" .. filename
                return loadstring(game:HttpGet(url))()
            end)
            
            if ok and result then
                _G[name] = result.new and result.new() or result
                print("[Phantom] Loaded: " .. name)
            else
                print("[Phantom] Warning: Could not load " .. name)
            end
        end
    end
