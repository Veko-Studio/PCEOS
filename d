local size = _G.size
local meshonly = _G.meshonly
local configremote = game:GetService("ReplicatedStorage").Remotes.UpdateValue
local flightmodeuiremote = game:GetService("Players")["535345h2h7ii785445"].PlayerGui.BuildGUI2.Bindables.FlightModeActivated
local spawnremote = game:GetService("Players")["535345h2h7ii785445"].PlayerGui.BuildGui.Spawn
loadstring(game:HttpGet("https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/Emotes.lua"))()

local NotificationLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/IceMinisterq/Notification-Library/Main/Library.lua"))()
if meshonly then
	neededropes = 64*6
else
	NotificationLibrary:SendNotification("Error","can't give an accurate needed amount for this mode",10)
	neededropes = math.ceil(23.52*size)
end
local ropes = {}
local ac = workspace.PIayerAircraft:FindFirstChild(game.Players.LocalPlayer.Name)
for _, child in ac and ac:GetChildren() or {} do
    if child.Name == "Rope" then table.insert(ropes,child) end
end

if not ac then
    NotificationLibrary:SendNotification("Error","not in build mode",10)
    error("")
end
if #ropes < neededropes then
    NotificationLibrary:SendNotification("Error","not enough ropes "..tostring(#ropes).."/"..tostring(neededropes),10)
    error("")
end









local ac_c = #ac:GetChildren()-3
spawnremote:Fire(true)
repeat
task.wait()
until workspace:FindFirstChild(game.Players.LocalPlayer.Name.." Aircraft") and #workspace:FindFirstChild(game.Players.LocalPlayer.Name.." Aircraft"):GetChildren()-1==ac_c
ac = workspace:FindFirstChild(game.Players.LocalPlayer.Name.." Aircraft")
warn("finished spawning")
task.wait(1)
local trails = {}
for _, block in ac:GetChildren() do
	if block.Name == "Rope" then table.insert(trails,block) end
end
local nodes = {}
for _, block in ac:GetChildren() do
	if block.Name == "CompressionBlock" then table.insert(nodes,block) end
end
local hide = {}
for _, block in ac:GetChildren() do
	if block.Name == "BlockStd" then table.insert(hide,block) end
end
warn("rope", #trails,"compress",#nodes)
local UIS = game:GetService("UserInputService")
loadstring(game:HttpGet("https://raw.githubusercontent.com/sametcetinkaya1447/planecrazy2/refs/heads/main/folder/pcutils.lua"))()
local TOTAL = 0
local function createpanel(center, offset, x, y)
	TOTAL=TOTAL+(y/2.5)
	local corners = {
		{
			p1 = Vector3.new(-x/2, -y/2, 0),
			p2 = Vector3.new( x/2, -y/2, 0),
		},
		{
			p1 = Vector3.new( x/2, -y/2, 0),
			p2 = Vector3.new( x/2,  y/2, 0),
		},
		{
			p1 = Vector3.new( x/2,  y/2, 0),
			p2 = Vector3.new(-x/2,  y/2, 0),
		},
		{
			p1 = Vector3.new(-x/2,  y/2, 0),
			p2 = Vector3.new(-x/2, -y/2, 0),
		},
		{
			p1 = Vector3.new(-x/2,  -y/2, 0),
			p2 = Vector3.new(x/2, y/2, 0),
		},
		{
			p1 = Vector3.new(x/2,  -y/2, 0),
			p2 = Vector3.new(-x/2, y/2, 0),
		},
	}
	if not meshonly then
		corners = {}

		local step = 2
		local count = math.floor(y / step)

		local startY = -y/2 + step/2

		for i = 0, count - 1 do
			local yOffset = startY + (i * step)

			table.insert(corners, {
				p1 = Vector3.new(-x/2, yOffset, 0),
				p2 = Vector3.new( x/2, yOffset, 0),
			})
		end
	end

	local function runEdge(data)
		task.spawn(function()
			local target = trails[1]
			table.remove(trails, 1)

			target.Main.CanCollide = false
			target.Other.CanCollide = false
			target.Invisible.CanCollide = false

			target.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
			target.PrimaryPart.AssemblyAngularVelocity = Vector3.zero

			Weld(center, target.Main, offset * CFrame.new(data.p1))
			Weld(center, target.Other, offset * CFrame.new(data.p2))

			print("ending")
		end)
	end

	for i = 1, #corners do
		runEdge(corners[i])
		task.wait()
	end
end
function createHollowCylinder(centerPart, centerCF, sizeX, sizeY, sizeZ, faces)
	local panelHeight = sizeY

	-- 🔲 SPECIAL CASE: cube / rectangular prism
	if faces == 4 then
		local halfX = sizeX / 2
		local halfZ = sizeZ / 2

		local sides = {
			{pos = Vector3.new(0, 0, -halfZ), width = sizeX, angle = 0},              -- front
			{pos = Vector3.new(halfX, 0, 0),  width = sizeZ, angle = math.pi/2},     -- right
			{pos = Vector3.new(0, 0, halfZ),  width = sizeX, angle = math.pi},       -- back
			{pos = Vector3.new(-halfX, 0, 0), width = sizeZ, angle = -math.pi/2},    -- left
		}

		for i = 1, 4 do
			local side = sides[i]

			local offset = centerCF
				* CFrame.new(side.pos)
				* CFrame.Angles(0, -side.angle, 0)

			createpanel(
				centerPart,
				offset,
				side.width,
				panelHeight
			)
		end

		return
	end

	-- 🟢 DEFAULT: ellipse / cylinder
	local radiusX = sizeX / 2
	local radiusZ = sizeZ / 2

	for i = 0, faces - 1 do
		local angle1 = (i / faces) * math.pi * 2
		local angle2 = ((i + 1) / faces) * math.pi * 2

		local x1 = math.cos(angle1) * radiusX
		local z1 = math.sin(angle1) * radiusZ

		local x2 = math.cos(angle2) * radiusX
		local z2 = math.sin(angle2) * radiusZ

		local mx = (x1 + x2) / 2
		local mz = (z1 + z2) / 2

		local dx = x2 - x1
		local dz = z2 - z1
		local panelWidth = math.sqrt(dx*dx + dz*dz)

		local angle = math.atan2(dz, dx)

		local offset = centerCF
			* CFrame.new(mx, 0, mz)
			* CFrame.Angles(0, -angle, 0)

		createpanel(
			centerPart,
			offset,
			panelWidth,
			panelHeight
		)
	end
end
local RunService = game:GetService("RunService")

local function followParts(part1, part2)
	-- Position control
	local bodyPos = Instance.new("BodyPosition")
	bodyPos.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyPos.P = 100000
	bodyPos.D = 500
	bodyPos.Parent = part1

	-- Rotation control
	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bodyGyro.P = 100000
	bodyGyro.D = 500
	bodyGyro.Parent = part1

	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not (part1 and part2 and part1.Parent and part2.Parent) then
			conn:Disconnect()
			bodyPos:Destroy()
			bodyGyro:Destroy()
			return
		end

		part1.AssemblyLinearVelocity = Vector3.zero
		part1.AssemblyAngularVelocity = Vector3.zero

		bodyPos.Position = part2.Position
		bodyGyro.CFrame = part2.CFrame
	end)
end
warn("defined funcs")
local chr_r = game.Players.LocalPlayer.Character
local parts = {
	"Head",
	"UpperTorso",
	"LowerTorso",
	"LeftUpperLeg",
	"RightUpperLeg",
	"LeftLowerLeg",
	"RightLowerLeg",
	"LeftFoot",
	"RightFoot",
	"LeftUpperArm",
	"RightUpperArm",
	"LeftLowerArm",
	"RightLowerArm",
	"LeftHand",
	"RightHand",
}
local chr = {}
for i, limb in parts do
	print(nodes[i])
	repeat task.wait() until nodes[i]:FindFirstChild("CompressedBlock")
	pcall(function()
		chr[limb]=nodes[i].CompressedBlock
		followParts(nodes[i].CompressedBlock,chr_r[limb])
	end)
end
chr_r:ScaleTo(1)
game.Players.LocalPlayer.Character:WaitForChild("Humanoid").WalkSpeed = 16
chr_r:ScaleTo(size)
warn("scaled")
createHollowCylinder(
	chr.Head,
	CFrame.new(0,0.1*size,0),
	1.4*size,  -- sizeX (diameter)
	1.4*size,  -- sizeY (height)
	1.4*size,   -- sizeZ (thickness, mostly visual depending on your panel)
	8   -- faces
)
createHollowCylinder(
	chr.UpperTorso,
	CFrame.new(0,0.1*size,0),
	1.7*size,  -- sizeX (diameter)
	1.7*size,  -- sizeY (height)
	1*size,   -- sizeZ (thickness, mostly visual depending on your panel)
	4   -- faces
)
createHollowCylinder(
	chr.LowerTorso,
	CFrame.new(0,-0.2*size,0),
	1.7*size,  -- sizeX (diameter)
	0.3*size,  -- sizeY (height)
	1*size,   -- sizeZ (thickness, mostly visual depending on your panel)
	4   -- faces
)
createHollowCylinder(
	chr.LeftUpperLeg,
	CFrame.new(0,0*size,0),
	0.8*size,  -- sizeX (diameter)
	1.3*size,  -- sizeY (height)
	0.8*size,   -- sizeZ (thickness, mostly visual depending on your panel)
	4   -- faces
)
createHollowCylinder(
	chr.RightUpperLeg,
	CFrame.new(0,0*size,0),
	0.8*size,  -- sizeX (diameter)
	1.3*size,  -- sizeY (height)
	0.8*size,   -- sizeZ (thickness, mostly visual depending on your panel)
	4   -- faces
)
createHollowCylinder(
	chr.LeftLowerLeg,
	CFrame.new(0,0*size,0),
	0.8*size,  -- sizeX (diameter)
	0.9*size,  -- sizeY (height)
	0.8*size,   -- sizeZ (thickness, mostly visual depending on your panel)
	4   -- faces
)
createHollowCylinder(
	chr.RightLowerLeg,
	CFrame.new(0,0*size,0),
	0.8*size,  -- sizeX (diameter)
	0.9*size,  -- sizeY (height)
	0.8*size,   -- sizeZ (thickness, mostly visual depending on your panel)
	4   -- faces
)
createHollowCylinder(
	chr.LeftFoot,
	CFrame.new(0,-0.35*size/2,0),
	0.8*size,  -- sizeX (diameter)
	0.35*size,  -- sizeY (height)
	1*size,   -- sizeZ (thickness, mostly visual depending on your panel)
	4   -- faces
)
createHollowCylinder(
	chr.RightFoot,
	CFrame.new(0,-0.35*size/2,0),
	0.8*size,  -- sizeX (diameter)
	0.35*size,  -- sizeY (height)
	1*size,   -- sizeZ (thickness, mostly visual depending on your panel)
	4   -- faces
)
createHollowCylinder(
	chr.LeftUpperArm,
	CFrame.new(0,0.2*size,0)*CFrame.fromEulerAnglesXYZ(math.rad(-10),math.rad(15),math.rad(-10)),
	0.7*size,  -- sizeX (diameter)
	1*size,  -- sizeY (height)
	0.7*size,   -- sizeZ (thickness, mostly visual depending on your panel)
	4   -- faces
)
createHollowCylinder(
	chr.RightUpperArm,
	CFrame.new(0,0.2*size,0)*CFrame.fromEulerAnglesXYZ(math.rad(-10),math.rad(-15),math.rad(10)),
	0.7*size,  -- sizeX (diameter)
	1*size,  -- sizeY (height)
	0.7*size,   -- sizeZ (thickness, mostly visual depending on your panel)
	4   -- faces
)
createHollowCylinder(
	chr.LeftLowerArm,
	CFrame.new(0.15*size,0.15*size,0)*CFrame.fromEulerAnglesXYZ(math.rad(20),math.rad(15),math.rad(-10)),
	0.7*size,  -- sizeX (diameter)
	0.9*size,  -- sizeY (height)
	0.7*size,   -- sizeZ (thickness, mostly visual depending on your panel)
	4   -- faces
)
createHollowCylinder(
	chr.RightLowerArm,
	CFrame.new(-0.15*size,0.15*size,0)*CFrame.fromEulerAnglesXYZ(math.rad(20),math.rad(-15),math.rad(10)),
	0.7*size,  -- sizeX (diameter)
	0.9*size,  -- sizeY (height)
	0.7*size,   -- sizeZ (thickness, mostly visual depending on your panel)
	4   -- faces
)
createHollowCylinder(
	chr.LeftHand,
	CFrame.new(0.1*size,0*size,0.1*size)*CFrame.fromEulerAnglesXYZ(math.rad(20),math.rad(-10),math.rad(10)),
	0.7*size,  -- sizeX (diameter)
	0.5*size,  -- sizeY (height)
	0.7*size,   -- sizeZ (thickness, mostly visual depending on your panel)
	4   -- faces
)
createHollowCylinder(
	chr.RightHand,
	CFrame.new(-0.1*size,0*size,0.1*size)*CFrame.fromEulerAnglesXYZ(math.rad(20),math.rad(10),math.rad(-10)),
	0.7*size,  -- sizeX (diameter)
	0.5*size,  -- sizeY (height)
	0.7*size,   -- sizeZ (thickness, mostly visual depending on your panel)
	4   -- faces
)
print("hide",#hide)
Weld(hide[1].BlockStd,chr_r.HumanoidRootPart,CFrame.new(0,1.25,0))
Weld(hide[2].BlockStd,chr_r.HumanoidRootPart,CFrame.new(0,-1.25,0))
print("eeeeeeeeeeeeeeeeee,TOTA",TOTAL)
repeat task.wait(0.1) game.Players.LocalPlayer.Character:WaitForChild("Humanoid").WalkSpeed = 16*size until not string.find(ac:GetFullName(), "Workspace")
print("e2dd")
game.Players.LocalPlayer.Character:ScaleTo(1)
game.Players.LocalPlayer.Character:WaitForChild("Humanoid").WalkSpeed = 16
flightmodeuiremote:Fire(false)
