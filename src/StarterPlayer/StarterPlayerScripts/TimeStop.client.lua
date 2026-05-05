local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TSEvent = ReplicatedStorage.TimeStop
local inputService = game:GetService("UserInputService")

-- VALUES
local tsDuration = 8 -- Time stop duration in seconds
local tsRange = 120 -- Stuhds
local tsCooldown = 60 -- In Segunda Etapas

local function antiCharacterAndBasepartParameterFunctionBecauseGodLeftUs() -- So we don't get the stupid little runt charatcer BEFORE they get a character
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {workspace.Baseplate, LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()}
	
	return params
end

local function timeStopRadiusCheck(plr, radius) -- Returns player position, and parts to stop the time for
	local pos = plr.Character:GetPivot().Position
	local partsToStop = {}
	local testdict = {}
	
	local AntiBasepartParams = antiCharacterAndBasepartParameterFunctionBecauseGodLeftUs()
	
	partsInRadius = workspace:GetPartBoundsInRadius(pos, tsRange, AntiBasepartParams)
	
	for _, part in ipairs(partsInRadius) do
		if part.Parent == LocalPlayer then continue end
		if part.Anchored then continue end
		table.insert(partsToStop, part)
	end -- Main filter statenent ig
	return pos, partsToStop
end


inputService.InputBegan:Connect(function(input, proAtChess)
	if input.KeyCode == Enum.KeyCode.F and not proAtChess then
		local position, tsParts = timeStopRadiusCheck(LocalPlayer, tsRange)
		print(tsParts)
		TSEvent:FireServer(position, tsParts, tsDuration, tsRange)
		task.wait()
		
		tabler = nil
	end
end)



