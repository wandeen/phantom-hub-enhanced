-- ╔══════════════════════════════════════════════════════╗
-- ║    PHANTOM HUB v3.0 - ENHANCED (GITHUB VERSION)   ║
-- ║    Loads all modules from GitHub automatically     ║
-- ║  Change YOUR_USERNAME to your actual GitHub name   ║
-- ╚══════════════════════════════════════════════════════╝

-- ════════════════════════════════════════════════════════════════
-- ── CONFIGURATION - CHANGE THIS TO YOUR GITHUB USERNAME ────────
-- ════════════════════════════════════════════════════════════════

local GITHUB_USERNAME = "YOUR_USERNAME"  -- ← CHANGE THIS!
local GITHUB_REPO = "phantom-hub-enhanced"
local GITHUB_BRANCH = "main"

-- Build base URL
local GITHUB_BASE_URL = "https://raw.githubusercontent.com/" .. GITHUB_USERNAME .. "/" .. GITHUB_REPO .. "/" .. GITHUB_BRANCH

print("[Phantom] Loading from GitHub: " .. GITHUB_USERNAME .. "/" .. GITHUB_REPO)

-- ════════════════════════════════════════════════════════════════
-- ── Load UI Library ───────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════
local _phantomUrl = "https://raw.githubusercontent.com/wandeen/pine/main/Phantom.lua"
local _loaded, _result = pcall(function()
    return loadstring(game:HttpGet(_phantomUrl))()
end)
if not _loaded or not _result then
    local sg = Instance.new("ScreenGui"); sg.ResetOnSpawn = false
    local ok, cg = pcall(function() return cloneref(game:GetService("CoreGui")) end)
    sg.Parent = ok and cg or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,80); lbl.Position = UDim2.new(0,0,0.4,0)
    lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(255,80,80)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 18; lbl.TextWrapped = true
    lbl.Text = "Phantom: failed to load UI library.\nURL: " .. _phantomUrl
    lbl.Parent = sg
    error("Phantom Hub: could not load Phantom.lua — " .. tostring(_result))
end
local Phantom = _result

-- ── Services ──────────────────────────────────────────────────
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UIS            = game:GetService("UserInputService")
local Lighting       = game:GetService("Lighting")
local PhysicsService = game:GetService("PhysicsService")
local LocalPlayer    = Players.LocalPlayer

-- ── Helpers ───────────────────────────────────────────────────
local function getChar() return LocalPlayer.Character end
local function getHum()  local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end

-- ════════════════════════════════════════════════════════════════
-- ── LOAD ALL 7 ENHANCEMENT SYSTEMS (FROM GITHUB) ──────────────
-- ════════════════════════════════════════════════════════════════

local EventHooks, Noclip, Logger, Aliases, AutoKeyPress, PluginManager, KeybindUI

local function loadFromGitHub(moduleName, filename)
    local url = GITHUB_BASE_URL .. "/" .. filename
    local ok, result = pcall(function()
        print("[Phantom] Fetching " .. filename .. "...")
        local content = game:HttpGet(url)
        local fn = loadstring(content)
        return fn()
    end)
    
    if ok and result then
        _G[moduleName] = result.new and result.new() or result
        print("[Phantom] ✓ Loaded: " .. moduleName)
        return result.new and result.new() or result
    else
        warn("[Phantom] ✗ Failed to load " .. moduleName .. ": " .. tostring(result))
        return nil
    end
end

-- Load all modules
print("[Phantom] Loading enhancement systems from GitHub...")
EventHooks = loadFromGitHub("EventHooks", "1_EventHooks.lua")
Noclip = loadFromGitHub("Noclip", "2_NoclipSystem.lua")
Logger = loadFromGitHub("Logger", "3_LoggingSystem.lua")
Aliases = loadFromGitHub("Aliases", "4_AliasSystem.lua")
AutoKeyPress = loadFromGitHub("AutoKeyPress", "5_AutoKeyPressSystem.lua")
PluginManager = loadFromGitHub("PluginManager", "6_PluginSystem.lua")
KeybindUI = loadFromGitHub("KeybindUI", "7_KeybindUI.lua")

print("[Phantom] Module loading complete!")

