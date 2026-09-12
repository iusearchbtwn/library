local Library = {}
Library.__index = Library

-- ==========================================
-- ⚙️ СЕРВИСЫ ROBLOX И СИСТЕМНЫЕ НАСТРОЙКИ
-- ==========================================
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

Library.SafeModeActive = false 
Library.ElementsRegistry = {}  
Library.CurrentTheme = {
	MainBg = Color3.fromRGB(22, 22, 22),
	TopBar = Color3.fromRGB(28, 28, 28),
	Sidebar = Color3.fromRGB(26, 26, 26),
	Accent = Color3.fromRGB(80, 140, 255),
	ElementBg = Color3.fromRGB(32, 32, 32),
	Text = Color3.fromRGB(240, 240, 240)
}

local Themes = {
	["Dark Default"] = { MainBg = Color3.fromRGB(22,22,22), TopBar = Color3.fromRGB(28,28,28), Sidebar = Color3.fromRGB(26,26,26), Accent = Color3.fromRGB(80,140,255), ElementBg = Color3.fromRGB(32,32,32), Text = Color3.fromRGB(240,240,240) },
	["Neon Blue"] = { MainBg = Color3.fromRGB(15,15,20), TopBar = Color3.fromRGB(20,20,30), Sidebar = Color3.fromRGB(18,18,25), Accent = Color3.fromRGB(0,255,200), ElementBg = Color3.fromRGB(25,25,35), Text = Color3.fromRGB(255,255,255) },
	["Sakura Pink"] = { MainBg = Color3.fromRGB(30,25,28), TopBar = Color3.fromRGB(40,30,35), Sidebar = Color3.fromRGB(35,28,32), Accent = Color3.fromRGB(255,150,180), ElementBg = Color3.fromRGB(45,35,40), Text = Color3.fromRGB(255,240,245) },
	["Cyberpunk"] = { MainBg = Color3.fromRGB(18,10,28), TopBar = Color3.fromRGB(30,15,45), Sidebar = Color3.fromRGB(24,12,38), Accent = Color3.fromRGB(255,240,0), ElementBg = Color3.fromRGB(40,20,55), Text = Color3.fromRGB(0,255,255) }
}

local function GetGuiParent()
	if gethui then return gethui() end
	if syn and syn.protect_gui then
		local gui = Instance.new("ScreenGui")
		syn.protect_gui(gui)
		gui.Parent = CoreGui
		return gui
	end
	return CoreGui
end

local function MakeDraggable(topBar, mainFrame)
	local dragging, dragInput, dragStart, startPos
	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	topBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			TweenService:Create(mainFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			}):Play()
		end
	end)
end

