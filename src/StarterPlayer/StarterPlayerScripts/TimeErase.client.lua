local UIs = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local Event = ReplicatedStorage:WaitForChild("TimeErase")
local TauntEvent = ReplicatedStorage:WaitForChild("TauntEvent")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local IsErasing = false
local TauntCooldown = false
local ShakeConnection
local SkyRotationConnection
local VictimLoop
local AfterimageConnection
local CollisionConnection
local TimeFrozen = {}
local AfterimageTimers = {}
local HighlightedParts = {}
local BorderLoop
local OutsiderLoop
local CenterPosition = nil
local TimeEraseRadius = 100
local ActiveBubble = nil
local InitialSkyRotation = Vector3.new(0, 0, 0)
local LineSpawningConnection
local CurrentStartSound
local CurrentActiveSound

local SoundIDs = {
	Start = "rbxassetid://138406944410156",
	Active = "rbxassetid://133669116018154",
	End = "rbxassetid://80787231220458"
}

LocalPlayer:SetAttribute("CurrentSensitivity", 0.5)

local function ApplyEnvironmentHighlight(part)
	if not part or not part:IsA("BasePart") then return end
	if part:IsA("Terrain") then return end
	if part:FindFirstChild("KC_Highlight") then return end

	local Box = Instance.new("SelectionBox")
	Box.Name = "KC_Highlight"
	Box.Adornee = part
	Box.Color3 = Color3.fromRGB(255, 0, 0)
	Box.LineThickness = 0.04
	Box.SurfaceColor3 = Color3.fromRGB(255, 0, 0)
	Box.SurfaceTransparency = 1
	Box.Parent = part

	table.insert(HighlightedParts, Box)
end

local function ClearHighlights()
	for _, h in ipairs(HighlightedParts) do
		if h and h.Parent then
			h:Destroy()
		end
	end
	HighlightedParts = {}
end

local function ScreenShake(Intensity, Duration)
	local StartTime = tick()
	if ShakeConnection then ShakeConnection:Disconnect() end
	ShakeConnection = RunService.RenderStepped:Connect(function()
		local Elapsed = tick() - StartTime
		if Elapsed < Duration then
			local ShakeOffset = Vector3.new(math.random(-Intensity, Intensity), math.random(-Intensity, Intensity), math.random(-Intensity, Intensity)) / 10
			Camera.CFrame = Camera.CFrame * CFrame.new(ShakeOffset)
		else
			ShakeConnection:Disconnect()
		end
	end)
end

local function GetChar()
	return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function CreateAfterimage(Character)
	if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end

	local LastTime = AfterimageTimers[Character.Name] or 0
	if tick() - LastTime < 0.7 then return end 
	AfterimageTimers[Character.Name] = tick()

	local LifeTime = 4 -- afterimage lifetime
	for _, Part in ipairs(Character:GetDescendants()) do
		if Part:IsA("BasePart") and Part.Transparency < 1 and Part.Name ~= "HumanoidRootPart" then
			local AfterImage = Instance.new("Part")
			AfterImage.Size = Part.Size
			AfterImage.CFrame = Part.CFrame
			AfterImage.CanCollide = false
			AfterImage.CanQuery = false
			AfterImage.Anchored = true
			AfterImage.Material = Enum.Material.ForceField
			AfterImage.Color = Color3.fromRGB(255, 0, 0)
			AfterImage.Parent = workspace

			local Tween = TweenService:Create(AfterImage, TweenInfo.new(LifeTime), {Transparency = 1})
			Tween:Play()

			Debris:AddItem(AfterImage, LifeTime)
		end
	end
end

local function PlayTaunt()
	if TauntCooldown then return end
	TauntCooldown = true
	TauntEvent:FireServer()
	task.wait(3)
	TauntCooldown = false
end

local function SetupSounds()
	local sStart = Instance.new("Sound")
	sStart.Name = "TE_Start"
	sStart.SoundId = SoundIDs.Start
	sStart.Volume = 1
	sStart.Parent = SoundService
	local sActive = Instance.new("Sound")
	sActive.Name = "TE_Active"
	sActive.SoundId = SoundIDs.Active
	sActive.Looped = true
	sActive.Volume = 0.8
	sActive.Parent = SoundService
	return sStart, sActive
end

