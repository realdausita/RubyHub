-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local StatsService = game:GetService("Stats")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

-- Environment Setup & Platform Detection
local LocalPlayer = Players.LocalPlayer
local parentTarget = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Cleanup Old UI
if parentTarget:FindFirstChild("RubyHubGui") then
    parentTarget.RubyHubGui:Destroy()
end

-- ScreenGui
local RubyHubGui = Instance.new("ScreenGui")
RubyHubGui.Name = "RubyHubGui"
RubyHubGui.ResetOnSpawn = false
RubyHubGui.Parent = parentTarget

-- Global States
local selectedScripts = {}
local multiSelectActive = false
local settingsOpen = false
local wasSettingsOpenBeforeClose = false
local isMinimized = false
local isTransparent = false
local isAcrylic = false
local isUIOpen = true
local isAnimating = false
local hideUsername = false
local streamerModeEnabled = false
local streamerName = "Ruby On Top!"
local currentKeybind = Enum.KeyCode.RightControl
local listeningForKey = false
local antiAfkConnection = nil

-- Theme Configuration
local Themes = {
    ["Amethyst (Purple)"] = {
        Start = Color3.fromRGB(140, 70, 255),
        End = Color3.fromRGB(45, 15, 95),
        Accent = Color3.fromRGB(175, 115, 255)
    },
    ["Ruby (Red)"] = {
        Start = Color3.fromRGB(245, 45, 80),
        End = Color3.fromRGB(110, 10, 30),
        Accent = Color3.fromRGB(255, 90, 120)
    },
    ["Sapphire (Blue)"] = {
        Start = Color3.fromRGB(30, 140, 250),
        End = Color3.fromRGB(10, 40, 110),
        Accent = Color3.fromRGB(90, 180, 255)
    },
    ["Emerald (Green)"] = {
        Start = Color3.fromRGB(0, 220, 130),
        End = Color3.fromRGB(0, 70, 40),
        Accent = Color3.fromRGB(50, 255, 180)
    },
    ["Vaporwave (Sunset)"] = {
        Start = Color3.fromRGB(255, 80, 180),
        End = Color3.fromRGB(80, 20, 180),
        Accent = Color3.fromRGB(255, 150, 220)
    },
    ["Gold (Luxury)"] = {
        Start = Color3.fromRGB(255, 200, 50),
        End = Color3.fromRGB(100, 70, 10),
        Accent = Color3.fromRGB(255, 220, 110)
    },
    ["Cyberpunk (Neon)"] = {
        Start = Color3.fromRGB(255, 230, 0),
        End = Color3.fromRGB(255, 0, 110),
        Accent = Color3.fromRGB(0, 240, 255)
    },
    ["Midnight (Dark Ocean)"] = {
        Start = Color3.fromRGB(20, 80, 160),
        End = Color3.fromRGB(5, 15, 45),
        Accent = Color3.fromRGB(70, 160, 255)
    },
    ["Sakura (Soft Pink)"] = {
        Start = Color3.fromRGB(255, 140, 190),
        End = Color3.fromRGB(140, 40, 100),
        Accent = Color3.fromRGB(255, 180, 220)
    },
    ["Matrix (Lime)"] = {
        Start = Color3.fromRGB(50, 255, 80),
        End = Color3.fromRGB(10, 80, 20),
        Accent = Color3.fromRGB(120, 255, 140)
    },
    ["Blood Orange (Fire)"] = {
        Start = Color3.fromRGB(255, 100, 0),
        End = Color3.fromRGB(120, 20, 0),
        Accent = Color3.fromRGB(255, 150, 50)
    },
    ["Ocean Teal (Cyan)"] = {
        Start = Color3.fromRGB(0, 210, 220),
        End = Color3.fromRGB(0, 70, 100),
        Accent = Color3.fromRGB(100, 240, 255)
    }
}
local activeTheme = Themes["Amethyst (Purple)"]

-- Tracking Tables
local gradientObjects = {}
local accentObjects = {}
local transparentFrames = {}

-- Dimensions
local mainWidth = isMobile and 350 or 380
local mainHeight = 340

-- ==================== ADVANCED STREAMER MODE (ESC / TAB MASKING) ====================

local origName = LocalPlayer.Name
local origDisplayName = LocalPlayer.DisplayName

local oldIndex
pcall(function()
    if hookmetamethod then
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if streamerModeEnabled and not checkcaller() then
                if typeof(self) == "Instance" and self:IsA("Player") and self == LocalPlayer then
                    if key == "Name" or key == "DisplayName" then
                        return streamerName
                    end
                end
            end
            return oldIndex(self, key)
        end))
    end
end)

local function sanitizeText(str)
    if not streamerModeEnabled then return str end
    if type(str) ~= "string" then return str end
    if origName ~= "" and string.find(str, origName) then
        str = string.gsub(str, origName, streamerName)
    end
    if origDisplayName ~= "" and string.find(str, origDisplayName) then
        str = string.gsub(str, origDisplayName, streamerName)
    end
    return str
end

local function applyStreamerMaskToObj(obj)
    if not streamerModeEnabled then return end
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        if obj.Text and obj.Text ~= "" then
            local newText = sanitizeText(obj.Text)
            if newText ~= obj.Text then
                obj.Text = newText
            end
        end
    end
end

-- Scan CoreGui & PlayerGui for ESC Menu / TAB Leaderboard
RunService.RenderStepped:Connect(function()
    if not streamerModeEnabled then return end
    pcall(function()
        for _, gui in ipairs(CoreGui:GetChildren()) do
            if gui.Name == "RobloxGui" or gui.Name == "PlayerList" or gui.Name == "CoreGui" then
                for _, desc in ipairs(gui:GetDescendants()) do
                    applyStreamerMaskToObj(desc)
                end
            end
        end
    end)
    pcall(function()
        for _, desc in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            applyStreamerMaskToObj(desc)
        end
    end)
end)


-- ==================== NOTIFICATION SYSTEM ====================

local NotifyHolder = Instance.new("Frame")
NotifyHolder.Name = "NotifyHolder"
NotifyHolder.Size = UDim2.new(0, 240, 1, -20)
NotifyHolder.Position = UDim2.new(1, -15, 1, -15)
NotifyHolder.AnchorPoint = Vector2.new(1, 1)
NotifyHolder.BackgroundTransparency = 1
NotifyHolder.ZIndex = 100
NotifyHolder.Parent = RubyHubGui

local NotifyLayout = Instance.new("UIListLayout")
NotifyLayout.Padding = UDim.new(0, 8)
NotifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotifyLayout.Parent = NotifyHolder

