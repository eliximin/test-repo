local ReplicatedStorage = game:GetService("ReplicatedStorage")
local earthbendEvent = ReplicatedStorage:WaitForChild("Earthbending")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local getPartFromBelowParams = RaycastParams.new()
getPartFromBelowParams.FilterType = Enum.RaycastFilterType.Exclude

local CoupleGoals = {Size=Vector3.new(range, range, range)}

local function getPlayers()
	local characters = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(characters, player.Character)
		end
	end
	return characters	
end


local upGoesTheWall = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local downGoesTheWall = TweenInfo.new(0.9, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local slamGoesTheWall = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

earthbendEvent.OnServerEvent:Connect(function(player, technique)
	print(`Received {technique}!`)
	local character = player.Character
	getPartFromBelowParams.FilterDescendantsInstances = {getPlayers()}

	local ground = workspace:Raycast(character:GetPivot().Position, Vector3.new(0, -6, 0), getPartFromBelowParams)
	if not ground then print("No ground!") return end
	print(`{ground.Instance.Name} {ground.Instance.Material}`)
	
	local wallPart = Instance.new("Part")
	wallPart.Size = Vector3.new(4, 0.1, 0.7)
	wallPart.Anchored = true
	wallPart.Material = ground.Instance.Material
	wallPart.Color = ground.Instance.Color
	wallPart.CFrame = player.Character:FindFirstChild("HumanoidRootPart").CFrame * CFrame.new(0, -6, -4)
	wallPart.Parent = workspace

	
	local riseTween = TweenService:Create(wallPart, upGoesTheWall, {Size=Vector3.new(4, 8, 0.7), Position=wallPart.Position + Vector3.new(0, 6, 0)})
	local fallTween = TweenService:Create(wallPart, downGoesTheWall, {Size=Vector3.new(4, 0.1, 0.7), Position=wallPart.Position + Vector3.new(0, -6, 0)})
	riseTween:Play()
	
	task.wait(0.9)
	
	local slamTween = TweenService:Create(wallPart, slamGoesTheWall, {Orientation=wallPart.Orientation + Vector3.new(-90, 0, 0),Position=wallPart.CFrame * Vector3.new(0, -2, 0)})
	-- slamTween:Play() disabled coz i need weld constraints
	
	task.delay(8, function()
		fallTween:Play()
		wait(0.8)
		wallPart:Destroy()
	end)
end)
	
	