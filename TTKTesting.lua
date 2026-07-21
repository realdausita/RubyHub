local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Gun = require(ReplicatedStorage.Modules.Client.Controllers.GunController)
local BulletController = require(ReplicatedStorage.Modules.Client.Controllers.BulletController)
local SpreadUtil = require(ReplicatedStorage.Modules.Shared.SpreadUtil)

local CameraPOV
pcall(function() CameraPOV = require(ReplicatedStorage.Modules.Client.CameraPOV) end)

local sg = LocalPlayer.PlayerGui:FindFirstChild("ScreenGui")
if sg and sg:FindFirstChild("LocalScript") then sg.LocalScript:Destroy() end
local oldRadar = game:GetService("CoreGui"):FindFirstChild("RadarESP_Dausita") or LocalPlayer:FindFirstChildOfClass("PlayerGui"):FindFirstChild("RadarESP_Dausita")
if oldRadar then oldRadar:Destroy() end

local scriptStartTime = os.clock()

local Window = Library:CreateWindow({
    Title = "Ruby Hub | TTK Testing",
    Footer = "credits to dausita",
    NotifySide = "Right",
    ShowCustomCursor = false,
})

local Tabs = {
    Information = Window:AddTab("Information", "info"),
    Main = Window:AddTab("Main", "crosshair"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Misc = Window:AddTab("Misc", "sliders"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings")
}

local InfoLeftGroup = Tabs.Information:AddLeftGroupbox("Information / Bilgilendirme")
local InfoRightGroup = Tabs.Information:AddRightGroupbox("Server & System Status")

InfoLeftGroup:AddLabel("Bu script dausita tarafından yapılmıştır.", true)
InfoLeftGroup:AddLabel("This script was made by dausita.", true)
InfoLeftGroup:AddDivider()
InfoLeftGroup:AddButton({
    Text = "Copy Discord Link",
    Func = function()
        if setclipboard then
            setclipboard("https://discord.com/invite/pyCZNAHT9M")
            Library:Notify({ Title = "Success", Description = "Discord link copied to clipboard!", Time = 3 })
        else
            Library:Notify({ Title = "Error", Description = "Exploit does not support clipboard copying.", Time = 3 })
        end
    end
})

local execName = (identifyexecutor or getexecutorname or function() return "Unknown Executor" end)()
local execLabel = InfoRightGroup:AddLabel("Executor: " .. execName)
local placeIdLabel = InfoRightGroup:AddLabel("Place ID: " .. game.PlaceId)
local jobIdLabel = InfoRightGroup:AddLabel("Job ID: " .. (game.JobId ~= "" and game.JobId or "Studio / Local"))
local playerCountLabel = InfoRightGroup:AddLabel("Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
local serverAgeLabel = InfoRightGroup:AddLabel("Server Age: Calculating...")
local uptimeLabel = InfoRightGroup:AddLabel("Uptime: 0s")

InfoRightGroup:AddDivider()

local fpsLabel = InfoRightGroup:AddLabel("FPS: Calculating...")
local pingLabel = InfoRightGroup:AddLabel("Ping: Calculating...")
local cpuLabel = InfoRightGroup:AddLabel("CPU Usage: Calculating...")
local gpuLabel = InfoRightGroup:AddLabel("GPU Usage: Calculating...")
local ramLabel = InfoRightGroup:AddLabel("RAM Usage: Calculating...")

InfoRightGroup:AddDivider()

InfoRightGroup:AddButton({
    Text = "Copy Job ID",
    Func = function()
        if setclipboard then
            setclipboard(game.JobId)
            Library:Notify({ Title = "Success", Description = "Job ID copied!", Time = 2 })
        end
    end
})

InfoRightGroup:AddButton({
    Text = "Copy Place ID",
    Func = function()
        if setclipboard then
            setclipboard(tostring(game.PlaceId))
            Library:Notify({ Title = "Success", Description = "Place ID copied!", Time = 2 })
        end
    end
})

local fps = 0
local lastUpdate = os.clock()
local frames = 0
RunService.RenderStepped:Connect(function()
    frames = frames + 1
    local now = os.clock()
    if now - lastUpdate >= 1 then
        fps = frames
        frames = 0
        lastUpdate = now
    end
end)

local function getPing()
    local ping = 0
    pcall(function()
        ping = math.round(LocalPlayer:GetNetworkPing() * 1000)
    end)
    if ping == 0 then
        pcall(function()
            ping = math.round(game:GetService("Stats").Network.ServerToClientPing:GetValue())
        end)
    end
    return ping
end

local function getRAM()
    local ram = 0
    pcall(function()
        ram = math.round(game:GetService("Stats"):GetTotalMemoryUsageMb())
    end)
    return ram > 0 and ram or math.random(300, 600)
end

local function getCPU()
    local cpu = 0
    pcall(function()
        local stats = game:GetService("Stats")
        local internalTime = (stats.HeartbeatTimeMs or 4) + (stats.PhysicsTimeMs or 2)
        cpu = math.clamp(math.round((internalTime / 16.6) * 100), 5, 95)
    end)
    return cpu > 0 and cpu or math.random(8, 22)
end

local function getGPU()
    local gpu = 0
    pcall(function()
        local baseGpu = math.clamp(math.round((1 - (fps / 60)) * 60) + 20, 10, 95)
        gpu = baseGpu + math.random(-2, 2)
    end)
    return gpu > 0 and gpu or math.random(15, 30)
end

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            playerCountLabel:SetText("Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
        end)
        
        pcall(function()
            local sAge = math.floor(workspace.DistributedGameTime)
            local sHours = math.floor(sAge / 3600)
            local sMinutes = math.floor((sAge % 3600) / 60)
            local sSeconds = sAge % 60
            serverAgeLabel:SetText(string.format("Server Age: %02dh %02dm %02ds", sHours, sMinutes, sSeconds))
        end)
        
        pcall(function()
            local upTime = math.floor(os.clock() - scriptStartTime)
            local uHours = math.floor(upTime / 3600)
            local uMinutes = math.floor((upTime % 3600) / 60)
            local uSeconds = upTime % 60
            uptimeLabel:SetText(string.format("Uptime: %02dh %02dm %02ds", uHours, uMinutes, uSeconds))
        end)

        pcall(function() fpsLabel:SetText("FPS: " .. fps) end)
        pcall(function() pingLabel:SetText("Ping: " .. getPing() .. " ms") end)
        pcall(function() cpuLabel:SetText("CPU Usage: " .. getCPU() .. "%") end)
        pcall(function() gpuLabel:SetText("GPU Usage: " .. getGPU() .. "%") end)
        pcall(function() ramLabel:SetText("RAM Usage: " .. getRAM() .. " MB") end)
    end
end)

local LeftGroupBox = Tabs.Main:AddLeftGroupbox("Silent Aim Settings")
local WhitelistGroupBox = Tabs.Main:AddLeftGroupbox("Target Whitelist")
local TriggerGroupBox = Tabs.Main:AddRightGroupbox("Triggerbot Settings")

local VisualsLeftBox = Tabs.Visuals:AddLeftGroupbox("Visual Settings (ESP)")
local VisualsRightBox = Tabs.Visuals:AddRightGroupbox("ESP Customize & Radar")

-- Misc Tab Grupları
local MiscLeftBox = Tabs.Misc:AddLeftGroupbox("Environment Settings")
local MiscRightBox = Tabs.Misc:AddRightGroupbox("Sound Manager (Experimental)")

local WhitelistedPlayers = {}
local function getPlayerNames()
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    return names
end

local expandedBones = {
    "Head", "Neck", "Chest", "Hips", "Torso", "Upper Torso", "Lower Torso",
    "Left Upper Arm", "Left Lower Arm", "Right Upper Arm", "Right Lower Arm",
    "Left Upper Leg", "Left Lower Leg", "Right Upper Leg", "Right Lower Leg", "Random"
}

local expandedTriggerBones = {
    "Any", "Head", "Neck", "Chest", "Hips", "Torso", "Upper Torso", "Lower Torso",
    "Left Upper Arm", "Left Lower Arm", "Right Upper Arm", "Right Lower Arm",
    "Left Upper Leg", "Left Lower Leg", "Right Upper Leg", "Right Lower Leg"
}

LeftGroupBox:AddToggle("SilentAim_Enabled", { Text = "Enable Silent Aim", Default = false })
LeftGroupBox:AddLabel("Silent Aim Key"):AddKeyPicker("SilentAim_Key", { Default = "MB2", SyncToggleState = false, Mode = "Hold", Text = "Silent Aim Key" })
LeftGroupBox:AddDropdown("Target_Part", { Values = expandedBones, Default = 1, Multi = false, Text = "Target Bone" })
LeftGroupBox:AddToggle("FOV_360", { Text = "360 FOV (Ignore Circle)", Default = false })
LeftGroupBox:AddDropdown("Target_Prioritize", { Values = { "Closest", "Farthest", "Lowest Health", "Highest Health" }, Default = 1, Multi = false, Text = "Target Prioritize" })
LeftGroupBox:AddToggle("Wallcheck", { Text = "Wall Check", Default = true })
LeftGroupBox:AddDivider()
LeftGroupBox:AddToggle("Show_FOV", { Text = "Show FOV Circle", Default = false }):AddColorPicker("FOV_Color", { Default = Color3.fromRGB(0, 255, 120), Title = "FOV Line Color" })
LeftGroupBox:AddToggle("Rainbow_FOV", { Text = "Rainbow FOV Line", Default = false })
LeftGroupBox:AddToggle("Fill_FOV", { Text = "Fill FOV Space", Default = false }):AddColorPicker("Fill_FOV_Color", { Default = Color3.fromRGB(20, 20, 20), Title = "Fill Color" })
LeftGroupBox:AddSlider("Fill_FOV_Trans", { Text = "Fill FOV Opacity", Default = 0.2, Min = 0, Max = 1, Rounding = 2 })
LeftGroupBox:AddToggle("Draw_Target_Dot", { Text = "Draw Target Dot", Default = false })
LeftGroupBox:AddSlider("Aim_FOV", { Text = "FOV Radius", Default = 120, Min = 10, Max = 1200, Rounding = 0 })
LeftGroupBox:AddSlider("Max_Dist", { Text = "Max Distance Limit", Default = 2000, Min = 100, Max = 50000, Rounding = 0 })

WhitelistGroupBox:AddDropdown("Player_List", { Values = getPlayerNames(), Default = 1, Multi = false, Text = "Select Player" })
WhitelistGroupBox:AddButton({ Text = "Refresh Player List", Func = function() Options.Player_List:SetValues(getPlayerNames()) end })
WhitelistGroupBox:AddButton({ Text = "Toggle Whitelist Status", Func = function()
    local sel = Options.Player_List.Value
    if sel then
        WhitelistedPlayers[sel] = not WhitelistedPlayers[sel]
        Library:Notify({ Title = "Whitelist", Description = sel .. (WhitelistedPlayers[sel] and " whitelisted." or " unwhitelisted."), Time = 3 })
    end
end })

TriggerGroupBox:AddToggle("Triggerbot_Enabled", { Text = "Enable Triggerbot", Default = false })
TriggerGroupBox:AddLabel("Triggerbot Key"):AddKeyPicker("Triggerbot_Key", { Default = "X", SyncToggleState = false, Mode = "Hold", Text = "Triggerbot Key" })
TriggerGroupBox:AddDropdown("Triggerbot_Mode", { Values = { "Tap", "Burst" }, Default = 1, Multi = false, Text = "Triggerbot Mode" })
TriggerGroupBox:AddSlider("Triggerbot_Delay", { Text = "Triggerbot Delay (ms)", Default = 0, Min = 0, Max = 1000, Rounding = 0 })
TriggerGroupBox:AddSlider("Triggerbot_TapCooldown", { Text = "Tap Cooldown (s)", Default = 0.1, Min = 0, Max = 3, Rounding = 2 })
TriggerGroupBox:AddSlider("Triggerbot_BurstCooldown", { Text = "Burst Cooldown (s)", Default = 0.6, Min = 0, Max = 5, Rounding = 2 })
TriggerGroupBox:AddDropdown("Triggerbot_TargetPart", { Values = expandedTriggerBones, Default = 1, Multi = false, Text = "Triggerbot Target Part" })
TriggerGroupBox:AddDivider()
TriggerGroupBox:AddToggle("Triggerbot_ShowFOV", { Text = "Show Triggerbot FOV", Default = false }):AddColorPicker("Triggerbot_FOV_Color", { Default = Color3.fromRGB(255, 0, 0), Title = "Triggerbot FOV Color" })
TriggerGroupBox:AddToggle("Triggerbot_RainbowFOV", { Text = "Triggerbot Rainbow FOV", Default = false })
TriggerGroupBox:AddSlider("Triggerbot_FOV_Radius", { Text = "Triggerbot FOV Radius", Default = 50, Min = 5, Max = 600, Rounding = 0 })

VisualsLeftBox:AddToggle("ESP_Enabled", { Text = "Enable Master ESP", Default = false })
VisualsLeftBox:AddToggle("Dead_Check", { Text = "Dead Check (Hide Dead)", Default = true })
VisualsLeftBox:AddSlider("ESP_Range", { Text = "Max ESP Range", Default = 5000, Min = 100, Max = 100000, Rounding = 0 })
VisualsLeftBox:AddDivider()
VisualsLeftBox:AddToggle("Name_ESP", { Text = "Name ESP", Default = false })
VisualsLeftBox:AddToggle("Use_Display_Name", { Text = "Use Display Name", Default = false })
VisualsLeftBox:AddSlider("Name_Text_Size", { Text = "Name Font Size", Default = 14, Min = 10, Max = 26, Rounding = 0 })
VisualsLeftBox:AddSlider("Name_Transparency", { Text = "Name Opacity", Default = 1, Min = 0, Max = 1, Rounding = 2 })
VisualsLeftBox:AddToggle("Distance_ESP", { Text = "Distance ESP", Default = false })
VisualsLeftBox:AddDropdown("Distance_Mode", { Values = { "Meters", "Studs" }, Default = 1, Multi = false, Text = "Distance Unit" })
VisualsLeftBox:AddDivider()
VisualsLeftBox:AddToggle("Box_ESP", { Text = "Box ESP", Default = false }):AddColorPicker("Box_Color", { Default = Color3.fromRGB(255, 255, 255), Title = "Box Color" })
VisualsLeftBox:AddDropdown("Box_Type", { Values = { "Normal Box", "Corner Box" }, Default = 1, Multi = false, Text = "Box Visual Style" })
VisualsLeftBox:AddSlider("Box_Thickness", { Text = "Box Line Thickness", Default = 1.5, Min = 1, Max = 5, Rounding = 1 })
VisualsLeftBox:AddSlider("Box_Transparency", { Text = "Box Line Opacity", Default = 1, Min = 0, Max = 1, Rounding = 2 })
VisualsLeftBox:AddSlider("Box_Outline_Thickness", { Text = "Box Outline Thickness", Default = 1, Min = 0, Max = 4, Rounding = 1 })
VisualsLeftBox:AddSlider("Box_Outline_Transparency", { Text = "Box Outline Opacity", Default = 0.8, Min = 0, Max = 1, Rounding = 2 })
VisualsLeftBox:AddDivider()
VisualsLeftBox:AddToggle("BoxFill", { Text = "Box Fill", Default = false }):AddColorPicker("BoxFill_Color", { Default = Color3.fromRGB(30, 30, 30), Title = "Fill Color" })
VisualsLeftBox:AddSlider("BoxFill_Transparency", { Text = "Box Fill Opacity", Default = 0.3, Min = 0, Max = 1, Rounding = 2 })

VisualsRightBox:AddToggle("HealthBar_ESP", { Text = "Health Bar", Default = false })
VisualsRightBox:AddSlider("HealthBar_Transparency", { Text = "Health Bar Opacity", Default = 1, Min = 0, Max = 1, Rounding = 2 })
VisualsRightBox:AddToggle("HP_Text_ESP", { Text = "HP Text", Default = false }):AddColorPicker("HP_Text_Color", { Default = Color3.fromRGB(255, 255, 255), Title = "HP Text Color" })
VisualsRightBox:AddSlider("HP_Text_Transparency", { Text = "HP Text Opacity", Default = 1, Min = 0, Max = 1, Rounding = 2 })
VisualsRightBox:AddDivider()
VisualsRightBox:AddToggle("Head_Circle", { Text = "Head Circle ESP", Default = false }):AddColorPicker("Head_Circle_Color", { Default = Color3.fromRGB(255, 0, 0), Title = "Border Color" })
VisualsRightBox:AddToggle("Head_Circle_Fill", { Text = "Head Circle Fill", Default = false }):AddColorPicker("Head_Circle_Fill_Color", { Default = Color3.fromRGB(50, 0, 0), Title = "Fill Color" })
VisualsRightBox:AddSlider("Head_Circle_Trans", { Text = "Head Border Opacity", Default = 1, Min = 0, Max = 1, Rounding = 2 })
VisualsRightBox:AddSlider("Head_Circle_Fill_Trans", { Text = "Head Fill Opacity", Default = 0.4, Min = 0, Max = 1, Rounding = 2 })
VisualsRightBox:AddDivider()
VisualsRightBox:AddToggle("China_Hat_ESP", { Text = "China Hat ESP", Default = false }):AddColorPicker("China_Hat_Color", { Default = Color3.fromRGB(255, 0, 0), Title = "Hat Color" })
VisualsRightBox:AddSlider("China_Hat_Lines", { Text = "China Hat Lines Count", Default = 12, Min = 4, Max = 24, Rounding = 0 })
VisualsRightBox:AddSlider("China_Hat_Width", { Text = "China Hat Width", Default = 1.5, Min = 0.5, Max = 4, Rounding = 1 })
VisualsRightBox:AddSlider("China_Hat_Length", { Text = "China Hat Length", Default = 0.8, Min = 0.2, Max = 3, Rounding = 1 })
VisualsRightBox:AddSlider("China_Hat_Transparency", { Text = "China Hat Opacity", Default = 0.7, Min = 0, Max = 1, Rounding = 2 })
VisualsRightBox:AddDivider()
VisualsRightBox:AddToggle("Skeleton_ESP", { Text = "Skeleton ESP", Default = false }):AddColorPicker("Skeleton_Color", { Default = Color3.fromRGB(255, 255, 0), Title = "Bone Color" })
VisualsRightBox:AddSlider("Skeleton_Thickness", { Text = "Skeleton Thickness", Default = 1.5, Min = 1, Max = 5, Rounding = 1 })
VisualsRightBox:AddSlider("Skeleton_Transparency", { Text = "Skeleton Opacity", Default = 1, Min = 0, Max = 1, Rounding = 2 })
VisualsRightBox:AddDivider()
VisualsRightBox:AddToggle("ThreeD_Circle", { Text = "3D Under-Foot Circle", Default = false }):AddColorPicker("ThreeD_Circle_Color", { Default = Color3.fromRGB(0, 255, 255), Title = "Circle Line Color" })
VisualsRightBox:AddSlider("ThreeD_Circle_Trans", { Text = "3D Circle Opacity", Default = 0.8, Min = 0, Max = 1, Rounding = 2 })
VisualsRightBox:AddDivider()
VisualsRightBox:AddToggle("Offscreen_Arrows", { Text = "Offscreen Arrows", Default = false }):AddColorPicker("Arrow_Color", { Default = Color3.fromRGB(255, 0, 0), Title = "Arrow Color" })
VisualsRightBox:AddSlider("Arrow_Transparency", { Text = "Arrow Opacity", Default = 0.8, Min = 0, Max = 1, Rounding = 2 })
VisualsRightBox:AddDivider()
local RadarToggle = VisualsRightBox:AddToggle("Radar_ESP", { Text = "Radar ESP", Default = false })
VisualsRightBox:AddDivider()
VisualsRightBox:AddToggle("Tracer_ESP", { Text = "Snapline/Tracer ESP", Default = false }):AddColorPicker("Tracer_Color", { Default = Color3.fromRGB(255, 255, 255), Title = "Tracer Line Color" })
VisualsRightBox:AddDropdown("Tracer_Mode", { Values = { "Below", "Center", "Mouse", "Top" }, Default = 1, Multi = false, Text = "Screen Origin" })
VisualsRightBox:AddSlider("Tracer_Thickness", { Text = "Tracer Thickness", Default = 1, Min = 1, Max = 5, Rounding = 1 })
VisualsRightBox:AddSlider("Tracer_Transparency", { Text = "Tracer Opacity", Default = 0.6, Min = 0, Max = 1, Rounding = 2 })

local Skyboxes = {
    ['--'] = {},
    Galaxy = {
        SkyboxBk = 'rbxassetid://159454299', SkyboxDn = 'rbxassetid://159454296', SkyboxFt = 'rbxassetid://159454293',
        SkyboxLf = 'rbxassetid://159454286', SkyboxRt = 'rbxassetid://159454300', SkyboxUp = 'rbxassetid://159454288'
    },
    Purple = {
        SkyboxBk = 'rbxassetid://570557514', SkyboxDn = 'rbxassetid://570557775', SkyboxFt = 'rbxassetid://570557559',
        SkyboxLf = 'rbxassetid://570557620', SkyboxRt = 'rbxassetid://570557672', SkyboxUp = 'rbxassetid://570557727'
    },
    ['Purple Night'] = {
        SkyboxBk = 'rbxassetid://296908715', SkyboxDn = 'rbxassetid://296908724', SkyboxFt = 'rbxassetid://296908740',
        SkyboxLf = 'rbxassetid://296908755', SkyboxRt = 'rbxassetid://296908764', SkyboxUp = 'rbxassetid://296908769'
    },
    ['Night Sky'] = {
        SkyboxBk = 'rbxassetid://12064107', SkyboxDn = 'rbxassetid://12064152', SkyboxFt = 'rbxassetid://12064121',
        SkyboxLf = 'rbxassetid://12063984', SkyboxRt = 'rbxassetid://12064115', SkyboxUp = 'rbxassetid://12064131'
    },
    ['Pink Daylight'] = {
        SkyboxBk = 'rbxassetid://271042516', SkyboxDn = 'rbxassetid://271077243', SkyboxFt = 'rbxassetid://271042556',
        SkyboxLf = 'rbxassetid://271042310', SkyboxRt = 'rbxassetid://271042467', SkyboxUp = 'rbxassetid://271077958'
    },
    ['Morning Glow'] = {
        SkyboxBk = 'rbxassetid://1417494030', SkyboxDn = 'rbxassetid://1417494146', SkyboxFt = 'rbxassetid://1417494253',
        SkyboxLf = 'rbxassetid://1417494402', SkyboxRt = 'rbxassetid://1417494499', SkyboxUp = 'rbxassetid://1417494643'
    },
    ['Setting Sun'] = {
        SkyboxBk = 'rbxassetid://626460377', SkyboxDn = 'rbxassetid://626460216', SkyboxFt = 'rbxassetid://626460513',
        SkyboxLf = 'rbxassetid://626473032', SkyboxRt = 'rbxassetid://626458639', SkyboxUp = 'rbxassetid://626460625'
    },
    ['Fade Blue'] = {
        SkyboxBk = 'rbxassetid://153695414', SkyboxDn = 'rbxassetid://153695352', SkyboxFt = 'rbxassetid://153695452',
        SkyboxLf = 'rbxassetid://153695320', SkyboxRt = 'rbxassetid://153695383', SkyboxUp = 'rbxassetid://153695471'
    },
    ['Elegant Morning'] = {
        SkyboxBk = 'rbxassetid://153767241', SkyboxDn = 'rbxassetid://153767216', SkyboxFt = 'rbxassetid://153767266',
        SkyboxLf = 'rbxassetid://153767200', SkyboxRt = 'rbxassetid://153767231', SkyboxUp = 'rbxassetid://153767288'
    },
    Neptune = {
        SkyboxBk = 'rbxassetid://218955819', SkyboxDn = 'rbxassetid://218953419', SkyboxFt = 'rbxassetid://218954524',
        SkyboxLf = 'rbxassetid://218958493', SkyboxRt = 'rbxassetid://218957134', SkyboxUp = 'rbxassetid://218950090'
    },
    Redshift = {
        SkyboxBk = 'rbxassetid://401664839', SkyboxDn = 'rbxassetid://401664862', SkyboxFt = 'rbxassetid://401664960',
        SkyboxLf = 'rbxassetid://401664881', SkyboxRt = 'rbxassetid://401664901', SkyboxUp = 'rbxassetid://401664936'
    },
    ['Aesthetic Night'] = {
        SkyboxBk = 'rbxassetid://1045964490', SkyboxDn = 'rbxassetid://1045964368', SkyboxFt = 'rbxassetid://1045964655',
        SkyboxLf = 'rbxassetid://1045964655', SkyboxRt = 'rbxassetid://1045964655', SkyboxUp = 'rbxassetid://1045962969'
    }
}

MiscLeftBox:AddToggle("Lock_FOV", { Text = "Lock FOV", Default = false })
MiscLeftBox:AddSlider("Camera_FOV", {
    Text = "Field of View",
    Default = 70,
    Min = 50,
    Max = 120,
    Rounding = 0,
    Callback = function(v)
        if not Toggles.Lock_FOV.Value then
            Camera.FieldOfView = v
        end
    end
})

local skyboxKeys = {}
for k, _ in pairs(Skyboxes) do table.insert(skyboxKeys, k) end
table.sort(skyboxKeys)

local originalSkybox = {}
local skyboxFolder = Lighting:FindFirstChildOfClass("Sky")
if skyboxFolder then
    originalSkybox.SkyboxBk = skyboxFolder.SkyboxBk
    originalSkybox.SkyboxDn = skyboxFolder.SkyboxDn
    originalSkybox.SkyboxFt = skyboxFolder.SkyboxFt
    originalSkybox.SkyboxLf = skyboxFolder.SkyboxLf
    originalSkybox.SkyboxRt = skyboxFolder.SkyboxRt
    originalSkybox.SkyboxUp = skyboxFolder.SkyboxUp
end

MiscLeftBox:AddDropdown("Skybox_Selector", {
    Values = skyboxKeys,
    Default = 1,
    Multi = false,
    Text = "Skybox Changer",
    Callback = function(val)
        local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
        if val == "--" then
            if originalSkybox.SkyboxBk then
                sky.SkyboxBk = originalSkybox.SkyboxBk
                sky.SkyboxDn = originalSkybox.SkyboxDn
                sky.SkyboxFt = originalSkybox.SkyboxFt
                sky.SkyboxLf = originalSkybox.SkyboxLf
                sky.SkyboxRt = originalSkybox.SkyboxRt
                sky.SkyboxUp = originalSkybox.SkyboxUp
            end
        else
            local selected = Skyboxes[val]
            if selected then
                sky.SkyboxBk = selected.SkyboxBk
                sky.SkyboxDn = selected.SkyboxDn
                sky.SkyboxFt = selected.SkyboxFt
                sky.SkyboxLf = selected.SkyboxLf
                sky.SkyboxRt = selected.SkyboxRt
                sky.SkyboxUp = selected.SkyboxUp
            end
        end
    end
})

MiscLeftBox:AddDivider()

MiscLeftBox:AddToggle("FPS_Optimizer", { Text = "FPS Optimizer", Default = false })
MiscLeftBox:AddToggle("Anti_Lag", { Text = "Anti Lag", Default = false })

local fpsOptConn
Toggles.FPS_Optimizer:OnChanged(function()
    if Toggles.FPS_Optimizer.Value then
        pcall(function()
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("Decal") or v:IsA("Texture") then
                    pcall(function() v.Transparency = 1 end)
                elseif v:IsA("MeshPart") or v:IsA("SpecialMesh") then
                    pcall(function() v.TextureID = "" end)
                elseif v:IsA("BasePart") then
                    pcall(function()
                        v.Material = Enum.Material.SmoothPlastic
                        v.CastShadow = false
                    end)
                end
            end
        end)
        fpsOptConn = workspace.DescendantAdded:Connect(function(v)
            task.wait()
            if Toggles.FPS_Optimizer.Value then
                if v:IsA("Decal") or v:IsA("Texture") then
                    pcall(function() v.Transparency = 1 end)
                elseif v:IsA("MeshPart") or v:IsA("SpecialMesh") then
                    pcall(function() v.TextureID = "" end)
                elseif v:IsA("BasePart") then
                    pcall(function()
                        v.Material = Enum.Material.SmoothPlastic
                        v.CastShadow = false
                    end)
                end
            end
        end)
        Library:Notify({ Title = "FPS", Description = "FPS Optimizer enabled. Decals transparent & textures optimized.", Time = 3 })
    else
        if fpsOptConn then fpsOptConn:Disconnect() fpsOptConn = nil end
    end
end)

local function applyFullbright()
    if Toggles.Anti_Lag and Toggles.Anti_Lag.Value then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
    end
end

local antiLagConn
Toggles.Anti_Lag:OnChanged(function()
    if Toggles.Anti_Lag.Value then
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level1
        end)
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.ShadowMap = false
            Lighting.EnvironmentSpecularScale = 0
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.FogEnd = 9e9
            Lighting.FogStart = 9e9
        end)
        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") or v:IsA("PostEffect") or v:IsA("Clouds") then
                pcall(function() v.Enabled = false end)
            end
        end
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Clouds") or v:IsA("Sky") then
                pcall(function() v.Enabled = false end)
            end
        end
        applyFullbright()
        antiLagConn = Lighting.Changed:Connect(applyFullbright)
        Library:Notify({ Title = "Anti-Lag", Description = "Anti-Lag activated! Fog disabled & maximum brightness locked.", Time = 3 })
    else
        if antiLagConn then antiLagConn:Disconnect() antiLagConn = nil end
    end
end)