local function Notify(title, message, notifyType, duration)
    duration = duration or 3.5
    notifyType = notifyType or "Success"

    local iconSymbol = "✓"
    local typeColor = Color3.fromRGB(80, 220, 120)

    if notifyType == "Warning" then
        iconSymbol = "⚠"
        typeColor = Color3.fromRGB(255, 190, 50)
    elseif notifyType == "Fail" or notifyType == "Error" then
        iconSymbol = "✕"
        typeColor = Color3.fromRGB(255, 75, 75)
    end

    local card = Instance.new("Frame")
    card.Name = "NotifyCard"
    card.Size = UDim2.new(1, 0, 0, 46)
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    card.BackgroundTransparency = 1
    card.ClipsDescendants = true
    card.Parent = NotifyHolder

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = typeColor
    cardStroke.Transparency = 1
    cardStroke.Thickness = 1.2
    cardStroke.Parent = card

    local cardGrad = Instance.new("UIGradient")
    cardGrad.Color = ColorSequence.new(activeTheme.Start, Color3.fromRGB(18, 18, 24))
    cardGrad.Rotation = 45
    cardGrad.Transparency = NumberSequence.new(0.85)
    cardGrad.Parent = card
    table.insert(gradientObjects, cardGrad)

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 3, 1, -12)
    accentBar.Position = UDim2.new(0, 6, 0.5, -17)
    accentBar.BackgroundColor3 = typeColor
    accentBar.BackgroundTransparency = 1
    accentBar.BorderSizePixel = 0
    accentBar.Parent = card

    local accentBarCorner = Instance.new("UICorner")
    accentBarCorner.CornerRadius = UDim.new(1, 0)
    accentBarCorner.Parent = accentBar

    local iconBg = Instance.new("Frame")
    iconBg.Size = UDim2.new(0, 24, 0, 24)
    iconBg.Position = UDim2.new(0, 16, 0.5, -12)
    iconBg.BackgroundColor3 = typeColor
    iconBg.BackgroundTransparency = 1
    iconBg.Parent = card

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(1, 0)
    iconCorner.Parent = iconBg

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = iconSymbol
    iconLabel.TextColor3 = Color3.fromRGB(18, 18, 24)
    iconLabel.TextSize = 12
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.Parent = iconBg

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -50, 0, 15)
    titleLbl.Position = UDim2.new(0, 48, 0, 8)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.TextTransparency = 1
    titleLbl.TextSize = 11
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = card

    local msgLbl = Instance.new("TextLabel")
    msgLbl.Size = UDim2.new(1, -50, 0, 14)
    msgLbl.Position = UDim2.new(0, 48, 0, 23)
    msgLbl.BackgroundTransparency = 1
    msgLbl.Text = message
    msgLbl.TextColor3 = Color3.fromRGB(180, 180, 195)
    msgLbl.TextTransparency = 1
    msgLbl.TextSize = 9
    msgLbl.Font = Enum.Font.GothamMedium
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.Parent = card

    -- Smooth Slide-In
    card.Position = UDim2.new(1, 40, 0, 0)
    TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0.1
    }):Play()
    TweenService:Create(cardStroke, TweenInfo.new(0.35), {Transparency = 0.3}):Play()
    TweenService:Create(accentBar, TweenInfo.new(0.35), {BackgroundTransparency = 0}):Play()
    TweenService:Create(iconBg, TweenInfo.new(0.35), {BackgroundTransparency = 0.2}):Play()
    TweenService:Create(titleLbl, TweenInfo.new(0.35), {TextTransparency = 0}):Play()
    TweenService:Create(msgLbl, TweenInfo.new(0.35), {TextTransparency = 0}):Play()

    -- Fade Out & Destroy
    task.delay(duration, function()
        if card and card.Parent then
            local fadeOut = TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 40, 0, 0),
                BackgroundTransparency = 1
            })
            TweenService:Create(cardStroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
            TweenService:Create(accentBar, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            TweenService:Create(iconBg, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            TweenService:Create(titleLbl, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            TweenService:Create(msgLbl, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            fadeOut:Play()
            fadeOut.Completed:Connect(function()
                card:Destroy()
            end)
        end
    end)
end

-- ==================== MAIN FRAME SETUP ====================

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
MainFrame.BackgroundTransparency = 0
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = RubyHubGui
table.insert(transparentFrames, MainFrame)

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 45, 55)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

local MainFrameGradient = Instance.new("UIGradient")
MainFrameGradient.Color = ColorSequence.new(activeTheme.Start, Color3.fromRGB(16, 16, 22))
MainFrameGradient.Rotation = 90
MainFrameGradient.Parent = MainFrame
table.insert(gradientObjects, MainFrameGradient)

-- Helper: Blur Manager
local function setBlurEnabled(state)
    local blurObj = Lighting:FindFirstChild("RubyHubBlur")
    if state and isAcrylic and isUIOpen then
        if not blurObj then
            blurObj = Instance.new("BlurEffect")
            blurObj.Name = "RubyHubBlur"
            blurObj.Size = 16
            blurObj.Parent = Lighting
        end
    else
        if blurObj then
            blurObj:Destroy()
        end
    end
end

-- Helper: Shine Effect
local function addShineEffect(parentBtn)
    local shineFrame = Instance.new("Frame")
    shineFrame.Name = "ShineFrame"
    shineFrame.Size = UDim2.new(1, 0, 1, 0)
    shineFrame.BackgroundTransparency = 1
    shineFrame.ZIndex = 2
    shineFrame.ClipsDescendants = true
    shineFrame.Parent = parentBtn

    local shineGradient = Instance.new("UIGradient")
    shineGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    shineGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.4, 1),
        NumberSequenceKeypoint.new(0.5, 0.35),
        NumberSequenceKeypoint.new(0.6, 1),
        NumberSequenceKeypoint.new(1, 1)
    })
    shineGradient.Rotation = 45
    shineGradient.Offset = Vector2.new(-1.2, 0)
    shineGradient.Parent = shineFrame

    task.spawn(function()
        while shineFrame and shineFrame.Parent do
            shineGradient.Offset = Vector2.new(-1.2, 0)
            local tween = TweenService:Create(shineGradient, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Offset = Vector2.new(1.2, 0)})
            tween:Play()
            tween.Completed:Wait()
            task.wait(2.2)
        end
    end)
end

-- Forward Declarations
local SettingsFrame
local syncSettingsPosition
local animateCloseUI
local animateOpenUI
local UserLabel

local function updateUserDisplay()
    if not UserLabel then return end
    if hideUsername then
        UserLabel.Text = "Hidden User"
    elseif streamerModeEnabled then
        UserLabel.Text = streamerName
    else
        UserLabel.Text = LocalPlayer.DisplayName
    end
end

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundTransparency = 1
TitleBar.Parent = MainFrame

