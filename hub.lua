--[[
    Neverlose Universal Hub
]]

local REPO_UI = "https://raw.githubusercontent.com/GhosterXS/Neverlose-Ui-Roblox/main/source.luau"
local REPO_UI_FALLBACK = "https://raw.githubusercontent.com/4lpaca-pin/NeverLose/refs/heads/main/source.luau"

local function LoadNeverLoseUI()
    local candidates = {
        "source.luau",
        "source.lua",
        "Neverlose/source.luau",
        "Neverlose-Ui-Roblox/source.luau",
    }
    if type(isfile) == "function" and type(readfile) == "function" then
        for _, path in ipairs(candidates) do
            local ok, body = pcall(function()
                if isfile(path) then return readfile(path) end
                return nil
            end)
            if ok and type(body) == "string" and #body > 100 then
                local fn = loadstring(body)
                if fn then
                    local ok2, res = pcall(fn)
                    if ok2 and res then
                        print("[Neverlose] Loaded local UI:", path)
                        return res
                    end
                end
            end
        end
    end
    for _, url in ipairs({REPO_UI, REPO_UI_FALLBACK}) do
        local ok, res = pcall(function()
            local src = game:HttpGet(url)
            assert(type(src) == "string" and #src > 100)
            local fn = assert(loadstring(src))
            return fn()
        end)
        if ok and res then
            print("[Neverlose] Loaded UI from:", url)
            return res
        end
    end
    error("Failed to load Neverlose UI")
end

local NeverLose
do
    local ok, res = pcall(LoadNeverLoseUI)
    if not ok or not res then
        warn("[Neverlose] Failed to load UI:", res)
        return
    end
    NeverLose = res
    pcall(function()
        NeverLose.UnloadEnabled = true
        NeverLose.EnabledBlur = false
        getgenv().NeverLose = NeverLose
    end)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local moveMouse = mousemoverel or (Input and Input.MouseMove) or nil


-- Disable previous Neverlose / hub instance completely
local function KillOldNeverlose()
    pcall(function()
        if getgenv().NL_HUB_CONNECTIONS then
            for _, c in ipairs(getgenv().NL_HUB_CONNECTIONS) do
                pcall(function()
                    if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
                    if type(c) == "thread" then task.cancel(c) end
                end)
            end
        end
        getgenv().NL_HUB_CONNECTIONS = {}

        local old = rawget(getgenv(), "NeverLose") or rawget(getgenv(), "Neverlose") or rawget(getgenv(), "NL_UI")
        if type(old) == "table" then
            pcall(function()
                if type(old.GlobalSignals) == "table" then
                    for _, sig in ipairs(old.GlobalSignals) do
                        pcall(function()
                            if typeof(sig) == "RBXScriptConnection" then sig:Disconnect() end
                        end)
                    end
                end
            end)
            pcall(function()
                if old.ScreenGui then old.ScreenGui:Destroy() end
            end)
            pcall(function()
                if type(old.Unload) == "function" then old:Unload() end
            end)
            getgenv().NeverLose = nil
            getgenv().Neverlose = nil
            getgenv().NL_UI = nil
        end

        local parents = {}
        pcall(function() table.insert(parents, game:GetService("CoreGui")) end)
        pcall(function() table.insert(parents, player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 1)) end)
        pcall(function() if gethui then table.insert(parents, gethui()) end end)
        pcall(function() if get_hidden_gui then table.insert(parents, get_hidden_gui()) end end)

        for _, parent in ipairs(parents) do
            if parent then
                for _, gui in ipairs(parent:GetChildren()) do
                    pcall(function()
                        if gui:IsA("ScreenGui") then
                            local n = string.lower(tostring(gui.Name))
                            if gui:GetAttribute("NL_HUB") == true
                                or gui:GetAttribute("Neverlose") == true
                                or string.find(n, "nl_intro", 1, true)
                                or string.find(n, "neverlose", 1, true)
                                or string.find(n, "nl_esp", 1, true) then
                                gui:Destroy()
                            end
                        end
                    end)
                end
            end
        end

        -- Remove previous Drawing objects created by this hub
        pcall(function()
            if getgenv().NL_ESP_CLEAR then getgenv().NL_ESP_CLEAR() end
        end)
    end)
end
KillOldNeverlose()

local Config = {
    AA_Enabled = false,
    AA_Yaw = "None",
    AA_Jitter = false,
    AA_SpinSpeed = 12,
    AA_JitterAmount = 40,
    AA_DisableWhenSitting = true,

    Aimbot_Enabled = false,
    Aimbot_TeamCheck = true,
    Aimbot_AliveCheck = true,
    Aimbot_AutoWall = true,
    Aimbot_Silent = false,
    Aimbot_FOV = 120,
    Aimbot_Smooth = 0.30,
    Aimbot_Part = "Head",
    Aimbot_ShowFOV = true,
    Aimbot_AimKey = "M2B",

    ESP_Enabled = false,
    ESP_TeamCheck = true,
    ESP_TeamChams = true,
    ESP_Chams = true,
    ESP_Highlight = true,
    ESP_Name = true,
    ESP_Distance = true,
    ESP_Healthbar = true,
    ESP_Tracers = true,
    ESP_Ball = true,
    ESP_OOF = true,
    ESP_OOF_Color = {255, 255, 255},
    ESP_OOF_Size = 12,
    ESP_BallSize = 6,
    ESP_NameSize = 14,
    ESP_DistSize = 12,
    ESP_HealthWidth = 4,
    ESP_HealthHeight = 44,
    ESP_NamePos = "Up",
    ESP_DistPos = "Bottom",
    ESP_HealthPos = "Left",
    ESP_FillTransparency = 0.55,
    ESP_OutlineTransparency = 0,
    ESP_MaxDistance = 100000,
    ESP_FillColor = {255, 50, 50},
    ESP_OutlineColor = {255, 255, 255},
    ESP_NameColor = {255, 255, 255},
    ESP_DistColor = {220, 220, 220},
    ESP_TracerColor = {255, 80, 80},
    ESP_BallColor = {255, 80, 80},
    ESP_TeamFillColor = {50, 120, 255},
    ESP_TeamOutlineColor = {180, 210, 255},

    AutoJump = false,
    LoopWalkSpeed = 0,
    LoopJumpPower = 0,

    ThirdPerson = false,
    ThirdPerson_Distance = 10,
    LoopFOV = false,
    LoopFOV_Value = 90,
    Freecam = false,
    Freecam_Speed = 2,

    LocalChams = false,
    LocalChams_Fill = {80, 160, 255},
    LocalChams_Outline = {255, 255, 255},
    LocalChams_FillTransparency = 0.5,
    LocalChams_OutlineTransparency = 0,

    AmbientEnabled = false,
    ConfigName = "default",
    LightColor = {255, 255, 255},
    LightBrightness = 1,
    AmbientColor = {128, 128, 128},
    OutdoorAmbient = {128, 128, 128},
    ColorShift_Top = {0, 0, 0},
    ColorShift_Bottom = {0, 0, 0},
    BloomEnabled = false,
    BloomIntensity = 0.4,
    BloomSize = 24,
    BloomThreshold = 0.95,
    ColorCorrectionEnabled = false,
    CC_Brightness = 0,
    CC_Contrast = 0,
    CC_Saturation = 0,
    SunRaysEnabled = false,
    SunRaysIntensity = 0.1,
    SunRaysSpread = 0.5,
    AtmosphereEnabled = false,
    AtmosphereDensity = 0.3,
    AtmosphereOffset = 0.25,
    AtmosphereColor = {199, 199, 199},
    FogEnabled = false,
    FogStart = 0,
    FogEnd = 1000,
    FogColor = {192, 192, 192},


    ConfigName = "default",
    Skin_UserId = 0,
    Skin_Username = "",

    Keys = {
        AA = { Key = "None", Mode = "Toggle" },
        Aimbot = { Key = "None", Mode = "Toggle" },
        ESP = { Key = "None", Mode = "Toggle" },
        Bhop = { Key = "None", Mode = "Toggle" },
        ThirdPerson = { Key = "None", Mode = "Toggle" },
        LoopFOV = { Key = "None", Mode = "Toggle" },
        LocalChams = { Key = "None", Mode = "Toggle" },
        Freecam = { Key = "None", Mode = "Toggle" },
        Ambient = { Key = "None", Mode = "Toggle" },
    },
}

local function ToColor3(t)
    if typeof(t) == "Color3" then return t end
    return Color3.fromRGB(t[1] or 255, t[2] or 50, t[3] or 50)
end

local function FromColor3(c)
    return {
        math.floor(c.R * 255 + 0.5),
        math.floor(c.G * 255 + 0.5),
        math.floor(c.B * 255 + 0.5)
    }
end

local ConfigFolder = "NeverloseNL"

local function EnsureConfigFolder()
    pcall(function()
        if makefolder and isfolder and not isfolder(ConfigFolder) then
            makefolder(ConfigFolder)
        elseif makefolder then
            pcall(makefolder, ConfigFolder)
        end
    end)
end

local function ConfigPath(name)
    name = tostring(name or "default"):gsub("[^%w%-%_ ]", "")
    if name == "" then name = "default" end
    return ConfigFolder .. "/" .. name .. ".json"
end

local function SaveConfig(name)
    name = name or Config.ConfigName or "default"
    Config.ConfigName = name
    EnsureConfigFolder()
    local ok, err = pcall(function()
        assert(writefile, "writefile not available")
        writefile(ConfigPath(name), HttpService:JSONEncode(Config))
    end)
    return ok, err
end

local function LoadConfig(name)
    name = name or Config.ConfigName or "default"
    local path = ConfigPath(name)
    local ok, err = pcall(function()
        assert(readfile and isfile, "readfile not available")
        assert(isfile(path), "config not found: " .. path)
        local data = HttpService:JSONDecode(readfile(path))
        assert(type(data) == "table", "invalid config")
        for k, v in pairs(data) do
            Config[k] = v
        end
        Config.ConfigName = name
    end)
    return ok, err
end