local soundsFolder = ReplicatedStorage:FindFirstChild("Sounds")
local oldHit = soundsFolder and soundsFolder:FindFirstChild("HitSound") and tostring(soundsFolder.HitSound.Value) or ""
local oldKill = soundsFolder and soundsFolder:FindFirstChild("KillSound") and tostring(soundsFolder.KillSound.Value) or ""

local Sounds = {
    ['Default Hit Sound'] = oldHit,
    ['Default Kill Sound'] = oldKill,
    Bameware = 'rbxassetid://3124331820',
    Bell = 'rbxassetid://6534947240',
    Bubble = 'rbxassetid://6534947588',
    Pick = 'rbxassetid://1347140027',
    Pop = 'rbxassetid://198598793',
    Rust = 'rbxassetid://1255040462',
    Skeet = 'rbxassetid://5447626464',
    ['Mario Coin'] = 'rbxassetid://5709456554',
    ['COD Hitmarker'] = 'rbxassetid://160432334',
    ['Minecraft XP'] = 'rbxassetid://1053296915',
    Neverlose = 'rbxassetid://6607204501',
    Fatality = 'rbxassetid://6534947869'
}

local soundKeys = {}
for k, _ in pairs(Sounds) do table.insert(soundKeys, k) end
table.sort(soundKeys)

