-- ==========================================
-- WAIFU HUB V8 (ULTIMATE EDITION)
-- ==========================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

-- Configurações de Cor & Tema
local COLOR_BG = Color3.fromRGB(15, 15, 15)
local COLOR_PURPLE = Color3.fromRGB(148, 0, 211)
local COLOR_TEXT = Color3.fromRGB(255, 255, 255)
local COLOR_DARK = Color3.fromRGB(25, 25, 25)
local COLOR_CLOSE = Color3.fromRGB(200, 50, 50)

-- ==========================================
-- CONSTRUÇÃO DA UI PRINCIPAL
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MyWaifuHubV8"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui") or Player.PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 520, 0, 500)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -250)
MainFrame.BackgroundColor3 = COLOR_BG
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = COLOR_PURPLE
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- Imagem da Waifu (Lado Direito)
local WaifuImage = Instance.new("ImageLabel")
WaifuImage.Size = UDim2.new(0, 210, 0, 480)
WaifuImage.Position = UDim2.new(0, 300, 0, 10)
WaifuImage.BackgroundColor3 = Color3.new(0, 0, 0)
WaifuImage.Image = "rbxassetid://135247969077372"
WaifuImage.ScaleType = Enum.ScaleType.Crop
WaifuImage.Parent = MainFrame

Instance.new("UICorner", WaifuImage).CornerRadius = UDim.new(0, 10)
local ImageStroke = Instance.new("UIStroke")
ImageStroke.Color = COLOR_PURPLE
ImageStroke.Thickness = 1
ImageStroke.Parent = WaifuImage

-- Botão de Fechar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 10)
CloseBtn.BackgroundColor3 = COLOR_DARK
CloseBtn.TextColor3 = COLOR_CLOSE
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Text = "X"
CloseBtn.ZIndex = 5
CloseBtn.Parent = MainFrame

Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", CloseBtn).Color = COLOR_CLOSE

-- Título
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 280, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = COLOR_PURPLE
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.Text = "Waifu Hub V8"
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- ==========================================
-- SISTEMA DE ABAS (TABS)
-- ==========================================
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(0, 280, 0, 30)
TabContainer.Position = UDim2.new(0, 10, 0, 45)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainFrame

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 5)
TabListLayout.Parent = TabContainer

local function CreateTabFrame(name)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = name
	scroll.Size = UDim2.new(0, 290, 0, 410)
	scroll.Position = UDim2.new(0, 10, 0, 80)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.Visible = false
	scroll.Parent = MainFrame
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = scroll
	
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end)
	
	return scroll
end

local Tabs = {
	Universal = CreateTabFrame("Universal"),
	Murder = CreateTabFrame("Murder"),
	Jailbreak = CreateTabFrame("Jailbreak")
}
Tabs.Universal.Visible = true

local TabButtons = {}

local function SelectTab(tabName)
	for name, frame in pairs(Tabs) do frame.Visible = (name == tabName) end
	for name, btn in pairs(TabButtons) do
		if name == tabName then
			btn.BackgroundColor3 = COLOR_PURPLE
			btn.TextColor3 = COLOR_TEXT
		else
			btn.BackgroundColor3 = COLOR_DARK
			btn.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end
end

local function CreateTabButton(name)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 90, 1, 0)
	btn.BackgroundColor3 = COLOR_DARK
	btn.TextColor3 = Color3.fromRGB(150, 150, 150)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.Text = name
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	btn.Parent = TabContainer
	
	btn.MouseButton1Click:Connect(function() SelectTab(name) end)
	TabButtons[name] = btn
end

CreateTabButton("Universal")
CreateTabButton("Murder")
CreateTabButton("Jailbreak")
SelectTab("Universal")