local function DeleteConfig(name)
    name = name or Config.ConfigName or "default"
    local path = ConfigPath(name)
    local ok, err = pcall(function()
        if delfile and isfile and isfile(path) then
            delfile(path)
        end
    end)
    return ok, err
end
local function AutoSave()
end

local menuOpen = false -- wait for intro
local savedMouseBehavior = Enum.MouseBehavior.Default
local savedMouseIcon = true

local function CaptureMouseState()
    pcall(function()
        savedMouseBehavior = UserInputService.MouseBehavior
        savedMouseIcon = UserInputService.MouseIconEnabled
    end)
end

local function ApplyMenuMouse(open)
    pcall(function()
        if open then
            UserInputService.MouseIconEnabled = true
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        else
            -- Only freecam forces lock; third person must NOT trap the mouse
            if Config.Freecam then
                UserInputService.MouseIconEnabled = false
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            else
                UserInputService.MouseIconEnabled = true
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end
        end
    end)
end

local function UnlockMouse()
    ApplyMenuMouse(true)
end

local MouseMap = {
    M1B = Enum.UserInputType.MouseButton1,
    M2B = Enum.UserInputType.MouseButton2,
    M3B = Enum.UserInputType.MouseButton3,
}
pcall(function() MouseMap.M4B = Enum.UserInputType.MouseButton4 end)
pcall(function() MouseMap.M5B = Enum.UserInputType.MouseButton5 end)

local function InputMatches(bindKey, input)
    if not bindKey or bindKey == "None" or bindKey == "" then return false end
    -- normalize names
    if bindKey == "MouseButton4" or bindKey == "MB4" then bindKey = "M4B" end
    if bindKey == "MouseButton5" or bindKey == "MB5" then bindKey = "M5B" end
    if bindKey == "MouseButton1" or bindKey == "MB1" then bindKey = "M1B" end
    if bindKey == "MouseButton2" or bindKey == "MB2" then bindKey = "M2B" end
    if bindKey == "MouseButton3" or bindKey == "MB3" then bindKey = "M3B" end

    local uitName = tostring(input.UserInputType and input.UserInputType.Name or "")
    if bindKey == "M4B" then
        return uitName == "MouseButton4" or (MouseMap.M4B and input.UserInputType == MouseMap.M4B)
    end
    if bindKey == "M5B" then
        return uitName == "MouseButton5" or (MouseMap.M5B and input.UserInputType == MouseMap.M5B)
    end
    if MouseMap[bindKey] then
        return input.UserInputType == MouseMap[bindKey]
    end
    return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == bindKey
end

local function IsBindHeld(bindKey)
    if not bindKey or bindKey == "None" then return false end
    if bindKey == "MouseButton4" or bindKey == "MB4" then bindKey = "M4B" end
    if bindKey == "MouseButton5" or bindKey == "MB5" then bindKey = "M5B" end
    if bindKey == "M4B" or bindKey == "M5B" then
        local ok, pressed = pcall(function()
            local enumVal = MouseMap[bindKey]
            if enumVal then return UserInputService:IsMouseButtonPressed(enumVal) end
            return false
        end)
        return ok and pressed
    end
    if MouseMap[bindKey] then
        return UserInputService:IsMouseButtonPressed(MouseMap[bindKey])
    end
    local ok, code = pcall(function() return Enum.KeyCode[bindKey] end)
    if ok and code then return UserInputService:IsKeyDown(code) end
    return false
end

local function GetCharactersFolder()
    return workspace:FindFirstChild("Characters") or workspace:FindFirstChild("characters")
end

local function GetPlayerFromModelName(modelName)
    local plr = Players:FindFirstChild(modelName)
    if plr and plr:IsA("Player") then return plr end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == modelName or p.DisplayName == modelName then return p end
    end
    return nil
end

local function GetPlayerModel(plr)
    if not plr then return nil end
    local folder = GetCharactersFolder()
    if folder then
        local m = folder:FindFirstChild(plr.Name)
        if m and m:IsA("Model") then return m end
        if plr.DisplayName ~= "" then
            m = folder:FindFirstChild(plr.DisplayName)
            if m and m:IsA("Model") then return m end
        end
    end
    return nil
end

local function CollectTargets()
    local list, seen = {}, {}
    local folder = GetCharactersFolder()
    if folder then
        for _, model in ipairs(folder:GetChildren()) do
            if model:IsA("Model") then
                local plr = GetPlayerFromModelName(model.Name)
                if plr and plr ~= player and not seen[plr] then
                    seen[plr] = true
                    table.insert(list, { Plr = plr, Model = model, Char = plr.Character })
                end
            end
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and not seen[plr] then
            seen[plr] = true
            table.insert(list, { Plr = plr, Model = GetPlayerModel(plr), Char = plr.Character })
        end
    end
    return list
end

local function GetLocalModel()
    local folder = GetCharactersFolder()
    if folder then
        local m = folder:FindFirstChild(player.Name)
        if m and m:IsA("Model") then return m end
        if player.DisplayName ~= "" then
            m = folder:FindFirstChild(player.DisplayName)
            if m and m:IsA("Model") then return m end
        end
    end
    return player.Character
end

local function IsEmpty(val)
    if val == nil then return true end
    if type(val) == "string" then return string.gsub(val, "%s+", "") == "" end
    return false
end

local function IsTeammate(target)
    if not target or target == player then return false end
    -- Standard Team / TeamColor
    if player.Team and target.Team and player.Team == target.Team then return true end
    local sameColor = false
    pcall(function()
        if player.TeamColor and target.TeamColor and player.TeamColor == target.TeamColor then
            sameColor = true
        elseif player.TeamColor and target.TeamColor and player.TeamColor.Name == target.TeamColor.Name then
            sameColor = true
        end
    end)
    if sameColor then return true end
    -- Attributes on player / character (Rivals + others)
    local attrs = {
        "team", "Team", "TeamName", "teamName", "TeamId", "teamId",
        "clan", "Clan", "faction", "Faction", "FactionName",
        "group", "Group", "side", "Side", "Party", "party",
        "Squad", "squad", "Alliance", "Role", "role"
    }
    local function attrOf(plr, attr)
        local v = plr:GetAttribute(attr)
        if not IsEmpty(v) then return v end
        local ch = plr.Character
        if ch then
            local cv = ch:GetAttribute(attr)
            if not IsEmpty(cv) then return cv end
        end
        return nil
    end
    for _, attr in ipairs(attrs) do
        local a, b = attrOf(player, attr), attrOf(target, attr)
        if not IsEmpty(a) and not IsEmpty(b) and a == b then return true end
    end
    -- Values / StringValues under character (common in custom games)
    local function findTeamValue(plr)
        local ch = plr.Character
        if not ch then return nil end
        for _, name in ipairs({"Team", "team", "TeamName", "Side", "Faction"}) do
            local v = ch:FindFirstChild(name)
            if v and v:IsA("ValueBase") then return v.Value end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if hum then
                local hv = hum:FindFirstChild(name)
                if hv and hv:IsA("ValueBase") then return hv.Value end
            end
        end
        return nil
    end
    local ta, tb = findTeamValue(player), findTeamValue(target)
    if not IsEmpty(ta) and not IsEmpty(tb) and ta == tb then return true end
    return false
end

local function IsLocalAlive()
    local model = GetLocalModel()
    if not model then return false end
    if model:GetAttribute("Dead") == true or player:GetAttribute("Dead") == true then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum and (hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead) then return false end
    return true
end

local function ForceLocalVisible()
    local function vis(model)
        if not model then return end
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.LocalTransparencyModifier = 0 end)
            end
        end
    end
    vis(GetLocalModel())
    if player.Character then vis(player.Character) end
end


