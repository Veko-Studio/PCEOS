local paintremote = game:GetService("ReplicatedStorage").Remotes:GetChildren()[86]--86
local moveremote = game:GetService("ReplicatedStorage").Remotes:GetChildren()[89]--89
local deleteremote = game:GetService("ReplicatedStorage").Remotes:GetChildren()[94]--94

local blockdef = require(game:GetService("ReplicatedStorage").ModuIes.BlockDef)
local envbuild = getsenv(game:GetService("Players").LocalPlayer.PlayerGui.BuildGui:FindFirstChild("BuildObjects",true).Parent)

_G.originalRaycast = _G.originalRaycast or workspace.Raycast
local originalRaycast = _G.originalRaycast


local realmath = math
math = {}

-- Copy everything from the original math
for k, v in pairs(realmath) do
    math[k] = v
end
math.trunc = function(n)
    if n > 0 then
        return realmath.floor(n)
    else
        return realmath.ceil(n)
    end
end

local camera = workspace.CurrentCamera
local Players = game.Players
local LocalPlayer = game.Players.LocalPlayer
local workspacemt
if getrawmetatable then workspacemt = getrawmetatable(workspace) end
local zone
for _, zonei in workspace.BuildingZones:GetChildren() do
    if zonei.Owner.Value == Players.LocalPlayer then zone = zonei end
end





---converting
local function GlobalVecToPlotVec(globalVec:Vector3)
    -- Subtract the zone position
    local localVec = globalVec - zone.Position

    -- Reverse the scaling and offset
    local x = localVec.X / 2.5
    local y = (localVec.Y / 2.5) - 0.4
    local z = localVec.Z / 2.5

    return Vector3.new(x, y, z)
end
local function PlotVecToGlobalVec(plotvec:Vector3)
    local vec1 = zone.Position + Vector3.new(plotvec.X*2.5,(plotvec.Y+0.4)*2.5,plotvec.Z*2.5)
    return vec1
end
---raycast overwrite setup
local pceos_mousepos
if workspacemt then
    setreadonly(workspacemt, false)
    local oldIndex = workspacemt.__index
    workspacemt.__index = newcclosure(function(self, key)
        if self == workspace and key == "Raycast" then
            return function(selfArg, origin, direction, raycastParams)
                -- Handle colon-style calls
                if typeof(origin) ~= "Vector3" then
                    raycastParams = direction
                    direction = origin
                    origin = selfArg
                end

                -- Call the original raycast
                local result = originalRaycast(selfArg, origin, direction, raycastParams)
                if result then
                    -- Offset the hit position by +5 on the X axis
                    local Players = game:GetService("Players")
                    local plr = Players.LocalPlayer
                    local newPosition
                    if not workspace:FindFirstChild("PCEOS_MOUSE_OVEWRITE") then
                        local p = Instance.new("Part",workspace)
                        p.Size = Vector3.new(1,1,1)
                        p.Name = "PCEOS_MOUSE_OVEWRITE"
                        p.CanCollide = false
                        p.CanTouch = false
                        p.CanQuery = false
                        p.Transparency = 0.5
                        p.Anchored = true
                        p.Color = Color3.new(1,0,0)
                    end
                    if pceos_mousepos then
                        newPosition = pceos_mousepos-Vector3.new(0,2.5,0)
                        workspace:FindFirstChild("PCEOS_MOUSE_OVEWRITE").Position = pceos_mousepos
                    end
                    -- Return a modified RaycastResult
                    return {
                        Instance = result.Instance,
                        Position = newPosition or result.Position,
                        Normal = result.Normal,
                        Material = result.Material,
                    }
                end

                return nil
            end
        end
        return oldIndex(self, key)
    end)
    setreadonly(workspacemt, true)
end
--setting block
local function checkstatus(ID)
    repeat task.wait() until workspace.Camera.BuildObjects:FindFirstChildOfClass("Model")
    return workspace.Camera.BuildObjects:FindFirstChildOfClass("Model").ID.Value ~= ID
end
local function setblock(id)
	game:GetService("Players").LocalPlayer.PlayerGui.BuildGUI2.Bindables.BlockSelected:Fire(id)
end
local function setblock2(id)
	game:GetService("Players").LocalPlayer.PlayerGui.BuildGUI2.Bindables.BlockSelected2:Fire(id)
end
--others
local function buildmode()
    game:GetService("Players").LocalPlayer.PlayerGui.BuildGui.EnableBuilding:Fire()
end
local function isPointOccupied(point)
    local ac = workspace:FindFirstChild("PIayerAircraft"):FindFirstChild(game.Players.LocalPlayer.Name)
    if not ac then return false end

    for _, model in ipairs(ac:GetChildren()) do
        if model:IsA("Model") then
            local hitbox = model:FindFirstChild("HitBox")
            if hitbox and hitbox:IsA("BasePart") then
                -- Convert point into hitbox's local space
                local localPoint = hitbox.CFrame:PointToObjectSpace(point)
                local halfSize = hitbox.Size / 2

                -- Check if point lies within hitbox extents
                if math.abs(localPoint.X) <= halfSize.X
                and math.abs(localPoint.Y) <= halfSize.Y
                and math.abs(localPoint.Z) <= halfSize.Z then
                    return true
                end
            end
        end
    end

    return false
end



local function cframeToQuarterTurns(cf: CFrame): Vector3
    local x, y, z = cf:ToOrientation() -- safer for rotations
    local function radToSteps(rad: number): number
        local turns = math.floor(math.deg(rad) / 90 + 0.5)
        return (turns % 4)
    end
    return Vector3.new(
        radToSteps(x),
        radToSteps(y),
        radToSteps(z)
    )
