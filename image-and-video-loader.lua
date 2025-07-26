local image = [[
import os
import sys

# Try to import Pillow, install if not found
try:
    from PIL import Image
except ImportError:
    print("Pillow not found — installing...")
    os.system(f"{sys.executable} -m pip install pillow")
    from PIL import Image

TARGET_SIZE = (51, 51)
VALID_EXTENSIONS = (".png", ".jpg", ".jpeg", ".bmp", ".gif", ".tiff", ".webp", ".jfif")

def save_pixels(image, output_filename):
    # Ensure the results folder exists
    os.makedirs("results", exist_ok=True)

    # Save the file inside the results folder
    output_path = os.path.join("results", output_filename)

    pixels = list(image.getdata())
    with open(output_path, "w") as f:
        for rgb in pixels:
            f.write(f"{rgb[0]},{rgb[1]},{rgb[2]}\n")

def process_image(filename):
    try:
        with Image.open(filename) as img:
            img = img.convert("RGB")

            # With Antialiasing
            img_aa = img.copy()
            img_aa.thumbnail(TARGET_SIZE, Image.LANCZOS)
            new_img_aa = Image.new("RGB", TARGET_SIZE, (0, 0, 0))
            offset_x = (TARGET_SIZE[0] - img_aa.width) // 2
            offset_y = (TARGET_SIZE[1] - img_aa.height) // 2
            new_img_aa.paste(img_aa, (offset_x, offset_y))

            base, _ = os.path.splitext(filename)
            output_filename_aa = base + "_aa.txt"
            save_pixels(new_img_aa, output_filename_aa)

            # Without Antialiasing
            img_noaa = img.copy()
            img_noaa.thumbnail(TARGET_SIZE, Image.NEAREST)
            new_img_noaa = Image.new("RGB", TARGET_SIZE, (0, 0, 0))
            offset_x = (TARGET_SIZE[0] - img_noaa.width) // 2
            offset_y = (TARGET_SIZE[1] - img_noaa.height) // 2
            new_img_noaa.paste(img_noaa, (offset_x, offset_y))

            output_filename_noaa = base + "_noaa.txt"
            save_pixels(new_img_noaa, output_filename_noaa)

            print(f"Saved: {output_filename_aa} and {output_filename_noaa}")

    except Exception as e:
        print(f"Skipping {filename}: {e}")

def main():
    for filename in os.listdir("."):
        if filename.lower().endswith(VALID_EXTENSIONS):
            process_image(filename)

if __name__ == "__main__":
    main()
]]

