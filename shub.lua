local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInput = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer

local cloneref = (cloneref or clonereference or function(instance)
    return instance
end)

local WindUI

do
    local ok, result = pcall(function()
        return require("./src/Init")
    end)

    if ok then
        WindUI = result
    else
        if cloneref(game:GetService("RunService")):IsStudio() then
            WindUI = require(cloneref(ReplicatedStorage:WaitForChild("WindUI"):WaitForChild("Init")))
        else
            WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
        end
    end
end

-- ============ VARIABLES ============
local FarmEnabled = false
local ChestEnabled = false
local SelectedWeapon = nil
local ForceEquip = false
local HakiQuestEnabled = false
local CollectedRings = {}
local CurrentTarget = nil
local AntiAFKEnabled = true
local KillActive = false
local CurrentKillTarget = nil
local FarmMode = "Easy"
local AutoBringCompass = false
local AutoBringOldBook = false
local FlyEnabled = false
local FlySpeed = 200
local FlyConnection = nil
local NoclipEnabled = false
local NoclipConnection = nil
local ESPEnabled = false
local ESPFolder = nil
local ESPConnection = nil
local AutoHakiEnabled = false
local menuVisible = true

local AutoSkillEnabled = false
local SelectedSkills = {}
local AvailableSkills = {"Z", "X", "C", "V", "B", "N", "F", "L", "H", "J", "K", "G"}

local AutoBringNormalFruit = false
local AutoBringDemonFruit = false

local NormalFruitNames = {
    ["apple"]=true, ["banana"]=true, ["greenapple"]=true,
    ["melon"]=true, ["pumpkin"]=true,
    ["cantaloupe"]=true, ["coconut"]=true, ["prickly pear"]=true
}

local RAYLEIGH_POSITION = Vector3.new(-1009.7536010742188, 4011.46484375, 10135.1171875)

-- ============ MOB DEFINITIONS ============
local hardcoreMobs = {
    ["Lv2000 Crocodile"] = true, ["Lv20000 Whitebeard"] = true,
    ["Lv2000 Vokun"] = true, ["Lv40 Cave Demon [Weakened]"] = true,
    ["Lv8000 Gunner Captain"] = true, ["Bandits Leader"] = true,
    ["Bart Nospris"] = true, ["Demon Hunter"] = true,
    ["Fallen Captain"] = true, ["Rayleigh"] = true,
}

local easyMobs = {
    ["Lv1Crab"] = true, ["Lvl1 Boar"] = true, ["Lvl11 Boar"] = true, ["Lvl12 Boar"] = true,
    ["Lvl12 Thug"] = true, ["Lvl14 Bandit"] = true, ["Lvl14 Boar"] = true, ["Lvl15 Bandit"] = true,
    ["Lvl15 Boar"] = true, ["Lvl15 Thug"] = true, ["Lvl16 Boar"] = true, ["Lvl17 Thug"] = true,
    ["Lvl186 Cave Demon"] = true, ["Lvl188 Cave Demon"] = true, ["Lv198 Cave Demon"] = true,
    ["Lv20 Thief"] = true, ["Lv22 Thug"] = true, ["Lv23 Thug"] = true,
    ["Lv24 Thug"] = true, ["Lv24 Fred"] = true,
    ["Lv28 Fredde"] = true, ["Lv28 Freyd"] = true,
    ["Lv28 Friedrich"] = true, ["Lv29 Frued"] = true, ["Lv3 Crab"] = true,
    ["Lv30 Thug"] = true, ["Lv32 Fredric"] = true, ["Lv32 Thief"] = true,
    ["Lv34 Freddi"] = true, ["Lv360 Bruno"] = true,
    ["Lv4 Angry Freddy"] = true, ["Lv4 Boar"] = true, ["Lv4 Crab"] = true, ["Lv40 Thug"] = true,
    ["Lv440 Buster"] = true, ["Lv5 Crab"] = true, ["Lv500 Bucky"] = true, ["Lv9 Bandit Traitor"] = true,
}

local mediumMobs = {
    ["Lv219 Cave Demon"] = true, ["Lv2000 Vokun"] = true, ["Lv300 King Crab"] = true,
}

local FruitNames = {
    "Barrier Fruit", "Swim Fruit", "Spring Fruit", "String Fruit",
    "Spin Fruit", "Smelt Fruit", "Snow Fruit", "Slip Fruit",
    "Slow Fruit", "Quake Fruit", "Sand Fruit", "Rumble Fruit",
    "Plasma Fruit", "Phoenix Fruit", "Paw Fruit", "Order Fruit",
    "Magma Fruit", "Ope Fruit", "Luck Fruit", "Love Fruit",
    "Light Fruit", "Hot Fruit", "Gum Fruit", "Gravity Fruit",
    "Gas Fruit", "Float Fruit", "Flare Fruit", "Diamond Fruit",
    "Dark Fruit", "Clone Fruit", "Clear Fruit", "Chop Fruit",
    "Chilly Fruit", "Candy Fruit", "Bomb Fruit", "Buddha Fruit"
}

-- ============ HELPER FUNCTIONS ============
local function getCharacter()
    return Player.Character or Player.CharacterAdded:Wait()
end

local function getLevelFromName(name)
    if type(name) ~= "string" then return 0 end
    local level = name:match("Lv(%d+)")
    if level then return tonumber(level) or 0 end
    level = name:match("Lvl(%d+)")
    if level then return tonumber(level) or 0 end
    return 0
end

local function isGunslinger(name)
    if type(name) ~= "string" then return false end
    return string.find(name, "Gunslinger") and true or false
end

local function IsValidMobForMode(mobName)
    if type(mobName) ~= "string" then return false end
    if isGunslinger(mobName) then return false end
    if FarmMode == "Easy" then return easyMobs[mobName] == true end
    if FarmMode == "Medium" then
        if hardcoreMobs[mobName] then return false end
        local level = getLevelFromName(mobName)
        return level > 200 or mediumMobs[mobName] == true
    end
    if FarmMode == "Hardcore" then return hardcoreMobs[mobName] == true end
    return false