local TitleText = Instance.new("TextLabel")
TitleText.Name = "TitleText"
TitleText.Size = UDim2.new(1, -115, 1, 0)
TitleText.Position = UDim2.new(0, 15, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Ruby Hub | Evade Loader"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 14
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

-- Top Action Buttons Helper
local function createTopButton(name, text, posOffset, parentFrame)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 24, 0, 24)
    btn.Position = UDim2.new(1, posOffset, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = name == "CloseBtn" and 18 or 13
    btn.Font = Enum.Font.GothamBold
    btn.Parent = parentFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(activeTheme.Start, activeTheme.End)
    grad.Rotation = 45
    grad.Parent = btn
    table.insert(gradientObjects, grad)

    return btn
end

local CloseBtn = createTopButton("CloseBtn", "×", -32, TitleBar)
local SettingsBtn = createTopButton("SettingsBtn", "⚙", -62, TitleBar)
local MinBtn = createTopButton("MinBtn", "-", -92, TitleBar)

CloseBtn.MouseButton1Click:Connect(function()
    animateCloseUI(true)
end)

-- Dragging System
local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        if syncSettingsPosition then syncSettingsPosition() end
    end
end)

-- Container
local Container = Instance.new("Frame")
Container.Name = "Container"
Container.Size = UDim2.new(1, -30, 0, 95)
Container.Position = UDim2.new(0, 15, 0, 46)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame

-- Theme Color Applier
local function applyThemeColors()
    for _, grad in ipairs(gradientObjects) do
        if grad == MainFrameGradient then
            grad.Color = ColorSequence.new(activeTheme.Start, Color3.fromRGB(16, 16, 22))
        else
            grad.Color = ColorSequence.new(activeTheme.Start, activeTheme.End)
        end
    end
    for _, obj in ipairs(accentObjects) do
        if obj:IsA("UIStroke") then
            obj.Color = activeTheme.Accent
        elseif obj:IsA("TextButton") or obj:IsA("TextLabel") or obj:IsA("ScrollingFrame") then
            if obj:IsA("ScrollingFrame") then
                obj.ScrollBarImageColor3 = activeTheme.Accent
            else
                obj.TextColor3 = activeTheme.Accent
            end
        elseif obj:IsA("Frame") then
            obj.BackgroundColor3 = activeTheme.Accent
        end
    end
end

-- Script Button Maker
local function createScriptButton(name, position, loadstringUrl)
    local Btn = Instance.new("TextButton")
    Btn.Name = name
    Btn.Size = UDim2.new(1, 0, 0, 42)
    Btn.Position = position
    Btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    Btn.Text = name
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.TextSize = 13
    Btn.Font = Enum.Font.GothamBold
    Btn.ZIndex = 3
    Btn.Parent = Container
    table.insert(transparentFrames, Btn)

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 9)
    BtnCorner.Parent = Btn

    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Color = Color3.fromRGB(55, 55, 70)
    BtnStroke.Thickness = 1.2
    BtnStroke.Parent = Btn

    local BtnGradient = Instance.new("UIGradient")
    BtnGradient.Color = ColorSequence.new(activeTheme.Start, activeTheme.End)
    BtnGradient.Rotation = 45
    BtnGradient.Transparency = NumberSequence.new(0.65)
    BtnGradient.Parent = Btn
    table.insert(gradientObjects, BtnGradient)

    addShineEffect(Btn)

    Btn.MouseButton1Click:Connect(function()
        if not multiSelectActive then
            for otherBtn, info in pairs(selectedScripts) do
                if otherBtn ~= Btn then
                    TweenService:Create(otherBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 36)}):Play()
                    TweenService:Create(info.Stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(55, 55, 70)}):Play()
                    selectedScripts[otherBtn] = nil
                end
            end
        end

        if selectedScripts[Btn] then
            selectedScripts[Btn] = nil
            TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 36)}):Play()
            TweenService:Create(BtnStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(55, 55, 70)}):Play()
        else
            selectedScripts[Btn] = {Url = loadstringUrl, Stroke = BtnStroke}
            TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 35, 60)}):Play()
            TweenService:Create(BtnStroke, TweenInfo.new(0.2), {Color = activeTheme.Accent}):Play()
        end
    end)
    return Btn
end

local MainScriptBtn = createScriptButton("Evade Main Script", UDim2.new(0, 0, 0, 0), "https://raw.githubusercontent.com/realdausita/RubyHub/refs/heads/main/Evadee.lua")
local FarmScriptBtn = createScriptButton("Evade Farm Script", UDim2.new(0, 0, 0, 48), "https://raw.githubusercontent.com/realdausita/RubyHub/refs/heads/main/EvadeFarm.lua")

-- ==================== STATS PANEL (GRADIENT COPY BUTTONS & ACCENTS) ====================

local StatsFrame = Instance.new("Frame")
StatsFrame.Name = "StatsFrame"
StatsFrame.Size = UDim2.new(1, -30, 0, 68)
StatsFrame.Position = UDim2.new(0, 15, 0, 146)
StatsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
StatsFrame.Parent = MainFrame
table.insert(transparentFrames, StatsFrame)

local StatsCorner = Instance.new("UICorner")
StatsCorner.CornerRadius = UDim.new(0, 10)
StatsCorner.Parent = StatsFrame

local StatsStroke = Instance.new("UIStroke")
StatsStroke.Color = Color3.fromRGB(255, 255, 255)
StatsStroke.Thickness = 1.2
StatsStroke.Parent = StatsFrame

local StatsStrokeGradient = Instance.new("UIGradient")
StatsStrokeGradient.Color = ColorSequence.new(activeTheme.Start, activeTheme.End)
StatsStrokeGradient.Rotation = 45
StatsStrokeGradient.Parent = StatsStroke
table.insert(gradientObjects, StatsStrokeGradient)

local StatsGradient = Instance.new("UIGradient")
StatsGradient.Color = ColorSequence.new(activeTheme.Start, activeTheme.End)
StatsGradient.Rotation = 45
StatsGradient.Transparency = NumberSequence.new(0.82)
StatsGradient.Parent = StatsFrame
table.insert(gradientObjects, StatsGradient)

local StatsGrid = Instance.new("UIGridLayout")
StatsGrid.CellSize = UDim2.new(0.5, -6, 0, 17)
StatsGrid.CellPadding = UDim2.new(0, 6, 0, 3)
StatsGrid.SortOrder = Enum.SortOrder.LayoutOrder
StatsGrid.Parent = StatsFrame

local StatsPadding = Instance.new("UIPadding")
StatsPadding.PaddingLeft = UDim.new(0, 10)
StatsPadding.PaddingTop = UDim.new(0, 7)
StatsPadding.PaddingRight = UDim.new(0, 10)
StatsPadding.Parent = StatsFrame

