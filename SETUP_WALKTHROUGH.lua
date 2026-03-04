--[[
PHANTOM HUB ENHANCED - IMPLEMENTATION GUIDE
Complete walkthrough for integrating all 7 systems into your Hub

This guide assumes you're starting with the basic Hub.lua and want to add:
1. Event Hook System
2. Noclip System (replacement)
3. Logging System
4. Alias System
5. Auto Key Press System
6. Plugin System
7. Keybind Customization UI
]]

-- ════════════════════════════════════════════════════════════════
-- STEP 1: PREPARE YOUR FILES
-- ════════════════════════════════════════════════════════════════

--[[
You should have these files in your executor folder:

Hub_Enhanced.lua                  ← Your new integrated Hub (MAIN FILE)
Phantom.lua                       ← UI Library (unchanged)

1_EventHooks.lua                  ← New module 1
2_NoclipSystem.lua                ← New module 2
3_LoggingSystem.lua               ← New module 3
4_AliasSystem.lua                 ← New module 4
5_AutoKeyPressSystem.lua          ← New module 5
6_PluginSystem.lua                ← New module 6
7_KeybindUI.lua                   ← New module 7

Optional:
INTEGRATION_GUIDE.lua             ← Reference docs
QUICK_REFERENCE.lua               ← API reference

File structure:
/your_executor_folder/
├── Hub_Enhanced.lua              (MAIN - execute this)
├── Phantom.lua
├── 1_EventHooks.lua
├── 2_NoclipSystem.lua
├── 3_LoggingSystem.lua
├── 4_AliasSystem.lua
├── 5_AutoKeyPressSystem.lua
├── 6_PluginSystem.lua
└── 7_KeybindUI.lua

Data files (auto-created):
├── phantom_sm_phantom.json       (Settings Manager)
├── phantom_aliases.json          (Aliases)
├── phantom_keybinds.json         (Keybinds)
├── phantom_chat_logs.json        (Chat logs)
├── phantom_join_logs.json        (Join logs)
└── phantom_keyseq.json           (Key sequences)
]]

-- ════════════════════════════════════════════════════════════════
-- STEP 2: EXECUTE HUB_ENHANCED.LUA
-- ════════════════════════════════════════════════════════════════

--[[
Method 1: Direct loadstring
loadstring(readfile("Hub_Enhanced.lua"))()

Method 2: Via executor UI
- Open your executor
- Click "Load File"
- Select Hub_Enhanced.lua
- Click "Execute"

Method 3: From game console
loadstring(game:HttpGet("https://your_github_raw/Hub_Enhanced.lua"))()

The script will:
✓ Load Phantom.lua from GitHub
✓ Attempt to load all 7 modules from readfile
✓ Create the UI with all tabs and sections
✓ Initialize all systems
✓ Print "[Phantom] Enhanced Hub loaded successfully!"
]]

-- ════════════════════════════════════════════════════════════════
-- STEP 3: UNDERSTAND THE KEY FEATURES
-- ════════════════════════════════════════════════════════════════

--[[ 
KEYBINDS (Now Customizable via UI)

Default keybinds:
  J              = Toggle Hub menu
  RightAlt       = Toggle Aimbot
  N              = Toggle Noclip
  F              = Toggle Flight
  E              = Toggle ESP
  G              = Toggle Infinite Jump
  Delete         = PANIC (disable everything)
  Backspace+Eq   = Emergency stop Auto Key Press

All can be remapped via:
Settings Tab → Keybinds section (NEW!)

TABS & SECTIONS

Player Tab:
  - Walk Speed slider (16-500)
  - Jump Power slider (7-300)
  - Infinite Jump toggle

Movement Tab:
  - Noclip toggle & speed slider (10-500) ← NOW USES NEW SYSTEM
  - Flight toggle & speed slider

Combat Tab:
  - Aimbot toggle, FOV, Smoothing
  - Triggerbot toggle & delay controls

Visuals Tab:
  - Player ESP toggle

Utility Tab:
  - Record key sequences (NEW SYSTEM)
  - Play recorded sequences

Settings Tab:
  - Appearance: Accent color, window opacity
  - Config: Save/Load/Auto-save
  - Logging: Export chat & join logs (NEW!)
  - Keybinds: Remap all hotkeys (NEW!)
]]

-- ════════════════════════════════════════════════════════════════
-- STEP 4: USING THE NEW SYSTEMS
-- ════════════════════════════════════════════════════════════════

