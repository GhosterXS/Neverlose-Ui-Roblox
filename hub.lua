--[[
    Neverlose Universal Hub
    UI: https://raw.githubusercontent.com/GhosterXS/Neverlose-Ui-Roblox/main/source.luau
]]

local REPO_UI = "https://raw.githubusercontent.com/GhosterXS/Neverlose-Ui-Roblox/main/source.luau"

local NeverLose
do
    local ok, res = pcall(function()
        local src = game:HttpGet(REPO_UI)
        assert(type(src) == "string" and #src > 100, "UI download empty")
        local fn, err = loadstring(src)
        assert(fn, tostring(err))
        return fn()
    end)
    if not ok or not res then
        warn("[Neverlose] Failed to load UI:", res)
        return
    end
    NeverLose = res
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local moveMouse = mousemoverel or (Input and Input.MouseMove) or nil

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

    LocalChams = false,
    LocalChams_Fill = {80, 160, 255},
    LocalChams_Outline = {255, 255, 255},
    LocalChams_FillTransparency = 0.5,
    LocalChams_OutlineTransparency = 0,

    Freecam = false,
    Freecam_Speed = 2,

    AmbientEnabled = false,
    AmbientColor = {255, 255, 255},
    OutdoorAmbient = {128, 128, 128},
    ColorShift_Top = {0, 0, 0},
    ColorShift_Bottom = {0, 0, 0},

    Rage_Spinbot = false,
    Rage_SpinSpeed = 20,
    Rage_NoRotate = false,
    Rage_AutoFire = false,
    Rage_RapidFire = false,

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
        Silent = { Key = "None", Mode = "Toggle" },
        Spinbot = { Key = "None", Mode = "Toggle" },
        AutoFire = { Key = "None", Mode = "Toggle" },
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

local ConfigFolder, ConfigFile = "NeverloseHub", "config.json"

local function SaveConfig()
    pcall(function()
        if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
        writefile(ConfigFolder .. "/" .. ConfigFile, HttpService:JSONEncode(Config))
    end)
end

local function LoadConfig()
    pcall(function()
        local path = ConfigFolder .. "/" .. ConfigFile
        if isfile(path) then
            local data = HttpService:JSONDecode(readfile(path))
            for k, v in pairs(data) do
                if Config[k] ~= nil then Config[k] = v end
            end
        end
    end)
end
LoadConfig()

local function AutoSave()
    SaveConfig()
end

local function UnlockMouse()
    pcall(function()
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end)
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
    if MouseMap[bindKey] then
        return input.UserInputType == MouseMap[bindKey]
    end
    return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == bindKey
end

local function IsBindHeld(bindKey)
    if not bindKey or bindKey == "None" then return false end
    if MouseMap[bindKey] then
        return UserInputService:IsMouseButtonPressed(MouseMap[bindKey])
    end
    local ok, code = pcall(function() return Enum.KeyCode[bindKey] end)
    if ok and code then
        return UserInputService:IsKeyDown(code)
    end
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
    if player.Team and target.Team and player.Team == target.Team then return true end
    local attrs = {"team", "Team", "clan", "Clan", "faction", "Faction", "FactionName", "group", "Group", "side", "Side"}
    for _, attr in ipairs(attrs) do
        local a, b = player:GetAttribute(attr), target:GetAttribute(attr)
        if not IsEmpty(a) and not IsEmpty(b) and a == b then return true end
    end
    return false
end

local function IsLocalAlive()
    local model = GetLocalModel()
    if not model then return false end
    if model:GetAttribute("Dead") == true then return false end
    if player:GetAttribute("Dead") == true then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then
        if hum.Health <= 0 then return false end
        if hum:GetState() == Enum.HumanoidStateType.Dead then return false end
    end
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

do
    local gui = Instance.new("ScreenGui")
    gui.Name = "NLIntro"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 9999
    gui.ResetOnSpawn = false
    pcall(function() gui.Parent = gethui and gethui() or CoreGui end)
    if not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
    bg.BorderSizePixel = 0
    bg.Parent = gui

    local title = Instance.new("TextLabel")
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.Position = UDim2.fromScale(0.5, 0.5)
    title.Size = UDim2.fromOffset(420, 60)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "Neverlose"
    title.TextColor3 = Color3.fromRGB(120, 190, 255)
    title.TextSize = 42
    title.TextTransparency = 1
    title.Parent = bg

    local sub = Instance.new("TextLabel")
    sub.AnchorPoint = Vector2.new(0.5, 0)
    sub.Position = UDim2.new(0.5, 0, 0.5, 36)
    sub.Size = UDim2.fromOffset(300, 24)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Gotham
    sub.Text = "Universal Hub"
    sub.TextColor3 = Color3.fromRGB(160, 170, 190)
    sub.TextSize = 14
    sub.TextTransparency = 1
    sub.Parent = bg

    TweenService:Create(title, TweenInfo.new(0.55), { TextTransparency = 0 }):Play()
    TweenService:Create(sub, TweenInfo.new(0.55), { TextTransparency = 0.2 }):Play()

    for i = 1, 16 do
        local line = Instance.new("Frame")
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Position = UDim2.fromScale(0.5, 0.5)
        line.Size = UDim2.fromOffset(2, 0)
        line.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
        line.BackgroundTransparency = 0.25
        line.BorderSizePixel = 0
        line.Parent = bg
        local angle = math.rad((i - 1) * (360 / 16))
        local dist = 160
        TweenService:Create(line, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {
            Size = UDim2.fromOffset(2, 70),
            Position = UDim2.new(0.5, math.cos(angle) * dist, 0.5, math.sin(angle) * dist),
            BackgroundTransparency = 1,
            Rotation = math.deg(angle) + 90
        }):Play()
    end

    task.wait(1.2)
    TweenService:Create(title, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
    TweenService:Create(sub, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
    TweenService:Create(bg, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
    task.wait(0.4)
    gui:Destroy()
end

pcall(function()
    local Notification = NeverLose:CreateNotification()
    Notification.new({ Title = "Neverlose", Content = "Universal Hub loaded", Duration = 3 })
end)

local FeatureState = {
    AA = false, Aimbot = false, ESP = false, Bhop = false,
    ThirdPerson = false, LoopFOV = false, LocalChams = false,
    Freecam = false, Ambient = false, Silent = false,
    Spinbot = false, AutoFire = false,
}

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
    spinAngle = 0
    jitterSide = 1
    jitterClock = 0
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
            local _, y, _ = hrp.CFrame:ToOrientation()
            hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, y + yaw, 0)
            return
        end

        if Config.AA_Yaw == "None" and not Config.Rage_Spinbot then
            if not Config.Rage_NoRotate then
                hum.AutoRotate = true
            end
            return
        end

        hum.AutoRotate = false
        local pos = hrp.Position

        if Config.Rage_Spinbot or Config.AA_Yaw == "Spin" then
            local spd = Config.Rage_Spinbot and Config.Rage_SpinSpeed or Config.AA_SpinSpeed
            spinAngle = (spinAngle + spd * 60 * dt) % 360
            hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(spinAngle), 0)
        elseif Config.AA_Yaw == "Back" then
            local look = camera.CFrame.LookVector
            local flat = Vector3.new(look.X, 0, look.Z)
            if flat.Magnitude > 0.01 then
                hrp.CFrame = CFrame.new(pos, pos - flat.Unit)
            end
        end

        if Config.Rage_NoRotate then
            hum.AutoRotate = false
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
        if not Config.AutoJump then return end
        if not IsLocalAlive() then return end
        local model = GetLocalModel()
        local hum = model and model:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Running
            or state == Enum.HumanoidStateType.RunningNoPhysics
            or state == Enum.HumanoidStateType.Landed then
            hum.Jump = true
        end
        if player.Character then
            local h2 = player.Character:FindFirstChildOfClass("Humanoid")
            if h2 and h2 ~= hum then
                local s2 = h2:GetState()
                if s2 == Enum.HumanoidStateType.Running or s2 == Enum.HumanoidStateType.Landed then
                    h2.Jump = true
                end
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
        if player.Character then
            apply(player.Character:FindFirstChildOfClass("Humanoid"))
        end
    end)
end

local aimConn, fovCircle, silentTarget = nil, nil, nil

local function CreateFOV()
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    if Drawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1.5
        fovCircle.NumSides = 64
        fovCircle.Radius = Config.Aimbot_FOV
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
            local origin = camera.CFrame.Position
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = { localModel, player.Character }
            params.FilterType = Enum.RaycastFilterType.Exclude
            local result = workspace:Raycast(origin, part.Position - origin, params)
            if result and result.Instance and not result.Instance:IsDescendantOf(char) then
                return
            end
        end
        dist = d
        closest = part
    end

    for _, entry in ipairs(CollectTargets()) do
        if entry.Model then checkModel(entry.Model, entry.Plr) end
        if entry.Char and entry.Char ~= entry.Model then
            checkModel(entry.Char, entry.Plr)
        end
    end
    return closest
end

local function MoveMouseToTarget(part)
    local screen, onScreen = camera:WorldToViewportPoint(part.Position)
    if not onScreen or screen.Z <= 0 then return end
    local mousePos = UserInputService:GetMouseLocation()
    local dx = screen.X - mousePos.X
    local dy = screen.Y - mousePos.Y
    local smooth = math.clamp(tonumber(Config.Aimbot_Smooth) or 0.3, 0.10, 1.00)
    local div = 1.05 - smooth
    if div < 0.05 then div = 0.05 end
    if moveMouse then
        moveMouse(dx * div, dy * div)
    else
        pcall(function()
            VirtualInputManager:SendMouseMoveEvent(
                mousePos.X + dx * div,
                mousePos.Y + dy * div,
                game
            )
        end)
    end
end

local function StartAimbot()
    if aimConn then aimConn:Disconnect() end
    CreateFOV()
    aimConn = RunService.RenderStepped:Connect(function()
        if fovCircle then
            local center = camera.ViewportSize / 2
            fovCircle.Position = center
            fovCircle.Radius = Config.Aimbot_FOV
            fovCircle.Visible = Config.Aimbot_ShowFOV and (Config.Aimbot_Enabled or Config.Aimbot_Silent)
        end

        local aimHeld = IsBindHeld(Config.Aimbot_AimKey)
        local wantAim = Config.Aimbot_Enabled and aimHeld
        local wantSilent = Config.Aimbot_Silent

        if not wantAim and not wantSilent then
            silentTarget = nil
            return
        end

        local target = GetClosest()
        silentTarget = target

        if wantSilent and target then
            pcall(function()
                camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
            end)
        elseif wantAim and target then
            MoveMouseToTarget(target)
        end

        if Config.Rage_AutoFire and target and aimHeld then
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            end)
            task.defer(function()
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                end)
            end)
        end
    end)
