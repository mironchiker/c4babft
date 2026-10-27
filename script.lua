-- [c4] BABFT Studio v2 — Setup (PC/Mobile, RU/EN, Themes), Minimize, .build Loader & Reset Farm

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================================
-- CONFIG, THEMES & LOCALIZATION (I18N)
-- ============================================================================
local Config = {
	ToggleKey = Enum.KeyCode.Insert,
	Platform = "PC", -- "PC" | "Mobile"
	Language = "RU", -- "RU" | "EN"
	Theme = "Monochrome", -- "Monochrome" | "Midnight" | "Crimson"
	BuildDelay = 0.05,
	UseRelativeOrigin = false,
	AutoFarmActive = false,
	AutoBuildActive = false,
	SelectedFile = "",
}

type ThemePalette = {
	Bg: Color3,
	Panel: Color3,
	Card: Color3,
	Accent: Color3,
	AccentText: Color3,
	Text: Color3,
	SubText: Color3,
	Stroke: Color3,
	Good: Color3,
	Bad: Color3,
}

local Themes: { [string]: ThemePalette } = {
	-- По умолчанию: строго черно-белая (Monochrome)
	["Monochrome"] = {
		Bg         = Color3.fromRGB(10, 10, 10),
		Panel      = Color3.fromRGB(18, 18, 18),
		Card       = Color3.fromRGB(24, 24, 24),
		Accent     = Color3.fromRGB(245, 245, 245),
		AccentText = Color3.fromRGB(10, 10, 10),
		Text       = Color3.fromRGB(245, 245, 245),
		SubText    = Color3.fromRGB(155, 155, 155),
		Stroke     = Color3.fromRGB(70, 70, 70),
		Good       = Color3.fromRGB(220, 220, 220),
		Bad        = Color3.fromRGB(110, 110, 110),
	},
	["Midnight"] = {
		Bg         = Color3.fromRGB(15, 16, 22),
		Panel      = Color3.fromRGB(22, 23, 32),
		Card       = Color3.fromRGB(28, 30, 42),
		Accent     = Color3.fromRGB(75, 115, 245),
		AccentText = Color3.fromRGB(255, 255, 255),
		Text       = Color3.fromRGB(240, 242, 255),
		SubText    = Color3.fromRGB(150, 160, 185),
		Stroke     = Color3.fromRGB(52, 58, 82),
		Good       = Color3.fromRGB(85, 205, 130),
		Bad        = Color3.fromRGB(225, 95, 95),
	},
	["Crimson"] = {
		Bg         = Color3.fromRGB(16, 12, 14),
		Panel      = Color3.fromRGB(24, 18, 20),
		Card       = Color3.fromRGB(32, 22, 26),
		Accent     = Color3.fromRGB(220, 55, 75),
		AccentText = Color3.fromRGB(255, 255, 255),
		Text       = Color3.fromRGB(245, 235, 238),
		SubText    = Color3.fromRGB(175, 145, 152),
		Stroke     = Color3.fromRGB(78, 42, 48),
		Good       = Color3.fromRGB(220, 55, 75),
		Bad        = Color3.fromRGB(130, 60, 68),
	},
}

local I18n: { [string]: { [string]: string } } = {
	["RU"] = {
		SetupTitle = "НАСТРОЙКА СКРИПТА",
		PlatformLbl = "Устройство (PC / Mobile):",
		LangLbl = "Язык интерфейса (Language):",
		ThemeLbl = "Тема оформления:",
		StartScript = "ПРОДОЛЖИТЬ",
		TabFarm = "Авто Фарм",
		TabBuild = "Авто Билд",
		TabWorkshop = "Воркшоп (.build)",
		TabSettings = "Настройки",
		FarmTitle = "Reset Gold Grinder (Быстрый фарм порциями)",
		FarmIdle = "Статус: Ожидание запуска",
		FarmStage = "Статус: Импульс по этапу %d / 10 (+золото)",
		FarmReset = "Статус: Фиксация золота и быстрый ресет...",
		FarmStart = "Запустить Auto Farm",
		FarmStop = "Остановить Auto Farm",
		StatCurrent = "Сейчас есть",
		StatSession = "Собрано за сессию",
		StatHourly = "Заработок в час",
		ResetStats = "Сбросить счетчик",
		FileSelected = "Файл: ",
		FileNone = "Файл не выбран",
		MetaFormat = "Версия: %s  |  Деталей: %d  |  Типов: %d",
		SelectFileBtn = "Выбрать .build файл ▾",
		RescanBtn = "Обновить",
		CoordWorld = "Коорд: World",
		CoordPlot = "Коорд: Plot",
		BuildStart = "Построить",
		BuildStop = "Стоп",
		BuildReady = "Готов к постройке",
		BuildProgress = "Сборка [%d/%d]: %s",
		BuildDone = "Сборка завершена",
		ItemStatsFormat = "Есть: %d   |   Еще надо: %d   |   Всего нужно: %d",
		SelectPreset = "Выбрать",
	},
	["EN"] = {
		SetupTitle = "SCRIPT INITIAL SETUP",
		PlatformLbl = "Platform (PC / Mobile):",
		LangLbl = "Interface Language:",
		ThemeLbl = "Color Theme:",
		StartScript = "CONTINUE",
		TabFarm = "Auto Farm",
		TabBuild = "Auto Build",
		TabWorkshop = "Workshop (.build)",
		TabSettings = "Settings",
		FarmTitle = "Reset Gold Grinder (Chunked Fast Farm)",
		FarmIdle = "Status: Idle",
		FarmStage = "Status: Stage impulse %d / 10 (+gold chunk)",
		FarmReset = "Status: Claiming gold & fast resetting...",
		FarmStart = "Start Auto Farm",
		FarmStop = "Stop Auto Farm",
		StatCurrent = "Current Gold",
		StatSession = "Session Gained",
		StatHourly = "Gold / Hour",
		ResetStats = "Reset Counter",
		FileSelected = "File: ",
		FileNone = "No file selected",
		MetaFormat = "Version: %s  |  Blocks: %d  |  Types: %d",
		SelectFileBtn = "Select .build file ▾",
		RescanBtn = "Rescan",
		CoordWorld = "Coord: World",
		CoordPlot = "Coord: Plot",
		BuildStart = "Start Build",
		BuildStop = "Stop",
		BuildReady = "Ready to build",
		BuildProgress = "Building [%d/%d]: %s",
		BuildDone = "Build completed",
		ItemStatsFormat = "Have: %d   |   Need: %d   |   Total: %d",
		SelectPreset = "Select",
	},
}

local function tr(key: string): string
	local dict = I18n[Config.Language] or I18n["RU"]
	return dict[key] or key
end

local function getPalette(): ThemePalette
	return Themes[Config.Theme] or Themes["Monochrome"]
end