local function SpawnGlitchLine(Origin, Range)
	local GlitchColors = {
		Color3.fromRGB(255, 0, 0), -- red   
		Color3.fromRGB(0, 255, 255), -- cyan
		Color3.fromRGB(255, 255, 255), -- white
		Color3.fromRGB(0, 255, 0), -- green
		Color3.fromRGB(255, 255, 0) -- yellow
	}

	local Axis = math.random(1, 3)
	local StartPos = Origin + Vector3.new(
		math.random(-Range, Range),
		math.random(-Range, Range),
		math.random(-Range, Range)
	)

	local p = Instance.new("Part")
	p.Name = "GlitchLine"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Material = Enum.Material.Neon
	p.Color = GlitchColors[math.random(1, #GlitchColors)]
	p.Transparency = 0
	p.Parent = workspace

	local Length = math.random(60, 150)
	local Thick = 0.08
	local Speed = math.random(0.8, 1)

	if Axis == 1 then
		p.Size = Vector3.new(Length, Thick, Thick)
		p.Position = StartPos - Vector3.new(Range, 0, 0)
		TweenService:Create(p, TweenInfo.new(Speed, Enum.EasingStyle.Linear), {Position = p.Position + Vector3.new(Range * 2, 0, 0), Transparency = 1}):Play()
	elseif Axis == 2 then
		p.Size = Vector3.new(Thick, Length, Thick)
		p.Position = StartPos - Vector3.new(0, Range, 0)
		TweenService:Create(p, TweenInfo.new(Speed, Enum.EasingStyle.Linear), {Position = p.Position + Vector3.new(0, Range * 2, 0), Transparency = 1}):Play()
	else
		p.Size = Vector3.new(Thick, Thick, Length)
		p.Position = StartPos - Vector3.new(0, 0, Range)
		TweenService:Create(p, TweenInfo.new(Speed, Enum.EasingStyle.Linear), {Position = p.Position + Vector3.new(0, 0, Range * 2), Transparency = 1}):Play()
	end

	Debris:AddItem(p, Speed + 0.1)
end

local function TransitionVisuals(State, IsUser)
	local CC = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
	local Atmos = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
	local Sky = Lighting:FindFirstChildOfClass("Sky")
	local Bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)

	if State then
		if SkyRotationConnection then SkyRotationConnection:Disconnect() end

		if Sky then 
			InitialSkyRotation = Sky.SkyboxOrientation 
			local TargetRotSpeed = 450

			SkyRotationConnection = RunService.Heartbeat:Connect(function(dt)
				Sky.SkyboxOrientation = Sky.SkyboxOrientation + Vector3.new(0, TargetRotSpeed * dt, 0)
			end)
		end

		if LineSpawningConnection then LineSpawningConnection:Disconnect() end
		LineSpawningConnection = RunService.Heartbeat:Connect(function()
			if CenterPosition then
				for i = 1, 3 do
					SpawnGlitchLine(CenterPosition, TimeEraseRadius * 2.5)
				end
			end
		end)

		ScreenShake(12, 1.2) 
		CC.Contrast = 5
		CC.Saturation = -5
		CC.Brightness = 0.8

		Lighting.GlobalShadows = false
		Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
		Lighting.Ambient = Color3.fromRGB(200, 200, 200)

		TweenService:Create(Bloom, TweenInfo.new(0.8), {
			Intensity = 0.4, 
			Threshold = 3, 
			Size = 12
		}):Play()

		TweenService:Create(Lighting, TweenInfo.new(0.8, Enum.EasingStyle.Quart), {
			ClockTime = 0, 
			ExposureCompensation = 1.1, 
			Brightness = 2
		}):Play()

		task.spawn(function()
			task.wait(0.2)
			if IsUser then
				Atmos.Density = 0.05
				TweenService:Create(CC, TweenInfo.new(1, Enum.EasingStyle.Quart), {
					Brightness = 0.1, 
					Contrast = 2.5, 
					Saturation = 1.5,
					TintColor = Color3.fromRGB(255, 220, 220)
				}):Play()
			else
				Atmos.Density = 0.4
				Atmos.Color = Color3.fromRGB(0, 0, 0)
				TweenService:Create(CC, TweenInfo.new(1, Enum.EasingStyle.Quart), {
					Brightness = -0.05, 
					Contrast = 3, 
					Saturation = 0.8, 
					TintColor = Color3.fromRGB(255, 180, 180)
				}):Play()
			end
		end)
	else
		if LineSpawningConnection then LineSpawningConnection:Disconnect() LineSpawningConnection = nil end
		if SkyRotationConnection then SkyRotationConnection:Disconnect() SkyRotationConnection = nil end

		if Sky then 
			TweenService:Create(Sky, TweenInfo.new(1, Enum.EasingStyle.Quint), {
				SkyboxOrientation = InitialSkyRotation
			}):Play() 
		end

		ScreenShake(10, 0.8)

		TweenService:Create(Lighting, TweenInfo.new(0.8), {ClockTime = 14, ExposureCompensation = 0}):Play()
		TweenService:Create(CC, TweenInfo.new(0.5), {Saturation = -2, Brightness = -0.5, Contrast = 4}):Play()

		task.delay(0.5, function()
			TweenService:Create(CC, TweenInfo.new(0.4), {
				Brightness = 0, 
				Contrast = 0, 
				Saturation = 0, 
				TintColor = Color3.fromRGB(255, 255, 255)
			}):Play()

			Lighting.Brightness = 2
			Lighting.GlobalShadows = true
			Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
			Lighting.Ambient = Color3.fromRGB(127, 127, 127)
			Atmos.Density = 0

			if Bloom then
				TweenService:Create(Bloom, TweenInfo.new(0.5), {
					Intensity = 1, 
					Threshold = 2, 
					Size = 24
				}):Play()
			end
		end)
	end
end

local function RunUserAnchoring(State)
	local MyChar = GetChar()

	if State then
		ClearHighlights()

		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") and not v:IsDescendantOf(MyChar) then
				local IsCharacterPart = false

				for _, player in ipairs(Players:GetPlayers()) do
					if player.Character and v:IsDescendantOf(player.Character) then
						IsCharacterPart = true
						break
					end
				end

				if not IsCharacterPart then
					if v.Anchored == false then
						v.Anchored = true
						table.insert(TimeFrozen, v)
					end
					v.LocalTransparencyModifier = 0.9 -- dont tweak these or everything blows up, i need to figure out how to use highlights properly, or just switch to selection boxes
					ApplyEnvironmentHighlight(v)
				else
					v.LocalTransparencyModifier = 0 
				end
			end
		end
	else
		for _, part in ipairs(TimeFrozen) do
			if part then part.Anchored = false end
		end
		TimeFrozen = {}

		ClearHighlights()

		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") then
				v.LocalTransparencyModifier = 0
			end
		end
	end
end

local function Intangibility(State, UserChar)
	if State then
		if CollisionConnection then CollisionConnection:Disconnect() end
		CollisionConnection = RunService.Stepped:Connect(function()
			if not UserChar then CollisionConnection:Disconnect() return end
			for _, Part in ipairs(UserChar:GetDescendants()) do
				if Part:IsA("BasePart") then Part.CanCollide = false end
			end
		end)
	else
		if CollisionConnection then CollisionConnection:Disconnect() CollisionConnection = nil end
		if UserChar then
			for _, Part in ipairs(UserChar:GetDescendants()) do
				if Part:IsA("BasePart") then Part.CanCollide = true end
			end
		end
	end
end

local function RadiusBubble(State, User)
	if State then
		if ActiveBubble then ActiveBubble:Destroy() end
		local UserChar = User.Character
		if not UserChar then return end 
		local pos = UserChar:GetPivot().Position
		CenterPosition = pos

		ActiveBubble = Instance.new("Part")
		ActiveBubble.Name = "TimeErase_Shell"
		ActiveBubble.Shape = Enum.PartType.Ball
		ActiveBubble.Size = Vector3.new(1, 1, 1)
		ActiveBubble.Position = pos
		ActiveBubble.Anchored = true
		ActiveBubble.CanCollide = false
		ActiveBubble.Material = Enum.Material.ForceField
		ActiveBubble.Color = Color3.fromRGB(255, 0, 0)
		ActiveBubble.Parent = workspace

		local BubbleHighlight = Instance.new("Highlight")
		BubbleHighlight.Name = "BorderHighlight"
		BubbleHighlight.Adornee = ActiveBubble
		BubbleHighlight.FillColor = Color3.fromRGB(255, 0, 0)
		BubbleHighlight.FillTransparency = 0.98 
		BubbleHighlight.OutlineColor = Color3.fromRGB(255, 0, 0)
		BubbleHighlight.OutlineTransparency = 0.1
		BubbleHighlight.Parent = ActiveBubble

		local VoidCore = Instance.new("Part")
		VoidCore.Name = "DimensionVisual"
		VoidCore.Shape = Enum.PartType.Ball
		VoidCore.Size = Vector3.new(1, 1, 1)
		VoidCore.Position = pos
		VoidCore.Anchored = true
		VoidCore.CanCollide = false
		VoidCore.Material = Enum.Material.Neon
		VoidCore.Color = Color3.fromRGB(0, 0, 0)
		VoidCore.Parent = ActiveBubble

		local VoidMesh = Instance.new("SpecialMesh")
		VoidMesh.MeshType = Enum.MeshType.Sphere
		VoidMesh.Scale = Vector3.new(-1, -1, -1)
		VoidMesh.Parent = VoidCore

		local VoidCore2 = Instance.new("Part")
		VoidCore2.Name = "NebulaLayer"
		VoidCore2.Shape = Enum.PartType.Ball
		VoidCore2.Size = Vector3.new(0.9, 0.9, 0.9)
		VoidCore2.Position = pos
		VoidCore2.Anchored = true
		VoidCore2.CanCollide = false
		VoidCore2.Material = Enum.Material.ForceField
		VoidCore2.Color = Color3.fromRGB(255, 20, 20)
		VoidCore2.Parent = ActiveBubble

		local Void2Mesh = Instance.new("SpecialMesh")
		Void2Mesh.MeshType = Enum.MeshType.Sphere
		Void2Mesh.Scale = Vector3.new(-1.01, -1.01, -1.01)
		Void2Mesh.Parent = VoidCore2

		local sStart = Instance.new("Sound")
		sStart.SoundId = SoundIDs.Start
		sStart.Volume = 2 
		sStart.Parent = ActiveBubble
		sStart:Play()

		local Info = TweenInfo.new(0.6, Enum.EasingStyle.Quint)
		local TargetDiameter = TimeEraseRadius * 2 * 0.95
		TweenService:Create(ActiveBubble, Info, {Size = Vector3.new(TargetDiameter, TargetDiameter, TargetDiameter)}):Play()
		TweenService:Create(VoidCore, Info, {Size = Vector3.new(TargetDiameter - 0.2, TargetDiameter - 0.2, TargetDiameter - 0.2)}):Play()
		TweenService:Create(VoidCore2, Info, {Size = Vector3.new(TargetDiameter - 0.5, TargetDiameter - 0.5, TargetDiameter - 0.5)}):Play()

		task.spawn(function()
			local t = 0
			while ActiveBubble and ActiveBubble.Parent do
				t = t + 0.03
				if VoidCore2 then VoidCore2.Color = Color3.fromRGB(150 + math.sin(t) * 105, 10, 10) end
				task.wait()
			end
		end)
	else
		if ActiveBubble then
			local sEnd = Instance.new("Sound")
			sEnd.SoundId = SoundIDs.End
			sEnd.Volume = 2
			sEnd.Parent = ActiveBubble
			sEnd:Play()
			local shrinkInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back)
			for _, child in ipairs(ActiveBubble:GetChildren()) do
				if child:IsA("BasePart") then TweenService:Create(child, shrinkInfo, {Size = Vector3.new(0.1, 0.1, 0.1)}):Play() end
			end
			TweenService:Create(ActiveBubble, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {Size = ActiveBubble.Size + Vector3.new(20, 20, 20), Transparency = 1}):Play()
			Debris:AddItem(ActiveBubble, 0.5)
			ActiveBubble = nil
		end
	end