end

local function StopAimbot()
    if aimConn then aimConn:Disconnect() aimConn = nil end
    if fovCircle then fovCircle.Visible = false end
    silentTarget = nil
end

local rapidConn = nil
local function StartRapidFire()
    if rapidConn then rapidConn:Disconnect() end
    rapidConn = RunService.Heartbeat:Connect(function()
        if not Config.Rage_RapidFire then return end
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
    end)
end

local function StopRapidFire()
    if rapidConn then rapidConn:Disconnect() rapidConn = nil end
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
            for _, obj in pairs(d) do
                if obj and obj.Remove then obj:Remove() end
            end
        end)
    end
    drawings = {}
end

local function EnsureHL(store, key, adornee, fill, outline, ft, ot)
    if not adornee or not adornee.Parent then return end
    local h = store[key]
    if not h or not h.Parent then
        h = Instance.new("Highlight")
        h.Name = "ESP_" .. tostring(key)
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
    local enemyFill = ToColor3(Config.ESP_FillColor)
    local enemyOutline = ToColor3(Config.ESP_OutlineColor)
    local teamFill = ToColor3(Config.ESP_TeamFillColor)
    local teamOutline = ToColor3(Config.ESP_TeamOutlineColor)
    local seenLocal, seenP = {}, {}

    if Config.LocalChams then
        local model, char = GetLocalModel(), player.Character
        local fill, outline = ToColor3(Config.LocalChams_Fill), ToColor3(Config.LocalChams_Outline)
        local ft, ot = Config.LocalChams_FillTransparency, Config.LocalChams_OutlineTransparency
        if model then
            EnsureHL(localHighlights, "lm", model, fill, outline, ft, ot)
            seenLocal.lm = true
        end
        if char and char ~= model then
            EnsureHL(localHighlights, "lc", char, fill, outline, ft, ot)
            seenLocal.lc = true
        end
    end
    for k, h in pairs(localHighlights) do
        if not Config.LocalChams or not seenLocal[k] then
            pcall(function() h:Destroy() end)
            localHighlights[k] = nil
        end
    end

    if Config.ESP_Enabled and (Config.ESP_Chams or Config.ESP_Highlight) then
        for _, entry in ipairs(CollectTargets()) do
            local plr = entry.Plr
            local isTeam = IsTeammate(plr)
            if isTeam and Config.ESP_TeamCheck and not Config.ESP_TeamChams then
                -- skip
            else
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
        if not seenP[key] then
            pcall(function() h:Destroy() end)
            highlights[key] = nil
        end
    end