-- ==========================================
-- FUNÇÕES CRIADORAS DE ELEMENTOS
-- ==========================================
local function CreateSlider(text, parent, minVal, maxVal, defaultVal, callback)
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(0, 270, 0, 50)
	Container.BackgroundTransparency = 1
	Container.Parent = parent

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, 0, 0, 20)
	Label.BackgroundTransparency = 1
	Label.TextColor3 = COLOR_TEXT
	Label.Font = Enum.Font.GothamSemibold
	Label.TextSize = 14
	Label.Text = text .. ": " .. defaultVal
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Container

	local SliderBg = Instance.new("Frame")
	SliderBg.Size = UDim2.new(1, -10, 0, 6)
	SliderBg.Position = UDim2.new(0, 5, 0, 30)
	SliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)
	SliderBg.Parent = Container

	local SliderFill = Instance.new("Frame")
	local startScale = (defaultVal - minVal) / (maxVal - minVal)
	SliderFill.Size = UDim2.new(startScale, 0, 1, 0)
	SliderFill.BackgroundColor3 = COLOR_PURPLE
	Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)
	SliderFill.Parent = SliderBg

	local Knob = Instance.new("TextButton")
	Knob.Size = UDim2.new(0, 16, 0, 16)
	Knob.Position = UDim2.new(startScale, -8, 0.5, -8)
	Knob.BackgroundColor3 = COLOR_TEXT
	Knob.Text = ""
	Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)
	Knob.Parent = SliderBg

	local dragging = false

	local function UpdateFromMouse(inputX)
		local sliderPos = SliderBg.AbsolutePosition.X
		local sliderSize = SliderBg.AbsoluteSize.X
		if sliderSize > 0 then
			local percentage = math.clamp((inputX - sliderPos) / sliderSize, 0, 1)
			Knob.Position = UDim2.new(percentage, -8, 0.5, -8)
			SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
			local value = math.floor(minVal + ((maxVal - minVal) * percentage))
			Label.Text = text .. ": " .. value
			callback(value)
		end
	end

	Knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			UpdateFromMouse(input.Position.X)
		end
	end)

	SliderBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			UpdateFromMouse(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			UpdateFromMouse(input.Position.X)
		end
	end)
end

local function CreateButton(text, parent, bgCol)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 270, 0, 35)
	btn.BackgroundColor3 = bgCol or Color3.fromRGB(20, 20, 20)
	btn.TextColor3 = COLOR_TEXT
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 14
	btn.Text = text
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLOR_PURPLE
	stroke.Thickness = 1
	stroke.Parent = btn
	btn.Parent = parent
	return btn
end

-- ==========================================
-- VARIÁVEIS GLOBAIS & ESTADO
-- ==========================================
local currentSpeed, currentFlySpeed = 16, 50
local customSpeedEnabled = false
local flying, flinging, noclip, espMM2, espJB, showHitboxes, autoTpGun, espCoins = false, false, false, false, false, false, false, false
local bg, bv, noclipConnection, flyConnection, speedConnection, selectedTarget

local EspFolderMM2 = Instance.new("Folder", game:GetService("CoreGui")); EspFolderMM2.Name = "Waifu_MM2_ESP"
local EspFolderCoins = Instance.new("Folder", game:GetService("CoreGui")); EspFolderCoins.Name = "Waifu_Coins_ESP"
local EspFolderJB = Instance.new("Folder", game:GetService("CoreGui")); EspFolderJB.Name = "Waifu_JB_ESP"
local HitboxFolder = Instance.new("Folder", game:GetService("CoreGui")); HitboxFolder.Name = "Waifu_Hitboxes"

-- Manter velocidade sempre aplicada mesmo após respawn ou animações
local function ApplySpeed()
	if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
		local hum = Player.Character:FindFirstChildOfClass("Humanoid")
		hum.WalkSpeed = customSpeedEnabled and currentSpeed or 16
	end
end

speedConnection = RunService.Heartbeat:Connect(function()
	if customSpeedEnabled then
		ApplySpeed()
	end
end)

Player.CharacterAdded:Connect(function()
	task.wait(0.5)
	ApplySpeed()
end)