-- Intro: white "Neverlose" + two horizontal lines (UI opens only after this finishes)
getgenv().NL_INTRO_DONE = false
pcall(function()
    local guiParent = (gethui and gethui()) or CoreGui
    local introGui = Instance.new("ScreenGui")
    introGui.Name = "NL_Intro"
    introGui.IgnoreGuiInset = true
    introGui.DisplayOrder = 100000
    introGui.ResetOnSpawn = false
    introGui:SetAttribute("NL_HUB", true)
    introGui.Parent = guiParent

    -- Full-screen dark dim
    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BorderSizePixel = 0
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 1
    bg.ZIndex = 1
    bg.Parent = introGui

    local label = Instance.new("TextLabel")
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Position = UDim2.fromScale(0.5, 0.5)
    label.Size = UDim2.fromOffset(400, 48)
    label.BackgroundTransparency = 1
    label.Text = "Neverlose"
    label.Font = Enum.Font.GothamBold
    label.TextSize = 32
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextTransparency = 1
    label.ZIndex = 30
    label.Parent = introGui

    local function softLine(dir)
        -- dir: -1 left, +1 right
        local holder = Instance.new("Frame")
        holder.AnchorPoint = Vector2.new(dir < 0 and 1 or 0, 0.5)
        holder.Position = UDim2.new(0.5, dir * 105, 0.5, 0)
        holder.Size = UDim2.fromOffset(0, 14)
        holder.BackgroundTransparency = 1
        holder.BorderSizePixel = 0
        holder.ZIndex = 20
        holder.Parent = introGui

        -- Soft bloom (single outer glow)
        local glow = Instance.new("Frame")
        glow.AnchorPoint = Vector2.new(0, 0.5)
        glow.Position = UDim2.new(0, 0, 0.5, 0)
        glow.Size = UDim2.new(1, 0, 0, 8)
        glow.BorderSizePixel = 0
        glow.BackgroundColor3 = Color3.fromRGB(220, 235, 255)
        glow.BackgroundTransparency = 1
        glow.ZIndex = 21
        glow.Parent = holder
        local gc = Instance.new("UICorner")
        gc.CornerRadius = UDim.new(1, 0)
        gc.Parent = glow
        local ggrad = Instance.new("UIGradient")
        ggrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.35),
            NumberSequenceKeypoint.new(1, 1),
        })
        ggrad.Parent = glow

        -- Core sharp line
        local core = Instance.new("Frame")
        core.AnchorPoint = Vector2.new(0, 0.5)
        core.Position = UDim2.new(0, 0, 0.5, 0)
        core.Size = UDim2.new(1, 0, 0, 1)
        core.BorderSizePixel = 0
        core.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        core.BackgroundTransparency = 1
        core.ZIndex = 22
        core.Parent = holder
        local cc = Instance.new("UICorner")
        cc.CornerRadius = UDim.new(1, 0)
        cc.Parent = core

        return holder, glow, core
    end

    local leftH, leftGlow, leftCore = softLine(-1)
    local rightH, rightGlow, rightCore = softLine(1)

    TweenService:Create(bg, TweenInfo.new(0.4), { BackgroundTransparency = 0.4 }):Play()
    TweenService:Create(label, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()

    local expand = TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(leftH, expand, { Size = UDim2.fromOffset(145, 14) }):Play()
    TweenService:Create(rightH, expand, { Size = UDim2.fromOffset(145, 14) }):Play()
    TweenService:Create(leftGlow, expand, { BackgroundTransparency = 0.55 }):Play()
    TweenService:Create(rightGlow, expand, { BackgroundTransparency = 0.55 }):Play()
    TweenService:Create(leftCore, expand, { BackgroundTransparency = 0.1 }):Play()
    TweenService:Create(rightCore, expand, { BackgroundTransparency = 0.1 }):Play()

    task.delay(1.6, function()
        local fade = TweenInfo.new(0.45, Enum.EasingStyle.Quad)
        TweenService:Create(bg, fade, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
        TweenService:Create(leftGlow, fade, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(rightGlow, fade, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(leftCore, fade, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(rightCore, fade, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(leftH, fade, { Size = UDim2.fromOffset(0, 14) }):Play()
        TweenService:Create(rightH, fade, { Size = UDim2.fromOffset(0, 14) }):Play()
        task.delay(0.5, function()
            pcall(function() introGui:Destroy() end)
            getgenv().NL_INTRO_DONE = true
        end)
    end)
end)





task.delay(2.0, function()
    pcall(function()
        NeverLose:CreateNotification().new({ Title = "Neverlose", Content = "Universal Hub loaded", Duration = 3 })
    end)
end)

local FeatureState = {
    AA = false, Aimbot = false, ESP = false, Bhop = false,
    ThirdPerson = false, LoopFOV = false, LocalChams = false,
    Freecam = false, Ambient = false,
    AutoFire = false, KillAura = false,
}

local LastKeyFeature = nil

local aaConn, spinAngle, jitterSide, jitterClock = nil, 0, 1, 0

local function getHRP()
    local model = GetLocalModel()
    if not model then return nil, nil end
    return model:FindFirstChild("HumanoidRootPart"), model:FindFirstChildOfClass("Humanoid")
end

local function isShooting()
    return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        or UserInputService:IsKeyDown(Enum.KeyCode.F)
        or UserInputService:IsKeyDown(Enum.KeyCode.E)
end

local function StartAA()
    if aaConn then aaConn:Disconnect() end
    spinAngle, jitterSide, jitterClock = 0, 1, 0
    aaConn = RunService.RenderStepped:Connect(function(dt)
        if not Config.AA_Enabled then return end
        if isShooting() then return end
        local hrp, hum = getHRP()
        if not hrp or not hum then return end
        if Config.AA_DisableWhenSitting and (hum.Sit or hum.SeatPart) then
            hum.AutoRotate = true
            return
        end
        if Config.AA_Jitter then
            hum.AutoRotate = false
            jitterClock = jitterClock + dt
            if jitterClock >= 0.05 then
                jitterClock = 0
                jitterSide = -jitterSide
            end
            local yaw = math.rad(jitterSide * (Config.AA_JitterAmount or 40))
            local pos = hrp.Position
            local _, y = hrp.CFrame:ToOrientation()
            hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, y + yaw, 0)
            return
        end
        if Config.AA_Yaw == "None" then
            hum.AutoRotate = true
            return
        end
        hum.AutoRotate = false
        local pos = hrp.Position
        if Config.AA_Yaw == "Spin" then
            spinAngle = (spinAngle + Config.AA_SpinSpeed * 60 * dt) % 360
            hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(spinAngle), 0)
        elseif Config.AA_Yaw == "Back" then
            local look = camera.CFrame.LookVector
            local flat = Vector3.new(look.X, 0, look.Z)
            if flat.Magnitude > 0.01 then
                hrp.CFrame = CFrame.new(pos, pos - flat.Unit)
            end
        end
    end)
end

local function StopAA()
    if aaConn then aaConn:Disconnect() aaConn = nil end
    local _, hum = getHRP()
    if hum then hum.AutoRotate = true end
end

local jumpConn = nil
local function StartAutoJump()
    if jumpConn then jumpConn:Disconnect() end
    jumpConn = RunService.Heartbeat:Connect(function()
        if not Config.AutoJump or not IsLocalAlive() then return end
        local model = GetLocalModel()
        local hum = model and model:FindFirstChildOfClass("Humanoid")
        if hum then
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.Running or st == Enum.HumanoidStateType.RunningNoPhysics or st == Enum.HumanoidStateType.Landed then
                hum.Jump = true
            end
        end
    end)
end

local function StopAutoJump()
    if jumpConn then jumpConn:Disconnect() jumpConn = nil end
end

local speedLoopConn, jumpPowerConn = nil, nil

local function StartWalkSpeedLoop()
    if speedLoopConn then speedLoopConn:Disconnect() speedLoopConn = nil end
    if not Config.LoopWalkSpeed or Config.LoopWalkSpeed <= 0 then return end
    speedLoopConn = RunService.Heartbeat:Connect(function()
        if not Config.LoopWalkSpeed or Config.LoopWalkSpeed <= 0 then
            if speedLoopConn then speedLoopConn:Disconnect() speedLoopConn = nil end
            return
        end
        local model = GetLocalModel()
        local hum = model and model:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Config.LoopWalkSpeed end
        if player.Character then
            local h2 = player.Character:FindFirstChildOfClass("Humanoid")
            if h2 then h2.WalkSpeed = Config.LoopWalkSpeed end
        end
    end)
end

local function StartJumpPowerLoop()
    if jumpPowerConn then jumpPowerConn:Disconnect() jumpPowerConn = nil end
    if not Config.LoopJumpPower or Config.LoopJumpPower <= 0 then return end
    jumpPowerConn = RunService.Heartbeat:Connect(function()
        if not Config.LoopJumpPower or Config.LoopJumpPower <= 0 then
            if jumpPowerConn then jumpPowerConn:Disconnect() jumpPowerConn = nil end
            return
        end
        local function apply(hum)
            if not hum then return end
            hum.JumpPower = Config.LoopJumpPower
            pcall(function() hum.JumpHeight = Config.LoopJumpPower / 5 end)
        end
        local model = GetLocalModel()
        apply(model and model:FindFirstChildOfClass("Humanoid"))
        if player.Character then apply(player.Character:FindFirstChildOfClass("Humanoid")) end
    end)
end

local aimConn, fovCircle = nil, nil

local function CreateFOV()
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    if Drawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1.5
        fovCircle.NumSides = 64
        fovCircle.Filled = false
        fovCircle.Visible = false
        fovCircle.Color = Color3.fromRGB(255, 255, 255)
        fovCircle.Transparency = 1
    end
end

local function GetClosest()
    local closest, dist = nil, Config.Aimbot_FOV
    local center = camera.ViewportSize / 2
    local localModel = GetLocalModel()
    local function checkModel(char, plr)
        if not char or not char:IsA("Model") then return end
        if Config.Aimbot_TeamCheck and plr and IsTeammate(plr) then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local part = char:FindFirstChild(Config.Aimbot_Part)
            or char:FindFirstChild("HumanoidRootPart")
            or char:FindFirstChild("Head")
        if not part then return end
        if Config.Aimbot_AliveCheck and hum and hum.Health <= 0 then return end
        local screen, onScreen = camera:WorldToViewportPoint(part.Position)
        if not onScreen or screen.Z <= 0 then return end
        local d = (Vector2.new(screen.X, screen.Y) - center).Magnitude
        if d >= dist then return end
        if not Config.Aimbot_AutoWall then
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = { localModel, player.Character }
            params.FilterType = Enum.RaycastFilterType.Exclude
            local result = workspace:Raycast(camera.CFrame.Position, part.Position - camera.CFrame.Position, params)
            if result and result.Instance and not result.Instance:IsDescendantOf(char) then return end
        end
        dist = d
        closest = part
    end
    for _, entry in ipairs(CollectTargets()) do
        if entry.Model then checkModel(entry.Model, entry.Plr) end
        if entry.Char and entry.Char ~= entry.Model then checkModel(entry.Char, entry.Plr) end
    end
    return closest
end

local function MoveMouseToTarget(part)
    local screen, onScreen = camera:WorldToViewportPoint(part.Position)
    if not onScreen or screen.Z <= 0 then return end
    local mousePos = UserInputService:GetMouseLocation()
    local dx, dy = screen.X - mousePos.X, screen.Y - mousePos.Y
    local smooth = math.clamp(tonumber(Config.Aimbot_Smooth) or 0.3, 0.10, 1.00)
    local div = math.max(1.05 - smooth, 0.05)
    if moveMouse then
        moveMouse(dx * div, dy * div)
    else
        pcall(function()
            VirtualInputManager:SendMouseMoveEvent(mousePos.X + dx * div, mousePos.Y + dy * div, game)
        end)
    end
end

local function StartAimbot()
    if aimConn then aimConn:Disconnect() end
    CreateFOV()
    aimConn = RunService.RenderStepped:Connect(function()
        if fovCircle then
            fovCircle.Position = camera.ViewportSize / 2
            fovCircle.Radius = Config.Aimbot_FOV
            fovCircle.Visible = Config.Aimbot_ShowFOV and Config.Aimbot_Enabled
        end
        local aimHeld = IsBindHeld(Config.Aimbot_AimKey)
        local wantAim = Config.Aimbot_Enabled and aimHeld
        if not wantAim then return end
        local target = GetClosest()
        if not target then return end
        MoveMouseToTarget(target)
    end)
end

local function StopAimbot()
    if aimConn then aimConn:Disconnect() aimConn = nil end
    if fovCircle then fovCircle.Visible = false end
end

local killAuraConn = nil
local function StartKillAura()
end

local function StopKillAura()
    if killAuraConn then killAuraConn:Disconnect() killAuraConn = nil end
end

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "NL_ESP_" .. tostring(math.random(10000, 99999))
pcall(function() ESPFolder.Parent = gethui and gethui() or CoreGui end)
if not ESPFolder.Parent then ESPFolder.Parent = player:WaitForChild("PlayerGui") end

local highlights, drawings, localHighlights = {}, {}, {}

local function CreateDrawing(t)
    if not Drawing then return nil end
    local d = Drawing.new(t)
    d.Visible = false
    return d
end

local function ClearESP()
    for _, h in pairs(highlights) do pcall(function() h:Destroy() end) end
    highlights = {}
    for _, d in pairs(drawings) do
        pcall(function()
            for _, obj in pairs(d) do if obj and obj.Remove then obj:Remove() end end
        end)
    end
    drawings = {}
end

local function EnsureHL(store, key, adornee, fill, outline, ft, ot)
    if not adornee or not adornee.Parent then return end
    local h = store[key]
    if not h or not h.Parent then
        h = Instance.new("Highlight")
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = ESPFolder
        store[key] = h
    end
    h.Adornee = adornee
    h.FillColor = fill
    h.OutlineColor = outline
    h.FillTransparency = ft
    h.OutlineTransparency = ot
    h.Enabled = true
end

local function RefreshChams()
    local enemyFill, enemyOutline = ToColor3(Config.ESP_FillColor), ToColor3(Config.ESP_OutlineColor)
    local teamFill, teamOutline = ToColor3(Config.ESP_TeamFillColor), ToColor3(Config.ESP_TeamOutlineColor)
    local seenLocal, seenP = {}, {}
    if Config.LocalChams then
        local model, char = GetLocalModel(), player.Character
        local fill, outline = ToColor3(Config.LocalChams_Fill), ToColor3(Config.LocalChams_Outline)
        local ft, ot = Config.LocalChams_FillTransparency, Config.LocalChams_OutlineTransparency
        if model then EnsureHL(localHighlights, "lm", model, fill, outline, ft, ot) seenLocal.lm = true end
        if char and char ~= model then EnsureHL(localHighlights, "lc", char, fill, outline, ft, ot) seenLocal.lc = true end
    end
    for k, h in pairs(localHighlights) do
        if not Config.LocalChams or not seenLocal[k] then pcall(function() h:Destroy() end) localHighlights[k] = nil end
    end
    if Config.ESP_Enabled and (Config.ESP_Chams or Config.ESP_Highlight) then
        for _, entry in ipairs(CollectTargets()) do
            local plr = entry.Plr
            local isTeam = IsTeammate(plr)
            if not (isTeam and Config.ESP_TeamCheck and not Config.ESP_TeamChams) then
                local fill = isTeam and teamFill or enemyFill
                local outline = isTeam and teamOutline or enemyOutline
                local ft, ot = Config.ESP_FillTransparency, Config.ESP_OutlineTransparency
                if entry.Model then
                    local key = "m" .. plr.UserId
                    seenP[key] = true
                    EnsureHL(highlights, key, entry.Model, fill, outline, ft, ot)
                end
                if entry.Char then
                    local key = "c" .. plr.UserId
                    seenP[key] = true
                    EnsureHL(highlights, key, entry.Char, fill, outline, ft, ot)
                end
            end
        end
    end
    for key, h in pairs(highlights) do
        if not seenP[key] then pcall(function() h:Destroy() end) highlights[key] = nil end
    end
end

task.spawn(function()
    while true do
        pcall(RefreshChams)
        task.wait(Config.LocalChams and 0.35 or 5)
    end
end)

local function OffsetPos(base, side, amount)
    if side == "Up" then return Vector2.new(base.X, base.Y - amount)
    elseif side == "Bottom" then return Vector2.new(base.X, base.Y + amount)
    elseif side == "Left" then return Vector2.new(base.X - amount, base.Y)
    elseif side == "Right" then return Vector2.new(base.X + amount, base.Y)
    end
    return base
end

local function UpdateESPDrawings()
    if not Config.ESP_Enabled then
        for _, d in pairs(drawings) do for _, o in pairs(d) do if o then o.Visible = false end end end
        return
    end
    local nameColor, distColor = ToColor3(Config.ESP_NameColor), ToColor3(Config.ESP_DistColor)
    local tracerColor, ballColor = ToColor3(Config.ESP_TracerColor), ToColor3(Config.ESP_BallColor)
    local seen = {}
    for _, entry in ipairs(CollectTargets()) do
        local plr = entry.Plr
        if Config.ESP_TeamCheck and IsTeammate(plr) then
            -- skip
        else
            local model = entry.Model or entry.Char
            if model then
                local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model:FindFirstChildWhichIsA("BasePart")
                local head = model:FindFirstChild("Head") or hrp
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hrp then
                    local dist = (hrp.Position - camera.CFrame.Position).Magnitude
                    if dist <= Config.ESP_MaxDistance then
                        local uid = plr.UserId
                        seen[uid] = true
                        if not drawings[uid] then
                            drawings[uid] = {
                                Name = CreateDrawing("Text"), Dist = CreateDrawing("Text"),
                                HealthBg = CreateDrawing("Square"), Health = CreateDrawing("Square"),
                                Tracer = CreateDrawing("Line"), Ball = CreateDrawing("Circle"),
                            }
                        end
                        local d = drawings[uid]
                        if not d.OOF then
                            d.OOF = CreateDrawing("Triangle")
                        end
                        local screen, onScreen = camera:WorldToViewportPoint(hrp.Position)
                        local screenPos = Vector2.new(screen.X, screen.Y)
                        local showOnScreen = onScreen and screen.Z > 0
                        if d.Ball then
                            if showOnScreen and Config.ESP_Ball then
                                d.Ball.Position = screenPos
                                d.Ball.Radius = Config.ESP_BallSize
                                d.Ball.Color = ballColor
                                d.Ball.Filled = true
                                d.Ball.NumSides = 16
                                d.Ball.Visible = true
                            else
                                d.Ball.Visible = false
                            end
                        end
                        if d.Name then
                            if showOnScreen and Config.ESP_Name then
                                d.Name.Text = plr.DisplayName or plr.Name
                                d.Name.Size = Config.ESP_NameSize
                                d.Name.Color = nameColor
                                d.Name.Center = true
                                d.Name.Outline = true
                                d.Name.OutlineColor = Color3.new(0, 0, 0)
                                d.Name.Position = OffsetPos(screenPos, Config.ESP_NamePos, Config.ESP_BallSize + 16)
                                d.Name.Visible = true
                            else
                                d.Name.Visible = false
                            end
                        end
                        if d.Dist then
                            if showOnScreen and Config.ESP_Distance then
                                d.Dist.Text = math.floor(dist) .. "m"
                                d.Dist.Size = Config.ESP_DistSize
                                d.Dist.Color = distColor
                                d.Dist.Center = true
                                d.Dist.Outline = true
                                d.Dist.OutlineColor = Color3.new(0, 0, 0)
                                d.Dist.Position = OffsetPos(screenPos, Config.ESP_DistPos, Config.ESP_BallSize + 4)
                                d.Dist.Visible = true
                            else
                                d.Dist.Visible = false
                            end
                        end
                        -- OOF arrow (Lines — works without Drawing Triangle support)
                        if not d.OOF1 then
                            d.OOF1 = CreateDrawing("Line")
                            d.OOF2 = CreateDrawing("Line")
                            d.OOF3 = CreateDrawing("Line")
                        end
                        if d.OOF1 then
                            if (not showOnScreen) and Config.ESP_OOF then
                                local vp = camera.ViewportSize
                                local cx, cy = vp.X * 0.5, vp.Y * 0.5
                                local rel = camera.CFrame:PointToObjectSpace(hrp.Position)
                                local dir = Vector2.new(rel.X, -rel.Y)
                                if dir.Magnitude < 0.001 then dir = Vector2.new(0, -1) else dir = dir.Unit end
                                local radius = math.min(cx, cy) * 0.45
                                local tip = Vector2.new(cx, cy) + dir * radius
                                local side = Vector2.new(-dir.Y, dir.X)
                                local size = Config.ESP_OOF_Size or 14
                                local base = tip - dir * size
                                local p2 = base + side * (size * 0.6)
                                local p3 = base - side * (size * 0.6)
                                local oc = ToColor3(Config.ESP_OOF_Color or {255,255,255})
                                for _, ln in ipairs({d.OOF1, d.OOF2, d.OOF3}) do
                                    ln.Color = oc
                                    ln.Thickness = 2
                                    ln.Visible = true
                                end
                                d.OOF1.From, d.OOF1.To = tip, p2
                                d.OOF2.From, d.OOF2.To = tip, p3
                                d.OOF3.From, d.OOF3.To = p2, p3
                            else
                                if d.OOF1 then d.OOF1.Visible = false end
                                if d.OOF2 then d.OOF2.Visible = false end
                                if d.OOF3 then d.OOF3.Visible = false end
                            end
                        end
                        if d.OOF then d.OOF.Visible = false end
                        if onScreen and screen.Z > 0 and d.Health and hum then
                            local headScreen = camera:WorldToViewportPoint((head and head.Position or hrp.Position) + Vector3.new(0, 0.9, 0))
                            local hp = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                            local barH, barW = Config.ESP_HealthHeight, Config.ESP_HealthWidth
                            local bx, by = headScreen.X - 34, headScreen.Y - 14
                            if Config.ESP_HealthPos == "Right" then bx = headScreen.X + 28
                            elseif Config.ESP_HealthPos == "Up" then bx = headScreen.X - barW / 2 by = headScreen.Y - barH - 8
                            elseif Config.ESP_HealthPos == "Bottom" then bx = headScreen.X - barW / 2 by = headScreen.Y + 8 end
                            d.HealthBg.Size = Vector2.new(barW, barH)
                            d.HealthBg.Position = Vector2.new(bx, by)
                            d.HealthBg.Color = Color3.fromRGB(15, 15, 15)
                            d.HealthBg.Filled = true
                            d.HealthBg.Visible = Config.ESP_Healthbar
                            d.Health.Size = Vector2.new(barW, barH * hp)
                            d.Health.Position = Vector2.new(bx, by + barH * (1 - hp))
                            d.Health.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 40)
                            d.Health.Filled = true
                            d.Health.Visible = Config.ESP_Healthbar
                        else
                            if d.Health then d.Health.Visible = false end
                            if d.HealthBg then d.HealthBg.Visible = false end
                        end
                        if d.Tracer and onScreen and screen.Z > 0 then
                            d.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                            d.Tracer.To = screenPos
                            d.Tracer.Color = tracerColor
                            d.Tracer.Thickness = 1.3
                            d.Tracer.Visible = Config.ESP_Tracers
                        elseif d.Tracer then d.Tracer.Visible = false end
                    end
                end
            end
        end
    end
    for uid, d in pairs(drawings) do
        if not seen[uid] then
            pcall(function() for _, o in pairs(d) do if o and o.Remove then o:Remove() end end end)
            drawings[uid] = nil
        end
    end
end

local thirdConn, savedZoom = nil, nil
local function StartThirdPerson()
    if thirdConn then thirdConn:Disconnect() end
    pcall(function()
        savedZoom = { min = player.CameraMinZoomDistance, max = player.CameraMaxZoomDistance }
        player.CameraMinZoomDistance = Config.ThirdPerson_Distance
        player.CameraMaxZoomDistance = Config.ThirdPerson_Distance
    end)
    camera.CameraType = Enum.CameraType.Custom
    thirdConn = RunService.RenderStepped:Connect(function()
        if not Config.ThirdPerson or Config.Freecam then return end
        ForceLocalVisible()
        -- Do not force MouseBehavior here (was trapping cursor)
        pcall(function()
            player.CameraMinZoomDistance = Config.ThirdPerson_Distance
            player.CameraMaxZoomDistance = Config.ThirdPerson_Distance
        end)
        local model = GetLocalModel()
        local hum = model and model:FindFirstChildOfClass("Humanoid")
        if hum then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = hum
            pcall(function() hum.CameraOffset = Vector3.new(0, 1.5, 0) end)
        end
    end)
end

local function StopThirdPerson()
    if thirdConn then thirdConn:Disconnect() thirdConn = nil end
    pcall(function()
        if savedZoom then
            player.CameraMinZoomDistance = savedZoom.min or 0.5
            player.CameraMaxZoomDistance = savedZoom.max or 128
        end
    end)
    if not Config.Freecam then
        camera.CameraType = Enum.CameraType.Custom
        local model = GetLocalModel()
        local hum = model and model:FindFirstChildOfClass("Humanoid")
        if hum then
            camera.CameraSubject = hum
            pcall(function() hum.CameraOffset = Vector3.zero end)
        end
    end
end

local fovConn, defaultFOV = nil, 70
pcall(function() defaultFOV = camera.FieldOfView end)

local function StartLoopFOV()
    if fovConn then fovConn:Disconnect() end
    fovConn = RunService.RenderStepped:Connect(function()
        if Config.LoopFOV then camera.FieldOfView = Config.LoopFOV_Value end
    end)
end

local function StopLoopFOV()
    if fovConn then fovConn:Disconnect() fovConn = nil end
    camera.FieldOfView = defaultFOV
end

local freecamConn, freecamYaw, freecamPitch, moveKeys = nil, 0, 0, {}

local function StartFreecam()
    if freecamConn then return end
    if Config.ThirdPerson then StopThirdPerson() end
    camera.CameraType = Enum.CameraType.Scriptable
    if not menuOpen then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
    local look = camera.CFrame.LookVector
    freecamYaw = math.atan2(-look.X, -look.Z)
    freecamPitch = math.asin(math.clamp(look.Y, -1, 1))
    freecamConn = RunService.RenderStepped:Connect(function(dt)
        if not Config.Freecam then return end
        ForceLocalVisible()
        if menuOpen then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        else
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
        local delta = UserInputService:GetMouseDelta()
        freecamYaw = freecamYaw - delta.X * 0.0035
        freecamPitch = math.clamp(freecamPitch - delta.Y * 0.0035, math.rad(-89), math.rad(89))
        local rot = CFrame.Angles(0, freecamYaw, 0) * CFrame.Angles(freecamPitch, 0, 0)
        local move = Vector3.zero
        local speed = Config.Freecam_Speed * (moveKeys.Shift and 3 or 1) * 60 * dt
        if moveKeys.W then move = move + rot.LookVector end
        if moveKeys.S then move = move - rot.LookVector end
        if moveKeys.A then move = move - rot.RightVector end
        if moveKeys.D then move = move + rot.RightVector end
        if moveKeys.E then move = move + Vector3.yAxis end
        if moveKeys.Q then move = move - Vector3.yAxis end
        if move.Magnitude > 0 then move = move.Unit * speed end
        camera.CFrame = CFrame.new(camera.CFrame.Position + move) * rot
    end)
end

local function StopFreecam()
    if freecamConn then freecamConn:Disconnect() freecamConn = nil end
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    camera.CameraType = Enum.CameraType.Custom
    local model = GetLocalModel()
    local hum = model and model:FindFirstChildOfClass("Humanoid")
    if hum then camera.CameraSubject = hum end
    if Config.ThirdPerson then StartThirdPerson() end
end

local function EnsureEffect(className, name)
    local e = Lighting:FindFirstChild(name)
    if not e then
        e = Instance.new(className)
        e.Name = name
        e.Parent = Lighting
    end
    return e
end

local savedLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ColorShift_Top = Lighting.ColorShift_Top,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor,
}

local function ApplyWorld()
    if Config.AmbientEnabled then
        Lighting.Ambient = ToColor3(Config.AmbientColor)
        Lighting.OutdoorAmbient = ToColor3(Config.OutdoorAmbient)
        Lighting.ColorShift_Top = ToColor3(Config.ColorShift_Top)
        Lighting.ColorShift_Bottom = ToColor3(Config.ColorShift_Bottom)
        pcall(function()
            Lighting.Brightness = Config.LightBrightness or 1
        end)
    else
        Lighting.Ambient = savedLighting.Ambient
        Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
        Lighting.ColorShift_Top = savedLighting.ColorShift_Top
        Lighting.ColorShift_Bottom = savedLighting.ColorShift_Bottom
    end

    local bloom = EnsureEffect("BloomEffect", "NL_Bloom")
    bloom.Enabled = Config.BloomEnabled
    bloom.Intensity = Config.BloomIntensity
    bloom.Size = Config.BloomSize
    bloom.Threshold = Config.BloomThreshold

    local cc = EnsureEffect("ColorCorrectionEffect", "NL_CC")
    cc.Enabled = Config.ColorCorrectionEnabled
    cc.Brightness = Config.CC_Brightness
    cc.Contrast = Config.CC_Contrast
    cc.Saturation = Config.CC_Saturation

    local rays = EnsureEffect("SunRaysEffect", "NL_SunRays")
    rays.Enabled = Config.SunRaysEnabled
    rays.Intensity = Config.SunRaysIntensity
    rays.Spread = Config.SunRaysSpread

    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if Config.AtmosphereEnabled then
        if not atmo then
            atmo = Instance.new("Atmosphere")
            atmo.Name = "NL_Atmosphere"
            atmo.Parent = Lighting
        end
        atmo.Density = Config.AtmosphereDensity
        atmo.Offset = Config.AtmosphereOffset
        atmo.Color = ToColor3(Config.AtmosphereColor)
    elseif atmo and atmo.Name == "NL_Atmosphere" then
        atmo:Destroy()
    end

    if Config.FogEnabled then
        Lighting.FogStart = Config.FogStart
        Lighting.FogEnd = Config.FogEnd
        Lighting.FogColor = ToColor3(Config.FogColor)
    else
        Lighting.FogStart = savedLighting.FogStart
        Lighting.FogEnd = savedLighting.FogEnd
        Lighting.FogColor = savedLighting.FogColor
    end
end

local function ApplySkinToModel(model, description)
    if not model then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    pcall(function()
        hum:ApplyDescriptionClientServer(description)
    end)
    pcall(function()
        hum:ApplyDescription(description)
    end)
    pcall(function()
        local clone = description:Clone()
        hum:ApplyDescriptionReset(clone)
    end)
end

local function ApplySkinChanger(userId)
    userId = tonumber(userId)
    if not userId or userId <= 0 then return false, "Invalid user id" end
    local ok, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(userId)
    end)
    if not ok or not desc then return false, tostring(desc) end

    local applied = false
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local ok2 = pcall(function() hum:ApplyDescription(desc) end)
            if not ok2 then
                pcall(function()
                    local appearance = Players:GetCharacterAppearanceInfoAsync(userId)
                end)
                pcall(function()
                    char.Parent = nil
                    local newModel = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
                    if newModel then
                        newModel.Name = char.Name
                        newModel.Parent = workspace
                    end
                end)
            end
            applied = true
        end
    end

    local model = GetLocalModel()
    if model and model ~= char then
        local hum = model:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function() hum:ApplyDescription(desc) end)
            applied = true
        end
    end

    -- visual bodycolors / clothing fallback
    pcall(function()
        local target = model or char
        if not target then return end
        for _, item in ipairs(target:GetChildren()) do
            if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
                item:Destroy()
            end
        end
        if desc.Shirt > 0 then
            local s = Instance.new("Shirt")
            s.ShirtTemplate = "rbxassetid://" .. tostring(desc.Shirt)
            s.Parent = target
        end
        if desc.Pants > 0 then
            local p = Instance.new("Pants")
            p.PantsTemplate = "rbxassetid://" .. tostring(desc.Pants)
            p.Parent = target
        end
    end)

    return applied, applied and "Applied" or "Failed"
