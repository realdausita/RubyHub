local pId = game.PlaceId
local player = game:GetService("Players").LocalPlayer

if pId == 4620170611 or pId == 3851622790 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/realdausita/RubyHub/refs/heads/main/BreakIn.lua"))()
elseif pId == 9872472334 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/realdausita/RubyHub/refs/heads/main/Evade.lua"))()
elseif pId == 18687417158 or pId == 83645629621104 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/realdausita/RubyHub/refs/heads/main/Forsaken.lua"))()
elseif pId == 2753915549 or pId == 4442272183 or pId == 7449423635 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/realdausita/RubyHub/refs/heads/main/Bloxfruit.lua"))()
else
    player:Kick("This Game Is Not Supported by Ruby Hub Universal Version Soon..")
end
