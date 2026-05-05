local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TSEvent = ReplicatedStorage.TimeStop
local inputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")

local fastTween = TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local slowTween = TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

local soundService = game:GetService("SoundService")

local globalTimeStopCD = false

-- Dict that has userid as index and cooldown as value
local cooldownList = {}
-- Initializes time-stop related sounds.
local function initSounds(player)

	
	return stopTime, resumeTime
end


local function stopTime(parts)

end

TSEvent.OnServerEvent:Connect(function(player, pos, parts, dur, range)
	if globalTimeStopCD == true then return end
	globalTimeStopCD = true
	task.delay(dur + 1, function()
		globalTimeStopCD = false
	end)
	
	timeStopped = soundService:WaitForChild("TimeStopStart", 5)
	timeStopped.Name = "TimeStopStart"
	timeStopped.SoundId = "rbxassetid://139589191046133"
	timeStopped.Volume = 0.3
	timeStopped.Parent = soundService

	timeResumed = soundService:WaitForChild("TimeStopEnd", 5)
	timeResumed.Name = "TimeStopEnd"
	timeResumed.SoundId = "rbxassetid://119512674229989"
	timeResumed.Volume = 0.3
	timeResumed.Parent = soundService
	
	task.delay(dur - 1, function()
		timeResumed:Play()
	end)
	
	print("Stopping time")
	timeStopped.TimePosition = 0.37
	timeStopped:Play()
	
	local bubble = ReplicatedStorage:WaitForChild("InversionSpiel", 5):Clone()
	bubble.Parent = workspace
	bubble.CFrame = CFrame.new(pos)
	bubble.Size = Vector3.new(1, 1, 1)
	
	local CoupleGoals = {Size=Vector3.new(range, range, range)}
	local CoupleGoals2 = {Size=Vector3.new(0.1, 0.1, 0.1)}

	tweened = tweenService:Create(bubble, fastTween, CoupleGoals)
	untweened = tweenService:Create(bubble, slowTween, CoupleGoals2)
	print("Defined tweened")
	task.delay(dur-0.3, function()
		untweened:Play()
		task.wait(0.8)
		bubble:Destroy()
	end)
	tweened:Play()
	print("Playing tween")
	
	for _, part in ipairs(parts) do
		part.Anchored = true
		task.delay(dur, function()
			part.Anchored = false
			print("freez")
		end)
	end
end)