end

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local DamageEvent = Remotes and Remotes:FindFirstChild("DamageEvent")
local SkillsReceiverEvent = Remotes and Remotes:FindFirstChild("SkillsReceiverEvent")
local KeyBindEvent = Remotes and Remotes:FindFirstChild("KeyBindEvent")

local function getTableKick()
    local char = getCharacter()
    if not char then return nil end
    local tool = char:FindFirstChild("Table Kick")
    if tool then return tool end
    local backpack = Player:FindFirstChild("Backpack")
    if backpack then
        tool = backpack:FindFirstChild("Table Kick")
        if tool then return tool end
    end
    return nil
end

local function getToolByName(toolName)
    if not toolName then return nil end
    local backpack = Player:FindFirstChild("Backpack")
    if backpack then
        local tool = backpack:FindFirstChild(toolName)
        if tool and tool:IsA("Tool") then return tool end
    end
    local char = getCharacter()
    return char and char:FindFirstChild(toolName)
end

local function equipWeapon(toolName)
    if not toolName or not ForceEquip then return false end
    local tool = getToolByName(toolName)
    if not tool then return false end
    local char = getCharacter()
    if not char then return false end
    if tool.Parent ~= char then
        pcall(function() tool.Parent = char end)
        task.wait(0.1)
    end
    return tool.Parent == char
end

-- ============ AUTO EQUIP ============
task.spawn(function()
    while task.wait(0.5) do
        if ForceEquip and SelectedWeapon then
            local char = getCharacter()
            if char then
                local currentTool = char:FindFirstChildWhichIsA("Tool")
                if not currentTool or currentTool.Name ~= SelectedWeapon then
                    equipWeapon(SelectedWeapon)
                end
            end
        end
    end
end)

-- ============ AUTO SKILL ============
task.spawn(function()
    local function pressKey(key)
        local keyCode = Enum.KeyCode[key]
        if not keyCode then return end
        pcall(function()
            VirtualInput:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.05)
            VirtualInput:SendKeyEvent(false, keyCode, false, game)
        end)
    end
    
    local skillIndex = 1
    local skillKeys = {}
    
    while true do
        task.wait(0.15)
        if not AutoSkillEnabled then 
            skillIndex = 1
            continue 
        end
        
        skillKeys = {}
        for skill, selected in pairs(SelectedSkills) do
            if selected then
                table.insert(skillKeys, skill)
            end
        end
        
        if #skillKeys == 0 then continue end
        
        if skillIndex > #skillKeys then
            skillIndex = 1
        end
        
        pressKey(skillKeys[skillIndex])
        skillIndex = skillIndex + 1
    end
end)

-- ============ AUTO HAKI ============
task.spawn(function()
    while true do
        task.wait(2)
        if not AutoHakiEnabled then continue end
        local char = getCharacter()
        if char then
            local observation = char:GetAttribute("Observation")
            if not observation then
                pcall(function()
                    VirtualInput:SendKeyEvent(true, Enum.KeyCode.R, false, game)
                    task.wait(0.1)
                    VirtualInput:SendKeyEvent(false, Enum.KeyCode.R, false, game)
                end)
            end
        end
    end
end)

-- ============ AUTO BRING FUNCTIONS ============
task.spawn(function()
    while true do
        task.wait(0.7)
        if not AutoBringNormalFruit then continue end
        local char = getCharacter()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        for _, v in pairs(workspace:GetDescendants()) do
            if not v then continue end
            local name = v.Name
            if type(name) ~= "string" then continue end
            if NormalFruitNames[string.lower(name)] then
                local part = v:FindFirstChildWhichIsA("BasePart")
                if not part and v:IsA("BasePart") then
                    part = v
                end
                if part then
                    pcall(function()
                        part.CFrame = hrp.CFrame * CFrame.new(0, -2.5, 0)
                    end)
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.7)
        if not AutoBringDemonFruit then continue end
        local char = getCharacter()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        for _, obj in pairs(Workspace:GetChildren()) do
            if not obj or not obj:IsA("Tool") then continue end
            local name = obj.Name
            if type(name) ~= "string" then continue end
            for _, fn in ipairs(FruitNames) do
                if name == fn then
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if not part and obj:IsA("BasePart") then
                        part = obj
                    end
                    if part then
                        pcall(function()
                            part.CFrame = hrp.CFrame * CFrame.new(0, -2.5, 0)
                        end)
                    end
                    break
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.7)
        if not AutoBringOldBook then continue end
        local char = getCharacter()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        for _, obj in pairs(Workspace:GetDescendants()) do
            if not obj then continue end
            local name = obj.Name
            if type(name) ~= "string" then continue end
            local lowerName = string.lower(name)
            if lowerName == "oldbook" or lowerName == "old book" or string.find(lowerName, "oldbook") then
                local part = obj:FindFirstChildWhichIsA("BasePart")
                if not part and obj:IsA("BasePart") then
                    part = obj
                end
                if part then
                    pcall(function()
                        part.CFrame = hrp.CFrame * CFrame.new(0, -2.5, 0)
                    end)
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.7)
        if not AutoBringCompass then continue end
        local char = getCharacter()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        for _, obj in pairs(Workspace:GetDescendants()) do
            if not obj then continue end
            local name = obj.Name
            if type(name) ~= "string" then continue end
            local lowerName = string.lower(name)
            if lowerName == "compass" or string.find(lowerName, "compass") then
                local part = obj:FindFirstChildWhichIsA("BasePart")
                if not part and obj:IsA("BasePart") then
                    part = obj
                end
                if part then
                    pcall(function()
                        part.CFrame = hrp.CFrame * CFrame.new(0, -2.5, 0)
                    end)
                end
            end
        end
    end
end)

-- ============ FARM FUNCTIONS ============
local function findMob()
    local aliveFolder = workspace:FindFirstChild("Alive")
    if not aliveFolder then return nil, nil, nil end
    local bestMob, bestHum, bestRoot = nil, nil, nil
    local lowestLevel = math.huge
    local bestDistance = math.huge
    local myChar = getCharacter()
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil, nil, nil end
    for _, npc in ipairs(aliveFolder:GetChildren()) do
        if not npc or not npc:IsA("Model") then continue end
        if Players:GetPlayerFromCharacter(npc) then continue end
        if not IsValidMobForMode(npc.Name) then continue end
        local level = getLevelFromName(npc.Name)
        local hum = npc:FindFirstChildOfClass("Humanoid")
        local root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head")
        if hum and root and hum.Health > 0 then
            local dist = (myRoot.Position - root.Position).Magnitude
            if level < lowestLevel or (level == lowestLevel and dist < bestDistance) then
                lowestLevel = level
                bestDistance = dist
                bestMob, bestHum, bestRoot = npc, hum, root
            end
        end
    end
    return bestMob, bestHum, bestRoot