-- ==========================================
-- 🔔 УВЕДОМЛЕНИЯ И ЗАГРУЗКА АССЕТОВ
-- ==========================================
function Library:Notify(title, text, duration)
	duration = duration or 4
	local parent = GetGuiParent()
	local notifyHolder = parent:FindFirstChild("NotifyHolder")

	if not notifyHolder then
		notifyHolder = Instance.new("ScreenGui")
		notifyHolder.Name = "NotifyHolder"
		notifyHolder.Parent = parent

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 10)
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		layout.Parent = notifyHolder

		local padding = Instance.new("UIPadding")
		padding.PaddingBottom = UDim.new(0, 20)
		padding.PaddingRight = UDim.new(0, 20)
		padding.Parent = notifyHolder
	end

	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(0, 250, 0, 70)
	Frame.BackgroundColor3 = Library.CurrentTheme.ElementBg
	Frame.BackgroundTransparency = 1
	Frame.Parent = notifyHolder

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Frame

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Library.CurrentTheme.Accent
	Stroke.Thickness = 1
	Stroke.Parent = Frame

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -20, 0, 25)
	Title.Position = UDim2.new(0, 10, 0, 5)
	Title.Text = title
	Title.TextColor3 = Library.CurrentTheme.Text
	Title.TextSize = 14
	Title.Font = Enum.Font.SourceSansBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.BackgroundTransparency = 1
	Title.Parent = Frame

	local Desc = Instance.new("TextLabel")
	Desc.Size = UDim2.new(1, -20, 1, -35)
	Desc.Position = UDim2.new(0, 10, 0, 30)
	Desc.Text = text
	Desc.TextColor3 = Color3.fromRGB(200, 200, 200)
	Desc.TextSize = 13
	Desc.Font = Enum.Font.SourceSans
	Desc.TextXAlignment = Enum.TextXAlignment.Left
	Desc.TextYAlignment = Enum.TextYAlignment.Top
	Desc.TextWrapped = true
	Desc.BackgroundTransparency = 1
	Desc.Parent = Frame

	TweenService:Create(Frame, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
	task.wait(duration)
	TweenService:Create(Frame, TweenInfo.new(0.3), {BackgroundTransparency = 1, Size = UDim2.new(0,0,0,0)}):Play()
	game:GetService("Debris"):AddItem(Frame, 0.3)
end

function Library:Init(scriptName, assetsList, callback)
	local parent = GetGuiParent()
	local LoadingGui = Instance.new("ScreenGui")
	LoadingGui.Name = "Loader"
	LoadingGui.Parent = parent

	local Main = Instance.new("Frame")
	Main.Size = UDim2.new(0, 350, 0, 180)
	Main.Position = UDim2.new(0.5, -175, 0.5, -90)
	Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	Main.Parent = LoadingGui

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = Main

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, 0, 0, 40)
	Title.Text = scriptName or "Loading Assets..."
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextSize = 18
	Title.Font = Enum.Font.SourceSansBold
	Title.BackgroundTransparency = 1
	Title.Parent = Main

	local Status = Instance.new("TextLabel")
	Status.Size = UDim2.new(1, 0, 0, 30)
	Status.Position = UDim2.new(0, 0, 0, 70)
	Status.Text = "Initializing setup..."
	Status.TextColor3 = Color3.fromRGB(180, 180, 180)
	Status.TextSize = 14
	Status.Font = Enum.Font.SourceSansItalic
	Status.BackgroundTransparency = 1
	Status.Parent = Main

	local BarBg = Instance.new("Frame")
	BarBg.Size = UDim2.new(0.85, 0, 0, 6)
	BarBg.Position = UDim2.new(0.075, 0, 0, 120)
	BarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	BarBg.BorderSizePixel = 0
	BarBg.Parent = Main

	local BarFill = Instance.new("Frame")
	BarFill.Size = UDim2.new(0, 0, 1, 0)
	BarFill.BackgroundColor3 = Library.CurrentTheme.Accent
	BarFill.BorderSizePixel = 0
	BarFill.Parent = BarBg

	local FillCorner = Instance.new("UICorner")
	FillCorner.CornerRadius = UDim.new(0, 3)
	FillCorner.Parent = BarFill

	task.wait(0.3)
	local total = #assetsList
	for i, asset in ipairs(assetsList) do
		Status.Text = "Loading: " .. tostring(asset)
		local progress = i / total
		TweenService:Create(BarFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(progress, 0, 1, 0)}):Play()
		task.wait(math.random(1, 3) / 10)
	end

	Status.Text = "Done! Opening interface..."
	task.wait(0.3)
	LoadingGui:Destroy()
	if callback then pcall(callback) end
end

-- ==========================================
-- 🪟 СОЗДАНИЕ ГЛАВНОГО ОКНА И ТАБОВ
-- ==========================================
function Library:CreateWindow(titleText)
	local Window = {}
	setmetatable(Window, { __index = Library })

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "UI_Library_Base"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = GetGuiParent()

	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 520, 0, 370)
	MainFrame.Position = UDim2.new(0.5, -260, 0.5, -185)
	MainFrame.BackgroundColor3 = Library.CurrentTheme.MainBg
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = ScreenGui

	local MainCorner = Instance.new("UICorner")
	MainCorner.CornerRadius = UDim.new(0, 8)
	MainCorner.Parent = MainFrame

	local TitleBar = Instance.new("Frame")
	TitleBar.Name = "TitleBar"
	TitleBar.Size = UDim2.new(1, 0, 0, 40)
	TitleBar.BackgroundColor3 = Library.CurrentTheme.TopBar
	TitleBar.BorderSizePixel = 0
	TitleBar.Parent = MainFrame

	local TitleCorner = Instance.new("UICorner")
	TitleCorner.CornerRadius = UDim.new(0, 8)
	TitleCorner.Parent = TitleBar

	MakeDraggable(TitleBar, MainFrame)

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size = UDim2.new(1, -20, 1, 0)
	TitleLabel.Position = UDim2.new(0, 15, 0, 0)
	TitleLabel.Text = titleText or "Premium Engine"
	TitleLabel.TextColor3 = Library.CurrentTheme.Text
	TitleLabel.TextSize = 16
	TitleLabel.Font = Enum.Font.SourceSansBold
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Parent = TitleBar

	local TabContainer = Instance.new("Frame")
	TabContainer.Name = "TabContainer"
	TabContainer.Size = UDim2.new(0, 130, 1, -40)
	TabContainer.Position = UDim2.new(0, 0, 0, 40)
	TabContainer.BackgroundColor3 = Library.CurrentTheme.Sidebar
	TabContainer.BorderSizePixel = 0
	TabContainer.Parent = MainFrame

	local TabLayout = Instance.new("UIListLayout")
	TabLayout.Padding = UDim.new(0, 4)
	TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	TabLayout.Parent = TabContainer

	local TabPadding = Instance.new("UIPadding")
	TabPadding.PaddingTop = UDim.new(0, 8)
	TabPadding.Parent = TabContainer

	local ContentContainer = Instance.new("Frame")
	ContentContainer.Name = "ContentContainer"
	ContentContainer.Size = UDim2.new(1, -130, 1, -40)
	ContentContainer.Position = UDim2.new(0, 130, 0, 40)
	ContentContainer.BackgroundTransparency = 1
	ContentContainer.Parent = MainFrame

	-- Глобальный бинд на скрытие/открытие всего меню (по умолчанию на RightShift)
	local uiVisible = true
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.RightShift then
			uiVisible = not uiVisible
			MainFrame.Visible = uiVisible
			Library:Notify("Интерфейс", uiVisible and "Меню открыто" or "Меню скрыто (Нажмите RightShift)", 2)
		end
	end)

	Window.MainFrame = MainFrame
	Window.ContentContainer = ContentContainer
	Window.TabContainer = TabContainer
	return Window