end

local function ApplyAffliction(State, IsUser, UserChar)
	local Char = GetChar()
	local Hum = Char:FindFirstChildOfClass("Humanoid")
	local Hrp = Char:FindFirstChild("HumanoidRootPart")
	IsErasing = State

	if IsUser then Intangibility(State, UserChar) end
	if VictimLoop then VictimLoop:Disconnect() VictimLoop = nil end
	if AfterimageConnection then AfterimageConnection:Disconnect() AfterimageConnection = nil end
	if BorderLoop then BorderLoop:Disconnect() BorderLoop = nil end

	if State then
		if Hrp then Hrp.AssemblyLinearVelocity = Vector3.zero end
		workspace.Gravity = IsUser and 110 or 196.2
		CurrentStartSound, CurrentActiveSound = SetupSounds()
		if CurrentStartSound then CurrentStartSound:Play() end
		if CurrentActiveSound then CurrentActiveSound:Play() end
		TransitionVisuals(true, IsUser)
		RunUserAnchoring(true)

		BorderLoop = RunService.Heartbeat:Connect(function()
			if not Hrp or not CenterPosition then return end
			local DistVector = (Hrp.Position - CenterPosition)
			local Distance = DistVector.Magnitude

			local VisualRadius = TimeEraseRadius * 0.95

			if Distance > VisualRadius + 5 then ApplyAffliction(false, IsUser, UserChar) return end
			if Distance > VisualRadius - 2 then
				local PushDir = DistVector.Unit
				Hrp.CFrame = CFrame.new(CenterPosition + (PushDir * (VisualRadius - 2)), Hrp.Position + Hrp.CFrame.LookVector)
			end
		end)

		AfterimageConnection = RunService.Heartbeat:Connect(function()
			if IsUser then 
				for _, otherPlayer in ipairs(Players:GetPlayers()) do 
					if otherPlayer ~= LocalPlayer and otherPlayer.Character then 
						CreateAfterimage(otherPlayer.Character) 
					end 
				end
			else 
				CreateAfterimage(Char) 
			end
		end)

		if not IsUser then
			LocalPlayer:SetAttribute("CurrentSensitivity", 0.07) 
			if Hum then
				Hum.AutoRotate = false
				Hum.JumpPower = 10
				Hum.JumpHeight = 2

				VictimLoop = RunService.RenderStepped:Connect(function()
					Hum.WalkSpeed = 4 
					Hum.JumpPower = 10

					if Hrp then 
						local look = Camera.CFrame.LookVector
						Hrp.CFrame = Hrp.CFrame:Lerp(CFrame.new(Hrp.Position, Hrp.Position + Vector3.new(look.X, 0, look.Z)), 0.05) 
					end
				end)
			end
		else 
			if Hum then Hum.WalkSpeed = 24 end 
		end
	else
		CenterPosition = nil
		if Hrp then 
			Hrp.AssemblyLinearVelocity = Vector3.zero 
			Hrp.AssemblyAngularVelocity = Vector3.zero 
		end

		workspace.Gravity = 196.2
		LocalPlayer:SetAttribute("CurrentSensitivity", 0.5)
		AfterimageTimers = {} 

		if CurrentStartSound then CurrentStartSound:Stop() CurrentStartSound:Destroy() end
		if CurrentActiveSound then CurrentActiveSound:Stop() CurrentActiveSound:Destroy() end

		local sEnd = Instance.new("Sound", SoundService)
		sEnd.SoundId = SoundIDs.End
		sEnd:Play()
		Debris:AddItem(sEnd, 3)

		TransitionVisuals(false, IsUser)
		RunUserAnchoring(false)

		if Hum then 
			Hum.WalkSpeed = 16 
			Hum.AutoRotate = true 
			Hum.JumpPower = 50
			Hum.JumpHeight = 7.2
		end
	end