end

local function freezeNPC(npc)
    if not npc then return end
    local root = npc:FindFirstChild("HumanoidRootPart")
    local hum = npc:FindFirstChildOfClass("Humanoid")
    if root then pcall(function() root.AssemblyLinearVelocity = Vector3.zero end) end
    if hum then
        pcall(function()
            hum.AutoRotate = false
            hum.PlatformStand = true
            hum.WalkSpeed = 0
            hum.JumpPower = 0
        end)
    end
end

local function unfreezeNPC(npc)
    if not npc then return end
    local hum = npc:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum.AutoRotate = true
            hum.PlatformStand = false
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end)
    end
end

local attackCooldown = 0
local function attack()
    local now = tick()
    if now - attackCooldown < 0.05 then return end
    attackCooldown = now
    
    pcall(function()
        if DamageEvent then
            local tool = getTableKick()
            DamageEvent:FireServer("Click", tool, CFrame.new())
            DamageEvent:FireServer()
            DamageEvent:FireServer("Melee")
            DamageEvent:FireServer("Hit", tool)
        end
    end)
    
    pcall(function()
        if SkillsReceiverEvent then
            SkillsReceiverEvent:FireServer("F", "Table Kick")
        end
    end)
    
    pcall(function()
        VirtualInput:SendMouseButtonEvent(0, 0, 0, true, Enum.UserInputType.MouseButton1, 1)
        task.wait(0.01)
        VirtualInput:SendMouseButtonEvent(0, 0, 0, false, Enum.UserInputType.MouseButton1, 1)
    end)
    
    pcall(function()
        VirtualUser:Button1Down(Vector2.new(500, 300), workspace.CurrentCamera.CFrame)
        task.wait(0.01)
        VirtualUser:Button1Up(Vector2.new(500, 300), workspace.CurrentCamera.CFrame)
    end)
    
    local char = getCharacter()
    if char then
        local tool = char:FindFirstChildWhichIsA("Tool")
        if tool then
            pcall(function() tool:Activate() end)
        end
    end
    
    pcall(function()
        if KeyBindEvent then
            KeyBindEvent:FireServer("F", true)
        end
    end)
end

-- ============ FARM LOOP ============
task.spawn(function()
    while task.wait(0.05) do
        if not FarmEnabled then
            if CurrentTarget then
                unfreezeNPC(CurrentTarget)
                CurrentTarget = nil
            end
            continue
        end
        local mob, hum, root = findMob()
        if mob and hum and root then
            if CurrentTarget ~= mob then
                if CurrentTarget then unfreezeNPC(CurrentTarget) end
                CurrentTarget = mob
            end
            freezeNPC(CurrentTarget)
            local char = getCharacter()
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            if myRoot and root then
                pcall(function()
                    myRoot.CFrame = root.CFrame * CFrame.new(0, 0, 2.5)
                end)
            end
            attack()
            if hum.Health <= 0 then
                unfreezeNPC(CurrentTarget)
                CurrentTarget = nil
            end
        end
    end
end)

-- ============ AUTO CHEST ============
task.spawn(function()
    while task.wait(0.2) do
        if not ChestEnabled then continue end
        for _, v in ipairs(workspace:GetDescendants()) do
            if not ChestEnabled then break end
            if v and v.Name == "TreasureChest" and v:IsA("Model") then
                local pos = v:FindFirstChild("Pos1", true) or v:FindFirstChild("PrimaryPart")
                if pos then
                    local char = getCharacter()
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        pcall(function()
                            hrp.CFrame = pos.CFrame + Vector3.new(0, 3, 0)
                        end)
                    end
                    task.wait(0.5)
                end
            end
        end
    end
end)

-- ============ HAKI QUEST ============
local function getAllRings()
    local rings = {}
    local mapFolder = workspace:FindFirstChild("MapFolder")
    if not mapFolder then return rings end
    local ringsFolder = mapFolder:FindFirstChild("Rings")
    if not ringsFolder then return rings end
    for i = 1, 8 do
        local ringName = "Rayleigh Ring " .. i
        for _, v in pairs(ringsFolder:GetChildren()) do
            if v and v.Name == ringName then
                local primary = v:FindFirstChild("PrimaryPart") or v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("Part")
                if primary then
                    table.insert(rings, {Name = ringName, Order = i, CFrame = primary.CFrame, Object = v, Primary = primary})
                else
                    table.insert(rings, {Name = ringName, Order = i, CFrame = v.CFrame, Object = v, Primary = v})
                end
                break
            end
        end
    end
    table.sort(rings, function(a, b) return a.Order < b.Order end)
    return rings
end

local function teleportToRayleigh()
    local char = getCharacter()
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then pcall(function() hrp.CFrame = CFrame.new(RAYLEIGH_POSITION) + Vector3.new(0, 3, 0) end) end
end

local currentRingIndex = 1
local RingTweenActive = false

