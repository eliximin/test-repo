local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SandyRE = ReplicatedStorage:WaitForChild("Sandevistan")

local ActiveSandyPlayers = {}
local Cooldowns = {}

local SandyDuration = 35
local SandyCooldown = 5

SandyRE.OnServerEvent:Connect(function(Player, RequestState)
	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

	if RequestState == true then
		if Cooldowns[Player] or ActiveSandyPlayers[Player] then return end
		if not Humanoid then return end

		ActiveSandyPlayers[Player] = true
		Humanoid.WalkSpeed = 60
		SandyRE:FireAllClients(Player, true, 60)

		task.delay(SandyDuration, function()
			if ActiveSandyPlayers[Player] then
				ActiveSandyPlayers[Player] = nil
				if Humanoid and Humanoid.Parent then Humanoid.WalkSpeed = 16 end
				SandyRE:FireAllClients(Player, false, 60)

				Cooldowns[Player] = true
				task.wait(SandyCooldown)
				Cooldowns[Player] = nil
			end
		end)
	else
		if ActiveSandyPlayers[Player] then
			ActiveSandyPlayers[Player] = nil
			if Humanoid then Humanoid.WalkSpeed = 16 end
			SandyRE:FireAllClients(Player, false, 60)

			Cooldowns[Player] = true
			task.wait(SandyCooldown)
			Cooldowns[Player] = nil
		end
	end
end)

Players.PlayerRemoving:Connect(function(Player)
	ActiveSandyPlayers[Player] = nil
	Cooldowns[Player] = nil
end)