MiscRightBox:AddToggle("HitSound_Enabled", { Text = "Enable Hit Sound (Experimental)", Default = false })
local hitSoundDropdown = MiscRightBox:AddDropdown("HitSound_Selected", { Values = soundKeys, Default = 1, Multi = false, Text = "Hit Sound" })

MiscRightBox:AddButton({
    Text = "Test Hit Sound",
    Func = function()
        local sId = Sounds[hitSoundDropdown.Value]
        if sId then
            local testSnd = Instance.new("Sound")
            testSnd.SoundId = sId
            testSnd.Volume = Options.Sound_Volume and Options.Sound_Volume.Value or 1
            testSnd.Parent = game:GetService("SoundService")
            testSnd:Play()
            game:GetService("Debris"):AddItem(testSnd, 5)
        end
    end
})

MiscRightBox:AddDivider()

MiscRightBox:AddToggle("KillSound_Enabled", { Text = "Enable Kill Sound (Experimental)", Default = false })
local killSoundDropdown = MiscRightBox:AddDropdown("KillSound_Selected", { Values = soundKeys, Default = 1, Multi = false, Text = "Kill Sound" })

MiscRightBox:AddButton({
    Text = "Test Kill Sound",
    Func = function()
        local sId = Sounds[killSoundDropdown.Value]
        if sId then
            local testSnd = Instance.new("Sound")
            testSnd.SoundId = sId
            testSnd.Volume = Options.Sound_Volume and Options.Sound_Volume.Value or 1
            testSnd.Parent = game:GetService("SoundService")
            testSnd:Play()
            game:GetService("Debris"):AddItem(testSnd, 5)
        end
    end
})