local function createStatLabel(title, defaultValue, order, copyValue)
    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    container.Parent = StatsFrame

    local textXOffset = 0

    if copyValue ~= nil then
        textXOffset = 18
        local copyBtn = Instance.new("TextButton")
        copyBtn.Name = "CopyBtn"
        copyBtn.Size = UDim2.new(0, 14, 0, 14)
        copyBtn.Position = UDim2.new(0, 0, 0.5, -7)
        copyBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
        copyBtn.Text = "📋"
        copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        copyBtn.TextSize = 8
        copyBtn.Font = Enum.Font.GothamBold
        copyBtn.Parent = container

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = copyBtn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(255, 255, 255)
        btnStroke.Thickness = 1
        btnStroke.Parent = copyBtn

        local btnStrokeGrad = Instance.new("UIGradient")
        btnStrokeGrad.Color = ColorSequence.new(activeTheme.Start, activeTheme.End)
        btnStrokeGrad.Rotation = 45
        btnStrokeGrad.Parent = btnStroke
        table.insert(gradientObjects, btnStrokeGrad)

        local btnGrad = Instance.new("UIGradient")
        btnGrad.Color = ColorSequence.new(activeTheme.Start, activeTheme.End)
        btnGrad.Rotation = 45
        btnGrad.Transparency = NumberSequence.new(0.5)
        btnGrad.Parent = copyBtn
        table.insert(gradientObjects, btnGrad)

        copyBtn.MouseButton1Click:Connect(function()
            local targetVal = tostring(copyValue)
            if setclipboard then
                setclipboard(targetVal)
            elseif toclipboard then
                toclipboard(targetVal)
            end
            copyBtn.Text = "✓"
            Notify("Copied", title .. " ID is copied successfully!", "Success", 3)
            task.delay(1.2, function()
                if copyBtn then copyBtn.Text = "📋" end
            end)
        end)
    end

    local Lbl = Instance.new("TextLabel")
    Lbl.BackgroundTransparency = 1
    Lbl.Position = UDim2.new(0, textXOffset, 0, 0)
    Lbl.Size = UDim2.new(1, -textXOffset, 1, 0)
    Lbl.Text = string.format("<font color=\"#B0B0C0\">%s:</font> <font color=\"#FFFFFF\"><b>%s</b></font>", title, defaultValue)
    Lbl.RichText = true
    Lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    Lbl.TextSize = 10
    Lbl.Font = Enum.Font.GothamMedium
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.ClipsDescendants = true
    Lbl.Parent = container

    return Lbl, title
end

local DeviceLbl, dTitle = createStatLabel("Device", isMobile and "Mobile" or "PC", 1)
local FpsLbl, fTitle = createStatLabel("FPS", "--", 2)
local PingLbl, pTitle = createStatLabel("Ping", "-- ms", 3)
local RamLbl, rTitle = createStatLabel("RAM", "-- MB", 4)
local PlaceLbl, plTitle = createStatLabel("Place", tostring(game.PlaceId), 5, game.PlaceId)
local fullJobId = game.JobId ~= "" and game.JobId or "Studio/Local"
local displayJobId = #fullJobId > 12 and (string.sub(fullJobId, 1, 10) .. "...") or fullJobId
local JobLbl, jTitle = createStatLabel("Job", displayJobId, 6, fullJobId)

-- Live Stat Loop
local frameCount = 0
local lastFpsCheck = tick()

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastFpsCheck >= 1 then
        FpsLbl.Text = string.format("<font color=\"#B0B0C0\">%s:</font> <font color=\"#FFFFFF\"><b>%d</b></font>", fTitle, frameCount)
        frameCount = 0
        lastFpsCheck = now
    end
end)

task.spawn(function()
    while task.wait(1.5) do
        pcall(function()
            local pingVal = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
            PingLbl.Text = string.format("<font color=\"#B0B0C0\">%s:</font> <font color=\"#FFFFFF\"><b>%d ms</b></font>", pTitle, pingVal)
        end)
        pcall(function()
            local ramVal = math.floor(StatsService:GetTotalMemoryUsageMb())
            RamLbl.Text = string.format("<font color=\"#B0B0C0\">%s:</font> <font color=\"#FFFFFF\"><b>%d MB</b></font>", rTitle, ramVal)
        end)
    end
end)

-- ==================== BOTTOM CONTROLS & LOAD BUTTON ====================

local BottomNav = Instance.new("Frame")
BottomNav.Name = "BottomNav"
BottomNav.Size = UDim2.new(1, -30, 0, 24)
BottomNav.Position = UDim2.new(0, 15, 0, 220)
BottomNav.BackgroundTransparency = 1
BottomNav.Parent = MainFrame

local MultiToggle = Instance.new("TextButton")
MultiToggle.Name = "MultiToggle"
MultiToggle.Size = UDim2.new(0, 115, 1, 0)
MultiToggle.Position = UDim2.new(1, -115, 0, 0)
MultiToggle.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
MultiToggle.Text = "Multi Select: OFF"
MultiToggle.TextColor3 = Color3.fromRGB(180, 180, 190)
MultiToggle.TextSize = 10
MultiToggle.Font = Enum.Font.GothamBold
MultiToggle.ZIndex = 3
MultiToggle.Parent = BottomNav
table.insert(transparentFrames, MultiToggle)

local MultiCorner = Instance.new("UICorner")
MultiCorner.CornerRadius = UDim.new(0, 7)
MultiCorner.Parent = MultiToggle

local MultiStroke = Instance.new("UIStroke")
MultiStroke.Color = Color3.fromRGB(55, 55, 70)
MultiStroke.Thickness = 1
MultiStroke.Parent = MultiToggle

local MultiGradient = Instance.new("UIGradient")
MultiGradient.Color = ColorSequence.new(activeTheme.Start, activeTheme.End)
MultiGradient.Rotation = 45
MultiGradient.Transparency = NumberSequence.new(0.7)
MultiGradient.Parent = MultiToggle
table.insert(gradientObjects, MultiGradient)

MultiToggle.MouseButton1Click:Connect(function()
    multiSelectActive = not multiSelectActive
    if multiSelectActive then
        MultiToggle.Text = "Multi Select: ON"
        MultiToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        TweenService:Create(MultiStroke, TweenInfo.new(0.2), {Color = activeTheme.Accent}):Play()
    else
        MultiToggle.Text = "Multi Select: OFF"
        MultiToggle.TextColor3 = Color3.fromRGB(180, 180, 190)
        TweenService:Create(MultiStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(55, 55, 70)}):Play()
        for otherBtn, info in pairs(selectedScripts) do
            TweenService:Create(otherBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 36)}):Play()
            TweenService:Create(info.Stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(55, 55, 70)}):Play()
            selectedScripts[otherBtn] = nil
        end
    end