end

Event.OnClientEvent:Connect(function(UserWhoTriggered, EraseState, InRadius)
	local isUser = (UserWhoTriggered == LocalPlayer)

	if UserWhoTriggered and UserWhoTriggered.Character then
		CenterPosition = UserWhoTriggered.Character:GetPivot().Position
	end

	RadiusBubble(EraseState, UserWhoTriggered)

	if EraseState then
		if InRadius or isUser then 
			ApplyAffliction(true, isUser, UserWhoTriggered.Character)
		else
			if OutsiderLoop then OutsiderLoop:Disconnect() OutsiderLoop = nil end
			OutsiderLoop = RunService.Heartbeat:Connect(function()
				local Hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				if Hrp and CenterPosition then
					local DistVector = Hrp.Position - CenterPosition
					local Distance = DistVector.Magnitude

					local VisualRadius = TimeEraseRadius * 0.95
					local BarrierRadius = VisualRadius + 3

					if Distance < BarrierRadius then
						local PushDir = Distance == 0 and Vector3.new(1, 0, 0) or DistVector.Unit
						Hrp.CFrame = CFrame.new(CenterPosition + (PushDir * BarrierRadius), Hrp.Position + Hrp.CFrame.LookVector)
					end
				end
			end)
		end
	else
		if OutsiderLoop then OutsiderLoop:Disconnect() OutsiderLoop = nil end
		if IsErasing then 
			ApplyAffliction(false, isUser, UserWhoTriggered.Character) 
		end
	end
end)
UIs.InputBegan:Connect(function(input, proc)
	if proc then return end
	if input.KeyCode == Enum.KeyCode.G then Event:FireServer(not IsErasing)
	elseif input.KeyCode == Enum.KeyCode.B then PlayTaunt() end
end)