-- ============================================================================
-- BLOCK METADATA & EMBEDDED .BUILD SAMPLE
-- ============================================================================
local BlockMeta: { [string]: { Icon: string, Display: string } } = {
	["BackWheel"]     = { Icon = "rbxassetid://6031260781", Display = "Back Wheel" },
	["Camera"]        = { Icon = "rbxassetid://6031094670", Display = "Camera" },
	["CarSeat"]       = { Icon = "rbxassetid://6031094678", Display = "Car Seat" },
	["ConcreteBlock"] = { Icon = "rbxassetid://6031265976", Display = "Concrete Block" },
	["Gate"]          = { Icon = "rbxassetid://6031097225", Display = "Logic Gate" },
	["LightBulb"]     = { Icon = "rbxassetid://6031265970", Display = "Light Bulb" },
	["MetalBlock"]    = { Icon = "rbxassetid://6031280882", Display = "Metal Block" },
	["Motor"]         = { Icon = "rbxassetid://6031260781", Display = "Motor" },
	["Piston"]        = { Icon = "rbxassetid://6031097225", Display = "Piston" },
	["PlasticBlock"]  = { Icon = "rbxassetid://6031265976", Display = "Plastic Block" },
	["Portal"]        = { Icon = "rbxassetid://6031265970", Display = "Portal" },
	["Rope"]          = { Icon = "rbxassetid://6031097225", Display = "Rope" },
	["Servo"]         = { Icon = "rbxassetid://6031260781", Display = "Servo" },
	["Switch"]        = { Icon = "rbxassetid://6031097225", Display = "Switch" },
	["Thruster"]      = { Icon = "rbxassetid://6031260781", Display = "Thruster" },
	["UltraThruster"] = { Icon = "rbxassetid://6031260781", Display = "Ultra Thruster" },
	["WoodBlock"]     = { Icon = "rbxassetid://6031265976", Display = "Wood Block" },
}

local EmbeddedSampleJSON = [[{"AutoBuild_Version":"v1","Data":{"BackWheel":[{"Anchored":false,"CFrame":[-2.0299,811.6921,-131.1107,1,-0.0007,0.0012,0.0007,1,-0.001,-0.0012,0.001,1],"CanCollide":false,"CastShadow":true,"Color":"282828","ID":477,"MValues":{"Health":10,"MaxSpeed":4},"Size":[2,2,2],"Transparency":1}],"CarSeat":[{"Anchored":true,"CFrame":[6,805.1,-121.25,-1,0,0,0,1,0,0,0,-1],"CanCollide":false,"CastShadow":true,"Color":"1b2a35","ID":470,"MValues":{"ControllerId":6,"Health":4},"Size":[3,5,3],"Transparency":0}],"ConcreteBlock":[{"Anchored":true,"CFrame":[2.1,803.2,1.6,1,0,0,0,1,0,0,0,1],"CanCollide":true,"CastShadow":false,"Color":"a3a2a5","ID":1027,"MValues":{"Health":5},"Size":[246.2,0.2,276],"Transparency":0}],"MetalBlock":[{"Anchored":true,"CFrame":[-32,867.1,-34,-1,0,0,0,1,0,0,0,-1],"CanCollide":true,"CastShadow":false,"Color":"635f62","ID":222,"MValues":{"Health":4},"Size":[8,42,8],"Transparency":0}],"PlasticBlock":[{"Anchored":true,"CFrame":[6.7042,805.6581,-118.2508,-1,0,0,0,1,0,0,0,-1],"CanCollide":false,"CastShadow":true,"Color":"111111","ID":1,"MValues":{"Health":1},"Size":[0.127,0.05,0.077],"Transparency":0}],"Thruster":[{"Anchored":true,"CFrame":[13.5542,810.6222,-112.3338,0,-1,0,0,0,1,-1,0,0],"CanCollide":false,"CastShadow":true,"Color":"282828","ID":455,"MValues":{"Fuel":10,"Health":10,"LastGlobalTick":0,"MassMuiltiplier":1},"Size":[4.0296,4.0694,4.1582],"Transparency":1}],"UltraThruster":[{"Anchored":true,"CFrame":[13.5543,810.4384,-112.3388,-1,0,-0,0,0,-1,0,-1,-0],"CanCollide":false,"CastShadow":true,"Color":"282828","ID":451,"MValues":{"Fuel":40,"Health":20,"LastGlobalTick":0,"MassMuiltiplier":1.5},"Size":[4.0296,4.0694,4.1582],"Transparency":1}],"WoodBlock":[{"Anchored":false,"CFrame":[6.1213,802.4586,-120.3175,-0.0001,0,-1,-0.001,-1,0,-1,0.001,0.0001],"CanCollide":false,"CastShadow":true,"Color":"e29b40","ID":414,"MValues":{"Health":1},"Size":[0.7996,9.3513,2],"Transparency":1}]}}]]

-- ============================================================================
-- PARSER (.build v1)
-- ============================================================================
export type ParsedBlock = {
	BlockType: string,
	ID: number,
	CF: CFrame,
	Size: Vector3,
	Color: Color3,
	Anchored: boolean,
	CanCollide: boolean,
}

export type ParsedBuildFile = {
	FileName: string,
	Version: string,
	TotalBlocks: number,
	Requirements: { [string]: number },
	Queue: { ParsedBlock },
	CenterCF: CFrame,
}

local LoadedBuilds: { [string]: ParsedBuildFile } = {}

local function hexToColor3(hex: string): Color3
	local clean = string.gsub(hex, "#", "")
	if #clean ~= 6 then return Color3.fromRGB(255, 255, 255) end
	return Color3.fromRGB(
		tonumber(string.sub(clean, 1, 2), 16) or 255,
		tonumber(string.sub(clean, 3, 4), 16) or 255,
		tonumber(string.sub(clean, 5, 6), 16) or 255
	)
end

local function arrayToCFrame(arr: { number }): CFrame
	if #arr >= 12 then
		return CFrame.new(
			arr[1], arr[2], arr[3],
			arr[4], arr[5], arr[6],
			arr[7], arr[8], arr[9],
			arr[10], arr[11], arr[12]
		)
	elseif #arr >= 3 then
		return CFrame.new(arr[1], arr[2], arr[3])
	end
	return CFrame.new()
end

local function parseBuildJSON(fileName: string, rawJson: string): ParsedBuildFile?
	local ok, decoded = pcall(function() return HttpService:JSONDecode(rawJson) end)
	if not ok or type(decoded) ~= "table" or type(decoded.Data) ~= "table" then return nil end

	local requirements: { [string]: number } = {}
	local queue: { ParsedBlock } = {}
	local sumPos = Vector3.zero
	local totalCount = 0

	for blockType, instances in pairs(decoded.Data) do
		if type(instances) == "table" then
			requirements[blockType] = (requirements[blockType] or 0) + #instances
			for _, item in ipairs(instances) do
				local cf = arrayToCFrame(item.CFrame or {})
				local sz = item.Size or { 2, 2, 2 }
				totalCount += 1
				sumPos += cf.Position
				table.insert(queue, {
					BlockType = blockType,
					ID = tonumber(item.ID) or totalCount,
					CF = cf,
					Size = Vector3.new(sz[1] or 2, sz[2] or 2, sz[3] or 2),
					Color = hexToColor3(tostring(item.Color or "ffffff")),
					Anchored = (item.Anchored ~= false),
					CanCollide = (item.CanCollide == true),
				})
			end
		end
	end

	table.sort(queue, function(a, b) return a.ID < b.ID end)
	local centerPos = totalCount > 0 and (sumPos / totalCount) or Vector3.zero

	return {
		FileName = fileName,
		Version = tostring(decoded.AutoBuild_Version or "v1"),
		TotalBlocks = totalCount,
		Requirements = requirements,
		Queue = queue,
		CenterCF = CFrame.new(centerPos),
	}