-- ════════════════════════════════════════════════════════════════
-- ──  PANIC KEY  (Delete)
-- ════════════════════════════════════════════════════════════════
local _panicShutdown  -- forward declared

local function _showDisengagedOverlay()
    pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "PhantomPanicOverlay"; sg.ResetOnSpawn = false
        local ok, cg = pcall(function() return cloneref(game:GetService("CoreGui")) end)
        sg.Parent = ok and cg or LocalPlayer:WaitForChild("PlayerGui")
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1,0,0,60); lbl.Position = UDim2.new(0,0,0.5,-30)
        lbl.BackgroundTransparency = 1; lbl.Text = "DISENGAGED"
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 36
        lbl.TextColor3 = Color3.fromRGB(255,65,65); lbl.TextStrokeTransparency = 0.4
        lbl.Parent = sg
        task.delay(1, function() pcall(function() sg:Destroy() end) end)
    end)
end

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Delete and _panicShutdown then
        _panicShutdown()
    end
end)

-- ── Create Window ─────────────────────────────────────────────
local Hub = Phantom.new({
    Title    = "Phantom",
    Subtitle = "hub",
    Keybind  = Enum.KeyCode.J,
})
Hub:SetProfile()
Hub._win.BackgroundTransparency = 0.05

-- ════════════════════════════════════════════════════════════════
-- ──  WIRE UP ENHANCEMENT SYSTEMS ───────────────────────────────
-- ════════════════════════════════════════════════════════════════

if PluginManager and EventHooks then
    PluginManager:SetEventHooks(EventHooks)
    print("[Phantom] Wired event system to plugin manager")
end

if Aliases then
    Aliases:Load()
    print("[Phantom] Loaded aliases from storage")
end

if KeybindUI then
    KeybindUI:LoadKeybinds()
    print("[Phantom] Loaded keybinds from storage")
end

-- ════════════════════════════════════════════════════════════════
-- ──  SETTINGS MANAGER (inlined — `script` is nil in executors)
-- ════════════════════════════════════════════════════════════════
local _smHS = game:GetService("HttpService")
local SettingsManager = {}; SettingsManager.__index = SettingsManager
function SettingsManager.new(hub, name)
    return setmetatable({_hub=hub,_name=name or "default",_entries={},_charConn=nil}, SettingsManager)
end
function SettingsManager:Register(key, getter, setter)
    self._entries[key] = {get=getter, set=setter}
end
local function _smEncode(v)
    if typeof(v)=="Color3" then
        return {__type="Color3",r=math.round(v.R*255),g=math.round(v.G*255),b=math.round(v.B*255)}
    end; return v
end
local function _smDecode(v)
    if type(v)=="table" and v.__type=="Color3" then
        return Color3.fromRGB(v.r or 0,v.g or 0,v.b or 0)
    end; return v
end
function SettingsManager:Save()
    local data={}
    for k,e in pairs(self._entries) do local ok,val=pcall(e.get); if ok then data[k]=_smEncode(val) end end
    local ok,json=pcall(function() return _smHS:JSONEncode(data) end)
    if ok then pcall(function() writefile("phantom_sm_"..self._name..".json",json) end) end
end
function SettingsManager:Load()
    local ok,content=pcall(function() return readfile("phantom_sm_"..self._name..".json") end)
    if not ok or not content or content=="" then return false end
    local ok2,data=pcall(function() return _smHS:JSONDecode(content) end)
    if not ok2 or type(data)~="table" then return false end
    for k,e in pairs(self._entries) do
        if data[k]~=nil then pcall(function() e.set(_smDecode(data[k])) end) end
    end; return true
end
function SettingsManager:StartAutoApply()
    if self._charConn then self._charConn:Disconnect() end
    self._charConn = Players.LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1); self:Load()
    end)
end

local _flySpeed = 60
local SM = SettingsManager.new(Hub, "phantom")
SM:Register("WalkSpeed",
    function() return _G.PhantomWalkSpeed or 16 end,
    function(v) _G.PhantomWalkSpeed=v; local h=getHum(); if h then h.WalkSpeed=v end end)
