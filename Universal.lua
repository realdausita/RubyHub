--// Ruby Hub Universal | Beta (Linoria UI Port & Mega Update)
--// Made by dausita

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MPS = game:GetService("MarketplaceService")
local Lighting = game:GetService("Lighting")
local VIM = game:GetService("VirtualInputManager")
local TPS = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--============================================================--
--              UNIVERSAL ANTI-CHEAT BYPASS V3                --
--============================================================--
pcall(function()
    local gmt = getrawmetatable(game)
    local oldNamecall = gmt.__namecall
    local oldIndex = gmt.__index
    setreadonly(gmt, false)
    
    gmt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" or method == "kick" then return end
        if method == "FireServer" and tostring(self) == "Ban" then return end
        if method == "FireServer" and tostring(self):lower():find("anticheat") then return end
        if method == "FireServer" and tostring(self):lower():find("crash") then return end
        return oldNamecall(self, ...)
    end)
    
    gmt.__index = newcclosure(function(self, key)
        if key == "WalkSpeed" or key == "JumpPower" then return 16 end
        return oldIndex(self, key)
    end)
    setreadonly(gmt, true)
    
    if sethiddenproperty then
        pcall(function() sethiddenproperty(LP, "MaximumSimulationRadius", math.huge) end)
        pcall(function() sethiddenproperty(LP, "SimulationRadius", math.huge) end)
    end
end)

local executorName = "Unknown"
pcall(function()
    if identifyexecutor then executorName = identifyexecutor()
    elseif getexecutorname then executorName = getexecutorname() end
end)

local repo = 'https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Toggles = Library.Toggles
local Options = Library.Options

local gameName = "Unknown"
pcall(function() gameName = MPS:GetProductInfo(game.PlaceId).Name end)

local Window = Library:CreateWindow({
    Title = 'Ruby Hub Universal | Beta',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Information = Window:AddTab('Information'),
    Main = Window:AddTab('Main'),
    Visuals = Window:AddTab('Visuals'),
    Player = Window:AddTab('Player'),
    Misc = Window:AddTab('Miscellaneous'),
    Settings = Window:AddTab('Settings')
}

Library:Notify("Welcome, " .. LP.Name .. " | Executor: " .. executorName, 5)

--============================================================--
--                     WATERMARK                              --
--============================================================--
local Watermark = Drawing.new("Text")
Watermark.Visible = true
Watermark.Text = "Ruby Hub"
Watermark.Size = 22
Watermark.Center = true
Watermark.Outline = true
Watermark.Color = Color3.fromRGB(255, 255, 255)
Watermark.Font = 3
Watermark.Position = Vector2.new(100, Camera.ViewportSize.Y - 50)

--============================================================--
--                     INFORMATION TAB                        --
--============================================================--
local InfoBox = Tabs.Information:AddLeftGroupbox('Information')
InfoBox:AddLabel('Game: ' .. gameName)
InfoBox:AddLabel('This script is still in Beta.')

local DiscordBox = Tabs.Information:AddRightGroupbox('Community')
DiscordBox:AddLabel('discord.gg/hxwE6RMwXs')
DiscordBox:AddButton('Copy Discord Link', function()
    pcall(function()
        if setclipboard then
            setclipboard("https://discord.gg/hxwE6RMwXs")
        end
    end)
    Library:Notify("Discord link copied!", 3)
end)

local UpdateLog = Tabs.Information:AddLeftGroupbox('Update Log')
UpdateLog:AddLabel('v1.1 [Mega Update]')
UpdateLog:AddLabel('- Aimbot fixes & Silent Aim')
UpdateLog:AddLabel('- Skeleton & Head Box ESP')
UpdateLog:AddLabel('- Anti Aim / Spinbot')
UpdateLog:AddLabel('- Triggerbot & Rainbow FOV')
UpdateLog:AddLabel('- Third Person & BunnyHop')

--============================================================--
--                        ESP SYSTEM                          --
--============================================================--
local ESPFolder = Instance.new("Folder", game:GetService("CoreGui"))
ESPFolder.Name = "RubyHubESP"

local ESPObjects = {}
local ESP = {
    Highlight = false, HLColor = Color3.fromRGB(255, 50, 50), FillTrans = 0.5, OutTrans = 0,
    NameTag = false, HPBar = false, HPText = false, Distance = false,
    Box = false, BoxColor = Color3.fromRGB(255, 255, 255), BoxOutline = true, BoxOutColor = Color3.new(0, 0, 0),
    HeadBox = false, HeadBoxColor = Color3.fromRGB(255, 255, 255),
    Skeleton = false, SkeletonColor = Color3.fromRGB(255, 255, 255),
    Tracers = false, TracersColor = Color3.fromRGB(255, 255, 255), TracersOrigin = "Top", TracerOutline = true, TracerOutColor = Color3.new(0, 0, 0),
    TeamCheck = false, UseTeamColor = false,
    VisCheck = false, VisColor = Color3.fromRGB(0, 255, 0)
}
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")

local function removeESP(plr)
    local d = ESPObjects[plr]
    if not d then return end
    pcall(function() d.Highlight:Destroy() end)
    pcall(function() d.NameBB:Destroy() end)
    pcall(function() d.BarBB:Destroy() end)
    pcall(function() d.DistBB:Destroy() end)
    pcall(function() if d.Box then d.Box:Remove() end end)
    pcall(function() if d.BoxOut then d.BoxOut:Remove() end end)
    pcall(function() if d.HeadBox then d.HeadBox:Remove() end end)
    pcall(function() if d.Tracer then d.Tracer:Remove() end end)
    pcall(function() if d.TracerOut then d.TracerOut:Remove() end end)
    if d.Skeletons then
        for _, v in pairs(d.Skeletons) do pcall(function() v:Remove() end) end
    end
    ESPObjects[plr] = nil
end

local function getSkeletonsParts(char)
    local parts = {}
    if char:FindFirstChild("UpperTorso") then -- R15
        parts = {
            {char:FindFirstChild("Head"), char:FindFirstChild("UpperTorso")},
            {char:FindFirstChild("UpperTorso"), char:FindFirstChild("LowerTorso")},
            {char:FindFirstChild("UpperTorso"), char:FindFirstChild("RightUpperArm")},
            {char:FindFirstChild("RightUpperArm"), char:FindFirstChild("RightLowerArm")},
            {char:FindFirstChild("RightLowerArm"), char:FindFirstChild("RightHand")},
            {char:FindFirstChild("UpperTorso"), char:FindFirstChild("LeftUpperArm")},
            {char:FindFirstChild("LeftUpperArm"), char:FindFirstChild("LeftLowerArm")},
            {char:FindFirstChild("LeftLowerArm"), char:FindFirstChild("LeftHand")},
            {char:FindFirstChild("LowerTorso"), char:FindFirstChild("RightUpperLeg")},
            {char:FindFirstChild("RightUpperLeg"), char:FindFirstChild("RightLowerLeg")},
            {char:FindFirstChild("RightLowerLeg"), char:FindFirstChild("RightFoot")},
            {char:FindFirstChild("LowerTorso"), char:FindFirstChild("LeftUpperLeg")},
            {char:FindFirstChild("LeftUpperLeg"), char:FindFirstChild("LeftLowerLeg")},
            {char:FindFirstChild("LeftLowerLeg"), char:FindFirstChild("LeftFoot")}
        }
    else -- R6
        parts = {
            {char:FindFirstChild("Head"), char:FindFirstChild("Torso")},
            {char:FindFirstChild("Torso"), char:FindFirstChild("Right Arm")},
            {char:FindFirstChild("Torso"), char:FindFirstChild("Left Arm")},
            {char:FindFirstChild("Torso"), char:FindFirstChild("Right Leg")},
            {char:FindFirstChild("Torso"), char:FindFirstChild("Left Leg")}
        }
    end
    return parts
end

local function createESP(plr)
    if plr == LP then return end
    removeESP(plr)
    
    local char = plr.Character
    if not char then return end
    
    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not head or not hum or not hrp then return end
    
    local d = {}
    local charH = 5
    pcall(function() local _, s = char:GetBoundingBox(); charH = s.Y end)

    local hl = Instance.new("Highlight")
    hl.FillColor = ESP.HLColor
    hl.FillTransparency = ESP.FillTrans
    hl.OutlineTransparency = ESP.OutTrans
    hl.Adornee = char
    hl.Enabled = ESP.Highlight
    hl.Parent = char
    d.Highlight = hl

    local nbb = Instance.new("BillboardGui")
    nbb.Name = "RubyESP"
    nbb.Adornee = head
    nbb.Size = UDim2.new(8, 0, 3, 0)
    nbb.StudsOffset = Vector3.new(0, 2.5, 0)
    nbb.AlwaysOnTop = true
    nbb.Parent = ESPFolder

    local ntL = Instance.new("TextLabel", nbb)
    ntL.Size = UDim2.new(1, 0, 0.45, 0)
    ntL.Position = UDim2.new(0, 0, 0, 0)
    ntL.BackgroundTransparency = 1
    ntL.TextColor3 = Color3.fromRGB(255, 100, 100)
    ntL.TextStrokeTransparency = 0.3
    ntL.TextScaled = true
    ntL.Font = Enum.Font.GothamBold
    ntL.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
    ntL.Visible = ESP.NameTag
    d.NTLabel = ntL

    local hpL = Instance.new("TextLabel", nbb)
    hpL.Size = UDim2.new(1, 0, 0.45, 0)
    hpL.Position = UDim2.new(0, 0, 0.45, 0)
    hpL.BackgroundTransparency = 1
    hpL.TextColor3 = Color3.fromRGB(0, 255, 100)
    hpL.TextStrokeTransparency = 0.3
    hpL.TextScaled = false
    hpL.TextSize = 13
    hpL.Font = Enum.Font.GothamBold
    hpL.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
    hpL.Visible = ESP.HPText
    d.HPLabel = hpL
    d.NameBB = nbb

    local dbb = Instance.new("BillboardGui")
    dbb.Name = "RubyDist"
    dbb.Adornee = hrp
    dbb.Size = UDim2.new(4, 0, 1, 0)
    dbb.StudsOffset = Vector3.new(0, -(charH / 2 + 1.5), 0)
    dbb.AlwaysOnTop = true
    dbb.Parent = ESPFolder
    d.DistBB = dbb

    local dL = Instance.new("TextLabel", dbb)
    dL.Size = UDim2.new(1, 0, 1, 0)
    dL.BackgroundTransparency = 1
    dL.TextColor3 = Color3.fromRGB(200, 200, 255)
    dL.TextStrokeTransparency = 0.3
    dL.TextScaled = false
    dL.TextSize = 12
    dL.Font = Enum.Font.GothamBold
    dL.Text = "0m"
    dL.Visible = ESP.Distance
    d.DistLabel = dL

    local bbb = Instance.new("BillboardGui")
    bbb.Name = "RubyBar"
    bbb.Adornee = hrp
    bbb.Size = UDim2.new(0.4, 0, charH, 0)
    bbb.StudsOffset = Vector3.new(-(hrp.Size.X / 2 + 0.8), 0, 0)
    bbb.AlwaysOnTop = true
    bbb.Enabled = ESP.HPBar
    bbb.Parent = ESPFolder
    
    local bg = Instance.new("Frame", bbb)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 4)
    
    local fl = Instance.new("Frame", bg)
    fl.AnchorPoint = Vector2.new(0, 1)
    fl.Position = UDim2.new(0, 0, 1, 0)
    fl.Size = UDim2.new(1, 0, math.clamp(hum.Health / hum.MaxHealth, 0, 1), 0)
    fl.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    fl.BorderSizePixel = 0
    Instance.new("UICorner", fl).CornerRadius = UDim.new(0, 4)
    
    d.BarBB = bbb
    d.BarFill = fl
    d.Humanoid = hum
    d.HRP = hrp
    d.Head = head
    
    local boxOut = Drawing.new("Square")
    boxOut.Visible = false; boxOut.Color = ESP.BoxOutColor; boxOut.Thickness = 2; boxOut.Filled = false; boxOut.ZIndex = 1
    d.BoxOut = boxOut
    
    local box = Drawing.new("Square")
    box.Visible = false; box.Color = ESP.BoxColor; box.Thickness = 1; box.Filled = false; box.ZIndex = 2
    d.Box = box
    
    local hb = Drawing.new("Circle")
    hb.Visible = false; hb.Color = ESP.HeadBoxColor; hb.Thickness = 1; hb.Filled = false; hb.ZIndex = 2
    d.HeadBox = hb

    local trOut = Drawing.new("Line")
    trOut.Visible = false; trOut.Color = ESP.TracerOutColor; trOut.Thickness = 2; trOut.ZIndex = 1
    d.TracerOut = trOut
    
    local tr = Drawing.new("Line")
    tr.Visible = false; tr.Color = ESP.TracersColor; tr.Thickness = 1; tr.ZIndex = 2
    d.Tracer = tr
    
    d.Skeletons = {}
    for i=1, 14 do
        local l = Drawing.new("Line")
        l.Visible = false; l.Color = ESP.SkeletonColor; l.Thickness = 1; l.ZIndex = 2
        table.insert(d.Skeletons, l)
    end

    ESPObjects[plr] = d
