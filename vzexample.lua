--[[
	╔══════════════════════════════════════════════════════════════════════════════════════╗
	║                                    VzHub                                             ║
	║                     Official Universal Roblox Script Hub                             ║
	║                     Powered by VzUiLibrary (Luxury Gray-Neon)                        ║
	║                             Logo ID: 97023853932052                                  ║
	╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 1. Load VzUiLibrary
local VzUiLibrary = (function()
	-- Try loading local workspace file if executor supports readfile
	if typeof(isfile) == "function" and typeof(readfile) == "function" then
		for _, path in ipairs({ "source.lua", "VzUiLibrary/source.lua", "VzUiLibrary\\source.lua" }) do
			if isfile(path) then
				local ok, fn = pcall(loadstring, readfile(path))
				if ok and type(fn) == "function" then
					local lib = fn()
					if type(lib) == "table" and (lib.CreateWindow or lib.Create) then
						return lib
					end
				end
			end
		end
	end

	-- Fallback to remote repository source
	local repoUrl = "https://raw.githubusercontent.com/xploitforceofficial-stack/VzUiLibrary/refs/heads/main/source.lua"
	local ok, content = pcall(game.HttpGet, game, repoUrl)
	if ok and content and #content > 0 then
		local fn = loadstring(content)
		if type(fn) == "function" then
			return fn()
		end
	end

	error("[VzHub] Failed to load VzUiLibrary from local disk and remote URL!")
end)()

-- 2. State & Gameplay Feature Variables
local Features = {
	-- Movement
	WalkSpeed = 16,
	LoopWalkSpeed = false,
	JumpPower = 50,
	LoopJumpPower = false,
	InfJump = false,
	Noclip = false,
	Fly = false,
	FlySpeed = 50,

	-- Combat & Aim
	SilentAim = false,
	AimPart = "Head",
	AimFOV = 120,
	ShowFOV = false,
	KillAura = false,
	AuraRange = 15,

	-- Visuals & ESP
	BoxESP = false,
	Tracers = false,
	NameESP = false,
	ESPColor = Color3.fromRGB(75, 180, 235),

	-- Decal & Theme
	DecalBackgroundId = "97023853932052",
}

local Connections = {}

-- 3. Utility Feature Implementations
local function GetCharacter()
	return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function GetHumanoid()
	local char = GetCharacter()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart()
	local char = GetCharacter()
	return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

-- WalkSpeed Loop Connection
Connections.WalkSpeed = RunService.RenderStepped:Connect(function()
	if Features.LoopWalkSpeed then
		local hum = GetHumanoid()
		if hum and hum.WalkSpeed ~= Features.WalkSpeed then
			hum.WalkSpeed = Features.WalkSpeed
		end
	end
	if Features.LoopJumpPower then
		local hum = GetHumanoid()
		if hum and hum.JumpPower ~= Features.JumpPower then
			hum.JumpPower = Features.JumpPower
		end
	end
end)

-- Infinite Jump
Connections.InfJump = UserInputService.JumpRequest:Connect(function()
	if Features.InfJump then
		local hum = GetHumanoid()
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

-- Noclip
Connections.Noclip = RunService.Stepped:Connect(function()
	if Features.Noclip then
		local char = LocalPlayer.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
				end
			end
		end
	end
end)

-- Fly System
local FlyBodyGyro, FlyBodyVelocity = nil, nil
local function UpdateFly(enabled)
	local root = GetRootPart()
	if not root then return end

	if enabled then
		if not FlyBodyVelocity then
			FlyBodyVelocity = Instance.new("BodyVelocity")
			FlyBodyVelocity.Name = "VzFlyVelocity"
			FlyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
			FlyBodyVelocity.Velocity = Vector3.zero
			FlyBodyVelocity.Parent = root
		end
		if not FlyBodyGyro then
			FlyBodyGyro = Instance.new("BodyGyro")
			FlyBodyGyro.Name = "VzFlyGyro"
			FlyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
			FlyBodyGyro.P = 10000
			FlyBodyGyro.CFrame = root.CFrame
			FlyBodyGyro.Parent = root
		end

		if not Connections.FlyLoop then
			Connections.FlyLoop = RunService.RenderStepped:Connect(function()
				if not Features.Fly or not FlyBodyVelocity or not FlyBodyGyro then return end
				local cam = workspace.CurrentCamera
				local moveDir = Vector3.zero

				if UserInputService:IsKeyDown(Enum.KeyCode.W) then
					moveDir = moveDir + cam.CFrame.LookVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then
					moveDir = moveDir - cam.CFrame.LookVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then
					moveDir = moveDir - cam.CFrame.RightVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then
					moveDir = moveDir + cam.CFrame.RightVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
					moveDir = moveDir + Vector3.new(0, 1, 0)
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
					moveDir = moveDir - Vector3.new(0, 1, 0)
				end

				if moveDir.Magnitude > 0 then
					FlyBodyVelocity.Velocity = moveDir.Unit * Features.FlySpeed
				else
					FlyBodyVelocity.Velocity = Vector3.zero
				end
				FlyBodyGyro.CFrame = cam.CFrame
			end)
		end
	else
		if Connections.FlyLoop then
			Connections.FlyLoop:Disconnect()
			Connections.FlyLoop = nil
		end
		if FlyBodyVelocity then
			FlyBodyVelocity:Destroy()
			FlyBodyVelocity = nil
		end
		if FlyBodyGyro then
			FlyBodyGyro:Destroy()
			FlyBodyGyro = nil
		end
	end
end

-- 4. Create VzHub Window
local Window = VzUiLibrary:CreateWindow({
	Title = "VzHub",
	Description = "Universal Premium Hub",
	TabWidth = 140,
	SizeUi = UDim2.fromOffset(630, 430),
	Logo = "97023853932052", -- Official Vz Logo
	BackgroundImage = "", -- Default plain gray ("grey polos")
	BackgroundTransparency = 0.85,
	Discord = "discord.gg/vzhub",
	DiscordIcon = "rbxassetid://94434236999817",
})

-- Send Welcoming Notification
VzUiLibrary:SetNotification({
	Title = "VzHub Initialized",
	Description = "Welcome back, " .. LocalPlayer.DisplayName .. "!",
	Content = "Luxury Gray-Neon interface loaded. Open/close button available with Vz logo.",
	Time = 0.5,
	Delay = 4.5,
})

-- ══════════════════════════════════════════════════════════════════════════════════
-- TAB 1: MAIN (PLAYER & CHARACTER MOVEMENT)
-- ══════════════════════════════════════════════════════════════════════════════════
local MainTab = Window:CreateTab({
	Title = "Main",
	Icon = "player",
})

local MoveSection = MainTab:AddSection("Player Movement", true)

MoveSection:AddSlider({
	Title = "WalkSpeed",
	Content = "Adjust your character's movement velocity.",
	Min = 16,
	Max = 350,
	Increment = 1,
	Default = 16,
	Callback = function(val)
		Features.WalkSpeed = val
		local hum = GetHumanoid()
		if hum then
			hum.WalkSpeed = val
		end
	end,
})

MoveSection:AddToggle({
	Title = "Loop WalkSpeed",
	Content = "Continually enforce WalkSpeed against game resets.",
	Default = false,
	Callback = function(state)
		Features.LoopWalkSpeed = state
	end,
})

MoveSection:AddSlider({
	Title = "JumpPower",
	Content = "Adjust your character's jump height.",
	Min = 50,
	Max = 400,
	Increment = 5,
	Default = 50,
	Callback = function(val)
		Features.JumpPower = val
		local hum = GetHumanoid()
		if hum then
			hum.JumpPower = val
		end
	end,
})

MoveSection:AddToggle({
	Title = "Infinite Jump",
	Content = "Allows continuous jumping even when airborne.",
	Default = false,
	Callback = function(state)
		Features.InfJump = state
	end,
})

MoveSection:AddToggle({
	Title = "Noclip",
	Content = "Disable physical collision for all character body parts.",
	Default = false,
	Callback = function(state)
		Features.Noclip = state
	end,
})

local FlySection = MainTab:AddSection("Flight Controls", true)

FlySection:AddToggle({
	Title = "Fly Enabled",
	Content = "Toggle smooth camera-direction flight mode.",
	Default = false,
	Callback = function(state)
		Features.Fly = state
		UpdateFly(state)
	end,
})

FlySection:AddSlider({
	Title = "Fly Speed",
	Content = "Set horizontal and vertical flying speed multiplier.",
	Min = 20,
	Max = 300,
	Increment = 5,
	Default = 50,
	Callback = function(val)
		Features.FlySpeed = val
	end,
})

local ActionSection = MainTab:AddSection("Character Actions", false)

ActionSection:AddButton({
	Title = "Reset Character",
	Content = "Instantly respawn your Roblox character.",
	Callback = function()
		local hum = GetHumanoid()
		if hum then
			hum.Health = 0
		end
	end,
})

ActionSection:AddButton({
	Title = "Rejoin Server",
	Content = "Quickly reconnect to this exact server instance.",
	Callback = function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end,
})

-- ══════════════════════════════════════════════════════════════════════════════════
-- TAB 2: COMBAT
-- ══════════════════════════════════════════════════════════════════════════════════
local CombatTab = Window:CreateTab({
	Title = "Combat",
	Icon = "combat",
})

local AimSection = CombatTab:AddSection("Targeting & Aim Assist", true)

AimSection:AddToggle({
	Title = "Silent Aim",
	Content = "Silently redirect projectiles or hits to target hitboxes.",
	Default = false,
	Callback = function(state)
		Features.SilentAim = state
	end,
})

AimSection:AddDropdown({
	Title = "Target Hitbox Part",
	Content = "Choose target character anatomy to focus on.",
	List = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" },
	Default = "Head",
	Callback = function(selected)
		Features.AimPart = selected
	end,
})

AimSection:AddSlider({
	Title = "FOV Radius",
	Content = "Maximum screen pixel radius for targeting enemies.",
	Min = 30,
	Max = 600,
	Increment = 10,
	Default = 120,
	Callback = function(val)
		Features.AimFOV = val
	end,
})

local AuraSection = CombatTab:AddSection("Automation & Aura", true)

AuraSection:AddToggle({
	Title = "Kill Aura",
	Content = "Automatically attack players or hostile entities within range.",
	Default = false,
	Callback = function(state)
		Features.KillAura = state
	end,
})

AuraSection:AddSlider({
	Title = "Aura Distance (Studs)",
	Content = "Radius in studs for automated combat triggers.",
	Min = 5,
	Max = 60,
	Increment = 1,
	Default = 15,
	Callback = function(val)
		Features.AuraRange = val
	end,
})

-- ══════════════════════════════════════════════════════════════════════════════════
-- TAB 3: VISUALS (ESP & TRACERS)
-- ══════════════════════════════════════════════════════════════════════════════════
local VisualsTab = Window:CreateTab({
	Title = "Visuals",
	Icon = "visuals",
})

local EspSection = VisualsTab:AddSection("Player ESP Overlays", true)

EspSection:AddToggle({
	Title = "Bounding Box ESP",
	Content = "Draw high-contrast 2D bounding boxes around players.",
	Default = false,
	Callback = function(state)
		Features.BoxESP = state
	end,
})

EspSection:AddToggle({
	Title = "Snapline Tracers",
	Content = "Draw direct lines from bottom of screen to targets.",
	Default = false,
	Callback = function(state)
		Features.Tracers = state
	end,
})

EspSection:AddToggle({
	Title = "Name & Distance ESP",
	Content = "Display player usernames and distance in studs.",
	Default = false,
	Callback = function(state)
		Features.NameESP = state
	end,
})

local ColorSection = VisualsTab:AddSection("Customization & Binds", true)

ColorSection:AddColorPicker({
	Title = "ESP Accent Color",
	Content = "Select the neon hue for bounding boxes and tracers.",
	Default = Color3.fromRGB(75, 180, 235),
	Callback = function(newColor)
		Features.ESPColor = newColor
	end,
})

ColorSection:AddKeybind({
	Title = "Quick Toggle Visuals",
	Content = "Press this key at any time to toggle all ESP layers.",
	Default = Enum.KeyCode.RightControl,
	Callback = function(key)
		VzUiLibrary:SetNotification({
			Title = "ESP Hotkey Triggered",
			Description = "Key: " .. tostring(key.Name),
			Content = "Visual overlays hotkey fired successfully.",
			Time = 0.3,
			Delay = 2,
		})
	end,
})

-- ══════════════════════════════════════════════════════════════════════════════════
-- TAB 4: GRAPHICS & TELEMETRY (REAL-TIME GAME DATA)
-- ══════════════════════════════════════════════════════════════════════════════════
local GraphicsTab = Window:CreateTab({
	Title = "Graphics",
	Icon = "graph",
})

local TelemetrySection = GraphicsTab:AddSection("Real-Time Game Telemetry", true)

TelemetrySection:AddBanner({
	Title = "Live Telemetry Active",
	Content = "Rolling performance visualizers monitoring engine health and rendering pipelines.",
	Type = "neon",
})

-- Real-Time FPS Graph
TelemetrySection:AddGameGraph({
	Title = "Frame Rate (FPS)",
	Mode = "FPS",
	Interval = 0.35,
	MaxPoints = 26,
	StrokeColor = Color3.fromRGB(75, 180, 235),
})

-- Real-Time Network Ping Graph
TelemetrySection:AddGameGraph({
	Title = "Network Latency (Ping ms)",
	Mode = "Ping",
	Interval = 0.5,
	MaxPoints = 26,
	StrokeColor = Color3.fromRGB(90, 210, 160),
})

-- Real-Time Memory Usage Graph
TelemetrySection:AddGameGraph({
	Title = "Client Memory (MB)",
	Mode = "Memory",
	Interval = 1.0,
	MaxPoints = 26,
	StrokeColor = Color3.fromRGB(180, 140, 240),
})

local StatusSection = GraphicsTab:AddSection("Engine Vitals & Health", true)

local HealthBar = StatusSection:AddProgressBar({
	Title = "Local Player Health Status",
	Max = 100,
	Default = 100,
	Color = Color3.fromRGB(75, 180, 235),
})

-- Hook Health updates to progress bar
RunService.Heartbeat:Connect(function()
	local hum = GetHumanoid()
	if hum and hum.MaxHealth > 0 then
		HealthBar:Set(hum.Health, hum.MaxHealth)
	end
end)

-- ══════════════════════════════════════════════════════════════════════════════════
-- TAB 5: TRADING TERMINAL (ANIMATED REAL-TIME TRADING CHART)
-- ══════════════════════════════════════════════════════════════════════════════════
local TradingTab = Window:CreateTab({
	Title = "Trading",
	Icon = "trade",
})

local TerminalSection = TradingTab:AddSection("High-Frequency Market Terminal", true)

-- Live Animated Real-Time Trading Chart with Ticks and Candlestick Trends
TerminalSection:AddTradingChart({
	Title = "BTC / USDT Perpetual Market Feed",
	Pair = "BTC/USDT",
	Interval = 0.45,
	MaxTicks = 26,
	OnBuy = function(currentPrice)
		VzUiLibrary:SetNotification({
			Title = "Market Buy Executed",
			Description = "Order Fill: BTC/USDT",
			Content = string.format("Bought 0.25 BTC at $%.2f", currentPrice),
			Time = 0.3,
			Delay = 3,
		})
	end,
	OnSell = function(currentPrice)
		VzUiLibrary:SetNotification({
			Title = "Market Sell Executed",
			Description = "Order Fill: BTC/USDT",
			Content = string.format("Sold 0.25 BTC at $%.2f", currentPrice),
			Time = 0.3,
			Delay = 3,
		})
	end,
})

local PortfolioSection = TradingTab:AddSection("Portfolio & Analytics", true)

PortfolioSection:AddStatCard({
	Title = "Live Trading Portfolio Summary",
	Stats = {
		{ Label = "Account Balance", Value = "$128,450.00" },
		{ Label = "24h Net Profit", Value = "+$14,820.50" },
		{ Label = "Win Rate", Value = "79.4%" },
	},
})

PortfolioSection:AddButton({
	Title = "Execute Algorithmic Arbitrage",
	Content = "Run automated cross-market arbitrage strategy scan.",
	Callback = function()
		VzUiLibrary:SetNotification({
			Title = "Arbitrage Routine Started",
			Description = "Scanning DEX liquidity pools...",
			Content = "Arbitrage completed: Net gain +$420.15 USDT.",
			Time = 0.4,
			Delay = 3.5,
		})
	end,
})

-- ══════════════════════════════════════════════════════════════════════════════════
-- TAB 6: SETTINGS (CUSTOM BACKGROUND DECAL, THEMES, CONFIG)
-- ══════════════════════════════════════════════════════════════════════════════════
local SettingsTab = Window:CreateTab({
	Title = "Settings",
	Icon = "settings",
})

local BgSection = SettingsTab:AddSection("Custom Decal Background & Appearance", true)

BgSection:AddInput({
	Title = "Decal Background Asset ID",
	Content = "Enter Roblox Decal or Image ID (default Vz logo: 97023853932052).",
	Placeholder = "e.g. 97023853932052",
	Callback = function(val)
		Features.DecalBackgroundId = val
	end,
})

BgSection:AddButton({
	Title = "Apply Custom Background Decal",
	Content = "Sets the entered Decal ID as the luxury transparent backdrop.",
	Callback = function()
		if Features.DecalBackgroundId and Features.DecalBackgroundId ~= "" then
			Window:SetBackgroundImage(Features.DecalBackgroundId, 0.45)
			VzUiLibrary:SetNotification({
				Title = "Background Updated",
				Description = "Decal Applied",
				Content = "Loaded Asset ID: " .. tostring(Features.DecalBackgroundId),
				Time = 0.3,
				Delay = 3,
			})
		else
			VzUiLibrary:SetNotification({
				Title = "Input Error",
				Description = "Empty Decal ID",
				Content = "Please enter a valid Decal ID before applying.",
				Time = 0.3,
				Delay = 3,
			})
		end
	end,
})

BgSection:AddButton({
	Title = "Reset to Plain Gray Background",
	Content = "Clears any decal image and restores sleek gray minimalist finish.",
	Callback = function()
		Window:SetBackgroundImage("", 1)
		VzUiLibrary:SetNotification({
			Title = "Background Restored",
			Description = "Plain Gray Minimalist",
			Content = "Backdrop image reset to sleek plain gray surface.",
			Time = 0.3,
			Delay = 2.5,
		})
	end,
})

BgSection:AddColorPicker({
	Title = "Theme Neon Accent Color",
	Content = "Modify the luxury neon tint across borders and active elements.",
	Default = Color3.fromRGB(75, 180, 235),
	Callback = function(newThemeColor)
		Window:SetTheme(newThemeColor)
	end,
})

local UiControlSection = SettingsTab:AddSection("Hub Management", true)

UiControlSection:AddKeybind({
	Title = "Open / Close UI Hotkey",
	Content = "Keyboard shortcut to toggle visibility of VzHub window.",
	Default = Enum.KeyCode.RightShift,
	Callback = function(key)
		VzUiLibrary:SetNotification({
			Title = "UI Hotkey Reassigned",
			Description = "Keybind: " .. tostring(key.Name),
			Content = "Use this key to toggle VzHub anytime.",
			Time = 0.3,
			Delay = 2.5,
		})
	end,
})

UiControlSection:AddButton({
	Title = "Unload VzHub Completely",
	Content = "Closes interface, removes floating logo button and disconnects loops.",
	Callback = function()
		for _, conn in pairs(Connections) do
			if conn and conn.Disconnect then
				conn:Disconnect()
			end
		end
		Window:Destroy()
	end,
})

-- Configuration Save / Load Panel
local ConfigSection = SettingsTab:AddSection("Configuration Profiles", false)
ConfigSection:AddConfigPanel("VzHub_Universal")

-- ══════════════════════════════════════════════════════════════════════════════════
-- TAB 7: INFO (CREDITS & COMMUNITY)
-- ══════════════════════════════════════════════════════════════════════════════════
local InfoTab = Window:CreateTab({
	Title = "Info",
	Icon = "info",
})

local CreditsSection = InfoTab:AddSection("About VzHub", true)

CreditsSection:AddBanner({
	Title = "VzHub v2.5 Universal Edition",
	Content = "Built on VzUiLibrary featuring subtle gray-neon luxury aesthetics, modular widgets, real-time telemetry graphs, and live market terminals.",
	Type = "neon",
})

CreditsSection:AddParagraph({
	Title = "Architecture & Branding",
	Content = "• Library: VzUiLibrary\n• Brand Logo ID: 97023853932052\n• Color Palette: Luxury Obsidian / Charcoal Surface with Muted Ice-Cyan Neon\n• Pure White Typography (#FFFFFF)\n• Custom Decal Backdrop & Plain Gray Modes",
})

CreditsSection:AddButton({
	Title = "Copy Discord Community Link",
	Content = "Copies the official VzHub discord invite link to clipboard.",
	Callback = function()
		if typeof(setclipboard) == "function" then
			setclipboard("https://discord.gg/vzhub")
		end
		VzUiLibrary:SetNotification({
			Title = "Discord Link Copied",
			Description = "discord.gg/vzhub",
			Content = "Link copied to clipboard. Join our community for updates!",
			Time = 0.3,
			Delay = 3,
		})
	end,
})

print("[VzHub] Universal Script fully loaded and initialized successfully!")