local cloneref = cloneref or function(o) return o end
local httpService = cloneref(game:GetService('HttpService'))
local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local getassetfunc = getcustomasset or getsynasset

-- Mobile Executor Polyfill (Fixes file system errors on mobile)
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

local ThemeManager = {} do
	ThemeManager.Folder = 'LinoriaLibSettings'
	-- if not isfolder(ThemeManager.Folder) then makefolder(ThemeManager.Folder) end
    
	ThemeManager.Library = nil
	ThemeManager.BuiltInThemes = {
		['Default'] 		= { 1, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"0055ff","BackgroundColor":"141414","OutlineColor":"323232"}') },
		['Dracula'] 		= { 2, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"232533","AccentColor":"6271a5","BackgroundColor":"1b1c27","OutlineColor":"7c82a7"}') },
		['Bitch Bot'] 		= { 3, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414"}') },
		['Kiriot Hub'] 		= { 4, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"30333b","AccentColor":"ffaa00","BackgroundColor":"1a1c20","OutlineColor":"141414"}') },
		['Fatality'] 		= { 5, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d"}') },
		['Quartz'] 			= { 6, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"232330","AccentColor":"426e87","BackgroundColor":"1d1b26","OutlineColor":"27232f"}') },
		['Jester'] 			= { 7, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"db4467","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		['Mint'] 			= { 8, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		['Tokyo Night'] 	= { 9, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}') },
		['Ubuntu'] 			= { 10, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"3e3e3e","AccentColor":"e2581e","BackgroundColor":"323232","OutlineColor":"191919"}') },
	}
    
	function ApplyBackgroundVideo(webmLink)
		if writefile == nil or readfile == nil or isfile == nil or not getassetfunc then return end
		if ThemeManager.Library == nil then return end
		if ThemeManager.Library.InnerVideoBackground == nil then return end

		if string.sub(tostring(webmLink), -5) == ".webm" then
			local CurrentSaved = ""
			if isfile(ThemeManager.Folder .. '/themes/currentVideoLink.txt') then
				CurrentSaved = readfile(ThemeManager.Folder .. '/themes/currentVideoLink.txt')
			end
			local VideoData = nil;
			if CurrentSaved == tostring(webmLink) then
				VideoData = {
					Success = true,
					Body = nil
				}
			else
				VideoData = httprequest({
					Url = tostring(webmLink),
					Method = 'GET'
				})
			end
			
			if (VideoData.Success) then
				if VideoData.Body then
                    writefile(ThemeManager.Folder .. '/themes/currentVideo.webm', VideoData.Body)
                    writefile(ThemeManager.Folder .. '/themes/currentVideoLink.txt', tostring(webmLink))
                end
				
                if isfile(ThemeManager.Folder .. '/themes/currentVideo.webm') then
                    local Video = getassetfunc(ThemeManager.Folder .. '/themes/currentVideo.webm')
                    ThemeManager.Library.InnerVideoBackground.Video = Video
                    ThemeManager.Library.InnerVideoBackground.Visible = true
                    ThemeManager.Library.InnerVideoBackground:Play()
                end
			end
		else
            -- If not a valid webm, hide the video
            ThemeManager.Library.InnerVideoBackground.Visible = false
        end
	end
	
	function ThemeManager:ApplyTheme(theme)
		local customThemeData = self:GetCustomTheme(theme)
		local data = customThemeData or self.BuiltInThemes[theme]

		if not data then return end

		if self.Library.InnerVideoBackground ~= nil then
			self.Library.InnerVideoBackground.Visible = false
		end
		
		local scheme = data[2]
		for idx, col in next, customThemeData or scheme do
			if idx ~= "VideoLink" then
				self.Library[idx] = Color3.fromHex(col)
				
				if getgenv().Options[idx] then
					getgenv().Options[idx]:SetValueRGB(Color3.fromHex(col))
				end
			else
				self.Library[idx] = col
				
				if getgenv().Options[idx] then
					getgenv().Options[idx]:SetValue(col)
				end
				
				ApplyBackgroundVideo(col)
			end
		end

		self:ThemeUpdate()
	end

	function ThemeManager:ThemeUpdate()
		local options = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor", "VideoLink" }
		for i, field in next, options do
			if getgenv().Options and getgenv().Options[field] then
				if field == "VideoLink" then
                    ApplyBackgroundVideo(getgenv().Options[field].Value)
                else
				    self.Library[field] = getgenv().Options[field].Value
                end
			end
		end

		self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor);
		self.Library:UpdateColorsUsingRegistry()
	end

	function ThemeManager:LoadDefault()		
		local theme = 'Default'
		local content = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt')

		local isDefault = true
		if content then
			if self.BuiltInThemes[content] then
				theme = content
			elseif self:GetCustomTheme(content) then
				theme = content
				isDefault = false;
			end
		elseif self.BuiltInThemes[self.DefaultTheme] then
		    theme = self.DefaultTheme
		end

		if isDefault then
			getgenv().Options.ThemeManager_ThemeList:SetValue(theme)
		else
			self:ApplyTheme(theme)
		end
	end

	function ThemeManager:SaveDefault(theme)
		writefile(self.Folder .. '/themes/default.txt', theme)
	end

	function ThemeManager:Delete(name)
		if (not name) then
			return false, 'no config file is selected'
		end
		
		local file = self.Folder .. '/themes/' .. name .. '.json'
		if not isfile(file) then return false, 'invalid file' end

		local success, decoded = pcall(delfile, file)
		if not success then return false, 'delete file error' end
		
		return true
	end
	
	function ThemeManager:CreateThemeManager(groupbox)
		groupbox:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor });
		groupbox:AddLabel('Main color')	:AddColorPicker('MainColor', { Default = self.Library.MainColor });
		groupbox:AddLabel('Accent color'):AddColorPicker('AccentColor', { Default = self.Library.AccentColor });
		groupbox:AddLabel('Outline color'):AddColorPicker('OutlineColor', { Default = self.Library.OutlineColor });
		groupbox:AddLabel('Font color')	:AddColorPicker('FontColor', { Default = self.Library.FontColor });
        groupbox:AddInput('VideoLink', { Text = 'Background Video (.webm)', Default = "", Placeholder = "Direct link to .webm file" })
			
		local ThemesArray = {}
		for Name, Theme in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name)
		end

		table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)

		groupbox:AddDivider()

		groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'Theme list', Values = ThemesArray, Default = 1 })
        
        groupbox:AddButton('Set as default', function()
			self:SaveDefault(getgenv().Options.ThemeManager_ThemeList.Value)
			self.Library:Notify(string.format('Set default theme to %q', getgenv().Options.ThemeManager_ThemeList.Value))
		end)

		getgenv().Options.ThemeManager_ThemeList:OnChanged(function()
			self:ApplyTheme(getgenv().Options.ThemeManager_ThemeList.Value)
		end)
        
        groupbox:AddDivider()
		groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom theme name' })
		groupbox:AddDropdown('ThemeManager_CustomThemeList', { Text = 'Custom themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
		groupbox:AddDivider()
		
		groupbox:AddButton('Save theme', function() 
			self:SaveCustomTheme(getgenv().Options.ThemeManager_CustomThemeName.Value)

			getgenv().Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			getgenv().Options.ThemeManager_CustomThemeList:SetValue(nil)
		end):AddButton('Load theme', function() 
			self:ApplyTheme(getgenv().Options.ThemeManager_CustomThemeList.Value) 
		end)

		groupbox:AddButton('Refresh list', function()
			getgenv().Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			getgenv().Options.ThemeManager_CustomThemeList:SetValue(nil)
		end)

		groupbox:AddButton('Set as default', function()
			if getgenv().Options.ThemeManager_CustomThemeList.Value ~= nil and getgenv().Options.ThemeManager_CustomThemeList.Value ~= '' then
				self:SaveDefault(getgenv().Options.ThemeManager_CustomThemeList.Value)
				self.Library:Notify(string.format('Set default theme to %q', getgenv().Options.ThemeManager_CustomThemeList.Value))
			end
		end)

		ThemeManager:LoadDefault()

		local function UpdateTheme()
			self:ThemeUpdate()
		end

		getgenv().Options.BackgroundColor:OnChanged(UpdateTheme)
		getgenv().Options.MainColor:OnChanged(UpdateTheme)
		getgenv().Options.AccentColor:OnChanged(UpdateTheme)
		getgenv().Options.OutlineColor:OnChanged(UpdateTheme)
		getgenv().Options.FontColor:OnChanged(UpdateTheme)
        getgenv().Options.VideoLink:OnChanged(UpdateTheme)
	end

	function ThemeManager:GetCustomTheme(file)
		local path = self.Folder .. '/themes/' .. file
		if not isfile(path) then
			return nil
		end

		local data = readfile(path)
		local success, decoded = pcall(httpService.JSONDecode, httpService, data)
		
		if not success then
			return nil
		end

		return decoded
	end

	function ThemeManager:SaveCustomTheme(file)
		if file:gsub(' ', '') == '' then
			return self.Library:Notify('Invalid file name for theme (empty)', 3)
		end

		local theme = {}
		local fields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor", "VideoLink" }

		for _, field in next, fields do
			if field == "VideoLink" then
				theme[field] = getgenv().Options[field].Value
			else
				theme[field] = getgenv().Options[field].Value:ToHex()
			end
		end

		writefile(self.Folder .. '/themes/' .. file .. '.json', httpService:JSONEncode(theme))
	end

	function ThemeManager:ReloadCustomThemes()
		local list = listfiles(self.Folder .. '/themes')

		local out = {}
		for i = 1, #list do
			local file = list[i]
			if file:sub(-5) == '.json' then
				local pos = file:find('.json', 1, true)
				local char = file:sub(pos, pos)

				while char ~= '/' and char ~= '\\' and char ~= '' do
					pos = pos - 1
					char = file:sub(pos, pos)
				end

				if char == '/' or char == '\\' then
					table.insert(out, file:sub(pos + 1))
				end
			end
		end

		return out
	end

	function ThemeManager:SetLibrary(lib)
		self.Library = lib
	end

	function ThemeManager:BuildFolderTree()
		local paths = {}

		local parts = self.Folder:split('/')
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, '/', 1, idx)
		end

		table.insert(paths, self.Folder .. '/themes')

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

	function ThemeManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function ThemeManager:CreateGroupBox(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		return tab:AddRightGroupbox('Themes')
	end

	function ThemeManager:ApplyToTab(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		local groupbox = self:CreateGroupBox(tab)
		self:CreateThemeManager(groupbox)
	end

	function ThemeManager:ApplyToGroupbox(groupbox)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		self:CreateThemeManager(groupbox)
	end

	ThemeManager:BuildFolderTree()
end

return ThemeManager
