local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local envbuild = getsenv(game.Players.LocalPlayer.PlayerGui.BuildGui.LocalBuildScript)
local zone = _G.RequestData1[1]:InvokeServer()

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local originalCameraType = camera.CameraType
local originalCameraSubject = camera.CameraSubject

local tempPart -- holds the temporary part

function SetCameraPosition(position: Vector3)
    -- Create the temp part
    tempPart = Instance.new("Part")
    tempPart.Anchored = true
    tempPart.Size = Vector3.new(2,2,0.05)--Vector3.new(5,5,0.05) -- flat surface
    tempPart.Transparency = 0
    tempPart.Position = position
    tempPart.Name = "TempCameraTarget"
    tempPart.Parent = Workspace

    local cameraPosition = position
    local partpos = position + Vector3.new(0, -1.5, 0)
    -- Make the camera look at the part
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = CFrame.new(cameraPosition, partpos) -- Look at the part

    -- Optional: make the part face the camera
    tempPart.CFrame = CFrame.new(partpos, camera.CFrame.Position)
end

function ResetCamera()
    -- Restore default camera
    camera.CameraType = originalCameraType
    camera.CameraSubject = originalCameraSubject

    -- Cleanup
    if tempPart and tempPart.Parent then
        tempPart:Destroy()
    end
    tempPart = nil
end
local function setblock(id)
game:GetService("Players").LocalPlayer.PlayerGui.BuildGUI2.Bindables.BlockSelected:Fire(id)
end
local function runButton1Down()
    if typeof(envbuild.button1down) == "function" then envbuild.button1down() end
end
local function getinplotposinworldspace(vec)
    print("getinplotposinworldspace zone:",zone)
    local vec1 = zone.Position + Vector3.new(vec.X*2.5,(vec.Y+0.4)*2.5,vec.Z*2.5)
    print("getinplotposinworldspace vec1:",vec1)
    return vec1
end
local function rotateblockto(block: Model, targetRot: Vector3)
    -- Simulated key presses for global axis rotation
    local function rotate90onR() keypress(82) keyrelease(82) end -- Global X
    local function rotate90onT() keypress(84) keyrelease(84) end -- Global Y
    local function rotate90onZ() keypress(90) keyrelease(90) end -- Global Z

    -- Get current rotation of the model (assumes block.PrimaryPart is set)
    local currentCF = block:GetPivot()
    local _, currentRotY, _ = currentCF:ToEulerAnglesYXZ()
    local x, y, z = currentCF:ToOrientation()
    
    local currentRot = Vector3.new(
        math.deg(x),
        math.deg(y),
        math.deg(z)
    )

    -- Round both current and target to nearest 90
    local function roundTo90(angle)
        return math.floor((angle % 360 + 45) / 90) % 4
    end

    local xSteps = (roundTo90(targetRot.X) - roundTo90(currentRot.X)) % 4
    local ySteps = (roundTo90(targetRot.Y) - roundTo90(currentRot.Y)) % 4
    local zSteps = (roundTo90(targetRot.Z) - roundTo90(currentRot.Z)) % 4

    -- Apply rotations in RTZ order (global axis)
    for _ = 1, xSteps do rotate90onR() end--wait() end
    for _ = 1, ySteps do rotate90onT() end--wait() end
    for _ = 1, zSteps do rotate90onZ() end--wait() end
end
local function buildmode()
    local Event = game:GetService("Players").LocalPlayer.PlayerGui.BuildGui.EnableBuilding
    Event:Fire()
end
local function findModelAtPosition(pos: Vector3)
    local playerName = Players.LocalPlayer.Name
    local aircraftFolder = workspace:FindFirstChild("PIayerAircraft")
    if not aircraftFolder then return nil end

    local playerAircraft = aircraftFolder:FindFirstChild(playerName)
    if not playerAircraft then return nil end

    for _, model in ipairs(playerAircraft:GetChildren()) do
        if model:IsA("Model") and model.PrimaryPart then
            local modelPos = model:GetPivot().Position
            if (modelPos - pos).Magnitude < 0.001 then -- tiny tolerance to avoid float mismatch
                return model
            end
        end
    end

    return nil