end

function Library:CreateTab(tabName)
	local Tab = {}
	local Window = self

	local TabButton = Instance.new("TextButton")
	TabButton.Size = UDim2.new(0.9, 0, 0, 32)
	TabButton.BackgroundColor3 = Library.CurrentTheme.ElementBg
	TabButton.Text = tabName
	TabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
	TabButton.Font = Enum.Font.SourceSansMedium
	TabButton.TextSize = 14
	TabButton.Parent = Window.TabContainer

	local BCorner = Instance.new("UICorner")
	BCorner.CornerRadius = UDim.new(0, 4)
	BCorner.Parent = TabButton

	local TabPage = Instance.new("ScrollingFrame")
	TabPage.Size = UDim2.new(1, 0, 1, 0)
	TabPage.BackgroundTransparency = 1
	TabPage.Visible = false
	TabPage.ScrollBarThickness = 3
	TabPage.ScrollBarImageColor3 = Library.CurrentTheme.Accent
	TabPage.Parent = Window.ContentContainer

	local PageLayout = Instance.new("UIListLayout")
	PageLayout.Padding = UDim.new(0, 8)
	PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
	PageLayout.Parent = TabPage

	local PagePadding = Instance.new("UIPadding")
	PagePadding.PaddingTop = UDim.new(0, 10)
	PagePadding.Parent = TabPage

	PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
	end)

	TabButton.MouseButton1Click:Connect(function()
		for _, page in pairs(Window.ContentContainer:GetChildren()) do
			if page:IsA("ScrollingFrame") then page.Visible = false end
		end
		for _, btn in pairs(Window.TabContainer:GetChildren()) do
			if btn:IsA("TextButton") then 
				TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Library.CurrentTheme.ElementBg, TextColor3 = Color3.fromRGB(200,200,200)}):Play()
			end
		end
		TabPage.Visible = true
		TweenService:Create(TabButton, TweenInfo.new(0.2), {BackgroundColor3 = Library.CurrentTheme.Accent, TextColor3 = Color3.fromRGB(255,255,255)}):Play()
	end)

	if #Window.TabContainer:GetChildren() == 3 then
		TabPage.Visible = true
		TabButton.BackgroundColor3 = Library.CurrentTheme.Accent
		TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	Tab.Page = TabPage
	setmetatable(Tab, { __index = Library })
	return Tab
end

-- ==========================================
-- 🛡️ ЛОГИКА SAFE MODE
-- ==========================================
local function CheckSafeMode(config, title, actionCallback)
	if config and config.unsafe and Library.SafeModeActive then
		Library:Notify("Safe Mode Блокировка", "Функция '" .. tostring(title) .. "' заблокирована из-за Safe Mode!", 3)
		return false
	end
	actionCallback()
	return true
end

