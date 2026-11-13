-- MM2 Coin Collector | Roblox | Murder Mystery 2
-- Minimize-to-square GUI, drag on both square and window
-- From scratch: raw Roblox API only

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local lp       = Players.LocalPlayer
local char     = lp.Character or lp.CharacterAdded:Wait()
local hrp      = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

-- ─── state ───────────────────────────────────────────────
local collecting    = false
local speed         = 10
local noclipConn    = nil
local collectLoop   = nil
local currentTarget = nil

-- ─── noclip ──────────────────────────────────────────────
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
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

-- ─── coin scanner ────────────────────────────────────────
local function isValidCoin(obj)
    if not obj or not obj.Parent then return false end
    if not obj:IsA("BasePart") then return false end
    if obj.Transparency >= 1 then return false end
    return obj.Name:lower():find("coin") ~= nil
end

local function getNearestCoin()
    local best, bestDist = nil, math.huge
    local origin = hrp.Position
    local root   = workspace:FindFirstChild("CoinContainer") or workspace

    for _, obj in ipairs(root:GetDescendants()) do
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

-- ─── movement ────────────────────────────────────────────
local HOVER_OFFSET = Vector3.new(0, 3, 0)

local function stepToward(targetPart)
    if not targetPart or not targetPart.Parent then
        return true
    end

    local origin = hrp.Position
    local goal   = targetPart.Position + HOVER_OFFSET
    local delta  = goal - origin
    local dist   = delta.Magnitude

    if dist <= 3 then
        return true
    end

    local step   = math.min(speed, dist)
    local newPos = origin + delta.Unit * step

    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.CFrame = CFrame.new(newPos, newPos + delta)
    return false
end

-- ─── collect loop ────────────────────────────────────────
local function startCollecting()
    if collecting then return end
    collecting = true
    enableNoclip()
    humanoid.PlatformStand = true

    collectLoop = RunService.Heartbeat:Connect(function()
        if currentTarget then
            if not currentTarget.Parent then
                currentTarget = nil
                return
            end
            if stepToward(currentTarget) then
                currentTarget = nil
            end
        else
            local coin = getNearestCoin()
            if coin then
                currentTarget = coin
            end
        end
    end)
end

local function stopCollecting()
    if not collecting then return end
    collecting    = false
    currentTarget = nil

    if collectLoop then
        collectLoop:Disconnect()
        collectLoop = nil
    end

    disableNoclip()
    humanoid.PlatformStand = false
end

-- ─── drag helper (mouse + touch) ─────────────────────────
-- handle = what you grab, target = what moves, onTap = fires if no real drag happened
local function makeDraggable(handle, target, onTap)
    local dragging, dragStart, startPos, moved = false, nil, nil, false

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = target.Position
            moved     = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
           and input.UserInputType ~= Enum.UserInputType.Touch then return end

        local delta = input.Position - dragStart
        if delta.Magnitude > 6 then
            moved = true
        end
        target.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            if dragging and not moved and onTap then
                onTap()
            end
            dragging = false
        end
    end)
end

-- ─── ScreenGui ───────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "MM2Collector"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = lp:WaitForChild("PlayerGui")

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

-- ─── minimized square (black, purple stroke, rounded) ────
local square = Instance.new("TextButton")
square.Name                  = "Square"
square.Size                  = UDim2.new(0, 52, 0, 52)
square.Position              = UDim2.new(0, 20, 0, 120)
square.BackgroundColor3      = Color3.fromRGB(0, 0, 0)
square.BackgroundTransparency = 0.1
square.Text                  = "💜"
square.TextSize              = 22
square.AutoButtonColor       = false
square.BorderSizePixel       = 0
square.Parent                = screenGui

addCorner(square, 12)

local squareStroke = Instance.new("UIStroke")
squareStroke.Color        = Color3.fromRGB(160, 80, 220)
squareStroke.Thickness    = 2
squareStroke.Parent       = square

-- ─── main window ────────────────────────────────────────
local frame = Instance.new("Frame")
frame.Name                   = "Window"
frame.Size                   = UDim2.new(0, 240, 0, 190)
frame.Position               = UDim2.new(0.5, -120, 0.5, -95)
frame.BackgroundColor3       = Color3.fromRGB(30, 10, 50)
frame.BackgroundTransparency = 0.25
frame.BorderSizePixel        = 0
frame.Visible                = false
frame.Parent                 = screenGui

addCorner(frame, 10)

-- header bar: drag handle + minimize line
local header = Instance.new("Frame")
header.Name                  = "Header"
header.Size                  = UDim2.new(1, 0, 0, 36)
header.BackgroundTransparency = 1
header.Parent                = frame

local title = Instance.new("TextLabel")
title.Size                  = UDim2.new(1, -44, 1, 0)
title.Position              = UDim2.new(0, 8, 0, 0)
title.BackgroundTransparency = 1
title.Text                  = "💜 MM2 Coin Collector"
title.TextColor3            = Color3.fromRGB(220, 180, 255)
title.Font                  = Enum.Font.GothamBold
title.TextSize              = 15
title.TextXAlignment        = Enum.TextXAlignment.Left
title.Parent                = header

-- minimize: the "—" line
local minBtn = Instance.new("TextButton")
minBtn.Size                  = UDim2.new(0, 32, 0, 28)
minBtn.Position              = UDim2.new(1, -38, 0, 4)
minBtn.BackgroundTransparency = 1
minBtn.Text                  = "—"
minBtn.TextColor3            = Color3.fromRGB(220, 180, 255)
minBtn.Font                  = Enum.Font.GothamBold
minBtn.TextSize              = 18
minBtn.Parent                = header