end

local function scanWorkspaceBuildFiles(): { string }
	table.clear(LoadedBuilds)
	local names: { string } = {}

	local listfilesFn = (getfenv() :: any).listfiles
	local readfileFn = (getfenv() :: any).readfile

	if type(listfilesFn) == "function" and type(readfileFn) == "function" then
		local ok, files = pcall(listfilesFn, "")
		if ok and type(files) == "table" then
			for _, path in ipairs(files) do
				if string.sub(string.lower(path), -6) == ".build" then
					local cleanName = string.match(path, "([^/\\]+)$") or path
					local rOk, content = pcall(readfileFn, path)
					if rOk and type(content) == "string" then
						local parsed = parseBuildJSON(cleanName, content)
						if parsed then
							LoadedBuilds[cleanName] = parsed
							table.insert(names, cleanName)
						end
					end
				end
			end
		end
	end

	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("StringValue") and string.sub(string.lower(obj.Name), -6) == ".build" then
			if not LoadedBuilds[obj.Name] then
				local parsed = parseBuildJSON(obj.Name, obj.Value)
				if parsed then
					LoadedBuilds[obj.Name] = parsed
					table.insert(names, obj.Name)
				end
			end
		end
	end

	if #names == 0 then
		local demo = "air_75.Build"
		local parsed = parseBuildJSON(demo, EmbeddedSampleJSON)
		if parsed then
			LoadedBuilds[demo] = parsed
			table.insert(names, demo)
		end
	end

	table.sort(names)
	if Config.SelectedFile == "" or not LoadedBuilds[Config.SelectedFile] then
		Config.SelectedFile = names[1] or ""
	end
	return names
end

-- ============================================================================
-- GOLD TELEMETRY & INVENTORY HELPERS
-- ============================================================================
local function readPlayerGold(): number
	local dataFolder = LocalPlayer:FindFirstChild("Data")
	if dataFolder then
		local g = dataFolder:FindFirstChild("Gold")
		if g and (g:IsA("IntValue") or g:IsA("NumberValue")) then
			return g.Value
		end
	end
	local ls = LocalPlayer:FindFirstChild("leaderstats")
	if ls then
		local g = ls:FindFirstChild("Gold")
		if g and (g:IsA("IntValue") or g:IsA("NumberValue")) then
			return g.Value
		end
	end
	return 0
end

local GoldTracker = {
	StartTime = os.clock(),
	InitialGold = readPlayerGold(),
	CurrentGold = readPlayerGold(),
	SessionGained = 0,
	HourlyRate = 0,
}

local function formatNumber(n: number): string
	local s = tostring(math.floor(n))
	return (string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2"):gsub("(%d)(%d%d%d)$", "%1,%2"))
end

local function updateGoldTelemetry()
	local nowGold = readPlayerGold()
	if nowGold > GoldTracker.CurrentGold then
		GoldTracker.SessionGained += (nowGold - GoldTracker.CurrentGold)
	end
	GoldTracker.CurrentGold = nowGold

	local elapsedHours = math.max((os.clock() - GoldTracker.StartTime) / 3600, 1 / 3600)
	GoldTracker.HourlyRate = math.floor(GoldTracker.SessionGained / elapsedHours)
end

local function getOwnedBlockCount(blockType: string): number
	local dataFolder = LocalPlayer:FindFirstChild("Data") or LocalPlayer:FindFirstChild("Inventory")
	if dataFolder then
		local valObj = dataFolder:FindFirstChild(blockType)
		if valObj and (valObj:IsA("IntValue") or valObj:IsA("NumberValue")) then
			return valObj.Value
		end
	end
	return 0
end

local function getTeamZoneOrigin(): CFrame
	local team = LocalPlayer.Team
	if team then
		local zone = Workspace:FindFirstChild(team.Name .. "Zone") or Workspace:FindFirstChild(team.Name)
		if zone and zone:IsA("BasePart") then return zone.CFrame
		elseif zone and zone:IsA("Model") and zone.PrimaryPart then return zone.PrimaryPart.CFrame end
	end
	return CFrame.new(0, 800, 0)
end

local function deployBlock(block: ParsedBlock, targetCF: CFrame)
	local placeRemote = ReplicatedStorage:FindFirstChild("PlaceBlock", true)
	if placeRemote and placeRemote:IsA("RemoteFunction") then
		pcall(function() placeRemote:InvokeServer(block.BlockType, targetCF, block.Anchored, block.CanCollide) end)
	elseif placeRemote and placeRemote:IsA("RemoteEvent") then
		placeRemote:FireServer(block.BlockType, targetCF, block.Anchored, block.CanCollide)
	end
end

-- ============================================================================
-- UNIVERSAL DRAG HELPER (PC MOUSE + MOBILE TOUCH)
-- ============================================================================
local function makeDraggable(handle: GuiObject, target: GuiObject)
	local dragging = false
	local dragInput: InputObject? = nil
	local dragStart = Vector3.zero
	local startPos = UDim2.new()

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- ============================================================================
-- UI ROOT & THEME ENGINE
-- ============================================================================
local oldGui = PlayerGui:FindFirstChild("c4_BABFT_Hub")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "c4_BABFT_Hub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Реестр объектов для динамической перекраски при смене темы
local ThemedObjects: { { Obj: Instance, Prop: string, Key: string } } = {}
local function bindTheme(obj: Instance, prop: string, key: string)
	table.insert(ThemedObjects, { Obj = obj, Prop = prop, Key = key })
	local pal = getPalette()
	;(obj :: any)[prop] = (pal :: any)[key]
end

local function applyThemeAll()
	local pal = getPalette()
	for _, entry in ipairs(ThemedObjects) do
		if entry.Obj and entry.Obj.Parent then
			;(entry.Obj :: any)[entry.Prop] = (pal :: any)[entry.Key]
		end
	end
end

-- ============================================================================
-- FLOATING MINIMIZED PILL (СВЕРНУТЫЙ ВИДЖЕТ)
-- ============================================================================
local MiniPill = Instance.new("TextButton")
MiniPill.Size = UDim2.fromOffset(150, 38)
MiniPill.Position = UDim2.new(0.5, -75, 0.06, 0)
MiniPill.Text = "[c4] BABFT  ▴"
MiniPill.Font = Enum.Font.GothamBold
MiniPill.TextSize = 13
MiniPill.Visible = false
MiniPill.AutoButtonColor = false
MiniPill.Parent = ScreenGui
Instance.new("UICorner", MiniPill).CornerRadius = UDim.new(1, 0)
bindTheme(MiniPill, "BackgroundColor3", "Panel")
bindTheme(MiniPill, "TextColor3", "Text")

local MiniStroke = Instance.new("UIStroke")
MiniStroke.Thickness = 1.5
MiniStroke.Parent = MiniPill
bindTheme(MiniStroke, "Color", "Accent")

makeDraggable(MiniPill, MiniPill)

-- ============================================================================
-- MAIN WINDOW
-- ============================================================================
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.fromOffset(720, 450)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false -- Показывается после стартовой настройки
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
bindTheme(MainFrame, "BackgroundColor3", "Bg")

local MainScale = Instance.new("UIScale")
MainScale.Scale = 1
MainScale.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame
bindTheme(MainStroke, "Color", "Stroke")

-- TopBar (Перетаскивание + Сворачивание)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 42)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)
bindTheme(TopBar, "BackgroundColor3", "Panel")