end

local function ResolveUsernameToId(name)
    local ok, id = pcall(function()
        return Players:GetUserIdFromNameAsync(name)
    end)
    if ok then return id end
    return nil
end

local function ApplyFeature(name, on)
    on = on and true or false
    FeatureState[name] = on
    if name == "AA" then
        Config.AA_Enabled = on
        if on then StartAA() else StopAA() end
    elseif name == "Aimbot" then
        Config.Aimbot_Enabled = on
        if on then StartAimbot() else StopAimbot() end
    elseif name == "ESP" then
        Config.ESP_Enabled = on
        if not on then ClearESP() end
        RefreshChams()
    elseif name == "Bhop" then
        Config.AutoJump = on
        if on then StartAutoJump() else StopAutoJump() end
    elseif name == "ThirdPerson" then
        Config.ThirdPerson = on
        if on then StartThirdPerson() else StopThirdPerson() end
    elseif name == "LoopFOV" then
        Config.LoopFOV = on
        if on then StartLoopFOV() else StopLoopFOV() end
    elseif name == "LocalChams" then
        Config.LocalChams = on
        RefreshChams()
    elseif name == "Freecam" then
        Config.Freecam = on
        if on then StartFreecam() else StopFreecam() end
    elseif name == "Ambient" then
        Config.AmbientEnabled = on
        ApplyWorld()
    end
    AutoSave()
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.W then moveKeys.W = true end
    if input.KeyCode == Enum.KeyCode.A then moveKeys.A = true end
    if input.KeyCode == Enum.KeyCode.S then moveKeys.S = true end
    if input.KeyCode == Enum.KeyCode.D then moveKeys.D = true end
    if input.KeyCode == Enum.KeyCode.E then moveKeys.E = true end
    if input.KeyCode == Enum.KeyCode.Q then moveKeys.Q = true end
    if input.KeyCode == Enum.KeyCode.LeftShift then moveKeys.Shift = true end

    if gpe then return end
    for name, data in pairs(Config.Keys) do
        if InputMatches(data.Key, input) then
            ApplyFeature(name, not FeatureState[name])
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then moveKeys.W = false end
    if input.KeyCode == Enum.KeyCode.A then moveKeys.A = false end
    if input.KeyCode == Enum.KeyCode.S then moveKeys.S = false end
    if input.KeyCode == Enum.KeyCode.D then moveKeys.D = false end
    if input.KeyCode == Enum.KeyCode.E then moveKeys.E = false end
    if input.KeyCode == Enum.KeyCode.Q then moveKeys.Q = false end
    if input.KeyCode == Enum.KeyCode.LeftShift then moveKeys.Shift = false end
