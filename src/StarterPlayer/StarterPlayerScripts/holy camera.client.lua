local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Character
local RootPart 
local Head
local FakeHead
local BlurSmooth = 0
local MaxBlur = 10

-- camera settings
local FOV = 70
local DefaultSensitivity = 0.5	
local MouseLockKey = Enum.KeyCode.T 
local SensMultiplier = 0.5

-- mouse states
local MouseLocked = true
local Yaw = 0
local Pitch = 0
local LastYaw = 0
local LastPitch = 0

local Blur = Lighting:FindFirstChild("MotionBlur") or Instance.new("BlurEffect")
Blur.Name = "MotionBlur"
Blur.Size = 0
Blur.Parent = Lighting

local function SetMouseLock(Locked)
	MouseLocked = Locked
	if Locked then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
end

local function OnMouseMovement(Delta)
	if not MouseLocked then return end

	local SensAttribute = Player:GetAttribute("CurrentSensitivity")
	local CurrentSens = (SensAttribute and SensAttribute > 0) and SensAttribute or DefaultSensitivity

	local FinalMultiplier = (CurrentSens < 0.1) and 0.05 or 0.4

	Yaw = Yaw - (Delta.X * CurrentSens * FinalMultiplier)
	Pitch = math.clamp(Pitch - (Delta.Y * CurrentSens * FinalMultiplier), -89, 89)
end

local function UpdateCamera()
	if not RootPart or not Head then return end

	if Camera.CameraType ~= Enum.CameraType.Scriptable then
		Camera.CameraType = Enum.CameraType.Scriptable
	end

	local Offset = Vector3.new(0, 0.2, -0.6)
	local CameraPOS = (Head.CFrame * CFrame.new(Offset)).Position

	RootPart.CFrame = CFrame.new(RootPart.Position) * CFrame.Angles(0, math.rad(Yaw), 0)

	Camera.CFrame = CFrame.new(CameraPOS)
		* CFrame.Angles(0, math.rad(Yaw), 0)
		* CFrame.Angles(math.rad(Pitch), 0, 0)
end

local function HidePlayerBody()
	if not Character then return end

	for _, part in ipairs(Character:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name == "Head" then
				part.LocalTransparencyModifier = 1
			elseif part.Name ~= "HumanoidRootPart" then
				part.LocalTransparencyModifier = 0
			end
		end
	end

	for _, item in ipairs(Character:GetChildren()) do
		if item:IsA("Accessory") then
			local handle = item:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				handle.LocalTransparencyModifier = 1
			end
		end
	end
end

local function CreateFakeHead()
	if not Character then return end 
	local realHead = Character:FindFirstChild("Head")
	if not realHead then return end

	if FakeHead then FakeHead:Destroy() end

	FakeHead = Instance.new("Part")
	FakeHead.Name = "FakeHead"
	FakeHead.Size = realHead.Size
	FakeHead.Transparency = 0
	FakeHead.Color = Color3.new(0, 0, 0)
	FakeHead.Material = Enum.Material.SmoothPlastic
	FakeHead.CanCollide = false
	FakeHead.CastShadow = true
	FakeHead.Anchored = false

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = realHead
	weld.Part1 = FakeHead
	weld.Parent = realHead

	FakeHead.CFrame = realHead.CFrame
	FakeHead.Parent = realHead
	realHead.LocalTransparencyModifier = 1
end

UserInputService.InputChanged:Connect(function(input, proc)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		OnMouseMovement(input.Delta)
	end
end)

UserInputService.InputBegan:Connect(function(input, proc)
	if proc then return end
	if input.KeyCode == MouseLockKey then
		SetMouseLock(not MouseLocked)
	end
end)

RunService.RenderStepped:Connect(function()
	UpdateCamera()
	HidePlayerBody()

	local Delta = Vector2.new(math.abs(Yaw - LastYaw), math.abs(Pitch - LastPitch))
	LastYaw, LastPitch = Yaw, Pitch
	local TargetBlur = math.clamp(Delta.Magnitude * 20, 0, MaxBlur)
	BlurSmooth = BlurSmooth + (TargetBlur - BlurSmooth) * 0.1
	Blur.Size = BlurSmooth
end)

local function FullSetup(Char)
	Character = Char
	RootPart = Char:WaitForChild("HumanoidRootPart")
	Head = Char:WaitForChild("Head")

	task.wait(0.2) 

	Camera.CameraType = Enum.CameraType.Scriptable
	Camera.FieldOfView = FOV
	Player.CameraMinZoomDistance = 0.5
	Player.CameraMaxZoomDistance = 0.5

	SetMouseLock(true)
	CreateFakeHead()
end

Player.CharacterAdded:Connect(FullSetup)
if Player.Character then task.spawn(FullSetup, Player.Character) end

task.spawn(function()
	for i = 1, 30 do
		SetMouseLock(true)
		task.wait(0.1)
	end
end)