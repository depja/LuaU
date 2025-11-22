local cloneref = cloneref or function(o) return o end
local httpService = cloneref(game:GetService("HttpService"))

if copyfunction and isfolder then -- fix for mobile executors :/
	local isfolder_, isfile_, listfiles_ = copyfunction(isfolder), copyfunction(isfile), copyfunction(listfiles)
	local success_, error_ = pcall(function() return isfolder_(tostring(math.random(999999999, 999999999999))) end)

	if success_ == false or (tostring(error_):match("not") and tostring(error_):match("found")) then
		getgenv().isfolder = function(folder)
			local s, data = pcall(function() return isfolder_(folder) end)
			if s == false then return nil end
			return data
		end

		getgenv().isfile = function(file)
			local s, data = pcall(function() return isfile_(file) end)
			if s == false then return nil end
			return data
		end

		getgenv().listfiles = function(folder)
			local s, data = pcall(function() return listfiles_(folder) end)
			if s == false then return {} end
			return data
		end
	end
end

local SaveManager = {}
do
	SaveManager.Folder = "Khy's Hub"
	SaveManager.Ignore = {}
	SaveManager.Parser = {
		Toggle = {
			Save = function(idx, object) return { type = "Toggle", idx = idx, value = object.Value } end,
			Load = function(idx, data)
				if getgenv().Linoria.Toggles[idx] then getgenv().Linoria.Toggles[idx]:SetValue(data.value) end
			end,
		},
		Slider = {
			Save = function(idx, object) return { type = "Slider", idx = idx, value = tostring(object.Value) } end,
			Load = function(idx, data)
				if getgenv().Linoria.Options[idx] then getgenv().Linoria.Options[idx]:SetValue(data.value) end
			end,
		},
		Dropdown = {
			Save = function(idx, object) return { type = "Dropdown", idx = idx, value = object.Value, mutli = object.Multi } end,
			Load = function(idx, data)
				if getgenv().Linoria.Options[idx] then getgenv().Linoria.Options[idx]:SetValue(data.value) end
			end,
		},
		ColorPicker = {
			Save = function(idx, object) return { type = "ColorPicker", idx = idx, value = object.Value:ToHex(), transparency = object.Transparency } end,
			Load = function(idx, data)
				if getgenv().Linoria.Options[idx] then getgenv().Linoria.Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency) end
			end,
		},
		KeyPicker = {
			Save = function(idx, object) return { type = "KeyPicker", idx = idx, mode = object.Mode, key = object.Value } end,
			Load = function(idx, data)
				if getgenv().Linoria.Options[idx] then getgenv().Linoria.Options[idx]:SetValue({ data.key, data.mode }) end
			end,
		},

		Input = {
			Save = function(idx, object) return { type = "Input", idx = idx, text = object.Value } end,
			Load = function(idx, data)
				if getgenv().Linoria.Options[idx] and type(data.text) == "string" then getgenv().Linoria.Options[idx]:SetValue(data.text) end
			end,
		},
	}
    
	function SaveManager:CheckFolderTree()
		pcall(function()
			if not isfolder(self.Folder) then -- who tought that isfolder should error when the folder is not found 😭
				SaveManager:BuildFolderTree()
				task.wait()
			end
		end)
	end

	function SaveManager:SetIgnoreIndexes(list)
		for _, key in next, list do
			self.Ignore[key] = true
		end
	end

	function SaveManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function SaveManager:Save(name)
		if not name then return false, "no config file is selected" end
		SaveManager:CheckFolderTree()

		local fullPath = self.Folder .. '/' .. name .. '.json'
		local data = {
			objects = {},
		}

		for idx, toggle in next, getgenv().Linoria.Toggles do
			if self.Ignore[idx] then continue end

			table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
		end

		for idx, option in next, getgenv().Linoria.Options do
			if not self.Parser[option.Type] then continue end
			if self.Ignore[idx] then continue end

			table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
		end

		local success, encoded = pcall(httpService.JSONEncode, httpService, data)
		if not success then return false, "failed to encode data" end

		writefile(fullPath, encoded)
		return true
	end

	function SaveManager:Load(name)
		if not name then return false, "no config file is selected" end
		SaveManager:CheckFolderTree()

		local file = self.Folder .. '/' .. name .. '.json'
		if not isfile(file) then return false, "invalid file" end

		local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
		if not success then return false, "decode error" end

		for _, option in next, decoded.objects do
			if self.Parser[option.type] then
				task.spawn(function() self.Parser[option.type].Load(option.idx, option) end) -- task.spawn() so the config loading wont get stuck.
			end
		end

		return true
	end

	function SaveManager:Delete(name)
		if not name then return false, "no config file is selected" end

		local file = self.Folder .. '/' .. name .. '.json'
		if not isfile(file) then return false, "invalid file" end

		local success, decoded = pcall(delfile, file)
		if not success then return false, "delete file error" end

		return true
	end

	function SaveManager:IgnoreThemeSettings()
		self:SetIgnoreIndexes({
			"BackgroundColor",
			"MainColor",
			"AccentColor",
			"OutlineColor",
			"FontColor", -- themes
			"ThemeManager_ThemeList",
			"ThemeManager_CustomThemeList",
			"ThemeManager_CustomThemeName", -- themes
			"VideoLink",
		})
	end

	function SaveManager:SetLibrary(library) self.Library = library end

	makefolder(SaveManager.Folder)
end

return SaveManager