end

local function checkVisible(targetPart, char)
    if not targetPart then return false end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LP.Character, Camera}
    rayParams.IgnoreWater = true
    local raycastResult = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 1000, rayParams)
    return (raycastResult and raycastResult.Instance and raycastResult.Instance:IsDescendantOf(char)) or false
end

RunService.Heartbeat:Connect(function()
    local camPos = Camera.CFrame.Position
    for plr, d in pairs(ESPObjects) do
        if not plr.Parent or not plr.Character or not d.Humanoid or not d.Humanoid.Parent then
            removeESP(plr)
            continue
        end
        
        local isVisible = ESP.VisCheck and checkVisible(d.HRP, plr.Character)
        
        if ESP.TeamCheck and plr.Team == LP.Team then
            if d.Highlight then d.Highlight.Enabled = false end
            if d.NTLabel then d.NTLabel.Visible = false end
            if d.HPLabel then d.HPLabel.Visible = false end
            if d.DistLabel then d.DistLabel.Visible = false end
            if d.DistBB then d.DistBB.Enabled = false end
            if d.BarBB then d.BarBB.Enabled = false end
            if d.Box then d.Box.Visible = false end
            if d.BoxOut then d.BoxOut.Visible = false end
            if d.HeadBox then d.HeadBox.Visible = false end
            if d.Tracer then d.Tracer.Visible = false end
            if d.TracerOut then d.TracerOut.Visible = false end
            if d.Skeletons then for _, v in pairs(d.Skeletons) do v.Visible = false end end
            continue
        end
        
        local char = plr.Character
        local h = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not h or not hrp or not head then
            if d.Highlight then d.Highlight.Enabled = false end
            if d.NTLabel then d.NTLabel.Visible = false end
            if d.HPLabel then d.HPLabel.Visible = false end
            if d.DistLabel then d.DistLabel.Visible = false end
            if d.DistBB then d.DistBB.Enabled = false end
            if d.BarBB then d.BarBB.Enabled = false end
            if d.Box then d.Box.Visible = false end
            if d.BoxOut then d.BoxOut.Visible = false end
            if d.HeadBox then d.HeadBox.Visible = false end
            if d.Tracer then d.Tracer.Visible = false end
            if d.TracerOut then d.TracerOut.Visible = false end
            if d.Skeletons then for _, v in pairs(d.Skeletons) do v.Visible = false end end
            continue
        end
        local ratio = math.clamp(h.Health / h.MaxHealth, 0, 1)
        d.HRP = hrp
        d.Head = head
        
        local currentColor = ESP.BoxColor
        if ESP.UseTeamColor and plr.Team then
            pcall(function() currentColor = plr.Team.TeamColor.Color end)
        elseif ESP.VisCheck and isVisible then
            currentColor = ESP.VisColor
        end
        
        if d.Highlight then
            d.Highlight.Enabled = ESP.Highlight
            d.Highlight.FillColor = ESP.UseTeamColor and (plr.Team and plr.Team.TeamColor.Color or ESP.HLColor) or ESP.HLColor
            d.Highlight.FillTransparency = ESP.FillTrans
            d.Highlight.OutlineTransparency = ESP.OutTrans
        end
        
        if d.NTLabel then d.NTLabel.Visible = ESP.NameTag end
        if d.HPLabel then
            d.HPLabel.Visible = ESP.HPText
            d.HPLabel.Text = math.floor(h.Health) .. "/" .. math.floor(h.MaxHealth)
        end
        
        if d.DistLabel and d.HRP and d.HRP.Parent then
            if d.DistBB then d.DistBB.Enabled = true end
            d.DistLabel.Visible = ESP.Distance
            d.DistLabel.Text = math.floor((camPos - d.HRP.Position).Magnitude) .. "m"
        end
        
        if d.BarBB then
            d.BarBB.Enabled = ESP.HPBar
            d.BarFill.Size = UDim2.new(1, 0, ratio, 0)
            d.BarFill.BackgroundColor3 = Color3.new(ratio < 0.5 and 1 or (1 - ratio) * 2, ratio > 0.5 and 1 or ratio * 2, 0)
        end
        
        local pos, vis = Camera:WorldToViewportPoint(d.HRP.Position)
        if vis then
            local dist = (camPos - d.HRP.Position).Magnitude
            local scale = 1000 / math.clamp(dist, 10, 150)
            
            if d.Box then
                local size = Vector2.new(scale * 4, scale * 6)
                local boxPos = Vector2.new(pos.X - size.X / 2, pos.Y - size.Y / 2)
                
                if d.BoxOut and ESP.BoxOutline then
                    d.BoxOut.Visible = ESP.Box; d.BoxOut.Size = size; d.BoxOut.Position = boxPos; d.BoxOut.Color = ESP.BoxOutColor
                elseif d.BoxOut then d.BoxOut.Visible = false end
                
                d.Box.Visible = ESP.Box; d.Box.Size = size; d.Box.Position = boxPos; d.Box.Color = currentColor
            end
            
            if d.HeadBox and d.Head then
                local hPos, hVis = Camera:WorldToViewportPoint(d.Head.Position)
                if hVis then
                    d.HeadBox.Visible = ESP.HeadBox
                    d.HeadBox.Radius = scale * 1.5
                    d.HeadBox.Position = Vector2.new(hPos.X, hPos.Y)
                    d.HeadBox.Color = ESP.HeadBoxColor
                else
                    d.HeadBox.Visible = false
                end
            elseif d.HeadBox then d.HeadBox.Visible = false end

            if d.Tracer then
                local trY = 0
                local fromX = Camera.ViewportSize.X / 2
                local toX, toY = pos.X, pos.Y
                if ESP.TracersOrigin == "Bottom" then trY = Camera.ViewportSize.Y
                elseif ESP.TracersOrigin == "Top" then trY = 0
                elseif ESP.TracersOrigin == "Middle" then trY = Camera.ViewportSize.Y / 2
                elseif ESP.TracersOrigin == "Mouse" then
                    local mPos = UIS:GetMouseLocation()
                    fromX = mPos.X; trY = mPos.Y
                end
                local origin = Vector2.new(fromX, trY)
                local target = Vector2.new(toX, toY)
                
                if d.TracerOut and ESP.TracerOutline then
                    d.TracerOut.Visible = ESP.Tracers; d.TracerOut.From = origin; d.TracerOut.To = target; d.TracerOut.Color = ESP.TracerOutColor
                elseif d.TracerOut then d.TracerOut.Visible = false end
                
                d.Tracer.Visible = ESP.Tracers; d.Tracer.From = origin; d.Tracer.To = target; d.Tracer.Color = ESP.TracersColor
            end
            
            if ESP.Skeleton and d.Skeletons then
                local sParts = getSkeletonsParts(plr.Character)
                for i=1, 14 do
                    local l = d.Skeletons[i]
                    if sParts[i] and sParts[i][1] and sParts[i][2] then
                        local p1, v1 = Camera:WorldToViewportPoint(sParts[i][1].Position)
                        local p2, v2 = Camera:WorldToViewportPoint(sParts[i][2].Position)
                        if v1 and v2 then
                            l.Visible = true; l.From = Vector2.new(p1.X, p1.Y); l.To = Vector2.new(p2.X, p2.Y); l.Color = ESP.SkeletonColor
                        else
                            l.Visible = false
                        end
                    else
                        l.Visible = false
                    end
                end
            elseif d.Skeletons then
                for _, v in pairs(d.Skeletons) do v.Visible = false end
            end
        else
            if d.Box then d.Box.Visible = false end
            if d.BoxOut then d.BoxOut.Visible = false end
            if d.HeadBox then d.HeadBox.Visible = false end
            if d.Tracer then d.Tracer.Visible = false end
            if d.TracerOut then d.TracerOut.Visible = false end
            if d.Skeletons then for _, v in pairs(d.Skeletons) do v.Visible = false end end
        end
    end
end)

