local p =game.Players.LocalPlayer
local c ='loadstring(game:HttpGet("https://raw.githubusercontent.com/Veko-Studio/PCEOS/refs/heads/main/rawlib.lua"))()'
local c2='loadstring(game:HttpGet("https://raw.githubusercontent.com/Veko-Studio/PCEOS/refs/heads/main/drop-in-tool.lua"))()'
if os.time()-p:GetJoinTime()>=2 then
    queue_on_teleport(c)
    queue_on_teleport(c2)
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,game.JobId,p)
else
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Veko-Studio/PCEOS/refs/heads/main/drop-in-tool.lua"))()
end
