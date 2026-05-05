local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local inputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local stomping = false
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")
local kickAnimation = Instance.new("Animation")
local earthbendEvent = ReplicatedStorage:WaitForChild("Earthbending")
kickAnimation.AnimationId = "rbxassetid://100302933540097"
local kickAnimationTrack = animator:LoadAnimation(kickAnimation)

local stompSFX = Game:GetService("SoundService"):WaitForChild("Stomp")

inputService.InputBegan:Connect(function(input, proAtChess)
	if input.KeyCode == Enum.KeyCode.V and not proAtChess and not stomping then 
		stomping = true
		kickAnimationTrack:Play()
		task.wait(0.6)
		stompSFX:Play()
		earthbendEvent:FireServer(player, "wall")
		task.wait(0.8)
		stomping = false
	end
end)