end)

RunService.RenderStepped:Connect(function()
    if Config.ESP_Enabled then UpdateESPDrawings() end
    if Config.ThirdPerson or Config.Freecam then ForceLocalVisible() end
end)

-- Mouse is only forced unlocked while the menu is open.
-- When closed, gameplay / freecam mouse lock is restored.
RunService.RenderStepped:Connect(function()
    if menuOpen and not Config.Freecam then
        -- Keep unlocked only while menu is open (do not touch freecam lock while closed)
        if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
        if not UserInputService.MouseIconEnabled then
            UserInputService.MouseIconEnabled = true
        end
    end
end)

local charsFolder = GetCharactersFolder()
if charsFolder then
    charsFolder.ChildAdded:Connect(function() task.wait(0.2) RefreshChams() end)
end
Players.PlayerAdded:Connect(function() task.wait(0.3) RefreshChams() end)

local Window
do
    local ok, win = pcall(function()
        return NeverLose:CreateWindow({
            Logo = NeverLose.GlobalLogo,
            Name = "Neverlose",
            Content = "Universal Hub",
            Size = (NeverLose.Scales and NeverLose.Scales.Default) or UDim2.fromOffset(700, 520),
            ConfigFolder = "NeverloseNL",
            Enable3DRenderer = false,
            Keybind = "Insert"
        })
    end)
    if not ok or not win then
        warn("[Neverlose] CreateWindow failed:", win)
        return
    end
    Window = win
    pcall(function()
        if NeverLose.ScreenGui then
            NeverLose.ScreenGui:SetAttribute("NL_HUB", true)
        end
    end)
