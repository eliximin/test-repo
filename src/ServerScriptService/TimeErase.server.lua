local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TimeErase = ReplicatedStorage:WaitForChild("TimeErase")
local TauntEvent = ReplicatedStorage:WaitForChild("TauntEvent")

local GlobalTimeEraseActive = false
local CurrentEraser = nil 
local Cooldowns = {} 
local TimeEraseRadius = 100 -- it's in studs

local TauntIDs = {
	"rbxassetid://127177684805011", 
	"rbxassetid://96320179546519",
	"rbxassetid://98136294551256" 
}

local MaxDuration = 26.5
local Cooldown = 20

local function BroadcastTimeErase(User, State)
	local UserChar = User.Character -- just defining the character
	if not UserChar then return end -- if you're not real KILL YOURSELF
	local UserPos = UserChar:GetPivot().Position -- Gets position wahioooo

	for _, TargetPlayer in ipairs(Players:GetPlayers()) do -- For players
		local InRadius = false -- Define radius value thingy and default to false

		if State == true then -- if they're in...
			if TargetPlayer == User then -- if the target's wait hold on im checking where it sends state
				InRadius = true 
			elseif TargetPlayer.Character then
				local Dist = (TargetPlayer.Character:GetPivot().Position - UserPos).Magnitude
				if Dist <= TimeEraseRadius then
					InRadius = true
				end
			end
		else
			InRadius = false 
		end

		TimeErase:FireClient(TargetPlayer, User, State, InRadius)
	end
end

TimeErase.OnServerEvent:Connect(function(Player, RequestedState)
	local Character = Player.Character
	if not Character then return end

	if RequestedState == true then
		if GlobalTimeEraseActive then return end

		local lastFinished = Cooldowns[Player] or 0
		if tick() - lastFinished < Cooldown then
			return 
		end

		GlobalTimeEraseActive = true
		CurrentEraser = Player

		BroadcastTimeErase(Player, true)

		task.delay(MaxDuration, function()
			if GlobalTimeEraseActive and CurrentEraser == Player then
				GlobalTimeEraseActive = false
				CurrentEraser = nil
				Cooldowns[Player] = tick() 
				BroadcastTimeErase(Player, false)
			end
		end)

	elseif RequestedState == false then
		if Player == CurrentEraser then
			GlobalTimeEraseActive = false
			CurrentEraser = nil
			Cooldowns[Player] = tick() 
			BroadcastTimeErase(Player, false)
		end
	end
end)

TauntEvent.OnServerEvent:Connect(function(Player)
	local Character = Player.Character
	local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")

	if RootPart then
		local Sound = Instance.new("Sound")
		Sound.Name = "TauntSound"
		Sound.SoundId = TauntIDs[math.random(1, #TauntIDs)]
		Sound.Volume = 1
		Sound.Parent = RootPart
		Sound:Play()

		Sound.Ended:Connect(function()
			Sound:Destroy()
		end)
	end
end)

game:GetService("Players").PlayerRemoving:Connect(function(Player)
	if Player == CurrentEraser then
		GlobalTimeEraseActive = false
		CurrentEraser = nil
		BroadcastTimeErase(Player, false)
	end
	Cooldowns[Player] = nil
end)