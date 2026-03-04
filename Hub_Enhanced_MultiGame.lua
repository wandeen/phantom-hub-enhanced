-- ╔════════════════════════════════════════════════════════════════════════════════╗
-- ║         PHANTOM HUB ENHANCED - v3.5                                          ║
-- ║  ✅ Improved aimbot (smooth, wall-check, bone target, team filter, lock)      ║
-- ║  ✅ Upgraded ESP (health/dist/lookline, survives death+rejoin)                ║
-- ║  ✅ Teleport + Server Hop + Auto Rejoin (restored)                           ║
-- ║  ✅ Working Noclip (dual-method)                                             ║
-- ╚════════════════════════════════════════════════════════════════════════════════╝

-- ── Load UI Library ──────────────────────────────────────────────────────────
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

-- ── Services ──────────────────────────────────────────────────────────────
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UIS            = game:GetService("UserInputService")
local Lighting       = game:GetService("Lighting")
local PhysicsService = game:GetService("PhysicsService")
local LocalPlayer    = Players.LocalPlayer

-- ── Helpers ───────────────────────────────────────────────────────────────
local function getChar() return LocalPlayer.Character end
local function getHum()  local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end

-- ════════════════════════════════════════════════════════════════════════════════
-- ──  PANIC KEY  (Delete)
-- ════════════════════════════════════════════════════════════════════════════════
local _panicShutdown

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

-- ── Create Window (BIGGER SIZE) ────────────────────────────────────────────
local Hub = Phantom.new({
    Title    = "Phantom",
    Subtitle = "hub",
    Keybind  = Enum.KeyCode.J,
})
Hub:SetProfile()
Hub._win.BackgroundTransparency = 0.05
Hub._win.Size = UDim2.new(0, 900, 0, 550)  -- BIGGER WINDOW

-- ════════════════════════════════════════════════════════════════════════════════
-- ──  SETTINGS MANAGER (from original)
-- ════════════════════════════════════════════════════════════════════════════════
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
    function() return _G.PhantomJumpPower or 50 end,
    function(v) _G.PhantomJumpPower=v; local h=getHum(); if h then h.JumpPower=v end end)
SM:Register("FlySpeed",
    function() return _flySpeed end,
    function(v) _flySpeed=v end)
SM:Load(); SM:StartAutoApply()

-- ════════════════════════════════════════════════════════════════════════════════
-- ──  IMPROVED NOCLIP (MY DUAL-METHOD SYSTEM)
-- ════════════════════════════════════════════════════════════════════════════════
local _noclipEnabled = false
local _noclipConn, _noclipPartConn, _noclipCharConn = nil, nil, nil
local _noclipGroup = "PhantomNoclip"
local _noclipGroupReady = false

pcall(function()
    pcall(function() PhysicsService:RegisterCollisionGroup(_noclipGroup) end)
    PhysicsService:CollisionGroupSetCollidable(_noclipGroup, "Default", false)
    PhysicsService:CollisionGroupSetCollidable(_noclipGroup, _noclipGroup, false)
    _noclipGroupReady = true
end)

local function _ncPart(part, on)
    part.CanCollide = not on
    if _noclipGroupReady then pcall(function() part.CollisionGroup = on and _noclipGroup or "Default" end) end
end

local function _ncChar(char, on)
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then _ncPart(d, on) end
    end
end

local function _enableNoclip()
    _noclipEnabled = true
    local char = getChar()
    if char then _ncChar(char, true) end
    
    if _noclipConn then _noclipConn:Disconnect() end
    _noclipConn = RunService.RenderStepped:Connect(function()
        if not _noclipEnabled then return end
        local c = getChar()
        if not c then return end
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") and d.CanCollide then d.CanCollide = false end
        end
    end)
    
    if char then
        if _noclipPartConn then _noclipPartConn:Disconnect() end
        _noclipPartConn = char.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") and _noclipEnabled then
                task.defer(function() pcall(function() _ncPart(d, true) end) end)
            end
        end)
    end
    
    if _noclipCharConn then _noclipCharConn:Disconnect() end
    _noclipCharConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(0.3)
        if not _noclipEnabled then return end
        _ncChar(newChar, true)
        if _noclipPartConn then _noclipPartConn:Disconnect() end
        _noclipPartConn = newChar.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") and _noclipEnabled then
                task.defer(function() pcall(function() _ncPart(d, true) end) end)
            end
        end)
    end)
end

local function _disableNoclip()
    _noclipEnabled = false
    if _noclipConn then _noclipConn:Disconnect(); _noclipConn = nil end
    if _noclipPartConn then _noclipPartConn:Disconnect(); _noclipPartConn = nil end
    if _noclipCharConn then _noclipCharConn:Disconnect(); _noclipCharConn = nil end
    _ncChar(getChar(), false)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- ──  WALK SPEED ENFORCER
-- ════════════════════════════════════════════════════════════════════════════════
local _wsTarget = 16
local _wsConn = nil
local function startWsEnforcer(speed)
    _wsTarget = speed
    if _wsConn then _wsConn:Disconnect() end
    _wsConn = RunService.Heartbeat:Connect(function()
        local h = getHum()
        if h and h.WalkSpeed ~= _wsTarget then h.WalkSpeed = _wsTarget end
    end)
end
local function stopWsEnforcer()
    if _wsConn then _wsConn:Disconnect(); _wsConn = nil end
end

-- ════════════════════════════════════════════════════════════════════════════════
-- ──  AIMBOT  (Heartbeat assist · bone targeting · wall check · sticky lock)
-- ─────────────────────────────────────────────────────────────────────────────
--  • Bone targeting  — Head / Neck / HRP (configurable)
--  • Wall check      — raycast; skip targets behind geometry
--  • Team filter     — never aims at teammates
--  • Smoothing       — Heartbeat lerp so mouse input is never blocked
--  • Target lock     — stays on acquired target until they die / hide behind wall
-- ════════════════════════════════════════════════════════════════════════════════
local _abEnabled    = false
local _abMode       = "Toggle"
local _abKey        = Enum.KeyCode.RightAlt
local _abKeyName    = "RightAlt"
local _abFov        = 150
local _abPrediction = 0.1768521
local _abSmoothing  = 0.35    -- 0=instant snap  1=no movement (0.1–0.5 is best)
local _abBone       = "Head"  -- "Head" | "Neck" | "HRP"
local _abWallCheck  = true
local _abTeamCheck  = true
local _abConn       = nil
local _abTarget     = nil     -- {part=BasePart, player=Player}  or  nil