task.spawn(function()
    while true do
        task.wait(0.5)
        if not HakiQuestEnabled then 
            currentRingIndex = 1
            continue 
        end
        
        local rings = getAllRings()
        if #rings == 0 then
            task.wait(1)
            continue
        end
        
        local allCollected = true
        for _, ring in ipairs(rings) do
            if not CollectedRings[ring.Name] then
                allCollected = false
                break
            end
        end
        
        if allCollected then
            teleportToRayleigh()
            HakiQuestEnabled = false
            CollectedRings = {}
            currentRingIndex = 1
            WindUI:Notify({ Title = "Haki Quest", Content = "Completed!", Duration = 3 })
            continue
        end
        
        if currentRingIndex > #rings then
            currentRingIndex = 1
        end
        
        local ring = rings[currentRingIndex]
        if not ring then
            currentRingIndex = currentRingIndex + 1
            continue
        end
        
        if CollectedRings[ring.Name] then
            currentRingIndex = currentRingIndex + 1
            continue
        end
        
        if ring.Object and ring.Object.Parent and ring.CFrame and not RingTweenActive then
            local char = getCharacter()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                RingTweenActive = true
                
                local targetPos = ring.CFrame.Position + Vector3.new(0, 2.5, 0)
                local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
                pcall(function() tween:Play() end)
                task.wait(0.4)
                
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    for i = 1, 3 do
                        pcall(function()
                            hum.Jump = true
                            task.wait(0.08)
                            hum.Jump = false
                            task.wait(0.08)
                        end)
                    end
                end
                
                task.wait(0.2)
                CollectedRings[ring.Name] = true
                WindUI:Notify({ Title = "Ring", Content = "Collected " .. ring.Name .. " (" .. currentRingIndex .. "/" .. #rings .. ")", Duration = 2 })
                currentRingIndex = currentRingIndex + 1
                RingTweenActive = false
                task.wait(0.1)
            end
        end
    end
end)

-- ============ ANTI AFK ============
local afkConnection = nil
local function setupAntiAFK()
    if afkConnection then afkConnection:Disconnect() end
    if AntiAFKEnabled then
        afkConnection = Player.Idled:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end
end
setupAntiAFK()

-- ============ FLY ============
local FlyAttachment = nil
local FlyLinearVelocity = nil
local FlyBodyGyro = nil

local function toggleFly()
    FlyEnabled = not FlyEnabled
    if FlyEnabled then
        local char = getCharacter()
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        local animate = char:FindFirstChild("Animate")
        if animate then pcall(function() animate.Disabled = true end) end
        
        pcall(function()
            char.Humanoid.PlatformStand = true
            char.Humanoid.AutoRotate = false
            char.Humanoid.WalkSpeed = 0
            char.Humanoid.JumpPower = 0
        end)
        
        if FlyLinearVelocity then pcall(function() FlyLinearVelocity:Destroy() end) end
        if FlyBodyGyro then pcall(function() FlyBodyGyro:Destroy() end) end
        if FlyAttachment then pcall(function() FlyAttachment:Destroy() end) end
        
        FlyAttachment = Instance.new("Attachment")
        FlyAttachment.Parent = root
        
        FlyLinearVelocity = Instance.new("LinearVelocity")
        FlyLinearVelocity.Parent = root
        FlyLinearVelocity.Attachment0 = FlyAttachment
        FlyLinearVelocity.MaxForce = math.huge
        FlyLinearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        FlyLinearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
        FlyLinearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
        
        FlyBodyGyro = Instance.new("BodyGyro")
        FlyBodyGyro.Parent = root
        FlyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        FlyBodyGyro.D = 5000
        FlyBodyGyro.P = 50000
        FlyBodyGyro.CFrame = CFrame.new(root.Position, root.Position + Vector3.new(0, 1, 0))
        
        if FlyConnection then FlyConnection:Disconnect() end
        FlyConnection = RunService.Heartbeat:Connect(function()
            if not FlyEnabled then return end
            local currentRoot = char:FindFirstChild("HumanoidRootPart")
            if not currentRoot then return end
            
            local moveX = 0
            local moveZ = 0
            local moveY = 0
            local cam = workspace.CurrentCamera
            
            if UserInputService.TouchEnabled then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local dir = hum.MoveDirection
                    if dir.Magnitude > 0.1 then
                        local flatLook = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit
                        local flatRight = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z).Unit
                        moveX = dir:Dot(flatRight)
                        moveZ = dir:Dot(flatLook)
                    end
                    if hum.Jump then moveY = 1 end
                end
            else
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveZ = moveZ + 1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveZ = moveZ - 1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveX = moveX - 1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveX = moveX + 1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveY = moveY + 1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveY = moveY - 1 end
            end
            
            local look = cam.CFrame.LookVector
            local right = cam.CFrame.RightVector
            local up = cam.CFrame.UpVector
            
            local velocity = (right * moveX + look * moveZ + up * moveY) * FlySpeed
            FlyLinearVelocity.VectorVelocity = velocity
            
            FlyBodyGyro.CFrame = CFrame.new(currentRoot.Position, currentRoot.Position + Vector3.new(0, 1, 0))
        end)
    else
        if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
        if FlyLinearVelocity then pcall(function() FlyLinearVelocity:Destroy() end) end
        if FlyBodyGyro then pcall(function() FlyBodyGyro:Destroy() end) end
        if FlyAttachment then pcall(function() FlyAttachment:Destroy() end) end
        
        local char = getCharacter()
        if char then
            local animate = char:FindFirstChild("Animate")
            if animate then pcall(function() animate.Disabled = false end) end
            pcall(function()
                char.Humanoid.PlatformStand = false
                char.Humanoid.AutoRotate = true
                char.Humanoid.WalkSpeed = 16
                char.Humanoid.JumpPower = 50
            end)
        end
    end
end

-- ============ NOCLIP ============
local function toggleNoclip()
    NoclipEnabled = not NoclipEnabled
    if NoclipEnabled then
        if NoclipConnection then NoclipConnection:Disconnect() end
        NoclipConnection = RunService.Stepped:Connect(function()
            if not NoclipEnabled then return end
            local char = getCharacter()
            if not char then return end
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then
                    pcall(function() v.CanCollide = false end)
                end
            end
        end)
    else
        if NoclipConnection then NoclipConnection:Disconnect(); NoclipConnection = nil end
        local char = getCharacter()
        if char then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    pcall(function() v.CanCollide = true end)
                end
            end
        end
    end
end

-- ============ ESP ============
local function toggleESP()
    ESPEnabled = not ESPEnabled
    if ESPEnabled then
        if ESPFolder then pcall(function() ESPFolder:Destroy() end) end
        ESPFolder = Instance.new("Folder")
        ESPFolder.Name = "ESP_Players"
        ESPFolder.Parent = workspace
        if ESPConnection then ESPConnection:Disconnect() end
        ESPConnection = RunService.RenderStepped:Connect(function()
            if not ESPEnabled then return end
            for _, obj in pairs(ESPFolder:GetChildren()) do
                pcall(function() obj:Destroy() end)
            end
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= Player and player.Character then
                    local root = player.Character:FindFirstChild("HumanoidRootPart")
                    local hum = player.Character:FindFirstChildOfClass("Humanoid")
                    if root and hum then
                        pcall(function()
                            local bill = Instance.new("BillboardGui")
                            bill.Name = "ESP_" .. player.Name
                            bill.Parent = ESPFolder
                            bill.Adornee = root
                            bill.Size = UDim2.new(0, 150, 0, 40)
                            bill.StudsOffset = Vector3.new(0, 3, 0)
                            bill.AlwaysOnTop = true
                            local label = Instance.new("TextLabel")
                            label.Parent = bill
                            label.Size = UDim2.new(1, 0, 1, 0)
                            label.BackgroundTransparency = 1
                            label.Text = player.Name .. " ❤️" .. math.floor(hum.Health)
                            label.TextColor3 = Color3.new(1, 0, 0)
                            label.TextScaled = true
                            label.Font = Enum.Font.GothamBold
                            label.TextStrokeTransparency = 0.3
                        end)
                    end
                end
            end
        end)
    else
        if ESPConnection then ESPConnection:Disconnect(); ESPConnection = nil end
        if ESPFolder then pcall(function() ESPFolder:Destroy() end) end
    end
end

-- ============ PLAYER FUNCTIONS ============
local function GetPlayerList()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            table.insert(list, plr.Name)
        end
    end
    return list
end

local Camera = workspace.CurrentCamera
local Spectating = false
local CurrentSpectatePlayer = nil
local OriginalCameraSubject = nil
local OriginalCameraType = nil
local SelectedPlayerName = nil
local KillLoopConnection = nil

local function StartSpectate(playerName)
    local target = Players:FindFirstChild(playerName)
    if not target or not target.Character then
        WindUI:Notify({ Title = "Spectator", Content = "Player not found!", Duration = 2 })
        return false
    end
    local hum = target.Character:FindFirstChildOfClass("Humanoid")
    if not hum then
        WindUI:Notify({ Title = "Spectator", Content = "No humanoid!", Duration = 2 })
        return false
    end
    Spectating = true
    CurrentSpectatePlayer = target
    OriginalCameraSubject = Camera.CameraSubject
    OriginalCameraType = Camera.CameraType
    pcall(function()
        Camera.CameraType = Enum.CameraType.Custom
        Camera.CameraSubject = hum
    end)
    WindUI:Notify({ Title = "Spectator", Content = "Watching " .. target.Name, Duration = 2 })
    return true
end

local function StopSpectate()
    if not Spectating then return end
    Spectating = false
    CurrentSpectatePlayer = nil
    pcall(function()
        if OriginalCameraSubject then
            Camera.CameraType = OriginalCameraType
            Camera.CameraSubject = OriginalCameraSubject
        else
            local char = getCharacter()
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                Camera.CameraType = Enum.CameraType.Custom
                Camera.CameraSubject = hum
            end
        end
    end)
    WindUI:Notify({ Title = "Spectator", Content = "Stopped", Duration = 2 })
end

local function TeleportToPlayer(playerName)
    local target = Players:FindFirstChild(playerName)
    if not target or not target.Character then
        WindUI:Notify({ Title = "Teleport", Content = "Player not found!", Duration = 2 })
        return
    end
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        WindUI:Notify({ Title = "Teleport", Content = "No root part!", Duration = 2 })
        return
    end
    local myChar = getCharacter()
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if myRoot then
        pcall(function()
            myRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 1.5, 1.5)
        end)
        WindUI:Notify({ Title = "Teleport", Content = "Teleported to " .. target.Name, Duration = 2 })
    end