local video = [[
import os
import sys
import numpy as np

try:
    import cv2
except ImportError:
    print("OpenCV not found — installing...")
    os.system(f"{sys.executable} -m pip install opencv-python")
    import cv2

TARGET_SIZE = (51, 51)

VALID_EXTENSIONS = (
    ".mp4", ".mov", ".avi", ".mkv", ".webm", ".flv", ".wmv", ".mpg", ".mpeg",
    ".m4v", ".3gp", ".ogv", ".mts", ".m2ts", ".ts", ".vob", ".rm", ".rmvb",
    ".f4v", ".divx", ".asf", ".mxf", ".bik", ".drc", ".mve", ".nsv", ".amv",
    ".yuv", ".vp9", ".h264", ".264", ".mp2", ".m1v", ".mod", "gif"
)

def write_frame_pixels(frame, file_handle):
    pixels = frame.reshape(-1, 3)
    for rgb in pixels:
        file_handle.write(f"{rgb[2]},{rgb[1]},{rgb[0]}\n")  # BGR to RGB

def resize_with_padding(image, target_size, interpolation):
    h, w = image.shape[:2]
    target_w, target_h = target_size
    scale = min(target_w / w, target_h / h)
    new_w = int(w * scale)
    new_h = int(h * scale)
    resized = cv2.resize(image, (new_w, new_h), interpolation=interpolation)

    # Create a black canvas and paste the resized image onto it
    padded = cv2.copyMakeBorder(
        resized,
        top=(target_h - new_h) // 2,
        bottom=(target_h - new_h + 1) // 2,
        left=(target_w - new_w) // 2,
        right=(target_w - new_w + 1) // 2,
        borderType=cv2.BORDER_CONSTANT,
        value=(0, 0, 0)
    )
    return padded

def process_video(filename):
    cap = cv2.VideoCapture(filename)
    if not cap.isOpened():
        print(f"Skipping {filename}: cannot open video.")
        return

    fps = cap.get(cv2.CAP_PROP_FPS)
    base_name = os.path.splitext(filename)[0]
    os.makedirs("results", exist_ok=True)

    output_aa_path = os.path.join("results", base_name + "_aa.txt")
    output_noaa_path = os.path.join("results", base_name + "_noaa.txt")

    with open(output_aa_path, "w") as f_aa, open(output_noaa_path, "w") as f_noaa:
        f_aa.write(f"FPS: {fps:.2f}\n")
        f_noaa.write(f"FPS: {fps:.2f}\n")

        prev_frame_aa = None
        prev_frame_noaa = None
        noise_threshold = 10  # max pixel diff allowed to consider noise (tune as needed)

        frame_index = 0
        while True:
            ret, frame = cap.read()
            if not ret:
                break

            # Resize frames
            frame_aa = resize_with_padding(frame, TARGET_SIZE, interpolation=cv2.INTER_LANCZOS4)
            frame_noaa = resize_with_padding(frame, TARGET_SIZE, interpolation=cv2.INTER_NEAREST)

            # Noise reduction for AA frame
            if prev_frame_aa is not None:
                diff = cv2.absdiff(frame_aa, prev_frame_aa)
                mask = np.all(diff <= noise_threshold, axis=2)
                frame_aa[mask] = prev_frame_aa[mask]
            prev_frame_aa = frame_aa.copy()

            # Noise reduction for No AA frame
            if prev_frame_noaa is not None:
                diff = cv2.absdiff(frame_noaa, prev_frame_noaa)
                mask = np.all(diff <= noise_threshold, axis=2)
                frame_noaa[mask] = prev_frame_noaa[mask]
            prev_frame_noaa = frame_noaa.copy()

            # Write frames to files
            f_aa.write(f"--- Frame {frame_index} ---\n")
            write_frame_pixels(frame_aa, f_aa)
            f_aa.write("------\n")

            f_noaa.write(f"--- Frame {frame_index} ---\n")
            write_frame_pixels(frame_noaa, f_noaa)
            f_noaa.write("------\n")

            frame_index += 1

    cap.release()
    print(f"Processed {frame_index} frames from {filename} into:")
    print(f"  {output_aa_path}")
    print(f"  {output_noaa_path}")

def main():
    for filename in os.listdir("."):
        if filename.lower().endswith(VALID_EXTENSIONS):
            process_video(filename)

if __name__ == "__main__":
    main()
]]

local cmd = [[
python convert.py
]]
---
makefolder("plane crazy")
---
makefolder("plane crazy/videos")
makefolder("plane crazy/videos/results")
makefolder("plane crazy/images/to not scan")
writefile("plane crazy/videos/convert.py",video)
writefile("plane crazy/videos/runpy.cmd",cmd)
---
---
makefolder("plane crazy/images")
makefolder("plane crazy/images/results")
makefolder("plane crazy/images/to not scan")
writefile("plane crazy/images/convert.py",image)
writefile("plane crazy/images/runpy.cmd",cmd)
---
local sf
local gui

local LocalPlayer = game.Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local previousColors = {}

local function colorsAreDifferent(c1, c2)
	local tolerance = 0.04
	return math.abs(c1.R - c2.R) > tolerance
		or math.abs(c1.G - c2.G) > tolerance
		or math.abs(c1.B - c2.B) > tolerance
end

