local UIs = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local SandyRE = ReplicatedStorage:WaitForChild("Sandevistan")
local LocalPlayer = Players.LocalPlayer 
local Camera = workspace.CurrentCamera

local IsSandying = false
local AfterimageConnection
local CameraCheckConnection
local UserDistanceConnection
local LastClonePos = Vector3.new()
local InsideBubble = false

local StartSoundID = "rbxassetid://126506277707533"
local MiddleSoundID = "rbxassetid://125191555816807"
local EndSoundID = "rbxassetid://102751703995250"

local WalkspeedBoost = 35
local VictimSpeed = 3
local NGreen = Color3.fromRGB(150, 255, 150)
local SandyRadius = 60
local TrailLifetime = 2.0 
local CloneDistance = 3 

local CenterPosition = nil
local Bubble = nil
local ActiveSounds = {}

local function GetChar()
	return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function PlaySandySound(Name, ID, Parent, Loop)
	if ActiveSounds[Name] then ActiveSounds[Name]:Destroy() end
	local s = Instance.new("Sound")
	s.Name = Name
	s.SoundId = ID
	s.Looped = Loop or false
	s.Volume = 2
	s.RollOffMaxDistance = 150
	s.RollOffMinDistance = 10
	s.Parent = Parent
	s:Play()
	ActiveSounds[Name] = s
	if not Loop then Debris:AddItem(s, 10) end
end

local function CreateAvatarAfterimage(Character)
	if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end

	local HRP = Character.HumanoidRootPart
	local DistanceMoved = (HRP.Position - LastClonePos).Magnitude

	if HRP.AssemblyLinearVelocity.Magnitude < 5 or DistanceMoved < CloneDistance then return end

	LastClonePos = HRP.Position

	local Hue = (tick() * 0.5) % 1
	local RainbowAft = Color3.fromHSV(Hue, 0.9, 1)

	Character.Archivable = true
	local Clone = Character:Clone()
	Character.Archivable = false

	for _, obj in ipairs(Clone:GetDescendants()) do
		if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("Sound") then
			obj:Destroy()
		elseif obj:IsA("BasePart") then
			obj.Anchored = true
			obj.CanCollide = false
			obj.CastShadow = false
			obj.Transparency = 0
			obj.Color = RainbowAft

			task.delay(TrailLifetime - 0.4, function()
				if obj and obj.Parent then
					TweenService:Create(obj, TweenInfo.new(0.4), {Transparency = 1}):Play()
				end
			end)
		elseif obj:IsA("Decal") then
			obj.Transparency = 0
			task.delay(TrailLifetime - 0.4, function()
				if obj and obj.Parent then
					TweenService:Create(obj, TweenInfo.new(0.4), {Transparency = 1}):Play()
				end
			end)
		end
	end

	local hum = Clone:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end

	Clone.Parent = workspace
	Debris:AddItem(Clone, TrailLifetime)
end

local function Visuals(State, IsUser)
	local CC = Lighting:FindFirstChild("SandyCC")
	local Blur = Lighting:FindFirstChild("SandyBlur")
	local Bloom = Lighting:FindFirstChild("SandyBloom")

	if not CC then
		CC = Instance.new("ColorCorrectionEffect", Lighting)
		CC.Name = "SandyCC"
	end
	if not Blur then
		Blur = Instance.new("BlurEffect", Lighting)
		Blur.Name = "SandyBlur"
		Blur.Size = 0
	end
	if not Bloom then
		Bloom = Instance.new("BloomEffect", Lighting)
		Bloom.Name = "SandyBloom"
		Bloom.Intensity = 0
		Bloom.Size = 56
		Bloom.Threshold = 0.8
	end

	if State then
		TweenService:Create(CC, TweenInfo.new(0.2), {
			TintColor = IsUser and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(100, 200, 100),
			Saturation = 0.4, 
			Contrast = 0.6, 
			Brightness = -0.1
		}):Play()

		TweenService:Create(Blur, TweenInfo.new(0.2), {Size = IsUser and 6 or 2}):Play()
		TweenService:Create(Bloom, TweenInfo.new(0.2), {Intensity = 1.5}):Play()

		if IsUser then
			TweenService:Create(Camera, TweenInfo.new(0.4, Enum.EasingStyle.Back), {FieldOfView = 105}):Play()
		end
	else
		TweenService:Create(CC, TweenInfo.new(0.5), {
			TintColor = Color3.fromRGB(255, 255, 255),
			Saturation = 0,
			Contrast = 0,
			Brightness = 0
		}):Play()

		TweenService:Create(Blur, TweenInfo.new(0.5), {Size = 0}):Play()
		TweenService:Create(Bloom, TweenInfo.new(0.5), {Intensity = 0}):Play()
		TweenService:Create(Camera, TweenInfo.new(0.5), {FieldOfView = 70}):Play()
	end
end