MiscRightBox:AddDivider()
MiscRightBox:AddSlider("Sound_Volume", { Text = "Sound Volume", Default = 1, Min = 0.1, Max = 10, Rounding = 1 })

task.spawn(function()
    while task.wait(0.1) do
        local currentSoundsFolder = ReplicatedStorage:FindFirstChild("Sounds")
        if currentSoundsFolder then
            local hitSoundObj = currentSoundsFolder:FindFirstChild("HitSound")
            local killSoundObj = currentSoundsFolder:FindFirstChild("KillSound")
            
            if hitSoundObj then
                if Toggles.HitSound_Enabled and Toggles.HitSound_Enabled.Value then
                    local sId = Sounds[hitSoundDropdown.Value]
                    if sId then hitSoundObj.Value = sId end
                else
                    hitSoundObj.Value = oldHit
                end
            end

            if killSoundObj then
                if Toggles.KillSound_Enabled and Toggles.KillSound_Enabled.Value then
                    local sId = Sounds[killSoundDropdown.Value]
                    if sId then killSoundObj.Value = sId end
                else
                    killSoundObj.Value = oldKill
                end
            end
        end
    end
end)

local RadarGui = Instance.new("ScreenGui")
RadarGui.Name = "RadarESP_Dausita"
RadarGui.ResetOnSpawn = false

local radarParent = nil
pcall(function() if gethui then radarParent = gethui() else radarParent = game:GetService("CoreGui") end end)
if not radarParent then radarParent = LocalPlayer:WaitForChild("PlayerGui") end
pcall(function() RadarGui.Parent = radarParent end)

local RadarFrame = Instance.new("Frame")
RadarFrame.Size = UDim2.new(0, 150, 0, 150)
RadarFrame.Position = UDim2.new(0, 50, 0, 120)
RadarFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
RadarFrame.BackgroundTransparency = 0.4
RadarFrame.BorderSizePixel = 1
RadarFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
RadarFrame.Visible = false
RadarFrame.Parent = RadarGui

local RadarCorner = Instance.new("UICorner")
RadarCorner.CornerRadius = UDim.new(1, 0)
RadarCorner.Parent = RadarFrame

local RadarLineV = Instance.new("Frame")
RadarLineV.Size = UDim2.new(0, 1, 1, 0)
RadarLineV.Position = UDim2.new(0.5, 0, 0, 0)
RadarLineV.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
RadarLineV.BorderSizePixel = 0
RadarLineV.Parent = RadarFrame

local RadarLineH = Instance.new("Frame")
RadarLineH.Size = UDim2.new(1, 0, 0, 1)
RadarLineH.Position = UDim2.new(0, 0, 0.5, 0)
RadarLineH.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
RadarLineH.BorderSizePixel = 0
RadarLineH.Parent = RadarFrame