SM:Register("JumpPower",
    function() return _G.PhantomJumpPower or 7 end,
    function(v) _G.PhantomJumpPower=v; local h=getHum(); if h then h.JumpPower=v end end)
SM:Register("FlySpeed",
    function() return _flySpeed end,
    function(v) _flySpeed=v end)
SM:Load(); SM:StartAutoApply()

-- ════════════════════════════════════════════════════════════════
-- ──  NOCLIP (NEW SYSTEM) ───────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

local _noclipSystem = Noclip or {
    Toggle = function(self) end,
    Enable = function(self) end,
    Disable = function(self) end,
    SetSpeed = function(self, s) end,
}

-- ════════════════════════════════════════════════════════════════
-- ──  WALK SPEED ENFORCER
-- ════════════════════════════════════════════════════════════════
local _wsTarget=16; local _wsConn=nil
local function startWsEnforcer(speed)
    _wsTarget=speed; if _wsConn then _wsConn:Disconnect() end
    _wsConn=RunService.Heartbeat:Connect(function()
        local h=getHum(); if h and h.WalkSpeed~=_wsTarget then h.WalkSpeed=_wsTarget end
    end)
end
local function stopWsEnforcer()
    if _wsConn then _wsConn:Disconnect(); _wsConn=nil end
end

-- ════════════════════════════════════════════════════════════════
-- ──  AIMBOT  (existing code, unchanged)
-- ════════════════════════════════════════════════════════════════
local _abEnabled=false; local _abMode="Toggle"; local _abKey=Enum.KeyCode.RightAlt
local _abFov=120; local _abSmoothing=40; local _abBone="Head"; local _abPriority="Distance"
local _abVisCheck=true; local _abAutoWall=false; local _abRCS=false; local _abRCSStrength=50
local _abHumanize=true; local _abFovColor=Color3.fromRGB(255,255,255)
local _abFovCircle=nil; local _abConn=nil; local _abTarget=nil

local _boneMapR15={Head="Head",Neck="UpperTorso",Chest="UpperTorso",Pelvis="LowerTorso"}
local _boneMapR6 ={Head="Head",Neck="Torso",Chest="Torso",Pelvis="Torso"}
local _randomR15={"Head","UpperTorso","LowerTorso"}; local _randomR6={"Head","Torso"}