-- ── helpers ───────────────────────────────────────────────────────────────────
local function _abGetBonePart(char)
    if _abBone == "Head" then
        return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    elseif _abBone == "Neck" then
        -- Try neck attachment on UpperTorso (R15) or Torso (R6)
        local ut = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if ut then
            local att = ut:FindFirstChild("NeckAttachment")
            if att then return ut, att end  -- returns part + attachment
        end
        return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    else -- HRP
        return char:FindFirstChild("HumanoidRootPart")
    end
end

local function _abGetBonePos(char)
    if _abBone == "Neck" then
        local ut = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if ut then
            local att = ut:FindFirstChild("NeckAttachment")
            if att then return (ut.CFrame * att.CFrame).Position end
        end
    end
    local part = _abGetBonePart(char)
    return part and part.Position or nil
end

local function _abIsWallBlocked(targetPos)
    local cam     = workspace.CurrentCamera
    local origin  = cam.CFrame.Position
    local dir     = (targetPos - origin)
    local dist    = dir.Magnitude - 0.5   -- stop just before the target
    if dist <= 0 then return false end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character or workspace}
    params.FilterType = Enum.RaycastFilterType.Exclude

    -- Also exclude all enemy characters so we don't stop on their own parts
    local filter = {LocalPlayer.Character}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then table.insert(filter, plr.Character) end
    end
    params.FilterDescendantsInstances = filter

    local result = workspace:Raycast(origin, dir.Unit * dist, params)
    return result ~= nil   -- hit something = blocked
end

local function _abIsValidTarget(plr)
    if plr == LocalPlayer then return false end
    if _abTeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then
        return false
    end
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    return true
end

local function _abGetScreenDist(worldPos)
    local cam = workspace.CurrentCamera
    local screenPos, onScreen = cam:WorldToViewportPoint(worldPos)
    if not onScreen then return math.huge end
    local center = Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)
    return (center - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
end

local function _abFindBestTarget()
    local best     = nil
    local bestDist = math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if _abIsValidTarget(plr) then
            local char    = plr.Character
            local bonePos = _abGetBonePos(char)
            if bonePos then
                local d = _abGetScreenDist(bonePos)
                if d < _abFov and d < bestDist then
                    -- wall check here keeps the list accurate
                    if not _abWallCheck or not _abIsWallBlocked(bonePos) then
                        bestDist = d
                        local part = _abGetBonePart(char)
                        best = {part = part, player = plr}
                    end
                end
            end
        end
    end
    return best
end

local function _abGetPredicted(target)
    if not target or not target.part then return nil end
    local part = target.part
    if not part.Parent then return nil end
    local vel  = pcall(function() return part.Velocity end) and part.Velocity or Vector3.new()
    return part.Position + vel * _abPrediction
end

local function _runAimbot()
    -- ── target lock maintenance ─────────────────────────────────────────────────
    --  Only drop lock when target is truly gone (dead / left / behind wall).
    local keepLock = false
    if _abTarget then
        local plr  = _abTarget.player
        local part = _abTarget.part
        if _abIsValidTarget(plr) and part and part.Parent then
            local bonePos = _abGetBonePos(plr.Character)
            if bonePos then
                if not _abWallCheck or not _abIsWallBlocked(bonePos) then
                    keepLock = true
                end
            end
        end
    end

    if not keepLock then
        _abTarget = _abFindBestTarget()
    end

    if not _abTarget then return end

    -- ── predicted world position ─────────────────────────────────────────────
    local predicted = _abGetPredicted(_abTarget)
    if not predicted then _abTarget = nil; return end

    -- ── normal aim: rotate camera toward target with smoothing ───────────────
    local cam     = workspace.CurrentCamera
    local targetCF = CFrame.new(cam.CFrame.Position, predicted)
    -- Spherical lerp between current and target orientation
    local alpha   = math.clamp(1 - _abSmoothing, 0.01, 1)
    cam.CFrame    = cam.CFrame:Lerp(targetCF, alpha)
end

-- ── FOV circle (Drawing API) ─────────────────────────────────────────────────
local _fovCircle = nil

local function _createFovCircle()
    pcall(function()
        if _fovCircle then pcall(function() _fovCircle:Remove() end); _fovCircle = nil end
        if not Drawing then return end
        local c = Drawing.new("Circle")
        c.Thickness      = 1
        c.NumSides       = 64
        c.Color          = Color3.fromRGB(255, 255, 255)
        c.Filled         = false
        c.Transparency   = 1        -- fully opaque in Drawing API
        c.Visible        = false
        _fovCircle = c
    end)
end

local function _destroyFovCircle()
    pcall(function()
        if _fovCircle then _fovCircle:Remove(); _fovCircle = nil end
    end)
end

local function _updateFovCircle()
    if not _fovCircle then return end
    pcall(function()
        local cam = workspace.CurrentCamera
        _fovCircle.Position = Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)
        _fovCircle.Radius   = _abFov
        _fovCircle.Visible  = _abEnabled
    end)
end

_createFovCircle()  -- create on script load (Drawing is always available in exploits)

-- ── Aimbot loop ─────────────────────────────────────────────────────────────
local _abConn = nil   -- Heartbeat connection for aimbot assist loop
local _fovConn = nil  -- separate RenderStepped for the FOV circle (visual only)

local function _startAimbot()
    -- FOV circle: update every render frame (pure visual, no cam manipulation)
    if _fovConn then _fovConn:Disconnect() end
    _fovConn = RunService.RenderStepped:Connect(_updateFovCircle)

    -- Aimbot assist: runs on Heartbeat so it DOES NOT override mouse input.
    -- Roblox's camera module processes mouse on RenderStepped AFTER Heartbeat,
    -- which means: aimbot nudges camera → mouse adds its delta on top.
    -- Net result: you can move freely, aimbot just pulls you toward target.
    if _abConn then _abConn:Disconnect() end
    _abConn = RunService.Heartbeat:Connect(function()
        if not _abEnabled then _abTarget = nil; return end
        if _abMode == "Hold" and not UIS:IsKeyDown(_abKey) then
            _abTarget = nil; return
        end
        if UIS:GetFocusedTextBox() then _abTarget = nil; return end
        _runAimbot()
    end)
end

local function _stopAimbot()
    _abEnabled = false
    if _abConn  then _abConn:Disconnect();  _abConn  = nil end
    if _fovConn then _fovConn:Disconnect(); _fovConn = nil end
    _abTarget = nil
    _destroyFovCircle()
end

-- ════════════════════════════════════════════════════════════════════════════════
-- ──  IMPROVED TRIGGERBOT (Visible + Crosshair Check)
-- ════════════════════════════════════════════════════════════════════════════════
local _tbActive = false
local _tbMode = "Toggle"
local _tbKey = Enum.KeyCode.T
local _tbDelay = 80
local _tbVariance = 20
local _tbFilter = "Any visible"
local _tbConn = nil
local _tbFiring = false

