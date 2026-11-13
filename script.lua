-- MM2 Coin Collector | Roblox | Murder Mystery 2
-- Persistent on/off + speed, lobby-safe, lying flight, touch-and-go coins
-- From scratch: raw Roblox API only
-- v2: real speed scaling, anti-fallthrough safety net, throttled scans, cheaper noclip

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local genv = (typeof(getgenv) == "function" and getgenv()) or _G
local guiPresent = Players.LocalPlayer:FindFirstChild("PlayerGui")
    and Players.LocalPlayer.PlayerGui:FindFirstChild("MM2Collector")
if genv.MM2CollectorRunning and guiPresent then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "MM2 Collector",
            Text = "Уже запущен 💜",
            Duration = 3,
        })
    end)
    return
end
genv.MM2CollectorRunning = true

local lp       = Players.LocalPlayer
local char     = lp.Character or lp.CharacterAdded:Wait()
local hrp      = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

-- ─── persistent store (survives respawn, and re-run if getgenv exists) ───
local store = (typeof(getgenv) == "function" and getgenv()) or _G
store.MM2Collector = store.MM2Collector or { on = false, speed = 1 }
local saved = store.MM2Collector

-- ─── speed model ──────────────────────────────────────────
-- Slider value IS studs/sec now. No hidden scale factor: moving the
-- slider actually moves the character faster/slower 1:1.
local SPEED_MIN, SPEED_MAX = 4, 120

local function clampSpeed(s)
    return math.clamp(tonumber(s) or SPEED_MIN, SPEED_MIN, SPEED_MAX)
end

local collectOn     = saved.on
local speed         = clampSpeed(saved.speed)
saved.speed         = speed -- normalize any bad/old saved value immediately

local active        = false
local noclipParts   = {}   -- [BasePart] = true, tracked set instead of rescanning every tick
local noclipConns   = {}   -- per-character connections (Stepped + DescendantAdded)
local currentTarget = nil
local coinCount     = 0
local statusLabel   = nil
local blacklist     = {}
local facing        = Vector3.new(0, 0, -1)
local LYING         = CFrame.Angles(math.rad(-90), 0, 0)

-- last confirmed grounded, upright, collidable position — our fallback
-- if we ever end up somewhere broken (under the map, stuck in geometry)
local lastSafeCFrame = hrp.CFrame
local UNDER_MAP_DROP = 40 -- studs below lastSafeCFrame.Y considered "fell through"

-- ─── noclip (cheap: tag parts once, no per-tick GetDescendants scan) ──
local function trackPart(part)
    if part:IsA("BasePart") and not noclipParts[part] then
        noclipParts[part] = true
    end
end

local function enableNoclip()
    for _, part in ipairs(char:GetDescendants()) do
        trackPart(part)
    end

    noclipConns.added = char.DescendantAdded:Connect(function(part)
        trackPart(part)
        if active and part:IsA("BasePart") then
            part.CanCollide = false
        end
    end)

    noclipConns.stepped = RunService.Stepped:Connect(function()
        for part in pairs(noclipParts) do
            if part.Parent then
                part.CanCollide = false
            else
                noclipParts[part] = nil -- part got destroyed, stop tracking it
            end
        end
    end)
end

local function disableNoclip()
    if noclipConns.stepped then
        noclipConns.stepped:Disconnect()
        noclipConns.stepped = nil
    end
    if noclipConns.added then
        noclipConns.added:Disconnect()
        noclipConns.added = nil
    end
    for part in pairs(noclipParts) do
        if part.Parent then
            part.CanCollide = true
        end
    end
end

-- ─── anti-fallthrough: raycast for a safe landing spot ────
local function findSafeLanding(fromPos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char }

    local result = workspace:Raycast(fromPos, Vector3.new(0, -500, 0), params)
    if result then
        return result.Position + Vector3.new(0, 3, 0)
    end

    -- nothing below at all (open void) — fall back to the last known
    -- good spot rather than leaving the character in freefall forever
    return lastSafeCFrame.Position
end