--[[
NOCLIP (Enhanced)

Old way: RenderStepped CanCollide disable with highlight
New way: Dual-method (RenderStepped + touch detection fallback)

Usage (identical to old):
  Toggle: Press N
  Adjust speed: Movement tab → Noclip Speed slider
  
New features:
  ✓ Visual indicator when active (green label)
  ✓ Better collision handling on tricky geometry
  ✓ Auto-reapply on respawn (no manual re-enable needed)
  ✓ Smooth speed adjustment mid-noclip

What changed in your code:
  Before: _enableNoclip() / _disableNoclip()
  After:  _noclipSystem:Enable() / _noclipSystem:Disable()
  
The Hub_Enhanced.lua handles this automatically!
]]

--[[
LOGGING (Chat & Join Tracking)

What it captures:
  • Every chat message with timestamp, username, and message
  • Every player join with join time, leave time, and session duration
  
How to access:
  Settings Tab → Logging section
  
Buttons:
  • Export Chat Logs → saves to phantom_chat_logs.json
  • Export Join Logs → saves to phantom_join_logs.json
  • Cleanup Old Logs → removes logs older than 7 days

Example: phantom_chat_logs.json contains:
[
  {
    "playerName": "Alice",
    "userId": 123456789,
    "message": "gg wp",
    "timestamp": 1699564800,
    "displayTime": "2024-11-09 15:30:00"
  },
  ...
]

Auto-saves every 60 seconds
]]

--[[
ALIASES (Text Expansion)

Simple aliases:
  /gg           → "Good game!"
  /tnx          → "Thanks!"
  /bye          → "Goodbye!"

Aliases with variables:
  /time         → "Current time: 15:30:45"
  /whoami       → "I'm Alice (ID: 123456789)"
  /greet        → "Hello Alice!"

Parameterized aliases:
  /hello Bob    → "Hey Bob, how are you?"
  /msg Bob hi   → "To Bob: hi"

How to add more:
  In Hub_Enhanced.lua, find the SETUP ALIASES section:
  
  if Aliases then
      Aliases:Add("shortcut", "expansion")
      Aliases:Add("yourkey", "your message here")
      Aliases:Save()
  end

Access logs & data:
  phantom_aliases.json stores all your aliases

Note: These are for reference/copy-paste (no clipboard dependency)
]]

--[[
AUTO KEY PRESS (Automation)

Record sequences:
  1. Utility Tab → Record Sequence toggle ON
  2. Manually press the keys you want to record
  3. Click toggle OFF
  4. Saved to phantom_keyseq.json
  
Play sequences:
  Utility Tab → Play Sequence button
  Replays the recorded sequence at 1x speed
  
Advanced usage (for coders):
  AutoKeyPress:StartRepeat(Enum.KeyCode.Space, 0.1, 0.1)
    → Hold Space: 100ms press, 100ms release, repeat
  
  AutoKeyPress:StopRepeat()
    → Stop the repeating action
  
  AutoKeyPress:HoldKey(Enum.KeyCode.W, 5)
    → Hold W for 5 seconds
  
Emergency stop:
  Backspace key stops all automation instantly
]]

--[[
KEYBIND CUSTOMIZATION (NEW UI!)

Where to access:
  Settings Tab → Keybinds section (right side)

What you can do:
  • Click on any keybind to change it
  • Press a new key when prompted
  • System detects conflicts (warns if two actions share a key)
  • All changes auto-save to phantom_keybinds.json

Default keybinds registered:
  • Aimbot Toggle    (RightAlt)
  • Noclip Toggle    (N)
  • Fly Toggle       (F)
  • ESP Toggle       (E)
  • Infinite Jump    (G)

To add more keybinds to custom features:
  In Hub_Enhanced.lua, find SETUP KEYBIND UI section:
  
  if KeybindUI then
      KeybindUI:Register("My Feature", Enum.KeyCode.Y, {
          category = "Custom",
          description = "Does something cool",
          onPress = function()
              print("Feature activated!")
          end
      })
  end
]]

--[[
EVENT HOOKS (Advanced Inter-Component Communication)

Fired events in Hub_Enhanced.lua:
  • "OnSpawn"         - When player respawns
  • "OnJoin"          - When another player joins server
  • "OnPlayerLeft"    - When another player leaves
  • "AimbotToggled"   - When aimbot is enabled/disabled

Example: React to aimbot being toggled
  if EventHooks then
      EventHooks:Listen("AimbotToggled", function(enabled)
          if enabled then
              print("Aimbot is now ON")
          else
              print("Aimbot is now OFF")
          end
      end)
  end

Example: Custom feature on player spawn
  if EventHooks then
      EventHooks:Listen("OnSpawn", function(player)
          print("You spawned!")
          -- Do something special
      end)
  end

Priorities (higher executes first):
  HIGHEST(1000) > HIGH(100) > NORMAL(0) > LOW(-100) > LOWEST(-1000)
  
Example with priority:
  EventHooks:Listen("OnSpawn", callback, EventHooks.PRIORITY.HIGH)
]]

