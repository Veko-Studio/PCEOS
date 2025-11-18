local function PlotVecToGlobalVec(plotvec:Vector3,zone)
    local vec1 = zone.Position + Vector3.new(plotvec.X*2.5,(plotvec.Y+0.4)*2.5,plotvec.Z*2.5)
    return vec1
end

local function GetZone(player)
    local zone
    for _, zonei in workspace.BuildingZones:GetChildren() do
        if zonei.Owner.Value == player then zone = zonei end
    end
    return zone
end

-- Save original raycast BEFORE any potential copies are made
_G.originalRaycast = _G.originalRaycast or workspace.Raycast
local originalRaycast = _G.originalRaycast

local workspacemt
if getrawmetatable then workspacemt = getrawmetatable(workspace) end

---raycast overwrite setup
_G.pceos_mousepos = nil

-- Create the wrapper function ONCE and reuse it
local raycastWrapper = newcclosure(function(selfArg, origin, direction, raycastParams)
    -- Handle colon-style calls (workspace:Raycast)
    -- When called with colon, selfArg is workspace, origin is the actual origin
    local actualOrigin, actualDirection, actualParams
    
    if typeof(selfArg) == "Vector3" then
        -- Called as workspace.Raycast(origin, direction, params)
        -- This means selfArg is actually the origin
        actualOrigin = selfArg
        actualDirection = origin
        actualParams = direction
        selfArg = workspace
    else
        -- Called as workspace:Raycast(origin, direction, params)
        actualOrigin = origin
        actualDirection = direction
        actualParams = raycastParams
    end

    -- Call the original raycast with workspace as first arg
    local result = originalRaycast(workspace, actualOrigin, actualDirection, actualParams)
    
    if result then
        -- Print original result
        print("=== ORIGINAL RAYCAST RESULT ===")
        print("Instance:", result.Instance)
        print("Position:", result.Position)
        print("Normal:", result.Normal)
        print("Material:", result.Material)
        
        -- Offset the hit position by +5 on the X axis
        local Players = game:GetService("Players")
        local plr = Players.LocalPlayer
        local newPosition
        local newnormal
        
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
        
        if _G.pceos_mousepos ~= nil then
            newPosition = _G.pceos_mousepos - Vector3.new(0,2.5,0)
            newnormal = Vector3.new(0, 1, 0)
            workspace:FindFirstChild("PCEOS_MOUSE_OVEWRITE").Position = _G.pceos_mousepos
        end
        
        -- Print modified result
        print("=== MODIFIED RAYCAST RESULT ===")
        print("Instance:", result.Instance)
        print("Position:", newPosition or result.Position)
        print("Normal:", newnormal or result.Normal)
        print("Material:", result.Material)
        print("===============================\n")
        
        -- Return a modified RaycastResult
        return {
            Instance = result.Instance,
            Position = newPosition or result.Position,
            Normal = newnormal or result.Normal,
            Material = result.Material,
            Distance = result.Distance
        }
    end

    return nil
end)

if workspacemt then
    setreadonly(workspacemt, false)
    local oldIndex = workspacemt.__index
    workspacemt.__index = newcclosure(function(self, key)
        if self == workspace and key == "Raycast" then
            return raycastWrapper
        end
        return oldIndex(self, key)
    end)
    setreadonly(workspacemt, true)
end

function _G.positionpreviewblock(pos)
    _G.pceos_mousepos = pos
end
