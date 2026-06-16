local ClientModules = script.Parent
local Controllers = {}

for _, module in ipairs(ClientModules:GetChildren()) do
	if module:IsA("ModuleScript") then
		Controllers[module.Name] = require(module)
	end
end

for _, controller in pairs(Controllers) do
	if type(controller.Init) == "function" then
		controller:Init()
	end
end

for _, controller in pairs(Controllers) do
	if type(controller.Start) == "function" then
		task.spawn(function()
			controller:Start()
		end)
	end
end
