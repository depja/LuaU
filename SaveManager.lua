local cloneref = cloneref or function(o) return o end
local httpService = cloneref(game:GetService("HttpService"))

-- Mobile/Executor compatibility fixes
if copyfunction and isfolder then 
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
SaveManager.Folder = "Konami Hub"
SaveManager.Ignore = {}
SaveManager.Library = nil

do
	SaveManager.Parser = {
		Toggle = {
			Save = function(idx, object) return { type = "Toggle", idx = idx, value = object.Value } end,
			Load = function(idx, data, library)
				if library.Toggles[idx] then library.Toggles[idx]:SetValue(data.value) end
			end,
		},
		Slider = {
			Save = function(idx, object) return { type = "Slider", idx = idx, value = tostring(object.Value) } end,
			Load = function(idx, data, library)
				if library.Options[idx] then library.Options[idx]:SetValue(data.value) end
			end,
		},
		Dropdown = {
			Save = function(idx, object) return { type = "Dropdown", idx = idx, value = object.Value, mutli = object.Multi } end,
			Load = function(idx, data, library)
				if library.Options[idx] then library.Options[idx]:SetValue(data.value) end
			end,
		},
		ColorPicker = {
			Save = function(idx, object) return { type = "ColorPicker", idx = idx, value = object.Value:ToHex(), transparency = object.Transparency } end,
			Load = function(idx, data, library)
				if library.Options[idx] then library.Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency) end
			end,
		},
		KeyPicker = {
			Save = function(idx, object) return { type = "KeyPicker", idx = idx, mode = object.Mode, key = object.Value } end,
			Load = function(idx, data, library)
				if library.Options[idx] then library.Options[idx]:SetValue({ data.key, data.mode }) end
			end,
		},
		Input = {
			Save = function(idx, object) return { type = "Input", idx = idx, text = object.Value } end,
			Load = function(idx, data, library)
				if library.Options[idx] and type(data.text) == "string" then library.Options[idx]:SetValue(data.text) end
			end,
		},
	}

    function SaveManager:SetLibrary(library)
        self.Library = library
        -- FIX: The UI Library uses global Toggles/Options, but doesn't put them in the Library table by default.
        -- We map them here so SaveManager can find them.
        if not self.Library.Toggles then
            self.Library.Toggles = getgenv().Toggles or {}
        end
        if not self.Library.Options then
            self.Library.Options = getgenv().Options or {}
        end
    end

	function SaveManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function SaveManager:SetIgnoreIndexes(list)
		for _, key in next, list do
			self.Ignore[key] = true
		end
	end

	function SaveManager:IgnoreThemeSettings()
		self:SetIgnoreIndexes({
			"BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor",
			"ThemeManager_ThemeList", "ThemeManager_CustomThemeList", "ThemeManager_CustomThemeName",
		})
	end

	function SaveManager:BuildFolderTree()
		local paths = {}
		local parts = self.Folder:split("/")
		local currentPath = ""
		for i, part in next, parts do
			currentPath = currentPath .. part
			table.insert(paths, currentPath)
			currentPath = currentPath .. "/"
		end

		for _, path in next, paths do
			if not isfolder(path) then
				makefolder(path)
			end
		end
	end

	function SaveManager:CheckFolderTree()
		if not isfolder(self.Folder) then
			self:BuildFolderTree()
			task.wait()
		end
	end

	function SaveManager:Save(name)
		if not name then return false, "no config file is selected" end
		self:CheckFolderTree()

		local fullPath = self.Folder .. '/' .. name .. '.json'
		local data = { objects = {} }

		if not self.Library then return false, "Library not set" end

		for idx, toggle in next, self.Library.Toggles do
			if self.Ignore[idx] then continue end
			table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
		end

		for idx, option in next, self.Library.Options do
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
		self:CheckFolderTree()

		local file = self.Folder .. '/' .. name .. '.json'
		if not isfile(file) then return false, "invalid file" end

		local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
		if not success then return false, "decode error" end

		if not self.Library then return false, "Library not set" end

		for _, option in next, decoded.objects do
			if self.Parser[option.type] then
				task.spawn(function() 
                    self.Parser[option.type].Load(option.idx, option, self.Library) 
                end)
			end
		end

		return true
	end

    function SaveManager:Delete(name)
		if not name then return false, "no config file is selected" end
		local file = self.Folder .. '/' .. name .. '.json'
		if not isfile(file) then return false, "invalid file" end
		delfile(file)
		return true
	end

    function SaveManager:RefreshConfigList()
        local list = listfiles(self.Folder)
        local out = {}
        for i = 1, #list do
            local file = list[i]
            if file:sub(-5) == ".json" then
                local pos = file:find(self.Folder, 1, true)
                if pos then
                    local name = file:sub(pos + #self.Folder + 1, -6)
                    table.insert(out, name)
                end
            end
        end
        return out
    end

    function SaveManager:BuildConfigSection(tab)
        assert(self.Library, "Must set SaveManager.Library before building config section")

        local section = tab:AddRightGroupbox('Configuration')

        section:AddInput('SaveManager_ConfigName', { Text = 'Config name' })
        section:AddDropdown('SaveManager_ConfigList', { Text = 'Config list', Values = self:RefreshConfigList(), AllowNull = true })

        section:AddDivider()

        section:AddButton('Create config', function()
            local name = self.Library.Options.SaveManager_ConfigName.Value
            if name:gsub(' ', '') == '' then return self.Library:Notify('Invalid config name (empty)', 2) end

            local success, err = self:Save(name)
            if not success then return self.Library:Notify('Failed to save config: ' .. err, 3) end

            self.Library:Notify(string.format('Created config %q', name), 2.5)
            self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            self.Library.Options.SaveManager_ConfigList:SetValue(nil)
        end)

        section:AddButton('Load config', function()
            local name = self.Library.Options.SaveManager_ConfigList.Value
            local success, err = self:Load(name)
            if not success then return self.Library:Notify('Failed to load config: ' .. err, 3) end
            self.Library:Notify(string.format('Loaded config %q', name), 2.5)
        end)

        section:AddButton('Overwrite config', function()
            local name = self.Library.Options.SaveManager_ConfigList.Value
            local success, err = self:Save(name)
            if not success then return self.Library:Notify('Failed to overwrite config: ' .. err, 3) end
            self.Library:Notify(string.format('Overwrote config %q', name), 2.5)
        end)
        
        section:AddButton('Delete config', function()
            local name = self.Library.Options.SaveManager_ConfigList.Value
            local success, err = self:Delete(name)
            if not success then return self.Library:Notify('Failed to delete config: ' .. err, 3) end
            self.Library:Notify(string.format('Deleted config %q', name), 2.5)
            self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            self.Library.Options.SaveManager_ConfigList:SetValue(nil)
        end)

        section:AddButton('Refresh list', function()
            self.Library.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            self.Library.Options.SaveManager_ConfigList:SetValue(nil)
        end)

        section:AddDivider()
        section:AddLabel('Autoload Config')
        section:AddDropdown('SaveManager_AutoloadConfig', { Text = 'Select config', Values = self:RefreshConfigList(), AllowNull = true })
        
        local autoloadFile = self.Folder .. '/autoload.txt'
        if isfile(autoloadFile) then
            local name = readfile(autoloadFile)
            self.Library.Options.SaveManager_AutoloadConfig:SetValue(name)
            task.spawn(function()
                task.wait(0.5) -- Wait for UI to load
                self:Load(name)
            end)
        end

        self.Library.Options.SaveManager_AutoloadConfig:OnChanged(function()
            local val = self.Library.Options.SaveManager_AutoloadConfig.Value
            if val == nil then 
                if isfile(autoloadFile) then delfile(autoloadFile) end
            else
                writefile(autoloadFile, val)
            end
        end)
    end

    function SaveManager:LoadAutoloadConfig()
        local autoloadFile = self.Folder .. '/autoload.txt'
        if isfile(autoloadFile) then
            local name = readfile(autoloadFile)
            self:Load(name)
        end
    end
end

return SaveManager