local function _tbRaycast(char)
    local cam = workspace.CurrentCamera
    local vp = cam.ViewportSize
    local ray = cam:ScreenPointToRay(vp.X * 0.5, vp.Y * 0.5)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
    if not result then return false end
    
    local hit = result.Instance
    if _tbFilter == "Head only" then return hit.Name == "Head" end
    if _tbFilter == "Body" then
        for _, n in ipairs({"Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart"}) do
            if hit.Name == n then return true end
        end
        return false
    end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            if hit:IsDescendantOf(plr.Character) then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                return hum and hum.Health > 0
            end
        end
    end
    return false
end

local function _tbFire()
    if _tbFiring then return end
    _tbFiring = true
    task.spawn(function()
        local char = getChar()
        if not char then _tbFiring = false; return end
        if not _tbRaycast(char) then _tbFiring = false; return end
        task.wait(math.max(0, (_tbDelay + math.random(-_tbVariance, _tbVariance)) / 1000))
        if not _tbActive then _tbFiring = false; return end
        pcall(function()
            local VU = game:GetService("VirtualUser")
            VU:Button1Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(0.05)
            VU:Button1Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
        _tbFiring = false
    end)
end

local function _startTriggerLoop()
    if _tbConn then _tbConn:Disconnect() end
    _tbConn = RunService.Heartbeat:Connect(function()
        if not _tbActive then return end
        if UIS:GetFocusedTextBox() then return end
        if _tbMode == "Hold" and not UIS:IsKeyDown(_tbKey) then return end
        _tbFire()
    end)
end

local function _stopTrigger()
    _tbActive = false
    if _tbConn then _tbConn:Disconnect(); _tbConn = nil end
end

-- ════════════════════════════════════════════════════════════════════════════════
-- ──  UPGRADED ESP  (character-keyed — survives death, respawn, and rejoin)
-- ─────────────────────────────────────────────────────────────────────────────
--  Keyed by CHARACTER (not player) so cleanup is unambiguous.
--  CharacterAdded / CharacterRemoving are connected per-player;
--  PlayerAdded handles latecomers; PlayerRemoving cleans up fully.
--  The update loop runs on Heartbeat and updates all labels every frame.
-- ════════════════════════════════════════════════════════════════════════════════
local _ESP = {
    Active       = false,
    Glow         = true,
    ShowNames    = true,
    ShowHealth   = true,
    ShowDistance = true,
    ShowLookLine = true,
    TeamCheck    = false,
    TeamColor    = false,
    ShowEnemies  = true,
    ShowTeam     = false,
    Color        = Color3.fromRGB(255, 170, 60),
    FillTrans    = 0.65,
    Range        = 1000,
    LookLineLen  = 15,
    LookLineDist = 1.5,
}

-- [character] = { Player, Folder, Highlight, Billboard, NameLabel, HealthLabel, DistLabel, LLFolder }
local _espTracked    = {}
local _espPlayerConns= {}   -- [player] = { charAddedConn, charRemovingConn }
local _espGlobalConns= {}   -- PlayerAdded, PlayerRemoving
local _espUpdateConn = nil

-- ── look-line helpers ─────────────────────────────────────────────────────────
local function _espHideLL(folder)
    if not folder then return end
    for _, p in ipairs(folder:GetChildren()) do
        if p:IsA("BasePart") then p.Transparency = 1 end
    end
end

local function _espMakeLL(folder, count)
    for _, p in ipairs(folder:GetChildren()) do p:Destroy() end
    for i = 1, count do
        local p = Instance.new("Part")
        p.Name = "LL"..i; p.Anchored = true; p.CanCollide = false
        p.CanTouch = false; p.CanQuery = false
        p.Size = Vector3.new(0.15,0.15,0.15); p.Transparency = 1
        p.Color = _ESP.Color; p.Material = Enum.Material.Neon
        p.Shape = Enum.PartType.Ball; p.Parent = folder
    end
end

local function _espUpdateLL(char, folder)
    if not _ESP.ShowLookLine then _espHideLL(folder); return end
    local head = char:FindFirstChild("Head")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not head or not hum then _espHideLL(folder); return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local lv
    if hum.MoveDirection.Magnitude > 0.1 then
        lv = hum.MoveDirection.Unit
    elseif root then
        lv = root.CFrame.LookVector
    else
        lv = head.CFrame.LookVector
    end
    for _, p in ipairs(folder:GetChildren()) do
        if p:IsA("BasePart") then
            local idx = tonumber(p.Name:match("LL(%d+)"))
            if idx then
                p.Position = head.Position + lv * (idx * _ESP.LookLineDist)
                p.Color    = _ESP.Color
                local t = (idx - 1) / math.max(_ESP.LookLineLen - 1, 1)
                p.Transparency = 0.3 + t * 0.7
                local s = (1 - t * 0.5) * 0.15
                p.Size = Vector3.new(s, s, s)
            end
        end
    end
end

-- ── create / remove ESP for a specific character ──────────────────────────────
local function _espCreate(char, plr)
    if not char or char:FindFirstChild("_PhESP") then return end

    local folder = Instance.new("Folder"); folder.Name = "_PhESP"; folder.Parent = char

    local hl = Instance.new("Highlight")
    hl.Adornee = char; hl.FillColor = _ESP.Color
    hl.OutlineColor = Color3.fromRGB(255,255,255); hl.FillTransparency = _ESP.FillTrans
    hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false; hl.Parent = folder

    local bill = Instance.new("BillboardGui")
    bill.Size = UDim2.new(0,200,0,80); bill.StudsOffset = Vector3.new(0,3,0)
    bill.AlwaysOnTop = true; bill.Enabled = false; bill.Parent = folder

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,1,0); frame.BackgroundTransparency = 1; frame.Parent = bill

    local function lbl(nm,sz,pos,fn,ts,col)
        local l = Instance.new("TextLabel"); l.Name = nm; l.Size = sz; l.Position = pos
        l.BackgroundTransparency = 1; l.Font = fn; l.TextSize = ts; l.TextColor3 = col
        l.TextStrokeTransparency = 0; l.TextStrokeColor3 = Color3.new(0,0,0); l.Parent = frame
        return l
    end

    local nameLbl = lbl("Name", UDim2.new(1,0,0.33,0), UDim2.new(0,0,0,0),
        Enum.Font.GothamBold, 16, _ESP.Color)
    nameLbl.Text = plr.Name

    local hpLbl = lbl("HP", UDim2.new(1,0,0.33,0), UDim2.new(0,0,0.33,0),
        Enum.Font.Gotham, 14, Color3.fromRGB(0,255,0))
    hpLbl.Text = "HP: ?"

    local distLbl = lbl("Dist", UDim2.new(1,0,0.34,0), UDim2.new(0,0,0.66,0),
        Enum.Font.Gotham, 12, Color3.fromRGB(255,255,255))
    distLbl.Text = "0m"

    local llf = Instance.new("Folder"); llf.Name = "LL"; llf.Parent = folder
    _espMakeLL(llf, _ESP.LookLineLen)

    _espTracked[char] = {
        Player = plr, Folder = folder, Highlight = hl, Billboard = bill,
        NameLabel = nameLbl, HealthLabel = hpLbl, DistLabel = distLbl, LLFolder = llf,
    }