makeDraggable(TopBar, MainFrame)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -110, 1, 0)
TitleLabel.Position = UDim2.fromOffset(16, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "[c4] BABFT // STUDIO & RESET FARM"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar
bindTheme(TitleLabel, "TextColor3", "Text")

-- Кнопка сворачивания (—)
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.fromOffset(32, 28)
MinimizeBtn.Position = UDim2.new(1, -42, 0.5, -14)
MinimizeBtn.Text = "—"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 14
MinimizeBtn.Parent = TopBar
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 6)
bindTheme(MinimizeBtn, "BackgroundColor3", "Card")
bindTheme(MinimizeBtn, "TextColor3", "Text")

MinimizeBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
	MiniPill.Visible = true
end)

MiniPill.MouseButton1Click:Connect(function()
	MiniPill.Visible = false
	MainFrame.Visible = true
end)

-- Сайдбар
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 165, 1, -54)
Sidebar.Position = UDim2.fromOffset(10, 48)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)
bindTheme(Sidebar, "BackgroundColor3", "Panel")

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 6)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Parent = Sidebar

local SidePad = Instance.new("UIPadding")
SidePad.PaddingTop = UDim.new(0, 10)
SidePad.Parent = Sidebar

local PagesFolder = Instance.new("Frame")
PagesFolder.Size = UDim2.new(1, -190, 1, -54)
PagesFolder.Position = UDim2.fromOffset(182, 48)
PagesFolder.BackgroundTransparency = 1
PagesFolder.Parent = MainFrame

local Pages: { [string]: ScrollingFrame } = {}
local TabButtons: { [string]: TextButton } = {}
local ActiveTabKey = "Farm"

local function updateTabStyles()
	local pal = getPalette()
	for k, btn in pairs(TabButtons) do
		local isAct = (k == ActiveTabKey)
		btn.BackgroundColor3 = isAct and pal.Accent or pal.Card
		btn.TextColor3 = isAct and pal.AccentText or pal.SubText
	end
end

local function switchTab(key: string)
	ActiveTabKey = key
	for k, p in pairs(Pages) do p.Visible = (k == key) end
	updateTabStyles()
end

local function createTab(key: string, order: number): ScrollingFrame
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -16, 0, 36)
	btn.LayoutOrder = order
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 13
	btn.AutoButtonColor = false
	btn.Parent = Sidebar
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	local page = Instance.new("ScrollingFrame")
	page.Size = UDim2.fromScale(1, 1)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 4
	page.Visible = false
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.Parent = PagesFolder
	bindTheme(page, "ScrollBarImageColor3", "Accent")

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = page

	local pad = Instance.new("UIPadding")
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.Parent = page

	btn.MouseButton1Click:Connect(function() switchTab(key) end)
	Pages[key] = page
	TabButtons[key] = btn
	return page
end

local PageFarm = createTab("Farm", 1)
local PageBuild = createTab("Build", 2)
local PageWorkshop = createTab("Workshop", 3)
local PageSettings = createTab("Settings", 4)

-- ============================================================================
-- TAB 1: AUTO FARM (МЕТОД РЕСЕТА + СТАТИСТИКА: ЕСТЬ / СОБРАНО / В ЧАС)
-- ============================================================================
local StatsGrid = Instance.new("Frame")
StatsGrid.Size = UDim2.new(1, 0, 0, 74)
StatsGrid.BackgroundTransparency = 1
StatsGrid.LayoutOrder = 1
StatsGrid.Parent = PageFarm

local StatsLayout = Instance.new("UIListLayout")
StatsLayout.FillDirection = Enum.FillDirection.Horizontal
StatsLayout.Padding = UDim.new(0, 8)
StatsLayout.Parent = StatsGrid

local function createStatBox(order: number): (TextLabel, TextLabel)
	local box = Instance.new("Frame")
	box.Size = UDim2.new(0.333, -6, 1, 0)
	box.LayoutOrder = order
	box.Parent = StatsGrid
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
	bindTheme(box, "BackgroundColor3", "Card")

	local st = Instance.new("UIStroke")
	st.Thickness = 1
	st.Parent = box
	bindTheme(st, "Color", "Stroke")

	local caption = Instance.new("TextLabel")
	caption.Size = UDim2.new(1, -16, 0, 20)
	caption.Position = UDim2.fromOffset(10, 10)
	caption.BackgroundTransparency = 1
	caption.Font = Enum.Font.GothamMedium
	caption.TextSize = 12
	caption.TextXAlignment = Enum.TextXAlignment.Left
	caption.Parent = box
	bindTheme(caption, "TextColor3", "SubText")

	local val = Instance.new("TextLabel")
	val.Size = UDim2.new(1, -16, 0, 28)
	val.Position = UDim2.fromOffset(10, 34)
	val.BackgroundTransparency = 1
	val.Text = "0"
	val.Font = Enum.Font.GothamBold
	val.TextSize = 18
	val.TextXAlignment = Enum.TextXAlignment.Left
	val.Parent = box
	bindTheme(val, "TextColor3", "Text")

	return caption, val
end

local CapCurrent, ValCurrent = createStatBox(1)
local CapSession, ValSession = createStatBox(2)
local CapHourly, ValHourly = createStatBox(3)

local FarmCard = Instance.new("Frame")
FarmCard.Size = UDim2.new(1, 0, 0, 128)
FarmCard.LayoutOrder = 2
FarmCard.Parent = PageFarm
Instance.new("UICorner", FarmCard).CornerRadius = UDim.new(0, 8)
bindTheme(FarmCard, "BackgroundColor3", "Card")

local FarmCardStroke = Instance.new("UIStroke")
FarmCardStroke.Thickness = 1
FarmCardStroke.Parent = FarmCard
bindTheme(FarmCardStroke, "Color", "Stroke")