end

-- Gate: library auto-opens at 0.25s; block until intro finishes
getgenv().NL_ALLOW_UI = false
do
    local rawSetRender = Window.SetRender
    function Window:SetRender(value)
        if value == true and not getgenv().NL_ALLOW_UI then
            value = false
        end
        if type(rawSetRender) == "function" then
            return rawSetRender(self, value)
        end
    end
    -- Force closed now
    pcall(function()
        if Window.Signal then Window.Signal:SetValue(false) end
        rawSetRender(Window, false)
    end)
end

pcall(function()
    local oldToggle = Window.ToggleInterface
    if typeof(oldToggle) == "function" then
        function Window:ToggleInterface(...)
            if not getgenv().NL_ALLOW_UI then return end
            local wasOpen = menuOpen
            if not wasOpen then CaptureMouseState() end
            oldToggle(self, ...)
            local open = false
            pcall(function()
                open = self.Signal and self.Signal:GetValue() or false
            end)
            menuOpen = open and true or false
            ApplyMenuMouse(menuOpen)
        end
    end
end)
CaptureMouseState()
menuOpen = false
ApplyMenuMouse(false)

local function storeKey(name)
    return function(v)
        if typeof(v) == "EnumItem" then v = v.Name end
        if v == "Escape" or v == "Esc" then
            Config.Keys[name].Key = "None"
        elseif v == "MouseButton4" or v == "MB4" then
            Config.Keys[name].Key = "M4B"
            LastKeyFeature = name
        elseif v == "MouseButton5" or v == "MB5" then
            Config.Keys[name].Key = "M5B"
            LastKeyFeature = name
        elseif type(v) == "string" and v ~= "" and v ~= "None" then
            Config.Keys[name].Key = v
            LastKeyFeature = name
        else
            Config.Keys[name].Key = "None"
        end
    end
end

local function bindFeature(label, name, defaultOn, flag)
    label:AddToggle({
        Default = defaultOn,
        Flag = flag,
        Callback = function(v) ApplyFeature(name, v) end
    })
    label:AddKeybind({
        Default = Config.Keys[name].Key ~= "None" and Config.Keys[name].Key or nil,
        Flag = flag .. "_Key",
        Callback = function(v)
            storeKey(name)(v)
            LastKeyFeature = name
        end
    })
end

Window:AddTabLabel("MAIN")
local LegitTab = Window:AddTab({ Icon = "crosshairs", Name = "Legit" })
local AATab = Window:AddTab({ Icon = "eye", Name = "Anti-Aim" })
local MoveTab = Window:AddTab({ Icon = "person", Name = "Movement" })
local Visuals = Window:AddTab({ Icon = "cube", Name = "Visuals" })
local WorldTab = Window:AddTab({ Icon = "sun", Name = "World" })
local MiscTab = Window:AddTab({ Icon = "cube", Name = "Misc" })
local ConfigTab = Window:AddTab({ Icon = "gear", Name = "Configs" })

local AimSec = LegitTab:AddSection({ Name = "AIMBOT", Position = "left" })
local AASec = AATab:AddSection({ Name = "ANTI-AIM", Position = "left" })
local ESPSec = Visuals:AddSection({ Name = "ESP", Position = "left" })
local ESPStyle = Visuals:AddSection({ Name = "ESP STYLE", Position = "right" })
local LocalSec = Visuals:AddSection({ Name = "LOCAL", Position = "right" })
local MoveSec = MoveTab:AddSection({ Name = "MOVEMENT", Position = "left" })
local CamSec = MiscTab:AddSection({ Name = "CAMERA", Position = "left" })
local EnvSec = WorldTab:AddSection({ Name = "LIGHTING", Position = "left" })
local FxSec = WorldTab:AddSection({ Name = "EFFECTS", Position = "right" })
local CfgSec = ConfigTab:AddSection({ Name = "CONFIGS", Position = "left" })


local aimLabel = AimSec:AddLabel("Enabled")
bindFeature(aimLabel, "Aimbot", Config.Aimbot_Enabled, "Aimbot_Enabled")
AimSec:AddLabel("Aim Key"):AddKeybind({
    Default = Config.Aimbot_AimKey ~= "None" and Config.Aimbot_AimKey or "M2B",
    Flag = "Aimbot_AimKey",
    Callback = function(v)
        if v == "None" or v == "Escape" or v == "Esc" then
            Config.Aimbot_AimKey = "None"
        else
            Config.Aimbot_AimKey = (type(v) == "string" and v ~= "" and v) or "M2B"
        end
    end
})
AimSec:AddLabel("Team Check"):AddToggle({
    Default = Config.Aimbot_TeamCheck, Flag = "Aimbot_TeamCheck",
    Callback = function(v) Config.Aimbot_TeamCheck = v AutoSave() end
})
AimSec:AddLabel("Alive Check"):AddToggle({
    Default = Config.Aimbot_AliveCheck, Flag = "Aimbot_AliveCheck",
    Callback = function(v) Config.Aimbot_AliveCheck = v AutoSave() end
})
AimSec:AddLabel("Auto Wall"):AddToggle({
    Default = Config.Aimbot_AutoWall, Flag = "Aimbot_AutoWall",
    Callback = function(v) Config.Aimbot_AutoWall = v AutoSave() end
})
AimSec:AddLabel("Show FOV"):AddToggle({
    Default = Config.Aimbot_ShowFOV, Flag = "Aimbot_ShowFOV",
    Callback = function(v) Config.Aimbot_ShowFOV = v AutoSave() end
})
AimSec:AddLabel("FOV"):AddSlider({
    Min = 40, Max = 400, Default = Config.Aimbot_FOV, Flag = "Aimbot_FOV",
    Callback = function(v) Config.Aimbot_FOV = v AutoSave() end
})
AimSec:AddLabel("Smoothness"):AddSlider({
    Min = 0.10, Max = 1.00, Default = Config.Aimbot_Smooth, Rounding = 2, Flag = "Aimbot_Smooth",
    Callback = function(v)
        Config.Aimbot_Smooth = math.floor(v * 10 + 0.5) / 10
        AutoSave()
    end
})
AimSec:AddLabel("Aim Part"):AddDropdown({
    Default = Config.Aimbot_Part, Values = {"Head", "HumanoidRootPart", "UpperTorso"}, Flag = "Aimbot_Part",
    Callback = function(v) Config.Aimbot_Part = v AutoSave() end
})

