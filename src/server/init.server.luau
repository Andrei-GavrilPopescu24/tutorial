print("Trace: ClickService Init")
local ServerModules = script

local Services = {}

-- Phase 1: Require all modules
for _, module in ipairs(ServerModules:GetChildren()) do
	if module:IsA("ModuleScript") then
		Services[module.Name] = require(module)
	end
end

-- Phase 2: Initialize (Setup events, properties)
for _, service in pairs(Services) do
	if type(service.Init) == "function" then
		service:Init()
	end
end

-- Phase 3: Start (Connect listeners, execute logic)
for _, service in pairs(Services) do
	if type(service.Start) == "function" then
		task.spawn(function()
			service:Start()
		end)
	end
end