end

local function StartKill(playerName)
    local target = Players:FindFirstChild(playerName)
    if not target then
        WindUI:Notify({ Title = "Kill", Content = "Player not found!", Duration = 2 })
        return false
    end
    if not target.Character then
        WindUI:Notify({ Title = "Kill", Content = "Target has no character!", Duration = 2 })
        return false
    end
    CurrentKillTarget = target
    KillActive = true
    WindUI:Notify({ Title = "Kill", Content = "Targeting " .. target.Name, Duration = 2 })
    
    if KillLoopConnection then KillLoopConnection:Disconnect() end
    KillLoopConnection = RunService.Heartbeat:Connect(function()
        if not KillActive or not CurrentKillTarget then
            if KillLoopConnection then KillLoopConnection:Disconnect(); KillLoopConnection = nil end
            return
        end
        
        local target = CurrentKillTarget
        if not target or not target.Character then
            WindUI:Notify({ Title = "Kill", Content = "Target lost!", Duration = 2 })
            KillActive = false
            if KillLoopConnection then KillLoopConnection:Disconnect(); KillLoopConnection = nil end
            return
        end
        
        local targetHum = target.Character:FindFirstChildOfClass("Humanoid")
        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
        
        if not targetHum or not targetRoot or targetHum.Health <= 0 then
            WindUI:Notify({ Title = "Kill", Content = "Target eliminated!", Duration = 2 })
            KillActive = false
            CurrentKillTarget = nil
            if KillLoopConnection then KillLoopConnection:Disconnect(); KillLoopConnection = nil end
            return
        end
        
        local myChar = getCharacter()
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        
        if myRoot and targetRoot then
            pcall(function()
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 1.5)
            end)
        end
        
        attack()
    end)
    
    return true
end

local function StopKill()
    KillActive = false
    CurrentKillTarget = nil
    if KillLoopConnection then 
        KillLoopConnection:Disconnect()
        KillLoopConnection = nil
    end
    WindUI:Notify({ Title = "Kill", Content = "Stopped", Duration = 2 })
end

-- ============ WINDOW SETUP - WINDUI ============
local Window = WindUI:CreateWindow({
    Title = "SON HUB V3.5",
    Folder = "sonhub",
    Icon = "solar:folder-2-bold-duotone",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Title = "Open SON HUB",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.5,
        Color = ColorSequence.new(
            Color3.fromHex("#FF6B6B"),
            Color3.fromHex("#FFE66D")
        ),
    },
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
})