local function hookPlayer(plr)
    if plr == LP then return end
    if plr.Character then createESP(plr) end
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        createESP(plr)
    end)
end

for _, p in pairs(Players:GetPlayers()) do hookPlayer(p) end
Players.PlayerAdded:Connect(hookPlayer)
Players.PlayerRemoving:Connect(removeESP)

--============================================================--
--                         MAIN TAB                           --
--============================================================--
local AimbotEnv = {
    Enabled = false,
    Method = "Camlock",
    Part = "Head",
    Smooth = 1,
    Prediction = false,
    PredX = 0,
    PredY = 0,
    PredZ = 0,
    WallCheck = false,
    ShowFOV = false,
    FOVSize = 100,
    FOV360 = false,
    RainbowFOV = false
}

local SilentAimEnv = {
    Enabled = false,
    Method = "Raycast",
    Part = "Head",
    WallCheck = false,
    ShowFOV = false,
    FOVSize = 100,
    FOV360 = false,
    AutoFire = false
}

local TriggerEnv = {
    Enabled = false,
    Delay = 0
}

local AntiAimEnv = {
    Enabled = false,
    Pitch = "None",
    Yaw = "None",
    SpinSpeed = 10
}

local FOVColor = Color3.fromRGB(255, 255, 255)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false; FOVCircle.Color = FOVColor; FOVCircle.Thickness = 1; FOVCircle.Filled = false

local SilentFOVColor = Color3.fromRGB(170, 0, 255)
local SilentFOVCircle = Drawing.new("Circle")
SilentFOVCircle.Visible = false; SilentFOVCircle.Color = SilentFOVColor; SilentFOVCircle.Thickness = 1; SilentFOVCircle.Filled = false

-- LEFT GROUPBOX (Aimbot & Config)
local AimBox = Tabs.Main:AddLeftGroupbox('Aimbot')

AimBox:AddToggle('AimToggle', { Text = 'Enable Aimbot', Default = false, Callback = function(v) AimbotEnv.Enabled = v end })
:AddKeyPicker('AimKey', { Default = 'MB2', SyncToggleState = false, Mode = 'Hold', Text = 'Aimbot', NoUI = false })

AimBox:AddDropdown('AimMethod', { Values = {'Camlock', 'Mouse'}, Default = 1, Multi = false, Text = 'Aim Method', Callback = function(v) AimbotEnv.Method = v end })
AimBox:AddDropdown('AimPart', { Values = {'Head', 'HumanoidRootPart', 'Torso'}, Default = 1, Multi = false, Text = 'Target Part', Callback = function(v) AimbotEnv.Part = v end })
AimBox:AddSlider('AimSmooth', { Text = 'Smoothness (Lower = Faster)', Default = 1, Min = 0.1, Max = 10, Rounding = 1, Compact = false, Callback = function(v) AimbotEnv.Smooth = v end })
AimBox:AddToggle('AimWall', { Text = 'Wall Check', Default = false, Callback = function(v) AimbotEnv.WallCheck = v end })

AimBox:AddDivider()
AimBox:AddToggle('AimPredT', { Text = 'Enable Prediction', Default = false, Callback = function(v) AimbotEnv.Prediction = v end })
AimBox:AddSlider('AimPredX', { Text = 'Prediction X', Default = 0, Min = -10, Max = 10, Rounding = 1, Compact = true, Callback = function(v) AimbotEnv.PredX = v end })
AimBox:AddSlider('AimPredY', { Text = 'Prediction Y', Default = 0, Min = -10, Max = 10, Rounding = 1, Compact = true, Callback = function(v) AimbotEnv.PredY = v end })
AimBox:AddSlider('AimPredZ', { Text = 'Prediction Z', Default = 0, Min = -10, Max = 10, Rounding = 1, Compact = true, Callback = function(v) AimbotEnv.PredZ = v end })