end)

-- LOAD SCRIPTS Button
local LoadBtn = Instance.new("TextButton")
LoadBtn.Name = "LoadBtn"
LoadBtn.Size = UDim2.new(1, -30, 0, 40)
LoadBtn.Position = UDim2.new(0, 15, 0, 250)
LoadBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
LoadBtn.Text = "LOAD SCRIPTS"
LoadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadBtn.TextSize = 13
LoadBtn.Font = Enum.Font.GothamBold
LoadBtn.ZIndex = 5
LoadBtn.Parent = MainFrame
table.insert(transparentFrames, LoadBtn)

local LoadCorner = Instance.new("UICorner")
LoadCorner.CornerRadius = UDim.new(0, 9)
LoadCorner.Parent = LoadBtn

local LoadStroke = Instance.new("UIStroke")
LoadStroke.Color = Color3.fromRGB(70, 70, 90)
LoadStroke.Thickness = 1.2
LoadStroke.Parent = LoadBtn

local LoadGradient = Instance.new("UIGradient")
LoadGradient.Color = ColorSequence.new(activeTheme.Start, activeTheme.End)
LoadGradient.Rotation = 45
LoadGradient.Parent = LoadBtn
table.insert(gradientObjects, LoadGradient)

addShineEffect(LoadBtn)

LoadBtn.MouseButton1Click:Connect(function()
    local hasSelection = false
    for _ in pairs(selectedScripts) do
        hasSelection = true
        break
    end

    if not hasSelection then
        Notify("Warning", "Select A Script First!", "Warning", 3)
        return
    end

    local executionList = {}
    for btn, info in pairs(selectedScripts) do
        table.insert(executionList, info.Url)
    end
    
    animateCloseUI(true)
    
    for _, url in ipairs(executionList) do
        task.spawn(function()
            pcall(function()
                loadstring(game:HttpGet(url))()
            end)
        end)
    end
end)

-- ==================== FOOTER ====================

local FooterFrame = Instance.new("Frame")
FooterFrame.Name = "FooterFrame"
FooterFrame.Size = UDim2.new(1, -30, 0, 30)
FooterFrame.Position = UDim2.new(0, 15, 0, 298)
FooterFrame.BackgroundTransparency = 1
FooterFrame.Parent = MainFrame

local ProfileImage = Instance.new("ImageLabel")
ProfileImage.Name = "ProfileImage"
ProfileImage.Size = UDim2.new(0, 24, 0, 24)
ProfileImage.Position = UDim2.new(0, 0, 0.5, -12)
ProfileImage.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
ProfileImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
ProfileImage.Visible = true
ProfileImage.Parent = FooterFrame

local ProfileCorner = Instance.new("UICorner")
ProfileCorner.CornerRadius = UDim.new(1, 0)
ProfileCorner.Parent = ProfileImage

local ProfileStroke = Instance.new("UIStroke")
ProfileStroke.Color = activeTheme.Accent
ProfileStroke.Thickness = 1
ProfileStroke.Parent = ProfileImage
table.insert(accentObjects, ProfileStroke)

UserLabel = Instance.new("TextLabel")
UserLabel.Name = "UserLabel"
UserLabel.Size = UDim2.new(0, 150, 1, 0)
UserLabel.Position = UDim2.new(0, 30, 0, 0)
UserLabel.BackgroundTransparency = 1
UserLabel.Text = LocalPlayer.DisplayName
UserLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
UserLabel.TextSize = 11
UserLabel.Font = Enum.Font.GothamBold
UserLabel.TextXAlignment = Enum.TextXAlignment.Left
UserLabel.Parent = FooterFrame

local UserGradient = Instance.new("UIGradient")
UserGradient.Color = ColorSequence.new(activeTheme.Start, activeTheme.End)
UserGradient.Rotation = 45
UserGradient.Parent = UserLabel
table.insert(gradientObjects, UserGradient)

local CreditLabel = Instance.new("TextLabel")
CreditLabel.Name = "CreditLabel"
CreditLabel.Size = UDim2.new(0, 130, 1, 0)
CreditLabel.Position = UDim2.new(1, -130, 0, 0)
CreditLabel.BackgroundTransparency = 1
CreditLabel.Text = "made by dausita"
CreditLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
CreditLabel.TextSize = 10
CreditLabel.Font = Enum.Font.GothamMedium
CreditLabel.TextXAlignment = Enum.TextXAlignment.Right
CreditLabel.Parent = FooterFrame

local CreditGradient = Instance.new("UIGradient")
CreditGradient.Color = ColorSequence.new(activeTheme.Start, activeTheme.End)
CreditGradient.Rotation = 45
CreditGradient.Parent = CreditLabel
table.insert(gradientObjects, CreditGradient)

MinBtn.MouseButton1Click:Connect(function()
    if isAnimating then return end
    isMinimized = not isMinimized
    if isMinimized then
        MinBtn.Text = "+"
        if settingsOpen then
            settingsOpen = false
            TweenService:Create(SettingsFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, mainHeight)}):Play()
            task.delay(0.2, function() SettingsFrame.Visible = false end)
        end
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, mainWidth, 0, 42)}):Play()
    else
        MinBtn.Text = "-"
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, mainWidth, 0, mainHeight)}):Play()
    end
end)


-- ==================== SETTINGS MENU ====================

SettingsFrame = Instance.new("Frame")
SettingsFrame.Name = "SettingsFrame"
SettingsFrame.AnchorPoint = Vector2.new(0, 0.5)
SettingsFrame.Size = UDim2.new(0, 0, 0, mainHeight)
SettingsFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
SettingsFrame.BackgroundTransparency = 0
SettingsFrame.BorderSizePixel = 0
SettingsFrame.ClipsDescendants = true
SettingsFrame.Visible = false
SettingsFrame.Parent = RubyHubGui
table.insert(transparentFrames, SettingsFrame)

local SettingsCorner = Instance.new("UICorner")
SettingsCorner.CornerRadius = UDim.new(0, 14)
SettingsCorner.Parent = SettingsFrame

local SettingsStroke = Instance.new("UIStroke")
SettingsStroke.Color = Color3.fromRGB(45, 45, 55)
SettingsStroke.Thickness = 1.5
SettingsStroke.Parent = SettingsFrame

local SettingsFrameGradient = Instance.new("UIGradient")
SettingsFrameGradient.Color = ColorSequence.new(activeTheme.Start, Color3.fromRGB(16, 16, 22))
SettingsFrameGradient.Rotation = 90
SettingsFrameGradient.Parent = SettingsFrame
table.insert(gradientObjects, SettingsFrameGradient)