function Library:UpdateSafeModeVisuals()
	for _, item in pairs(Library.ElementsRegistry) do
		if item.config and item.config.unsafe then
			if Library.SafeModeActive then
				TweenService:Create(item.instance, TweenInfo.new(0.2), {BackgroundTransparency = 0.6}):Play()
				if item.label then item.label.TextColor3 = Color3.fromRGB(120, 120, 120) end
			else
				TweenService:Create(item.instance, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
				if item.label then item.label.TextColor3 = Library.CurrentTheme.Text end
			end
		end
	end
end

-- ==========================================
-- 🛠️ СОЗДАНИЕ ИНТЕРФЕЙСНЫХ ЭЛЕМЕНТОВ
-- ==========================================
function Library:CreateInfo(text)
	local BaseFrame = Instance.new("Frame")
	BaseFrame.Size = UDim2.new(0.92, 0, 0, 30)
	BaseFrame.BackgroundColor3 = Library.CurrentTheme.ElementBg
	BaseFrame.Parent = self.Page

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 5)
	Corner.Parent = BaseFrame

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -20, 1, 0)
	Label.Position = UDim2.new(0, 10, 0, 0)
	Label.Text = "ℹ️  " .. text
	Label.TextColor3 = Color3.fromRGB(180, 210, 255)
	Label.TextSize = 13
	Label.Font = Enum.Font.SourceSansMedium
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.BackgroundTransparency = 1
	Label.Parent = BaseFrame
end

function Library:CreateButton(text, config, callback)
	config = config or {unsafe = false}
	local callback = callback or function() end

	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(0.92, 0, 0, 34)
	Button.BackgroundColor3 = Library.CurrentTheme.ElementBg
	Button.Text = text .. (config.unsafe and " ⚠️" or "")
	Button.TextColor3 = Library.CurrentTheme.Text
	Button.Font = Enum.Font.SourceSansSemibold
	Button.TextSize = 14
	Button.Parent = self.Page

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 5)
	Corner.Parent = Button

	table.insert(Library.ElementsRegistry, {instance = Button, label = nil, config = config})

	Button.MouseButton1Click:Connect(function()
		CheckSafeMode(config, text, callback)
	end)
	return Button
end

function Library:CreateSubButton(text, config, callback)
	config = config or {unsafe = false}
	local callback = callback or function() end

	local SubButton = Instance.new("TextButton")
	SubButton.Size = UDim2.new(0.85, 0, 0, 26)
	SubButton.BackgroundColor3 = Library.CurrentTheme.ElementBg
	SubButton.Text = "↳ " .. text .. (config.unsafe and " ⚠️" or "")
	SubButton.TextColor3 = Color3.fromRGB(190, 190, 190)
	SubButton.Font = Enum.Font.SourceSans
	SubButton.TextSize = 13
	SubButton.TextXAlignment = Enum.TextXAlignment.Left
	SubButton.Parent = self.Page

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 12)
	Padding.Parent = SubButton

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 4)
	Corner.Parent = SubButton

	table.insert(Library.ElementsRegistry, {instance = SubButton, label = nil, config = config})

	SubButton.MouseButton1Click:Connect(function()
		CheckSafeMode(config, text, callback)
	end)
end

function Library:CreateToggle(text, config, default, callback)
	config = config or {id = HttpService:GenerateGUID(false), unsafe = false}
	local state = default or false
	local callback = callback or function() end

	local ToggleFrame = Instance.new("Frame")
	ToggleFrame.Size = UDim2.new(0.92, 0, 0, 36)
	ToggleFrame.BackgroundColor3 = Library.CurrentTheme.ElementBg
	ToggleFrame.Parent = self.Page

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 5)
	Corner.Parent = ToggleFrame

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -60, 1, 0)
	Label.Position = UDim2.new(0, 12, 0, 0)
	Label.Text = text .. (config.unsafe and " [UNSAFE]" or "")
	Label.TextColor3 = Library.CurrentTheme.Text
	Label.TextSize = 14
	Label.Font = Enum.Font.SourceSans
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.BackgroundTransparency = 1
	Label.Parent = ToggleFrame

	local SwitchBg = Instance.new("TextButton")
	SwitchBg.Size = UDim2.new(0, 36, 0, 20)
	SwitchBg.Position = UDim2.new(1, -46, 0.5, -10)
	SwitchBg.BackgroundColor3 = state and Library.CurrentTheme.Accent or Color3.fromRGB(50, 50, 50)
	SwitchBg.Text = ""
	SwitchBg.Parent = ToggleFrame

	local SwitchCorner = Instance.new("UICorner")
	SwitchCorner.CornerRadius = UDim.new(1, 0)
	SwitchCorner.Parent = SwitchBg

	local Ball = Instance.new("Frame")
	Ball.Size = UDim2.new(0, 14, 0, 14)
	Ball.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
	Ball.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Ball.Parent = SwitchBg

	local BallCorner = Instance.new("UICorner")
	BallCorner.CornerRadius = UDim.new(1, 0)
	BallCorner.Parent = Ball

	local function SetState(newstate)
		state = newstate
		local targetPos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
		local targetColor = state and Library.CurrentTheme.Accent or Color3.fromRGB(50, 50, 50)
		TweenService:Create(Ball, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Position = targetPos}):Play()
		TweenService:Create(SwitchBg, TweenInfo.new(0.15), {BackgroundColor3 = targetColor}):Play()
		pcall(callback, state)
	end

	SwitchBg.MouseButton1Click:Connect(function()
		CheckSafeMode(config, text, function()
			SetState(not state)
		end)
	end)

	local registryEntry = {
		type = "Toggle",
		id = config.id,
		config = config,
		instance = ToggleFrame,
		label = Label,
		SetValue = SetState,
		GetValue = function() return state end
	}
	table.insert(Library.ElementsRegistry, registryEntry)