AimBox:AddDivider()
AimBox:AddToggle('AimFov', { Text = 'Show FOV', Default = false, Callback = function(v) AimbotEnv.ShowFOV = v end }):AddColorPicker('FovColorP', { Default = Color3.fromRGB(255, 255, 255), Title = 'FOV Color', Callback = function(c) FOVCircle.Color = c end })
AimBox:AddToggle('AimRainbowFOV', { Text = 'Rainbow FOV', Default = false, Callback = function(v) AimbotEnv.RainbowFOV = v end })
AimBox:AddToggle('Aim360FOV', { Text = '360° FOV', Default = false, Callback = function(v) AimbotEnv.FOV360 = v end })
AimBox:AddSlider('AimFovS', { Text = 'FOV Size', Default = 100, Min = 10, Max = 1000, Rounding = 0, Compact = false, Callback = function(v) AimbotEnv.FOVSize = v; FOVCircle.Radius = v end })

-- RIGHT GROUPBOX (Silent Aim & Triggerbot & Anti Aim)
local SilentBox = Tabs.Main:AddRightGroupbox('Silent Aim')

SilentBox:AddToggle('SilentAimToggle', { Text = 'Enable Silent Aim', Default = false, Callback = function(v) SilentAimEnv.Enabled = v end })

SilentBox:AddDropdown('SilentAimMethod', { Values = {'Raycast', 'FindPartOnRay', 'Mouse.Hit/Target'}, Default = 1, Multi = false, Text = 'Method', Callback = function(v) SilentAimEnv.Method = v end })
SilentBox:AddDropdown('SilentAimPart', { Values = {'Head', 'HumanoidRootPart', 'Torso'}, Default = 1, Multi = false, Text = 'Target Part', Callback = function(v) SilentAimEnv.Part = v end })
SilentBox:AddToggle('SilentAimWall', { Text = 'Wall Check', Default = false, Callback = function(v) SilentAimEnv.WallCheck = v end })
SilentBox:AddToggle('SilentAimAutoFire', { Text = 'Auto Fire', Default = false, Callback = function(v) SilentAimEnv.AutoFire = v end })
SilentBox:AddToggle('SilentAimAutoFireTC', { Text = 'Auto Fire TeamCheck', Default = true, Callback = function(v) SilentAimEnv.AutoFireTC = v end })

SilentBox:AddDivider()
SilentBox:AddToggle('SilentAimFov', { Text = 'Show Silent FOV', Default = false, Callback = function(v) SilentAimEnv.ShowFOV = v end }):AddColorPicker('SilentFovColorP', { Default = Color3.fromRGB(170, 0, 255), Title = 'Silent FOV Color', Callback = function(c) SilentFOVCircle.Color = c end })
SilentBox:AddToggle('SilentAim360FOV', { Text = '360° FOV', Default = false, Callback = function(v) SilentAimEnv.FOV360 = v end })
SilentBox:AddSlider('SilentAimFovS', { Text = 'FOV Size', Default = 100, Min = 10, Max = 1000, Rounding = 0, Compact = false, Callback = function(v) SilentAimEnv.FOVSize = v; SilentFOVCircle.Radius = v end })

local TriggerBox = Tabs.Main:AddRightGroupbox('Triggerbot')
TriggerBox:AddToggle('TriggerToggle', { Text = 'Enable Triggerbot', Default = false, Callback = function(v) TriggerEnv.Enabled = v end })
TriggerBox:AddSlider('TriggerDelay', { Text = 'Trigger Delay (ms)', Default = 0, Min = 0, Max = 1000, Rounding = 0, Compact = false, Callback = function(v) TriggerEnv.Delay = v end })

local AntiAimBox = Tabs.Main:AddRightGroupbox('Anti Aim')
AntiAimBox:AddToggle('AntiAimToggle', { Text = 'Enable Anti Aim', Default = false, Callback = function(v) AntiAimEnv.Enabled = v end })
AntiAimBox:AddDropdown('AntiAimPitch', { Values = {'None', 'Look Up', 'Look Down', 'Jitter'}, Default = 1, Multi = false, Text = 'Pitch', Callback = function(v) AntiAimEnv.Pitch = v end })
AntiAimBox:AddDropdown('AntiAimYaw', { Values = {'None', 'Spin', 'Backwards', 'Jitter'}, Default = 1, Multi = false, Text = 'Yaw', Callback = function(v) AntiAimEnv.Yaw = v end })
AntiAimBox:AddSlider('AntiAimSpinSpeed', { Text = 'Spin Speed', Default = 10, Min = 1, Max = 50, Rounding = 0, Compact = false, Callback = function(v) AntiAimEnv.SpinSpeed = v end })

local HitboxEnv = {
    Enabled = false,
    Size = 10,
    Transparency = 0.5
}
local HitboxBox = Tabs.Main:AddLeftGroupbox('Hitbox Expander')
HitboxBox:AddToggle('HitboxToggle', { Text = 'Enable Hitbox', Default = false, Callback = function(v) HitboxEnv.Enabled = v end })
HitboxBox:AddSlider('HitboxSize', { Text = 'Hitbox Size', Default = 10, Min = 2, Max = 50, Rounding = 1, Compact = false, Callback = function(v) HitboxEnv.Size = v end })
HitboxBox:AddSlider('HitboxTrans', { Text = 'Transparency', Default = 0.5, Min = 0, Max = 1, Rounding = 1, Compact = false, Callback = function(v) HitboxEnv.Transparency = v end })

local aimTarget = nil
local silentTarget = nil

local function getClosestPlayer(env)
    local maxDist = env.FOV360 and math.huge or env.FOVSize
    local target = nil
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild(env.Part) and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            if ESP.TeamCheck and p.Team == LP.Team then continue end
            local pos, vis = Camera:WorldToViewportPoint(p.Character[env.Part].Position)
            if vis or env.FOV360 then
                local dist = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
                if dist < maxDist or env.FOV360 then
                    if env.WallCheck then
                        local rayParams = RaycastParams.new()
                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                        rayParams.FilterDescendantsInstances = {LP.Character, Camera}
                        rayParams.IgnoreWater = true
                        
                        local dir = p.Character[env.Part].Position - Camera.CFrame.Position
                        if dir.Magnitude > 0.1 then
                            local raycastResult = workspace:Raycast(Camera.CFrame.Position, dir.Unit * 1000, rayParams)
                            if raycastResult and raycastResult.Instance and raycastResult.Instance:IsDescendantOf(p.Character) then
                                maxDist = env.FOV360 and maxDist or dist
                                target = p.Character
                            end
                        end
                    else
                        maxDist = env.FOV360 and maxDist or dist
                        target = p.Character
                    end
                end
            end
        end
    end
    return target
end

-- Hooking for Silent Aim
local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    if SilentAimEnv.Enabled and silentTarget then
        if SilentAimEnv.Method == "Raycast" and method == "Raycast" then
            local args = {...}
            if silentTarget:FindFirstChild(SilentAimEnv.Part) then
                args[2] = (silentTarget[SilentAimEnv.Part].Position - args[1]).Unit * args[2].Magnitude
                return OldNamecall(self, unpack(args))
            end
        elseif SilentAimEnv.Method == "FindPartOnRay" and (method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" or method == "FindPartOnRay") then
            local args = {...}
            if silentTarget:FindFirstChild(SilentAimEnv.Part) then
                local ray = args[1]
                local newRay = Ray.new(ray.Origin, (silentTarget[SilentAimEnv.Part].Position - ray.Origin).Unit * ray.Direction.Magnitude)
                args[1] = newRay
                return OldNamecall(self, unpack(args))
            end
        end
    end
    return OldNamecall(self, ...)
end)

local OldIndex
OldIndex = hookmetamethod(game, "__index", function(self, key)
    if SilentAimEnv.Method == "Mouse.Hit/Target" and (key == "Hit" or key == "Target") and self:IsA("Mouse") and SilentAimEnv.Enabled then
        if silentTarget and silentTarget:FindFirstChild(SilentAimEnv.Part) then
            if key == "Hit" then return silentTarget[SilentAimEnv.Part].CFrame end
            if key == "Target" then return silentTarget[SilentAimEnv.Part] end
        end
    end
    return OldIndex(self, key)
end)

local nextTrigger = 0

