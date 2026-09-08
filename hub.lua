--[[
    Prismora Hub
    UI: GhosterXS/Neverlose-Ui-Roblox source.luau
    Chams on Characters model + Player.Character
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
        warn("[Prismora] Failed to load UI:", res)
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

    Aimbot_Enabled = false,
    Aimbot_TeamCheck = true,
    Aimbot_AliveCheck = true,
    Aimbot_AutoWall = true,
    Aimbot_FOV = 120,
    Aimbot_Smooth = 3,
    Aimbot_Part = "Head",
    Aimbot_ShowFOV = true,

    ESP_Enabled = false,
    ESP_TeamCheck = true,
    ESP_TeamChams = true,
    ESP_Chams = true,
    ESP_Highlight = true,
    ESP_Ball = true,
    ESP_BallSize = 6,
    ESP_BallColor = {255, 80, 80},
    AA_DisableWhenSitting = true,
    ESP_Name = true,
    ESP_Distance = true,
    ESP_Healthbar = true,
    ESP_Tracers = true,
    ESP_NameSize = 14,
    ESP_FillTransparency = 0.55,
    ESP_OutlineTransparency = 0,
    ESP_MaxDistance = 100000,
    ESP_FillColor = {255, 50, 50},
    ESP_OutlineColor = {255, 255, 255},
    ESP_NameColor = {255, 255, 255},
    ESP_TracerColor = {255, 80, 80},
    ESP_TeamFillColor = {50, 120, 255},
    ESP_TeamOutlineColor = {180, 210, 255},

    AutoBhop = false,
    LoopWalkSpeed = 0,
    LoopJumpPower = 0,

    ThirdPerson = false,
    ThirdPerson_Distance = 8,

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

local ConfigFolder, ConfigFile = "AntiAimHub", "config.json"

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
    local list = {}
    local seen = {}
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
    local model = GetLocalModel()
    if not model then return end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.LocalTransparencyModifier = 0
            end)
        end
    end
end

do
    local gui = Instance.new("ScreenGui")
    gui.Name = "NLIntro"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 9999
    gui.ResetOnSpawn = false
    pcall(function()
        gui.Parent = gethui and gethui() or CoreGui
    end)
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
    title.Text = "Prismora"
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
    sub.Text = "loading"
    sub.TextColor3 = Color3.fromRGB(160, 170, 190)
    sub.TextSize = 14
    sub.TextTransparency = 1
    sub.Parent = bg

    TweenService:Create(title, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    }):Play()
    TweenService:Create(sub, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0.2
    }):Play()

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
        TweenService:Create(line, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(2, 70),
            Position = UDim2.new(0.5, math.cos(angle) * dist, 0.5, math.sin(angle) * dist),
            BackgroundTransparency = 1,
            Rotation = math.deg(angle) + 90
        }):Play()
    end

    task.wait(1.35)
    TweenService:Create(title, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
    TweenService:Create(sub, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
    TweenService:Create(bg, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
    task.wait(0.45)
    gui:Destroy()
end

pcall(function()
    local Notification = NeverLose:CreateNotification()
    Notification.new({ Title = "Prismora", Content = "Loaded", Duration = 3 })
end)

local aaConn, spinAngle, jitterSide = nil, 0, 1

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
    aaConn = RunService.RenderStepped:Connect(function()
        if not Config.AA_Enabled or isShooting() then return end
        local hrp, hum = getHRP()
        if not hrp or not hum then return end
        if Config.AA_DisableWhenSitting and (hum.Sit or hum.SeatPart) then
            hum.AutoRotate = true
            return
        end
        if Config.AA_Jitter then
            hum.AutoRotate = false
            jitterSide = -jitterSide
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(jitterSide * Config.AA_JitterAmount), 0)
            return
        end
        if Config.AA_Yaw == "None" then
            hum.AutoRotate = true
            return
        end
        hum.AutoRotate = false
        if Config.AA_Yaw == "Spin" then
            spinAngle = (spinAngle + Config.AA_SpinSpeed) % 360
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
        elseif Config.AA_Yaw == "Back" then
            local look = camera.CFrame.LookVector
            local flat = Vector3.new(look.X, 0, look.Z)
            if flat.Magnitude > 0.01 then
                hrp.CFrame = CFrame.new(hrp.Position, hrp.Position - flat.Unit)
            end
        end
    end)
end

local function StopAA()
    if aaConn then aaConn:Disconnect() aaConn = nil end
    local _, hum = getHRP()
    if hum then hum.AutoRotate = true end
end

local bhopConn, lastSpace = nil, 0

local function PressSpace()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
    end)
    task.delay(0.03, function()
        pcall(function()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end)
end

local function StartBhop()
    if bhopConn then bhopConn:Disconnect() end
    bhopConn = RunService.Heartbeat:Connect(function()
        if not Config.AutoBhop then return end
        if not IsLocalAlive() then return end
        if (tick() - lastSpace) < 0.18 then return end
        lastSpace = tick()
        PressSpace()
    end)
end

local function StopBhop()
    if bhopConn then bhopConn:Disconnect() bhopConn = nil end
end

local speedConn, jumpConn = nil, nil

local function StartWalkSpeedLoop()
    if speedConn then speedConn:Disconnect() end
    if Config.LoopWalkSpeed <= 0 then return end
    speedConn = RunService.Heartbeat:Connect(function()
        if Config.LoopWalkSpeed <= 0 then
            if speedConn then speedConn:Disconnect() speedConn = nil end
            return
        end
        local model = GetLocalModel()
        local hum = model and model:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Config.LoopWalkSpeed end
    end)
end

local function StartJumpPowerLoop()
    if jumpConn then jumpConn:Disconnect() end
    if Config.LoopJumpPower <= 0 then return end
    jumpConn = RunService.Heartbeat:Connect(function()
        if Config.LoopJumpPower <= 0 then
            if jumpConn then jumpConn:Disconnect() jumpConn = nil end
            return
        end
        local model = GetLocalModel()
        local hum = model and model:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.JumpPower = Config.LoopJumpPower
            pcall(function() hum.JumpHeight = Config.LoopJumpPower / 5 end)
        end
    end)
end

local aimConn, fovCircle = nil, nil

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
    local folder = GetCharactersFolder()

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
            local localModel = GetLocalModel()
            params.FilterDescendantsInstances = localModel and {localModel} or {}
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
    local smooth = math.max(Config.Aimbot_Smooth, 1)
    if moveMouse then
        moveMouse(dx / smooth, dy / smooth)
    else
        pcall(function()
            VirtualInputManager:SendMouseMoveEvent(
                mousePos.X + dx / smooth,
                mousePos.Y + dy / smooth,
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
            fovCircle.Visible = Config.Aimbot_ShowFOV and Config.Aimbot_Enabled
        end
        if not Config.Aimbot_Enabled then return end
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
        local target = GetClosest()
        if target then
            MoveMouseToTarget(target)
        end
    end)
end

local function StopAimbot()
    if aimConn then aimConn:Disconnect() aimConn = nil end
    if fovCircle then fovCircle.Visible = false end
end

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "CharsESP_" .. tostring(math.random(10000, 99999))
pcall(function()
    ESPFolder.Parent = gethui and gethui() or CoreGui
end)
if not ESPFolder.Parent then
    ESPFolder.Parent = player:WaitForChild("PlayerGui")
end

local highlights, drawings, localHighlight = {}, {}, nil

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
            if d.Name then d.Name:Remove() end
            if d.Dist then d.Dist:Remove() end
            if d.Health then d.Health:Remove() end
            if d.HealthBg then d.HealthBg:Remove() end
            if d.Tracer then d.Tracer:Remove() end
        end)
    end
    drawings = {}
end

local function RemoveModelESP(model)
    if highlights[model] then pcall(function() highlights[model]:Destroy() end) highlights[model] = nil end
    if drawings[model] then
        pcall(function()
            if drawings[model].Name then drawings[model].Name:Remove() end
            if drawings[model].Dist then drawings[model].Dist:Remove() end
            if drawings[model].Health then drawings[model].Health:Remove() end
            if drawings[model].HealthBg then drawings[model].HealthBg:Remove() end
            if drawings[model].Tracer then drawings[model].Tracer:Remove() end
        end)
        drawings[model] = nil
    end
end

local localHighlights = {}

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
    local seen = {}

    if Config.LocalChams then
        local model = GetLocalModel()
        local char = player.Character
        local fill = ToColor3(Config.LocalChams_Fill)
        local outline = ToColor3(Config.LocalChams_Outline)
        local ft = Config.LocalChams_FillTransparency
        local ot = Config.LocalChams_OutlineTransparency
        if model then
            EnsureHL(localHighlights, "lm", model, fill, outline, ft, ot)
            seen["lm"] = true
        end
        if char and char ~= model then
            EnsureHL(localHighlights, "lc", char, fill, outline, ft, ot)
            seen["lc"] = true
        end
    end
    for k, h in pairs(localHighlights) do
        if not Config.LocalChams or not seen[k] then
            pcall(function() h:Destroy() end)
            localHighlights[k] = nil
        end
    end

    local seenP = {}
    if Config.ESP_Enabled and (Config.ESP_Chams or Config.ESP_Highlight) then
        for _, entry in ipairs(CollectTargets()) do
            local plr = entry.Plr
            local isTeam = IsTeammate(plr)
            if isTeam and Config.ESP_TeamCheck and not Config.ESP_TeamChams then
                continue
            end
            local fill = isTeam and teamFill or enemyFill
            local outline = isTeam and teamOutline or enemyOutline
            local ft = Config.ESP_FillTransparency
            local ot = Config.ESP_OutlineTransparency
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

local function UpdateESPDrawings()
    if not Config.ESP_Enabled then
        for _, d in pairs(drawings) do
            if d.Name then d.Name.Visible = false end
            if d.Dist then d.Dist.Visible = false end
            if d.Health then d.Health.Visible = false end
            if d.HealthBg then d.HealthBg.Visible = false end
            if d.Tracer then d.Tracer.Visible = false end
        end
        return
    end

    local nameColor = ToColor3(Config.ESP_NameColor)
    local tracerColor = ToColor3(Config.ESP_TracerColor)
    local maxDist = Config.ESP_MaxDistance
    local seen = {}

    for _, entry in ipairs(CollectTargets()) do
        local plr = entry.Plr
        if Config.ESP_TeamCheck and IsTeammate(plr) then continue end
        local model = entry.Model or entry.Char
        if not model then continue end

        local hrp = model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChild("Torso")
            or model:FindFirstChild("UpperTorso")
            or model:FindFirstChildWhichIsA("BasePart")
        local head = model:FindFirstChild("Head") or hrp
        local hum = model:FindFirstChildOfClass("Humanoid")
        if not hrp then continue end
        local dist = (hrp.Position - camera.CFrame.Position).Magnitude
        if dist > maxDist then continue end
        seen[model] = true

        if not drawings[model] then
            drawings[model] = {
                Name = CreateDrawing("Text"),
                Dist = CreateDrawing("Text"),
                HealthBg = CreateDrawing("Square"),
                Health = CreateDrawing("Square"),
                Tracer = CreateDrawing("Line"),
            }
        end

        local d = drawings[model]
        local screen, onScreen = camera:WorldToViewportPoint(hrp.Position)
        local headScreen = camera:WorldToViewportPoint((head and head.Position or hrp.Position) + Vector3.new(0, 1, 0))
        local screenPos = Vector2.new(screen.X, screen.Y)

        if onScreen and screen.Z > 0 then
            if d.Name then
                d.Name.Text = plr.DisplayName or plr.Name
                d.Name.Size = Config.ESP_NameSize
                d.Name.Color = nameColor
                d.Name.Center = true
                d.Name.Outline = true
                d.Name.OutlineColor = Color3.new(0, 0, 0)
                d.Name.Position = Vector2.new(screenPos.X, screenPos.Y - 28)
                d.Name.Visible = Config.ESP_Name
            end
            if d.Dist then
                d.Dist.Text = math.floor(dist) .. "m"
                d.Dist.Size = Config.ESP_NameSize - 2
                d.Dist.Color = Color3.fromRGB(220, 220, 220)
                d.Dist.Center = true
                d.Dist.Outline = true
                d.Dist.OutlineColor = Color3.new(0, 0, 0)
                d.Dist.Position = Vector2.new(screenPos.X, screenPos.Y - 12)
                d.Dist.Visible = Config.ESP_Distance
            end
            if d.HealthBg and d.Health and hum and headScreen.Z > 0 then
                local hp = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                local barH, barW = 44, 4
                local x, y = headScreen.X - 34, headScreen.Y - 14
                d.HealthBg.Size = Vector2.new(barW, barH)
                d.HealthBg.Position = Vector2.new(x, y)
                d.HealthBg.Color = Color3.fromRGB(15, 15, 15)
                d.HealthBg.Filled = true
                d.HealthBg.Visible = Config.ESP_Healthbar
                d.Health.Size = Vector2.new(barW, barH * hp)
                d.Health.Position = Vector2.new(x, y + barH * (1 - hp))
                d.Health.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 40)
                d.Health.Filled = true
                d.Health.Visible = Config.ESP_Healthbar
            end
            if d.Tracer then
                d.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                d.Tracer.To = screenPos
                d.Tracer.Color = tracerColor
                d.Tracer.Thickness = 1.3
                d.Tracer.Visible = Config.ESP_Tracers
            end
        else
            if d.Name then d.Name.Visible = false end
            if d.Dist then d.Dist.Visible = false end
            if d.Health then d.Health.Visible = false end
            if d.HealthBg then d.HealthBg.Visible = false end
            if d.Tracer then d.Tracer.Visible = false end
        end
    end

    for model in pairs(drawings) do
        if not seen[model] then RemoveModelESP(model) end
    end
end

local thirdConn = nil
local function StartThirdPerson()
    if thirdConn then thirdConn:Disconnect() end
    thirdConn = RunService.RenderStepped:Connect(function()
        if not Config.ThirdPerson or Config.Freecam then return end
        local model = GetLocalModel()
        local hrp = model and (model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso"))
        if not hrp then return end
        ForceLocalVisible()
        local dist = Config.ThirdPerson_Distance
        local look = camera.CFrame.LookVector
        local pos = hrp.Position - look * dist + Vector3.new(0, 1.5, 0)
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.new(pos, hrp.Position + Vector3.new(0, 1, 0))
    end)
end

local function StopThirdPerson()
    if thirdConn then thirdConn:Disconnect() thirdConn = nil end
    if not Config.Freecam then
        camera.CameraType = Enum.CameraType.Custom
        local model = GetLocalModel()
        local hum = model and model:FindFirstChildOfClass("Humanoid")
        if hum then camera.CameraSubject = hum end
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
local keys = {}

local function StartFreecam()
    if freecamConn then return end
    StopThirdPerson()
    camera.CameraType = Enum.CameraType.Scriptable
    local look = camera.CFrame.LookVector
    freecamYaw = math.atan2(-look.X, -look.Z)
    freecamPitch = math.asin(math.clamp(look.Y, -1, 1))
    freecamConn = RunService.RenderStepped:Connect(function(dt)
        if not Config.Freecam then return end
        local delta = UserInputService:GetMouseDelta()
        freecamYaw = freecamYaw - delta.X * 0.004
        freecamPitch = math.clamp(freecamPitch - delta.Y * 0.004, math.rad(-89), math.rad(89))
        local rot = CFrame.Angles(0, freecamYaw, 0) * CFrame.Angles(freecamPitch, 0, 0)
        local move = Vector3.zero
        local speed = Config.Freecam_Speed * (keys.Shift and 3 or 1) * 60 * dt
        if keys.W then move = move + rot.LookVector end
        if keys.S then move = move - rot.LookVector end
        if keys.A then move = move - rot.RightVector end
        if keys.D then move = move + rot.RightVector end
        if keys.E then move = move + Vector3.yAxis end
        if keys.Q then move = move - Vector3.yAxis end
        if move.Magnitude > 0 then move = move.Unit * speed end
        camera.CFrame = CFrame.new(camera.CFrame.Position + move) * rot
    end)
end

local function StopFreecam()
    if freecamConn then freecamConn:Disconnect() freecamConn = nil end
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

local FeatureState = {
    AA = false,
    Aimbot = false,
    ESP = false,
    Bhop = false,
    ThirdPerson = false,
    LoopFOV = false,
    LocalChams = false,
    Freecam = false,
    Ambient = false,
}

local function ApplyFeature(name, on)
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
        Config.AutoBhop = on
        if on then StartBhop() else StopBhop() end
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
    end
    AutoSave()
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.W then keys.W = true end
    if input.KeyCode == Enum.KeyCode.A then keys.A = true end
    if input.KeyCode == Enum.KeyCode.S then keys.S = true end
    if input.KeyCode == Enum.KeyCode.D then keys.D = true end
    if input.KeyCode == Enum.KeyCode.E then keys.E = true end
    if input.KeyCode == Enum.KeyCode.Q then keys.Q = true end
    if input.KeyCode == Enum.KeyCode.LeftShift then keys.Shift = true end

    if gpe then return end
    for name, data in pairs(Config.Keys) do
        if InputMatches(data.Key, input) then
            if data.Mode == "Toggle" then
                ApplyFeature(name, not FeatureState[name])
            else
                ApplyFeature(name, true)
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then keys.W = false end
    if input.KeyCode == Enum.KeyCode.A then keys.A = false end
    if input.KeyCode == Enum.KeyCode.S then keys.S = false end
    if input.KeyCode == Enum.KeyCode.D then keys.D = false end
    if input.KeyCode == Enum.KeyCode.E then keys.E = false end
    if input.KeyCode == Enum.KeyCode.Q then keys.Q = false end
    if input.KeyCode == Enum.KeyCode.LeftShift then keys.Shift = false end

    for name, data in pairs(Config.Keys) do
        if data.Mode == "Hold" and InputMatches(data.Key, input) then
            ApplyFeature(name, false)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if Config.ESP_Enabled then UpdateESPDrawings() end
    if Config.ThirdPerson then ForceLocalVisible() end
end)

local charsFolder = GetCharactersFolder()
if charsFolder then
    charsFolder.ChildAdded:Connect(function()
        task.wait(0.2)
        RefreshChams()
    end)
    charsFolder.ChildRemoved:Connect(function(child)
        RemoveModelESP(child)
    end)
end

local Window
do
    local ok, win = pcall(function()
        return NeverLose:CreateWindow({
            Logo = NeverLose.GlobalLogo,
            Name = "Prismora",
            Content = "AA Aimbot ESP",
            Size = (NeverLose.Scales and NeverLose.Scales.Default) or UDim2.fromOffset(640, 480),
            ConfigFolder = "PrismoraNL",
            Enable3DRenderer = false,
            Keybind = "Insert"
        })
    end)
    if not ok or not win then
        warn("[Prismora] CreateWindow failed:", win)
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

local function addKeyMode(section, name)
    section:AddLabel("Key Mode"):AddDropdown({
        Default = Config.Keys[name].Mode,
        Values = {"Toggle", "Hold"},
        Flag = name .. "_Mode",
        Callback = function(v)
            Config.Keys[name].Mode = v
            AutoSave()
        end
    })
end

Window:AddTabLabel("COMBAT")
local Rage = Window:AddTab({ Icon = "crosshairs", Name = "Combat" })
local Visuals = Window:AddTab({ Icon = "eye", Name = "Visuals" })
local MoveTab = Window:AddTab({ Icon = "person", Name = "Movement" })
local WorldTab = Window:AddTab({ Icon = "globe", Name = "World" })

local AASec = Rage:AddSection({ Name = "ANTI-AIM", Position = "left" })
local AimSec = Rage:AddSection({ Name = "AIMBOT", Position = "right" })
local ESPSec = Visuals:AddSection({ Name = "ESP", Position = "left" })
local LocalSec = Visuals:AddSection({ Name = "LOCAL", Position = "right" })
local MoveSec = MoveTab:AddSection({ Name = "MOVEMENT", Position = "left" })
local CamSec = MoveTab:AddSection({ Name = "CAMERA", Position = "right" })
local EnvSec = WorldTab:AddSection({ Name = "ENVIRONMENT", Position = "left" })

local aaLabel = AASec:AddLabel("Enabled")
aaLabel:AddToggle({
    Default = Config.AA_Enabled, Flag = "AA_Enabled",
    Callback = function(v) ApplyFeature("AA", v) end
})
aaLabel:AddKeybind({
    Default = Config.Keys.AA.Key ~= "None" and Config.Keys.AA.Key or nil,
    Flag = "AA_Key",
    Callback = storeKey("AA")
})
addKeyMode(AASec, "AA")
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
    Callback = function(v) Config.AA_Jitter = v AutoSave() end
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
aimLabel:AddToggle({
    Default = Config.Aimbot_Enabled, Flag = "Aimbot_Enabled",
    Callback = function(v) ApplyFeature("Aimbot", v) end
})
aimLabel:AddKeybind({
    Default = Config.Keys.Aimbot.Key ~= "None" and Config.Keys.Aimbot.Key or nil,
    Flag = "Aimbot_Key",
    Callback = storeKey("Aimbot")
})
addKeyMode(AimSec, "Aimbot")
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
    Min = 1, Max = 20, Default = Config.Aimbot_Smooth, Flag = "Aimbot_Smooth",
    Callback = function(v) Config.Aimbot_Smooth = v AutoSave() end
})
AimSec:AddLabel("Aim Part"):AddDropdown({
    Default = Config.Aimbot_Part, Values = {"Head", "HumanoidRootPart", "UpperTorso"}, Flag = "Aimbot_Part",
    Callback = function(v) Config.Aimbot_Part = v AutoSave() end
})

