local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local CorrectKey = "Release"

local Window = Fluent:CreateWindow({
    Title = "Key System",
    SubTitle = "by Ruby Hub Team",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 400),
    Acrylic = false,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local MainTab = Window:AddTab({ Title = "Key Verification", Icon = "key" })
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })

MainTab:AddParagraph({
    Title = "Tutorial",
    Content = "1 - Click to Get Key (If u are in discord server no need for it).\n2 - When u click get key it will copy the our discord link paste it to your browser and join to the server.\n3 - Verify on our server and u will gain access to see other channels, find the Script Key channel and get ur key."
})

local KeyInput = MainTab:AddInput("KeyInput", {
    Title = "Enter Key",
    Placeholder = "Type your key here",
    Numeric = false, 
    Finished = false
})

MainTab:AddButton({
    Title = "Verify Key",
    Description = "Check if the key is correct",
    Callback = function()
        local EnteredKey = KeyInput.Value or ""
        
        if EnteredKey == CorrectKey then
            Fluent:Notify({
                Title = "Success!",
                Content = "Key is valid. Running script...",
                Duration = 3
            })

            local success, err = pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/realdausita/RubyHub/refs/heads/main/Loader.lua"))()
            end)

            if not success then
                Fluent:Notify({
                    Title = "Execution Error",
                    Content = "Report this bug to us on discord.",
                    Duration = 5
                })
                warn("Error: " .. err)
            end

            task.wait(1)
            Window:Destroy()
        else
            Fluent:Notify({
                Title = "Error!",
                Content = "Invalid Key! Try again.",
                Duration = 3
            })
        end
    end
})

MainTab:AddButton({
    Title = "Get Key",
    Description = "Click to copy Discord link",
    Callback = function()
        setclipboard("https://discord.gg/3hDUrYY435")
        Fluent:Notify({
            Title = "Link Copied",
            Content = "Discord link copied to clipboard!",
            Duration = 3
        })
    end
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("Ruby Hub")
SaveManager:SetFolder("Ruby Hub/configs")

InterfaceManager:BuildInterfaceSection(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Ruby Hub",
    Content = "Please get your key from OUR discord server.",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()