RunService.RenderStepped:Connect(function()
    -- Watermark Updates
    Watermark.Position = Vector2.new(100, Camera.ViewportSize.Y - 50)
    
    local mouseLoc = UIS:GetMouseLocation()
    
    -- Aimbot FOV
    if AimbotEnv.ShowFOV and not AimbotEnv.FOV360 then
        FOVCircle.Visible = true
        FOVCircle.Position = mouseLoc
        if AimbotEnv.RainbowFOV then
            FOVCircle.Color = Color3.fromHSV(tick() * 0.5 % 1, 1, 1)
        end
    else
        FOVCircle.Visible = false
    end

    -- Silent Aim FOV
    if SilentAimEnv.ShowFOV and not SilentAimEnv.FOV360 then
        SilentFOVCircle.Visible = true
        SilentFOVCircle.Position = mouseLoc
    else
        SilentFOVCircle.Visible = false
    end

    -- Aimbot Logic
    if AimbotEnv.Enabled and Options.AimKey:GetState() then
        aimTarget = getClosestPlayer(AimbotEnv)
        
        if aimTarget and aimTarget:FindFirstChild(AimbotEnv.Part) then
            local tPart = aimTarget[AimbotEnv.Part]
            local tPos = tPart.Position
            
            if AimbotEnv.Prediction then
                tPos = tPos + Vector3.new(
                    tPart.Velocity.X * (AimbotEnv.PredX / 10),
                    tPart.Velocity.Y * (AimbotEnv.PredY / 10),
                    tPart.Velocity.Z * (AimbotEnv.PredZ / 10)
                )
            end
            
            if AimbotEnv.Method == "Camlock" then
                local newCFrame = CFrame.new(Camera.CFrame.Position, tPos)
                local smoothFactor = math.clamp(0.1 / AimbotEnv.Smooth, 0.01, 1)
                Camera.CFrame = Camera.CFrame:Lerp(newCFrame, smoothFactor)
            elseif AimbotEnv.Method == "Mouse" then
                local pos, vis = Camera:WorldToViewportPoint(tPos)
                if vis and mousemoverel then
                    local diffX = (pos.X - mouseLoc.X) * (0.1 / AimbotEnv.Smooth)
                    local diffY = (pos.Y - mouseLoc.Y) * (0.1 / AimbotEnv.Smooth)
                    mousemoverel(diffX, diffY)
                end
            end
        end
    else
        aimTarget = nil
    end
    
    -- Silent Aim Logic
    if SilentAimEnv.Enabled then
        silentTarget = getClosestPlayer(SilentAimEnv)
        if silentTarget and SilentAimEnv.AutoFire then
            local p = Players:GetPlayerFromCharacter(silentTarget)
            local canShoot = true
            if SilentAimEnv.AutoFireTC and p and p.Team == LP.Team then canShoot = false end
            if canShoot and tick() > nextTrigger then
                pcall(function() mouse1click() end)
                nextTrigger = tick() + 0.2
            end
        end
    else
        silentTarget = nil
    end

    -- Triggerbot Logic
    if TriggerEnv.Enabled then
        local ray = Camera:ViewportPointToRay(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = {LP.Character, Camera}
        rayParams.IgnoreWater = true
        local res = workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
        
        if res and res.Instance then
            local model = res.Instance:FindFirstAncestorOfClass("Model")
            if model and model:FindFirstChild("Humanoid") then
                local targetPlayer = Players:GetPlayerFromCharacter(model)
                if targetPlayer and targetPlayer ~= LP then
                    if not ESP.TeamCheck or targetPlayer.Team ~= LP.Team then
                        if tick() > nextTrigger then
                            pcall(function() mouse1click() end)
                            nextTrigger = tick() + (TriggerEnv.Delay / 1000)
                        end
                    end
                end
            end
        end
    end
    
    if Toggles.UnlockCamToggle and Toggles.UnlockCamToggle.Value then
        LP.CameraMaxZoomDistance = 128
        LP.CameraMinZoomDistance = 0.5
        LP.CameraMode = Enum.CameraMode.Classic
    end
end)

local origHrpCFrame = nil
RunService:BindToRenderStep("RubyThirdPerson", Enum.RenderPriority.Camera.Value + 1, function()
    if origHrpCFrame and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        LP.Character.HumanoidRootPart.CFrame = origHrpCFrame
        origHrpCFrame = nil
    end

    if Toggles.ThirdPersonToggle and Toggles.ThirdPersonToggle.Value then
        if LP.Character and LP.Character:FindFirstChild("Head") then
            local head = LP.Character.Head
            local camAngle = Camera.CFrame - Camera.CFrame.Position
            local dist = Options.ThirdPersonDist and Options.ThirdPersonDist.Value or 10
            Camera.CFrame = camAngle + head.Position + (camAngle.LookVector * -dist)
            for _, p in pairs(LP.Character:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    pcall(function() p.LocalTransparencyModifier = 0 end)
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if HitboxEnv.Enabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
                if ESP.TeamCheck and p.Team == LP.Team then continue end
                local head = p.Character.Head
                head.Size = Vector3.new(HitboxEnv.Size, HitboxEnv.Size, HitboxEnv.Size)
                head.Transparency = HitboxEnv.Transparency
                head.CanCollide = false
            end
        end
    else
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
                local head = p.Character.Head
                if head.Size.X > 5 then
                    head.Size = Vector3.new(1.2, 1.2, 1.2)
                    head.Transparency = 0
                end
            end
        end
    end

    if AntiAimEnv.Enabled and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LP.Character.HumanoidRootPart
        local yaw = 0
        if AntiAimEnv.Yaw == "Spin" then yaw = tick() * AntiAimEnv.SpinSpeed * 10
        elseif AntiAimEnv.Yaw == "Jitter" then yaw = (math.random() - 0.5) * 360
        elseif AntiAimEnv.Yaw == "Backwards" then yaw = 180 end
        
        local pitch = 0
        if AntiAimEnv.Pitch == "Look Up" then pitch = 90
        elseif AntiAimEnv.Pitch == "Look Down" then pitch = -90
        elseif AntiAimEnv.Pitch == "Jitter" then pitch = (math.random() - 0.5) * 180 end
        
        if yaw ~= 0 or pitch ~= 0 then 
            origHrpCFrame = hrp.CFrame
            hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(pitch), math.rad(yaw), 0) 
        end
    end
end)

--============================================================--
--                       VISUALS TAB                          --
--============================================================--
local VMainBox = Tabs.Visuals:AddLeftGroupbox('ESP General')
VMainBox:AddToggle('HLToggle', { Text = 'Highlight ESP', Default = false, Callback = function(v) ESP.Highlight = v end }):AddColorPicker('HLColor', { Default = Color3.fromRGB(255, 50, 50), Title = 'Highlight Color', Callback = function(c) ESP.HLColor = c end })
VMainBox:AddSlider('FillT', { Text = 'Fill Transparency', Default = 5, Min = 0, Max = 10, Rounding = 0, Compact = true, Callback = function(v) ESP.FillTrans = v / 10 end })
VMainBox:AddSlider('OutT', { Text = 'Outline Transparency', Default = 0, Min = 0, Max = 10, Rounding = 0, Compact = true, Callback = function(v) ESP.OutTrans = v / 10 end })
VMainBox:AddToggle('UTC', { Text = 'Use Team Color', Default = false, Callback = function(v) ESP.UseTeamColor = v end })
VMainBox:AddToggle('TC', { Text = 'TeamCheck', Default = false, Callback = function(v) ESP.TeamCheck = v end })
VMainBox:AddToggle('VisCheck', { Text = 'Visible Check', Default = false, Callback = function(v) ESP.VisCheck = v end }):AddColorPicker('VisColor', { Default = Color3.fromRGB(0, 255, 0), Title = 'Visible Color', Callback = function(c) ESP.VisColor = c end })

local VLabelsBox = Tabs.Visuals:AddRightGroupbox('ESP Labels & Boxes')
VLabelsBox:AddToggle('NT', { Text = 'NameTag ESP', Default = false, Callback = function(v) ESP.NameTag = v end })
VLabelsBox:AddToggle('HPB', { Text = 'HP Bar', Default = false, Callback = function(v) ESP.HPBar = v end })
VLabelsBox:AddToggle('HPT', { Text = 'HP Text', Default = false, Callback = function(v) ESP.HPText = v end })
VLabelsBox:AddToggle('DIST', { Text = 'Distance ESP', Default = false, Callback = function(v) ESP.Distance = v end })

VLabelsBox:AddToggle('BOX', { Text = 'Box ESP', Default = false, Callback = function(v) ESP.Box = v end }):AddColorPicker('BoxColor', { Default = Color3.fromRGB(255, 255, 255), Title = 'Box Color', Callback = function(c) ESP.BoxColor = c end })
VLabelsBox:AddToggle('BOXOUT', { Text = 'Box Outline', Default = true, Callback = function(v) ESP.BoxOutline = v end }):AddColorPicker('BoxOutColor', { Default = Color3.new(0, 0, 0), Title = 'Box Outline Color', Callback = function(c) ESP.BoxOutColor = c end })
VLabelsBox:AddToggle('HEADBOX', { Text = 'Head Box', Default = false, Callback = function(v) ESP.HeadBox = v end }):AddColorPicker('HeadBoxColor', { Default = Color3.fromRGB(255, 255, 255), Title = 'Head Box Color', Callback = function(c) ESP.HeadBoxColor = c end })
VLabelsBox:AddToggle('SKELETON', { Text = 'Skeleton ESP', Default = false, Callback = function(v) ESP.Skeleton = v end }):AddColorPicker('SkeletonColor', { Default = Color3.fromRGB(255, 255, 255), Title = 'Skeleton Color', Callback = function(c) ESP.SkeletonColor = c end })

local VTracersBox = Tabs.Visuals:AddRightGroupbox('Tracers / Snaplines')
VTracersBox:AddToggle('TRACERS', { Text = 'Tracers / Snaplines', Default = false, Callback = function(v) ESP.Tracers = v end }):AddColorPicker('TracerColor', { Default = Color3.fromRGB(255, 255, 255), Title = 'Tracer Color', Callback = function(c) ESP.TracersColor = c end })
VTracersBox:AddToggle('TRACOUT', { Text = 'Tracer Outline', Default = true, Callback = function(v) ESP.TracerOutline = v end }):AddColorPicker('TracerOutColor', { Default = Color3.new(0, 0, 0), Title = 'Tracer Outline Color', Callback = function(c) ESP.TracerOutColor = c end })
VTracersBox:AddDropdown('TracerOrigin', { Values = {"Bottom", "Middle", "Top", "Mouse"}, Default = 3, Multi = false, Text = 'Tracers Origin', Callback = function(v) ESP.TracersOrigin = v end })

--============================================================--
--                        PLAYER TAB                          --
--============================================================--
local noclipOn = false
local infJumpOn = false
local cfSpeedOn = false
local cfSpeedVal = 1
local cfFlyOn = false
local cfFlySpeed = 1
local gpsOn = false
local bhopOn = false

local PMainBox = Tabs.Player:AddLeftGroupbox('Movement')
PMainBox:AddSlider('WS', { Text = 'WalkSpeed', Default = 16, Min = 0, Max = 500, Rounding = 0, Compact = false, Callback = function(v) pcall(function() LP.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = v end) end })
PMainBox:AddSlider('JP', { Text = 'JumpPower', Default = 50, Min = 0, Max = 500, Rounding = 0, Compact = false, Callback = function(v) pcall(function() LP.Character:FindFirstChildOfClass("Humanoid").JumpPower = v end) end })
PMainBox:AddToggle('Noclip', { Text = 'Noclip', Default = false, Callback = function(v) noclipOn = v end })
PMainBox:AddToggle('InfJump', { Text = 'Infinite Jump', Default = false, Callback = function(v) infJumpOn = v end })
PMainBox:AddToggle('Bhop', { Text = 'BunnyHop', Default = false, Callback = function(v) bhopOn = v end })

local PCFBox = Tabs.Player:AddRightGroupbox('CFrame Movement')
PCFBox:AddToggle('CFSpeedToggle', { Text = 'CFrame Speed', Default = false, Callback = function(v) cfSpeedOn = v end })
PCFBox:AddSlider('CFSpeedVal', { Text = 'CFrame Speed Value', Default = 1, Min = 0.1, Max = 10, Rounding = 1, Compact = true, Callback = function(v) cfSpeedVal = v end })
PCFBox:AddToggle('CFFlyToggle', { Text = 'CFrame Fly', Default = false, Callback = function(v) cfFlyOn = v; if not v and LP.Character and LP.Character:FindFirstChild("Humanoid") then LP.Character.Humanoid.PlatformStand = false end end })
PCFBox:AddSlider('CFFlySpeed', { Text = 'CFrame Fly Speed', Default = 1, Min = 0.1, Max = 10, Rounding = 1, Compact = true, Callback = function(v) cfFlySpeed = v end })

local GPSGui = Instance.new("ScreenGui")
GPSGui.Name = "RubyGPS"
GPSGui.ResetOnSpawn = false
GPSGui.Enabled = false
pcall(function() GPSGui.Parent = LP:WaitForChild("PlayerGui") end)

local GPSFrame = Instance.new("Frame", GPSGui)
GPSFrame.Size = UDim2.new(0, 250, 0, 30)
GPSFrame.Position = UDim2.new(0.5, -125, 0, 50)
GPSFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
GPSFrame.BorderSizePixel = 0
Instance.new("UICorner", GPSFrame).CornerRadius = UDim.new(0, 6)

local GPSText = Instance.new("TextLabel", GPSFrame)
GPSText.Size = UDim2.new(1, -60, 1, 0)
GPSText.Position = UDim2.new(0, 10, 0, 0)
GPSText.BackgroundTransparency = 1
GPSText.TextColor3 = Color3.new(1, 1, 1)
GPSText.Font = Enum.Font.GothamBold
GPSText.TextSize = 13
GPSText.TextXAlignment = Enum.TextXAlignment.Left
GPSText.Text = "X: 0, Y: 0, Z: 0"

local GPSCopy = Instance.new("TextButton", GPSFrame)
GPSCopy.Size = UDim2.new(0, 50, 0, 20)
GPSCopy.Position = UDim2.new(1, -55, 0.5, -10)
GPSCopy.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
GPSCopy.TextColor3 = Color3.new(1, 1, 1)
GPSCopy.Font = Enum.Font.GothamBold
GPSCopy.TextSize = 12
GPSCopy.Text = "Copy"
Instance.new("UICorner", GPSCopy).CornerRadius = UDim.new(0, 4)

GPSCopy.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then
            setclipboard(GPSText.Text)
            local old = GPSCopy.Text
            GPSCopy.Text = "Copied!"
            task.delay(1, function() GPSCopy.Text = old end)
        end
    end)