local function UpdateMovementRestriction(State)
	local Char = GetChar()
	local Hum = Char:FindFirstChildOfClass("Humanoid")
	if not Hum then return end

	if State then
		Hum.WalkSpeed = VictimSpeed
		Hum.JumpPower = 0
		Hum.JumpHeight = 0
		UIs.MouseDeltaSensitivity = 0.05 
	else
		Hum.WalkSpeed = 16
		Hum.JumpPower = 50
		Hum.JumpHeight = 7.2
		UIs.MouseDeltaSensitivity = 1
	end
end

local function HandleBubble(State, User)
	if State then
		if Bubble then Bubble:Destroy() end
		local Char = User.Character
		if not Char then return end

		CenterPosition = Char:GetPivot().Position

		Bubble = Instance.new("Part")
		Bubble.Name = "SandyBubble"
		Bubble.Shape = Enum.PartType.Ball
		Bubble.Size = Vector3.new(1, 1, 1)
		Bubble.Anchored = true
		Bubble.CanCollide = false
		Bubble.CastShadow = false
		Bubble.Transparency = 0.75
		Bubble.Material = Enum.Material.ForceField 
		Bubble.Color = NGreen
		Bubble.Position = CenterPosition
		Bubble.Parent = workspace

		local ExpandInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		TweenService:Create(Bubble, ExpandInfo, {Size = Vector3.new(SandyRadius * 2, SandyRadius * 2, SandyRadius * 2)}):Play()

		if CameraCheckConnection then CameraCheckConnection:Disconnect() end

		InsideBubble = false 
		CameraCheckConnection = RunService.RenderStepped:Connect(function()
			if not Bubble or not Bubble.Parent then return end
			local CamDist = (Camera.CFrame.Position - CenterPosition).Magnitude
			local CurrentRadius = Bubble.Size.X / 2

			if CamDist <= CurrentRadius then
				if not InsideBubble then
					InsideBubble = true
					Visuals(true, User == LocalPlayer)
					if User ~= LocalPlayer then UpdateMovementRestriction(true) end
				end
			else
				if InsideBubble then
					InsideBubble = false
					Visuals(false, User == LocalPlayer)
					if User ~= LocalPlayer then UpdateMovementRestriction(false) end
				end
			end
		end)
	else
		if CameraCheckConnection then 
			CameraCheckConnection:Disconnect() 
			CameraCheckConnection = nil 
		end

		Visuals(false, User == LocalPlayer)
		UpdateMovementRestriction(false)
		InsideBubble = false

		if Bubble then
			local Shrink = TweenService:Create(Bubble, TweenInfo.new(0.4), {Size = Vector3.new(1,1,1), Transparency = 1})
			Shrink:Play()
			Debris:AddItem(Bubble, 0.4)
			Bubble = nil
		end
	end
end

local function Activate(State, IsUser, UserChar)
	local Char = GetChar()
	local Hum = Char:FindFirstChildOfClass("Humanoid")
	IsSandying = State

	if AfterimageConnection then AfterimageConnection:Disconnect() end
	if UserDistanceConnection then UserDistanceConnection:Disconnect() end

	if State then
		HandleBubble(true, Players:GetPlayerFromCharacter(UserChar))

		local SoundParent = UserChar:FindFirstChild("HumanoidRootPart") or UserChar.PrimaryPart
		if SoundParent then
			PlaySandySound("Start", StartSoundID, SoundParent)
			task.delay(0.5, function()
				if IsSandying then PlaySandySound("Loop", MiddleSoundID, SoundParent, true) end
			end)
		end

		AfterimageConnection = RunService.Heartbeat:Connect(function()
			if not IsUser then
				CreateAvatarAfterimage(UserChar)
			end
		end)

		if IsUser then
			UserDistanceConnection = RunService.Heartbeat:Connect(function()
				if UserChar and UserChar.PrimaryPart and CenterPosition then
					local dist = (UserChar.PrimaryPart.Position - CenterPosition).Magnitude
					if dist > SandyRadius then
						SandyRE:FireServer(false)
					end
				end
			end)
		end

		if IsUser and Hum then Hum.WalkSpeed = WalkspeedBoost end
	else
		HandleBubble(false, Players:GetPlayerFromCharacter(UserChar))

		local SoundParent = UserChar:FindFirstChild("HumanoidRootPart") or UserChar.PrimaryPart
		if SoundParent then
			if ActiveSounds["Loop"] then ActiveSounds["Loop"]:Stop() end
			PlaySandySound("End", EndSoundID, SoundParent)
		end

		if Hum then Hum.WalkSpeed = 16 end
		AfterimageTimer = {}
	end
end

SandyRE.OnClientEvent:Connect(function(TriggerPlayer, State, InRadius)
	local isUser = (TriggerPlayer == LocalPlayer)
	if State then
		if isUser or InRadius then
			Activate(true, isUser, TriggerPlayer.Character)
		end
	else
		Activate(false, isUser, TriggerPlayer.Character)
	end
end)

UIs.InputBegan:Connect(function(input, proc)
	if proc then return end
	if input.KeyCode == Enum.KeyCode.H then 
		SandyRE:FireServer(not IsSandying)
	end
end)