Window:Tag({
    Title = "v3.5",
    Icon = "github",
    Color = Color3.fromHex("#1c1c1c"),
    Border = true,
})

-- ============ FARM TAB ============
local FarmTab = Window:Tab({
    Title = "Farm",
    Icon = "solar:leaf-bold",
})

local FarmSection = FarmTab:Section({
    Title = "Auto Farm",
})

FarmSection:Button({
    Title = "Refresh Weapons",
    Icon = "",
    Callback = function()
        WindUI:Notify({ Title = "Refreshed", Content = "Weapons list refreshed", Duration = 2 })
    end,
})

FarmSection:Toggle({
    Title = "Auto Farm",
    Desc = "Toggle auto farm on/off",
    Callback = function(v)
        FarmEnabled = v
        if not v and CurrentTarget then
            unfreezeNPC(CurrentTarget)
            CurrentTarget = nil
        end
    end,
})

FarmSection:Toggle({
    Title = "Auto Chest",
    Desc = "Auto open chests",
    Callback = function(v)
        ChestEnabled = v
    end,
})

-- Auto Bring
local BringSection = FarmTab:Section({
    Title = "Auto Bring",
})

BringSection:Toggle({
    Title = "Auto Bring Normal Fruit",
    Callback = function(v)
        AutoBringNormalFruit = v
    end,
})

BringSection:Toggle({
    Title = "Auto Bring Demon Fruit",
    Callback = function(v)
        AutoBringDemonFruit = v
    end,
})

BringSection:Toggle({
    Title = "Auto Bring Compass",
    Callback = function(v)
        AutoBringCompass = v
    end,
})

BringSection:Toggle({
    Title = "Auto Bring Old Book",
    Callback = function(v)
        AutoBringOldBook = v
    end,
})

-- ============ CONFIG FARM TAB ============
local ConfigTab = Window:Tab({
    Title = "Config Farm",
    Icon = "solar:cpu-bold",
})

local SkillSection = ConfigTab:Section({
    Title = "Auto Skill",
})

SkillSection:Toggle({
    Title = "Auto Skill",
    Callback = function(v)
        AutoSkillEnabled = v
    end,
})

for _, skill in ipairs(AvailableSkills) do
    SkillSection:Toggle({
        Title = "Skill " .. skill,
        Callback = function(v)
            SelectedSkills[skill] = v
            local count = 0
            for _, s in pairs(SelectedSkills) do if s then count = count + 1 end end
            WindUI:Notify({ Title = "Skills", Content = "Selected " .. count .. " skills", Duration = 1 })
        end,
    })
end

local HakiSection = ConfigTab:Section({
    Title = "Auto Haki",
})

HakiSection:Toggle({
    Title = "Auto Haki",
    Callback = function(v)
        AutoHakiEnabled = v
    end,
})

-- ============ TELEPORT TAB ============
local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "solar:planet-bold",
})

local TeleportSection = TeleportTab:Section({
    Title = "Teleport",
})

local IslandPositions = {
    ["Sam"] = Vector3.new(-1282.53, 218.00, -1347.59),
    ["Fisher"] = Vector3.new(-1689.73, 216.00, -320.37),
    ["SectorG9"] = Vector3.new(-2681.07, 216.00, -943.29),
    ["MarineFord"] = Vector3.new(-3310.71, 300.75, -3286.47),
    ["Purple Island"] = Vector3.new(-5273.88, 519.50, -7845.15),
    ["Water tower"] = Vector3.new(-233.99, 226.00, -1026.76),
    ["WindMills"] = Vector3.new(65.12, 224.00, -35.69),
    ["OneHouse"] = Vector3.new(720.87, 241.00, 1214.81),
    ["restaurant"] = Vector3.new(1954.35, 218.00, 610.74),
    ["KingCrab"] = Vector3.new(1215.75, 243.00, -268.88),
    ["CaveIsland"] = Vector3.new(2052.59, 491.00, -656.71),
    ["BigTree"] = Vector3.new(2051.62, 288.00, -1871.25),
    ["Krizma Island"] = Vector3.new(-1072.04, 361.00, 1677.36),
    ["Gun Island"] = Vector3.new(-1846.41, 222.00, 3402.44),
    ["Accient Island"] = Vector3.new(-2721.82, 252.69, 1153.06),
    ["C Island"] = Vector3.new(2953.90, 217.00, 1394.13),
    ["Bar Island"] = Vector3.new(1481.25, 263.90, 2117.69),
    ["Anna House"] = Vector3.new(1118.05, 217.20, 3353.08),
    ["Crocodile Land"] = Vector3.new(948.70, 392.59, 5014.60),
    ["Three Tree"] = Vector3.new(-5703.31, 216.00, 123.44),
    ["Hole Land"] = Vector3.new(-10913.88, 551.00, 5063.75),
    ["Many Land"] = Vector3.new(-9258.29, 216.00, -3025.81),
    ["Haki Land"] = Vector3.new(-1002.16, 4010.97, 10158.25),
    ["Vokun Land"] = Vector3.new(4685.26, 217.00, 4817.13),
    ["BigSnow"] = Vector3.new(6275.28, 487.00, -1829.30),
}

for island, pos in pairs(IslandPositions) do
    TeleportSection:Button({
        Title = island,
        Icon = "",
        Callback = function()
            local char = getCharacter()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function()
                    hrp.CFrame = CFrame.new(pos) + Vector3.new(0, 3, 0)
                end)
                WindUI:Notify({ Title = "Teleport", Content = "Teleported to " .. island, Duration = 2 })
            end
        end,
    })
end

TeleportSection:Button({
    Title = "Teleport to Rayleigh",
    Icon = "",
    Callback = function()
        teleportToRayleigh()
        WindUI:Notify({ Title = "Teleport", Content = "Teleported to Rayleigh", Duration = 2 })
    end,
})

-- ============ PLAYER TAB ============
local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "lucide:users",
})

local PlayerSection = PlayerTab:Section({
    Title = "Player Control",
})