-- ==========================================
-- ABA 1: UNIVERSAL
-- ==========================================

-- Slider e Botão de Ativar Velocidade
CreateSlider("Velocidade", Tabs.Universal, 16, 250, 16, function(val)
	currentSpeed = val
	if customSpeedEnabled then
		ApplySpeed()
	end
end)

local SpeedToggleBtn = CreateButton("Ativar Velocidade Customizada", Tabs.Universal)
SpeedToggleBtn.MouseButton1Click:Connect(function()
	customSpeedEnabled = not customSpeedEnabled
	if customSpeedEnabled then
		SpeedToggleBtn.TextColor3 = COLOR_PURPLE
		ApplySpeed()
	else
		SpeedToggleBtn.TextColor3 = COLOR_TEXT
		if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
			Player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
		end
	end
end)

-- Slider e Botão de Voo Otimizado (RenderStepped & Câmera Real)
CreateSlider("Velocidade Voo", Tabs.Universal, 10, 250, 50, function(val)
	currentFlySpeed = val
end)

local FlyBtn = CreateButton("Ativar Voo", Tabs.Universal)
FlyBtn.MouseButton1Click:Connect(function()
	local char = Player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end

	flying = not flying
	if flying then
		FlyBtn.TextColor3 = COLOR_PURPLE
		
		if bg then bg:Destroy() end
		if bv then bv:Destroy() end
		if flyConnection then flyConnection:Disconnect() end

		bg = Instance.new("BodyGyro")
		bg.P = 9e4
		bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		bg.CFrame = hrp.CFrame
		bg.Parent = hrp

		bv = Instance.new("BodyVelocity")
		bv.Velocity = Vector3.zero
		bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		bv.Parent = hrp

		hum.PlatformStand = true

		flyConnection = RunService.RenderStepped:Connect(function()
			if not flying or not hrp or not hrp.Parent then
				if flyConnection then flyConnection:Disconnect() end
				return
			end

			local cam = Workspace.CurrentCamera
			bg.CFrame = cam.CFrame

			local moveDir = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
				moveDir = moveDir - Vector3.new(0, 1, 0)
			end

			if moveDir.Magnitude > 0 then
				bv.Velocity = moveDir.Unit * currentFlySpeed
			else
				bv.Velocity = Vector3.zero
			end
		end)
	else
		FlyBtn.TextColor3 = COLOR_TEXT
		if flyConnection then flyConnection:Disconnect() end
		if bg then bg:Destroy() end
		if bv then bv:Destroy() end
		if hum then hum.PlatformStand = false end
	end
end)

