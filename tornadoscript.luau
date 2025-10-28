loadstring(game:HttpGet("https://raw.githubusercontent.com/Veko-Studio/PCEOS-FUNCTIONS/refs/heads/main/function_deweldaircraft.luau"))()
_G.deweldaircraft()


_G.Radius = 50
_G.Thick = 5
_G.speed = 1
_G.Offset = 0

local localplayer = game.Players.LocalPlayer
local aircraft = workspace:FindFirstChild(localplayer.Name.." Aircraft")

-- Random unit vectors on two perpendicular planes
local function randomUnitXZ()
    local angle = math.random() * math.pi * 2
    return Vector3.new(math.cos(angle), 0, math.sin(angle))
end

local function randomUnitYZ()
    local angle = math.random() * math.pi * 2
    return Vector3.new(0, math.cos(angle), math.sin(angle))
end

local function randomStep()
    local choices = {-0.05, 0, 0.05}
    return choices[math.random(1, #choices)]
end

local function wrapAngle(angle)
    angle = angle % 360
    if angle > 180 then
        angle = angle - 360
    end
    return angle
end


-- Stable rotation around Y-axis only (prevents NaN)
local function rotateAroundOrigin3D(pos, xDeg, yDeg, zDeg)
    local x, y, z = pos.X, pos.Y, pos.Z
    local rad = math.rad(yDeg)
    local cosR, sinR = math.cos(rad), math.sin(rad)

    -- Rotate on XZ plane
    local newX = x * cosR - z * sinR
    local newZ = x * sinR + z * cosR

    -- Check for invalid results
    if newX ~= newX or newZ ~= newZ then
        return Vector3.zero
    end

    return Vector3.new(newX, y, newZ)
end

-- Safe AlignPosition/AlignOrientation setup
local function applyforce(part, pos_, rot_)
    if not part then return end
    for _, n in ipairs({"PCEOS_pos","PCEOS_rot","PCEOS_atta"}) do
        local f = part:FindFirstChild(n)
        if f then f:Destroy() end
    end

    local atta = Instance.new("Attachment", part)
    atta.Name = "PCEOS_atta"

    local pos = Instance.new("AlignPosition", part)
    pos.Name = "PCEOS_pos"
    pos.Position = pos_
    pos.Mode = Enum.PositionAlignmentMode.OneAttachment
    pos.Attachment0 = atta
    pos.Responsiveness = 999999999999999999
    pos.MaxVelocity = 500
    pos.MaxForce = 25000

    local rot = Instance.new("AlignOrientation", part)
    rot.Name = "PCEOS_rot"
    rot.CFrame = CFrame.Angles(rot_.X, rot_.Y, rot_.Z)
    rot.RigidityEnabled = true
    rot.Mode = Enum.OrientationAlignmentMode.OneAttachment
    rot.Attachment0 = atta
    rot.Responsiveness = 10
end

-- === MAIN ===
for _, child in aircraft:GetChildren() do
    task.wait(0.05)
    if child:IsA("Model") and child.PrimaryPart then
        -- Create unit direction bases for both rings
        local baseXZ = randomUnitXZ() -- horizontal circle
        local baseYZ = randomUnitYZ() -- vertical circle

        local Radius = _G.Radius or 50
        local Thick = _G.Thick or 5

        local posXZ = baseXZ * Radius
        local posYZ = baseYZ * Thick
        local rot = Vector3.new(math.random(0,180), math.random(0,180), math.random(0,180))

        task.spawn(function()
            local randomrot = Vector3.new(randomStep(), randomStep(), randomStep())
            for _, part in child:GetDescendants() do
                pcall(function() part.CanCollide = false end)
                if part:IsA("Seat") then part.Disabled = true end
            end

            while aircraft do
                if _G.Radius == 0 then _G.Radius = 0.1 end
                if _G.Thick == 0 then _G.Thick = 0.1 end
                task.wait(0.05)
                local hrp = localplayer.Character and localplayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then break end
                local playerpos = hrp.Position

                rot += randomrot
				rot = Vector3.new(
					wrapAngle(rot.X),
					wrapAngle(rot.Y),
					wrapAngle(rot.Z)
				)
				
                posXZ = rotateAroundOrigin3D(posXZ, 0, _G.speed or 1, 0)

                -- Detect scaling changes safely
                local newRadius = _G.Radius or Radius
                local newThick = _G.Thick or Thick

                -- Scale horizontal ring
                if newRadius ~= Radius and Radius ~= 0 then
                    posXZ *= (newRadius / Radius)
                    Radius = newRadius
                end

                -- Scale vertical ring
                if newThick ~= Thick and Thick ~= 0 then
                    posYZ *= (newThick / Thick)
                    Thick = newThick
                end

                -- Combine both offsets
                local finalPos = posXZ + posYZ + Vector3.new(0, _G.Offset or 0, 0)

                -- Validate vector (prevent NaN)
                if finalPos.X == finalPos.X and finalPos.Y == finalPos.Y and finalPos.Z == finalPos.Z then
                    applyforce(child.PrimaryPart, playerpos + finalPos, rot)
                else
                    warn("NaN detected in finalPos, skipping frame")
                end
            end
            print("Aircraft not found: ending code")
        end)
    end
end