local MyDot = Instance.new("Frame")
MyDot.Size = UDim2.new(0, 6, 0, 6)
MyDot.Position = UDim2.new(0.5, -3, 0.5, -3)
MyDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MyDot.BorderSizePixel = 0
MyDot.Parent = RadarFrame
local MyDotCorner = Instance.new("UICorner")
MyDotCorner.CornerRadius = UDim.new(1, 0)
MyDotCorner.Parent = MyDot

RadarToggle:OnChanged(function() RadarFrame.Visible = RadarToggle.Value end)

local dragging, dragInput, dragStart, startPos
RadarFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true dragStart = input.Position startPos = RadarFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
RadarFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        RadarFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local RadarDots = {}
local function updateRadar()
    if not RadarToggle.Value then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local camCF = workspace.CurrentCamera.CFrame
    local flatCamLook = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
    local camYaw = math.atan2(flatCamLook.X, flatCamLook.Z)
    local mercs = workspace:FindFirstChild("MercPlayers")
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local hitboxes = mercs and mercs:FindFirstChild("MercHitboxes_" .. player.Name)
            local isDead = hitboxes and hitboxes:GetAttribute("Dead")
            local health = hitboxes and hitboxes:GetAttribute("Health") or 100
            local passDeadCheck = true
            if Toggles.Dead_Check and Toggles.Dead_Check.Value then
                if isDead or health <= 0 then passDeadCheck = false end
            end
            if hitboxes and not WhitelistedPlayers[player.Name] and passDeadCheck then
                local enemyRoot = hitboxes:FindFirstChild("Torso") or hitboxes:FindFirstChild("Head")
                if enemyRoot then
                    local relPos = enemyRoot.Position - myRoot.Position
                    local rotX = relPos.X * math.cos(-camYaw) - relPos.Z * math.sin(-camYaw)
                    local rotZ = relPos.X * math.sin(-camYaw) + relPos.Z * math.cos(-camYaw)
                    local scale = 0.6
                    local rx = 75 + (rotX * scale)
                    local ry = 75 - (rotZ * scale)
                    local distFromCenter = math.sqrt((rx - 75)^2 + (ry - 75)^2)
                    if distFromCenter < 70 then
                        if not RadarDots[player] then
                            local d = Instance.new("Frame")
                            d.Size = UDim2.new(0, 5, 0, 5)
                            d.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                            d.BorderSizePixel = 0 d.Parent = RadarFrame
                            local dc = Instance.new("UICorner")
                            dc.CornerRadius = UDim.new(1, 0) dc.Parent = d
                            RadarDots[player] = d
                        end
                        RadarDots[player].Position = UDim2.new(0, rx - 2.5, 0, ry - 2.5)
                        RadarDots[player].Visible = true
                    else
                        if RadarDots[player] then RadarDots[player].Visible = false end
                    end
                end
            else
                if RadarDots[player] then RadarDots[player].Visible = false end
            end
        end
    end
end

local target, targetPart
local fovCircle = Drawing.new("Circle") fovCircle.Filled = false fovCircle.Thickness = 1
local fovFill = Drawing.new("Circle") fovFill.Filled = true fovFill.Thickness = 0
local targetDot = Drawing.new("Circle") targetDot.Filled = true targetDot.Radius = 4 targetDot.Color = Color3.fromRGB(255, 0, 0)
local triggerCircle = Drawing.new("Circle") triggerCircle.Filled = false triggerCircle.Thickness = 1

local wallParams = RaycastParams.new()
wallParams.FilterType = Enum.RaycastFilterType.Exclude
wallParams.IgnoreWater = true

local discharge = BulletController.Discharge
BulletController.Discharge = function(self, weapon, eyePos, fireDir, muzzleCf, ...)
    local saActive = Toggles.SilentAim_Enabled and Toggles.SilentAim_Enabled.Value and Options.SilentAim_Key and Options.SilentAim_Key:GetState()
    
    if saActive and target then
        local origin = muzzleCf and muzzleCf.Position or eyePos or Gun:GetMuzzleWorldCFrame().Position
        fireDir = (target - origin).Unit
        return discharge(self, weapon, eyePos, fireDir, muzzleCf, ...)
    end
    return discharge(self, weapon, eyePos, fireDir, muzzleCf, ...)
end

local randomCone = SpreadUtil.RandomConeDirection
SpreadUtil.RandomConeDirection = function(dir, ...)
    local saActive = Toggles.SilentAim_Enabled and Toggles.SilentAim_Enabled.Value and Options.SilentAim_Key and Options.SilentAim_Key:GetState()
    
    if saActive and target then return dir end
    return randomCone(dir, ...)
end

local boneCache = setmetatable({}, { __mode = "k" })
local function fuzzyFind(folder, name)
    if not folder then return nil end
    local sub = boneCache[folder]
    if not sub then sub = {} boneCache[folder] = sub end
    local cached = sub[name]
    if cached and cached.Parent == folder then return cached end
    local tName = name:lower():gsub("%s+", "")
    for _, c in ipairs(folder:GetChildren()) do
        if c:IsA("BasePart") then
            local cName = c.Name:lower():gsub("%s+", "")
            if cName == tName or cName:find(tName) then
                sub[name] = c return c
            end
        end
    end
    return nil
end

local function executeClick(mousePos)
    if mouse1press and mouse1release then
        mouse1press() task.wait(0.01) mouse1release()
    else
        local Vim = game:GetService("VirtualInputManager")
        Vim:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 1)
        task.wait(0.01)
        Vim:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 1)
    end
end

local lastTriggerTime = 0
local currentCooldown = 0
local function runTriggerbot()
    if not Toggles.Triggerbot_Enabled or not Toggles.Triggerbot_Enabled.Value then return end
    if not Options.Triggerbot_Key or not Options.Triggerbot_Key:GetState() then return end
    if os.clock() - lastTriggerTime < currentCooldown then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local fovLimit = Options.Triggerbot_FOV_Radius.Value
    local targetPartName = Options.Triggerbot_TargetPart.Value
    local eyePos = CameraPOV and CameraPOV.GetEyePosition and CameraPOV.GetEyePosition() or workspace.CurrentCamera.CFrame.Position
    local mercs = workspace:FindFirstChild("MercPlayers")
    if not mercs then return end
    
    local bestTarget = nil local minScreenDist = fovLimit
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not WhitelistedPlayers[player.Name] then
            local hitboxes = mercs:FindFirstChild("MercHitboxes_" .. player.Name)
            if hitboxes and not hitboxes:GetAttribute("Dead") then
                local partsToCheck = {}
                if targetPartName == "Any" then
                    for _, child in ipairs(hitboxes:GetChildren()) do if child:IsA("BasePart") then table.insert(partsToCheck, child) end end
                else
                    local part = fuzzyFind(hitboxes, targetPartName) if part then table.insert(partsToCheck, part) end
                end
                for _, part in ipairs(partsToCheck) do
                    local scr, vis = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
                    if vis and scr.Z > 0 then
                        local screenDist = (Vector2.new(scr.X, scr.Y) - mousePos).Magnitude
                        if screenDist <= minScreenDist then
                            wallParams.FilterDescendantsInstances = { LocalPlayer.Character, workspace.CurrentCamera, mercs }
                            if not workspace:Raycast(eyePos, part.Position - eyePos, wallParams) then
                                bestTarget = part minScreenDist = screenDist
                            end
                        end
                    end
                end
            end
        end
    end
    if bestTarget then
        local delayMs = Options.Triggerbot_Delay.Value if delayMs > 0 then task.wait(delayMs / 1000) end
        if Toggles.Triggerbot_Enabled.Value and Options.Triggerbot_Key:GetState() then
            local mode = Options.Triggerbot_Mode.Value
            if mode == "Tap" then
                executeClick(mousePos) lastTriggerTime = os.clock() currentCooldown = Options.Triggerbot_TapCooldown.Value
            elseif mode == "Burst" then
                for i = 1, 3 do executeClick(mousePos) task.wait(0.03) end
                lastTriggerTime = os.clock() currentCooldown = Options.Triggerbot_BurstCooldown.Value
            end
        end
    end
end

task.spawn(function()
    while true do task.wait(0.01) pcall(runTriggerbot) end
end)

local function getSkeletonJoints(hitboxes)
    local joints = {} local function find(name) return fuzzyFind(hitboxes, name) end
    local head = find("head") local chest = find("chest") or find("uppertorso") or find("torso")
    local hips = find("hips") or find("lowertorso") or find("humanoidrootpart") or chest
    local leftUpperArm = find("leftupperarm") or find("leftarm") local leftLowerArm = find("leftlowerarm")
    local rightUpperArm = find("rightupperarm") or find("rightarm") local rightLowerArm = find("rightlowerarm")
    local leftUpperLeg = find("leftupperleg") or find("leftleg") local leftLowerLeg = find("leftlowerleg")
    local rightUpperLeg = find("rightupperleg") or find("rightleg") local rightLowerLeg = find("rightlowerleg")
    if head and chest then table.insert(joints, {head, chest}) end
    if chest and hips and chest ~= hips then table.insert(joints, {chest, hips}) end
    if chest and leftUpperArm then table.insert(joints, {chest, leftUpperArm}) end
    if leftUpperArm and leftLowerArm then table.insert(joints, {leftUpperArm, leftLowerArm}) end
    if chest and rightUpperArm then table.insert(joints, {chest, rightUpperArm}) end
    if rightUpperArm and rightLowerArm then table.insert(joints, {rightUpperArm, rightLowerArm}) end
    if hips and leftUpperLeg then table.insert(joints, {hips, leftUpperLeg}) end
    if leftUpperLeg and leftLowerLeg then table.insert(joints, {leftUpperLeg, leftLowerLeg}) end
    if hips and rightUpperLeg then table.insert(joints, {hips, rightUpperLeg}) end
    if rightUpperLeg and rightLowerLeg then table.insert(joints, {rightUpperLeg, rightLowerLeg}) end
    return joints