local function getModelList()
	local playerAircraft = workspace.PIayerAircraft:FindFirstChild(LocalPlayer.Name)
	if not playerAircraft then return {} end

	local models = {}
	for _, b in playerAircraft:GetChildren() do
		if b.Name == "BlockStd" then
			table.insert(models, b)
		end
	end

	table.sort(models, function(a, b)
		local posA = a.BlockStd.Position
		local posB = b.BlockStd.Position
		if posA.Z == posB.Z then
			return posA.X < posB.X
		else
			return posA.Z < posB.Z
		end
	end)

	return models
end

local function parseColorsFromText(text)
	local colors = {}
	for line in string.gmatch(text, "[^\r\n]+") do
		local r, g, b = line:match("(%d+),(%d+),(%d+)")
		if r and g and b then
			table.insert(colors, Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)))
		end
	end
	return colors
end


local function buildModeHandler(mode, configs)
	if not workspace.PIayerAircraft:FindFirstChild(LocalPlayer.Name) then
		error("Not in build mode")
	end
	_G.buildModeHandler_end_old = true
	wait(0)
	_G.buildModeHandler_end_old = false

	local modellist = getModelList()
	if workspace.BuildingZones:FindFirstChild("e") then workspace.BuildingZones:FindFirstChild("e"):destroy() end
	if #getModelList() ~= 51*51 then
	local zone = _G.RequestData1[1]:InvokeServer():Clone()
	zone.Name = "e"
	zone.Position = Vector3.new(zone.Position.X, 55.5, zone.Position.Z)
	zone.Size = Vector3.new(127.48999786376953, 3.5, 127.48999786376953)
	zone.Transparency = 0.8
	zone.Color = Color3.new(0,1,0)
	zone.Parent = workspace.BuildingZones
	for _, child in zone:GetChildren() do
		child:destroy()
	end
    sf.Visible = false
	repeat task.wait(0.5) if zone == nil or gui == nil then zone:Destroy() return end until #getModelList() == 51*51
	zone:Destroy()
    modellist = getModelList()
	end

	if mode == "image" then
		local colors = {}
		local rawText = configs.rawText
		local imageName = configs.image or "test"
		if configs.antialiasing == false then
			imageName = imageName .. "_no"
		else
			imageName = imageName .. "_"
		end

		if rawText then
			colors = parseColorsFromText(rawText)
		else
			if typeof(readfile) ~= "function" then print("executor does not support readfile") return end
			local success, result = pcall(function()
				return readfile("plane crazy/images/results/" .. imageName .. "aa.txt")
			end)
			if not success then
				success, result = pcall(function()
					return readfile("plane crazy/images/" .. imageName)
				end)
				if not success then
					print("Image does not exist at all.")
					return
				end
				if success then
					print("Image has not been converted by python script.")
					return
				end
			end
			colors = parseColorsFromText(result)
		end

		-- Precompute changes
		local changeIndices = {}
		for i, data in modellist do
			local blockId = data.BlockStd:GetDebugId() or tostring(data.BlockStd)
			local newColor = colors[i]
			if not previousColors[blockId] or colorsAreDifferent(previousColors[blockId], newColor) then
				table.insert(changeIndices, i)
			end
		end

		local shouldThrottle = #changeIndices > 250
		for i = 1, #changeIndices do
			local index = changeIndices[i]
			local data = modellist[index]
			local blockId = data.BlockStd:GetDebugId() or tostring(data.BlockStd)
			local newColor = colors[index]

			previousColors[blockId] = newColor
			task.spawn(function()
				_G.RequestData1[10]:InvokeServer(data.BlockStd, newColor)
			end)

			if shouldThrottle and i % 250 == 0 then
				wait(0)
			end
		end
	end

	if mode == "video" then
		local videoName = configs.video or "test"
		local targetFps = tonumber(configs.fps) or 24
		local useAA = configs.antialiasing
		local suffix = useAA and "_aa.txt" or "_noaa.txt"
		local path = "plane crazy/videos/results/" .. videoName .. suffix

		if typeof(readfile) ~= "function" then print("executor does not support readfile") return end
		local success, result = pcall(function()
			return readfile(path)
		end)
		if not success then
			warn("Could not read video file: " .. path)
			return
		end

		local data = result
		local fpsLine = data:match("FPS:%s*(%d+%.?%d*)")
		if not fpsLine then warn("Missing FPS line") return end
		local fileFps = tonumber(fpsLine)
		local delay = 1 / targetFps

		local allFrames = {}
		for frameBlock in data:gmatch("--- Frame.-\n(.-)\n------") do
			table.insert(allFrames, frameBlock)
		end

		local step = math.max(1, math.floor(fileFps / targetFps))
		local frames = {}
		for i = 1, #allFrames, step do
			table.insert(frames, allFrames[i])
		end

		print("Video loaded with " .. #frames .. " frames at " .. targetFps .. " FPS")

		for _, frame in frames do
			if _G.buildModeHandler_end_old then return end
			local colors = parseColorsFromText(frame)

			-- Precompute changes
			local changeIndices = {}
			for j, data in modellist do
				local blockId = data.BlockStd:GetDebugId() or tostring(data.BlockStd)
				local newColor = colors[j]
				if not previousColors[blockId] or colorsAreDifferent(previousColors[blockId], newColor) then
					table.insert(changeIndices, j)
				end
			end

			local shouldThrottle = false--#changeIndices > 300
			for i = 1, #changeIndices do
				local j = changeIndices[i]
				local data = modellist[j]
				local blockId = data.BlockStd:GetDebugId() or tostring(data.BlockStd)
				local newColor = colors[j]

				previousColors[blockId] = newColor
				task.spawn(function()
					_G.RequestData1[10]:InvokeServer(data.BlockStd, newColor)
				end)

				if shouldThrottle and i % 350 == 0 then
					wait(0)
				end
			end

			if targetFps ~= 0 then wait(delay) end
		end
	end
end
------------------------------------------------------------------------








local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:FindFirstChild("ColorGridGui")
if not screenGui then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ColorGridGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
end

-- Detect most common color in frame
local function getDominantColor(rgbString)
    local colorCount = {}
    local maxCount = 0
    local dominantColor = nil

    -- Brightness calculator using luminance formula
    local function brightness(r, g, b)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    end

    for r, g, b in rgbString:gmatch("(%d+),(%d+),(%d+)") do
        r, g, b = tonumber(r), tonumber(g), tonumber(b)

        -- Convert 16-bit to 8-bit if needed
        if r > 255 or g > 255 or b > 255 then
            r = math.floor(r / 257)
            g = math.floor(g / 257)
            b = math.floor(b / 257)
        end

        local key = r .. "," .. g .. "," .. b
        colorCount[key] = (colorCount[key] or 0) + 1

        local currentCount = colorCount[key]
        local currentBrightness = brightness(r, g, b)

        if currentCount > maxCount then
            maxCount = currentCount
            dominantColor = Color3.fromRGB(r, g, b)
        elseif currentCount == maxCount then
            local existingR, existingG, existingB = dominantColor.R * 255, dominantColor.G * 255, dominantColor.B * 255
            local existingBrightness = brightness(existingR, existingG, existingB)

            -- Prefer the darker color in case of tie
            if currentBrightness < existingBrightness then
                dominantColor = Color3.fromRGB(r, g, b)
            end
        end
    end

    return dominantColor
end

local function DisplayColorGrid(data, pixelSize, keepRatio, shouldLoop, playOnHover)
    pixelSize = pixelSize or 10
    keepRatio = keepRatio ~= false
    shouldLoop = shouldLoop or false
    playOnHover = playOnHover or false

    local width, height = 51, 51
    local containerSize = UDim2.new(0, width * pixelSize, 0, height * pixelSize)

    local container = Instance.new("TextButton")
    container.ZIndex = 2
    container.Size = containerSize
    container.BackgroundTransparency = 1
    container.BackgroundColor3 = Color3.new(0,0,0)
    container.TextColor3 = Color3.new(1,1,1)
    container.Font = Enum.Font.GothamBlack
    container.TextScaled = true
    container.ClipsDescendants = true
    container.Name = "VideoFrame"
    container.Parent = screenGui
	container.Text = ""

    -- Parse frames
    local frames, current = {}, {}
    local c = 0
    for line in data:gmatch("[^\r\n]+") do
        c = c+1
        --if (math.floor(c/220)) == 0 then wait() end
        if line:match("^%-%-%- Frame") then
            if #current > 0 then
                table.insert(frames, table.concat(current, ","))
                current = {}
            end
        elseif line:match("^%d+,%d+,%d+") then
            table.insert(current, line)
        end
    end
    if #current > 0 then table.insert(frames, table.concat(current, ",")) end
    if #frames == 0 then table.insert(frames, data) end
    -- Create grid
    local pixelGrid = {}
    for y = 1, height do
        for x = 1, width do
            local pixel = Instance.new("Frame")
            pixel.Size = UDim2.new((1/51), 0, (1/51), 0)
            pixel.Position = UDim2.new((x - 1) / 51, 0, (y - 1) / 51, 0)
            pixel.BorderSizePixel = 0
            pixel.BackgroundTransparency = 1 -- invisible initially
            pixel.Parent = container
            pixelGrid[(y - 1) * width + x] = pixel
        end
    end
    -- Create background pixel once
    local background = Instance.new("Frame")
    background.Size = container.Size
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BorderSizePixel = 0
    background.ZIndex = -1
    background.BackgroundTransparency = 1
    background.Parent = container
    -- Update one frame
    local function updatePixels(rgbString)
        local values = {}
        for num in rgbString:gmatch("%d+") do
            table.insert(values, tonumber(num))
        end

        if #values ~= width * height * 3 then
            warn("Invalid RGB frame data length:", #values)
            return
        end

        local index = 1
        local counts = {}
        local bgColor = getDominantColor(rgbString)

        -- Set background color
        if bgColor then
            background.BackgroundColor3 = bgColor
            background.BackgroundTransparency = 0
        else
            background.BackgroundTransparency = 1
        end

        for i, pixel in ipairs(pixelGrid) do
            local r, g, b = values[index], values[index + 1], values[index + 2]
            index += 3

            -- Convert 16-bit to 8-bit
            if r > 255 or g > 255 or b > 255 then
                r = math.floor(r / 257)
                g = math.floor(g / 257)
                b = math.floor(b / 257)
            end

            local color = Color3.fromRGB(r, g, b)

            if bgColor and color:ToHex() == bgColor:ToHex() then
                pixel.BackgroundTransparency = 1 -- hide
            elseif pixel.BackgroundColor3 ~= color then
                pixel.BackgroundColor3 = color
                pixel.BackgroundTransparency = 0
            end
        end
    end

    if #frames > 1 then
        if playOnHover then
            updatePixels(frames[1])
        end
        wait(0)
        task.spawn(function()
            local delayPerFrame = 1 / 30
            local isHovered = not playOnHover

            if playOnHover then
                container.MouseEnter:Connect(function() isHovered = true end)
                container.MouseLeave:Connect(function() isHovered = false end)
            end
            if shouldLoop then
                if #frames <= 500 then
                    local runService = game:GetService("RunService")

                    local startTime = os.clock()
                    local totalFrames = #frames
                    local videoDuration = totalFrames * delayPerFrame

                    repeat
                        runService.RenderStepped:Wait()

                        if playOnHover and not isHovered then
                            -- Pause until hovered again
                            repeat task.wait() until not (playOnHover and not isHovered)
                            startTime = os.clock() -- Reset timer when resuming
                        end

                        local elapsedTime = os.clock() - startTime
                        local currentFrameIndex = math.floor(elapsedTime / delayPerFrame) + 1

                        if currentFrameIndex > totalFrames then
                            if shouldLoop then
                                startTime = os.clock()
                                currentFrameIndex = 1
                            else
                                break
                            end
                        end

                        local frame = frames[currentFrameIndex]
                        if frame and isHovered then
                            updatePixels(frame)
                        end
                    until not shouldLoop
                else
                    task.spawn(function()
                        while true do
                            wait(0)
                            if isHovered then
                                container.Text = "frame count is "..tostring(#frames).." which is more then 500 so we disabled it for performance"
                                container.BackgroundTransparency = 0
                                container.ZIndex = 99
                            else
                                container.Text = ""
                                container.BackgroundTransparency = 1
                                container.ZIndex = 2
                            end
                        end
                    end)
                end
            end
        end)
    else
        updatePixels(frames[1])
    end

    return container,#frames >= 500
end



local TweenService = game:GetService("TweenService")
local TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)

local function applyHoverTween(button, scale)
    local defaultSize = button.Size
    local hoverSize = UDim2.new(
        defaultSize.X.Scale * scale, defaultSize.X.Offset * scale,
        defaultSize.Y.Scale * scale, defaultSize.Y.Offset * scale
    )

    button:GetPropertyChangedSignal("GuiState"):Connect(function()
        local state = button.GuiState
        if state == Enum.GuiState.Hover then
            TweenService:Create(button, TWEEN_INFO, {Size = hoverSize}):Play()
        elseif state == Enum.GuiState.Idle then
            TweenService:Create(button, TWEEN_INFO, {Size = defaultSize}):Play()
        end
    end)
end
local function divideUDim2(udim, divisor)
	return UDim2.new(
		udim.X.Scale / divisor,
		udim.X.Offset / divisor,
		0,--udim.Y.Scale / divisor,
		0--udim.Y.Offset / divisor
	)
end




-- GUI setup
gui = game:GetService("CoreGui"):FindFirstChild("MyScrollGui")
if gui then gui:Destroy() end
local gui = Instance.new("ScreenGui", playerGui)
gui.Name = "MyScrollGui"

sf = Instance.new("ScrollingFrame", gui)
---sf.Size = UDim2.new(0.2, 0, 1, 0)
sf.Size = UDim2.new(0.5, 0, 0.2, 0)
sf.Position = UDim2.new(0, 0, 0, 0)
sf.BackgroundTransparency = 0
sf.BackgroundColor3 = Color3.new(0, 0, 0)
sf.BorderSizePixel = 0
sf.ScrollBarThickness = 0
sf.ZIndex = 100
sfl = Instance.new("TextLabel", gui)
sfl.BackgroundTransparency = 1
sfl.Size = UDim2.new(0.5, 0, 0.2, 0)
sfl.Position = UDim2.new(0, 0, 0, 0)
sfl.ZIndex = 200
sfl.TextScaled = true
sfl.Font = Enum.Font.GothamBlack
sfl.TextColor3 = Color3.new(1,1,1)
sfl.Text = "loading..\n\nyou may experience a lot of lag rn"
sfl.RichText = true
l = Instance.new("TextLabel", gui)
l.BackgroundTransparency = 0
l.Size = UDim2.new(0.4, 0, 0.07, 0)
l.Position = UDim2.new(0.5-(0.4/2), 0, -0.07, 0)
l.ZIndex = 199
l.TextScaled = true
l.Font = Enum.Font.GothamBlack
l.TextColor3 = Color3.new(1,1,1)
l.BackgroundColor3 = Color3.new(0, 0, 0)
l.BorderSizePixel = 0
l.Text = "press G to open/close image and video loader"

gui.DisplayOrder = 99999
gui.Parent = game:GetService("CoreGui")
sf.Size = UDim2.new(1, 0, 1, 0)
sfl.Size = UDim2.new(1, 0, 1, 0)


local parentSize = sf.Parent.AbsoluteSize

local widthInPixels = sf.Size.X.Scale * parentSize.X + sf.Size.X.Offset
local heightInPixels = sf.Size.Y.Scale * parentSize.Y + sf.Size.Y.Offset

local size = 1.5
local xamount = 11


local sfpix = UDim2.new(0, widthInPixels/1.625, 0, heightInPixels)
local imagepix = UDim2.new(0, xamount * (55 * size), 0, 1) + UDim2.new(0, (25.5 * size), 0, (25.5 * size))
local offsetpix = divideUDim2(sfpix-imagepix, 0.5)
-- Load videos/images
local files = {}
table.insert(files, "images")
for _, file in ipairs(listfiles("plane crazy/images/results")) do
    table.insert(files, file)
end
table.insert(files, "videos [beta]")
for _, file in ipairs(listfiles("plane crazy/videos/results")) do
    --if not file:find("badapple") then
        table.insert(files, file)
    --end
end

local currentX = 0
local currentY = 0

for i, file in ipairs(files) do
    local dots = "..."
    task.spawn(function()
        while true do
        wait(0.1)
        dots = "."
        wait(0.1)
        dots = ".."
        wait(0.1)
        dots = ".."
        end
    end)
    task.spawn(function()
        while true do
        wait(0)
        sfl.Text = "loading"..dots.."\n["..tostring(i-1).."/"..tostring(#files)..']\n\n\n\n<font color="#757575">you may experience a lot of lag at this moment</font>'
        end
    end)
	wait(0)
	if file ~= "" then
		if not isfile(file) then
			-- Insert label row
			if currentX > 0 then
				currentX = 0
				currentY += 55 * size
			end
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 0, 20 * size)--UDim2.new(0, 55 * size * xamount, 0, 20 * size)
			label.Position = UDim2.new(0, 0, 0, currentY)
			label.BackgroundColor3 = Color3.new(0, 0, 0)
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextScaled = true
			label.Text = tostring(file)
			label.Font = Enum.Font.GothamBlack
			label.TextXAlignment = Enum.TextXAlignment.Center
			label.TextYAlignment = Enum.TextYAlignment.Center
			label.BorderSizePixel = 0
			label.Parent = sf

			currentX = 0
			currentY += 24 * size
		else
			local success, err = pcall(function()
				local frame,toomanyframes = DisplayColorGrid(readfile(file), size, true, true, true)
				frame.Position = UDim2.new(0, currentX * (55 * size), 0, currentY) + UDim2.new(0, (25.5 * size), 0, (25.5 * size)) + offsetpix
				frame.Parent = sf
				frame.AnchorPoint = Vector2.new(0.5, 0.5)
				frame.Activated:Connect(function()
				local t
				if string.find(file, "plane crazy\\videos\\results\\", 1, true) then
					t = "video"
				else
					t = "image"
				end
					local e = file:match("results\\(.+)_([^_\\]+)%.txt$")
					local f = file:match("_([^_]+)%.txt$")
					local g = f == "aa"
					print(file,e,t,f,g)
					buildModeHandler(t,{video = e, image = e, fps = 30, antialiasing = g, lagload = false})
				end)
				applyHoverTween(frame, 0.8)
				local fileType = tostring(file):match("([^_%s]+)%.txt$") or tostring(file)

				local label = Instance.new("TextLabel")
				label.Parent = frame
				label.Font = Enum.Font.GothamBlack
				if fileType ~= tostring(file) then
					label.Size = UDim2.new(0.5, 0, 0.15, 0)
				else
					warn(tostring(file))
					label.Size = UDim2.new(1, 0, 0.3, 0)
				end
				label.TextScaled = fileType ~= tostring(file)
				label.Text = fileType
				label.TextColor3 = Color3.new(1, 1, 1)
				label.BackgroundColor3 = Color3.new(0,0,0)
				label.BorderSizePixel = 0
				label.ZIndex = 50
				local e = Instance.new("Frame")
				e.Parent = frame
				e.BackgroundColor3 = Color3.new(0,0,0)
				e.BorderSizePixel = 0
				e.Size = UDim2.new(label.Size.X.Scale/2, 0, label.Size.Y.Scale, 0)
				e.ZIndex = 49
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0.5,0) -- 20 pixels rounded corners
				corner.Parent = label
			end)

			currentX += 1
			if currentX >= xamount then
				currentX = 0
				currentY += 55 * size
			end
		end
	end
end
sfl:Destroy()
sf.ZIndex = 1
sf.BackgroundTransparency = 0.3

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.G then
        sf.Visible = not sf.Visible
    end
end)