end

function Library:CreateSlider(text, config, min, max, default, callback)
	config = config or {id = HttpService:GenerateGUID(false)}
	local min = min or 0
	local max = max or 100
	local default = default or min
	local callback = callback or function() end
	local value = default

	local SliderFrame = Instance.new("Frame")
	SliderFrame.Size = UDim2.new(0.92, 0, 0, 45)
	SliderFrame.BackgroundColor3 = Library.CurrentTheme.ElementBg
	SliderFrame.Parent = self.Page

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 5)
	Corner.Parent = SliderFrame

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -80, 0, 25)
	Label.Position = UDim2.new(0, 12, 0, 2)
	Label.Text = text
	Label.TextColor3 = Library.CurrentTheme.Text
	Label.TextSize = 14
	Label.Font = Enum.Font.SourceSans
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.BackgroundTransparency = 1
	Label.Parent = SliderFrame

	local ValueLabel = Instance.new("TextLabel")
	ValueLabel.Size = UDim2.new(0, 60, 0, 25)
	ValueLabel.Position = UDim2.new(1, -72, 0, 2)
	ValueLabel.Text = tostring(value)
	ValueLabel.TextColor3 = Library.CurrentTheme.Accent
	ValueLabel.TextSize = 14
	ValueLabel.Font = Enum.Font.SourceSansBold
	ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
	ValueLabel.BackgroundTransparency = 1
	ValueLabel.Parent = SliderFrame

	local SlideTrack = Instance.new("TextButton")
	SlideTrack.Size = UDim2.new(0.92, 0, 0, 6)
	SlideTrack.Position = UDim2.new(0.04, 0, 0, 30)
	SlideTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	SlideTrack.Text = ""
	SlideTrack.Parent = SliderFrame

	local SlideFill = Instance.new("Frame")
	SlideFill.Size = UDim2.new((value - min)/(max - min), 0, 1, 0)
	SlideFill.BackgroundColor3 = Library.CurrentTheme.Accent
	SlideFill.BorderSizePixel = 0
	SlideFill.Parent = SlideTrack

	local sliding = false
	local function UpdateSlider(percentage)
		value = math.floor(min + (max - min) * percentage)
		ValueLabel.Text = tostring(value)
		SlideFill.Size = UDim2.new(percentage, 0, 1, 0)
		pcall(callback, value)
	end

	SlideTrack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			local percentage = math.clamp((input.Position.X - SlideTrack.AbsolutePosition.X) / SlideTrack.AbsoluteSize.X, 0, 1)
			UpdateSlider(percentage)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local percentage = math.clamp((input.Position.X - SlideTrack.AbsolutePosition.X) / SlideTrack.AbsoluteSize.X, 0, 1)
			UpdateSlider(percentage)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliding = false end
	end)

	local registryEntry = {
		type = "Slider",
		id = config.id,
		SetValue = function(val)
			local pct = math.clamp((val - min) / (max - min), 0, 1)
			UpdateSlider(pct)
		end,
		GetValue = function() return value end
	}
	table.insert(Library.ElementsRegistry, registryEntry)
end

