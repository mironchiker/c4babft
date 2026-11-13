-- MM2 Coin Collector | Roblox | Murder Mystery 2
-- Auto-collects coins with noclip flight, dark-purple GUI
-- From scratch: no frameworks, raw Roblox API only

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local lp           = Players.LocalPlayer
local char         = lp.Character or lp.CharacterAdded:Wait()
local hrp          = char:WaitForChild("HumanoidRootPart")
local humanoid     = char:WaitForChild("Humanoid")

-- ─── state ───────────────────────────────────────────────
local collecting   = false
local speed        = 10        -- studs per heartbeat step
local noclipConn   = nil
local collectLoop  = nil
local currentTarget = nil

-- ─── noclip (bypass collision while flying) ──────────────
local function enableNoclip()
    noclipConn = RunService.Stepped:Connect(function()
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function disableNoclip()
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
    -- restore normal collision on character
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

-- ─── coin scanner ────────────────────────────────────────
-- MM2 coins live under workspace, their Name contains "Coin"
-- or they have a tag / BillboardGui child — we check both
local function isValidCoin(obj)
    if not obj or not obj.Parent then return false end
    if not obj:IsA("BasePart") and not obj:IsA("MeshPart") and not obj:IsA("Part") then
        return false
    end
    local n = obj.Name:lower()
    return n:find("coin") ~= nil
end

local function getNearestCoin()
    local best     = nil
    local bestDist = math.huge
    local origin   = hrp.Position

    for _, obj in ipairs(workspace:GetDescendants()) do
        if isValidCoin(obj) then
            local d = (obj.Position - origin).Magnitude
            if d < bestDist then
                bestDist = d
                best     = obj
            end
        end
    end
    return best, bestDist
end

-- ─── movement toward a part ──────────────────────────────
-- steps toward target each Heartbeat tick at `speed` studs/step
local function stepToward(targetPart)
    -- returns true when arrived OR target gone
    if not targetPart or not targetPart.Parent then
        return true   -- target vanished → caller handles it
    end

    local origin = hrp.Position
    local goal   = targetPart.Position
    local delta  = (goal - origin)
    local dist   = delta.Magnitude

    if dist <= 3 then
        return true   -- close enough → collected
    end

    local direction = delta.Unit
    local step      = math.min(speed, dist)
    local newPos    = origin + direction * step

    hrp.CFrame = CFrame.new(newPos, goal)
    return false
end

-- ─── main collect loop ───────────────────────────────────
local function startCollecting()
    if collecting then return end
    collecting = true
    enableNoclip()

    humanoid.PlatformStand = true  -- freeze default locomotion

    collectLoop = RunService.Heartbeat:Connect(function()
        -- if we have a target, keep moving toward it
        if currentTarget then
            if not currentTarget.Parent then
                -- coin disappeared mid-flight → idle, search again
                currentTarget = nil
                return
            end
            local arrived = stepToward(currentTarget)
            if arrived then
                currentTarget = nil  -- pick next one next frame
            end
        else
            -- scan for nearest coin
            local coin, dist = getNearestCoin()
            if coin then
                currentTarget = coin
            end
            -- if no coin found we just idle until one spawns
        end
    end)
end

local function stopCollecting()
    if not collecting then return end
    collecting = false
    currentTarget = nil

    if collectLoop then
        collectLoop:Disconnect()
        collectLoop = nil
    end

    disableNoclip()
    humanoid.PlatformStand = false
end

-- ─── GUI ─────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "MM2Collector"
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Parent          = lp:WaitForChild("PlayerGui")

-- main frame — translucent dark purple
local frame = Instance.new("Frame")
frame.Size            = UDim2.new(0, 240, 0, 190)
frame.Position        = UDim2.new(0.5, -120, 0.5, -95)
frame.BackgroundColor3 = Color3.fromRGB(30, 10, 50)
frame.BackgroundTransparency = 0.25
frame.BorderSizePixel = 0
frame.Active          = true
frame.Draggable       = true
frame.Parent          = screenGui

-- rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

-- title bar
local title = Instance.new("TextLabel")
title.Size            = UDim2.new(1, 0, 0, 36)
title.Position        = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text            = "💜 MM2 Coin Collector"
title.TextColor3      = Color3.fromRGB(220, 180, 255)
title.Font            = Enum.Font.GothamBold
title.TextSize        = 15
title.Parent          = frame

-- start/stop button — dark purple
local btn = Instance.new("TextButton")
btn.Size              = UDim2.new(1, -24, 0, 42)
btn.Position          = UDim2.new(0, 12, 0, 44)
btn.BackgroundColor3  = Color3.fromRGB(70, 20, 110)
btn.BackgroundTransparency = 0.1
btn.Text              = "▶  Начать"
btn.TextColor3        = Color3.fromRGB(230, 200, 255)
btn.Font              = Enum.Font.GothamBold
btn.TextSize          = 16
btn.BorderSizePixel   = 0
btn.Parent            = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = btn

-- speed label
local speedLabel = Instance.new("TextLabel")
speedLabel.Size              = UDim2.new(1, -24, 0, 22)
speedLabel.Position          = UDim2.new(0, 12, 0, 100)
speedLabel.BackgroundTransparency = 1
speedLabel.Text              = "⚡ Скорость: " .. speed
speedLabel.TextColor3        = Color3.fromRGB(200, 170, 240)
speedLabel.Font              = Enum.Font.Gotham
speedLabel.TextSize          = 13
speedLabel.TextXAlignment    = Enum.TextXAlignment.Left
speedLabel.Parent            = frame

-- slider track
local sliderTrack = Instance.new("Frame")
sliderTrack.Size              = UDim2.new(1, -24, 0, 8)
sliderTrack.Position          = UDim2.new(0, 12, 0, 128)
sliderTrack.BackgroundColor3  = Color3.fromRGB(80, 40, 120)
sliderTrack.BackgroundTransparency = 0.3
sliderTrack.BorderSizePixel   = 0
sliderTrack.Parent            = frame

local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent = sliderTrack

-- slider fill
local sliderFill = Instance.new("Frame")
sliderFill.Size              = UDim2.new(speed / 40, 0, 1, 0)  -- max ~40
sliderFill.BackgroundColor3  = Color3.fromRGB(160, 80, 220)
sliderFill.BackgroundTransparency = 0
sliderFill.BorderSizePixel   = 0
sliderFill.Parent            = sliderTrack

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = sliderFill

-- slider knob
local knob = Instance.new("TextButton")
knob.Size              = UDim2.new(0, 18, 0, 18)
knob.AnchorPoint       = Vector2.new(0.5, 0.5)
knob.Position          = UDim2.new(speed / 40, 0, 0.5, 0)
knob.BackgroundColor3  = Color3.fromRGB(200, 130, 255)
knob.Text              = ""
knob.BorderSizePixel   = 0
knob.Parent            = sliderTrack

local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = knob

-- warning label (hidden by default)
local warnLabel = Instance.new("TextLabel")
warnLabel.Size              = UDim2.new(1, -24, 0, 22)
warnLabel.Position          = UDim2.new(0, 12, 0, 148)
warnLabel.BackgroundTransparency = 1
warnLabel.Text              = "⚠️ Высокая скорость — возможен кик!"
warnLabel.TextColor3        = Color3.fromRGB(255, 160, 80)
warnLabel.Font              = Enum.Font.Gotham
warnLabel.TextSize          = 11
warnLabel.TextXAlignment    = Enum.TextXAlignment.Center
warnLabel.Visible           = false
warnLabel.Parent            = frame

-- ─── slider drag logic ───────────────────────────────────
local dragging = false

knob.MouseButton1Down:Connect(function()
    dragging = true
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
       and input.UserInputType ~= Enum.UserInputType.Touch then return end

    local trackAbsPos  = sliderTrack.AbsolutePosition.X
    local trackAbsSize = sliderTrack.AbsoluteSize.X
    local mouseX       = input.Position.X

    local ratio = math.clamp((mouseX - trackAbsPos) / trackAbsSize, 0, 1)
    speed = math.floor(ratio * 40)
    if speed < 1 then speed = 1 end

    -- update visuals
    sliderFill.Size     = UDim2.new(ratio, 0, 1, 0)
    knob.Position       = UDim2.new(ratio, 0, 0.5, 0)
    speedLabel.Text     = "⚡ Скорость: " .. speed

    -- warn if > 20
    warnLabel.Visible   = speed > 20
end)

-- ─── start/stop button ───────────────────────────────────
btn.MouseButton1Click:Connect(function()
    if collecting then
        stopCollecting()
        btn.Text             = "▶  Начать"
        btn.BackgroundColor3 = Color3.fromRGB(70, 20, 110)
    else
        startCollecting()
        btn.Text             = "⏹  Остановить"
        btn.BackgroundColor3 = Color3.fromRGB(100, 20, 60)
    end
end)

-- ─── respawn handling ─────────────────────────────────────
-- if char respawns, re-grab references
lp.CharacterAdded:Connect(function(newChar)
    stopCollecting()
    char      = newChar
    hrp       = newChar:WaitForChild("HumanoidRootPart")
    humanoid  = newChar:WaitForChild("Humanoid")
    btn.Text              = "▶  Начать"
    btn.BackgroundColor3  = Color3.fromRGB(70, 20, 110)
end)