end

local function _espRemove(char)
    local d = _espTracked[char]; if not d then return end
    pcall(function() d.Folder:Destroy() end)
    _espTracked[char] = nil
end

local function _espUpdateChar(char)
    local d = _espTracked[char]; if not d then return end
    local plr = d.Player; if not plr then return end

    if not _ESP.Active then
        d.Highlight.Enabled = false; d.Billboard.Enabled = false
        _espHideLL(d.LLFolder); return
    end

    -- Team filter
    local isEnemy = true
    if plr.Team and LocalPlayer.Team then isEnemy = plr.Team ~= LocalPlayer.Team end
    local shouldShow = (isEnemy and _ESP.ShowEnemies) or (not isEnemy and _ESP.ShowTeam)
    if _ESP.TeamCheck and not shouldShow then
        d.Highlight.Enabled = false; d.Billboard.Enabled = false
        _espHideLL(d.LLFolder); return
    end

    -- Distance filter
    local primary = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not primary then return end
    local lpChar = LocalPlayer.Character
    local lpRoot = lpChar and (lpChar:FindFirstChild("HumanoidRootPart") or lpChar:FindFirstChild("Head"))
    local dist   = lpRoot and (primary.Position - lpRoot.Position).Magnitude or 0

    if dist > _ESP.Range then
        d.Highlight.Enabled = false; d.Billboard.Enabled = false
        _espHideLL(d.LLFolder); return
    end

    local col = _ESP.Color
    if _ESP.TeamColor and plr.Team and plr.Team.TeamColor then
        col = plr.Team.TeamColor.Color
    end

    d.Highlight.Enabled        = _ESP.Glow
    d.Highlight.OutlineColor   = col
    d.Highlight.FillColor      = col
    d.Highlight.FillTransparency = _ESP.FillTrans
    d.Highlight.Adornee        = char

    d.Billboard.Enabled  = _ESP.ShowNames or _ESP.ShowHealth or _ESP.ShowDistance
    d.Billboard.Adornee  = primary

    d.NameLabel.Visible      = _ESP.ShowNames
    d.NameLabel.TextColor3   = col
    d.NameLabel.Text         = plr.Name

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        d.HealthLabel.Visible = _ESP.ShowHealth
        local pct = hum.Health / math.max(hum.MaxHealth, 1)
        d.HealthLabel.TextColor3 = Color3.new(1 - pct, pct, 0)
        d.HealthLabel.Text = "HP: "..math.floor(hum.Health).."/"..math.floor(hum.MaxHealth)
    else
        d.HealthLabel.Visible = false
    end

    d.DistLabel.Visible = _ESP.ShowDistance
    d.DistLabel.Text    = math.floor(dist).."m"

    _espUpdateLL(char, d.LLFolder)
end

-- ── per-player connection setup ───────────────────────────────────────────────
local function _espConnectPlayer(plr)
    if plr == LocalPlayer then return end
    if _espPlayerConns[plr] then return end  -- already connected

    local function onCharAdded(char)
        -- Small wait so the character is fully assembled before we attach visuals
        task.wait(0.15)
        if not char.Parent then return end  -- respawn cancelled or died instantly
        if _ESP.Active then _espCreate(char, plr) end
    end

    local function onCharRemoving(char)
        _espRemove(char)
    end

    local ca = plr.CharacterAdded:Connect(onCharAdded)
    local cr = plr.CharacterRemoving:Connect(onCharRemoving)
    _espPlayerConns[plr] = {ca, cr}

    -- Handle character that was already present when we connected
    if plr.Character then
        task.spawn(onCharAdded, plr.Character)
    end
end

local function _espDisconnectPlayer(plr)
    local conns = _espPlayerConns[plr]
    if conns then
        for _, c in ipairs(conns) do c:Disconnect() end
        _espPlayerConns[plr] = nil
    end
    -- Clean up any tracked characters belonging to this player
    for char, d in pairs(_espTracked) do
        if d.Player == plr then _espRemove(char) end
    end
end

-- ── public API ────────────────────────────────────────────────────────────────
local function enableESP()
    _ESP.Active = true

    for _, plr in ipairs(Players:GetPlayers()) do
        _espConnectPlayer(plr)
    end

    local pa = Players.PlayerAdded:Connect(function(plr)
        _espConnectPlayer(plr)
    end)
    local pr = Players.PlayerRemoving:Connect(function(plr)
        _espDisconnectPlayer(plr)
    end)
    _espGlobalConns = {pa, pr}

    if _espUpdateConn then _espUpdateConn:Disconnect() end
    _espUpdateConn = RunService.Heartbeat:Connect(function()
        for char in pairs(_espTracked) do
            if char.Parent then
                pcall(_espUpdateChar, char)
            else
                _espRemove(char)
            end
        end
    end)
end

local function clearESP()
    _ESP.Active = false
    if _espUpdateConn then _espUpdateConn:Disconnect(); _espUpdateConn = nil end
    for _, c in ipairs(_espGlobalConns) do c:Disconnect() end
    _espGlobalConns = {}
    for plr in pairs(_espPlayerConns) do _espDisconnectPlayer(plr) end
    -- Any remaining tracked chars (shouldn't be any, but belt-and-suspenders)
    for char in pairs(_espTracked) do _espRemove(char) end
end

-- ════════════════════════════════════════════════════════════════════════════════
-- ──  IMPROVED SPECTATOR LIST (Real-time with alerts)
-- ════════════════════════════════════════════════════════════════════════════════
local _spectActive = false
local _spectAlert = true
local _spectStreamer = false
local _spectLastCount = 0
local _spectConn = nil
local _spectGui = nil
local _spectHistory = {}

local function _makeSpectGui()
    if _spectGui then pcall(function() _spectGui:Destroy() end); _spectGui = nil end
    local sg = Instance.new("ScreenGui")
    sg.Name = "PhantomSpectList"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 99
    local ok, cg = pcall(function() return cloneref(game:GetService("CoreGui")) end)
    sg.Parent = ok and cg or LocalPlayer:WaitForChild("PlayerGui")
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 20)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Parent = sg
    local c2 = Instance.new("UICorner")
    c2.CornerRadius = UDim.new(0, 6)
    c2.Parent = frame
    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, 2)
    l.Parent = frame
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, 4)
    p.PaddingBottom = UDim.new(0, 4)
    p.PaddingLeft = UDim.new(0, 6)
    p.PaddingRight = UDim.new(0, 6)
    p.Parent = frame
    _spectGui = sg
    return frame