-- on = lying + noclip + flight allowed, off = normal character
local function setActive(on)
    if on == active then
        if on then humanoid.PlatformStand = true end
        return
    end
    active = on

    if on then
        enableNoclip()
        humanoid.PlatformStand = true
    else
        -- straighten up BEFORE restoring collision, and if we're way
        -- below our last safe height, recover to a real surface first.
        -- This is what used to let the ragdoll-under-the-map happen:
        -- CanCollide flipped true while still rotated 90° and clipped
        -- into geometry. Fix order: unrotate -> verify ground -> collide.
        local pos = hrp.Position
        if pos.Y < lastSafeCFrame.Position.Y - UNDER_MAP_DROP then
            pos = findSafeLanding(lastSafeCFrame.Position + Vector3.new(0, 10, 0))
        end

        hrp.CFrame = CFrame.lookAt(pos, pos + facing)
        disableNoclip()
        humanoid.PlatformStand = false
        lastSafeCFrame = hrp.CFrame
    end
end

-- ─── coin detection (throttled — no full workspace scan every frame) ──
local SCAN_INTERVAL = 0.15
local scanTimer = 0

local function getCoinRoot()
    return workspace:FindFirstChild("CoinContainer") or workspace
end

local function isValidCoin(obj)
    if not obj or not obj.Parent then return false end
    if not (obj:IsA("BasePart") or obj:IsA("Model")) then return false end
    if obj:IsDescendantOf(char) then return false end
    return obj.Name:lower() == "coin_server"
end

