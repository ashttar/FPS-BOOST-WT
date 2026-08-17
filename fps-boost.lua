-- Check for table that is shared between executions.
if not shared then
	return warn("No shared, no script.")
end

-- Initialize Luraph globals if they do not exist.
loadstring("getfenv().LPH_NO_VIRTUALIZE = function(...) return ... end")()

-- Services.
local lightingService = game:GetService("Lighting")
local playersService = game:GetService("Players")
local workspaceService = game:GetService("Workspace")

-- State.
local localPlayer = playersService.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Constants.
local GRAY_COLOR = Color3.fromRGB(128, 128, 128)

-- Classes to destroy completely (Fire & Particle Effects)
local FIRE_CLASSES = {
	"Fire",
	"Smoke",
	"ParticleEmitter",
	"Sparkles"
}

-- Keywords to make invisible (Transparency = 1, Keeping Collision)
local TARGET_KEYWORDS = {
	"grass",
	"sandstone building",
	"sandstone_buildings",
	"cacti",
	"streetlight",
	"street lights",
	"planter",
	"rubble pile",
	"rubblepilerealistic",
	"metroseats",
	"bins",
	"oil barrel",
	"box asset",
	"gas pump",
	"awning_stand_g",
	"hedgehogs",
	"traffic_light",
	"metal table",
	"grass cliff tall1",
	"grass_rock",
	"cactus1",
	"large oil",
	"signage",
	"lasers",
	"warehouse oil barrel",
	"flagpole",
	"awningstand",
	"trees/flora",
	"palm tree",
	"unmanned systems control center",
	"helicopter operations",
	"pilot stand 2",
	"oil derrick start",
	"oil derrick oil",
	"oil derrick machine 1",
	"oil derrick machine 2",
	"ff1",
	"ff2",
	"small gate 3",
	"small gate 5",
	"small gate 1",
	"small gate 2",
	"hovercraft gate",
	"small gate",
	"armored gate",
	"tank building gate",
	"base solar panels",
	"cameras",
	"base shield",
	"shield",
	"unpurchasedbuttons",
	"lab repair station frame",
	"factory solar panels 2",
	"factory solar panels 1",
	"factory",
	"sand cliff1",
	"sand cliff2",
	"sand",
	"crane",
	"docks",
	"metro stations",
	"tree decor",
	"retail park",
	"uav control door",
	"ugv control center",
	"ugv control door",
	"unmanned systems operations",
	"drone spawner",
	"premium land upgrade 2",
	"partcrate"
}

---Check if an instance is a non-player character.
---@param instance Instance
---@return boolean
local function isNpc(instance)
	if not instance:IsA("Model") then
		return false
	end

	local humanoid = instance:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end

	local player = playersService:GetPlayerFromCharacter(instance)
	return player == nil
end

---Check if instance is a fire or particle effect.
---@param instance Instance
---@return boolean
local function isFireEffect(instance)
	for _, className in ipairs(FIRE_CLASSES) do
		if instance:IsA(className) then
			return true
		end
	end

	local lowerName = instance.Name:lower()
	if string.find(lowerName, "fire", 1, true) or string.find(lowerName, "flame", 1, true) or string.find(lowerName, "burn", 1, true) then
		return true
	end

	return false
end

---Check if an instance matches target keywords.
---@param instance Instance
---@return boolean
local function matchesKeywords(instance)
	local lowerName = instance.Name:lower()
	for _, keyword in ipairs(TARGET_KEYWORDS) do
		if string.find(lowerName, keyword, 1, true) then
			return true
		end
	end
	return false
end

---Make instance invisible without altering collision.
---@param instance Instance
local function makeInvisible(instance)
	pcall(function()
		if instance:IsA("BasePart") then
			instance.Transparency = 1
		elseif instance:IsA("Decal") or instance:IsA("Texture") then
			instance.Transparency = 1
		end

		for _, descendant in ipairs(instance:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Transparency = 1
			elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
				descendant.Transparency = 1
			elseif isFireEffect(descendant) then
				descendant:Destroy()
			end
		end
	end)
end

---Safely process target workspace instance.
---@param instance Instance
local function processWorkspaceInstance(instance)
	if isFireEffect(instance) then
		pcall(function()
			instance:Destroy()
		end)
		return
	end

	if isNpc(instance) or matchesKeywords(instance) then
		makeInvisible(instance)
	end
end

---Enforce gray sky settings and lock them.
local function enforceGraySky()
	pcall(function()
		lightingService.Ambient = GRAY_COLOR
		lightingService.OutdoorAmbient = GRAY_COLOR
		lightingService.FogColor = GRAY_COLOR

		-- Remove sky texture layers & atmosphere if present
		for _, child in ipairs(lightingService:GetChildren()) do
			if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("ColorCorrectionEffect") or child:IsA("BlurEffect") then
				child:Destroy()
			end
		end

		-- Create a solid gray skybox
		local graySky = lightingService:FindFirstChild("LockedGraySky")
		if not graySky then
			graySky = Instance.new("Sky")
			graySky.Name = "LockedGraySky"
			graySky.SkyboxBk = ""
			graySky.SkyboxDn = ""
			graySky.SkyboxFt = ""
			graySky.SkyboxLf = ""
			graySky.SkyboxRt = ""
			graySky.SkyboxUp = ""
			graySky.SunTextureId = ""
			graySky.MoonTextureId = ""
			graySky.Parent = lightingService
		end
	end)
end

---Remove unwanted lighting effects.
---@param child Instance
local function removeLightingEffects(child)
	if child.Name == "LockedGraySky" then
		return
	end

	local lowerName = child.Name:lower()
	if child:IsA("ColorCorrectionEffect")
		or child:IsA("BlurEffect")
		or child:IsA("Atmosphere")
		or child:IsA("Sky")
		or string.find(lowerName, "colorcorrection", 1, true)
		or string.find(lowerName, "blur", 1, true)
		or string.find(lowerName, "atmosphere", 1, true) then
		pcall(function()
			child:Destroy()
		end)
	end

	enforceGraySky()
end

---Remove OxygenBar from PlayerGui.
---@param descendant Instance
local function checkAndDestroyOxygenBar(descendant)
	if descendant.Name == "OxygenBar" then
		pcall(function()
			descendant:Destroy()
		end)
	end
end

-- Process current workspace descendants.
for _, descendant in ipairs(workspaceService:GetDescendants()) do
	processWorkspaceInstance(descendant)
end
workspaceService.DescendantAdded:Connect(processWorkspaceInstance)

-- Enforce Gray Sky & process lighting.
enforceGraySky()
for _, child in ipairs(lightingService:GetChildren()) do
	removeLightingEffects(child)
end
lightingService.ChildAdded:Connect(removeLightingEffects)
lightingService.Changed:Connect(enforceGraySky)

-- Process OxygenBar in PlayerGui.
for _, descendant in ipairs(playerGui:GetDescendants()) do
	checkAndDestroyOxygenBar(descendant)
end
playerGui.DescendantAdded:Connect(checkAndDestroyOxygenBar)