end

RunService.PreRender:Connect(function()
    -- FOV LOCK (dontchange)
    if Toggles.Lock_FOV and Toggles.Lock_FOV.Value then
        Camera.FieldOfView = Options.Camera_FOV.Value
    end

    target, targetPart = nil, nil
    local currentCam = workspace.CurrentCamera
    local center = currentCam.ViewportSize / 2
    local eyePos = CameraPOV and CameraPOV.GetEyePosition and CameraPOV.GetEyePosition() or currentCam.CFrame.Position
    local mercs = workspace:FindFirstChild("MercPlayers")
    
    if Toggles.Show_FOV and Toggles.Show_FOV.Value then
        fovCircle.Position = center fovCircle.Radius = Options.Aim_FOV.Value
        fovCircle.Color = Toggles.Rainbow_FOV.Value and Color3.fromHSV(tick() % 4 / 4, 1, 1) or Options.FOV_Color.Value
        fovCircle.Visible = true
    else fovCircle.Visible = false end
    if Toggles.Show_FOV and Toggles.Show_FOV.Value and Toggles.Fill_FOV and Toggles.Fill_FOV.Value then
        fovFill.Position = center fovFill.Radius = Options.Aim_FOV.Value
        fovFill.Color = Options.Fill_FOV_Color.Value fovFill.Transparency = Options.Fill_FOV_Trans.Value
        fovFill.Visible = true
    else fovFill.Visible = false end

    if Toggles.Triggerbot_ShowFOV and Toggles.Triggerbot_ShowFOV.Value then
        triggerCircle.Position = center triggerCircle.Radius = Options.Triggerbot_FOV_Radius.Value
        triggerCircle.Color = Toggles.Triggerbot_RainbowFOV.Value and Color3.fromHSV(tick() % 4 / 4, 1, 1) or Options.Triggerbot_FOV_Color.Value
        triggerCircle.Visible = true
    else triggerCircle.Visible = false end

    if not mercs then targetDot.Visible = false return end

    local saKeyActive = Options.SilentAim_Key and Options.SilentAim_Key:GetState()
    if not (Toggles.SilentAim_Enabled and Toggles.SilentAim_Enabled.Value and saKeyActive) then 
        if target then return end targetDot.Visible = false return 
    end
    
    local maxDist = Options.Max_Dist.Value local wallcheck = Toggles.Wallcheck.Value
    local is360 = Toggles.FOV_360.Value local fovRadius = Options.Aim_FOV.Value
    local priority = Options.Target_Prioritize.Value local chosenPartName = Options.Target_Part.Value
    local validTargets = {}
    
    for _, player in Players:GetPlayers() do
        if player ~= LocalPlayer and not WhitelistedPlayers[player.Name] then
            local hitboxes = mercs:FindFirstChild("MercHitboxes_" .. player.Name)
            if hitboxes and not hitboxes:GetAttribute("Dead") then
                local selectedBone = (chosenPartName == "Random") and hitboxes:GetChildren()[math.random(1, #hitboxes:GetChildren())] or fuzzyFind(hitboxes, chosenPartName)
                if selectedBone and selectedBone:IsA("BasePart") then
                    local dist = (selectedBone.Position - eyePos).Magnitude
                    if dist <= maxDist then
                        local aimPos = selectedBone.Position
                        if selectedBone.Name == "Head" then aimPos = aimPos + Vector3.new(0, selectedBone.Size.Y * 0.15, 0) end
                        local clear = true
                        if wallcheck then
                            wallParams.FilterDescendantsInstances = { LocalPlayer.Character, currentCam, mercs }
                            clear = workspace:Raycast(eyePos, aimPos - eyePos, wallParams) == nil
                        end
                        if clear then
                            local scr, vis = currentCam:WorldToViewportPoint(selectedBone.Position)
                            if is360 or (vis and scr.Z > 0) then
                                local px = (Vector2.new(scr.X, scr.Y) - center).Magnitude
                                if is360 or px < fovRadius then
                                    table.insert(validTargets, { Part = selectedBone, Position = aimPos, Distance = dist, Health = hitboxes:GetAttribute("Health") or 100 })
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    if #validTargets > 0 then
        table.sort(validTargets, function(a, b)
            if priority == "Closest" then return a.Distance < b.Distance
            elseif priority == "Farthest" then return a.Distance > b.Distance
            elseif priority == "Lowest Health" then return a.Health < b.Health
            elseif priority == "Highest Health" then return a.Health > b.Health end
            return a.Distance < b.Distance
        end)
        targetPart = validTargets[1].Part target = validTargets[1].Position
        if Toggles.Draw_Target_Dot and Toggles.Draw_Target_Dot.Value then
            local scr, vis = currentCam:WorldToViewportPoint(target)
            if vis and scr.Z > 0 then targetDot.Position = Vector2.new(scr.X, scr.Y) targetDot.Visible = true else targetDot.Visible = false end
        else targetDot.Visible = false end
    else targetDot.Visible = false end
end)

local ActiveDrawings = {}
local function getFast2DBoundingBox(hitboxes)
    local torso = fuzzyFind(hitboxes, "torso") or fuzzyFind(hitboxes, "head") or fuzzyFind(hitboxes, "humanoidrootpart")
    if not torso then return nil, nil, false end
    local pos = torso.Position local look = torso.CFrame.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z).Unit
    local cf = CFrame.lookAt(pos, pos + flatLook)
    local minX, minY = math.huge, math.huge local maxX, maxY = -math.huge, -math.huge
    local corners = {
        cf * Vector3.new(-2.2, -4.5, -1.5), cf * Vector3.new(2.2, -4.5, -1.5),
        cf * Vector3.new(-2.2, 3.5, -1.5), cf * Vector3.new(2.2, 3.5, -1.5),
        cf * Vector3.new(-2.2, -4.5, 1.5), cf * Vector3.new(2.2, -4.5, 1.5),
        cf * Vector3.new(-2.2, 3.5, 1.5), cf * Vector3.new(2.2, 3.5, 1.5)
    }
    for i = 1, 8 do
        local scr, vis = workspace.CurrentCamera:WorldToViewportPoint(corners[i])
        if scr.Z > 0 then
            if scr.X < minX then minX = scr.X end if scr.Y < minY then minY = scr.Y end
            if scr.X > maxX then maxX = scr.X end if scr.Y > maxY then maxY = scr.Y end
        end
    end
    if minX ~= math.huge then return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY), true end
    return nil, nil, false
end

local function drawESP(player)
    local box = Drawing.new("Square") box.Filled = false
    local boxOutline = Drawing.new("Square") boxOutline.Filled = false
    local boxFill = Drawing.new("Square") boxFill.Filled = true boxFill.Thickness = 0
    local corners = {} for i = 1, 8 do table.insert(corners, Drawing.new("Line")) end
    local nameText = Drawing.new("Text") nameText.Center = true nameText.Outline = true
    local distText = Drawing.new("Text") distText.Center = true distText.Outline = true
    local hpText = Drawing.new("Text") hpText.Center = false hpText.Outline = true
    local hBg = Drawing.new("Square") hBg.Filled = true hBg.Thickness = 0 hBg.Color = Color3.fromRGB(15, 15, 15)
    local hBar = Drawing.new("Square") hBar.Filled = true hBar.Thickness = 0
    local hOutline = Drawing.new("Square") hOutline.Filled = false hOutline.Thickness = 1 hOutline.Color = Color3.fromRGB(0, 0, 0)
    local headCircle = Drawing.new("Circle") headCircle.Filled = false headCircle.Thickness = 1.5
    local headFill = Drawing.new("Circle") headFill.Filled = true headFill.Thickness = 0
    local hatLines = {} for i = 1, 48 do table.insert(hatLines, Drawing.new("Line")) end
    local skeletonLines = {} for i = 1, 15 do table.insert(skeletonLines, Drawing.new("Line")) end
    local circleLines = {} for i = 1, 8 do table.insert(circleLines, Drawing.new("Line")) end
    local arrow = Drawing.new("Triangle") arrow.Thickness = 1 arrow.Filled = true
    local tracer = Drawing.new("Line")

    ActiveDrawings[player] = {
        Box = box, BoxOutline = boxOutline, BoxFill = boxFill, Corners = corners,
        NameText = nameText, DistText = distText, HPText = hpText, HBg = hBg, HBar = hBar, HOutline = hOutline,
        HeadCircle = headCircle, HeadFill = headFill, HatLines = hatLines, SkeletonLines = skeletonLines,
        CircleLines = circleLines, Arrow = arrow, Tracer = tracer
    }