-- ════════════════════════════════════════════════════════════════
-- STEP 5: CUSTOMIZATION EXAMPLES
-- ════════════════════════════════════════════════════════════════

--[[
Example 1: Add a custom alias

Locate this in Hub_Enhanced.lua:
    if Aliases then
        Aliases:Add("gg", "Good game!")
        Aliases:Add("tnx", "Thanks!")
        ...
    end

Add your custom alias:
    Aliases:Add("myfav", "This is my favorite game mode!")
    
Then type:
    /myfav → expands to "This is my favorite game mode!"
]]

--[[
Example 2: Add a custom keybind

Locate this in Hub_Enhanced.lua:
    if KeybindUI then
        KeybindUI:Register("Aimbot Toggle", Enum.KeyCode.RightAlt, {
            ...
        })
    end

Add your keybind:
    KeybindUI:Register("My Cool Feature", Enum.KeyCode.K, {
        category = "Custom",
        description = "Does something awesome",
        onPress = function()
            print("Feature activated!")
            -- Your code here
        end
    })

Now:
  Press K → activates your feature
  Settings Tab → Keybinds → can remap K to something else
]]

--[[
Example 3: React to player events

Find this section:
    if EventHooks then
        LocalPlayer.CharacterAdded:Connect(function(char)
            EventHooks:Fire("OnSpawn", LocalPlayer)
        end)
    end

Add your listener:
    if EventHooks then
        EventHooks:Listen("OnSpawn", function(player)
            Hub:Notify({
                Title = "Respawned",
                Message = "You respawned at " .. os.date("%H:%M:%S"),
                Duration = 3
            })
        end)
    end
]]

-- ════════════════════════════════════════════════════════════════
-- STEP 6: TROUBLESHOOTING
-- ════════════════════════════════════════════════════════════════

--[[
PROBLEM: Modules don't load
SOLUTION:
  1. Make sure all 7 .lua files are in the same folder as Hub_Enhanced.lua
  2. Check console for "[Phantom] Warning: Could not load [modulename]"
  3. If warning appears, check the module file is not corrupted
  4. Fallback: If modules fail to load, basic features still work (noclip, aimbot, etc)

PROBLEM: Noclip doesn't work
SOLUTION:
  1. Try using it manually: press N
  2. Check if it shows "NOCLIP: ON" indicator in top-right corner
  3. If indicator shows but you're still colliding, it's a server-side anti-cheat
  4. Try adjusting speed: might help with some maps
  5. Some games actively reject noclip - nothing can be done

PROBLEM: Keybinds not responding
SOLUTION:
  1. Check that Hub is open (press J first)
  2. Check in Settings Tab → Keybinds that binding exists
  3. Try remapping to a different key
  4. Some keys might be reserved by the game itself

PROBLEM: Logs not saving
SOLUTION:
  1. Check that readfile/writefile are available in your executor
  2. Check folder permissions (might be read-only)
  3. Try manually clicking "Export Chat Logs" button
  4. Check console for error messages

PROBLEM: Aliases not expanding
SOLUTION:
  1. Aliases are stored in phantom_aliases.json
  2. Check you saved the Hub (Settings Tab → Save Config)
  3. Verify spelling is correct (case-insensitive)
  4. Reload: Settings Tab → Load Config

PROBLEM: Auto Key Press sequence plays incorrectly
SOLUTION:
  1. Re-record the sequence (clear and start fresh)
  2. Press keys slowly and deliberately
  3. Check phantom_keyseq.json exists (Utility Tab → Play Sequence)
  4. Try pressing keys manually first to verify they work
]]

-- ════════════════════════════════════════════════════════════════
-- STEP 7: FILE LOCATIONS & DATA
-- ════════════════════════════════════════════════════════════════

--[[
WHERE YOUR DATA IS SAVED:

Main config:
  phantom_sm_phantom.json
    └─ Walk speed, jump power, fly speed settings

Aliases (text expansion):
  phantom_aliases.json
    └─ All your custom aliases and shortcuts

Keybinds (hotkey mappings):
  phantom_keybinds.json
    └─ All your key remappings

Chat logs:
  phantom_chat_logs.json
    └─ Every message with timestamp and player info
    └─ Export manually via Settings Tab → Export Chat Logs
    └─ Auto-saves every 60 seconds

Join logs:
  phantom_join_logs.json
    └─ Every player join/leave with duration
    └─ Export manually via Settings Tab → Export Join Logs
    └─ Auto-saves every 60 seconds

Key sequences:
  phantom_keyseq.json
    └─ Recorded keyboard sequences
    └─ Created when you record via Utility Tab
    └─ Played back with Play Sequence button

Plugin metadata:
  phantom_plugin_metadata.json
    └─ Only created if you use Plugin System
    └─ Tracks plugin versions and enabled state

AUTO-SAVE:
  Every 60 seconds, these files are saved:
  • Main settings
  • Aliases
  • Keybinds
  • Chat logs
  • Join logs
  
  Manual save: Settings Tab → Save Config
  Manual load: Settings Tab → Load Config
]]