local FarmHeader = Instance.new("TextLabel")
FarmHeader.Size = UDim2.new(1, -24, 0, 24)
FarmHeader.Position = UDim2.fromOffset(12, 10)
FarmHeader.BackgroundTransparency = 1
FarmHeader.Font = Enum.Font.GothamBold
FarmHeader.TextSize = 14
FarmHeader.TextXAlignment = Enum.TextXAlignment.Left
FarmHeader.Parent = FarmCard
bindTheme(FarmHeader, "TextColor3", "Text")

local FarmStatus = Instance.new("TextLabel")
FarmStatus.Size = UDim2.new(1, -24, 0, 20)
FarmStatus.Position = UDim2.fromOffset(12, 36)
FarmStatus.BackgroundTransparency = 1
FarmStatus.Font = Enum.Font.Gotham
FarmStatus.TextSize = 12
FarmStatus.TextXAlignment = Enum.TextXAlignment.Left
FarmStatus.Parent = FarmCard
bindTheme(FarmStatus, "TextColor3", "SubText")

local FarmToggleBtn = Instance.new("TextButton")
FarmToggleBtn.Size = UDim2.fromOffset(180, 36)
FarmToggleBtn.Position = UDim2.fromOffset(12, 74)
FarmToggleBtn.Font = Enum.Font.GothamBold
FarmToggleBtn.TextSize = 13
FarmToggleBtn.Parent = FarmCard
Instance.new("UICorner", FarmToggleBtn).CornerRadius = UDim.new(0, 6)
bindTheme(FarmToggleBtn, "BackgroundColor3", "Accent")
bindTheme(FarmToggleBtn, "TextColor3", "AccentText")

local ResetStatsBtn = Instance.new("TextButton")
ResetStatsBtn.Size = UDim2.fromOffset(150, 36)
ResetStatsBtn.Position = UDim2.fromOffset(202, 74)
ResetStatsBtn.Font = Enum.Font.GothamSemibold
ResetStatsBtn.TextSize = 12
ResetStatsBtn.Parent = FarmCard
Instance.new("UICorner", ResetStatsBtn).CornerRadius = UDim.new(0, 6)
bindTheme(ResetStatsBtn, "BackgroundColor3", "Panel")
bindTheme(ResetStatsBtn, "TextColor3", "Text")

local function refreshGoldLabels()
	updateGoldTelemetry()
	ValCurrent.Text = formatNumber(GoldTracker.CurrentGold)
	ValSession.Text = "+" .. formatNumber(GoldTracker.SessionGained)
	ValHourly.Text = formatNumber(GoldTracker.HourlyRate) .. " / h"
end

ResetStatsBtn.MouseButton1Click:Connect(function()
	GoldTracker.StartTime = os.clock()
	GoldTracker.SessionGained = 0
	GoldTracker.HourlyRate = 0
	GoldTracker.CurrentGold = readPlayerGold()
	refreshGoldLabels()
end)

-- Цикл фарма методом быстрого прохода этапов + мгновенного ресета (выдает золото частями каждую секунду)
local function runResetFarmCycle()
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
	if not hrp or not hum or hum.Health <= 0 then return end

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bv.Velocity = Vector3.zero
	bv.Parent = hrp

	local boatStages = Workspace:FindFirstChild("BoatStages")
	local normalStages = boatStages and boatStages:FindFirstChild("NormalStages")
	local claimRemote = Workspace:FindFirstChild("ClaimRiverResultsGold", true)

	-- Быстрый проход через триггеры этапов (по ~0.16с на этап -> порции по 10-20 золота в сек)
	for stage = 1, 10 do
		if not Config.AutoFarmActive or not hrp.Parent or hum.Health <= 0 then break end
		FarmStatus.Text = string.format(tr("FarmStage"), stage)

		local targetCF = CFrame.new(-55, 65, 1000 + (stage * 770))
		if normalStages then
			local cave = normalStages:FindFirstChild("CaveStage" .. tostring(stage))
			local darkness = cave and cave:FindFirstChild("DarknessPart")
			if darkness and darkness:IsA("BasePart") then
				targetCF = darkness.CFrame
			end
		end

		hrp.CFrame = targetCF
		-- Вызов серверного начисления за пройденные стены, если доступно
		if claimRemote and claimRemote:IsA("RemoteEvent") then
			pcall(function() claimRemote:FireServer() end)
		end

		task.wait(0.18)
		refreshGoldLabels()
	end

	-- Касание триггера воды/сундука и быстрый ресет персонажа (без долгого ожидания)
	if Config.AutoFarmActive and hrp.Parent and hum.Health > 0 then
		FarmStatus.Text = tr("FarmReset")
		local theEnd = normalStages and normalStages:FindFirstChild("TheEnd")
		local chest = theEnd and theEnd:FindFirstChild("GoldenChest")
		if chest and chest:FindFirstChild("Trigger") then
			hrp.CFrame = (chest.Trigger :: BasePart).CFrame
		else
			hrp.CFrame = CFrame.new(-55, -350, 9490)
		end

		task.wait(0.25)
		if claimRemote and claimRemote:IsA("RemoteEvent") then
			pcall(function() claimRemote:FireServer() end)
		end

		-- Ресет персонажа для мгновенной выдачи золота и перезапуска цикла
		hum.Health = 0
		LocalPlayer.CharacterAdded:Wait()
		task.wait(0.4)
		refreshGoldLabels()
	end

	if bv and bv.Parent then bv:Destroy() end
end

FarmToggleBtn.MouseButton1Click:Connect(function()
	Config.AutoFarmActive = not Config.AutoFarmActive
	FarmToggleBtn.Text = Config.AutoFarmActive and tr("FarmStop") or tr("FarmStart")
	if Config.AutoFarmActive then
		task.spawn(function()
			while Config.AutoFarmActive do
				runResetFarmCycle()
				task.wait(0.2)
			end
			FarmStatus.Text = tr("FarmIdle")
		end)
	end
end)

-- Фоновое обновление счетчика золота
task.spawn(function()
	while ScreenGui.Parent do
		refreshGoldLabels()
		task.wait(1)
	end
end)

-- ============================================================================
-- TAB 2: AUTO BUILD (.BUILD SELECTOR + ITEM LIST)
-- ============================================================================
local ControlPanel = Instance.new("Frame")
ControlPanel.Size = UDim2.new(1, 0, 0, 142)
ControlPanel.LayoutOrder = 1
ControlPanel.Parent = PageBuild
Instance.new("UICorner", ControlPanel).CornerRadius = UDim.new(0, 8)
bindTheme(ControlPanel, "BackgroundColor3", "Card")

local CtrlStroke = Instance.new("UIStroke")
CtrlStroke.Thickness = 1
CtrlStroke.Parent = ControlPanel
bindTheme(CtrlStroke, "Color", "Stroke")