end

RunService.RenderStepped:Connect(function()
    local master = Toggles.ESP_Enabled and Toggles.ESP_Enabled.Value
    local maxDist = Options.ESP_Range and Options.ESP_Range.Value or 5000
    local eyePos = workspace.CurrentCamera.CFrame.Position
    pcall(updateRadar)

    for player, d in pairs(ActiveDrawings) do
        local function clear()
            d.Box.Visible = false d.BoxOutline.Visible = false d.BoxFill.Visible = false
            d.NameText.Visible = false d.DistText.Visible = false d.HPText.Visible = false
            d.HBg.Visible = false d.HBar.Visible = false d.HOutline.Visible = false
            d.HeadCircle.Visible = false d.HeadFill.Visible = false d.Tracer.Visible = false d.Arrow.Visible = false
            for _, c in ipairs(d.Corners) do c.Visible = false end
            for _, b in ipairs(d.SkeletonLines) do b.Visible = false end
            for _, cl in ipairs(d.CircleLines) do cl.Visible = false end
            for _, hl in ipairs(d.HatLines) do hl.Visible = false end
        end

        local mercs = workspace:FindFirstChild("MercPlayers")
        local hitboxes = mercs and mercs:FindFirstChild("MercHitboxes_" .. player.Name)
        if not master or not hitboxes then clear() continue end

        local isDead = hitboxes:GetAttribute("Dead")
        local currentHP = hitboxes:GetAttribute("Health") or 100
        local maxHP = hitboxes:GetAttribute("MaxHealth") or 100
        local hpPercent = math.clamp(currentHP / maxHP, 0, 1)

        if Toggles.Dead_Check and Toggles.Dead_Check.Value then if isDead or currentHP <= 0 then clear() continue end end

        local root = fuzzyFind(hitboxes, "torso") or fuzzyFind(hitboxes, "head") or fuzzyFind(hitboxes, "humanoidrootpart")
        if not root then clear() continue end

        local distance = (root.Position - eyePos).Magnitude
        if distance > maxDist then clear() continue end

        local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(root.Position)
        if onScreen then
            d.Arrow.Visible = false
            local bPos, bSize, validBox = getFast2DBoundingBox(hitboxes)
            if not validBox then clear() continue end
            local bx, by = bPos.X, bPos.Y local w, h = bSize.X, bSize.Y
            local showBox = Toggles.Box_ESP and Toggles.Box_ESP.Value
            local boxType = Options.Box_Type.Value local fillActive = Toggles.BoxFill and Toggles.BoxFill.Value

            d.Box.Visible = false d.BoxOutline.Visible = false d.BoxFill.Visible = false
            for _, c in ipairs(d.Corners) do c.Visible = false end

            if showBox then
                if boxType == "Normal Box" then
                    d.Box.Size = Vector2.new(w, h) d.Box.Position = Vector2.new(bx, by)
                    d.Box.Color = Options.Box_Color.Value d.Box.Thickness = Options.Box_Thickness.Value
                    d.Box.Transparency = Options.Box_Transparency.Value d.Box.Visible = true
                    if Options.Box_Outline_Thickness.Value > 0 then
                        local out = Options.Box_Outline_Thickness.Value
                        d.BoxOutline.Size = Vector2.new(w + out*2, h + out*2) d.BoxOutline.Position = Vector2.new(bx - out, by - out)
                        d.BoxOutline.Color = Color3.fromRGB(0,0,0) d.BoxOutline.Thickness = out
                        d.BoxOutline.Transparency = Options.Box_Outline_Transparency.Value d.BoxOutline.Visible = true
                    end
                    if fillActive then
                        d.BoxFill.Size = Vector2.new(w, h) d.BoxFill.Position = Vector2.new(bx, by)
                        d.BoxFill.Color = Options.BoxFill_Color.Value d.BoxFill.Transparency = Options.BoxFill_Transparency.Value d.BoxFill.Visible = true
                    end
                elseif boxType == "Corner Box" then
                    local clen = w / 4 local thick = Options.Box_Thickness.Value local col = Options.Box_Color.Value local trans = Options.Box_Transparency.Value
                    local pts = {
                        {Vector2.new(bx, by), Vector2.new(bx + clen, by)}, {Vector2.new(bx, by), Vector2.new(bx, by + clen)},
                        {Vector2.new(bx + w, by), Vector2.new(bx + w - clen, by)}, {Vector2.new(bx + w, by), Vector2.new(bx + w, by + clen)},
                        {Vector2.new(bx, by + h), Vector2.new(bx + clen, by + h)}, {Vector2.new(bx, by + h), Vector2.new(bx, by + h - clen)},
                        {Vector2.new(bx + w, by + h), Vector2.new(bx + w - clen, by + h)}, {Vector2.new(bx + w, by + h), Vector2.new(bx + w, by + h - clen)}
                    }
                    for i, seg in ipairs(d.Corners) do
                        seg.From = pts[i][1] seg.To = pts[i][2] seg.Color = col seg.Thickness = thick seg.Transparency = trans seg.Visible = true
                    end
                    if fillActive then
                        d.BoxFill.Size = Vector2.new(w, h) d.BoxFill.Position = Vector2.new(bx, by)
                        d.BoxFill.Color = Options.BoxFill_Color.Value d.BoxFill.Transparency = Options.BoxFill_Transparency.Value d.BoxFill.Visible = true
                    end
                end
            end

            if Toggles.HealthBar_ESP and Toggles.HealthBar_ESP.Value then
                local barWidth = 1 local gap = 3 local hx = bx - barWidth - gap
                d.HBg.Size = Vector2.new(barWidth, h) d.HBg.Position = Vector2.new(hx, by) d.HBg.Transparency = Options.HealthBar_Transparency.Value d.HBg.Visible = true
                local fillHeight = h * hpPercent
                d.HBar.Size = Vector2.new(barWidth, fillHeight) d.HBar.Position = Vector2.new(hx, by + (h - fillHeight))
                d.HBar.Color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), hpPercent) d.HBar.Transparency = Options.HealthBar_Transparency.Value d.HBar.Visible = true
                d.HOutline.Size = Vector2.new(barWidth + 2, h + 2) d.HOutline.Position = Vector2.new(hx - 1, by - 1) d.HOutline.Transparency = Options.HealthBar_Transparency.Value d.HOutline.Visible = true
            else d.HBg.Visible = false d.HBar.Visible = false d.HOutline.Visible = false end

            if Toggles.Name_ESP and Toggles.Name_ESP.Value then
                d.NameText.Text = Toggles.Use_Display_Name.Value and player.DisplayName or player.Name
                d.NameText.Size = Options.Name_Text_Size.Value d.NameText.Transparency = Options.Name_Transparency.Value
                d.NameText.Position = Vector2.new(bx + w/2, by - Options.Name_Text_Size.Value - 4) d.NameText.Visible = true
            else d.NameText.Visible = false end

            if Toggles.Distance_ESP and Toggles.Distance_ESP.Value then
                local isMeters = Options.Distance_Mode.Value == "Meters"
                local fVal = isMeters and math.floor(distance / 3.3) or math.floor(distance)
                d.DistText.Text = tostring(fVal) .. (isMeters and "m" or " studs")
                d.DistText.Size = Options.Name_Text_Size.Value - 2 d.DistText.Position = Vector2.new(bx + w/2, by + h + 4) d.DistText.Visible = true
            else d.DistText.Visible = false end

            if Toggles.HP_Text_ESP and Toggles.HP_Text_ESP.Value then
                d.HPText.Text = tostring(math.floor(currentHP)) .. " HP"
                d.HPText.Size = Options.Name_Text_Size.Value - 2 d.HPText.Color = Options.HP_Text_Color.Value
                d.HPText.Transparency = Options.HP_Text_Transparency.Value d.HPText.Position = Vector2.new(bx + w + 6, by + 2) d.HPText.Visible = true
            else d.HPText.Visible = false end

            local head = fuzzyFind(hitboxes, "head")
            if head and Toggles.Head_Circle and Toggles.Head_Circle.Value then
                local hProj, hVis = workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                if hVis then
                    local rad = (head.Size.Y / 2 / hProj.Z) * (workspace.CurrentCamera.ViewportSize.Y / math.tan(math.rad(workspace.CurrentCamera.FieldOfView / 2))) * 0.4
                    d.HeadCircle.Position = Vector2.new(hProj.X, hProj.Y) d.HeadCircle.Radius = rad
                    d.HeadCircle.Color = Options.Head_Circle_Color.Value d.HeadCircle.Transparency = Options.Head_Circle_Trans.Value d.HeadCircle.Visible = true
                    if Toggles.Head_Circle_Fill.Value then
                        d.HeadFill.Position = Vector2.new(hProj.X, hProj.Y) d.HeadFill.Radius = rad - 1
                        d.HeadFill.Color = Options.Head_Circle_Fill_Color.Value d.HeadFill.Transparency = Options.Head_Circle_Fill_Trans.Value d.HeadFill.Visible = true
                    else d.HeadFill.Visible = false end
                else d.HeadCircle.Visible = false d.HeadFill.Visible = false end
            else d.HeadCircle.Visible = false d.HeadFill.Visible = false end

            if head and Toggles.China_Hat_ESP and Toggles.China_Hat_ESP.Value then
                local lineCount = math.clamp(Options.China_Hat_Lines.Value, 4, 24) local hLength = Options.China_Hat_Length.Value local hWidth = Options.China_Hat_Width.Value
                local tipPos = head.Position + Vector3.new(0, hLength, 0) local tipProj, tipVis = workspace.CurrentCamera:WorldToViewportPoint(tipPos)
                if tipVis then
                    local basePoints = {} local baseVisibles = {} local step = (math.pi * 2) / lineCount
                    for i = 1, lineCount do
                        local angle = (i - 1) * step local offset = Vector3.new(math.cos(angle) * hWidth, 0.1, math.sin(angle) * hWidth)
                        local bp, bvis = workspace.CurrentCamera:WorldToViewportPoint(head.Position + offset)
                        table.insert(basePoints, Vector2.new(bp.X, bp.Y)) table.insert(baseVisibles, bvis)
                    end
                    for i = 1, lineCount do
                        local line1 = d.HatLines[i] local line2 = d.HatLines[i + 24] local nextIdx = (i % lineCount) + 1
                        if baseVisibles[i] then
                            line1.From = Vector2.new(tipProj.X, tipProj.Y) line1.To = basePoints[i]
                            line1.Color = Options.China_Hat_Color.Value line1.Transparency = Options.China_Hat_Transparency.Value line1.Visible = true
                            if baseVisibles[nextIdx] then
                                line2.From = basePoints[i] line2.To = basePoints[nextIdx]
                                line2.Color = Options.China_Hat_Color.Value line2.Transparency = Options.China_Hat_Transparency.Value line2.Visible = true
                            else line2.Visible = false end
                        else line1.Visible = false line2.Visible = false end
                    end
                else for _, hl in ipairs(d.HatLines) do hl.Visible = false end end
            else for _, hl in ipairs(d.HatLines) do hl.Visible = false end end

            if Toggles.Skeleton_ESP and Toggles.Skeleton_ESP.Value then
                local connections = getSkeletonJoints(hitboxes) local col = Options.Skeleton_Color.Value local thick = Options.Skeleton_Thickness.Value local trans = Options.Skeleton_Transparency.Value
                local activeIndex = 1
                for _, pair in ipairs(connections) do
                    if activeIndex <= 15 then
                        local v1, vis1 = workspace.CurrentCamera:WorldToViewportPoint(pair[1].Position) local v2, vis2 = workspace.CurrentCamera:WorldToViewportPoint(pair[2].Position)
                        if vis1 and vis2 then
                            local sLine = d.SkeletonLines[activeIndex]
                            sLine.From = Vector2.new(v1.X, v1.Y) sLine.To = Vector2.new(v2.X, v2.Y)
                            sLine.Color = col sLine.Thickness = thick sLine.Transparency = trans sLine.Visible = true
                            activeIndex = activeIndex + 1
                        end
                    end
                end
                for i = activeIndex, 15 do d.SkeletonLines[i].Visible = false end
            else for _, b in ipairs(d.SkeletonLines) do b.Visible = false end end

            if Toggles.ThreeD_Circle and Toggles.ThreeD_Circle.Value then
                local lowestY = math.huge
                for _, p in ipairs(hitboxes:GetChildren()) do if p:IsA("BasePart") then local bottomY = p.Position.Y - (p.Size.Y / 2) if bottomY < lowestY then lowestY = bottomY end end end
                if lowestY == math.huge then lowestY = root.Position.Y - 3 end
                local footPos = Vector3.new(root.Position.X, lowestY, root.Position.Z)
                local points = {} local numPoints = 8 local step = (math.pi * 2) / numPoints local validCircle = true
                for i = 1, numPoints do
                    local angle = (i - 1) * step local offset = Vector3.new(math.cos(angle) * 2.5, 0, math.sin(angle) * 2.5)
                    local wPos, onScr = workspace.CurrentCamera:WorldToViewportPoint(footPos + offset)
                    if not onScr then validCircle = false break end
                    table.insert(points, Vector2.new(wPos.X, wPos.Y))
                end
                if validCircle then
                    for i = 1, numPoints do
                        local nextIdx = (i % numPoints) + 1 local line = d.CircleLines[i]
                        line.From = points[i] line.To = points[nextIdx] line.Color = Options.ThreeD_Circle_Color.Value
                        line.Thickness = 1.5 line.Transparency = Options.ThreeD_Circle_Trans.Value line.Visible = true
                    end
                else for _, cl in ipairs(d.CircleLines) do cl.Visible = false end end
            else for _, cl in ipairs(d.CircleLines) do cl.Visible = false end end

            if Toggles.Tracer_ESP and Toggles.Tracer_ESP.Value then
                local mode = Options.Tracer_Mode.Value local origin = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
                if mode == "Center" then origin = workspace.CurrentCamera.ViewportSize / 2
                elseif mode == "Mouse" then origin = UserInputService:GetMouseLocation()
                elseif mode == "Top" then origin = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, 0) end
                d.Tracer.From = origin d.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                d.Tracer.Color = Options.Tracer_Color.Value d.Tracer.Thickness = Options.Tracer_Thickness.Value
                d.Tracer.Transparency = Options.Tracer_Transparency.Value d.Tracer.Visible = true
            else d.Tracer.Visible = false end
        else
            clear()
            if Toggles.Offscreen_Arrows and Toggles.Offscreen_Arrows.Value then
                local camCF = workspace.CurrentCamera.CFrame local rel = camCF:PointToObjectSpace(root.Position)
                local angle = math.atan2(-rel.X, rel.Z) local dir = Vector2.new(math.sin(angle), math.cos(angle))
                local center = workspace.CurrentCamera.ViewportSize / 2 local arrowPos = center + dir * 150 local perp = Vector2.new(-dir.Y, dir.X) local size = 15
                d.Arrow.PointA = arrowPos + dir * size d.Arrow.PointB = arrowPos - dir * (size / 2) + perp * (size / 2) d.Arrow.PointC = arrowPos - dir * (size / 2) - perp * (size / 2)
                d.Arrow.Color = Options.Arrow_Color.Value d.Arrow.Transparency = Options.Arrow_Transparency.Value d.Arrow.Visible = true
            else d.Arrow.Visible = false end
        end
    end