end
-- Compute positive 90Â° rotations needed (0-3)
local function getSteps(target, current)
    current = math.floor(current + 0.5) % 4
    return (target - current) % 4
end

local function rotateBlock(cframe)
    local model = workspace.Camera.BuildObjects:FindFirstChildOfClass("Model")
    if not model then return end

    local buttons = game:GetService("Players").LocalPlayer.PlayerGui.BuildGUI2.Utilitybar2.Utilitybar2.BuildButtons
    local targetRot = cframeToQuarterTurns(cframe)
    local currentRot = cframeToQuarterTurns(model:GetPivot())

    local rotX = getSteps(targetRot.X, currentRot.X)
    local rotY = getSteps(targetRot.Y, currentRot.Y)
    local rotZ = getSteps(targetRot.Z, currentRot.Z)

    -- Rotate sequentially
    for i = 1, rotX do
        task.spawn(function()
            envbuild.RotateBlock(buttons.T, "X")
        end)
    end
    for i = 1, rotY do
        task.spawn(function()
            envbuild.RotateBlock(buttons.R, "Y")
        end)
    end
    for i = 1, rotZ do
        task.spawn(function()
            envbuild.RotateBlock(buttons:FindFirstChild("Y") or buttons.Z, "Z")
        end)
    end

    -- Wait a short time for tween to finish
    task.wait(0.15)

    -- Check rotation and retry recursively if needed
    local newRot = cframeToQuarterTurns(model:GetPivot())
    if newRot ~= targetRot then
        -- Retry with same arguments
        rotateBlock(cframe)
    else
        print("Rotation successful")
    end
end

local function showshortpreview(pos,color)
    local p = Instance.new("Part",workspace)
    p.Size = Vector3.new(1,1,1)
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Transparency = 0.5
    p.Anchored = true
    p.Color = color
    p.Position = pos
    task.spawn(function()
        task.wait(15)
        p:Destroy()
    end)
end

local function _G.placeblock(ID,origpos,cframe,config,color,material,applypivotoffset,retry)
    local arguments = {ID, origpos, cframe, config, color, material, applypivotoffset,retry}
    warn("[PCEOS]placing block",ID,"at",origpos,"with the rotation of",cframe)
    pceos_mousepos = PlotVecToGlobalVec(origpos)
    if not isPointOccupied(pceos_mousepos) then
        buildmode()
        if checkstatus(ID) then setblock(ID) end
        if checkstatus(ID) then setblock2(ID) end
        rotateBlock(cframe)
        
        --small block fix
        local box
        repeat
        local model = workspace.Camera.BuildObjects:FindFirstChildOfClass("Model")
        box = model:FindFirstChild("HitBox") or model:FindFirstChild("SelectionBoxPart")
        task.wait() until box
        local boxvec = Vector3.new(2.6, 2.6, 2.6)
        print("box:",box,boxvec)
        if box.Size.X < boxvec.X and box.Size.Y < boxvec.Y and box.Size.Z < boxvec.Z then
            origpos = Vector3.new(math.round(origpos.X),math.round(origpos.Y+0.1),math.round(origpos.Z))
        end
        
        
        local model = workspace.Camera.BuildObjects:FindFirstChildOfClass("Model")
        if applypivotoffset then
                local box = model:FindFirstChild("HitBox") or model:FindFirstChild("SelectionBoxPart")
                if box.Size ~= boxvec then
                    local g_offset_wrong = (blockdef[ID].Offset)
                    print("g_offset_wrong:",g_offset_wrong)
                    local g_offset = Vector3.new(
                    math.trunc(g_offset_wrong.X),
                    math.trunc(g_offset_wrong.Y),
                    math.trunc(g_offset_wrong.Z))*1.25--g_offset_wrong.X
                    print("g_offset:",g_offset)
                    local pivot = model:GetPivot()
                    local rotonly = CFrame.new(Vector3.new(0, 0, 0)) * CFrame.fromMatrix(Vector3.new(), pivot:vectorToWorldSpace(Vector3.new(1,0,0)), pivot:vectorToWorldSpace(Vector3.new(0,1,0)), pivot:vectorToWorldSpace(Vector3.new(0,0,1)))
                    local offset = (rotonly * CFrame.new(g_offset)).Position
                    print("offset",offset)
                    pceos_mousepos = pceos_mousepos-offset
                end
        end
        showshortpreview(model:GetBoundingBox().Position,Color3.new(0,1,0)  )
        showshortpreview(model:GetPivot().Position      ,Color3.new(0,0.5,0))
        showshortpreview(pceos_mousepos                 ,Color3.new(0,0,0))
        repeat task.wait() until isrbxactive()-- and workspace.Camera.BuildObjects:FindFirstChildOfClass("Model") and (workspace.Camera.BuildObjects:FindFirstChildOfClass("Model"):GetPivot().Position - pceos_mousepos).Magnitude <= 2
        local screenSize = camera.ViewportSize
        mousemoveabs(-screenSize.X,-screenSize.Y)
        mousemoveabs(screenSize.X/2,screenSize.Y/2)
        pcall(function()game:GetService("CoreGui").DevConsoleMaster.DevConsoleWindow.Visible = false end)
        
        local saved_pceos_mousepos = pceos_mousepos
        pceos_mousepos = nil
        pceos_mousepos = saved_pceos_mousepos
        --task.wait(0.1)
        local ac = workspace.PIayerAircraft:FindFirstChild(LocalPlayer.Name)
        local children = ac:GetChildren()
        local cc = 0
        mouse1click()
        task.wait(0.13)
    end
end