syncSettingsPosition = function()
    if SettingsFrame and MainFrame then
        SettingsFrame.Position = UDim2.new(
            MainFrame.Position.X.Scale,
            MainFrame.Position.X.Offset + (mainWidth/2) + 10,
            MainFrame.Position.Y.Scale,
            MainFrame.Position.Y.Offset
        )
    end
end

local SettTitleBar = Instance.new("Frame")
SettTitleBar.Name = "SettTitleBar"
SettTitleBar.Size = UDim2.new(1, 0, 0, 42)
SettTitleBar.BackgroundTransparency = 1
SettTitleBar.Parent = SettingsFrame

local SettTitleText = Instance.new("TextLabel")
SettTitleText.Size = UDim2.new(1, -45, 1, 0)
SettTitleText.Position = UDim2.new(0, 15, 0, 0)
SettTitleText.BackgroundTransparency = 1
SettTitleText.Text = "Settings Menu"
SettTitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
SettTitleText.TextSize = 13
SettTitleText.Font = Enum.Font.GothamBold
SettTitleText.TextXAlignment = Enum.TextXAlignment.Left
SettTitleText.Parent = SettTitleBar

local SettClose = createTopButton("SettClose", "×", -34, SettTitleBar)

local SettScroll = Instance.new("ScrollingFrame")
SettScroll.Size = UDim2.new(1, -20, 1, -55)
SettScroll.Position = UDim2.new(0, 10, 0, 48)
SettScroll.BackgroundTransparency = 1
SettScroll.ScrollBarThickness = 2
SettScroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 70)
SettScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
SettScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SettScroll.Parent = SettingsFrame

local SettLayout = Instance.new("UIListLayout")
SettLayout.Padding = UDim.new(0, 8)
SettLayout.SortOrder = Enum.SortOrder.LayoutOrder
SettLayout.Parent = SettScroll

local function attachSettingsGradient(item)
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(activeTheme.Start, activeTheme.End)
    grad.Rotation = 45
    grad.Transparency = NumberSequence.new(0.8)
    grad.Parent = item
    table.insert(gradientObjects, grad)
end

local function createToggle(parent, text, default, callback)
    local state = default or false
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(1, 0, 0, 32)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    ToggleBtn.Text = "   " .. text
    ToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    ToggleBtn.TextSize = 11
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextXAlignment = Enum.TextXAlignment.Left
    ToggleBtn.Parent = parent
    table.insert(transparentFrames, ToggleBtn)
    attachSettingsGradient(ToggleBtn)

    local TCorner = Instance.new("UICorner")
    TCorner.CornerRadius = UDim.new(0, 7)
    TCorner.Parent = ToggleBtn

    local TStroke = Instance.new("UIStroke")
    TStroke.Color = Color3.fromRGB(45, 45, 55)
    TStroke.Thickness = 1
    TStroke.Parent = ToggleBtn

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 13, 0, 13)
    Indicator.Position = UDim2.new(1, -22, 0.5, -6)
    Indicator.BackgroundColor3 = state and activeTheme.Accent or Color3.fromRGB(50, 50, 60)
    Indicator.Parent = ToggleBtn
    table.insert(accentObjects, Indicator)

    local ICorner = Instance.new("UICorner")
    ICorner.CornerRadius = UDim.new(1, 0)
    ICorner.Parent = Indicator

    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(Indicator, TweenInfo.new(0.2), {
            BackgroundColor3 = state and activeTheme.Accent or Color3.fromRGB(50, 50, 60)
        }):Play()
        callback(state)
    end)
end

createToggle(SettScroll, "Transparency", false, function(val)
    isTransparent = val
    local bgTrans = val and 0.25 or 0
    for _, elem in ipairs(transparentFrames) do
        TweenService:Create(elem, TweenInfo.new(0.3), {BackgroundTransparency = bgTrans}):Play()
    end
end)

createToggle(SettScroll, "Acrylic Blur", false, function(val)
    isAcrylic = val
    setBlurEnabled(val)
end)

createToggle(SettScroll, "Hide Username On Menu", false, function(val)
    hideUsername = val
    updateUserDisplay()
end)

createToggle(SettScroll, "Streamer Mode", false, function(val)
    streamerModeEnabled = val
    updateUserDisplay()
end)

local StreamerInputFrame = Instance.new("Frame")
StreamerInputFrame.Size = UDim2.new(1, 0, 0, 36)
StreamerInputFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
StreamerInputFrame.Parent = SettScroll
table.insert(transparentFrames, StreamerInputFrame)
attachSettingsGradient(StreamerInputFrame)

local SInputCorner = Instance.new("UICorner")
SInputCorner.CornerRadius = UDim.new(0, 7)
SInputCorner.Parent = StreamerInputFrame

local SInputStroke = Instance.new("UIStroke")
SInputStroke.Color = Color3.fromRGB(45, 45, 55)
SInputStroke.Thickness = 1
SInputStroke.Parent = StreamerInputFrame

local SInputLabel = Instance.new("TextLabel")
SInputLabel.Size = UDim2.new(0, 85, 1, 0)
SInputLabel.Position = UDim2.new(0, 10, 0, 0)
SInputLabel.BackgroundTransparency = 1
SInputLabel.Text = "Streamer Name:"
SInputLabel.TextColor3 = Color3.fromRGB(180, 180, 195)
SInputLabel.TextSize = 9
SInputLabel.Font = Enum.Font.GothamBold
SInputLabel.TextXAlignment = Enum.TextXAlignment.Left
SInputLabel.Parent = StreamerInputFrame

local StreamerBox = Instance.new("TextBox")
StreamerBox.Size = UDim2.new(1, -100, 0, 22)
StreamerBox.Position = UDim2.new(0, 92, 0.5, -11)
StreamerBox.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
StreamerBox.Text = streamerName
StreamerBox.PlaceholderText = "Ruby On Top!"
StreamerBox.TextColor3 = Color3.fromRGB(255, 255, 255)
StreamerBox.TextSize = 10
StreamerBox.Font = Enum.Font.GothamMedium
StreamerBox.Parent = StreamerInputFrame

local SBoxCorner = Instance.new("UICorner")
SBoxCorner.CornerRadius = UDim.new(0, 5)
SBoxCorner.Parent = StreamerBox

local SBoxStroke = Instance.new("UIStroke")
SBoxStroke.Color = Color3.fromRGB(50, 50, 65)
SBoxStroke.Thickness = 1
SBoxStroke.Parent = StreamerBox

StreamerBox.FocusLost:Connect(function()
    if StreamerBox.Text == "" then
        StreamerBox.Text = "Ruby On Top!"
    end
    streamerName = StreamerBox.Text
    updateUserDisplay()
end)

createToggle(SettScroll, "Anti AFK", false, function(enabled)
    if enabled then
        antiAfkConnection = LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    else
        if antiAfkConnection then
            antiAfkConnection:Disconnect()
            antiAfkConnection = nil
        end
    end
end)

