--_G.drive_moveblock(model,pos,rot)
--_G.listblocks()
--------------------------------------
repeat task.wait() until _G.RequestData1 ~= nil
repeat task.wait() until _G.RequestData2 ~= nil
repeat task.wait() until _G.RequestData3 ~= nil
--repeat task.wait() until _G.RequestData4 ~= nil end --4 support not there
local LocalPlayer = game.Players.LocalPlayer
local Zone = 
--------------------------------------
local function notify(text)
    print("[PCEOS LIB] "..text)
    game.StarterGui:SetCore("SendNotification", {
        Title = "PCEOS LIB";
        Text = text;
        Duration = 5;
    })
end
local function indrivemode()
    return workspace:FindFirstChild(LocalPlayer.Name.." Aircraft") ~= nil
end
--------------------------------------                                                                                                                                                                                                                                                                 1
function _G.moveblock(model,pos,rot)
    if workspace:FindFirstChild(LocalPlayer.Name.." Aircraft") then
        if not model.PrimaryPart:FindFirstChild("vm_1g2G_") then
            local attachment = Instance.new("Attachment")
            attachment.Parent = model.PrimaryPart

            local alignPosition = Instance.new("AlignPosition")
            alignPosition.Attachment0 = attachment
            alignPosition.RigidityEnabled = true
            alignPosition.Responsiveness = 1000
            alignPosition.MaxForce = math.huge
            alignPosition.Parent = model.PrimaryPart
            alignPosition.Name = "vm_1g2G_"
            alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment

            alignRotation = Instance.new("AlignOrientation", part)
            alignRotation.Attachment0 = attachment
            alignRotation.Responsiveness = 1000
            alignRotation.MaxTorque = math.huge
            alignRotation.RigidityEnabled = true
            alignRotation.Name = "vm_1g2G_2"
            alignRotation.Mode = Enum.OrientationAlignmentMode.OneAttachment
        end
        local alignPosition = model.PrimaryPart:FindFirstChild("vm_1g2G_")
        alignPosition.Position = pos
        local alignRotation = model.PrimaryPart:FindFirstChild("vm_1g2G_2")
        alignRotation.CFrame = CFrame.Angles(rot.X,rot.Y,rot,Z)
    else
        notify("Error 1 [check gitbook for more info]")
    end
end
--------------------------------------                                                                                                                                                                                                                                                                 2
function _G.listblocks()
    if indrivemode() then
        return workspace:FindFirstChild(LocalPlayer.Name.." Aircraft"):GetChildren()
    else
        return workspace.Alrcraft:FindFirstChild(LocalPlayer.Name):GetChildren()
    end
end