local espLabel = ESPSec:AddLabel("Enabled")
espLabel:AddToggle({
    Default = Config.ESP_Enabled, Flag = "ESP_Enabled",
    Callback = function(v) ApplyFeature("ESP", v) end
})
espLabel:AddKeybind({
    Default = Config.Keys.ESP.Key ~= "None" and Config.Keys.ESP.Key or nil,
    Flag = "ESP_Key",
    Callback = storeKey("ESP")
})
addKeyMode(ESPSec, "ESP")
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
ESPSec:AddLabel("Ball (Long Range)"):AddToggle({
    Default = Config.ESP_Ball, Flag = "ESP_Ball",
    Callback = function(v) Config.ESP_Ball = v AutoSave() end
})
ESPSec:AddLabel("Ball Size"):AddSlider({
    Min = 2, Max = 20, Default = Config.ESP_BallSize or 6, Flag = "ESP_BallSize",
    Callback = function(v) Config.ESP_BallSize = v AutoSave() end
})
ESPSec:AddLabel("Max Distance"):AddSlider({
    Min = 50, Max = 100000, Default = Config.ESP_MaxDistance, Flag = "ESP_MaxDistance",
    Callback = function(v) Config.ESP_MaxDistance = v AutoSave() end
})
pcall(function()
    ESPSec:AddLabel("Enemy Fill"):AddColorPicker({
        Default = ToColor3(Config.ESP_FillColor), Flag = "ESP_FillColor",
        Callback = function(c) Config.ESP_FillColor = FromColor3(c) RefreshChams() AutoSave() end
    })
    ESPSec:AddLabel("Team Fill"):AddColorPicker({
        Default = ToColor3(Config.ESP_TeamFillColor), Flag = "ESP_TeamFillColor",
        Callback = function(c) Config.ESP_TeamFillColor = FromColor3(c) RefreshChams() AutoSave() end
    })
end)