end

local function _rebuildSpectList()
    if not _spectActive then return end
    local container = _makeSpectGui()
    local spectNames = {}
    pcall(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then
                    table.insert(spectNames, plr.Name)
                end
            end
        end
    end)
    
    local count = #spectNames
    local isAlert = count > _spectLastCount
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 16)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.TextSize = 11
    header.TextColor3 = isAlert and Color3.fromRGB(255, 220, 50) or Color3.fromRGB(180, 180, 180)
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text = "Spectators: " .. count
    header.Parent = container
    
    for _, name in ipairs(spectNames) do
        local row = Instance.new("TextLabel")
        row.Size = UDim2.new(1, 0, 0, 13)
        row.BackgroundTransparency = 1
        row.Font = Enum.Font.Gotham
        row.TextSize = 10
        row.TextColor3 = Color3.fromRGB(200, 200, 200)
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.Text = "  - " .. name
        row.Parent = container
    end
    
    if isAlert and _spectAlert then
        Hub:Notify({Title = "Spectator Alert", Message = "Someone is watching!", Duration = 3})
    end
    
    if _spectStreamer and count > 0 then
        if _abEnabled then _stopAimbot() end
        if _tbActive then _stopTrigger() end
    end
    
    _spectLastCount = count
end

-- ════════════════════════════════════════════════════════════════════════════════
-- ──  FLIGHT (YOUR ORIGINAL)
-- ════════════════════════════════════════════════════════════════════════════════
local _flyEnabled = false
local _flyConn = nil
local _flyCharConn = nil
local _bodyVel = nil
local _bodyGyro = nil

local function stopFly()
    _flyEnabled = false
    if _flyConn then _flyConn:Disconnect(); _flyConn = nil end
    pcall(function()
        if _bodyVel then _bodyVel:Destroy(); _bodyVel = nil end
        if _bodyGyro then _bodyGyro:Destroy(); _bodyGyro = nil end
    end)
    local h = getHum()
    if h then h.PlatformStand = false end
end