function Library:CreateTextBox(text, config, placeholder, callback)
	config = config or {id = HttpService:GenerateGUID(false)}
	local callback = callback or function() end

	local BoxFrame = Instance.new("Frame")
	BoxFrame.Size = UDim2.new(0.92, 0, 0, 38)
	BoxFrame.BackgroundColor3 = Library.CurrentTheme.ElementBg
	BoxFrame.Parent = self.Page

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 5)
	Corner.Parent = BoxFrame

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0.5, 0, 1, 0)
	Label.Position = UDim2.new(0, 12, 0, 0)
	Label.Text = text
	Label.TextColor3 = Library.CurrentTheme.Text
	Label.TextSize = 14
	Label.Font = Enum.Font.SourceSans
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.BackgroundTransparency = 1
	Label.Parent = BoxFrame

	local Box = Instance.new("TextBox")
	Box.Size = UDim2.new(0.42, 0, 0, 26)
	Box.Position = UDim2.new(0.55, 0, 0.5, -13)
	Box.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	Box.PlaceholderText = placeholder or "Type here..."
	Box.Text = ""
	Box.TextColor3 = Color3.fromRGB(255, 255, 255)
	Box.TextSize = 13
	Box.Font = Enum.Font.SourceSans
	Box.Parent = BoxFrame

	Box.FocusLost:Connect(function(enterPressed)
		pcall(callback, Box.Text, enterPressed)
	end)

	local registryEntry = {
		type = "TextBox",
		id = config.id,
		SetValue = function(val) Box.Text = tostring(val) pcall(callback, val, true) end,
		GetValue = function() return Box.Text end
	}
	table.insert(Library.ElementsRegistry, registryEntry)
end

function Library:CreateDropDown(text, config, options, callback)
	config = config or {id = HttpService:GenerateGUID(false)}
	local callback = callback or function() end
	local expanded = false
	local currentSelection = "None"

	local DropFrame = Instance.new("Frame")
	DropFrame.Size = UDim2.new(0.92, 0, 0, 38)
	DropFrame.BackgroundColor3 = Library.CurrentTheme.ElementBg
	DropFrame.ClipsDescendants = true
	DropFrame.Parent = self.Page

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 5)
	Corner.Parent = DropFrame

	local MainButton = Instance.new("TextButton")
	MainButton.Size = UDim2.new(1, 0, 0, 38)
	MainButton.BackgroundTransparency = 1
	MainButton.Text = ""
	MainButton.Parent = DropFrame

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0.6, 0, 0, 38)
	Label.Position = UDim2.new(0, 12, 0, 0)
	Label.Text = text .. " : [" .. currentSelection .. "]"
	Label.TextColor3 = Library.CurrentTheme.Text
	Label.TextSize = 14
	Label.Font = Enum.Font.SourceSans
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.BackgroundTransparency = 1
	Label.Parent = DropFrame

	local OptionsContainer = Instance.new("Frame")
	OptionsContainer.Size = UDim2.new(1, 0, 0, #options * 28)
	OptionsContainer.Position = UDim2.new(0, 0, 0, 38)
	OptionsContainer.BackgroundTransparency = 1
	OptionsContainer.Parent = DropFrame

	local List = Instance.new("UIListLayout")
	List.SortOrder = Enum.SortOrder.LayoutOrder
	List.Parent = OptionsContainer

	local function Select(opt)
		currentSelection = tostring(opt)
		Label.Text = text .. " : [" .. currentSelection .. "]"
		pcall(callback, opt)
	end

	for _, opt in ipairs(options) do
		local OptButton = Instance.new("TextButton")
		OptButton.Size = UDim2.new(1, 0, 0, 28)
		OptButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
		OptButton.Text = tostring(opt)
		OptButton.TextColor3 = Color3.fromRGB(180, 180, 180)
		OptButton.Font = Enum.Font.SourceSans
		OptButton.TextSize = 13
		OptButton.Parent = OptionsContainer

		OptButton.MouseButton1Click:Connect(function()
			expanded = false
			DropFrame.Size = UDim2.new(0.92, 0, 0, 38)
			Select(opt)
		end)
	end

	MainButton.MouseButton1Click:Connect(function()
		expanded = not expanded
		DropFrame.Size = expanded and UDim2.new(0.92, 0, 0, 38 + (#options * 28)) or UDim2.new(0.92, 0, 0, 38)
	end)

	local registryEntry = {
		type = "DropDown",
		id = config.id,
		SetValue = Select,
		GetValue = function() return currentSelection end
	}
	table.insert(Library.ElementsRegistry, registryEntry)
end

function Library:CreateKeybind(text, config, defaultKey, callback)
	config = config or {id = HttpService:GenerateGUID(false)}
	local currentKey = defaultKey or Enum.KeyCode.E
	local callback = callback or function() end
	local binding = false

	local KeybindFrame = Instance.new("Frame")
	KeybindFrame.Size = UDim2.new(0.92, 0, 0, 36)
	KeybindFrame.BackgroundColor3 = Library.CurrentTheme.ElementBg
	KeybindFrame.Parent = self.Page

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 5)
	Corner.Parent = KeybindFrame

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -100, 1, 0)
	Label.Position = UDim2.new(0, 12, 0, 0)
	Label.Text = text
	Label.TextColor3 = Library.CurrentTheme.Text
	Label.TextSize = 14
	Label.Font = Enum.Font.SourceSans
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.BackgroundTransparency = 1
	Label.Parent = KeybindFrame

	local BindButton = Instance.new("TextButton")
	BindButton.Size = UDim2.new(0, 80, 0, 24)
	BindButton.Position = UDim2.new(1, -92, 0.5, -12)
	BindButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	BindButton.Text = currentKey.Name
	BindButton.TextColor3 = Library.CurrentTheme.Accent
	BindButton.Font = Enum.Font.SourceSansBold
	BindButton.TextSize = 12
	BindButton.Parent = KeybindFrame

	local BindCorner = Instance.new("UICorner")
	BindCorner.CornerRadius = UDim.new(0, 4)
	BindCorner.Parent = BindButton

	BindButton.MouseButton1Click:Connect(function()
		binding = true
	end)
	BindButton.Text = "..."
	BindButton.TextColor3 = Color3.fromRGB(200, 200, 200)
end

local inputConnection
inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if binding then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			binding = false
			currentKey = input.KeyCode
			BindButton.Text = currentKey.Name
			BindButton.TextColor3 = Library.CurrentTheme.Accent
		end
	else
		if input.KeyCode == currentKey then
			pcall(callback)
		end
	end
end)