local lcLabel = LocalSec:AddLabel("Local Chams")
lcLabel:AddToggle({
    Default = Config.LocalChams, Flag = "LocalChams",
    Callback = function(v) ApplyFeature("LocalChams", v) end
})
lcLabel:AddKeybind({
    Default = Config.Keys.LocalChams.Key ~= "None" and Config.Keys.LocalChams.Key or nil,
    Flag = "LocalChams_Key",
    Callback = storeKey("LocalChams")
})
addKeyMode(LocalSec, "LocalChams")
pcall(function()
    LocalSec:AddLabel("Local Fill"):AddColorPicker({
        Default = ToColor3(Config.LocalChams_Fill), Flag = "LocalChams_Fill",
        Callback = function(c) Config.LocalChams_Fill = FromColor3(c) RefreshChams() AutoSave() end
    })
end)

local bhopLabel = MoveSec:AddLabel("Auto Bhop")
bhopLabel:AddToggle({
    Default = Config.AutoBhop, Flag = "AutoBhop",
    Callback = function(v) ApplyFeature("Bhop", v) end
})
bhopLabel:AddKeybind({
    Default = Config.Keys.Bhop.Key ~= "None" and Config.Keys.Bhop.Key or nil,
    Flag = "Bhop_Key",
    Callback = storeKey("Bhop")
})
addKeyMode(MoveSec, "Bhop")
MoveSec:AddLabel("WalkSpeed Loop"):AddSlider({
    Min = 0, Max = 100, Default = Config.LoopWalkSpeed, Flag = "LoopWalkSpeed",
    Callback = function(v)
        Config.LoopWalkSpeed = v
        if v > 0 then StartWalkSpeedLoop()
        elseif speedConn then speedConn:Disconnect() speedConn = nil end
        AutoSave()
    end
})
MoveSec:AddLabel("JumpPower Loop"):AddSlider({
    Min = 0, Max = 200, Default = Config.LoopJumpPower, Flag = "LoopJumpPower",
    Callback = function(v)
        Config.LoopJumpPower = v
        if v > 0 then StartJumpPowerLoop()
        elseif jumpConn then jumpConn:Disconnect() jumpConn = nil end
        AutoSave()
    end
})