-- Player dropdown
local PlayerList = GetPlayerList()
if #PlayerList > 0 then
    local PlayerDropdown = PlayerSection:Dropdown({
        Title = "Select Player",
        Values = PlayerList,
        Value = PlayerList[1],
        Callback = function(v)
            SelectedPlayerName = v
        end,
    })
end

PlayerSection:Button({
    Title = "Refresh Player List",
    Icon = "",
    Callback = function()
        local newList = GetPlayerList()
        WindUI:Notify({ Title = "Refresh", Content = "Player list updated", Duration = 2 })
    end,
})

PlayerSection:Toggle({
    Title = "Spectate Player",
    Callback = function(v)
        if v then
            if SelectedPlayerName then
                StartSpectate(SelectedPlayerName)
            else
                WindUI:Notify({ Title = "Spectate", Content = "Select a player first!", Duration = 2 })
                return false
            end
        else
            StopSpectate()
        end
    end,
})

PlayerSection:Button({
    Title = "Teleport to Player",
    Icon = "",
    Callback = function()
        if SelectedPlayerName then
            TeleportToPlayer(SelectedPlayerName)
        else
            WindUI:Notify({ Title = "Teleport", Content = "Select a player first!", Duration = 2 })
        end
    end,
})

PlayerSection:Toggle({
    Title = "Kill Player",
    Callback = function(v)
        if v then
            if SelectedPlayerName then
                StartKill(SelectedPlayerName)
            else
                WindUI:Notify({ Title = "Kill", Content = "Select a player first!", Duration = 2 })
                return false
            end
        else
            StopKill()
        end
    end,
})

-- Utility
local UtilitySection = PlayerTab:Section({
    Title = "Utility",
})

UtilitySection:Toggle({
    Title = "Fly",
    Callback = function()
        toggleFly()
        WindUI:Notify({ Title = "Fly", Content = tostring(FlyEnabled), Duration = 2 })
    end,
})

UtilitySection:Slider({
    Title = "Fly Speed",
    Step = 1,
    Value = {
        Min = 50,
        Max = 1000,
        Default = 200,
    },
    Callback = function(v)
        FlySpeed = v
    end,
})

UtilitySection:Toggle({
    Title = "Noclip",
    Callback = function()
        toggleNoclip()
        WindUI:Notify({ Title = "Noclip", Content = tostring(NoclipEnabled), Duration = 2 })
    end,
})

UtilitySection:Toggle({
    Title = "ESP (Players)",
    Callback = function()
        toggleESP()
        WindUI:Notify({ Title = "ESP", Content = tostring(ESPEnabled), Duration = 2 })
    end,
})

-- ============ QUEST TAB ============
local QuestTab = Window:Tab({
    Title = "Quest",
    Icon = "solar:crown-bold",
})

local QuestSection = QuestTab:Section({
    Title = "Haki Quest",
})

QuestSection:Toggle({
    Title = "Auto Collect Rings",
    Callback = function(v)
        HakiQuestEnabled = v
        if not v then 
            CollectedRings = {}
            currentRingIndex = 1
            RingTweenActive = false
        end
    end,
})

QuestSection:Button({
    Title = "Teleport to Rayleigh",
    Icon = "",
    Callback = function()
        teleportToRayleigh()
    end,
})

QuestSection:Button({
    Title = "Reset Progress",
    Icon = "",
    Callback = function()
        CollectedRings = {}
        currentRingIndex = 1
        RingTweenActive = false
        WindUI:Notify({ Title = "Reset", Content = "Progress reset", Duration = 2 })
    end,
})

-- Fishing
local FishingSection = QuestTab:Section({
    Title = "Auto Fishing",
})

local AutoFishingEnabled = false
local AutoMinigameEnabled = false
local FishingState = "IDLE"
local CurrentBobber = nil
local MinigameActive = false
local FishingEvent = nil

local function GetCurrentRod()
    local char = getCharacter()
    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:find("Rod") or tool.Name:find("Fishing") or tool.Name:find("Super Rod") or tool.Name:find("Sturdy Rod") or tool.Name:find("Wood Rod")) then
                return tool
            end
        end
    end
    local backpack = Player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:find("Rod") or tool.Name:find("Fishing") or tool.Name:find("Super Rod") or tool.Name:find("Sturdy Rod") or tool.Name:find("Wood Rod")) then
                return tool
            end
        end
    end
    return nil
end

local function EquipRod()
    local rod = GetCurrentRod()
    if rod and rod.Parent == Player.Backpack then
        pcall(function() Player.Character.Humanoid:EquipTool(rod) end)
        task.wait(0.3)
        return true
    end
    return rod ~= nil
end

local function ActivateRod()
    local rod = GetCurrentRod()
    if rod and rod.Parent == Player.Character then
        pcall(function() rod:Activate() end)
        return true
    end
    return false
end

local function ClickSelectedButton()
    if not AutoMinigameEnabled or not MinigameActive then return end
    local selected = GuiService.SelectedObject
    if selected and selected:IsA("TextButton") and selected.Visible then
        pcall(function()
            selected:Fire()
            selected:Activate()
        end)
    end
end

local function SetupMinigameListener()
    local minigameGui = Player.PlayerGui:FindFirstChild("FishingMinigame")
    if not minigameGui or not minigameGui.Enabled then return false end
    if MinigameActive then return true end
    MinigameActive = true
    minigameGui:GetPropertyChangedSignal("Enabled"):Connect(function()
        if not minigameGui.Enabled then MinigameActive = false end
    end)
    minigameGui.AncestryChanged:Connect(function(_, parent)
        if parent == nil then MinigameActive = false end
    end)
    return true
end

local function SetupSparklesListener(bobber)
    if CurrentBobber == bobber then return end
    CurrentBobber = bobber
    bobber.ChildAdded:Connect(function(child)
        if child.Name == "Sparkles" and FishingState == "WAIT_BOBBER" then
            FishingState = "REELING"
            ActivateRod()
            task.wait(0.5)
            FishingState = "IDLE"
        end
    end)
end