local NoclipBtn = CreateButton("Ativar Noclip (Atravessar)", Tabs.Universal)
NoclipBtn.MouseButton1Click:Connect(function()
	noclip = not noclip
	if noclip then
		NoclipBtn.TextColor3 = COLOR_PURPLE
		noclipConnection = RunService.Stepped:Connect(function()
			if Player.Character then
				for _, part in pairs(Player.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end)
	else
		NoclipBtn.TextColor3 = COLOR_TEXT
		if noclipConnection then noclipConnection:Disconnect() end
		if Player.Character then
			for _, part in pairs(Player.Character:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.CanCollide = true
				end
			end
		end
	end
end)

local FlingBtn = CreateButton("Ativar Fling", Tabs.Universal)
FlingBtn.MouseButton1Click:Connect(function()
	local char = Player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	flinging = not flinging
	if flinging then
		FlingBtn.TextColor3 = COLOR_PURPLE
		local spin = Instance.new("BodyAngularVelocity")
		spin.Name = "FlingSpin"
		spin.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		spin.AngularVelocity = Vector3.new(0, 50000, 0)
		spin.Parent = hrp
	else
		FlingBtn.TextColor3 = COLOR_TEXT
		if hrp:FindFirstChild("FlingSpin") then hrp.FlingSpin:Destroy() end
	end
end)

local KickBtn = CreateButton("Super Chute (Arremessar)", Tabs.Universal)
KickBtn.MouseButton1Click:Connect(function()
	local char = Player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local nearestTarget, shortestDist = nil, 15 
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
			if dist < shortestDist then
				shortestDist = dist
				nearestTarget = p.Character.HumanoidRootPart
			end
		end
	end
	if nearestTarget then
		KickBtn.TextColor3 = COLOR_PURPLE
		local kickSpin = Instance.new("BodyAngularVelocity")
		kickSpin.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		kickSpin.AngularVelocity = Vector3.new(0, 999999, 0)
		kickSpin.Parent = hrp

		local dash = Instance.new("BodyVelocity")
		dash.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		dash.Velocity = (nearestTarget.Position - hrp.Position).Unit * 100
		dash.Parent = hrp

		task.wait(0.25)
		kickSpin:Destroy()
		dash:Destroy()
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		task.wait(0.1)
		KickBtn.TextColor3 = COLOR_TEXT
	end
end)

local DanceBtn = CreateButton("Dançar (/e dance)", Tabs.Universal)
DanceBtn.MouseButton1Click:Connect(function() Players:Chat("/e dance") end)

local PlayerDropdownBtn = CreateButton("Selecionar Alvo: Nenhum", Tabs.Universal, COLOR_DARK)
local PlayerListFrame = Instance.new("Frame")
PlayerListFrame.Size = UDim2.new(0, 270, 0, 0)
PlayerListFrame.BackgroundTransparency = 1
PlayerListFrame.Visible = false
PlayerListFrame.Parent = Tabs.Universal

local PlistLayout = Instance.new("UIListLayout")
PlistLayout.SortOrder = Enum.SortOrder.LayoutOrder
PlistLayout.Padding = UDim.new(0, 4)
PlistLayout.Parent = PlayerListFrame

PlayerDropdownBtn.MouseButton1Click:Connect(function()
	PlayerListFrame.Visible = not PlayerListFrame.Visible
	if PlayerListFrame.Visible then
		for _, child in pairs(PlayerListFrame:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		local count = 0
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= Player then
				local pBtn = Instance.new("TextButton")
				pBtn.Size = UDim2.new(1, 0, 0, 30)
				pBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				pBtn.TextColor3 = COLOR_TEXT
				pBtn.Font = Enum.Font.Gotham
				pBtn.TextSize = 13
				pBtn.Text = p.DisplayName
				Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 5)
				pBtn.MouseButton1Click:Connect(function()
					selectedTarget = p
					PlayerDropdownBtn.Text = "Alvo: " .. p.DisplayName
					PlayerListFrame.Visible = false
				end)
				pBtn.Parent = PlayerListFrame
				count = count + 1
			end
		end
		PlayerListFrame.Size = UDim2.new(0, 270, 0, count * 34)
	end
end)

local TeleportBtn = CreateButton("Teleportar ao Alvo", Tabs.Universal)
TeleportBtn.TextColor3 = COLOR_PURPLE
TeleportBtn.MouseButton1Click:Connect(function()
	if selectedTarget and selectedTarget.Character and selectedTarget.Character:FindFirstChild("HumanoidRootPart") then
		local char = Player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			char.HumanoidRootPart.CFrame = selectedTarget.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
		end
	end
end)

-- ==========================================
-- ABA 2: MURDER (MM2)
-- ==========================================
local EspMM2Btn = CreateButton("Ativar ESP (Ver Papéis)", Tabs.Murder)
EspMM2Btn.MouseButton1Click:Connect(function()
	espMM2 = not espMM2
	if espMM2 then
		EspMM2Btn.TextColor3 = COLOR_PURPLE
		task.spawn(function()
			while espMM2 do
				EspFolderMM2:ClearAllChildren()
				for _, p in pairs(Players:GetPlayers()) do
					if p ~= Player and p.Character and p.Character:FindFirstChild("Head") then
						local hasKnife, hasGun = false, false
						local function check(item)
							if item:IsA("Tool") then
								local name = item.Name:lower()
								if name == "knife" or name:find("scythe") or name:find("pitchfork") or name:find("blade") then hasKnife = true end
								if name == "gun" or name == "revolver" or name:find("blaster") then hasGun = true end
							end
						end
						if p.Character then for _, v in pairs(p.Character:GetChildren()) do check(v) end end
						if p:FindFirstChild("Backpack") then for _, v in pairs(p.Backpack:GetChildren()) do check(v) end end
						
						local role, color = nil, nil
						if hasKnife then
							role = "MURDER"
							color = Color3.fromRGB(255, 0, 0)
						elseif hasGun then
							role = "SHERIFE"
							color = Color3.fromRGB(0, 100, 255)
						end
						
						if role then
							local hl = Instance.new("Highlight", EspFolderMM2)
							hl.Adornee = p.Character
							hl.FillColor = color
							hl.OutlineColor = color
							hl.FillTransparency = 0.5

							local bgui = Instance.new("BillboardGui", EspFolderMM2)
							bgui.Adornee = p.Character.Head
							bgui.Size = UDim2.new(0, 100, 0, 50)
							bgui.StudsOffset = Vector3.new(0, 2.5, 0)
							bgui.AlwaysOnTop = true

							local txt = Instance.new("TextLabel", bgui)
							txt.Size = UDim2.new(1, 0, 1, 0)
							txt.BackgroundTransparency = 1
							txt.TextColor3 = color
							txt.Font = Enum.Font.GothamBold
							txt.TextSize = 16
							txt.Text = role
						end
					end
				end
				task.wait(1)
			end
		end)
	else
		EspMM2Btn.TextColor3 = COLOR_TEXT
		EspFolderMM2:ClearAllChildren()
	end
end)

local CoinEspBtn = CreateButton("ESP Moedas (MM2 Coins)", Tabs.Murder)
CoinEspBtn.MouseButton1Click:Connect(function()
	espCoins = not espCoins
	if espCoins then
		CoinEspBtn.TextColor3 = COLOR_PURPLE
		task.spawn(function()
			while espCoins do
				EspFolderCoins:ClearAllChildren()
				for _, obj in pairs(Workspace:GetDescendants()) do
					if obj:IsA("BasePart") and (obj.Name == "Coin_Server" or obj.Name == "Coin" or obj.Name == "CoinContainer") then
						local hl = Instance.new("Highlight", EspFolderCoins)
						hl.Adornee = obj
						hl.FillColor = Color3.fromRGB(255, 215, 0)
						hl.OutlineColor = Color3.fromRGB(255, 255, 255)
						hl.FillTransparency = 0.3
					end
				end
				task.wait(2)
			end
		end)
	else
		CoinEspBtn.TextColor3 = COLOR_TEXT
		EspFolderCoins:ClearAllChildren()
	end
end)

local HitboxBtn = CreateButton("Ver Hitboxes (Expandidas)", Tabs.Murder)
HitboxBtn.MouseButton1Click:Connect(function()
	showHitboxes = not showHitboxes
	if showHitboxes then
		HitboxBtn.TextColor3 = COLOR_PURPLE
		task.spawn(function()
			while showHitboxes do
				HitboxFolder:ClearAllChildren()
				for _, p in pairs(Players:GetPlayers()) do
					if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
						local box = Instance.new("BoxHandleAdornment")
						box.Adornee = p.Character.HumanoidRootPart
						box.Size = Vector3.new(3, 4, 3)
						box.Color3 = Color3.fromRGB(255, 0, 0)
						box.Transparency = 0.6
						box.AlwaysOnTop = true
						box.ZIndex = 1
						box.Parent = HitboxFolder
					end
				end
				task.wait(0.5)
			end
		end)
	else
		HitboxBtn.TextColor3 = COLOR_TEXT
		HitboxFolder:ClearAllChildren()
	end
end)

local AutoGunBtn = CreateButton("Auto TP para Arma (Sherife Morto)", Tabs.Murder)
AutoGunBtn.MouseButton1Click:Connect(function()
	autoTpGun = not autoTpGun
	if autoTpGun then
		AutoGunBtn.TextColor3 = COLOR_PURPLE
		task.spawn(function()
			while autoTpGun do
				task.wait(0.1)
				local gunDrop = Workspace:FindFirstChild("GunDrop")
				if gunDrop and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
					Player.Character.HumanoidRootPart.CFrame = gunDrop.CFrame
					task.wait(1)
				end
			end
		end)
	else
		AutoGunBtn.TextColor3 = COLOR_TEXT
	end
end)

-- ==========================================
-- ABA 3: JAILBREAK
-- ==========================================
local EspJBBtn = CreateButton("Ativar ESP (Policiais/Ladrões)", Tabs.Jailbreak)
EspJBBtn.MouseButton1Click:Connect(function()
	espJB = not espJB
	if espJB then
		EspJBBtn.TextColor3 = COLOR_PURPLE
		task.spawn(function()
			while espJB do
				EspFolderJB:ClearAllChildren()
				for _, p in pairs(Players:GetPlayers()) do
					if p ~= Player and p.Character and p.Character:FindFirstChild("Head") and p.Team then
						local tName = p.Team.Name:lower()
						local role, color = nil, nil
						
						if tName:find("police") or tName:find("guard") then
							role = "POLICIAL"
							color = Color3.fromRGB(0, 150, 255)
						elseif tName:find("criminal") then
							role = "CRIMINOSO"
							color = Color3.fromRGB(255, 0, 0)
						elseif tName:find("prisoner") then
							role = "PRISIONEIRO"
							color = Color3.fromRGB(255, 120, 0)
						end
						
						if role then
							local hl = Instance.new("Highlight", EspFolderJB)
							hl.Adornee = p.Character
							hl.FillColor = color
							hl.OutlineColor = color
							hl.FillTransparency = 0.5

							local bgui = Instance.new("BillboardGui", EspFolderJB)
							bgui.Adornee = p.Character.Head
							bgui.Size = UDim2.new(0, 100, 0, 50)
							bgui.StudsOffset = Vector3.new(0, 2.5, 0)
							bgui.AlwaysOnTop = true

							local txt = Instance.new("TextLabel", bgui)
							txt.Size = UDim2.new(1, 0, 1, 0)
							txt.BackgroundTransparency = 1
							txt.TextColor3 = color
							txt.Font = Enum.Font.GothamBold
							txt.TextSize = 16
							txt.Text = role
						end
					end
				end
				task.wait(1)
			end
		end)
	else
		EspJBBtn.TextColor3 = COLOR_TEXT
		EspFolderJB:ClearAllChildren()
	end
end)

-- ==========================================
-- LÓGICA DE FECHAMENTO GLOBAL
-- ==========================================
CloseBtn.MouseButton1Click:Connect(function()
	if noclipConnection then noclipConnection:Disconnect() end
	if flyConnection then flyConnection:Disconnect() end
	if speedConnection then speedConnection:Disconnect() end

	if flying then
		if bg then bg:Destroy() end
		if bv then bv:Destroy() end
		if Player.Character and Player.Character:FindFirstChild("Humanoid") then
			Player.Character.Humanoid.PlatformStand = false
		end
	end

	if flinging and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
		if Player.Character.HumanoidRootPart:FindFirstChild("FlingSpin") then
			Player.Character.HumanoidRootPart.FlingSpin:Destroy()
		end
	end

	if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
		Player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
	end

	espMM2 = false
	espCoins = false
	showHitboxes = false
	autoTpGun = false
	espJB = false

	EspFolderMM2:Destroy()
	EspFolderCoins:Destroy()
	HitboxFolder:Destroy()
	EspFolderJB:Destroy()
	ScreenGui:Destroy()
end)

print("Waifu Hub V8 Carregado com Sucesso!")