local tpLabel = CamSec:AddLabel("Third Person")
tpLabel:AddToggle({
    Default = Config.ThirdPerson, Flag = "ThirdPerson",
    Callback = function(v) ApplyFeature("ThirdPerson", v) end
})
tpLabel:AddKeybind({
    Default = Config.Keys.ThirdPerson.Key ~= "None" and Config.Keys.ThirdPerson.Key or nil,
    Flag = "ThirdPerson_Key",
    Callback = storeKey("ThirdPerson")
})
addKeyMode(CamSec, "ThirdPerson")
CamSec:AddLabel("TP Distance"):AddSlider({
    Min = 2, Max = 30, Default = Config.ThirdPerson_Distance, Flag = "TP_Distance",
    Callback = function(v) Config.ThirdPerson_Distance = v AutoSave() end
})

local fovLabel = CamSec:AddLabel("Loop FOV")
fovLabel:AddToggle({
    Default = Config.LoopFOV, Flag = "LoopFOV",
    Callback = function(v) ApplyFeature("LoopFOV", v) end
})
fovLabel:AddKeybind({
    Default = Config.Keys.LoopFOV.Key ~= "None" and Config.Keys.LoopFOV.Key or nil,
    Flag = "LoopFOV_Key",
    Callback = storeKey("LoopFOV")
})
CamSec:AddLabel("FOV Value"):AddSlider({
    Min = 30, Max = 120, Default = Config.LoopFOV_Value, Flag = "LoopFOV_Value",
    Callback = function(v) Config.LoopFOV_Value = v AutoSave() end
})