local function startFly()
    stopFly()
    _flyEnabled = true
    local char = getChar()
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    hum.PlatformStand = true
    _bodyVel = Instance.new("BodyVelocity")
    _bodyVel.Velocity = Vector3.new(0, 0, 0)
    _bodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    _bodyVel.Parent = hrp
    _bodyGyro = Instance.new("BodyGyro")
    _bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    _bodyGyro.D = 100
    _bodyGyro.CFrame = hrp.CFrame
    _bodyGyro.Parent = hrp
    local cam = workspace.CurrentCamera
    _flyConn = RunService.Heartbeat:Connect(function()
        if not _flyEnabled or not hrp.Parent then return end
        local dir = Vector3.new(0, 0, 0)
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
            dir = dir - Vector3.new(0, 1, 0)
        end
        _bodyVel.Velocity = dir.Magnitude > 0 and dir.Unit * _flySpeed or Vector3.new(0, 0, 0)
        _bodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
    end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- ──  INFINITE JUMP (YOUR ORIGINAL)
-- ════════════════════════════════════════════════════════════════════════════════
local _infJumpConn = nil

-- ════════════════════════════════════════════════════════════════════════════════
-- ──  BUILD UNIVERSAL TAB (BIGGER, CLEANER)
-- ════════════════════════════════════════════════════════════════════════════════

local UniTab = Hub:NewTab({Title = "Universal", Icon = "rbxassetid://3926305904"})

-- Player Section
local UniPlayer = UniTab:NewSection({Position = "Left", Title = "Player"})
UniPlayer:NewSlider({
    Title = "Walk Speed",
    Min = 16,
    Max = 300,
    Default = 16,
    Callback = function(v)
        _G.PhantomWalkSpeed = v
        if v > 16 then startWsEnforcer(v) else stopWsEnforcer(); local h = getHum(); if h then h.WalkSpeed = v end end
    end,
})
UniPlayer:NewSlider({
    Title = "Jump Power",
    Min = 7,
    Max = 200,
    Default = 50,
    Callback = function(v) _G.PhantomJumpPower = v; local h = getHum(); if h then h.JumpPower = v end end,
})
UniPlayer:NewToggle({
    Title = "Infinite Jump",
    Default = false,
    Callback = function(v)
        if _infJumpConn then _infJumpConn:Disconnect(); _infJumpConn = nil end
        if v then _infJumpConn = UIS.JumpRequest:Connect(function()
            local h = getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end) end
    end,
})

-- Movement Section
local UniMove = UniTab:NewSection({Position = "Left", Title = "Movement"})
UniMove:NewSlider({
    Title = "Fly Speed",
    Min = 10,
    Max = 200,
    Default = 60,
    Callback = function(v) _flySpeed = v end,
})
UniMove:NewToggle({
    Title = "Flight [WASD + Space/Ctrl]",
    Default = false,
    Callback = function(v)
        if v then
            startFly()
            if not _flyCharConn then
                _flyCharConn = LocalPlayer.CharacterAdded:Connect(function()
                    if _flyEnabled then task.wait(0.5); startFly() end
                end)
            end
        else
            stopFly()
        end
    end,
})
UniMove:NewToggle({
    Title = "Noclip",
    Default = false,
    Callback = function(v) if v then _enableNoclip() else _disableNoclip() end end,
})


-- Combat Section
local UniCombat = UniTab:NewSection({Position = "Right", Title = "Combat"})
UniCombat:NewToggle({
    Title = "Aimbot",
    Default = false,
    Callback = function(v)
        _abEnabled = v
        if v then
            _createFovCircle()
            _startAimbot()
        else
            _stopAimbot()
        end
    end
})
UniCombat:NewDropdown({
    Title = "Aimbot Mode",
    Options = {"Toggle", "Hold"},
    Default = "Toggle",
    Callback = function(v) _abMode = v end
})
UniCombat:NewDropdown({
    Title = "Aimbot Hold Key",
    Options = {"RightAlt","E","Q","F","G","X","Z","CapsLock","Tab"},
    Default = "RightAlt",
    Callback = function(v) _abKeyName = v; _abKey = Enum.KeyCode[v] end
})
UniCombat:NewDropdown({
    Title = "Target Bone",
    Options = {"Head", "Neck", "HRP"},
    Default = "Head",
    Callback = function(v) _abBone = v end
})
UniCombat:NewSlider({
    Title = "Aimbot FOV (px)",
    Min = 10, Max = 400, Default = 150,
    Callback = function(v)
        _abFov = v
        if _fovCircle then pcall(function() _fovCircle.Radius = v end) end
    end
})
UniCombat:NewSlider({
    Title = "Smoothing (0=snap 100=slow)",
    Min = 0, Max = 90, Default = 35,
    Callback = function(v) _abSmoothing = v / 100 end
})
UniCombat:NewSlider({
    Title = "Prediction (x0.01)",
    Min = 0, Max = 100, Default = 18,
    Callback = function(v) _abPrediction = v / 100 end
})
UniCombat:NewToggle({
    Title = "Wall Check",
    Default = true,
    Callback = function(v) _abWallCheck = v end
})
UniCombat:NewToggle({
    Title = "Team Check",
    Default = true,
    Callback = function(v) _abTeamCheck = v end
})

UniCombat:NewToggle({
    Title = "Triggerbot",
    Default = false,
    Callback = function(v) _tbActive = v; if v then _startTriggerLoop() else _stopTrigger() end end
})
UniCombat:NewSlider({
    Title = "Trigger Delay (ms)",
    Min = 0,
    Max = 200,
    Default = 80,
    Callback = function(v) _tbDelay = v end
})


-- Visuals Section
local UniVis = UniTab:NewSection({Position = "Right", Title = "Visuals"})
UniVis:NewToggle({
    Title = "Player ESP",
    Default = false,
    Callback = function(v) if v then enableESP() else clearESP() end end
})
UniVis:NewToggle({
    Title = "ESP Glow",
    Default = true,
    Callback = function(v) _ESP.Glow = v end
})
UniVis:NewToggle({
    Title = "ESP Names",
    Default = true,
    Callback = function(v) _ESP.ShowNames = v end
})
UniVis:NewToggle({
    Title = "ESP Health",
    Default = true,
    Callback = function(v) _ESP.ShowHealth = v end
})
UniVis:NewToggle({
    Title = "ESP Distance",
    Default = true,
    Callback = function(v) _ESP.ShowDistance = v end
})
UniVis:NewToggle({
    Title = "ESP Look Line",
    Default = true,
    Callback = function(v) _ESP.ShowLookLine = v end
})
UniVis:NewToggle({
    Title = "ESP Team Colors",
    Default = false,
    Callback = function(v) _ESP.TeamColor = v end
})
UniVis:NewSlider({
    Title = "ESP Range (studs)",
    Min = 50, Max = 2000, Default = 1000,
    Callback = function(v) _ESP.Range = v end
})
UniVis:NewSlider({
    Title = "ESP Fill Transparency %",
    Min = 0, Max = 100, Default = 65,
    Callback = function(v) _ESP.FillTrans = v / 100 end
})
UniVis:NewColorPicker({
    Title = "ESP Color",
    Default = Color3.fromRGB(255, 170, 60),
    Callback = function(c)
        _ESP.Color = c
        for _, d in pairs(_espTracked) do
            if d.Highlight  then d.Highlight.FillColor  = c; d.Highlight.OutlineColor = c end
            if d.NameLabel  then d.NameLabel.TextColor3 = c end
        end
    end
})
UniVis:NewToggle({
    Title = "Spectator List",
    Default = false,
    Callback = function(v)
        _spectActive = v
        if _spectConn then _spectConn:Disconnect(); _spectConn = nil end
        if _spectGui then pcall(function() _spectGui:Destroy() end); _spectGui = nil end
        if not v then return end
        _rebuildSpectList()
        local _lastSpectRebuild = 0
        _spectConn = RunService.Heartbeat:Connect(function()
            local _now = tick()
            if _now - _lastSpectRebuild < 2 then return end
            _lastSpectRebuild = _now
            _rebuildSpectList()
        end)
    end
})
UniVis:NewToggle({
    Title = "Spectator Alerts",
    Default = true,
    Callback = function(v) _spectAlert = v end
})

-- Teleport & Server Hop
local _tpTarget = ""
local _tpDropdown = nil
local function _buildPlayerOpts()
    local t = {}; for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LocalPlayer then table.insert(t, plr.Name) end end
    return #t > 0 and t or {"(no players)"}
end
local _tpOpts = _buildPlayerOpts()
_tpTarget = _tpOpts[1]

local function _refreshTpDropdown()
    local newOpts = _buildPlayerOpts()
    if _tpDropdown and _tpDropdown.SetOptions then _tpDropdown:SetOptions(newOpts) end
    _tpOpts = newOpts; _tpTarget = newOpts[1]
end
Players.PlayerAdded:Connect(function() task.wait(1); _refreshTpDropdown() end)
Players.PlayerRemoving:Connect(function() task.wait(0.1); _refreshTpDropdown() end)

local _autoRejoinActive = false
local _autoRejoinConn = nil

-- Utility Section (Fullbright, No Fog, etc)
local _origBright, _origAmbient, _origOutdoor
local _origFogEnd, _origFogStart, _origAtmDensity
local _afkThread

local UniUtil = UniTab:NewSection({Position = "Left", Title = "Utility"})
UniUtil:NewToggle({
    Title = "Anti-AFK",
    Default = false,
    Callback = function(v)
        if _afkThread then task.cancel(_afkThread); _afkThread = nil end
        if v then
            _afkThread = task.spawn(function()
                while true do
                    task.wait(60)
                    pcall(function()
                        local VU = game:GetService("VirtualUser")
                        VU:Button2Down(Vector2.new(0, 0), CFrame.new())
                        task.wait(0.1)
                        VU:Button2Up(Vector2.new(0, 0), CFrame.new())
                    end)
                end
            end)
        end
    end,
})
UniUtil:NewSeparator()
_tpDropdown = UniUtil:NewDropdown({
    Title = "Teleport Target",
    Options = _tpOpts,
    Default = _tpOpts[1],
    Callback = function(v) _tpTarget = v end
})
UniUtil:NewButton({
    Title = "Teleport to Player",
    Callback = function()
        if _tpTarget == "" or _tpTarget == "(no players)" then
            Hub:Notify({Title = "Teleport", Message = "No target selected", Duration = 2})
            return
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and (plr.Name:lower() == _tpTarget:lower() or plr.DisplayName:lower():find(_tpTarget:lower(), 1, true)) then
                local hrp = getHRP()
                local tHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp and tHrp then
                    hrp.CFrame = tHrp.CFrame + Vector3.new(0, 3, 0)
                    Hub:Notify({Title = "Teleport", Message = "-> " .. plr.Name, Duration = 2})
                else
                    Hub:Notify({Title = "Teleport", Message = plr.Name .. " has no character", Duration = 2})
                end
                return
            end
        end
        Hub:Notify({Title = "Teleport", Message = "Not found: " .. _tpTarget, Duration = 2})
    end,
})
UniUtil:NewSeparator()
UniUtil:NewButton({
    Title = "Server Hop",
    Callback = function()
        Hub:Notify({Title = "Server Hop", Message = "Searching...", Duration = 3})
        task.spawn(function()
            pcall(function()
                local HS = game:GetService("HttpService")
                local TS = game:GetService("TeleportService")
                local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                local ok, resp = pcall(function() return game:HttpGet(url) end)
                if not ok then Hub:Notify({Title = "Server Hop", Message = "HttpGet blocked", Duration = 3}); return end
                local ok2, data = pcall(function() return HS:JSONDecode(resp) end)
                if not ok2 or not data or not data.data then Hub:Notify({Title = "Server Hop", Message = "Failed to parse", Duration = 3}); return end
                local cands = {}
                for _, srv in ipairs(data.data) do if srv.playing < srv.maxPlayers then table.insert(cands, srv.id) end end
                if #cands == 0 then Hub:Notify({Title = "Server Hop", Message = "No open servers", Duration = 3}); return end
                TS:TeleportToPlaceInstance(game.PlaceId, cands[math.random(1, #cands)], LocalPlayer)
            end)
        end)
    end,
})
UniUtil:NewToggle({
    Title = "Auto Rejoin",
    Default = false,
    Callback = function(v)
        _autoRejoinActive = v
        if _autoRejoinConn then _autoRejoinConn:Disconnect(); _autoRejoinConn = nil end
        if not v then return end
        task.spawn(function()
            pcall(function()
                local CG = game:GetService("CoreGui")
                local TS = game:GetService("TeleportService")
                local pGui = CG:WaitForChild("RobloxPromptGui", 10)
                if not pGui then return end
                local ov = pGui:WaitForChild("promptOverlay", 10)
                if not ov then return end
                _autoRejoinConn = ov.ChildAdded:Connect(function()
                    if not _autoRejoinActive then return end
                    for i = 3, 1, -1 do
                        Hub:Notify({Title = "Auto Rejoin", Message = "Rejoining in " .. i .. "s...", Duration = 1})
                        task.wait(1)
                    end
                    pcall(function() TS:Teleport(game.PlaceId, LocalPlayer) end)
                end)
            end)
        end)
    end,
})
UniUtil:NewSeparator()
UniUtil:NewToggle({
    Title = "Fullbright",
    Default = false,
    Callback = function(v)
        if v then
            _origBright = Lighting.Brightness
            _origAmbient = Lighting.Ambient
            _origOutdoor = Lighting.OutdoorAmbient
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.fromRGB(178, 178, 178)
            Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        else
            Lighting.Brightness = _origBright or 1
            Lighting.Ambient = _origAmbient or Color3.fromRGB(127, 127, 127)
            Lighting.OutdoorAmbient = _origOutdoor or Color3.fromRGB(127, 127, 127)
        end
    end,
})
UniUtil:NewToggle({
    Title = "No Fog",
    Default = false,
    Callback = function(v)
        if v then
            _origFogEnd = Lighting.FogEnd
            _origFogStart = Lighting.FogStart
            Lighting.FogEnd = 1e9
            Lighting.FogStart = 1e9
            local atm = Lighting:FindFirstChildOfClass("Atmosphere")
            if atm then _origAtmDensity = atm.Density; atm.Density = 0 end
        else
            Lighting.FogEnd = _origFogEnd or 1000
            Lighting.FogStart = _origFogStart or 0
            local atm = Lighting:FindFirstChildOfClass("Atmosphere")
            if atm then atm.Density = _origAtmDensity or 0.395 end
        end
    end,
})
UniUtil:NewSeparator()
UniUtil:NewSlider({
    Title = "FOV",
    Min = 50,
    Max = 120,
    Default = 70,
    Callback = function(v) workspace.CurrentCamera.FieldOfView = v end
})
UniUtil:NewSlider({
    Title = "Time of Day",
    Min = 0,
    Max = 24,
    Default = 14,
    Callback = function(v) Lighting.ClockTime = v end
})

-- Settings Tab
local SetTab = Hub:NewTab({Title = "Settings", Icon = "rbxassetid://3926307641"})
local AppearSec = SetTab:NewSection({Position = "Left", Title = "Appearance"})
local DataSec = SetTab:NewSection({Position = "Right", Title = "Config"})

AppearSec:NewColorPicker({
    Title = "Accent Color",
    Default = Color3.fromRGB(110, 75, 255),
    Callback = function(c) Hub:SetAccent(c) end
})
AppearSec:NewSlider({
    Title = "Window Opacity %",
    Min = 30,
    Max = 100,
    Default = 95,
    Callback = function(v) Hub._win.BackgroundTransparency = 1 - (v / 100) end
})

DataSec:NewButton({
    Title = "Save Config",
    Callback = function() SM:Save(); Hub:Notify({Title = "Config", Message = "Saved", Duration = 2}) end
})
DataSec:NewButton({
    Title = "Load Config",
    Callback = function() SM:Load(); Hub:Notify({Title = "Config", Message = "Loaded", Duration = 2}) end
})
DataSec:NewToggle({
    Title = "Auto Save (60s)",
    Default = true,
    Callback = function(v)
        if v then
            task.spawn(function()
                while task.wait(60) do if not v then break end; SM:Save() end
            end)
        end
    end
})

-- ── Autoexec persistence ──────────────────────────────────────────────────────
--  Writes this hub script into your executor's autoexec folder so it
--  automatically re-injects whenever you join any Roblox game.
--
--  How it finds itself:
--    1. Tries common filenames in workspace / scripts folders
--    2. Falls back to writing a Phantom-library loader (loads the UI lib only)
--
--  After clicking, the file "autoexec/PhantomHub.lua" will exist in your
--  executor folder.  Delete it any time to stop auto-injection.
-- ─────────────────────────────────────────────────────────────────────────────
local _AUTOEXEC_FILE   = "autoexec/PhantomHub.lua"
local _AUTOEXEC_FOLDER = "autoexec"

local function _trySaveAutoexec(silent)
    local saved = false
    pcall(function()
        if not isfolder(_AUTOEXEC_FOLDER) then makefolder(_AUTOEXEC_FOLDER) end

        -- Try to find and copy the hub script file from common locations
        local candidates = {
            "Hub_Enhanced_MultiGame.lua",
            "PhantomHub.lua",
            "scripts/PhantomHub.lua",
            "scripts/Hub_Enhanced_MultiGame.lua",
            "workspace/PhantomHub.lua",
        }
        for _, path in ipairs(candidates) do
            if pcall(function()
                if isfile(path) then
                    writefile(_AUTOEXEC_FILE, readfile(path))
                    saved = true
                end
            end) and saved then break end
        end

        -- Fallback: write a minimal loader that re-runs from Phantom library URL
        -- (user will still need to manually add hub code below it)
        if not saved then
            local loaderContent = string.format([[
-- PhantomHub Auto-Loader (created %s)
-- NOTE: This is a minimal loader. For full hub code, paste your
--       Hub_Enhanced_MultiGame.lua content below the library load line.
local _ph = loadstring(game:HttpGet("%s"))
if _ph then _ph() end
]], os.date and os.date("%Y-%m-%d") or "unknown", _phantomUrl)
            writefile(_AUTOEXEC_FILE, loaderContent)
            saved = "partial"
        end
    end)
    return saved
end

DataSec:NewButton({
    Title = "💾 Save to Autoexec",
    Callback = function()
        local result = _trySaveAutoexec(false)
        if result == true then
            Hub:Notify({
                Title   = "Autoexec",
                Message = "✅ Saved! Hub will auto-load next game join.",
                Duration = 5,
            })
        elseif result == "partial" then
            Hub:Notify({
                Title   = "Autoexec",
                Message = "⚠ Partial save. Paste your hub script into autoexec/PhantomHub.lua manually.",
                Duration = 7,
            })
        else
            Hub:Notify({
                Title   = "Autoexec",
                Message = "❌ Failed — executor may not support writefile/isfolder.",
                Duration = 5,
            })
        end
    end,
})

DataSec:NewButton({
    Title = "🗑 Remove Autoexec",
    Callback = function()
        local ok = pcall(function()
            if isfile(_AUTOEXEC_FILE) then
                delfile(_AUTOEXEC_FILE)
            end
        end)
        Hub:Notify({
            Title   = "Autoexec",
            Message = ok and "Removed — hub will no longer auto-load." or "Not found or already removed.",
            Duration = 4,
        })
    end,
})

SetTab._btn.Visible = false

-- ── Teleport detection — warn the user before the script is killed ────────────
--  Roblox fires TeleportService.TeleportInitiated (client-side) just before the
--  local game session ends for a teleport.  We use this to show a heads-up.
task.spawn(function()
    pcall(function()
        local TS = game:GetService("TeleportService")
        -- Some executors expose this signal; others don't
        TS.LocalPlayerArrivedFromTeleport:Connect(function()
            -- We arrived in a new game — nothing to do, script will re-run from autoexec
        end)
    end)

    -- Universal fallback: watch for the game's DataModel being destroyed
    -- (happens right before teleport / game close)
    game.Close:Connect(function()
        -- Try a quick silent autoexec save so the next game gets the hub
        _trySaveAutoexec(true)
    end)

    -- Also watch for a "loading screen" GUI appearing which usually precedes
    -- a teleport in games that show one
    pcall(function()
        local CG = game:GetService("CoreGui")
        CG.DescendantAdded:Connect(function(d)
            if d.Name == "LoadingGui" or d.Name == "TeleportGui" then
                Hub:Notify({
                    Title   = "⚠ Teleport Detected",
                    Message = "Script will need re-inject unless autoexec is set up.",
                    Duration = 4,
                })
            end
        end)
    end)
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- ──  PANIC KEY WIRING
-- ════════════════════════════════════════════════════════════════════════════════
_panicShutdown = function()
    pcall(stopWsEnforcer)
    pcall(stopFly)
    pcall(_disableNoclip)
    pcall(clearESP)
    pcall(_stopAimbot)
    pcall(_stopTrigger)
    pcall(function()
        if _infJumpConn then _infJumpConn:Disconnect(); _infJumpConn = nil end
    end)
    pcall(function()
        _spectActive = false
        if _spectConn then _spectConn:Disconnect(); _spectConn = nil end
        if _spectGui then _spectGui:Destroy(); _spectGui = nil end
    end)
    pcall(function()
        _autoRejoinActive = false
        if _autoRejoinConn then _autoRejoinConn:Disconnect(); _autoRejoinConn = nil end
    end)
    pcall(function()
        Lighting.Brightness = _origBright or 1
        Lighting.Ambient = _origAmbient or Color3.fromRGB(127, 127, 127)
        Lighting.OutdoorAmbient = _origOutdoor or Color3.fromRGB(127, 127, 127)
        Lighting.FogEnd = _origFogEnd or 1000
        Lighting.FogStart = _origFogStart or 0
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then atm.Density = _origAtmDensity or 0.395 end
    end)
    pcall(function()
        local h = getHum()
        if h then h.WalkSpeed = 16; h.JumpPower = 50; h.PlatformStand = false end
    end)
    _showDisengagedOverlay()
end

-- ════════════════════════════════════════════════════════════════════════════════
-- ──  PUBLIC API
-- ════════════════════════════════════════════════════════════════════════════════
_G.PhantomHub = {
    Hub = Hub,
    Phantom = Phantom,
    Players = Players,
    RunService = RunService,
    UIS = UIS,
    LocalPlayer = LocalPlayer,
    PlaceId = game.PlaceId,
    getChar = getChar,
    getHum = getHum,
    getHRP = getHRP,
    startAimbot = _startAimbot,
    stopAimbot = _stopAimbot,
    enableESP = enableESP,
    clearESP = clearESP,
    Await = function(self) return self end,
}

-- ── Startup Notification ──────────────────────────────────────
Hub:Notify({
    Title = "Phantom v3.5",
    Message = "J=menu  |  Del=PANIC  |  Aimbot: smooth assist, target lock, FOV circle, autoexec",
    Duration = 6,
})

print("[Phantom] v3.5 loaded!")
print("[Phantom] ✅ Best Aimbot (Dex5 + Dex6)")
print("[Phantom] ✅ Your ESP")
print("[Phantom] ✅ Teleport/Server Hop/Auto Rejoin")
print("[Phantom] ✅ Working Noclip")
print("[Phantom] Press J to open menu")