end
local function getinplotposinworldspace(vec)
    print("getinplotposinworldspace zone:",zone)
    local vec1 = zone.Position + Vector3.new(vec.X*2.5,(vec.Y+0.4)*2.5,vec.Z*2.5)
    print("getinplotposinworldspace vec1:",vec1)
    return vec1
end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Levenshtein Distance function for string similarity
local function levenshtein(s, t)
    local len_s = #s
    local len_t = #t
    local matrix = {}

    for i = 0, len_s do
        matrix[i] = {}
        matrix[i][0] = i
    end
    for j = 0, len_t do
        matrix[0][j] = j
    end

    for i = 1, len_s do
        for j = 1, len_t do
            if s:sub(i,i) == t:sub(j,j) then
                matrix[i][j] = matrix[i-1][j-1]
            else
                matrix[i][j] = math.min(
                    matrix[i-1][j] + 1,
                    matrix[i][j-1] + 1,
                    matrix[i-1][j-1] + 1
                )
            end
        end
    end

    return matrix[len_s][len_t]
end

function _G.getBlockIDFromName(name)
    local container = LocalPlayer.PlayerGui.BuildGUI2.BuildMenu.Container.Container.BlockMenu
    if not container then
        return 1
    end

    local descendants = container:GetDescendants()
    local closestModel = nil
    local smallestDistance = math.huge

    for _, descendant in ipairs(descendants) do
        if descendant:IsA("Model") and descendant.Name then
            local dist = levenshtein(descendant.Name:lower(), name:lower())
            if dist < smallestDistance then
                smallestDistance = dist
                closestModel = descendant
            end
        end
    end

    if closestModel and closestModel.Parent and closestModel.Parent.Parent then
        return tonumber(closestModel.Parent.Parent.Name) or 1
    else
        return 1
    end
end

function _G.placeblock(id, pos, rot)
    print("")
    print("")
    print("")
    print("-------------------------")
    local function timed(label, func)
        local start = tick()
        func()
        task.spawn(function()
            warn("[PCEOS]"..label .. " took", tick() - start, "s")
        end)
    end

    local totalStart = tick()
    timed("occupied space check", function()
        if findModelAtPosition(getinplotposinworldspace(pos)) then return end
    end)

    local success, result_or_error = pcall(function()
        timed("Wait for RBX active", function()
            if not isrbxactive() then
                repeat task.wait() until isrbxactive()
            end
        end)
        timed("modelget1", function()
            local e = workspace.Camera.BuildObjects:FindFirstChildWhichIsA("Model")
        end)
        timed("Build mode and modelget2", function()
            if (not e) or e:FindFirstChild("SelectionBoxNoPos") then
                buildmode() task.wait(0.3)
                e = workspace.Camera.BuildObjects:FindFirstChildWhichIsA("Model")
            end
        end)
        timed("Set block", function()
            if e and e:FindFirstChild("ID") and e:FindFirstChild("ID").Value ~= id then
                task.spawn(function() setblock(id) end)
            end
        end)
        task.wait()

        timed("Set camera", function()
            SetCameraPosition(getinplotposinworldspace(pos))
        end)
        task.wait()

        timed("Rotate block", function()
            rotateblockto(e, rot)
        end)
        task.wait()

        timed("Run Button1Down", function()
            task.spawn(runButton1Down)
        end)
        task.wait(0.09)
    end)
    print(result_or_error)

    timed("Reset camera", ResetCamera)
    task.wait()

    print("[PCEOS]placeblock() total time including the task.wait()'s:", tick() - totalStart, "seconds")
    print("-------------------------")
end