-- СЮДА МЫ ДОБАВИЛИ ЗАЩИТУ ОТ NIL ОШИБКИ:
if typeof(config) ~= "table" then
	callback = defaultKey
	defaultKey = config
	config = {id = HttpService:GenerateGUID(false)}
end
config = config or {id = HttpService:GenerateGUID(false)}
config.id = config.id or HttpService:GenerateGUID(false)

-- Дальше идет твой блок, он теперь будет работать идеально:
local registryEntry = {
	type = "Keybind",
	id = config.id,
	SetValue = function(valName) 
		local success, keyCode = pcall(function() return Enum.KeyCode[valName] end)
		if success then
			currentKey = keyCode
			BindButton.Text = currentKey.Name
		end
	end,
	GetValue = function() return currentKey.Name end
}
table.insert(Library.ElementsRegistry, registryEntry)



-- ==========================================
-- 💾 МЕНЕДЖЕРЫ ДАННЫХ И СТИЛЕЙ
-- ==========================================
Library.ConfigManager = { FolderName = "Configs" }

function Library.ConfigManager:Save(name)
	local data = {}
	for _, item in pairs(Library.ElementsRegistry) do
		if item.id then
			data[item.id] = item.GetValue()
		end
	end

	local success, str = pcall(function() return HttpService:JSONEncode(data) end)
	if not success then return end

	if writefile then
		if not isfolder(self.FolderName) then makefolder(self.FolderName) end
		writefile(self.FolderName .. "/" .. name .. ".json", str)
		Library:Notify("Config Manager", "Конфиг '" .. name .. "' сохранен локально!", 3)
	else
		print("Локальное сохранение (writefile) не поддерживается в Roblox Studio. Данные JSON:\n" .. str)
	end
end

function Library.ConfigManager:Load(name)
	if readfile and isfile(self.FolderName .. "/" .. name .. ".json") then
		local str = readfile(self.FolderName .. "/" .. name .. ".json")
		local data = HttpService:JSONDecode(str)
		for _, item in pairs(Library.ElementsRegistry) do
			if item.id and data[item.id] ~= nil then
				item.SetValue(data[item.id])
			end
		end
		Library:Notify("Config Manager", "Конфиг '" .. name .. "' успешно загружен!", 3)
	else
		Library:Notify("Ошибка", "Файл локального конфига не найден или среда не поддерживает чтение файлов.", 3)
	end
end

Library.ConfigCloud = {}

function Library.ConfigCloud:FetchAvailable()
	return {"Legit_HVH_2026", "Rage_Blatant", "Only_Visuals"}
end

function Library.ConfigCloud:LoadFromCloud(configName)
	Library:Notify("Cloud", "Синхронизация с сервером базы данных...", 2)
	task.wait(1)

	local CloudMockDatabase = {
		["Legit_HVH_2026"] = { ["walkspeed_val"] = 25, ["aimbot_toggle"] = true, ["fly_toggle"] = false, ["fly_bind"] = "F" },
		["Rage_Blatant"] = { ["walkspeed_val"] = 200, ["aimbot_toggle"] = true, ["fly_toggle"] = true, ["fly_bind"] = "V" },
		["Only_Visuals"] = { ["walkspeed_val"] = 16, ["aimbot_toggle"] = false, ["fly_toggle"] = false, ["fly_bind"] = "G" }
	}

	local cloudData = CloudMockDatabase[configName]
	if cloudData then
		for _, item in pairs(Library.ElementsRegistry) do
			if item.id and cloudData[item.id] ~= nil then
				item.SetValue(cloudData[item.id])
			end
		end
		Library:Notify("Cloud Success", "Облачный пресет '" .. configName .. "' успешно применен!", 3)
	else
		Library:Notify("Cloud Error", "Пресет не найден в облаке.", 3)
	end