-- Theme Dropdown
local ThemeDropBtn = Instance.new("TextButton")
ThemeDropBtn.Size = UDim2.new(1, 0, 0, 32)
ThemeDropBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
ThemeDropBtn.Text = "   Theme: Amethyst"
ThemeDropBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
ThemeDropBtn.TextSize = 11
ThemeDropBtn.Font = Enum.Font.GothamBold
ThemeDropBtn.TextXAlignment = Enum.TextXAlignment.Left
ThemeDropBtn.Parent = SettScroll
table.insert(transparentFrames, ThemeDropBtn)
attachSettingsGradient(ThemeDropBtn)

local DropCorner = Instance.new("UICorner")
DropCorner.CornerRadius = UDim.new(0, 7)
DropCorner.Parent = ThemeDropBtn

local DropStroke = Instance.new("UIStroke")
DropStroke.Color = Color3.fromRGB(45, 45, 55)
DropStroke.Thickness = 1
DropStroke.Parent = ThemeDropBtn

local DropArrow = Instance.new("TextLabel")
DropArrow.Size = UDim2.new(0, 20, 1, 0)
DropArrow.Position = UDim2.new(1, -25, 0, 0)
DropArrow.BackgroundTransparency = 1
DropArrow.Text = "▼"
DropArrow.TextColor3 = Color3.fromRGB(150, 150, 160)
DropArrow.TextSize = 10
DropArrow.Font = Enum.Font.GothamBold
DropArrow.Parent = ThemeDropBtn

local DropListFrame = Instance.new("ScrollingFrame")
DropListFrame.Size = UDim2.new(1, 0, 0, 0)
DropListFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
DropListFrame.BorderSizePixel = 0
DropListFrame.ClipsDescendants = true
DropListFrame.Visible = false
DropListFrame.ScrollBarThickness = 4
DropListFrame.ScrollBarImageColor3 = activeTheme.Accent
DropListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
DropListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
DropListFrame.Parent = SettScroll
table.insert(accentObjects, DropListFrame)

local DLCorner = Instance.new("UICorner")
DLCorner.CornerRadius = UDim.new(0, 7)
DLCorner.Parent = DropListFrame

local DLStroke = Instance.new("UIStroke")
DLStroke.Color = Color3.fromRGB(255, 255, 255)
DLStroke.Thickness = 1
DLStroke.Parent = DropListFrame

local DLStrokeGradient = Instance.new("UIGradient")
DLStrokeGradient.Color = ColorSequence.new(activeTheme.Start, activeTheme.End)
DLStrokeGradient.Rotation = 45
DLStrokeGradient.Parent = DLStroke
table.insert(gradientObjects, DLStrokeGradient)

local DLGradient = Instance.new("UIGradient")
DLGradient.Color = ColorSequence.new(activeTheme.Start, Color3.fromRGB(20, 20, 28))
DLGradient.Rotation = 90
DLGradient.Parent = DropListFrame
table.insert(gradientObjects, DLGradient)

local DLList = Instance.new("UIListLayout")
DLList.SortOrder = Enum.SortOrder.LayoutOrder
DLList.Parent = DropListFrame

DropListFrame.MouseEnter:Connect(function()
    SettScroll.ScrollingEnabled = false
end)
DropListFrame.MouseLeave:Connect(function()
    SettScroll.ScrollingEnabled = true
end)

local dropdownOpen = false
ThemeDropBtn.MouseButton1Click:Connect(function()
    dropdownOpen = not dropdownOpen
    DropArrow.Text = dropdownOpen and "▲" or "▼"
    DropListFrame.Visible = dropdownOpen
    TweenService:Create(DropListFrame, TweenInfo.new(0.2), {
        Size = dropdownOpen and UDim2.new(1, 0, 0, 150) or UDim2.new(1, 0, 0, 0)
    }):Play()
    if not dropdownOpen then
        SettScroll.ScrollingEnabled = true
    end
end)

for themeName, themeColors in pairs(Themes) do
    local Choice = Instance.new("TextButton")
    Choice.Size = UDim2.new(1, -6, 0, 26)
    Choice.BackgroundTransparency = 1
    Choice.Text = "   " .. themeName
    Choice.TextColor3 = Color3.fromRGB(220, 220, 230)
    Choice.TextSize = 10
    Choice.Font = Enum.Font.GothamBold
    Choice.TextXAlignment = Enum.TextXAlignment.Left
    Choice.Parent = DropListFrame
    
    Choice.MouseButton1Click:Connect(function()
        activeTheme = themeColors
        ThemeDropBtn.Text = "   Theme: " .. themeName:split(" ")[1]
        applyThemeColors()
        
        dropdownOpen = false
        DropArrow.Text = "▼"
        SettScroll.ScrollingEnabled = true
        TweenService:Create(DropListFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)}):Play()
        task.delay(0.2, function() DropListFrame.Visible = false end)
    end)
end

-- FPS Slider
local SliderFrame = Instance.new("Frame")
SliderFrame.Size = UDim2.new(1, 0, 0, 42)
SliderFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
SliderFrame.Parent = SettScroll
table.insert(transparentFrames, SliderFrame)
attachSettingsGradient(SliderFrame)

local SFCorner = Instance.new("UICorner")
SFCorner.CornerRadius = UDim.new(0, 7)
SFCorner.Parent = SliderFrame

local SFStroke = Instance.new("UIStroke")
SFStroke.Color = Color3.fromRGB(45, 45, 55)
SFStroke.Thickness = 1
SFStroke.Parent = SliderFrame

local SliderLabel = Instance.new("TextLabel")
SliderLabel.Size = UDim2.new(1, -10, 0, 18)
SliderLabel.Position = UDim2.new(0, 10, 0, 2)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Text = "FPS Cap: Max (Infinite)"
SliderLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
SliderLabel.TextSize = 10
SliderLabel.Font = Enum.Font.GothamBold
SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
SliderLabel.Parent = SliderFrame

local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(1, -20, 0, 4)
SliderTrack.Position = UDim2.new(0, 10, 0, 26)
SliderTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
SliderTrack.BorderSizePixel = 0
SliderTrack.Parent = SliderFrame