local FileHeaderLbl = Instance.new("TextLabel")
FileHeaderLbl.Size = UDim2.new(1, -24, 0, 22)
FileHeaderLbl.Position = UDim2.fromOffset(12, 8)
FileHeaderLbl.BackgroundTransparency = 1
FileHeaderLbl.Font = Enum.Font.GothamBold
FileHeaderLbl.TextSize = 14
FileHeaderLbl.TextXAlignment = Enum.TextXAlignment.Left
FileHeaderLbl.Parent = ControlPanel
bindTheme(FileHeaderLbl, "TextColor3", "Text")

local FileMetaLbl = Instance.new("TextLabel")
FileMetaLbl.Size = UDim2.new(1, -24, 0, 18)
FileMetaLbl.Position = UDim2.fromOffset(12, 30)
FileMetaLbl.BackgroundTransparency = 1
FileMetaLbl.Font = Enum.Font.Gotham
FileMetaLbl.TextSize = 12
FileMetaLbl.TextXAlignment = Enum.TextXAlignment.Left
FileMetaLbl.Parent = ControlPanel
bindTheme(FileMetaLbl, "TextColor3", "SubText")

local FileDropdownBtn = Instance.new("TextButton")
FileDropdownBtn.Size = UDim2.fromOffset(230, 32)
FileDropdownBtn.Position = UDim2.fromOffset(12, 56)
FileDropdownBtn.Font = Enum.Font.GothamSemibold
FileDropdownBtn.TextSize = 12
FileDropdownBtn.Parent = ControlPanel
Instance.new("UICorner", FileDropdownBtn).CornerRadius = UDim.new(0, 6)
bindTheme(FileDropdownBtn, "BackgroundColor3", "Panel")
bindTheme(FileDropdownBtn, "TextColor3", "Text")

local RescanBtn = Instance.new("TextButton")
RescanBtn.Size = UDim2.fromOffset(125, 32)
RescanBtn.Position = UDim2.fromOffset(250, 56)
RescanBtn.Font = Enum.Font.GothamSemibold
RescanBtn.TextSize = 12
RescanBtn.Parent = ControlPanel
Instance.new("UICorner", RescanBtn).CornerRadius = UDim.new(0, 6)
bindTheme(RescanBtn, "BackgroundColor3", "Panel")
bindTheme(RescanBtn, "TextColor3", "Text")

local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.fromOffset(125, 32)
ModeBtn.Position = UDim2.fromOffset(383, 56)
ModeBtn.Font = Enum.Font.GothamSemibold
ModeBtn.TextSize = 12
ModeBtn.Parent = ControlPanel
Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 6)
bindTheme(ModeBtn, "BackgroundColor3", "Panel")
bindTheme(ModeBtn, "TextColor3", "Text")

ModeBtn.MouseButton1Click:Connect(function()
	Config.UseRelativeOrigin = not Config.UseRelativeOrigin
	ModeBtn.Text = Config.UseRelativeOrigin and tr("CoordPlot") or tr("CoordWorld")
end)

local StartBuildBtn = Instance.new("TextButton")
StartBuildBtn.Size = UDim2.fromOffset(175, 34)
StartBuildBtn.Position = UDim2.fromOffset(12, 96)
StartBuildBtn.Font = Enum.Font.GothamBold
StartBuildBtn.TextSize = 13
StartBuildBtn.Parent = ControlPanel
Instance.new("UICorner", StartBuildBtn).CornerRadius = UDim.new(0, 6)
bindTheme(StartBuildBtn, "BackgroundColor3", "Accent")
bindTheme(StartBuildBtn, "TextColor3", "AccentText")

local BuildProgressLbl = Instance.new("TextLabel")
BuildProgressLbl.Size = UDim2.new(1, -210, 0, 34)
BuildProgressLbl.Position = UDim2.fromOffset(198, 96)
BuildProgressLbl.BackgroundTransparency = 1
BuildProgressLbl.Font = Enum.Font.GothamMedium
BuildProgressLbl.TextSize = 12
BuildProgressLbl.TextXAlignment = Enum.TextXAlignment.Left
BuildProgressLbl.Parent = ControlPanel
bindTheme(BuildProgressLbl, "TextColor3", "SubText")

local DropdownContainer = Instance.new("Frame")
DropdownContainer.Size = UDim2.new(1, 0, 0, 0)
DropdownContainer.AutomaticSize = Enum.AutomaticSize.Y
DropdownContainer.Visible = false
DropdownContainer.LayoutOrder = 2
DropdownContainer.Parent = PageBuild
Instance.new("UICorner", DropdownContainer).CornerRadius = UDim.new(0, 8)
bindTheme(DropdownContainer, "BackgroundColor3", "Panel")

local DropLayout = Instance.new("UIListLayout")
DropLayout.Padding = UDim.new(0, 4)
DropLayout.Parent = DropdownContainer

local DropPad = Instance.new("UIPadding")
DropPad.PaddingTop = UDim.new(0, 6)
DropPad.PaddingBottom = UDim.new(0, 6)
DropPad.PaddingLeft = UDim.new(0, 6)
DropPad.PaddingRight = UDim.new(0, 6)
DropPad.Parent = DropdownContainer

FileDropdownBtn.MouseButton1Click:Connect(function()
	DropdownContainer.Visible = not DropdownContainer.Visible
end)

local ItemListContainer = Instance.new("Frame")
ItemListContainer.Size = UDim2.new(1, 0, 0, 0)
ItemListContainer.AutomaticSize = Enum.AutomaticSize.Y
ItemListContainer.BackgroundTransparency = 1
ItemListContainer.LayoutOrder = 3
ItemListContainer.Parent = PageBuild

local ItemListLayout = Instance.new("UIListLayout")
ItemListLayout.Padding = UDim.new(0, 6)
ItemListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ItemListLayout.Parent = ItemListContainer

