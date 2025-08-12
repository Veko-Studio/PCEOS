local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- The part or mesh you want to check inside (change this path accordingly)
local checkPart = workspace:WaitForChild("YourCheckPart") 

-- McDonald's ding sound asset (example from Roblox library)
local soundId = "rbxassetid://9118820636" -- "McDonald's ding" sound

local highlightInstances = {}

-- Function to check if a position is inside the part's bounding box
local function isInsidePart(position, part)
    local cf = part.CFrame
    local size = part.Size
    local relativePos = cf:PointToObjectSpace(position)
    local halfSize = size / 2
    return
        math.abs(relativePos.X) <= halfSize.X and
        math.abs(relativePos.Y) <= halfSize.Y and
        math.abs(relativePos.Z) <= halfSize.Z
end

-- Function to check if player's speed is 0 while in air
local function isPlayerInAirWithZeroSpeed(plr)
    local char = plr.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return false end
    
    local velocity = hrp.Velocity
    local speed = velocity.Magnitude
    local state = hum:GetState()
    
    -- Check if player is in the air (falling, freefall, jumping) and speed is 0
    local inAirStates = {
        Enum.HumanoidStateType.Freefall,
        Enum.HumanoidStateType.Jumping,
        Enum.HumanoidStateType.FallingDown,
    }
    
    local inAir = false
    for _, st in pairs(inAirStates) do
        if state == st then
            inAir = true
            break
        end
    end
    
    return inAir and speed < 0.1
end

-- Function to highlight character
local function highlightCharacter(char)
    if not char then return end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.new(1, 0.8, 0) -- golden-ish color
    highlight.OutlineColor = Color3.new(1, 0.5, 0)
    highlight.Adornee = char
    highlight.Parent = char
    return highlight
end

-- Main check function (runs for 5 seconds)
local function checkPlayersForCondition()
    local foundPlayers = {}
    local startTime = tick()
    
    while tick() - startTime < 5 do
        foundPlayers = {}
        
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = plr.Character.HumanoidRootPart
                
                -- Check if inside part
                local inside = isInsidePart(hrp.Position, checkPart)
                
                -- Check if speed=0 in air
                local zeroSpeedAir = isPlayerInAirWithZeroSpeed(plr)
                
                if inside or zeroSpeedAir then
                    table.insert(foundPlayers, plr)
                end
            end
        end
        
        if #foundPlayers > 0 then
            return foundPlayers
        end
        
        RunService.Heartbeat:Wait()
    end
    
    return nil -- no players found in 5 seconds
end

-- Play McDonald's ding sound
local function playDingSound()
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 1
    sound.Parent = workspace
    sound:Play()
    
    -- Cleanup after done playing
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- Wait for U key press
local function waitForUKeyPress()
    local event
    local pressed = false
    
    event = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.U then
            pressed = true
            event:Disconnect()
        end
    end)
    
    repeat RunService.Heartbeat:Wait() until pressed
end

-- Teleport player to new server
local function teleportToNewServer()
    local placeId = game.PlaceId
    -- Teleport to a new reserved server or public server, use teleport queue or reserved server if you want more control.
    TeleportService:Teleport(placeId, player)
end

-- Main logic
spawn(function()
    local playersFound = checkPlayersForCondition()
    
    if not playersFound then
        -- No players found, teleport away
        teleportToNewServer()
    else
        -- Players found, highlight and play sound
        playDingSound()
        
        -- Highlight players
        for _, plr in pairs(playersFound) do
            if plr.Character then
                highlightInstances[plr] = highlightCharacter(plr.Character)
            end
        end
        
        print("Players found in condition. Press U to teleport.")
        waitForUKeyPress()
        
        -- Clean up highlights
        for _, hl in pairs(highlightInstances) do
            hl:Destroy()
        end
        
        teleportToNewServer()
    end
end)