-- ════════════════════════════════════════════════════════════════
-- STEP 8: ADVANCED USAGE
-- ════════════════════════════════════════════════════════════════

--[[
Accessing systems programmatically:

All systems are exposed via _G:
  _G.EventHooks      - Event hook system
  _G.Noclip          - Noclip controller
  _G.Logger          - Logging system
  _G.Aliases         - Alias expansion
  _G.AutoKeyPress    - Key automation
  _G.PluginManager   - Plugin loader
  _G.KeybindUI       - Keybind manager

Example: Enable noclip from another script
  local Noclip = _G.Noclip
  if Noclip then
      Noclip:Enable()
      Noclip:SetSpeed(100)
  end

Example: Add alias from another script
  local Aliases = _G.Aliases
  if Aliases then
      Aliases:Add("custom", "My custom message")
      Aliases:Save()
  end

Example: Register a keybind from another script
  local KeybindUI = _G.KeybindUI
  local Hub = _G.PhantomHub.Hub
  if KeybindUI and Hub then
      KeybindUI:Register("My Feature", Enum.KeyCode.Y, {
          category = "Custom",
          onPress = function() print("Activated!") end
      })
      KeybindUI:SaveKeybinds()
  end
]]

--[[
Event-driven architecture:

Listen to events from anywhere:
  local EH = _G.EventHooks
  if EH then
      EH:Listen("OnSpawn", function(player)
          print(player.Name .. " spawned!")
      end)
  end

Fire custom events:
  local EH = _G.EventHooks
  if EH then
      EH:Fire("MyCustomEvent", arg1, arg2, arg3)
  end

Create your own event listeners:
  local EH = _G.EventHooks
  if EH then
      -- Listen with priority
      local listenerId = EH:Listen("MyEvent", function(...)
          print("Event fired!")
      end, EH.PRIORITY.HIGH)
      
      -- Later, remove listener
      EH:Unlisten("MyEvent", listenerId)
  end
]]

-- ════════════════════════════════════════════════════════════════
-- STEP 9: PANIC KEY & CLEANUP
-- ════════════════════════════════════════════════════════════════

--[[
PANIC KEY: Delete

What it does:
  1. Disables all features (noclip, flight, aimbot, etc)
  2. Saves all configurations
  3. Cleans up all connections
  4. Shows "DISENGAGED" overlay for 1 second
  5. Fully safe to press - can't break anything

Why use it:
  • Moderator coming
  • Suspicious player nearby
  • Want to go stealth
  • General paranoia

How it works:
  Press Delete key once
  Everything stops instantly
  All data is saved
  You're back to vanilla game state
]]

-- ════════════════════════════════════════════════════════════════
-- CONCLUSION
-- ════════════════════════════════════════════════════════════════

--[[
Your Hub now has:

CORE FEATURES (unchanged):
  ✓ Aimbot with FOV, smoothing, RCS
  ✓ Triggerbot with variable delay
  ✓ Flight with adjustable speed
  ✓ Walk speed enforcer
  ✓ Infinite jump
  ✓ ESP system

NEW SYSTEMS ADDED:
  ✓ Event Hooks - Component communication
  ✓ Noclip System - Improved collision bypass
  ✓ Logging System - Chat & join tracking
  ✓ Alias System - Text expansion
  ✓ Auto Key Press - Sequence automation
  ✓ Plugin System - Runtime module loading
  ✓ Keybind UI - Hotkey customization

TOTAL CODE:
  ~3,500 lines of well-documented Lua
  Full error handling and isolation
  Auto-save every 60 seconds
  Zero external dependencies

NEXT STEPS:
  1. Execute Hub_Enhanced.lua
  2. Explore Settings Tab → new features
  3. Customize keybinds to your preference
  4. Add your own aliases
  5. Enjoy your enhanced Phantom hub!

For questions or issues:
  - Check QUICK_REFERENCE.lua for API docs
  - See TROUBLESHOOTING section above
  - Review the module source code (well-commented)
  - Check console output for error messages
]]

print("═══════════════════════════════════════════════════════════════")
print("  PHANTOM HUB ENHANCED - IMPLEMENTATION GUIDE LOADED")
print("  Next: Execute Hub_Enhanced.lua to start the enhanced hub")
print("═══════════════════════════════════════════════════════════════")