local aaLabel = AASec:AddLabel("Enabled")
bindFeature(aaLabel, "AA", Config.AA_Enabled, "AA_Enabled")
AASec:AddLabel("Disable When Sitting"):AddToggle({
    Default = Config.AA_DisableWhenSitting, Flag = "AA_Sit",
    Callback = function(v) Config.AA_DisableWhenSitting = v AutoSave() end
})
AASec:AddLabel("Yaw Mode"):AddDropdown({
    Default = Config.AA_Yaw, Values = {"None", "Back", "Spin"}, Flag = "AA_Yaw",
    Callback = function(v) Config.AA_Yaw = v AutoSave() end
})
AASec:AddLabel("Jitter"):AddToggle({
    Default = Config.AA_Jitter, Flag = "AA_Jitter",
    Callback = function(v)
        Config.AA_Jitter = v
        if v and Config.AA_Enabled then StartAA() end
        AutoSave()
    end
})
AASec:AddLabel("Spin Speed"):AddSlider({
    Min = 1, Max = 40, Default = Config.AA_SpinSpeed, Flag = "AA_SpinSpeed",
    Callback = function(v) Config.AA_SpinSpeed = v AutoSave() end
})
AASec:AddLabel("Jitter Amount"):AddSlider({
    Min = 5, Max = 90, Default = Config.AA_JitterAmount, Flag = "AA_JitterAmount",
    Callback = function(v) Config.AA_JitterAmount = v AutoSave() end
})

local espLabel = ESPSec:AddLabel("Enabled")
bindFeature(espLabel, "ESP", Config.ESP_Enabled, "ESP_Enabled")
ESPSec:AddLabel("Team Check"):AddToggle({
    Default = Config.ESP_TeamCheck, Flag = "ESP_TeamCheck",
    Callback = function(v) Config.ESP_TeamCheck = v AutoSave() end
})
ESPSec:AddLabel("Team Chams"):AddToggle({
    Default = Config.ESP_TeamChams, Flag = "ESP_TeamChams",
    Callback = function(v) Config.ESP_TeamChams = v RefreshChams() AutoSave() end
})
ESPSec:AddLabel("Chams"):AddToggle({
    Default = Config.ESP_Chams, Flag = "ESP_Chams",
    Callback = function(v) Config.ESP_Chams = v RefreshChams() AutoSave() end
})
ESPSec:AddLabel("Name"):AddToggle({ Default = Config.ESP_Name, Flag = "ESP_Name", Callback = function(v) Config.ESP_Name = v AutoSave() end })
ESPSec:AddLabel("Distance"):AddToggle({ Default = Config.ESP_Distance, Flag = "ESP_Distance", Callback = function(v) Config.ESP_Distance = v AutoSave() end })
ESPSec:AddLabel("Healthbar"):AddToggle({ Default = Config.ESP_Healthbar, Flag = "ESP_Healthbar", Callback = function(v) Config.ESP_Healthbar = v AutoSave() end })
ESPSec:AddLabel("Tracers"):AddToggle({ Default = Config.ESP_Tracers, Flag = "ESP_Tracers", Callback = function(v) Config.ESP_Tracers = v AutoSave() end })
ESPSec:AddLabel("Ball"):AddToggle({ Default = Config.ESP_Ball, Flag = "ESP_Ball", Callback = function(v) Config.ESP_Ball = v end })
ESPSec:AddLabel("OOF Arrows"):AddToggle({ Default = Config.ESP_OOF ~= false, Flag = "ESP_OOF", Callback = function(v) Config.ESP_OOF = v end })
ESPSec:AddLabel("Max Distance"):AddSlider({
    Min = 50, Max = 100000, Default = Config.ESP_MaxDistance, Flag = "ESP_MaxDistance",
    Callback = function(v) Config.ESP_MaxDistance = v AutoSave() end
})

ESPStyle:AddLabel("Name Size"):AddSlider({ Min = 10, Max = 28, Default = Config.ESP_NameSize, Flag = "ESP_NameSize", Callback = function(v) Config.ESP_NameSize = v AutoSave() end })
ESPStyle:AddLabel("Name Position"):AddDropdown({ Default = Config.ESP_NamePos, Values = {"Up", "Bottom", "Left", "Right"}, Flag = "ESP_NamePos", Callback = function(v) Config.ESP_NamePos = v AutoSave() end })
ESPStyle:AddLabel("Dist Size"):AddSlider({ Min = 8, Max = 24, Default = Config.ESP_DistSize, Flag = "ESP_DistSize", Callback = function(v) Config.ESP_DistSize = v AutoSave() end })
ESPStyle:AddLabel("Dist Position"):AddDropdown({ Default = Config.ESP_DistPos, Values = {"Up", "Bottom", "Left", "Right"}, Flag = "ESP_DistPos", Callback = function(v) Config.ESP_DistPos = v AutoSave() end })
ESPStyle:AddLabel("Health Position"):AddDropdown({ Default = Config.ESP_HealthPos, Values = {"Left", "Right", "Up", "Bottom"}, Flag = "ESP_HealthPos", Callback = function(v) Config.ESP_HealthPos = v AutoSave() end })
pcall(function()
    ESPStyle:AddLabel("Name Color"):AddColorPicker({ Default = ToColor3(Config.ESP_NameColor), Flag = "ESP_NameColor", Callback = function(c) Config.ESP_NameColor = FromColor3(c) AutoSave() end })
    ESPStyle:AddLabel("Dist Color"):AddColorPicker({ Default = ToColor3(Config.ESP_DistColor), Flag = "ESP_DistColor", Callback = function(c) Config.ESP_DistColor = FromColor3(c) AutoSave() end })
    ESPStyle:AddLabel("Enemy Fill"):AddColorPicker({ Default = ToColor3(Config.ESP_FillColor), Flag = "ESP_FillColor", Callback = function(c) Config.ESP_FillColor = FromColor3(c) RefreshChams() AutoSave() end })
    ESPStyle:AddLabel("Team Fill"):AddColorPicker({ Default = ToColor3(Config.ESP_TeamFillColor), Flag = "ESP_TeamFillColor", Callback = function(c) Config.ESP_TeamFillColor = FromColor3(c) RefreshChams() AutoSave() end })
end)

local lcLabel = LocalSec:AddLabel("Local Chams")
bindFeature(lcLabel, "LocalChams", Config.LocalChams, "LocalChams")

local jumpLabel = MoveSec:AddLabel("Auto Jump")
bindFeature(jumpLabel, "Bhop", Config.AutoJump, "AutoJump")
MoveSec:AddLabel("WalkSpeed Loop"):AddSlider({
    Min = 0, Max = 100, Default = Config.LoopWalkSpeed, Flag = "LoopWalkSpeed",
    Nums = { [0] = "None" },
    Callback = function(v)
        Config.LoopWalkSpeed = v
        if v <= 0 then
            Config.LoopWalkSpeed = 0
            if speedLoopConn then speedLoopConn:Disconnect() speedLoopConn = nil end
        else
            StartWalkSpeedLoop()
        end
        AutoSave()
    end
})
MoveSec:AddLabel("JumpPower Loop"):AddSlider({
    Min = 0, Max = 200, Default = Config.LoopJumpPower, Flag = "LoopJumpPower",
    Nums = { [0] = "None" },
    Callback = function(v)
        Config.LoopJumpPower = v
        if v <= 0 then
            Config.LoopJumpPower = 0
            if jumpPowerConn then jumpPowerConn:Disconnect() jumpPowerConn = nil end
        else
            StartJumpPowerLoop()
        end
        AutoSave()
    end
})

local tpLabel = CamSec:AddLabel("Third Person")
bindFeature(tpLabel, "ThirdPerson", Config.ThirdPerson, "ThirdPerson")
CamSec:AddLabel("TP Distance"):AddSlider({
    Min = 2, Max = 30, Default = Config.ThirdPerson_Distance, Flag = "TP_Distance",
    Callback = function(v) Config.ThirdPerson_Distance = v AutoSave() end
})
local fovLabel = CamSec:AddLabel("Loop FOV")
bindFeature(fovLabel, "LoopFOV", Config.LoopFOV, "LoopFOV")
CamSec:AddLabel("FOV Value"):AddSlider({
    Min = 30, Max = 120, Default = Config.LoopFOV_Value, Flag = "LoopFOV_Value",
    Callback = function(v) Config.LoopFOV_Value = v AutoSave() end
})
local fcLabel = CamSec:AddLabel("Freecam")
bindFeature(fcLabel, "Freecam", Config.Freecam, "Freecam")
CamSec:AddLabel("Freecam Speed"):AddSlider({
    Min = 1, Max = 10, Default = Config.Freecam_Speed, Flag = "Freecam_Speed",
    Callback = function(v) Config.Freecam_Speed = v AutoSave() end
})