-- start/stop
local btn = Instance.new("TextButton")
btn.Size                  = UDim2.new(1, -24, 0, 42)
btn.Position              = UDim2.new(0, 12, 0, 44)
btn.BackgroundColor3      = Color3.fromRGB(70, 20, 110)
btn.BackgroundTransparency = 0.1
btn.Text                  = "▶  Начать"
btn.TextColor3            = Color3.fromRGB(230, 200, 255)
btn.Font                  = Enum.Font.GothamBold
btn.TextSize              = 16
btn.BorderSizePixel       = 0
btn.Parent                = frame

addCorner(btn, 8)

-- speed label
local speedLabel = Instance.new("TextLabel")
speedLabel.Size                  = UDim2.new(1, -24, 0, 22)
speedLabel.Position              = UDim2.new(0, 12, 0, 100)
speedLabel.BackgroundTransparency = 1
speedLabel.Text                  = "⚡ Скорость: " .. speed
speedLabel.TextColor3            = Color3.fromRGB(200, 170, 240)
speedLabel.Font                  = Enum.Font.Gotham
speedLabel.TextSize              = 13
speedLabel.TextXAlignment        = Enum.TextXAlignment.Left
speedLabel.Parent                = frame

-- slider
local sliderTrack = Instance.new("Frame")
sliderTrack.Size                  = UDim2.new(1, -24, 0, 8)
sliderTrack.Position              = UDim2.new(0, 12, 0, 128)
sliderTrack.BackgroundColor3      = Color3.fromRGB(80, 40, 120)
sliderTrack.BackgroundTransparency = 0.3
sliderTrack.BorderSizePixel       = 0
sliderTrack.Parent                = frame

addCorner(sliderTrack, 999)

local sliderFill = Instance.new("Frame")
sliderFill.Size                  = UDim2.new(speed / 40, 0, 1, 0)
sliderFill.BackgroundColor3      = Color3.fromRGB(160, 80, 220)
sliderFill.BorderSizePixel       = 0
sliderFill.Parent                = sliderTrack

addCorner(sliderFill, 999)

local knob = Instance.new("TextButton")
knob.Size                  = UDim2.new(0, 18, 0, 18)
knob.AnchorPoint           = Vector2.new(0.5, 0.5)
knob.Position              = UDim2.new(speed / 40, 0, 0.5, 0)
knob.BackgroundColor3      = Color3.fromRGB(200, 130, 255)
knob.Text                  = ""
knob.BorderSizePixel       = 0
knob.Parent                = sliderTrack

addCorner(knob, 999)

-- warning
local warnLabel = Instance.new("TextLabel")
warnLabel.Size                  = UDim2.new(1, -24, 0, 22)
warnLabel.Position              = UDim2.new(0, 12, 0, 148)
warnLabel.BackgroundTransparency = 1
warnLabel.Text                  = "⚠️ Высокая скорость — возможен кик!"
warnLabel.TextColor3            = Color3.fromRGB(255, 160, 80)
warnLabel.Font                  = Enum.Font.Gotham
warnLabel.TextSize              = 11
warnLabel.TextXAlignment        = Enum.TextXAlignment.Center
warnLabel.Visible               = false
warnLabel.Parent                = frame

-- ─── slider drag ─────────────────────────────────────────
local sliderDragging = false

local function setSpeedFromX(x)
    local trackX = sliderTrack.AbsolutePosition.X
    local trackW = sliderTrack.AbsoluteSize.X
    local ratio  = math.clamp((x - trackX) / trackW, 0, 1)

    speed = math.max(1, math.floor(ratio * 40 + 0.5))

    sliderFill.Size   = UDim2.new(ratio, 0, 1, 0)
    knob.Position     = UDim2.new(ratio, 0, 0.5, 0)
    speedLabel.Text   = "⚡ Скорость: " .. speed
    warnLabel.Visible = speed > 20
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

sliderTrack.InputBegan:Connect(function(input)
    if isPress(input) then
        sliderDragging = true
        setSpeedFromX(input.Position.X)
    end
end)

knob.InputBegan:Connect(function(input)
    if isPress(input) then
        sliderDragging = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if isPress(input) then
        sliderDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not sliderDragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
       and input.UserInputType ~= Enum.UserInputType.Touch then return end
    setSpeedFromX(input.Position.X)
end)

-- ─── start/stop ──────────────────────────────────────────
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

-- ─── minimize / open ─────────────────────────────────────
local function showWindow()
    frame.Position = UDim2.new(
        0, square.AbsolutePosition.X + 60,
        0, square.AbsolutePosition.Y
    )
    frame.Visible  = true
    square.Visible = false
end

local function minimizeWindow()
    square.Position = UDim2.new(
        0, frame.AbsolutePosition.X,
        0, frame.AbsolutePosition.Y
    )
    frame.Visible  = false
    square.Visible = true
end

minBtn.MouseButton1Click:Connect(minimizeWindow)

-- square: drag to move, tap to open
makeDraggable(square, square, showWindow)

-- window: drag by header
makeDraggable(header, frame)

-- ─── respawn ─────────────────────────────────────────────
lp.CharacterAdded:Connect(function(newChar)
    stopCollecting()
    char     = newChar
    hrp      = newChar:WaitForChild("HumanoidRootPart")
    humanoid = newChar:WaitForChild("Humanoid")
    btn.Text             = "▶  Начать"
    btn.BackgroundColor3 = Color3.fromRGB(70, 20, 110)
end)