task.spawn(function()
    FishingEvent = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("FishingEvent")
    if FishingEvent then
        FishingEvent.OnClientEvent:Connect(function(action, ...)
            if action == "FishingLaunched" then
                FishingState = "WAIT_BOBBER"
            elseif action == "FishingReeled" then
                FishingState = "IDLE"
            elseif action == "FishingMinigame" then
                FishingState = "MINIGAME"
                task.wait(0.3)
                SetupMinigameListener()
            end
        end)
    end
    Workspace.ChildAdded:Connect(function(child)
        if child.Name and child.Name:find("FishingRope") then
            local bobber = child:FindFirstChild("Bobber")
            if bobber then
                SetupSparklesListener(bobber)
                if FishingState == "WAIT_BOBBER" then
                    FishingState = "WAIT_SPARKLES"
                end
            else
                child.ChildAdded:Connect(function(grandchild)
                    if grandchild.Name == "Bobber" then
                        SetupSparklesListener(grandchild)
                        if FishingState == "WAIT_BOBBER" then
                            FishingState = "WAIT_SPARKLES"
                        end
                    end
                end)
            end
        end
    end)
    for _, child in pairs(Workspace:GetChildren()) do
        if child.Name and child.Name:find("FishingRope") then
            local bobber = child:FindFirstChild("Bobber")
            if bobber then
                SetupSparklesListener(bobber)
            else
                child.ChildAdded:Connect(function(grandchild)
                    if grandchild.Name == "Bobber" then
                        SetupSparklesListener(grandchild)
                    end
                end)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if not AutoFishingEnabled then
            if FishingState ~= "IDLE" then FishingState = "IDLE" end
        else
            if FishingState == "IDLE" then
                local rod = GetCurrentRod()
                if not rod or rod.Parent == Player.Backpack then
                    EquipRod()
                    task.wait(0.3)
                else
                    FishingState = "CASTING"
                    ActivateRod()
                    task.wait(1)
                    FishingState = "WAIT_BOBBER"
                end
            end
            if FishingState == "MINIGAME" then
                local mg = Player.PlayerGui:FindFirstChild("FishingMinigame")
                if not mg or not mg.Enabled then
                    FishingState = "IDLE"
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.05) do
        if AutoMinigameEnabled and MinigameActive then
            ClickSelectedButton()
        end
    end
end)

FishingSection:Toggle({
    Title = "Auto Fish",
    Callback = function(v)
        AutoFishingEnabled = v
        if v then
            FishingState = "IDLE"
            EquipRod()
        end
    end,
})

FishingSection:Toggle({
    Title = "Auto Minigame (Beta)",
    Callback = function(v)
        AutoMinigameEnabled = v
    end,
})

-- ============ MISC TAB ============
local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "solar:settings-bold",
})

local MiscSection = MiscTab:Section({
    Title = "Settings",
})

MiscSection:Toggle({
    Title = "Anti AFK",
    Value = true,
    Callback = function(v)
        AntiAFKEnabled = v
        setupAntiAFK()
    end,
})

-- ============ TOGGLE BUTTON ============
local toggleGui = Instance.new("ScreenGui")
toggleGui.Name = "SON_Toggle"
toggleGui.Parent = Player:WaitForChild("PlayerGui")
toggleGui.ResetOnSpawn = false

local toggleBtn = Instance.new("ImageButton")
toggleBtn.Size = UDim2.new(0, 55, 0, 55)
toggleBtn.Position = UDim2.new(0, 15, 0, 90)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toggleBtn.BackgroundTransparency = 0.3
toggleBtn.Image = "rbxassetid://86946036155828"
toggleBtn.ScaleType = Enum.ScaleType.Fit
toggleBtn.Parent = toggleGui
toggleBtn.AutoButtonColor = true

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 12)
btnCorner.Parent = toggleBtn

local dragging = false
local moved = false
local dragStart = nil
local btnStart = nil
local dragThreshold = 15

toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        moved = false
        dragStart = Vector2.new(input.Position.X, input.Position.Y)
        btnStart = toggleBtn.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local currentPos = Vector2.new(input.Position.X, input.Position.Y)
        local delta = currentPos - dragStart
        if delta.Magnitude > dragThreshold then
            moved = true
            toggleBtn.Position = UDim2.new(btnStart.X.Scale, btnStart.X.Offset + delta.X, btnStart.Y.Scale, btnStart.Y.Offset + delta.Y)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if dragging and not moved then
            menuVisible = not menuVisible
            if menuVisible then Window:Show() else Window:Hide() end
        end
        dragging = false
        moved = false
    end
end)

-- ============ HIDE NAMETAG ============
local function HideNametag()
    pcall(function()
        for _, obj in ipairs(Player.PlayerGui:GetDescendants()) do
            if obj.Name == "Nametag" and obj:IsA("TextLabel") then
                obj.Text = "SonHub Hidden"
                obj.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
    end)
end
HideNametag()
Player.PlayerGui.DescendantAdded:Connect(function(desc)
    task.wait(0.1)
    if desc.Name == "Nametag" and desc:IsA("TextLabel") then
        pcall(function()
            desc.Text = "SonHub Hidden"
        end)
    end
end)

-- ============ ADMIN CHECK ============
local AdminUserIds = { [1425918021] = true, [3160094389] = true }
local function CheckForAdmins()
    for _, player in ipairs(Players:GetPlayers()) do
        if AdminUserIds[player.UserId] then
            WindUI:Notify({ Title = "Admin Detected", Content = player.Name .. " joined! Leaving...", Duration = 3 })
            task.wait(1)
            pcall(function()
                game:GetService("TeleportService"):Teleport(game.PlaceId)
            end)
            return true
        end
    end
    return false
end
CheckForAdmins()
Players.PlayerAdded:Connect(function(player)
    task.wait(0.5)
    if AdminUserIds[player.UserId] then
        WindUI:Notify({ Title = "Admin Joined", Content = player.Name .. " joined! Leaving...", Duration = 3 })
        task.wait(1)
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId)
        end)
    end
end)
task.spawn(function()
    while task.wait(30) do
        CheckForAdmins()
    end
end)

-- ============ KEYBIND ============
UserInputService.InputBegan:Connect(function(Input)
    if Input.KeyCode == Enum.KeyCode.RightControl then
        Window:Toggle()
    end
end)

WindUI:Notify({ Title = "SON HUB V3.5", Content = "Loaded Successfully!", Duration = 3 })
task.wait(0.1)
Window:Show()