local ambLabel = EnvSec:AddLabel("Custom Ambient")
bindFeature(ambLabel, "Ambient", Config.AmbientEnabled, "AmbientEnabled")
pcall(function()
EnvSec:AddLabel("Light Color"):AddColorPicker({
    Default = ToColor3(Config.LightColor or {255,255,255}), Flag = "LightColor",
    Callback = function(c)
        Config.LightColor = FromColor3(c)
        pcall(function() Lighting.ColorShift_Top = c end)
        ApplyWorld()
    end
})
end)
EnvSec:AddLabel("Light Brightness"):AddSlider({
    Min = 0, Max = 10, Default = Config.LightBrightness or 1, Rounding = 2, Flag = "LightBrightness",
    Callback = function(v) Config.LightBrightness = v pcall(function() Lighting.Brightness = v end) end
})
pcall(function()
    EnvSec:AddLabel("Ambient"):AddColorPicker({ Default = ToColor3(Config.AmbientColor), Flag = "AmbientColor", Callback = function(c) Config.AmbientColor = FromColor3(c) ApplyWorld() AutoSave() end })
    EnvSec:AddLabel("Outdoor"):AddColorPicker({ Default = ToColor3(Config.OutdoorAmbient), Flag = "OutdoorAmbient", Callback = function(c) Config.OutdoorAmbient = FromColor3(c) ApplyWorld() AutoSave() end })
    EnvSec:AddLabel("Shift Top"):AddColorPicker({ Default = ToColor3(Config.ColorShift_Top), Flag = "ColorShift_Top", Callback = function(c) Config.ColorShift_Top = FromColor3(c) ApplyWorld() AutoSave() end })
    EnvSec:AddLabel("Shift Bottom"):AddColorPicker({ Default = ToColor3(Config.ColorShift_Bottom), Flag = "ColorShift_Bottom", Callback = function(c) Config.ColorShift_Bottom = FromColor3(c) ApplyWorld() AutoSave() end })
end)
EnvSec:AddLabel("Fog"):AddToggle({
    Default = Config.FogEnabled, Flag = "FogEnabled",
    Callback = function(v) Config.FogEnabled = v ApplyWorld() AutoSave() end
})
EnvSec:AddLabel("Fog Start"):AddSlider({ Min = 0, Max = 500, Default = Config.FogStart, Flag = "FogStart", Callback = function(v) Config.FogStart = v ApplyWorld() AutoSave() end })
EnvSec:AddLabel("Fog End"):AddSlider({ Min = 100, Max = 5000, Default = Config.FogEnd, Flag = "FogEnd", Callback = function(v) Config.FogEnd = v ApplyWorld() AutoSave() end })
pcall(function()
    EnvSec:AddLabel("Fog Color"):AddColorPicker({ Default = ToColor3(Config.FogColor), Flag = "FogColor", Callback = function(c) Config.FogColor = FromColor3(c) ApplyWorld() AutoSave() end })
end)

FxSec:AddLabel("Bloom"):AddToggle({
    Default = Config.BloomEnabled, Flag = "BloomEnabled",
    Callback = function(v) Config.BloomEnabled = v ApplyWorld() AutoSave() end
})
FxSec:AddLabel("Bloom Intensity"):AddSlider({ Min = 0, Max = 2, Default = Config.BloomIntensity, Rounding = 2, Flag = "BloomIntensity", Callback = function(v) Config.BloomIntensity = v ApplyWorld() AutoSave() end })
FxSec:AddLabel("Bloom Size"):AddSlider({ Min = 1, Max = 56, Default = Config.BloomSize, Flag = "BloomSize", Callback = function(v) Config.BloomSize = v ApplyWorld() AutoSave() end })
FxSec:AddLabel("Bloom Threshold"):AddSlider({ Min = 0, Max = 2, Default = Config.BloomThreshold, Rounding = 2, Flag = "BloomThreshold", Callback = function(v) Config.BloomThreshold = v ApplyWorld() AutoSave() end })
FxSec:AddLabel("Color Correction"):AddToggle({
    Default = Config.ColorCorrectionEnabled, Flag = "CCEnabled",
    Callback = function(v) Config.ColorCorrectionEnabled = v ApplyWorld() AutoSave() end
})
FxSec:AddLabel("CC Brightness"):AddSlider({ Min = -1, Max = 1, Default = Config.CC_Brightness, Rounding = 2, Flag = "CC_Brightness", Callback = function(v) Config.CC_Brightness = v ApplyWorld() AutoSave() end })
FxSec:AddLabel("CC Contrast"):AddSlider({ Min = -1, Max = 1, Default = Config.CC_Contrast, Rounding = 2, Flag = "CC_Contrast", Callback = function(v) Config.CC_Contrast = v ApplyWorld() AutoSave() end })
FxSec:AddLabel("CC Saturation"):AddSlider({ Min = -1, Max = 1, Default = Config.CC_Saturation, Rounding = 2, Flag = "CC_Saturation", Callback = function(v) Config.CC_Saturation = v ApplyWorld() AutoSave() end })
FxSec:AddLabel("Sun Rays"):AddToggle({
    Default = Config.SunRaysEnabled, Flag = "SunRays",
    Callback = function(v) Config.SunRaysEnabled = v ApplyWorld() AutoSave() end
})
FxSec:AddLabel("Sun Rays Intensity"):AddSlider({ Min = 0, Max = 1, Default = Config.SunRaysIntensity, Rounding = 2, Flag = "SunRaysI", Callback = function(v) Config.SunRaysIntensity = v ApplyWorld() AutoSave() end })
FxSec:AddLabel("Atmosphere"):AddToggle({
    Default = Config.AtmosphereEnabled, Flag = "Atmosphere",
    Callback = function(v) Config.AtmosphereEnabled = v ApplyWorld() AutoSave() end
})
FxSec:AddLabel("Atmosphere Density"):AddSlider({ Min = 0, Max = 1, Default = Config.AtmosphereDensity, Rounding = 2, Flag = "AtmoDensity", Callback = function(v) Config.AtmosphereDensity = v ApplyWorld() AutoSave() end })


-- ===================== Configs (manual) =====================
local function ListConfigFiles()
    local names = {}
    pcall(function()
        if isfolder and isfolder("NeverloseNL") then
            for _, f in ipairs(listfiles("NeverloseNL")) do
                local n = tostring(f):match("([^/\\]+)%.json$")
                if n then table.insert(names, n) end
            end
        end
    end)
    return names
end

pcall(function() -- configs tab (isolated so errors never block UI open)
Config.ConfigName = Config.ConfigName or "default"

CfgSec:AddLabel("Config Name"):AddTextBox({
    Default = Config.ConfigName or "default",
    Flag = "ConfigNameBox",
    Callback = function(v) Config.ConfigName = tostring(v or "default") end
})
CfgSec:AddButton({
    Name = "Save Config",
    Callback = function()
        local ok, err = SaveConfig(Config.ConfigName)
        pcall(function()
            NeverLose:CreateNotification().new({
                Title = "Configs",
                Content = ok and ("Saved: " .. tostring(Config.ConfigName)) or ("Save failed: " .. tostring(err)),
                Duration = 3
            })
        end)
    end
})
CfgSec:AddButton({
    Name = "Load Config",
    Callback = function()
        local ok, err = LoadConfig(Config.ConfigName)
        if ok then
            pcall(function()
                if Config.AA_Enabled then StartAA() else StopAA() end
                if Config.Aimbot_Enabled then StartAimbot() else StopAimbot() end
                if Config.AutoJump then StartAutoJump() else StopAutoJump() end
                if Config.ThirdPerson then StartThirdPerson() else StopThirdPerson() end
                if Config.Freecam then StartFreecam() else StopFreecam() end
                if Config.LoopFOV then StartLoopFOV() else StopLoopFOV() end
                ApplyWorld()
                RefreshChams()
            end)
        end
        pcall(function()
            NeverLose:CreateNotification().new({
                Title = "Configs",
                Content = ok and ("Loaded: " .. tostring(Config.ConfigName)) or ("Load failed: " .. tostring(err)),
                Duration = 3
            })
        end)
    end
})
CfgSec:AddButton({
    Name = "Delete Config",
    Callback = function()
        local ok, err = DeleteConfig(Config.ConfigName)
        pcall(function()
            NeverLose:CreateNotification().new({
                Title = "Configs",
                Content = ok and ("Deleted: " .. tostring(Config.ConfigName)) or ("Delete failed: " .. tostring(err)),
                Duration = 3
            })
        end)
    end
})

end)

FeatureState.AA = Config.AA_Enabled
FeatureState.Aimbot = Config.Aimbot_Enabled
FeatureState.ESP = Config.ESP_Enabled
FeatureState.Bhop = Config.AutoJump
FeatureState.ThirdPerson = Config.ThirdPerson
FeatureState.LoopFOV = Config.LoopFOV
FeatureState.LocalChams = Config.LocalChams
FeatureState.Freecam = Config.Freecam
FeatureState.Ambient = Config.AmbientEnabled

if Config.AA_Enabled then StartAA() end
if Config.Aimbot_Enabled then StartAimbot() end
if Config.AutoJump then StartAutoJump() end
if Config.LoopWalkSpeed and Config.LoopWalkSpeed > 0 then StartWalkSpeedLoop() end
if Config.LoopJumpPower and Config.LoopJumpPower > 0 then StartJumpPowerLoop() end
if Config.ThirdPerson then StartThirdPerson() end
if Config.LoopFOV then StartLoopFOV() end
if Config.Freecam then StartFreecam() end
ApplyWorld()
RefreshChams()
-- Open menu ONLY after intro is done
task.spawn(function()
    local t0 = os.clock()
    while not getgenv().NL_INTRO_DONE and (os.clock() - t0) < 4 do
        task.wait(0.05)
    end
    task.wait(0.15)

    getgenv().NL_ALLOW_UI = true

    pcall(function()
        -- destroy residual blur FX
        for _, fx in ipairs(game:GetService("Lighting"):GetChildren()) do
            if fx:IsA("DepthOfFieldEffect") then
                pcall(function() fx:Destroy() end)
            end
        end
    end)

    pcall(function()
        if not Window then return end
        if Window.Signal then Window.Signal:SetValue(true) end
        if Window.SetRender then Window:SetRender(true) end
        if type(Window.Tabs) == "table" then
            local idx = Window.CurrentTab or 1
            for i, tab in ipairs(Window.Tabs) do
                if tab and tab.SetValue then
                    tab.SetValue(i == idx)
                end
            end
        end
    end)

    menuOpen = true
    ApplyMenuMouse(true)
end)