end)

local PTrackerBox = Tabs.Player:AddLeftGroupbox('Trackers & View')
PTrackerBox:AddToggle('UnlockCamToggle', { Text = 'Unlock Camera', Default = false, Callback = function(v) end })
PTrackerBox:AddToggle('GPSToggle', { Text = 'GPS Tracker', Default = false, Callback = function(v) gpsOn = v; GPSGui.Enabled = v end })
PTrackerBox:AddToggle('ThirdPersonToggle', { Text = 'Third Person', Default = false, Callback = function(v)
    if not v then LP.CameraMaxZoomDistance = 128; LP.CameraMinZoomDistance = 0.5 end
end }):AddKeyPicker('ThirdPersonKey', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'Third Person', NoUI = false })
PTrackerBox:AddSlider('ThirdPersonDist', { Text = 'Third Person Distance', Default = 10, Min = 5, Max = 50, Rounding = 0, Compact = true, Callback = function(v) if Toggles.ThirdPersonToggle.Value then LP.CameraMaxZoomDistance = v; LP.CameraMinZoomDistance = v end end })

RunService.Stepped:Connect(function()
    if LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if bhopOn and hum and hum.FloorMaterial ~= Enum.Material.Air and UIS:IsKeyDown(Enum.KeyCode.Space) then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end

        for _, p in pairs(LP.Character:GetDescendants()) do
            if p:IsA("BasePart") then
                if noclipOn then
                    if p:GetAttribute("OrigCollide") == nil then p:SetAttribute("OrigCollide", p.CanCollide) end
                    p.CanCollide = false
                else
                    if p:GetAttribute("OrigCollide") ~= nil then
                        p.CanCollide = p:GetAttribute("OrigCollide")
                        p:SetAttribute("OrigCollide", nil)
                    end
                end
            end
        end
    end
end)