local function refreshUIForSelectedBuild()
	for _, ch in ipairs(ItemListContainer:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
	end

	local pal = getPalette()
	local buildData = LoadedBuilds[Config.SelectedFile]
	if not buildData then
		FileHeaderLbl.Text = tr("FileNone")
		FileMetaLbl.Text = ""
		FileDropdownBtn.Text = tr("SelectFileBtn")
		return
	end

	local typeCount = 0
	for _ in pairs(buildData.Requirements) do typeCount += 1 end

	FileHeaderLbl.Text = tr("FileSelected") .. buildData.FileName
	FileMetaLbl.Text = string.format(tr("MetaFormat"), buildData.Version, buildData.TotalBlocks, typeCount)
	FileDropdownBtn.Text = buildData.FileName .. " ▾"

	local sortedTypes: { string } = {}
	for bType in pairs(buildData.Requirements) do table.insert(sortedTypes, bType) end
	table.sort(sortedTypes, function(a, b) return buildData.Requirements[a] > buildData.Requirements[b] end)

	for idx, blockType in ipairs(sortedTypes) do
		local totalNeeded = buildData.Requirements[blockType]
		local owned = getOwnedBlockCount(blockType)
		local stillNeeded = math.max(0, totalNeeded - owned)
		local isEnough = (stillNeeded == 0)

		local meta = BlockMeta[blockType] or { Icon = "rbxassetid://6031265976", Display = blockType }

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 56)
		row.LayoutOrder = idx
		row.BackgroundColor3 = pal.Card
		row.Parent = ItemListContainer
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

		local st = Instance.new("UIStroke")
		st.Color = isEnough and pal.Good or pal.Stroke
		st.Thickness = 1
		st.Parent = row

		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.fromOffset(40, 40)
		icon.Position = UDim2.fromOffset(8, 8)
		icon.BackgroundColor3 = pal.Bg
		icon.Image = meta.Icon
		icon.Parent = row
		Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 6)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -65, 0, 20)
		title.Position = UDim2.fromOffset(58, 7)
		title.BackgroundTransparency = 1
		title.Text = meta.Display .. "  (" .. blockType .. ")"
		title.TextColor3 = pal.Text
		title.Font = Enum.Font.GothamBold
		title.TextSize = 13
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = row

		local counts = Instance.new("TextLabel")
		counts.Size = UDim2.new(1, -65, 0, 20)
		counts.Position = UDim2.fromOffset(58, 28)
		counts.BackgroundTransparency = 1
		counts.Text = string.format(tr("ItemStatsFormat"), owned, stillNeeded, totalNeeded)
		counts.TextColor3 = isEnough and pal.Good or pal.SubText
		counts.Font = Enum.Font.GothamMedium
		counts.TextSize = 12
		counts.TextXAlignment = Enum.TextXAlignment.Left
		counts.Parent = row
	end
end

local function rebuildFileBrowserAndDropdown()
	local fileNames = scanWorkspaceBuildFiles()
	local pal = getPalette()

	for _, ch in ipairs(DropdownContainer:GetChildren()) do
		if ch:IsA("TextButton") then ch:Destroy() end
	end
	for _, ch in ipairs(PageWorkshop:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
	end

	for _, fName in ipairs(fileNames) do
		local bData = LoadedBuilds[fName]
		if not bData then continue end

		local dropItem = Instance.new("TextButton")
		dropItem.Size = UDim2.new(1, 0, 0, 28)
		dropItem.BackgroundColor3 = pal.Card
		dropItem.Text = string.format("%s  (%d, %s)", fName, bData.TotalBlocks, bData.Version)
		dropItem.TextColor3 = pal.Text
		dropItem.Font = Enum.Font.GothamMedium
		dropItem.TextSize = 12
		dropItem.Parent = DropdownContainer
		Instance.new("UICorner", dropItem).CornerRadius = UDim.new(0, 5)

		dropItem.MouseButton1Click:Connect(function()
			Config.SelectedFile = fName
			DropdownContainer.Visible = false
			refreshUIForSelectedBuild()
		end)

		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 74)
		card.BackgroundColor3 = pal.Card
		card.Parent = PageWorkshop
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = pal.Stroke
		cStroke.Thickness = 1
		cStroke.Parent = card

		local cTitle = Instance.new("TextLabel")
		cTitle.Size = UDim2.new(1, -145, 0, 22)
		cTitle.Position = UDim2.fromOffset(12, 10)
		cTitle.BackgroundTransparency = 1
		cTitle.Text = bData.FileName
		cTitle.TextColor3 = pal.Text
		cTitle.Font = Enum.Font.GothamBold
		cTitle.TextSize = 14
		cTitle.TextXAlignment = Enum.TextXAlignment.Left
		cTitle.Parent = card

		local cSub = Instance.new("TextLabel")
		cSub.Size = UDim2.new(1, -145, 0, 26)
		cSub.Position = UDim2.fromOffset(12, 34)
		cSub.BackgroundTransparency = 1
		cSub.Text = string.format("%s  •  %d blocks", bData.Version, bData.TotalBlocks)
		cSub.TextColor3 = pal.SubText
		cSub.Font = Enum.Font.Gotham
		cSub.TextSize = 12
		cSub.TextXAlignment = Enum.TextXAlignment.Left
		cSub.Parent = card

		local loadBtn = Instance.new("TextButton")
		loadBtn.Size = UDim2.fromOffset(110, 32)
		loadBtn.Position = UDim2.new(1, -122, 0.5, -16)
		loadBtn.BackgroundColor3 = pal.Accent
		loadBtn.Text = tr("SelectPreset")
		loadBtn.TextColor3 = pal.AccentText
		loadBtn.Font = Enum.Font.GothamBold
		loadBtn.TextSize = 12
		loadBtn.Parent = card
		Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 6)

		loadBtn.MouseButton1Click:Connect(function()
			Config.SelectedFile = fName
			refreshUIForSelectedBuild()
			switchTab("Build")
		end)
	end

	refreshUIForSelectedBuild()
end

RescanBtn.MouseButton1Click:Connect(rebuildFileBrowserAndDropdown)

StartBuildBtn.MouseButton1Click:Connect(function()
	if Config.AutoBuildActive then
		Config.AutoBuildActive = false
		StartBuildBtn.Text = tr("BuildStart")
		return
	end

	local buildData = LoadedBuilds[Config.SelectedFile]
	if not buildData then return end

	Config.AutoBuildActive = true
	StartBuildBtn.Text = tr("BuildStop")

	task.spawn(function()
		local plotOrigin = getTeamZoneOrigin()
		local total = #buildData.Queue

		for i, blk in ipairs(buildData.Queue) do
			if not Config.AutoBuildActive then break end
			local finalCF = blk.CF
			if Config.UseRelativeOrigin then
				finalCF = plotOrigin * buildData.CenterCF:ToObjectSpace(blk.CF)
			end
			BuildProgressLbl.Text = string.format(tr("BuildProgress"), i, total, blk.BlockType)
			deployBlock(blk, finalCF)
			task.wait(Config.BuildDelay)
		end

		Config.AutoBuildActive = false
		StartBuildBtn.Text = tr("BuildStart")
		BuildProgressLbl.Text = tr("BuildDone")
		refreshUIForSelectedBuild()
	end)
end)

-- ============================================================================
-- LOCALIZATION & PLATFORM REFRESH FUNCTION
-- ============================================================================
local function applyConfigChanges()
	-- Масштаб под PC или Mobile
	MainScale.Scale = (Config.Platform == "Mobile") and 0.82 or 1.0

	-- Локализация всех текстов
	TabButtons["Farm"].Text = tr("TabFarm")
	TabButtons["Build"].Text = tr("TabBuild")
	TabButtons["Workshop"].Text = tr("TabWorkshop")
	TabButtons["Settings"].Text = tr("TabSettings")

	CapCurrent.Text = tr("StatCurrent")
	CapSession.Text = tr("StatSession")
	CapHourly.Text = tr("StatHourly")
	FarmHeader.Text = tr("FarmTitle")
	if not Config.AutoFarmActive then FarmStatus.Text = tr("FarmIdle") end
	FarmToggleBtn.Text = Config.AutoFarmActive and tr("FarmStop") or tr("FarmStart")
	ResetStatsBtn.Text = tr("ResetStats")

	RescanBtn.Text = tr("RescanBtn")
	ModeBtn.Text = Config.UseRelativeOrigin and tr("CoordPlot") or tr("CoordWorld")
	StartBuildBtn.Text = Config.AutoBuildActive and tr("BuildStop") or tr("BuildStart")
	if not Config.AutoBuildActive then BuildProgressLbl.Text = tr("BuildReady") end

	applyThemeAll()
	updateTabStyles()
	rebuildFileBrowserAndDropdown()