local STCorner = Instance.new("UICorner")
STCorner.CornerRadius = UDim.new(1, 0)
STCorner.Parent = SliderTrack

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(1, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderTrack

local SFillCorner = Instance.new("UICorner")
SFillCorner.CornerRadius = UDim.new(1, 0)
SFillCorner.Parent = SliderFill

local SliderFillGradient = Instance.new("UIGradient")
SliderFillGradient.Color = ColorSequence.new(activeTheme.Start, activeTheme.End)
SliderFillGradient.Rotation = 45
SliderFillGradient.Parent = SliderFill
table.insert(gradientObjects, SliderFillGradient)

local SliderBtn = Instance.new("TextButton")
SliderBtn.Size = UDim2.new(0, 12, 0, 12)
SliderBtn.Position = UDim2.new(1, -6, 0.5, -6)
SliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderBtn.Text = ""
SliderBtn.Parent = SliderTrack

local SBCorner = Instance.new("UICorner")
SBCorner.CornerRadius = UDim.new(1, 0)
SBCorner.Parent = SliderBtn

local sliderDragging = false
local function updateSlider(input)
    local relativeX = input.Position.X - SliderTrack.AbsolutePosition.X
    local pct = math.clamp(relativeX / SliderTrack.AbsoluteSize.X, 0, 1)
    
    SliderFill.Size = UDim2.new(pct, 0, 1, 0)
    SliderBtn.Position = UDim2.new(pct, -6, 0.5, -6)
    
    local calculatedFps = math.floor(30 + (pct * 330))
    if calculatedFps >= 350 then
        SliderLabel.Text = "FPS Cap: Max (Infinite)"
        if setfpscap then setfpscap(9999) end
    else
        SliderLabel.Text = "FPS Cap: " .. calculatedFps
        if setfpscap then setfpscap(calculatedFps) end
    end
end

SliderBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input)
    end
end)

-- Keybind Box
local KeybindBox = Instance.new("TextButton")
KeybindBox.Size = UDim2.new(1, 0, 0, 32)
KeybindBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
KeybindBox.Text = "   Keybind: RightControl"
KeybindBox.TextColor3 = Color3.fromRGB(200, 200, 210)
KeybindBox.TextSize = 11
KeybindBox.Font = Enum.Font.GothamBold
KeybindBox.TextXAlignment = Enum.TextXAlignment.Left
KeybindBox.Parent = SettScroll
table.insert(transparentFrames, KeybindBox)
attachSettingsGradient(KeybindBox)

local KBCorner = Instance.new("UICorner")
KBCorner.CornerRadius = UDim.new(0, 7)
KBCorner.Parent = KeybindBox

local KBStroke = Instance.new("UIStroke")
KBStroke.Color = Color3.fromRGB(45, 45, 55)
KBStroke.Thickness = 1
KBStroke.Parent = KeybindBox

KeybindBox.MouseButton1Click:Connect(function()
    listeningForKey = true
    KeybindBox.Text = "   Press any key..."
    KeybindBox.TextColor3 = activeTheme.Accent
end)

local function toggleSettings(overrideState)
    if isMinimized or isAnimating then return end
    if overrideState ~= nil then
        settingsOpen = overrideState
    else
        settingsOpen = not settingsOpen
    end

    if settingsOpen then
        syncSettingsPosition()
        SettingsFrame.Visible = true
        TweenService:Create(SettingsFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 210, 0, mainHeight)
        }):Play()
    else
        local tween = TweenService:Create(SettingsFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, mainHeight)
        })
        tween:Play()
        tween.Completed:Connect(function()
            if not settingsOpen then
                SettingsFrame.Visible = false
            end
        end)
    end
end

SettingsBtn.MouseButton1Click:Connect(function() toggleSettings() end)
SettClose.MouseButton1Click:Connect(function() toggleSettings(false) end)


-- ==================== OPEN & CLOSE ANIMATIONS ====================

animateOpenUI = function()
    if isAnimating then return end
    isAnimating = true
    isUIOpen = true
    
    MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    
    setBlurEnabled(true)
    
    local targetHeight = isMinimized and 42 or mainHeight
    local tweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    local t1 = TweenService:Create(MainFrame, tweenInfo, {Size = UDim2.new(0, mainWidth, 0, targetHeight)})
    t1:Play()
    t1.Completed:Wait()
    
    isAnimating = false

    if wasSettingsOpenBeforeClose and not isMinimized then
        toggleSettings(true)
    end
end

animateCloseUI = function(destroyAfter)
    if isAnimating then return end
    isAnimating = true
    
    wasSettingsOpenBeforeClose = settingsOpen
    
    if settingsOpen then
        settingsOpen = false
        TweenService:Create(SettingsFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, mainHeight)
        }):Play()
        task.delay(0.2, function() SettingsFrame.Visible = false end)
    end
    
    setBlurEnabled(false)
    
    local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    local t1 = TweenService:Create(MainFrame, tweenInfo, {Size = UDim2.new(0, 0, 0, 0)})
    t1:Play()
    t1.Completed:Wait()
    
    MainFrame.Visible = false
    isUIOpen = false
    isAnimating = false
    
    if destroyAfter then
        RubyHubGui:Destroy()
    end
end

-- Mobile Toggle Button
if isMobile then
    local MobileToggleBtn = Instance.new("TextButton")
    MobileToggleBtn.Name = "MobileToggleBtn"
    MobileToggleBtn.Size = UDim2.new(0, 50, 0, 50)
    MobileToggleBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
    MobileToggleBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    MobileToggleBtn.Text = "RH"
    MobileToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MobileToggleBtn.Font = Enum.Font.GothamBold
    MobileToggleBtn.TextSize = 16
    MobileToggleBtn.Parent = RubyHubGui
    
    local MobCorner = Instance.new("UICorner")
    MobCorner.CornerRadius = UDim.new(1, 0)
    MobCorner.Parent = MobileToggleBtn
    
    local MobStroke = Instance.new("UIStroke")
    MobStroke.Color = activeTheme.Accent
    MobStroke.Thickness = 2
    MobStroke.Parent = MobileToggleBtn

    local MobGradient = Instance.new("UIGradient")
    MobGradient.Color = ColorSequence.new(activeTheme.Start, activeTheme.End)
    MobGradient.Rotation = 45
    MobGradient.Parent = MobStroke
    
    MobileToggleBtn.MouseButton1Click:Connect(function()
        if isUIOpen then
            animateCloseUI(false)
        else
            animateOpenUI()
        end
    end)
end

-- Keybind Input Listener
UserInputService.InputBegan:Connect(function(input)
    if listeningForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            currentKeybind = input.KeyCode
            KeybindBox.Text = "   Keybind: " .. input.KeyCode.Name
            KeybindBox.TextColor3 = Color3.fromRGB(200, 200, 210)
            listeningForKey = false
        end
        return
    end

    if UserInputService:GetFocusedTextBox() then return end

    if not isMobile and input.KeyCode == currentKeybind then
        if isUIOpen then
            animateCloseUI(false)
        else
            animateOpenUI()
        end
    end
end)

-- Initial Startup Launch
applyThemeColors()
animateOpenUI()
Notify("Ruby Hub", "Ruby Loader loaded successfully!", "Success", 3.5)
