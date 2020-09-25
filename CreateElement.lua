local replicated_storage = game:GetService("ReplicatedStorage")
local Promise = require(replicated_storage:WaitForChild("Modules").Utilities.Promise)

local function returnDictionaryKV(tab, index)
	local count = 1
	local index_name

	local function loop()
		for key, value in next, tab do
			if count == index then
				return key, value
			end
			count = count + 1
		end
		return nil, nil
	end
	local result = loop() or function()
		return error(("Unable to return key in table: %s"):format(tab))
	end
	return result
end

local function safeCall(func)
	return Promise.new(function(resolve, reject)
		local success, result = xpcall(function()
			func()	
		end, function(err)
			reject(err)
		end)

		if success then
			resolve()
		end
	end)
end

local function instance_Meta(v, meta)
	meta = meta or {}
	
	return setmetatable({instance = v}, meta)
end

local element_creator = {} do

	element_creator.__index = element_creator
	
	function element_creator.New(element, parent, properties)
		properties = properties or {}

		local instance
		local self = setmetatable({

			_instance   = instance;
			_parent     = parent;
			_properties = properties;

		}, element_creator)
	
		local proxy_access = instance_Meta(tostring(nil), {
			
			__newindex = function(tab, _, value)
				local key1, _ = returnDictionaryKV(self, 1) do
					if key1 then
						rawset(self, key1, value)
					end
				end
			end
			
		})
		
		safeCall(function()
			proxy_access.instance = Instance.new(element, self._parent)

			for key, value in next, self._properties do
				proxy_access.instance[key] = value
			end
			
		end):catch(function(err)
			print(("ERROR: %s"):format(err))
		end)

		if proxy_access.instance ~= self._instance then
			self._instance = proxy_access.instance
		end

		if self and self._instance then
			return self, self._instance
		end
	end

	function element_creator:Change(property, value)
		assert(property, "A property must exist to change!")
		assert(value, "A property must be equal to a value!")
		
		safeCall(function()
			if self._instance then
				self._instance[property] = value
			end
		end):catch(function()
			print(string.format("Unable to change property of %s", self._instance.Name))
		end)
	end

	function element_creator:Delete(interval)
		interval = interval or 0
		
		if self._instance then
			if interval == 0 then
				self._instance:Destroy()
			else
				game:GetService("Debris"):AddItem(self._instance, interval)
			end
		end
	end

	function element_creator:Refresh()
		for key, value in ipairs(self._instance:GetDescendants()) do
			value:Destroy()
		end
	end
end

return element_creator