UIS.JumpRequest:Connect(function()
    if infJumpOn then
        pcall(function() LP.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
end)

RunService.Heartbeat:Connect(function()
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and LP.Character:FindFirstChild("Humanoid") then
        local hrp = LP.Character.HumanoidRootPart
        local hum = LP.Character.Humanoid
        
        if cfSpeedOn and hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * cfSpeedVal)
        end
        
        if cfFlyOn then
            hum.PlatformStand = true
            local cam = workspace.CurrentCamera
            local moveDir = Vector3.new()
            
            if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            
            if moveDir.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + (moveDir.Unit * cfFlySpeed)
            end
            hrp.Velocity = Vector3.new(0, 0, 0)
        end
        
        if gpsOn then
            local pos = hrp.Position
            GPSText.Text = string.format("X: %.1f, Y: %.1f, Z: %.1f", pos.X, pos.Y, pos.Z)
        end
    end
end)

--============================================================--
--                     MISCELLANEOUS TAB                      --
--============================================================--
local OptBox = Tabs.Misc:AddLeftGroupbox('Optimizations')

OptBox:AddToggle("OptPotato", {
    Text = "Potato Graphics",
    Default = false,
    Callback = function(v)
        if v then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            for _, p in pairs(workspace:GetDescendants()) do
                if p:IsA("BasePart") and not p:GetAttribute("OrigMat") then
                    p:SetAttribute("OrigMat", p.Material.Name)
                    p.Material = Enum.Material.SmoothPlastic
                end
            end
            Lighting.GlobalShadows = false
        else
            for _, p in pairs(workspace:GetDescendants()) do
                if p:IsA("BasePart") and p:GetAttribute("OrigMat") then
                    p.Material = Enum.Material[p:GetAttribute("OrigMat")]
                    p:SetAttribute("OrigMat", nil)
                end
            end
            Lighting.GlobalShadows = true
        end
    end
})

OptBox:AddToggle("OptNoTex", {
    Text = "No Textures",
    Default = false,
    Callback = function(v)
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Texture") or obj:IsA("Decal") then
                obj.Transparency = v and 1 or 0
            end
        end
    end
})

OptBox:AddToggle("OptAntiLag", {
    Text = "Anti-Lag",
    Default = false,
    Callback = function(v)
        for _, p in pairs(workspace:GetDescendants()) do
            if p:IsA("BasePart") then p.CastShadow = not v end
        end
        if workspace:FindFirstChildOfClass("Terrain") then
            if v then
                workspace.Terrain.WaterWaveSize = 0; workspace.Terrain.WaterWaveSpeed = 0
                workspace.Terrain.WaterReflectance = 0; workspace.Terrain.WaterTransparency = 1
            else
                workspace.Terrain.WaterWaveSize = 0.15; workspace.Terrain.WaterWaveSpeed = 10
                workspace.Terrain.WaterReflectance = 1; workspace.Terrain.WaterTransparency = 0.3
            end
        end
    end
})

OptBox:AddToggle("OptRTX", {
    Text = "RTX Graphics",
    Default = false,
    Callback = function(v)
        if v then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level21
            Lighting.GlobalShadows = true
            Lighting.Technology = Enum.Technology.Future
            Lighting.EnvironmentDiffuseScale = 1
            Lighting.EnvironmentSpecularScale = 1
        else
            Lighting.Technology = Enum.Technology.ShadowMap
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
        end
    end
})

OptBox:AddToggle("Desync", {
    Text = "Desync (Requires RakNet)",
    Default = false,
    Callback = function(v)
        if setfflag then
            setfflag("S2PhysicsSenderRate", v and "1" or "30")
            Library:Notify("Desync is " .. (v and "On" or "Off"), 3)
        else
            Library:Notify("Your executor does not support this!", 3)
        end
    end
})

local NetBox = Tabs.Misc:AddRightGroupbox('Server & Client')

local perfPanelEnabled = false
local PerfGui = Instance.new("ScreenGui")
PerfGui.Name = "RubyPerf"
PerfGui.ResetOnSpawn = false
PerfGui.Enabled = false
pcall(function() PerfGui.Parent = gethui and gethui() or game:GetService("CoreGui") end)

local PerfFrame = Instance.new("Frame", PerfGui)
PerfFrame.Size = UDim2.new(0, 180, 0, 70)
PerfFrame.Position = UDim2.new(0, 50, 0, 50)
PerfFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
PerfFrame.BackgroundTransparency = 0.3
PerfFrame.BorderSizePixel = 0
PerfFrame.Active = true
PerfFrame.Draggable = true
Instance.new("UICorner", PerfFrame).CornerRadius = UDim.new(0, 6)

local PerfText = Instance.new("TextLabel", PerfFrame)
PerfText.Size = UDim2.new(1, -10, 1, -10)
PerfText.Position = UDim2.new(0, 5, 0, 5)
PerfText.BackgroundTransparency = 1
PerfText.TextColor3 = Color3.new(1, 1, 1)
PerfText.Font = Enum.Font.GothamSemibold
PerfText.TextSize = 12
PerfText.TextXAlignment = Enum.TextXAlignment.Left
PerfText.TextYAlignment = Enum.TextYAlignment.Top
PerfText.Text = "FPS: 0\nPing: 0 ms\nRAM: 0 MB\nExec: " .. executorName

local Stats = game:GetService("Stats")
local lastTime = tick()
local frameCount = 0

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local currentTime = tick()
    if currentTime - lastTime >= 1 then
        local fps = math.floor(frameCount / (currentTime - lastTime))
        frameCount = 0
        lastTime = currentTime
        
        if perfPanelEnabled then
            local ping = 0
            pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            local ram = math.floor(Stats:GetTotalMemoryUsageMb())
            PerfText.Text = string.format("FPS: %d\nPing: %d ms\nRAM: %d MB\nExec: %s", fps, ping, ram, executorName)
        end
    end
end)

NetBox:AddToggle("PerfPanel", {
    Text = "Mini Performance Panel",
    Default = false,
    Callback = function(v)
        perfPanelEnabled = v
        PerfGui.Enabled = v
    end
})

NetBox:AddButton('Rejoin Server', function()
    TPS:TeleportToPlaceInstance(game.PlaceId, game.JobId)
end)