local function coinPos(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    end
    return obj:GetPivot().Position
end

local function scanCoins()
    local root = getCoinRoot()
    coinCount = 0
    if not root then return nil end

    local now    = os.clock()
    local origin = hrp.Position
    local best, bestDist = nil, math.huge

    for _, obj in ipairs(root:GetDescendants()) do
        if isValidCoin(obj) and (not blacklist[obj] or blacklist[obj] < now) then
            coinCount += 1
            local d = (coinPos(obj) - origin).Magnitude
            if d < bestDist then
                bestDist = d
                best     = obj
            end
        end
    end
    return best
end

-- ─── movement (always lying) ─────────────────────────────
local function layAt(pos)
    hrp.CFrame = CFrame.lookAt(pos, pos + facing) * LYING
end

local function isAlive()
    return lp.Character == char
        and char.Parent ~= nil
        and hrp.Parent ~= nil
        and humanoid.Health > 0
end

local function stepToward(targetPart, dt)
    if not targetPart or not targetPart.Parent then
        return true
    end

    local origin = hrp.Position
    local delta  = coinPos(targetPart) - origin
    local dist   = delta.Magnitude

    if dist <= 2 then
        return true
    end

    local flat = Vector3.new(delta.X, 0, delta.Z)
    if flat.Magnitude > 0.05 then
        facing = flat.Unit
    end

    -- speed is now studs/sec directly, clamped every use so a corrupted
    -- saved value (old save, external tamper) can never exceed SPEED_MAX
    local step   = math.min(clampSpeed(speed) * dt, dist)
    local newPos = origin + delta.Unit * step

    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    layAt(newPos)
    return false
end

-- ─── main loop ───────────────────────────────────────────
RunService.Heartbeat:Connect(function(dt)
    if not collectOn or not isAlive() then
        currentTarget = nil
        setActive(false)
        return
    end

    if not active then
        -- we're grounded and idle right now — remember this as a good
        -- recovery point before we start flying again
        lastSafeCFrame = hrp.CFrame
    end

    if statusLabel then
        statusLabel.Text = ("Монет: %d | цель: %s | ⚡%.0f"):format(
            coinCount, currentTarget and currentTarget.Name or "нет", speed)
    end

    if currentTarget and not currentTarget.Parent then
        currentTarget = nil
    end

    if not currentTarget then
        scanTimer -= dt
        if scanTimer <= 0 then
            scanTimer = SCAN_INTERVAL
            currentTarget = scanCoins()
        end
    end

    if not currentTarget then
        setActive(false)
        return
    end

    setActive(true)
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    if stepToward(currentTarget, dt) then
        blacklist[currentTarget] = os.clock() + 6
        currentTarget = nil
        layAt(hrp.Position)
    end
end)

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

local square = Instance.new("TextButton")
square.Name                   = "Square"
square.Size                   = UDim2.new(0, 52, 0, 52)
square.Position               = UDim2.new(0, 20, 0, 120)
square.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
square.BackgroundTransparency = 0.1
square.Text                   = "💜"
square.TextSize               = 22
square.AutoButtonColor        = false
square.BorderSizePixel        = 0
square.Parent                 = screenGui

addCorner(square, 12)

local squareStroke = Instance.new("UIStroke")
squareStroke.Color     = Color3.fromRGB(160, 80, 220)
squareStroke.Thickness = 2
squareStroke.Parent    = square

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

local header = Instance.new("Frame")
header.Name                   = "Header"
header.Size                   = UDim2.new(1, 0, 0, 36)
header.BackgroundTransparency = 1
header.Parent                 = frame

local title = Instance.new("TextLabel")
title.Size                   = UDim2.new(1, -44, 1, 0)
title.Position               = UDim2.new(0, 8, 0, 0)
title.BackgroundTransparency = 1
title.Text                   = "💜 MM2 Coin Collector"
title.TextColor3             = Color3.fromRGB(220, 180, 255)
title.Font                   = Enum.Font.GothamBold
title.TextSize               = 15
title.TextXAlignment         = Enum.TextXAlignment.Left
title.Parent                 = header

local minBtn = Instance.new("TextButton")
minBtn.Size                   = UDim2.new(0, 32, 0, 28)
minBtn.Position               = UDim2.new(1, -38, 0, 4)
minBtn.BackgroundTransparency = 1
minBtn.Text                   = "—"
minBtn.TextColor3             = Color3.fromRGB(220, 180, 255)
minBtn.Font                   = Enum.Font.GothamBold
minBtn.TextSize               = 18
minBtn.Parent                 = header

local btn = Instance.new("TextButton")
btn.Size                   = UDim2.new(1, -24, 0, 42)
btn.Position               = UDim2.new(0, 12, 0, 44)
btn.BackgroundTransparency = 0.1
btn.BorderSizePixel        = 0
btn.Font                   = Enum.Font.GothamBold
btn.TextSize               = 16
btn.Parent                 = frame

addCorner(btn, 8)

local speedLabel = Instance.new("TextLabel")
speedLabel.Size                   = UDim2.new(1, -24, 0, 22)
speedLabel.Position               = UDim2.new(0, 12, 0, 100)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3             = Color3.fromRGB(200, 170, 240)
speedLabel.Font                   = Enum.Font.Gotham
speedLabel.TextSize               = 13
speedLabel.TextXAlignment         = Enum.TextXAlignment.Left
speedLabel.Parent                 = frame

local sliderTrack = Instance.new("Frame")
sliderTrack.Size                   = UDim2.new(1, -24, 0, 8)
sliderTrack.Position               = UDim2.new(0, 12, 0, 128)
sliderTrack.BackgroundColor3       = Color3.fromRGB(80, 40, 120)
sliderTrack.BackgroundTransparency = 0.3
sliderTrack.BorderSizePixel        = 0
sliderTrack.Parent                 = frame

addCorner(sliderTrack, 999)

local sliderFill = Instance.new("Frame")
sliderFill.BackgroundColor3 = Color3.fromRGB(160, 80, 220)
sliderFill.BorderSizePixel  = 0
sliderFill.Parent           = sliderTrack

addCorner(sliderFill, 999)

local knob = Instance.new("TextButton")
knob.Size             = UDim2.new(0, 18, 0, 18)
knob.AnchorPoint      = Vector2.new(0.5, 0.5)
knob.BackgroundColor3 = Color3.fromRGB(200, 130, 255)
knob.Text             = ""
knob.BorderSizePixel  = 0
knob.Parent           = sliderTrack

addCorner(knob, 999)

local warnLabel = Instance.new("TextLabel")
warnLabel.Size                   = UDim2.new(1, -24, 0, 22)
warnLabel.Position               = UDim2.new(0, 12, 0, 148)
warnLabel.BackgroundTransparency = 1
warnLabel.Text                   = "⚠️ Высокая скорость — возможен кик!"
warnLabel.TextColor3             = Color3.fromRGB(255, 160, 80)
warnLabel.Font                   = Enum.Font.Gotham
warnLabel.TextSize               = 11
warnLabel.TextXAlignment         = Enum.TextXAlignment.Center
warnLabel.Visible                = false
warnLabel.Parent                 = frame

statusLabel = Instance.new("TextLabel")
statusLabel.Size                   = UDim2.new(1, -24, 0, 16)
statusLabel.Position               = UDim2.new(0, 12, 0, 170)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3             = Color3.fromRGB(170, 140, 210)
statusLabel.Font                   = Enum.Font.Gotham
statusLabel.TextSize               = 11
statusLabel.Text                   = "Монет: 0 | цель: нет"
statusLabel.Parent                 = frame

-- ─── GUI helpers ─────────────────────────────────────────
local function refreshButton()
    if collectOn then
        btn.Text             = "⏹  Остановить"
        btn.BackgroundColor3 = Color3.fromRGB(100, 20, 60)
    else
        btn.Text             = "▶  Начать"
        btn.BackgroundColor3 = Color3.fromRGB(70, 20, 110)
    end
end

local function speedToRatio(s)
    return math.sqrt((s - SPEED_MIN) / (SPEED_MAX - SPEED_MIN))
end

local function ratioToSpeed(r)
    return SPEED_MIN + (SPEED_MAX - SPEED_MIN) * r * r
end

local function showSpeed(ratio)
    sliderFill.Size   = UDim2.new(ratio, 0, 1, 0)
    knob.Position     = UDim2.new(ratio, 0, 0.5, 0)
    speedLabel.Text   = ("⚡ Скорость: %.0f studs/s"):format(speed)
    warnLabel.Visible = speed > 60
end

local function setSpeedFromX(x)
    local trackX = sliderTrack.AbsolutePosition.X
    local trackW = sliderTrack.AbsoluteSize.X
    local ratio  = math.clamp((x - trackX) / trackW, 0, 1)

    speed       = clampSpeed(math.floor(ratioToSpeed(ratio) + 0.5))
    saved.speed = speed
    showSpeed(speedToRatio(speed))
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

-- ─── slider drag ─────────────────────────────────────────
local sliderDragging = false

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

-- ─── start/stop (state saved) ────────────────────────────
btn.MouseButton1Click:Connect(function()
    collectOn   = not collectOn
    saved.on    = collectOn
    currentTarget = nil
    scanTimer = 0
    refreshButton()
end)

-- ─── minimize / open ─────────────────────────────────────
local function showWindow()
    frame.Position = UDim2.new(0, square.AbsolutePosition.X + 60, 0, square.AbsolutePosition.Y)
    frame.Visible  = true
    square.Visible = false
end

local function minimizeWindow()
    square.Position = UDim2.new(0, frame.AbsolutePosition.X, 0, frame.AbsolutePosition.Y)
    frame.Visible   = false
    square.Visible  = true
end

minBtn.MouseButton1Click:Connect(minimizeWindow)

-- ─── drag helper (mouse + touch) ─────────────────────────
local function makeDraggable(handle, target, onTap)
    local dragging, dragStart, startPos, moved = false, nil, nil, false

    handle.InputBegan:Connect(function(input)
        if isPress(input) then
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
        if isPress(input) then
            if dragging and not moved and onTap then
                onTap()
            end
            dragging = false
        end
    end)
end

makeDraggable(square, square, showWindow)
makeDraggable(header, frame)

-- ─── init GUI from saved state ───────────────────────────
showSpeed(speedToRatio(speed))
refreshButton()

-- ─── respawn: keep on/off, re-grab character refs ────────
lp.CharacterAdded:Connect(function(newChar)
    char     = newChar
    hrp      = newChar:WaitForChild("HumanoidRootPart")
    humanoid = newChar:WaitForChild("Humanoid")

    disableNoclip()
    noclipParts   = {}
    active        = false
    currentTarget = nil
    blacklist     = {}
    scanTimer     = 0
    lastSafeCFrame = hrp.CFrame
end)