local function _getTargetPart(char)
    local isR15=char:FindFirstChild("UpperTorso")~=nil; local bone=_abBone
    if bone=="Random" then local p=isR15 and _randomR15 or _randomR6; bone=p[math.random(1,#p)] end
    return char:FindFirstChild((isR15 and _boneMapR15 or _boneMapR6)[bone] or "HumanoidRootPart")
end

local function _abVisible(origin,targetPos)
    if _abAutoWall then return true end
    local params=RaycastParams.new()
    params.FilterDescendantsInstances={getChar()}; params.FilterType=Enum.RaycastFilterType.Exclude
    local result=workspace:Raycast(origin,targetPos-origin,params); if not result then return true end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer and plr.Character then
            if result.Instance:IsDescendantOf(plr.Character) then return true end
        end
    end; return false
end

local function _abScore(plr,char,camPos,fovPx)
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    local cam=workspace.CurrentCamera; local sp,inView=cam:WorldToViewportPoint(hrp.Position)
    if not inView or sp.Z<=0 then return nil end
    if (Vector2.new(sp.X,sp.Y)-cam.ViewportSize/2).Magnitude>fovPx then return nil end
    if _abVisCheck and not _abVisible(camPos,hrp.Position) then return nil end
    local dist=(hrp.Position-camPos).Magnitude
    local hp=(char:FindFirstChildOfClass("Humanoid") or {Health=100}).Health
    if _abPriority=="Distance" then return -dist
    elseif _abPriority=="Health" then return -hp
    elseif _abPriority=="Threat" then return -dist+hp*0.5 end
    return -(Vector2.new(sp.X,sp.Y)-workspace.CurrentCamera.ViewportSize/2).Magnitude
end

local function _runAimbot()
    local cam=workspace.CurrentCamera; local camCF=cam.CFrame; local camPos=camCF.Position
    local fovPx=(cam.ViewportSize.X/2)*math.tan(math.rad(_abFov/2))/math.tan(math.rad(cam.FieldOfView/2))
    local bestScore=-math.huge; local bestPart=nil; local bestPlr=nil
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer then
            local char=plr.Character; if char then
                local hum=char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health>0 then
                    local s=_abScore(plr,char,camPos,fovPx)
                    if s and s>bestScore then bestScore=s; bestPlr=plr; bestPart=_getTargetPart(char) end
                end
            end
        end
    end
    _abTarget=bestPlr; if not bestPlr or not bestPart then return end
    local tPos=bestPart.Position
    if _abHumanize then
        tPos=tPos+Vector3.new((math.random()-0.5)*0.10,(math.random()-0.5)*0.10,(math.random()-0.5)*0.10)
    end
    local tCF=CFrame.new(camPos,tPos)
    local camPitch=math.asin(math.clamp(camCF.LookVector.Y,-1,1))
    local tgtPitch=math.asin(math.clamp(tCF.LookVector.Y,-1,1))
    local _,camYaw,_=camCF:ToEulerAnglesYXZ(); local _,tgtYaw,_=tCF:ToEulerAnglesYXZ()
    local dPitch=math.deg(tgtPitch-camPitch); local dYaw=math.deg(tgtYaw-camYaw)
    if dYaw> 180 then dYaw=dYaw-360 end; if dYaw<-180 then dYaw=dYaw+360 end
    local alpha=math.clamp(1-(_abSmoothing/100),0.01,1)
    local eased=function(d) return d*(1-(1-alpha)^3) end
    local maxDeg=_abHumanize and 15 or 360
    local moveX=math.clamp(eased(dYaw),-maxDeg,maxDeg)
    local moveY=math.clamp(eased(dPitch),-maxDeg,maxDeg)
    if _abHumanize and math.random(1,20)==1 then return end
    local sens=cam.ViewportSize.X/cam.FieldOfView
    pcall(function() mousemoverel(moveX*sens*0.85,-moveY*sens*0.85) end)
    if _abRCS then
        local rcs=(_abRCSStrength/100)*1.8
        if _abHumanize then rcs=rcs+(math.random()-0.5)*0.4 end
        pcall(function() mousemoverel(0,rcs) end)
    end
end

local function _abUpdateFovCircle(show)
    if not Drawing then return end
    if not show then if _abFovCircle then pcall(function() _abFovCircle:Remove() end); _abFovCircle=nil end; return end
    if not _abFovCircle then
        _abFovCircle=Drawing.new("Circle"); _abFovCircle.Thickness=1
        _abFovCircle.Filled=false; _abFovCircle.NumSides=64
    end
    local cam=workspace.CurrentCamera
    local fovPx=(cam.ViewportSize.X/2)*math.tan(math.rad(_abFov/2))/math.tan(math.rad(cam.FieldOfView/2))
    _abFovCircle.Radius=fovPx; _abFovCircle.Position=cam.ViewportSize/2
    _abFovCircle.Color=_abTarget and Color3.fromRGB(255,80,80) or _abFovColor; _abFovCircle.Visible=true
end

local function _startAimbot()
    if _abConn then _abConn:Disconnect() end
    _abConn=RunService.RenderStepped:Connect(function()
        if not _abEnabled then return end
        _runAimbot()
        _abUpdateFovCircle(true)
    end)
end
local function _stopAimbot()
    if _abConn then _abConn:Disconnect(); _abConn=nil end
    _abUpdateFovCircle(false); _abTarget=nil
end

-- ════════════════════════════════════════════════════════════════
-- ──  TRIGGERBOT
-- ════════════════════════════════════════════════════════════════
local _tbActive=false; local _tbMode="Toggle"; local _tbDelay=80; local _tbVariance=20; local _tbFilter="Any visible"
local _tbConn=nil
local function _startTriggerLoop()
    if _tbConn then _tbConn:Disconnect() end
    _tbConn=RunService.RenderStepped:Connect(function()
        if not _tbActive then return end
        local cam=workspace.CurrentCamera; local params=RaycastParams.new()
        params.FilterDescendantsInstances={getChar()}; params.FilterType=Enum.RaycastFilterType.Exclude
        local hit=workspace:Raycast(cam.CFrame.Position,cam.CFrame.LookVector*5000,params)
        if not hit then return end
        local part=hit.Instance
        local found=false
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LocalPlayer and plr.Character and part:IsDescendantOf(plr.Character) then
                local hum=plr.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health>0 then
                    if _tbFilter=="Body" and not (part:FindFirstAncestorOfClass("BasePart") and not part:FindFirstAncestorOfClass("Humanoid")) then return end
                    if _tbFilter=="Head only" and part.Parent.Name~="Head" then return end
                    found=true; break
                end
            end
        end
        if found then
            local delay=_tbDelay+math.random(-_tbVariance,_tbVariance)
            task.wait(delay/1000)
            pcall(function() keypress(0x1) end)
            task.wait(0.05)
            pcall(function() keyrelease(0x1) end)
        end
    end)
end
local function _stopTrigger()
    if _tbConn then _tbConn:Disconnect(); _tbConn=nil end
end

-- ════════════════════════════════════════════════════════════════
-- ──  ESP (simplified for demo)
-- ════════════════════════════════════════════════════════════════
local _espEnabled=false; local _espPlayerColors={}
local function enableESP()
    _espEnabled=true
    Hub:Notify({Title="ESP",Message="Enabled",Duration=2})
end
local function clearESP()
    _espEnabled=false
    Hub:Notify({Title="ESP",Message="Disabled",Duration=2})
end

-- ════════════════════════════════════════════════════════════════
-- ──  FLY
-- ════════════════════════════════════════════════════════════════
local _flyEnabled=false; local _flyConn=nil; local _flyDir=Vector3.new(0,0,0)
local function startFly()
    _flyEnabled=true; local hrp=getHRP()
    if not hrp then return end
    if _flyConn then _flyConn:Disconnect() end
    _flyConn=RunService.RenderStepped:Connect(function()
        if not _flyEnabled then return end
        hrp=getHRP(); if not hrp then return end
        local moveDir=Vector3.new(0,0,0)
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir=moveDir+workspace.CurrentCamera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir=moveDir-workspace.CurrentCamera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir=moveDir-workspace.CurrentCamera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir=moveDir+workspace.CurrentCamera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir=moveDir+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir=moveDir-Vector3.new(0,1,0) end
        if moveDir.Magnitude>0 then moveDir=moveDir.Unit end
        hrp.Velocity=moveDir*_flySpeed
    end)
end
local function stopFly()
    _flyEnabled=false; if _flyConn then _flyConn:Disconnect(); _flyConn=nil end
end

-- ════════════════════════════════════════════════════════════════
-- ──  INFINITE JUMP
-- ════════════════════════════════════════════════════════════════
local _infJumpEnabled=false; local _infJumpConn=nil
local function startInfJump()
    _infJumpEnabled=true
    if _infJumpConn then _infJumpConn:Disconnect() end
    _infJumpConn=UIS.InputBegan:Connect(function(input,processed)
        if processed then return end
        if input.KeyCode==Enum.KeyCode.Space and _infJumpEnabled then
            local h=getHum(); if h then h:SetStateEnabled(Enum.HumanoidStateType.Jumping,false) end
        end
    end)
    UIS.InputEnded:Connect(function(input,processed)
        if input.KeyCode==Enum.KeyCode.Space and _infJumpEnabled then
            local h=getHum(); if h then h:SetStateEnabled(Enum.HumanoidStateType.Jumping,true) end
        end
    end)
end
local function stopInfJump()
    _infJumpEnabled=false; if _infJumpConn then _infJumpConn:Disconnect(); _infJumpConn=nil end
end

-- ════════════════════════════════════════════════════════════════
-- ──  SETUP EVENT HOOKS (NEW SYSTEM) ──────────────────────────
-- ════════════════════════════════════════════════════════════════

if EventHooks then
    LocalPlayer.CharacterAdded:Connect(function(char)
        EventHooks:Fire("OnSpawn", LocalPlayer)
    end)
    
    Players.PlayerAdded:Connect(function(plr)
        EventHooks:Fire("OnJoin", plr)
    end)
    
    Players.PlayerRemoving:Connect(function(plr)
        EventHooks:Fire("OnPlayerLeft", plr)
    end)
end

-- ════════════════════════════════════════════════════════════════
-- ──  SETUP LOGGING (NEW SYSTEM) ──────────────────────────────
-- ════════════════════════════════════════════════════════════════

if Logger then
    Logger:StartChatLogging()
    Logger:StartJoinLogging()
end

-- ════════════════════════════════════════════════════════════════
-- ──  SETUP ALIASES (NEW SYSTEM) ──────────────────────────────
-- ════════════════════════════════════════════════════════════════

if Aliases then
    Aliases:Add("gg", "Good game!")
    Aliases:Add("tnx", "Thanks!")
    Aliases:Add("wp", "Well played!")
    Aliases:Add("lol", "Haha!")
    Aliases:Add("bye", "Goodbye!")
    
    Aliases:Add("time", "Current time: %time%")
    Aliases:Add("greet", "Hello %username%!")
    Aliases:Add("whoami", "I'm %username% (ID: %userid%)")
    
    Aliases:Add("hello", "Hey $1, how are you?")
    Aliases:Add("msg", "To $1: $2")
    
    Aliases:Save()
end

-- ════════════════════════════════════════════════════════════════
-- ──  SETUP KEYBIND UI (NEW SYSTEM) ──────────────────────────────
-- ════════════════════════════════════════════════════════════════

if KeybindUI then
    KeybindUI:Register("Aimbot Toggle", Enum.KeyCode.RightAlt, {
        category = "Combat",
        description = "Toggle aimbot",
        onPress = function()
            _abEnabled = not _abEnabled
            if _abEnabled then
                _startAimbot()
                if EventHooks then EventHooks:Fire("AimbotToggled", true) end
            else
                _stopAimbot()
                if EventHooks then EventHooks:Fire("AimbotToggled", false) end
            end
        end
    })
    
    KeybindUI:Register("Noclip Toggle", Enum.KeyCode.N, {
        category = "Movement",
        description = "Toggle noclip",
        onPress = function()
            if _noclipSystem and _noclipSystem.Toggle then
                _noclipSystem:Toggle()
            end
        end
    })
    
    KeybindUI:Register("Fly Toggle", Enum.KeyCode.F, {
        category = "Movement",
        description = "Toggle flight",
        onPress = function()
            if _flyEnabled then
                stopFly()
            else
                startFly()
            end
        end
    })
    
    KeybindUI:Register("ESP Toggle", Enum.KeyCode.E, {
        category = "Visuals",
        description = "Toggle ESP",
        onPress = function()
            if _espEnabled then
                clearESP()
            else
                enableESP()
            end
        end
    })
    
    KeybindUI:Register("Infinite Jump", Enum.KeyCode.G, {
        category = "Movement",
        description = "Toggle infinite jump",
        onPress = function()
            if _infJumpEnabled then
                stopInfJump()
            else
                startInfJump()
            end
        end
    })
    
    KeybindUI:SaveKeybinds()
end

-- ════════════════════════════════════════════════════════════════
-- ──  TABS & SECTIONS ────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

local PlayerTab   = Hub:NewTab({Title="Player",Icon="rbxassetid://3926307641"})
local MoveTab     = Hub:NewTab({Title="Movement",Icon="rbxassetid://3926308105"})
local CombatTab   = Hub:NewTab({Title="Combat",Icon="rbxassetid://3926307641"})
local VisualTab   = Hub:NewTab({Title="Visuals",Icon="rbxassetid://3926305904"})
local UtilTab     = Hub:NewTab({Title="Utility",Icon="rbxassetid://3926307641"})
local SettingsTab = Hub:NewTab({Title="Settings",Icon="rbxassetid://3926307641"})

-- Player Tab
local PlayerSec = PlayerTab:NewSection({Position="Left",Title="Stats"})
PlayerSec:NewSlider({Title="Walk Speed",Min=16,Max=500,Default=16,Callback=function(v) startWsEnforcer(v) end})
PlayerSec:NewSlider({Title="Jump Power",Min=7,Max=300,Default=7,Callback=function(v) local h=getHum(); if h then h.JumpPower=v end end})

local JumpSec = PlayerTab:NewSection({Position="Right",Title="Jump"})
JumpSec:NewToggle({Title="Infinite Jump",Default=false,Callback=function(v) if v then startInfJump() else stopInfJump() end end})

-- Movement Tab
local MoveSec = MoveTab:NewSection({Position="Left",Title="Noclip"})
MoveSec:NewToggle({Title="Noclip",Default=false,Callback=function(v)
    if _noclipSystem then
        if v then _noclipSystem:Enable() else _noclipSystem:Disable() end
    end
end})
MoveSec:NewSlider({Title="Noclip Speed",Min=10,Max=500,Default=50,Callback=function(v)
    if _noclipSystem and _noclipSystem.SetSpeed then _noclipSystem:SetSpeed(v) end
end})

local FlySec = MoveTab:NewSection({Position="Right",Title="Flight"})
FlySec:NewToggle({Title="Flight",Default=false,Callback=function(v) if v then startFly() else stopFly() end end})
FlySec:NewSlider({Title="Flight Speed",Min=10,Max=500,Default=60,Callback=function(v) _flySpeed=v end})

-- Combat Tab
local AimbotSec = CombatTab:NewSection({Position="Left",Title="Aimbot"})
AimbotSec:NewToggle({Title="Aimbot",Default=false,Callback=function(v) _abEnabled=v; if v then _startAimbot() else _stopAimbot() end end})
AimbotSec:NewSlider({Title="FOV",Min=10,Max=360,Default=120,Callback=function(v) _abFov=v end})
AimbotSec:NewSlider({Title="Smoothing",Min=0,Max=100,Default=40,Callback=function(v) _abSmoothing=v end})

local TBSec = CombatTab:NewSection({Position="Right",Title="Triggerbot"})
TBSec:NewToggle({Title="Triggerbot",Default=false,Callback=function(v) _tbActive=v; if v then _startTriggerLoop() else _stopTrigger() end end})
TBSec:NewSlider({Title="Base Delay (ms)",Min=0,Max=200,Default=80,Callback=function(v) _tbDelay=v end})

-- Visuals Tab
local ESPSec = VisualTab:NewSection({Position="Left",Title="ESP"})
ESPSec:NewToggle({Title="Player ESP",Default=false,Callback=function(v) if v then enableESP() else clearESP() end end})

-- Utility Tab
local AutoKeySec = UtilTab:NewSection({Position="Left",Title="Automation"})
if AutoKeyPress then
    AutoKeySec:NewToggle({Title="Record Sequence",Default=false,Callback=function(v)
        if v then
            AutoKeyPress:StartRecording()
            Hub:Notify({Title="Recording",Message="Press keys to record",Duration=2})
        else
            local seq = AutoKeyPress:StopRecording()
            if #seq > 0 then
                AutoKeyPress:SaveSequence("phantom_keyseq.json",seq)
                Hub:Notify({Title="Recorded",Message=#seq.." keys",Duration=2})
            end
        end
    end})
    
    AutoKeySec:NewButton({Title="Play Sequence",Callback=function()
        local seq = AutoKeyPress:LoadSequence("phantom_keyseq.json")
        if seq then
            AutoKeyPress:PlaySequence(seq,1.0,1)
            Hub:Notify({Title="Playing",Message="Sequence started",Duration=2})
        end
    end})
end

-- Settings Tab
local AppearSec = SettingsTab:NewSection({Position="Left",Title="Appearance"})
AppearSec:NewColorPicker({Title="Accent Color",Default=Color3.fromRGB(110,75,255),
    Callback=function(c) Hub:SetAccent(c) end})
AppearSec:NewSlider({Title="Window Opacity %",Min=30,Max=100,Default=95,
    Callback=function(v) Hub._win.BackgroundTransparency=1-(v/100) end})

local DataSec = SettingsTab:NewSection({Position="Right",Title="Config"})
DataSec:NewButton({Title="Save Config",Callback=function()
    SM:Save()
    if Aliases then Aliases:Save() end
    if KeybindUI then KeybindUI:SaveKeybinds() end
    Hub:Notify({Title="Config",Message="Saved",Duration=2})
end})

DataSec:NewButton({Title="Load Config",Callback=function()
    SM:Load()
    if Aliases then Aliases:Load() end
    if KeybindUI then KeybindUI:LoadKeybinds() end
    Hub:Notify({Title="Config",Message="Loaded",Duration=2})
end})

local LoggingSec = SettingsTab:NewSection({Position="Right",Title="Logging"})
if Logger then
    LoggingSec:NewButton({Title="Export Chat Logs",Callback=function()
        Logger:ExportChatLogs()
        Hub:Notify({Title="Exported",Message="Chat logs saved",Duration=2})
    end})
    
    LoggingSec:NewButton({Title="Export Join Logs",Callback=function()
        Logger:ExportJoinLogs()
        Hub:Notify({Title="Exported",Message="Join logs saved",Duration=2})
    end})
    
    LoggingSec:NewButton({Title="Cleanup Old Logs",Callback=function()
        Logger:CleanupOldLogs(7)
        Hub:Notify({Title="Cleanup",Message="Old logs removed",Duration=2})
    end})
end

local KeybindSec = SettingsTab:NewSection({Position="Right",Title="Keybinds"})
if KeybindUI then
    KeybindUI:CreateSettingsUI(SettingsTab)
end

SettingsTab._btn.Visible = false
Hub:AutoSave("phantom", 60)

-- ════════════════════════════════════════════════════════════════
-- ──  PANIC KEY WIRING (all variables now in scope)
-- ════════════════════════════════════════════════════════════════

_panicShutdown = function()
    pcall(stopWsEnforcer)
    pcall(stopFly)
    pcall(stopInfJump)
    pcall(_stopAimbot)
    pcall(_stopTrigger)
    pcall(clearESP)
    
    if Noclip then pcall(function() Noclip:Cleanup() end) end
    if Logger then pcall(function() Logger:Cleanup() end) end
    if AutoKeyPress then pcall(function() AutoKeyPress:StopAll() end) end
    if Aliases then pcall(function() Aliases:Save() end) end
    if KeybindUI then pcall(function() KeybindUI:SaveKeybinds() end) end
    
    SM:Save()
    
    _showDisengagedOverlay()
end

-- ════════════════════════════════════════════════════════════════
-- ──  AUTOSAVE LOOP (all systems)
-- ════════════════════════════════════════════════════════════════

task.spawn(function()
    while true do
        task.wait(60)
        pcall(function() SM:Save() end)
        if Aliases then pcall(function() Aliases:Save() end) end
        if KeybindUI then pcall(function() KeybindUI:SaveKeybinds() end) end
        if Logger then
            pcall(function() Logger:ExportChatLogs() end)
            pcall(function() Logger:ExportJoinLogs() end)
        end
    end
end)

-- ════════════════════════════════════════════════════════════════
-- ──  STARTUP NOTIFICATION
-- ════════════════════════════════════════════════════════════════

Hub:Notify({
    Title = "Phantom v3.0 Enhanced",
    Message = "Loaded from GitHub: " .. GITHUB_USERNAME .. "/" .. GITHUB_REPO,
    Duration = 6,
})

print("[Phantom] ✓ Enhanced Hub fully initialized!")
print("[Phantom] GitHub: " .. GITHUB_USERNAME .. "/" .. GITHUB_REPO)
print("[Phantom] Press J to toggle menu")

-- ════════════════════════════════════════════════════════════════
-- ──  EXPOSE API FOR EXTERNAL SCRIPTS  ──────────────────────────
-- ════════════════════════════════════════════════════════════════

_G.PhantomHub = {
    Hub = Hub,
    Phantom = Phantom,
    Players = Players,
    RunService = RunService,
    UIS = UIS,
    LocalPlayer = LocalPlayer,
    getChar = getChar,
    getHum = getHum,
    getHRP = getHRP,
    startAimbot = _startAimbot,
    stopAimbot = _stopAimbot,
    enableESP = enableESP,
    clearESP = clearESP,
    PlaceId = game.PlaceId,
    
    EventHooks = EventHooks,
    Noclip = _noclipSystem,
    Logger = Logger,
    Aliases = Aliases,
    AutoKeyPress = AutoKeyPress,
    PluginManager = PluginManager,
    KeybindUI = KeybindUI,
    
    Await = function(self)
        return self
    end
}