end

-- ============================================================================
-- TAB 4: SETTINGS & INITIAL SETUP MODAL (PC/MOBILE, RU/EN, THEME)
-- ============================================================================
local function createSelectorCard(parent: Instance, labelKey: string, options: { string }, getCurrent: () -> string, onSelect: (string) -> ())
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 68)
	card.Parent = parent
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
	bindTheme(card, "BackgroundColor3", "Card")

	local st = Instance.new("UIStroke")
	st.Thickness = 1
	st.Parent = card
	bindTheme(st, "Color", "Stroke")

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -20, 0, 20)
	lbl.Position = UDim2.fromOffset(12, 6)
	lbl.BackgroundTransparency = 1
	lbl.Text = tr(labelKey)
	lbl.Font = Enum.Font.GothamSemibold
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = card
	bindTheme(lbl, "TextColor3", "SubText")

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -24, 0, 30)
	row.Position = UDim2.fromOffset(12, 30)
	row.BackgroundTransparency = 1
	row.Parent = card

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.Parent = row

	local btns: { [string]: TextButton } = {}
	local function refreshBtns()
		local pal = getPalette()
		lbl.Text = tr(labelKey)
		for val, b in pairs(btns) do
			local active = (getCurrent() == val)
			b.BackgroundColor3 = active and pal.Accent or pal.Panel
			b.TextColor3 = active and pal.AccentText or pal.Text
		end
	end

	for _, opt in ipairs(options) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1 / #options, -6, 1, 0)
		b.Text = opt
		b.Font = Enum.Font.GothamBold
		b.TextSize = 12
		b.Parent = row
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
		btns[opt] = b

		b.MouseButton1Click:Connect(function()
			onSelect(opt)
			refreshBtns()
		end)
	end

	refreshBtns()
	return refreshBtns
end

-- Наполняем вкладку Settings
createSelectorCard(PageSettings, "PlatformLbl", { "PC", "Mobile" }, function() return Config.Platform end, function(v)
	Config.Platform = v
	applyConfigChanges()
end)
createSelectorCard(PageSettings, "LangLbl", { "RU", "EN" }, function() return Config.Language end, function(v)
	Config.Language = v
	applyConfigChanges()
end)
createSelectorCard(PageSettings, "ThemeLbl", { "Monochrome", "Midnight", "Crimson" }, function() return Config.Theme end, function(v)
	Config.Theme = v
	applyConfigChanges()
end)

-- Стартовое окно настройки (Setup Modal)
local SetupModal = Instance.new("Frame")
SetupModal.Size = UDim2.fromOffset(420, 320)
SetupModal.Position = UDim2.fromScale(0.5, 0.5)
SetupModal.AnchorPoint = Vector2.new(0.5, 0.5)
SetupModal.BorderSizePixel = 0
SetupModal.Parent = ScreenGui
Instance.new("UICorner", SetupModal).CornerRadius = UDim.new(0, 10)
bindTheme(SetupModal, "BackgroundColor3", "Bg")

local SetupStroke = Instance.new("UIStroke")
SetupStroke.Thickness = 1.5
SetupStroke.Parent = SetupModal
bindTheme(SetupStroke, "Color", "Accent")

makeDraggable(SetupModal, SetupModal)

local SetupHeader = Instance.new("TextLabel")
SetupHeader.Size = UDim2.new(1, -24, 0, 36)
SetupHeader.Position = UDim2.fromOffset(12, 6)
SetupHeader.BackgroundTransparency = 1
SetupHeader.Text = "[c4] " .. tr("SetupTitle")
SetupHeader.Font = Enum.Font.GothamBold
SetupHeader.TextSize = 15
SetupHeader.Parent = SetupModal
bindTheme(SetupHeader, "TextColor3", "Text")

local SetupList = Instance.new("Frame")
SetupList.Size = UDim2.new(1, -24, 0, 216)
SetupList.Position = UDim2.fromOffset(12, 44)
SetupList.BackgroundTransparency = 1
SetupList.Parent = SetupModal

local SetupListLayout = Instance.new("UIListLayout")
SetupListLayout.Padding = UDim.new(0, 8)
SetupListLayout.Parent = SetupList

local ContinueBtn = Instance.new("TextButton")
ContinueBtn.Size = UDim2.new(1, -24, 0, 38)
ContinueBtn.Position = UDim2.fromOffset(12, 270)
ContinueBtn.Text = tr("StartScript")
ContinueBtn.Font = Enum.Font.GothamBold
ContinueBtn.TextSize = 14
ContinueBtn.Parent = SetupModal
Instance.new("UICorner", ContinueBtn).CornerRadius = UDim.new(0, 6)
bindTheme(ContinueBtn, "BackgroundColor3", "Accent")
bindTheme(ContinueBtn, "TextColor3", "AccentText")

local r1, r2, r3
local function syncSetupModal()
	SetupHeader.Text = "[c4] " .. tr("SetupTitle")
	ContinueBtn.Text = tr("StartScript")
	applyConfigChanges()
	if r1 then r1() end
	if r2 then r2() end
	if r3 then r3() end
end

r1 = createSelectorCard(SetupList, "PlatformLbl", { "PC", "Mobile" }, function() return Config.Platform end, function(v)
	Config.Platform = v
	syncSetupModal()
end)
r2 = createSelectorCard(SetupList, "LangLbl", { "RU", "EN" }, function() return Config.Language end, function(v)
	Config.Language = v
	syncSetupModal()
end)
r3 = createSelectorCard(SetupList, "ThemeLbl", { "Monochrome", "Midnight", "Crimson" }, function() return Config.Theme end, function(v)
	Config.Theme = v
	syncSetupModal()
end)

ContinueBtn.MouseButton1Click:Connect(function()
	SetupModal.Visible = false
	MainFrame.Visible = true
	switchTab("Farm")
	applyConfigChanges()
end)

-- Инициализация при старте
applyConfigChanges()

UserInputService.InputBegan:Connect(function(input, gp)
	if not gp and input.KeyCode == Config.ToggleKey and not SetupModal.Visible then
		if MainFrame.Visible then
			MainFrame.Visible = false
			MiniPill.Visible = true
		else
			MiniPill.Visible = false
			MainFrame.Visible = true
		end
	end
end)
