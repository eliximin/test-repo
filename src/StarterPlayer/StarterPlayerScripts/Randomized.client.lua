local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local InputService = game:GetService("UserInputService")

local abilityList = {
	["fool"]="# Fool", 
	["magician"]="# Magician", 
	["highpriestess"]="# Priestess", 
	["empress"]="# Empress", 
	["emperor"]="# Emperor", 
	["hierophant"]="# Hierophant", 
	["lovers"]="# Lovers", 
	["chariot"]="# Chariot", 
	["strength"]="# Strength", 
	["hermit"]="Hermit #", 
	["wheel of fortune"]="Wheel of Fortune", 
	["justice"]="# Justice", 
	["hanged man"]="# Hangman", 
	["death"]="# Death", 
	["temperance"]="# Temperance", 
	["devil"]="# Devil", 
	["tower"]="# Tower", 
	["star"]="Star #", 
	["moon"]="# Moon", 
	["sun"]="# Sun", 
	["judgement"]="Judgement #", 
	["world"]="The World",
	["haze"]="# Haze",
	["mist"]="# Mist",
	["blaze"]="# Blaze",
	["radiance"]="# Radiance",
	["turkiye"]="I don't actually know"
}
-- adding colors later it'll be primary secondary tertiary going from skin, accessories, maybe accents if needed
local colorList = {
	["Red"]=Color3.fromRGB(201, 79, 63),
	["Ruby"]=Color3.fromRGB(201, 37, 25),
	["Orange"]=Color3.fromRGB(196, 100, 51),
	["Amber"]=Color3.fromRGB(231, 126, 6),
	["Yellow"]=Color3.fromRGB(171, 148, 54),
	["Topaz"]=Color3.fromRGB(231, 216, 0),
	["Green"]=Color3.fromRGB(105, 140, 79),
	["Blue"]=Color3.fromRGB(51, 105, 171),
	["Purple"]=Color3.fromRGB(106, 60, 130),
	["Platinum"]=Color3.fromRGB(164, 188, 255),
	["Silver"]=Color3.fromRGB(192, 212, 209),
	["Bronze"]=Color3.fromRGB(166, 106, 49),
	["Diamond"]=Color3.fromRGB(111, 255, 250),
	["White"]=Color3.fromRGB(255, 255, 255),
	["Violet"]=Color3.fromRGB(138, 74, 171),
	["Violent"]=Color3.fromRGB(200, 71, 49),
	["Amoral"]=Color3.fromRGB(139, 156, 171),	
	["Black"]=Color3.fromRGB(12, 12, 12),
	["Silent"]=Color3.fromRGB(67, 67, 67)
	
}

-- i'll make these more lists later prob idk o rjust have categories i dont wanna do this rn its bumming me out
local function getStand(colors, abilities)
	
	colorkeys = {}

	for k in pairs(colorList) do
		table.insert(colorkeys, k)
	end
	
	abilitykeys = {}

	for k in pairs(abilityList) do
		table.insert(abilitykeys, k)
	end
	
	color = colorkeys[math.random(1, #colorkeys)]
	colorval = colorList[color]
	
	ability = abilitykeys[math.random(1, #abilitykeys)]
	abilityval = abilityList[ability]
	
	standname = string.gsub(abilityval, "#", color)

	
	return color, ability, standname
end


InputService.InputBegan:Connect(function(input, proAtChess)
	if input.KeyCode == Enum.KeyCode.L and not proAtChess then 
		local color, ability, standname = getStand()
		print(standname)
	end
end)