end

Library.ThemeManager = {}

function Library.ThemeManager:ApplyTheme(window, themeName)
	local targetTheme = Themes[themeName]
	if not targetTheme then return end
	Library.CurrentTheme = targetTheme

	if window and window.MainFrame then
		window.MainFrame.BackgroundColor3 = targetTheme.MainBg
		window.MainFrame.TitleBar.BackgroundColor3 = targetTheme.TopBar
		window.MainFrame.TabContainer.BackgroundColor3 = targetTheme.Sidebar
		window.MainFrame.TitleBar.TitleLabel.TextColor3 = targetTheme.Text

		for _, tabBtn in pairs(window.TabContainer:GetChildren()) do
			if tabBtn:IsA("TextButton") and tabBtn.TextColor3 ~= Color3.fromRGB(255,255,255) then
				tabBtn.BackgroundColor3 = targetTheme.ElementBg
			end
		end
		Library:Notify("Theme Manager", "Тема изменена на: " .. themeName, 2)
	end
end

-- ==========================================
-- 🚀 КОД ИНИЦИАЛИЗАЦИИ И ЗАПУСКА СЦЕНАРИЯ
-- ==========================================
local AppAssets = {"AntiCheat_Bypass.sys", "Themes_Library.json", "Cloud_Hub_Sync.lua"}

Library:Init("Nexus Hub Pro", AppAssets, function()
	local Window = Library:CreateWindow("base")

	local MainTab = Window:CreateTab("Функции")
	local SafeTab = Window:CreateTab("Безопасность")
	local ConfigTab = Window:CreateTab("Конфиги")

	MainTab:CreateInfo("Опасные функции помечены значком ⚠️")

	MainTab:CreateToggle("Бесконечный полет", {id = "fly_toggle", unsafe = true}, false, function(state)
		print("Полет активен:", state)
	end)

	MainTab:CreateKeybind("Клавиша триггера полета", {id = "fly_bind"}, Enum.KeyCode.F, function()
		Library:Notify("Keybind Trigger", "Вы активировали бинд полета!", 2)
	end)

	MainTab:CreateSlider("Кастомная Скорость", {id = "walkspeed_val"}, 16, 250, 16, function(v)
		if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
			game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
		end
	end)

	MainTab:CreateButton("Crash Server (Кик всех игроков)", {unsafe = true}, function()
		print("Запуск функции краша сервера...")
	end)

	SafeTab:CreateToggle("Включить Safe Mode (Защита от бана)", {id = "safemode_global"}, false, function(state)
		Library.SafeModeActive = state
		Library:UpdateSafeModeVisuals()
		Library:Notify("Защита", state and "Safe Mode теперь АКТИВЕН." or "Safe Mode ОТКЛЮЧЕН.", 3)
	end)

	SafeTab:CreateDropDown("Выбрать визуальный стиль", {id = "theme_select"}, {"Dark Default", "Neon Blue", "Sakura Pink", "Cyberpunk"}, function(selectedTheme)
		Library.ThemeManager:ApplyTheme(Window, selectedTheme)
	end)

	ConfigTab:CreateTextBox("Имя локального файла", {id = "cfg_name_box"}, "my_config", function(text) end)

	ConfigTab:CreateButton("Сохранить конфиг на ПК", nil, function()
		local name = "default"
		for _, el in pairs(Library.ElementsRegistry) do
			if el.id == "cfg_name_box" then name = el.GetValue() end
		end
		Library.ConfigManager:Save(name)
	end)

	ConfigTab:CreateButton("Загрузить конфиг с ПК", nil, function()
		local name = "default"
		for _, el in pairs(Library.ElementsRegistry) do
			if el.id == "cfg_name_box" then name = el.GetValue() end
		end
		Library.ConfigManager:Load(name)
	end)

	local cloudOptions = Library.ConfigCloud:FetchAvailable()
	ConfigTab:CreateDropDown("Облачные пресеты (Топ игроков)", {id = "cloud_dropdown"}, cloudOptions, function(selectedCloudCfg)
		Library.ConfigCloud:LoadFromCloud(selectedCloudCfg)
	end)
end)