local hopMin, hopMax = 1, 50
NetBox:AddSlider('HopMin', { Text = 'Hop Min Players', Default = 1, Min = 1, Max = 50, Rounding = 0, Compact = true, Callback = function(v) hopMin = v end })
NetBox:AddSlider('HopMax', { Text = 'Hop Max Players', Default = 50, Min = 1, Max = 50, Rounding = 0, Compact = true, Callback = function(v) hopMax = v end })
NetBox:AddButton('Server Hop', function()
    Library:Notify("Searching for servers...", 3)
    local ok, result = pcall(function() return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")) end)
    if not ok or not result or not result.data then Library:Notify("Server Hop failed!", 3); return end
    for _, s in pairs(result.data) do
        if s.id ~= game.JobId and s.playing >= hopMin and s.playing <= hopMax then
            Library:Notify("Joining Server...", 3)
            TPS:TeleportToPlaceInstance(game.PlaceId, s.id); return
        end
    end
    Library:Notify("No matching server found!", 3)
end)

local antiAfkActive = false
local antiAfkThread = nil
local selAfk = "Direct Bypass"

local AFKBox = Tabs.Misc:AddLeftGroupbox('Anti-AFK')
AFKBox:AddDropdown('AfkMode', { Values = {"Direct Bypass", "Keypress (5 min)"}, Default = 1, Multi = false, Text = 'Mode', Callback = function(v) selAfk = v end })
AFKBox:AddToggle("AntiAFK", {
    Text = "Enable Anti-AFK",
    Default = false,
    Callback = function(v)
        antiAfkActive = v
        if v then
            if selAfk == "Direct Bypass" then
                pcall(function() for _, c in pairs(getconnections(LP.Idled)) do c:Disable() end end)
                Library:Notify("Direct bypass on!", 3)
            else
                antiAfkThread = task.spawn(function()
                    while antiAfkActive do
                        pcall(function()
                            VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                            task.wait(0.1)
                            VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                        end)
                        task.wait(300)
                    end
                end)
                Library:Notify("Keypress mode on!", 3)
            end
        else
            if antiAfkThread then pcall(function() task.cancel(antiAfkThread) end); antiAfkThread = nil end
        end
    end
})

local WorldBox = Tabs.Misc:AddRightGroupbox('World / Environment')

local skyP = {
    ["Aesthetic Night"] = "rbxassetid://1045964490",
    Sunset = "rbxassetid://1417494402",
    ["Night Stars"] = "rbxassetid://12064107",
    Cloudy = "rbxassetid://1417494030",
    ["Blue Space"] = "rbxassetid://223210450",
    ["Red Sky"] = "rbxassetid://1012890"
}
local selSky = "Aesthetic Night"
local custSky = ""

WorldBox:AddDropdown('SkyP', { Values = {"Aesthetic Night", "Sunset", "Night Stars", "Cloudy", "Blue Space", "Red Sky"}, Default = 1, Multi = false, Text = 'Skybox Preset', Callback = function(v) selSky = v end })
WorldBox:AddInput('SkyCust', { Default = '', Numeric = false, Finished = true, Text = 'Custom Skybox ID', Placeholder = 'rbxassetid://...', Callback = function(v) custSky = v end })
WorldBox:AddButton('Apply Skybox', function()
    local id = custSky ~= "" and custSky or skyP[selSky]
    if not id:find("rbxassetid://") then id = "rbxassetid://" .. id end
    local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
    sky.SkyboxBk = id; sky.SkyboxDn = id; sky.SkyboxFt = id; sky.SkyboxLf = id; sky.SkyboxRt = id; sky.SkyboxUp = id
    Library:Notify("Skybox applied!", 3)
end)

WorldBox:AddToggle('Fullbright', {
    Text = 'Super Fullbright',
    Default = false,
    Callback = function(v)
        if v then
            Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        else
            Lighting.Brightness = 1; Lighting.GlobalShadows = true; Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
        end
    end
})

WorldBox:AddToggle('NoFog', { Text = 'No Fog', Default = false, Callback = function(v) Lighting.FogEnd = v and 100000 or 10000 end })

local shaderP = {
    None = { B = 0, C = 0, S = 0, T = Color3.new(1, 1, 1), Bl = false, SR = false, D = false },
    Cinematic = { B = 0.05, C = 0.15, S = 0.1, T = Color3.fromRGB(255, 240, 220), Bl = true, SR = true, D = false },
    Cold = { B = -0.05, C = 0.1, S = -0.1, T = Color3.fromRGB(200, 210, 255), Bl = false, SR = false, D = false },
    Vibrant = { B = 0.1, C = 0.2, S = 0.4, T = Color3.new(1, 1, 1), Bl = true, SR = false, D = false },
    Noir = { B = -0.1, C = 0.3, S = -1, T = Color3.new(1, 1, 1), Bl = false, SR = false, D = false },
    Dreamy = { B = 0.15, C = -0.1, S = 0.1, T = Color3.fromRGB(255, 230, 240), Bl = true, SR = true, D = true }
}
local selShader = "None"
WorldBox:AddDropdown('ShaderP', { Values = {"None", "Cinematic", "Cold", "Vibrant", "Noir", "Dreamy"}, Default = 1, Multi = false, Text = 'Shader Preset', Callback = function(v) selShader = v end })
WorldBox:AddButton('Apply Shader', function()
    for _, v in pairs(Lighting:GetChildren()) do if v.Name:sub(1, 4) == "Ruby" then v:Destroy() end end
    local p = shaderP[selShader]
    if not p or selShader == "None" then Library:Notify("Shaders removed!", 3); return end
    
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "RubyCC"; cc.Brightness = p.B; cc.Contrast = p.C; cc.Saturation = p.S; cc.TintColor = p.T; cc.Parent = Lighting
    
    if p.Bl then local b = Instance.new("BloomEffect"); b.Name = "RubyBl"; b.Intensity = 0.4; b.Size = 24; b.Threshold = 0.8; b.Parent = Lighting end
    if p.SR then local s = Instance.new("SunRaysEffect"); s.Name = "RubySR"; s.Intensity = 0.15; s.Spread = 0.8; s.Parent = Lighting end
    if p.D then local d = Instance.new("DepthOfFieldEffect"); d.Name = "RubyDOF"; d.FarIntensity = 0.2; d.FocusDistance = 50; d.InFocusRadius = 30; d.Parent = Lighting end
    
    Library:Notify(selShader .. " applied!", 3)
end)

local deathSoundId = ""
local killSoundId = ""

local SoundsBox = Tabs.Misc:AddLeftGroupbox('Sounds')
local deathP = { ["Taco Bell"] = "130791919", ["Vine Boom"] = "6295005982", Bruh = "5765933015", ["Oof Classic"] = "12222242", ["MLG Horn"] = "258057783" }
local selDeath = "Vine Boom"
local custDeath = ""

SoundsBox:AddDropdown('DeathP', { Values = {"Taco Bell", "Vine Boom", "Bruh", "Oof Classic", "MLG Horn"}, Default = 2, Multi = false, Text = 'Death Sound', Callback = function(v) selDeath = v end })
SoundsBox:AddInput('DeathCust', { Default = '', Numeric = false, Finished = true, Text = 'Custom Death ID', Placeholder = '...', Callback = function(v) custDeath = v end })
SoundsBox:AddButton('Apply Death Sound', function()
    local id = custDeath ~= "" and custDeath or deathP[selDeath]
    if not id:find("rbxassetid://") then id = "rbxassetid://" .. id end
    deathSoundId = id
    Library:Notify("Death sound set!", 3)
end)

local function hookDeath(c)
    local hum = c:WaitForChild("Humanoid", 10)
    if hum then
        hum.Died:Connect(function()
            if deathSoundId ~= "" then
                local s = Instance.new("Sound", workspace); s.SoundId = deathSoundId; s.Volume = 2; s:Play()
                task.delay(5, function() s:Destroy() end)
            end
        end)
    end
end
if LP.Character then hookDeath(LP.Character) end
LP.CharacterAdded:Connect(hookDeath)

local killP = { Hitmarker = "3744370687", ["Vine Boom"] = "6295005982", Ding = "138081500", Airhorn = "258057783" }
local selKill = "Hitmarker"
local custKill = ""

SoundsBox:AddDropdown('KillP', { Values = {"Hitmarker", "Vine Boom", "Ding", "Airhorn"}, Default = 1, Multi = false, Text = 'Kill Sound', Callback = function(v) selKill = v end })
SoundsBox:AddInput('KillCust', { Default = '', Numeric = false, Finished = true, Text = 'Custom Kill ID', Placeholder = '...', Callback = function(v) custKill = v end })
SoundsBox:AddButton('Apply Kill Sound', function()
    local id = custKill ~= "" and custKill or killP[selKill]
    if not id:find("rbxassetid://") then id = "rbxassetid://" .. id end
    killSoundId = id
    Library:Notify("Kill sound set!", 3)
end)

local function hookKill(p)
    if p == LP then return end
    local function oc(c)
        local hum = c:WaitForChild("Humanoid", 10)
        if hum then
            hum.Died:Connect(function()
                if killSoundId ~= "" then
                    local creator = hum:FindFirstChild("creator")
                    local isOurKill = false
                    if creator and creator.Value == LP then
                        isOurKill = true
                    elseif aimTarget == c or silentTarget == c then
                        isOurKill = true
                    end
                    if isOurKill then
                        local s = Instance.new("Sound", workspace); s.SoundId = killSoundId; s.Volume = 2; s:Play()
                        task.delay(5, function() s:Destroy() end)
                    end
                end
            end)
        end
    end
    if p.Character then oc(p.Character) end
    p.CharacterAdded:Connect(oc)
end

for _, p in pairs(Players:GetPlayers()) do hookKill(p) end
Players.PlayerAdded:Connect(hookKill)

--============================================================--
--                       SETTINGS TAB                         --
--============================================================--
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({'MenuKeybind'})

ThemeManager:SetFolder('RubyHubUniversal')
SaveManager:SetFolder('RubyHubUniversal/configs')

SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:BuildThemeSection(Tabs.Settings)

local MenuGroup = Tabs.Settings:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind (Change Script Keybind)'):AddKeyPicker('MenuKeybind', { Default = 'RightShift', NoUI = true, Text = 'Menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