local fcLabel = CamSec:AddLabel("Freecam")
fcLabel:AddToggle({
    Default = Config.Freecam, Flag = "Freecam",
    Callback = function(v) ApplyFeature("Freecam", v) end
})
fcLabel:AddKeybind({
    Default = Config.Keys.Freecam.Key ~= "None" and Config.Keys.Freecam.Key or nil,
    Flag = "Freecam_Key",
    Callback = storeKey("Freecam")
})
addKeyMode(CamSec, "Freecam")
CamSec:AddLabel("Freecam Speed"):AddSlider({
    Min = 1, Max = 10, Default = Config.Freecam_Speed, Flag = "Freecam_Speed",
    Callback = function(v) Config.Freecam_Speed = v AutoSave() end
})

local ambLabel = EnvSec:AddLabel("Custom Ambient")
ambLabel:AddToggle({
    Default = Config.AmbientEnabled, Flag = "AmbientEnabled",
    Callback = function(v) ApplyFeature("Ambient", v) end
})
ambLabel:AddKeybind({
    Default = Config.Keys.Ambient.Key ~= "None" and Config.Keys.Ambient.Key or nil,
    Flag = "Ambient_Key",
    Callback = storeKey("Ambient")
})
addKeyMode(EnvSec, "Ambient")
pcall(function()
    EnvSec:AddLabel("Ambient"):AddColorPicker({
        Default = ToColor3(Config.AmbientColor), Flag = "AmbientColor",
        Callback = function(c) Config.AmbientColor = FromColor3(c) ApplyAmbient() AutoSave() end
    })
    EnvSec:AddLabel("Outdoor"):AddColorPicker({
        Default = ToColor3(Config.OutdoorAmbient), Flag = "OutdoorAmbient",
        Callback = function(c) Config.OutdoorAmbient = FromColor3(c) ApplyAmbient() AutoSave() end
    })
    EnvSec:AddLabel("Shift Top"):AddColorPicker({
        Default = ToColor3(Config.ColorShift_Top), Flag = "ColorShift_Top",
        Callback = function(c) Config.ColorShift_Top = FromColor3(c) ApplyAmbient() AutoSave() end
    })
    EnvSec:AddLabel("Shift Bottom"):AddColorPicker({
        Default = ToColor3(Config.ColorShift_Bottom), Flag = "ColorShift_Bottom",
        Callback = function(c) Config.ColorShift_Bottom = FromColor3(c) ApplyAmbient() AutoSave() end
    })
end)

FeatureState.AA = Config.AA_Enabled
FeatureState.Aimbot = Config.Aimbot_Enabled
FeatureState.ESP = Config.ESP_Enabled
FeatureState.Bhop = Config.AutoBhop
FeatureState.ThirdPerson = Config.ThirdPerson
FeatureState.LoopFOV = Config.LoopFOV
FeatureState.LocalChams = Config.LocalChams
FeatureState.Freecam = Config.Freecam
FeatureState.Ambient = Config.AmbientEnabled

if Config.AA_Enabled then StartAA() end
if Config.Aimbot_Enabled then StartAimbot() end
if Config.AutoBhop then StartBhop() end
if Config.LoopWalkSpeed > 0 then StartWalkSpeedLoop() end
if Config.LoopJumpPower > 0 then StartJumpPowerLoop() end
if Config.ThirdPerson then StartThirdPerson() end
if Config.LoopFOV then StartLoopFOV() end
if Config.Freecam then StartFreecam() end
if Config.AmbientEnabled then ApplyAmbient() end
RefreshChams()