end

task.spawn(function()
    while true do
        pcall(RefreshChams)
        task.wait(5)
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
        for _, d in pairs(drawings) do
            for _, obj in pairs(d) do
                if obj then obj.Visible = false end
            end
        end
        return
    end

    local nameColor = ToColor3(Config.ESP_NameColor)
    local distColor = ToColor3(Config.ESP_DistColor)
    local tracerColor = ToColor3(Config.ESP_TracerColor)
    local ballColor = ToColor3(Config.ESP_BallColor)
    local maxDist = Config.ESP_MaxDistance
    local seen = {}

    for _, entry in ipairs(CollectTargets()) do
        local plr = entry.Plr
        if Config.ESP_TeamCheck and IsTeammate(plr) then
            -- skip enemy-only when teamcheck
        else
            local model = entry.Model or entry.Char
            if model then
                local hrp = model:FindFirstChild("HumanoidRootPart")
                    or model:FindFirstChild("Torso")
                    or model:FindFirstChild("UpperTorso")
                    or model:FindFirstChildWhichIsA("BasePart")
                local head = model:FindFirstChild("Head") or hrp
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hrp then
                    local dist = (hrp.Position - camera.CFrame.Position).Magnitude
                    if dist <= maxDist then
                        local uid = plr.UserId
                        seen[uid] = true
                        if not drawings[uid] then
                            drawings[uid] = {
                                Name = CreateDrawing("Text"),
                                Dist = CreateDrawing("Text"),
                                HealthBg = CreateDrawing("Square"),
                                Health = CreateDrawing("Square"),
                                Tracer = CreateDrawing("Line"),
                                Ball = CreateDrawing("Circle"),
                            }
                        end
                        local d = drawings[uid]
                        local screen, onScreen = camera:WorldToViewportPoint(hrp.Position)
                        local screenPos = Vector2.new(screen.X, screen.Y)
                        if not onScreen or screen.Z <= 0 then
                            local viewport = camera.ViewportSize
                            screenPos = Vector2.new(
                                math.clamp(screen.X, 20, viewport.X - 20),
                                math.clamp(screen.Y, 20, viewport.Y - 20)
                            )
                        end

                        if d.Ball and Config.ESP_Ball then
                            d.Ball.Position = screenPos
                            d.Ball.Radius = Config.ESP_BallSize
                            d.Ball.Color = ballColor
                            d.Ball.Filled = true
                            d.Ball.NumSides = 16
                            d.Ball.Visible = true
                        elseif d.Ball then
                            d.Ball.Visible = false
                        end

                        if d.Name then
                            d.Name.Text = plr.DisplayName or plr.Name
                            d.Name.Size = Config.ESP_NameSize
                            d.Name.Color = nameColor
                            d.Name.Center = true
                            d.Name.Outline = true
                            d.Name.OutlineColor = Color3.new(0, 0, 0)
                            d.Name.Position = OffsetPos(screenPos, Config.ESP_NamePos, Config.ESP_BallSize + 16)
                            d.Name.Visible = Config.ESP_Name
                        end

                        if d.Dist then
                            d.Dist.Text = math.floor(dist) .. "m"
                            d.Dist.Size = Config.ESP_DistSize
                            d.Dist.Color = distColor
                            d.Dist.Center = true
                            d.Dist.Outline = true
                            d.Dist.OutlineColor = Color3.new(0, 0, 0)
                            d.Dist.Position = OffsetPos(screenPos, Config.ESP_DistPos, Config.ESP_BallSize + 4)
                            d.Dist.Visible = Config.ESP_Distance
                        end

                        if onScreen and screen.Z > 0 and d.HealthBg and d.Health and hum then
                            local headScreen = camera:WorldToViewportPoint((head and head.Position or hrp.Position) + Vector3.new(0, 0.9, 0))
                            local hp = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                            local barH, barW = Config.ESP_HealthHeight, Config.ESP_HealthWidth
                            local bx, by = headScreen.X, headScreen.Y
                            if Config.ESP_HealthPos == "Left" then
                                bx = headScreen.X - 34
                                by = headScreen.Y - 14
                            elseif Config.ESP_HealthPos == "Right" then
                                bx = headScreen.X + 28
                                by = headScreen.Y - 14
                            elseif Config.ESP_HealthPos == "Up" then
                                bx = headScreen.X - barW / 2
                                by = headScreen.Y - barH - 8
                            else
                                bx = headScreen.X - barW / 2
                                by = headScreen.Y + 8
                            end
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
                        elseif d.Tracer then
                            d.Tracer.Visible = false
                        end
                    end
                end
            end
        end
    end

    for uid, d in pairs(drawings) do
        if not seen[uid] then
            pcall(function()
                for _, obj in pairs(d) do
                    if obj and obj.Remove then obj:Remove() end
                end
            end)
            drawings[uid] = nil
        end
    end
end

local thirdConn, savedZoom = nil, nil

local function StartThirdPerson()
    if thirdConn then thirdConn:Disconnect() end
    pcall(function()
        savedZoom = {
            min = player.CameraMinZoomDistance,
            max = player.CameraMaxZoomDistance,
        }
        player.CameraMinZoomDistance = Config.ThirdPerson_Distance
        player.CameraMaxZoomDistance = Config.ThirdPerson_Distance
    end)
    camera.CameraType = Enum.CameraType.Custom
    local model = GetLocalModel()
    local hum = model and model:FindFirstChildOfClass("Humanoid")
    if hum then camera.CameraSubject = hum end
    thirdConn = RunService.RenderStepped:Connect(function()
        if not Config.ThirdPerson or Config.Freecam then return end
        ForceLocalVisible()
        pcall(function()
            player.CameraMinZoomDistance = Config.ThirdPerson_Distance
            player.CameraMaxZoomDistance = Config.ThirdPerson_Distance
        end)
        local model = GetLocalModel()
        local hum = model and model:FindFirstChildOfClass("Humanoid")
        if hum and camera.CameraSubject ~= hum then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = hum
        end
        if hum then
            pcall(function()
                hum.CameraOffset = Vector3.new(0, 1, 0)
            end)
        end
    end)
end

local function StopThirdPerson()
    if thirdConn then thirdConn:Disconnect() thirdConn = nil end
    pcall(function()
        if savedZoom then
            player.CameraMinZoomDistance = savedZoom.min or 0.5
            player.CameraMaxZoomDistance = savedZoom.max or 128
        else
            player.CameraMinZoomDistance = 0.5
            player.CameraMaxZoomDistance = 128
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

local fovConn = nil
local defaultFOV = 70
pcall(function() defaultFOV = camera.FieldOfView end)

local function StartLoopFOV()
    if fovConn then fovConn:Disconnect() end
    fovConn = RunService.RenderStepped:Connect(function()
        if Config.LoopFOV then
            camera.FieldOfView = Config.LoopFOV_Value
        end
    end)
end

local function StopLoopFOV()
    if fovConn then fovConn:Disconnect() fovConn = nil end
    camera.FieldOfView = defaultFOV
end

local freecamConn = nil
local freecamYaw, freecamPitch = 0, 0
local moveKeys = {}

local function StartFreecam()
    if freecamConn then return end
    if Config.ThirdPerson then StopThirdPerson() end
    camera.CameraType = Enum.CameraType.Scriptable
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    local look = camera.CFrame.LookVector
    freecamYaw = math.atan2(-look.X, -look.Z)
    freecamPitch = math.asin(math.clamp(look.Y, -1, 1))
    freecamConn = RunService.RenderStepped:Connect(function(dt)
        if not Config.Freecam then return end
        ForceLocalVisible()
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
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

local savedLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ColorShift_Top = Lighting.ColorShift_Top,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
}

local function ApplyAmbient()
    if not Config.AmbientEnabled then
        Lighting.Ambient = savedLighting.Ambient
        Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
        Lighting.ColorShift_Top = savedLighting.ColorShift_Top
        Lighting.ColorShift_Bottom = savedLighting.ColorShift_Bottom
        return
    end
    Lighting.Ambient = ToColor3(Config.AmbientColor)
    Lighting.OutdoorAmbient = ToColor3(Config.OutdoorAmbient)
    Lighting.ColorShift_Top = ToColor3(Config.ColorShift_Top)
    Lighting.ColorShift_Bottom = ToColor3(Config.ColorShift_Bottom)
end

local function ApplyFeature(name, on)
    FeatureState[name] = on and true or false
    if name == "AA" then
        Config.AA_Enabled = on
        if on then StartAA() else StopAA() end
    elseif name == "Aimbot" then
        Config.Aimbot_Enabled = on
        if on or Config.Aimbot_Silent then StartAimbot() else StopAimbot() end
    elseif name == "Silent" then
        Config.Aimbot_Silent = on
        if on or Config.Aimbot_Enabled then StartAimbot() else StopAimbot() end
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
        ApplyAmbient()
    elseif name == "Spinbot" then
        Config.Rage_Spinbot = on
        if on then
            Config.AA_Enabled = true
            FeatureState.AA = true
            StartAA()
        end
    elseif name == "AutoFire" then
        Config.Rage_AutoFire = on
    end
    AutoSave()
end

local function IsFeatureActive(name)
    local data = Config.Keys[name]
    if data and data.Mode == "Always" then
        return true
    end
    return FeatureState[name] == true
end

RunService.Heartbeat:Connect(function()
    for name, data in pairs(Config.Keys) do
        if data.Mode == "Always" then
            if not FeatureState[name] then
                ApplyFeature(name, true)
            end
        end
    end
end)

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
        if data.Mode == "Always" then
            -- always on via heartbeat
        elseif InputMatches(data.Key, input) then
            if data.Mode == "Toggle" then
                ApplyFeature(name, not FeatureState[name])
            else
                ApplyFeature(name, true)
            end
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

    for name, data in pairs(Config.Keys) do
        if data.Mode == "Hold" and InputMatches(data.Key, input) then
            ApplyFeature(name, false)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if Config.ESP_Enabled then UpdateESPDrawings() end
    if Config.ThirdPerson or Config.Freecam then ForceLocalVisible() end
end)

local charsFolder = GetCharactersFolder()
if charsFolder then
    charsFolder.ChildAdded:Connect(function()
        task.wait(0.2)
        RefreshChams()
    end)
end
Players.PlayerAdded:Connect(function()
    task.wait(0.3)
    RefreshChams()
end)

local Window
do
    local ok, win = pcall(function()
        return NeverLose:CreateWindow({
            Logo = NeverLose.GlobalLogo,
            Name = "Neverlose",
            Content = "Universal Hub",
            Size = (NeverLose.Scales and NeverLose.Scales.Default) or UDim2.fromOffset(640, 480),
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
end

pcall(function()
    local oldToggle = Window.ToggleInterface
    if typeof(oldToggle) == "function" then
        function Window:ToggleInterface(...)
            oldToggle(self, ...)
            UnlockMouse()
        end
    end
end)
UnlockMouse()

local function storeKey(name)
    return function(v)
        if type(v) == "string" and v ~= "" and v ~= "None" then
            Config.Keys[name].Key = v
        else
            Config.Keys[name].Key = "None"
        end
        AutoSave()
    end
end

local function bindFeature(label, name, defaultOn, flag)
    label:AddToggle({
        Default = defaultOn,
        Flag = flag,
        Callback = function(v)
            ApplyFeature(name, v)
        end
    })
    local kb = label:AddKeybind({
        Default = Config.Keys[name].Key ~= "None" and Config.Keys[name].Key or nil,
        Flag = flag .. "_Key",
        Callback = storeKey(name)
    })
    pcall(function()
        local opt = label:AddOption()
        opt:AddLabel("Key Mode"):AddDropdown({
            Default = Config.Keys[name].Mode,
            Values = {"Toggle", "Hold", "Always"},
            Flag = flag .. "_Mode",
            Callback = function(v)
                Config.Keys[name].Mode = v
                if v == "Always" then
                    ApplyFeature(name, true)
                end
                AutoSave()
            end
        })
    end)
    return kb
end

Window:AddTabLabel("COMBAT")
local Rage = Window:AddTab({ Icon = "crosshairs", Name = "Combat" })
local Visuals = Window:AddTab({ Icon = "eye", Name = "Visuals" })
local MoveTab = Window:AddTab({ Icon = "person", Name = "Movement" })
local WorldTab = Window:AddTab({ Icon = "globe", Name = "World" })

local AASec = Rage:AddSection({ Name = "ANTI-AIM", Position = "left" })
local AimSec = Rage:AddSection({ Name = "AIMBOT", Position = "right" })
local RageSec = Rage:AddSection({ Name = "RAGE", Position = "left" })
local ESPSec = Visuals:AddSection({ Name = "ESP", Position = "left" })
local ESPStyle = Visuals:AddSection({ Name = "ESP STYLE", Position = "right" })
local LocalSec = Visuals:AddSection({ Name = "LOCAL", Position = "right" })
local MoveSec = MoveTab:AddSection({ Name = "MOVEMENT", Position = "left" })
local CamSec = MoveTab:AddSection({ Name = "CAMERA", Position = "right" })
local EnvSec = WorldTab:AddSection({ Name = "ENVIRONMENT", Position = "left" })

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

local aimLabel = AimSec:AddLabel("Enabled")
bindFeature(aimLabel, "Aimbot", Config.Aimbot_Enabled, "Aimbot_Enabled")
AimSec:AddLabel("Aim Key"):AddKeybind({
    Default = Config.Aimbot_AimKey ~= "None" and Config.Aimbot_AimKey or "M2B",
    Flag = "Aimbot_AimKey",
    Callback = function(v)
        Config.Aimbot_AimKey = (type(v) == "string" and v ~= "" and v) or "M2B"
        AutoSave()
    end
})
local silentLabel = AimSec:AddLabel("Silent Aim")
bindFeature(silentLabel, "Silent", Config.Aimbot_Silent, "Aimbot_Silent")
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

local spinLabel = RageSec:AddLabel("Spinbot")
bindFeature(spinLabel, "Spinbot", Config.Rage_Spinbot, "Rage_Spinbot")
RageSec:AddLabel("Spinbot Speed"):AddSlider({
    Min = 5, Max = 50, Default = Config.Rage_SpinSpeed, Flag = "Rage_SpinSpeed",
    Callback = function(v) Config.Rage_SpinSpeed = v AutoSave() end
})
RageSec:AddLabel("No Rotate"):AddToggle({
    Default = Config.Rage_NoRotate, Flag = "Rage_NoRotate",
    Callback = function(v) Config.Rage_NoRotate = v AutoSave() end
})
local afLabel = RageSec:AddLabel("Auto Fire")
bindFeature(afLabel, "AutoFire", Config.Rage_AutoFire, "Rage_AutoFire")
RageSec:AddLabel("Rapid Fire"):AddToggle({
    Default = Config.Rage_RapidFire, Flag = "Rage_RapidFire",
    Callback = function(v)
        Config.Rage_RapidFire = v
        if v then StartRapidFire() else StopRapidFire() end
        AutoSave()
    end
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
ESPSec:AddLabel("Name"):AddToggle({
    Default = Config.ESP_Name, Flag = "ESP_Name",
    Callback = function(v) Config.ESP_Name = v AutoSave() end
})
ESPSec:AddLabel("Distance"):AddToggle({
    Default = Config.ESP_Distance, Flag = "ESP_Distance",
    Callback = function(v) Config.ESP_Distance = v AutoSave() end
})
ESPSec:AddLabel("Healthbar"):AddToggle({
    Default = Config.ESP_Healthbar, Flag = "ESP_Healthbar",
    Callback = function(v) Config.ESP_Healthbar = v AutoSave() end
})
ESPSec:AddLabel("Tracers"):AddToggle({
    Default = Config.ESP_Tracers, Flag = "ESP_Tracers",
    Callback = function(v) Config.ESP_Tracers = v AutoSave() end
})
ESPSec:AddLabel("Ball"):AddToggle({
    Default = Config.ESP_Ball, Flag = "ESP_Ball",
    Callback = function(v) Config.ESP_Ball = v AutoSave() end
})
ESPSec:AddLabel("Ball Size"):AddSlider({
    Min = 2, Max = 20, Default = Config.ESP_BallSize, Flag = "ESP_BallSize",
    Callback = function(v) Config.ESP_BallSize = v AutoSave() end
})
ESPSec:AddLabel("Max Distance"):AddSlider({
    Min = 50, Max = 100000, Default = Config.ESP_MaxDistance, Flag = "ESP_MaxDistance",
    Callback = function(v) Config.ESP_MaxDistance = v AutoSave() end
})

ESPStyle:AddLabel("Name Size"):AddSlider({
    Min = 10, Max = 28, Default = Config.ESP_NameSize, Flag = "ESP_NameSize",
    Callback = function(v) Config.ESP_NameSize = v AutoSave() end
})
ESPStyle:AddLabel("Name Position"):AddDropdown({
    Default = Config.ESP_NamePos, Values = {"Up", "Bottom", "Left", "Right"}, Flag = "ESP_NamePos",
    Callback = function(v) Config.ESP_NamePos = v AutoSave() end
})
ESPStyle:AddLabel("Dist Size"):AddSlider({
    Min = 8, Max = 24, Default = Config.ESP_DistSize, Flag = "ESP_DistSize",
    Callback = function(v) Config.ESP_DistSize = v AutoSave() end
})
ESPStyle:AddLabel("Dist Position"):AddDropdown({
    Default = Config.ESP_DistPos, Values = {"Up", "Bottom", "Left", "Right"}, Flag = "ESP_DistPos",
    Callback = function(v) Config.ESP_DistPos = v AutoSave() end
})
ESPStyle:AddLabel("Health Position"):AddDropdown({
    Default = Config.ESP_HealthPos, Values = {"Left", "Right", "Up", "Bottom"}, Flag = "ESP_HealthPos",
    Callback = function(v) Config.ESP_HealthPos = v AutoSave() end
})
ESPStyle:AddLabel("Health Width"):AddSlider({
    Min = 2, Max = 10, Default = Config.ESP_HealthWidth, Flag = "ESP_HealthWidth",
    Callback = function(v) Config.ESP_HealthWidth = v AutoSave() end
})
ESPStyle:AddLabel("Health Height"):AddSlider({
    Min = 20, Max = 80, Default = Config.ESP_HealthHeight, Flag = "ESP_HealthHeight",
    Callback = function(v) Config.ESP_HealthHeight = v AutoSave() end
})
pcall(function()
    ESPStyle:AddLabel("Name Color"):AddColorPicker({
        Default = ToColor3(Config.ESP_NameColor), Flag = "ESP_NameColor",
        Callback = function(c) Config.ESP_NameColor = FromColor3(c) AutoSave() end
    })
    ESPStyle:AddLabel("Dist Color"):AddColorPicker({
        Default = ToColor3(Config.ESP_DistColor), Flag = "ESP_DistColor",
        Callback = function(c) Config.ESP_DistColor = FromColor3(c) AutoSave() end
    })
    ESPStyle:AddLabel("Enemy Fill"):AddColorPicker({
        Default = ToColor3(Config.ESP_FillColor), Flag = "ESP_FillColor",
        Callback = function(c) Config.ESP_FillColor = FromColor3(c) RefreshChams() AutoSave() end
    })
    ESPStyle:AddLabel("Team Fill"):AddColorPicker({
        Default = ToColor3(Config.ESP_TeamFillColor), Flag = "ESP_TeamFillColor",
        Callback = function(c) Config.ESP_TeamFillColor = FromColor3(c) RefreshChams() AutoSave() end
    })
end)

local lcLabel = LocalSec:AddLabel("Local Chams")
bindFeature(lcLabel, "LocalChams", Config.LocalChams, "LocalChams")
pcall(function()
    LocalSec:AddLabel("Local Fill"):AddColorPicker({
        Default = ToColor3(Config.LocalChams_Fill), Flag = "LocalChams_Fill",
        Callback = function(c) Config.LocalChams_Fill = FromColor3(c) RefreshChams() AutoSave() end
    })
end)

local jumpLabel = MoveSec:AddLabel("Auto Jump")
bindFeature(jumpLabel, "Bhop", Config.AutoJump, "AutoJump")
MoveSec:AddLabel("WalkSpeed Loop"):AddSlider({
    Min = 0, Max = 100, Default = Config.LoopWalkSpeed, Flag = "LoopWalkSpeed",
    Callback = function(v)
        Config.LoopWalkSpeed = v
        if v <= 0 then
            if speedLoopConn then speedLoopConn:Disconnect() speedLoopConn = nil end
        else
            StartWalkSpeedLoop()
        end
        AutoSave()
    end
})
MoveSec:AddLabel("JumpPower Loop"):AddSlider({
    Min = 0, Max = 200, Default = Config.LoopJumpPower, Flag = "LoopJumpPower",
    Callback = function(v)
        Config.LoopJumpPower = v
        if v <= 0 then
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
    EnvSec:AddLabel("Ambient"):AddColorPicker({
        Default = ToColor3(Config.AmbientColor), Flag = "AmbientColor",
        Callback = function(c) Config.AmbientColor = FromColor3(c) ApplyAmbient() AutoSave() end
    })
    EnvSec:AddLabel("Outdoor"):AddColorPicker({
        Default = ToColor3(Config.OutdoorAmbient), Flag = "OutdoorAmbient",
        Callback = function(c) Config.OutdoorAmbient = FromColor3(c) ApplyAmbient() AutoSave() end
    })
end)

FeatureState.AA = Config.AA_Enabled
FeatureState.Aimbot = Config.Aimbot_Enabled
FeatureState.Silent = Config.Aimbot_Silent
FeatureState.ESP = Config.ESP_Enabled
FeatureState.Bhop = Config.AutoJump
FeatureState.ThirdPerson = Config.ThirdPerson
FeatureState.LoopFOV = Config.LoopFOV
FeatureState.LocalChams = Config.LocalChams
FeatureState.Freecam = Config.Freecam
FeatureState.Ambient = Config.AmbientEnabled
FeatureState.Spinbot = Config.Rage_Spinbot
FeatureState.AutoFire = Config.Rage_AutoFire

if Config.AA_Enabled or Config.Rage_Spinbot then StartAA() end
if Config.Aimbot_Enabled or Config.Aimbot_Silent then StartAimbot() end
if Config.AutoJump then StartAutoJump() end
if Config.LoopWalkSpeed and Config.LoopWalkSpeed > 0 then StartWalkSpeedLoop() end
if Config.LoopJumpPower and Config.LoopJumpPower > 0 then StartJumpPowerLoop() end
if Config.ThirdPerson then StartThirdPerson() end
if Config.LoopFOV then StartLoopFOV() end
if Config.Freecam then StartFreecam() end
if Config.AmbientEnabled then ApplyAmbient() end
if Config.Rage_RapidFire then StartRapidFire() end
RefreshChams()