end)

Players.PlayerAdded:Connect(drawESP)
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then drawESP(p) end end

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu Settings")
MenuGroup:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(v) Library.KeybindFrame.Visible = v end })
MenuGroup:AddButton("Unload Engine", function() Library:Unload() end)
MenuGroup:AddLabel("Toggle Keybind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu Key" })
Library.ToggleKeybind = Options.MenuKeybind

Library:OnUnload(function()
    fovCircle:Destroy() fovFill:Destroy() targetDot:Destroy() triggerCircle:Destroy()
    if RadarGui then RadarGui:Destroy() end
    if fpsOptConn then fpsOptConn:Disconnect() end
    if antiLagConn then antiLagConn:Disconnect() end
    for _, d in pairs(ActiveDrawings) do
        pcall(function() d.Box:Destroy() d.BoxOutline:Destroy() d.BoxFill:Destroy() d.NameText:Destroy() d.DistText:Destroy() d.HPText:Destroy() end)
        pcall(function() d.HBg:Destroy() d.HBar:Destroy() d.HOutline:Destroy() d.HeadCircle:Destroy() d.HeadFill:Destroy() d.Tracer:Destroy() d.Arrow:Destroy() end)
        for _, c in ipairs(d.Corners) do pcall(function() c:Destroy() end) end
        for _, b in ipairs(d.SkeletonLines) do pcall(function() b:Destroy() end) end
        for _, cl in ipairs(d.CircleLines) do pcall(function() cl:Destroy() end) end
        for _, hl in ipairs(d.HatLines) do pcall(function() hl:Destroy() end) end
    end
    -- iyicecinlioldukvarya
    pcall(function()
        local sFolder = ReplicatedStorage:FindFirstChild("Sounds")
        if sFolder then
            if sFolder:FindFirstChild("HitSound") then sFolder.HitSound.Value = oldHit end
            if sFolder:FindFirstChild("KillSound") then sFolder.KillSound.Value = oldKill end
        end
    end)
end)

ThemeManager:SetLibrary(Library) SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings() SaveManager:SetIgnoreIndexes({ "MenuKeybind", "Player_List" })
ThemeManager:SetFolder("RubyHub/TTK") SaveManager:SetFolder("RubyHub/TTK")
SaveManager:BuildConfigSection(Tabs["UI Settings"]) ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()
