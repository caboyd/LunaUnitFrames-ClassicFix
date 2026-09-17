local Addon,LUF = ...

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local SML = SML or LibStub:GetLibrary("LibSharedMedia-3.0")
local ACR = LibStub("AceConfigRegistry-3.0", true)
local RC, RCminor = LibStub("LibRangeCheck-3.0")
local L = LUF.L
local oUF = LUF.oUF
local groupselectvalue, profiledb = "SOLO", {}

local ArenaAndFocusExists = not LUF.isClassic

function getRCCheckerList(unitType, inCombat)
	local noItems = LUF.db.profile.range.noItems
    if unitType == "friend" then
        return (noItems and (inCombat and RC.friendNoItemsRCInCombat or RC.friendNoItemsRC)
                        or (inCombat and RC.friendRCInCombat or RC.friendRC))
    elseif unitType == "harm" then
        return (noItems and (inCombat and RC.harmNoItemsRCInCombat or RC.harmNoItemsRC)
                        or (inCombat and RC.harmRCInCombat or RC.harmRC))
    elseif unitType == "pet" then
        return inCombat and RC.petRCInCombat or RC.petRC
    elseif unitType == "res" then
        return inCombat and RC.resRCInCombat or RC.resRC
	elseif unitType == "misc" then
        return inCombat and RC.miscRCInCombat or RC.miscRC
    end
end

function buildCheckerList(unitType, inCombat)
	RC:init()
	local RCCheckerList = getRCCheckerList(unitType, inCombat)
	local dist = LUF.db.profile.range.dist
	local lines = {}
	local found = false
	for _, entry in ipairs(RCCheckerList) do
		if entry.info and entry.range then
			local info = entry.info
			--localize the info text
			info = info:gsub("spell", STAT_CATEGORY_SPELL , 1)
			info = info:gsub("interact", UNIT_FRAME_DROPDOWN_SUBSECTION_TITLE_INTERACT, 1)
			local itemID = tonumber(info:match("item:(%d+)"))  -- extract the number
			if itemID then
				-- Classic / cached version
				local name = GetItemInfo(itemID)
				info = HELPFRAME_ITEM_TITLE .. ":" .. (name or itemID)
			end

			info = L["Range"]..":" .. tostring(entry.range) .. " " .. info
			if entry.range <= dist and not found then
                info = "|cff00ff00" .. info .. "|r"
                found = true
            end
			lines[#lines + 1] = info
		end
	end
	return table.concat(lines, "\n")
end


local InfoTags = {
	["numtargeting"] = true,
	["cnumtargeting"] = true,
	["enumtargeting"] = true,
	["grpnum"] = true,
	["br"] = true,
	["name"] = true,
	["nameafk"] = true,
	["afktime"] = true,
	["afk"] = true,
	["shortname:x"] = true,
	["abbrev:name"] = true,
	["guild"] = true,
	["guildrank"] = true,
	["level"] = true,
	["smartlevel"] = true,
	["class"] = true,
	["smartclass"] = true,
	["rare"] = true,
	["elite"] = true,
	["classification"] = true,
	["shortclassification"] = true,
	["race"] = true,
	["smartrace"] = true,
	["creature"] = true,
	["sex"] = true,
	["druidform"] = true,
	["civilian"] = true,
	["pvp"] = true,
	["rank"] = true,
	["numrank"] = true,
	["faction"] = true,
	["ignore"] = true,
	["server"] = true,
	["status"] = true,
	["happiness"] = true,
	["group"] = true,
	["combat"] = true,
	["loyalty"] = true,
	["buffcount"] = true,
	["range"] = true,
	["castname"] = true,
	["casttime"] = true,
	["casttimesmart"] = true,
	["xp"] = true,
	["xppet"] = true,
	["percxp"] = true,
	["percxppet"] = true,
	["rep"] = true,
	["threat"] = true,
}
local HealthnPowerTags = {
	["namehealerhealth"] = true,
	["healerhealth"] = true,
	["smart:healmishp"] = true,
	["cpoints"] = true,
	["smarthealth"] = true,
	["smarthealthp"] = true,
	["ssmarthealth"] = true,
	["ssmarthealthp"] = true,
	["healhp"] = true,
	["hp"] = true,
	["shp"] = true,
	["sshp"] = true,
	["maxhp"] = true,
	["smaxhp"] = true,
	["missinghp"] = true,
	["healmishp"] = true,
	["perhp"] = true,
	["perstatus"] = true,
	["pp"] = true,
	["spp"] = true,
	["maxpp"] = true,
	["smaxpp"] = true,
	["missingpp"] = true,
	["perpp"] = true,
	["druid:pp"] = true,
	["druid:maxpp"] = true,
	["druid:missingpp"] = true,
	["druid:perpp"] = true,
	["incheal"] = true,
	["numheals"] = true,
	["incownheal"] = true,
	["incpreheal"] = true,
	["incafterheal"] = true,
	["hotheal"] = true,
	["effheal"] = true,
	["overheal"] = true,
}
local ColorTags = {
	["combatcolor"] = true,
	["pvpcolor"] = true,
	["reactcolor"] = true,
	["levelcolor"] = true,
	["aggrocolor"] = true,
	["classcolor"] = true,
	["healthcolor"] = true,
	["color:xxxxxx"] = true,
	["nocolor"] = true,
}

local UnitToFrame = {
	["none"] = "UIParent",
	["player"] = "LUFUnitplayer",
	["pet"] = "LUFUnitpet",
	["pettarget"] = "LUFUnitpettarget",
	["pettargettarget"] = "LUFUnitpettargettarget",
	["target"] = "LUFUnittarget",
	["targettarget"] = "LUFUnittargettarget",
	["targettargettarget"] = "LUFUnittargettargettarget",
	["focus"] = "LUFUnitfocus",
	["focustarget"] = "LUFUnitfocustarget",
	["focustargettarget"] = "LUFUnitfocustargettarget",
	["party"] = "LUFHeaderparty",
	["partytarget"] = "LUFHeaderpartytarget",
	["partypet"] = "LUFHeaderpartypet",
	["raid1"] = "LUFHeaderraid1",
	["raid2"] = "LUFHeaderraid2",
	["raid3"] = "LUFHeaderraid3",
	["raid4"] = "LUFHeaderraid4",
	["raid5"] = "LUFHeaderraid5",
	["raid6"] = "LUFHeaderraid6",
	["raid7"] = "LUFHeaderraid7",
	["raid8"] = "LUFHeaderraid8",
	["raid9"] = "LUFHeaderraid9",
	["raidpet"] = "LUFHeaderraidpet",
	["maintank"] = "LUFHeadermaintank",
	["maintanktarget"] = "LUFHeadermaintanktarget",
	["maintanktargettarget"] = "LUFHeadermaintanktargettarget",
	["mainassist"] = "LUFHeadermainassist",
	["mainassisttarget"] = "LUFHeadermainassisttarget",
	["mainassisttargettarget"] = "LUFHeadermainassisttargettarget",
	["arena"] = "LUFHeaderarena",
	["arenapet"] = "LUFHeaderarenapet",
	["arenatarget"] = "LUFHeaderarenatarget",
}


do
	local frameTimeType = "LUF_FrameTime"
	local frameTimeVersion = 6
	local function formatFrameTime(ms, fps, refreshMs)
		local fpsText = string.format("%.1f %s", fps, strupper(FPS_ABBR))
		local frameText = string.format("%s: %.2f %s (%s)", UNITFRAME_LABEL, ms, MILLISECONDS_ABBR, fpsText)
		if refreshMs then
			local refreshFps = refreshMs > 0 and (1000 / refreshMs) or 0
			return string.format("%s\n%s: %.2f %s (%.1f %s)", frameText, REFRESH, refreshMs, MILLISECONDS_ABBR, refreshFps, strupper(FPS_ABBR))
		end
		return string.format("%s\n%s: --", frameText, REFRESH)
	end
	if (AceGUI:GetWidgetVersion(frameTimeType) or 0) < frameTimeVersion then
		local methods = {
			OnAcquire = function(self)
				self:SetWidth(self.width or 400)
				self:SetHeight(36)
				self.lastProfile = debugprofilestop()
				self.label:SetText(formatFrameTime(0, 0))
				self.frame:SetScript("OnUpdate", function()
					local now = debugprofilestop()
					local ms = now - self.lastProfile
					self.lastProfile = now
					if ms < 0 then ms = 0 end
					local fps = ms > 0 and (1000 / ms) or 0
					local test = LUF.AuraCache and LUF.AuraCache.test
					local refreshMs = test and test.active and test.refreshMs
					self.label:SetText(formatFrameTime(ms, fps, refreshMs))
				end)
			end,
			OnRelease = function(self)
				self.frame:SetScript("OnUpdate", nil)
			end,
			OnWidthSet = function(self, width)
				self.label:SetWidth(math.max(0, (width or 0) - 16))
				self:SetHeight(math.max(36, self.label:GetStringHeight() + 4))
			end,
			SetText = function() end,
			SetFontObject = function(self, font)
				self.label:SetFontObject(font or GameFontHighlight)
			end,
			SetImage = function() end,
			SetImageSize = function() end,
		}

		local function Constructor()
			local frame = CreateFrame("Frame", frameTimeType .. AceGUI:GetNextWidgetNum(frameTimeType), UIParent)
			frame:SetHeight(36)
			local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			label:SetPoint("LEFT", 16, 0)
			label:SetPoint("RIGHT", 0, 0)
			label:SetJustifyH("LEFT")
			label:SetJustifyV("TOP")
			local widget = { frame = frame, label = label, type = frameTimeType }
			for name, func in pairs(methods) do
				widget[name] = func
			end
			return AceGUI:RegisterAsWidget(widget)
		end

		AceGUI:RegisterWidgetType(frameTimeType, Constructor, frameTimeVersion)
	end
end

do
	local widgetType = "LUF_ScrollSelect"
	local widgetVersion = 1
	local ROW_HEIGHT = 20
	local VISIBLE_ROWS = 10
	local SLIDER_WIDTH = 12

	local function sortKeys(a, b)
		local na, nb = tonumber(a), tonumber(b)
		if na and nb then
			return na < nb
		end
		return tostring(a) < tostring(b)
	end

	local function refreshRows(self)
		local keys = self.keys
		if not keys or not self.rows then
			return
		end
		local list = self.list
		local offset = self.offset or 0
		local maxOffset = math.max(0, #keys - VISIBLE_ROWS)
		if offset > maxOffset then
			offset = maxOffset
			self.offset = offset
		elseif offset < 0 then
			offset = 0
			self.offset = offset
		end
		LUF._searchListOffset = offset

		local pad
		self.ignoreSlider = true
		if maxOffset < 1 then
			pad = 8
			self.slider:Hide()
			self.slider:SetMinMaxValues(0, 1)
			self.slider:SetValue(0)
		else
			pad = SLIDER_WIDTH + 8
			self.slider:Show()
			self.slider:SetMinMaxValues(0, maxOffset)
			self.slider:SetValue(offset)
		end
		self.ignoreSlider = nil

		for i = 1, VISIBLE_ROWS do
			local row = self.rows[i]
			local key = keys[offset + i]
			row:SetPoint("RIGHT", self.listFrame, "RIGHT", -pad, 0)
			if key and list and list[key] then
				row.value = key
				row.text:SetText(list[key])
				row:Show()
				if key == self.value then
					row.selectedTex:Show()
				else
					row.selectedTex:Hide()
				end
			else
				row.value = nil
				row.text:SetText("")
				row.selectedTex:Hide()
				row:Hide()
			end
		end
	end

	local function moveScroll(self, delta)
		if not self.keys then
			return
		end
		local maxOffset = math.max(0, #self.keys - VISIBLE_ROWS)
		self.offset = math.min(maxOffset, math.max(0, (self.offset or 0) - delta * 3))
		refreshRows(self)
	end

	local methods = {
		OnAcquire = function(self)
			self:SetWidth(self.width or 400)
			self:SetHeight(18 + 6 + VISIBLE_ROWS * ROW_HEIGHT + 8)
			self.list = {}
			self.keys = {}
			self.value = nil
			self.offset = LUF._searchListOffset or 0
			self:SetDisabled(false)
		end,
		OnRelease = function(self)
			self.list = nil
			if self.keys then
				wipe(self.keys)
			end
			self.value = nil
			self.offset = 0
		end,
		OnWidthSet = function(self, width)
			local pad = self.slider:IsShown() and (SLIDER_WIDTH + 6) or 8
			for i = 1, VISIBLE_ROWS do
				self.rows[i]:SetPoint("RIGHT", self.listFrame, "RIGHT", -pad, 0)
			end
		end,
		SetLabel = function(self, text)
			self.label:SetText(text or "")
		end,
		SetList = function(self, list, order)
			self.list = list or {}
			self.keys = self.keys or {}
			wipe(self.keys)
			if type(order) == "table" then
				for i = 1, #order do
					self.keys[i] = order[i]
				end
			else
				for key in pairs(self.list) do
					self.keys[#self.keys + 1] = key
				end
				table.sort(self.keys, sortKeys)
			end
			self.offset = LUF._searchListOffset or 0
			refreshRows(self)
		end,
		SetValue = function(self, value)
			self.value = value
			refreshRows(self)
		end,
		GetValue = function(self)
			return self.value
		end,
		SetDisabled = function(self, disabled)
			self.disabled = disabled
			local color = disabled and 0.5 or 1
			self.label:SetTextColor(1, disabled and 0.5 or 0.82, 0)
			for i = 1, VISIBLE_ROWS do
				self.rows[i].text:SetTextColor(color, color, color)
				if disabled then
					self.rows[i]:Disable()
				else
					self.rows[i]:Enable()
				end
			end
		end,
		SetText = function() end,
	}

	local function Constructor()
		local frame = CreateFrame("Frame", widgetType .. AceGUI:GetNextWidgetNum(widgetType), UIParent)
		frame:SetHeight(18 + 6 + VISIBLE_ROWS * ROW_HEIGHT + 8)

		local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		label:SetPoint("TOPLEFT", 0, 0)
		label:SetPoint("TOPRIGHT", 0, 0)
		label:SetJustifyH("LEFT")
		label:SetHeight(18)

		local listFrame = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
		listFrame:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
		listFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
		listFrame:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		listFrame:SetBackdropColor(0, 0, 0, 0.85)
		listFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
		listFrame:EnableMouse(true)
		listFrame:EnableMouseWheel(true)

		local slider = CreateFrame("Slider", nil, listFrame, BackdropTemplateMixin and "BackdropTemplate")
		slider:SetOrientation("VERTICAL")
		slider:SetWidth(SLIDER_WIDTH)
		slider:SetPoint("TOPRIGHT", listFrame, "TOPRIGHT", -4, -6)
		slider:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", -4, 6)
		slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Vertical")
		slider:SetBackdrop({
			bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
			edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
			tile = true,
			tileSize = 8,
			edgeSize = 8,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		slider:SetMinMaxValues(0, 1)
		slider:SetValueStep(1)
		slider:SetValue(0)
		slider:EnableMouseWheel(true)
		slider:Hide()

		local widget = {
			frame = frame,
			label = label,
			listFrame = listFrame,
			slider = slider,
			rows = {},
			keys = {},
			type = widgetType,
		}
		for name, func in pairs(methods) do
			widget[name] = func
		end
		frame.obj = widget
		listFrame.obj = widget
		slider.obj = widget

		listFrame:SetScript("OnMouseWheel", function(this, delta)
			moveScroll(this.obj, delta)
		end)
		slider:SetScript("OnValueChanged", function(this, value)
			local self = this.obj
			if self.ignoreSlider then
				return
			end
			self.offset = math.floor((value or 0) + 0.5)
			refreshRows(self)
		end)
		slider:SetScript("OnMouseWheel", function(this, delta)
			moveScroll(this.obj, delta)
		end)

		for i = 1, VISIBLE_ROWS do
			local row = CreateFrame("Button", nil, listFrame)
			row:SetHeight(ROW_HEIGHT)
			row:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 6, -6 - (i - 1) * ROW_HEIGHT)
			row:SetPoint("RIGHT", listFrame, "RIGHT", -8, 0)
			row:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]], "ADD")
			row:EnableMouseWheel(true)
			row.obj = widget

			local selectedTex = row:CreateTexture(nil, "BACKGROUND")
			selectedTex:SetAllPoints()
			selectedTex:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
			selectedTex:SetBlendMode("ADD")
			selectedTex:SetVertexColor(1, 0.82, 0)
			selectedTex:Hide()
			row.selectedTex = selectedTex

			local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			text:SetPoint("LEFT", 2, 0)
			text:SetPoint("RIGHT", -2, 0)
			text:SetJustifyH("LEFT")
			row.text = text

			row:SetScript("OnClick", function(this)
				local self = this.obj
				if self.disabled or not this.value then
					return
				end
				self:SetValue(this.value)
				self:Fire("OnValueChanged", this.value)
			end)
			row:SetScript("OnMouseWheel", function(this, delta)
				moveScroll(this.obj, delta)
			end)
			widget.rows[i] = row
		end

		return AceGUI:RegisterAsWidget(widget)
	end

	if (AceGUI:GetWidgetVersion(widgetType) or 0) < widgetVersion then
		AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)
	end
end

function LUF:CreateConfig()
	if self.configCreated then return end
	self.configCreated = true

	local UpdateFilterSpellList
	local function notifyFilterUI()
		if UpdateFilterSpellList then UpdateFilterSpellList() end
		ACR:NotifyChange("LunaUnitFrames")
	end

	local function auraFilterAssignmentEmpty(info, field)
		local db = LUF.db.profile.units[info[1]].auras.filters
		if not db then return true end
		local assigned = db[field]
		if type(assigned) == "string" then return assigned == "" end
		if type(assigned) == "table" then return not next(assigned) end
		return true
	end

	local function set(info, value)
		local db = LUF.db.profile.units
		for i=1, #info-1 do
			if info[i] ~= "GeneralOptions" then
				db = db[info[i]]
			end
		end
		db[info[#info]] = value
		LUF:Reload(info[1])
	end

	local function get(info)
		local db = LUF.db.profile.units
		for i=1, #info do
			if info[i] ~= "GeneralOptions" then
				db = db[info[i]]
			end
		end
		return db
	end

	local function setHeader(info, value)
		local db = LUF.db.profile.units
		for i=1, #info-1 do
			if info[i] ~= "GeneralOptions" then
				db = db[info[i]]
			end
		end
		db[info[#info]] = value
		
		LUF:SetupHeader(info[1])
	end

	local function getPos(info)
		local db = LUF.db.profile.units
		for i=1, #info do
			if info[i] ~= "GeneralOptions" then
				db = db[info[i]]
			end
		end
		return tostring(db)
	end

	local function setPos(info, value)
		local db = LUF.db.profile.units
		for i=1, #info-1 do
			if info[i] ~= "GeneralOptions" then
				db = db[info[i]]
			end
		end
		db[info[#info]] = value
		
		LUF:PlaceFrame(LUF.frameIndex[info[1]])
	end

	local function nbrValidate(info, value)
		if strmatch(value, "^%-?%d*%.?%d*$") then
			return true
		else
			return L["Not a valid number."]
		end
	end

	local function setGeneral(info, value)
		LUF.db.profile[info[#info]] = value
	end

	local function getGeneral(info)
		return LUF.db.profile[info[#info]]
	end

	local function setLockedOption(info, value)
		setGeneral(info, value)
		if value and LUF.AuraCache and LUF.AuraCache.test.active then
			LUF.AuraCache.test.Stop()
		end
		LUF:UpdateMovers()
	end

	local function setPreviewAurasOption(info, value)
		setGeneral(info, value)
		LUF:ReloadAll()
	end

	local function auraTestDisabled()
		return LUF.InCombatLockdown or LUF.db.profile.locked
	end

	local function anyAuraTestType()
		local profile = LUF.db.profile
		return profile.auratestBuffs or profile.auratestDebuffs or profile.auratestDispels
	end

	local function refreshAuraTest()
		if not (LUF.AuraCache and LUF.AuraCache.test.active) then return end
		if anyAuraTestType() then
			LUF.AuraCache.test.Refresh()
		else
			LUF.AuraCache.test.Stop()
		end
	end

	local function setAuraTestOption(info, value)
		setGeneral(info, value)
		if info[#info] == "auratestDebuffs" and not value then
			LUF.db.profile.auratestDispels = false
		end
		refreshAuraTest()
	end

	local function setEnableUnit(info, value)
		set(info, value)
		local unit = info[#info-1]
		if self.HeaderFrames[unit] then
			LUF:SetupHeader(unit)
		end
		if strmatch(unit, "^party.*$") then
			LUF.stateMonitor:SetAttribute(unit.."Enabled", value)
		end
		-- Locked: SetupHeader/Reload is enough (show/hide). Unlocked: refresh
		-- config-mode placeholders for the new enable set, then apply visuals once.
		if not LUF.db.profile.locked then
			LUF:UpdateMovers(true)
		end
		LUF:Reload(unit)
		if not value then
			if unit == "raid" then
				for unit,tbl in pairs(LUF.db.profile.units) do
					if unit ~= "raid" then
						if strsub(tbl.anchorTo,1,13) == "LUFHeaderraid" then
							tbl.anchorTo = "UIParent"
							LUF:CorrectPosition(_G[UnitToFrame[unit]])
						end
					end
				end
			else
				for unit,tbl in pairs(LUF.db.profile.units) do
					if unit == "raid" then
						for i,opt in pairs(tbl.positions) do
							if opt.anchorTo == UnitToFrame[unit] then
								opt.anchorTo = "UIParent"
								LUF:CorrectPosition(_G[UnitToFrame["raid"..i]])
							end
						end
					else
						if tbl.anchorTo == UnitToFrame[unit] then
							tbl.anchorTo = "UIParent"
							if _G[UnitToFrame[unit]] then
								LUF:CorrectPosition(_G[UnitToFrame[unit]])
							else
								tbl.point = "TOPRIGHT"
								tbl.relativePoint = "BOTTOMLEFT"
								tbl.x = UIParent:GetWidth()/2*UIParent:GetScale()
								tbl.y = UIParent:GetHeight()/2*UIParent:GetScale()
							end
						end
					end
				end
			end
		end
	end

	local function setColor(info, r, g, b)
		local db = LUF.db.profile.colors[info[#info]]
		db.r = r
		db.g = g
		db.b = b
		LUF:LoadoUFSettings()
		LUF:ReloadAll()
	end

	local function setAlphaColor(info, r, g, b, a)
		local db = LUF.db.profile.colors[info[#info]]
		db.r = r
		db.g = g
		db.b = b
		db.a = a
		LUF:LoadoUFSettings()
		LUF:ReloadAll()
	end

	local function getColor(info)
		local db = LUF.db.profile.colors[info[#info]]
		return db.r, db.g ,db.b, db.a
	end

	local MediaList = {}
	local function getMediaData(info)
		local mediaType = info[#(info)]

		MediaList[mediaType] = MediaList[mediaType] or {}

		for k in pairs(MediaList[mediaType]) do MediaList[mediaType][k] = nil end
		for _, name in pairs(SML:List(mediaType)) do
			MediaList[mediaType][name] = name
		end

		return MediaList[mediaType]
	end

	local function wipeTextures()
		for unit,tbl in pairs(LUF.db.profile.units) do
			for barname,bartbl in pairs(tbl) do
				if type(bartbl) == "table" and bartbl.statusbar then
					bartbl.statusbar = nil
				end
			end
		end
	end

	local function wipeFonts()
		for unit,tbl in pairs(LUF.db.profile.units) do
			for bar,bartbl in pairs(tbl.tags) do
				bartbl.font = nil
			end
			tbl.combatText.font = nil
		end
		LUF.db.profile.units.raid.font = nil
	end

	local function setGrowthDir(info, value)
		local unit = info[#info-2]
		local db = LUF.db.profile.units[unit]

		db.attribPoint = value
		if unit == "party" then
			LUF.db.profile.units.partytarget.attribPoint = value
			LUF.db.profile.units.partypet.attribPoint = value
		end

		-- Simply re-set all frames is easier than making a complicated selection algorithm
		for unitName, name in pairs(UnitToFrame) do
			if unitName ~= "None" and name ~= "UIParent" and _G[name] then
				LUF:CorrectPosition(_G[name])
			end
		end
		LUF:SetupHeader(unit)
		if unit == "party" then
			LUF:SetupHeader("partytarget")
			LUF:SetupHeader("partypet")
		end
		
	end

	local function setHideRaid(info, value)
		LUF.db.profile.units.party.hideraid = value
		LUF.stateMonitor:SetAttribute("hideraid", value)
		LUF:SetupHeader("party")
		LUF:SetupHeader("partypet")
		LUF:SetupHeader("partytarget")
	end

	local function setSortMethod(info, value)
		local unit = info[#info-2]
		LUF.db.profile.units[unit].sortMethod = value
		LUF:SetupHeader(unit)
		if unit == "party" then
			LUF.db.profile.units["partytarget"].sortMethod = value
			LUF:SetupHeader("partytarget")
			LUF.db.profile.units["partypet"].sortMethod = value
			LUF:SetupHeader("partypet")
		end
	end

	local function setSortOrder(info, value)
		local unit = info[#info-2]
		LUF.db.profile.units[unit].sortOrder = value
		LUF:SetupHeader(unit)
		if unit == "party" then
			LUF.db.profile.units["partytarget"].sortOrder = value
			LUF:SetupHeader("partytarget")
			LUF.db.profile.units["partypet"].sortOrder = value
			LUF:SetupHeader("partypet")
		end
	end

	local function getShowWhen(info)
		local db = LUF.db.profile.units.raid
		if db.showPlayer and db.showSolo then
			return "ALWAYS"
		elseif db.showParty then
			return "PARTY"
		else
			return "RAID"
		end
	end

	local function setShowWhen(info, value)
		if value == "ALWAYS" then
			LUF.db.profile.units.raid.showSolo = true
			LUF.db.profile.units.raid.showPlayer = true
			LUF.db.profile.units.raid.showParty = true
			LUF.db.profile.units.raidpet.showSolo = true
			LUF.db.profile.units.raidpet.showPlayer = true
			LUF.db.profile.units.raidpet.showParty = true
		elseif value == "PARTY" then
			LUF.db.profile.units.raid.showSolo = nil
			LUF.db.profile.units.raid.showPlayer = true
			LUF.db.profile.units.raid.showParty = true
			LUF.db.profile.units.raidpet.showSolo = nil
			LUF.db.profile.units.raidpet.showPlayer = true
			LUF.db.profile.units.raidpet.showParty = true
		else
			LUF.db.profile.units.raid.showSolo = nil
			LUF.db.profile.units.raid.showPlayer = nil
			LUF.db.profile.units.raid.showParty = nil
			LUF.db.profile.units.raidpet.showSolo = nil
			LUF.db.profile.units.raidpet.showPlayer = nil
			LUF.db.profile.units.raidpet.showParty = nil
		end
		LUF:SetupHeader("raid")
		LUF:SetupHeader("raidpet")
		LUF.stateMonitor:SetAttribute("showWhen", value)
	end

	local function Lockdown() return LUF.InCombatLockdown end

	local function deepAnchorCheck(tbl)
		local inserted
		for frame in pairs(tbl) do
			for key,value in pairs(LUF.db.profile.units) do
				if key == "raid" then
					for k,v in pairs(LUF.db.profile.units.raid.positions) do
						if v.anchorTo == frame and not tbl[UnitToFrame["raid"..k]] then
							tbl[UnitToFrame["raid"..k]] = true
							inserted = true
						end
					end
				else
					if value.anchorTo == frame and not tbl[UnitToFrame[key]] then
						tbl[UnitToFrame[key]] = true
						inserted = true
					end
				end
			end
		end
		if inserted then
			return deepAnchorCheck(tbl)
		else
			return tbl
		end
	end

	local function getAnchors(info)
		local unit = info[#info-2]
		if unit == "raid" then
			unit = info[#info]
		end
		local tbl = {
			["UIParent"]=NONE,
			["LUFUnitplayer"]=PLAYER,
			["LUFUnitpet"]=PET,
			["LUFUnitpettarget"]=L["pettarget"],
			["LUFUnitpettargettarget"]=L["pettargettarget"],
			["LUFUnittarget"]=TARGET,
			["LUFUnittargettarget"]=L["targettarget"],
			["LUFUnittargettargettarget"]=L["targettargettarget"],
			["LUFUnitfocus"]=FOCUS,
			["LUFUnitfocustarget"]=L["focustarget"],
			["LUFUnitfocustargettarget"]=L["focustargettarget"],
			["LUFHeaderparty"]=PARTY,
			["LUFHeaderpartytarget"]=L["partytarget"],
			["LUFHeaderpartypet"]=L["partypet"],
			["LUFHeaderraid1"]=(RAID.."1"),
			["LUFHeaderraid2"]=(RAID.."2"),
			["LUFHeaderraid3"]=(RAID.."3"),
			["LUFHeaderraid4"]=(RAID.."4"),
			["LUFHeaderraid5"]=(RAID.."5"),
			["LUFHeaderraid6"]=(RAID.."6"),
			["LUFHeaderraid7"]=(RAID.."7"),
			["LUFHeaderraid8"]=(RAID.."8"),
			["LUFHeaderraid9"]=(RAID.."9"),
			["LUFHeaderraidpet"]=L["raidpet"],
			["LUFHeadermaintank"]=MAINTANK,
			["LUFHeadermaintanktarget"]=L["maintanktarget"],
			["LUFHeadermaintanktargettarget"]=L["maintanktargettarget"],
			["LUFHeadermainassist"]=MAIN_ASSIST,
			["LUFHeadermainassisttarget"]=L["mainassisttarget"],
			["LUFHeadermainassisttargettarget"]=L["mainassisttargettarget"],
			["LUFHeaderarena"] = L["arena"],
			["LUFHeaderarenapet"] = L["arenapet"],
			["LUFHeaderarenatarget"] = L["arenatarget"],
		}
		for key in pairs(deepAnchorCheck({[UnitToFrame[unit]]=true})) do
			tbl[key] = nil
		end
		for frameName, unitName in pairs(tbl) do
			if frameName ~= "UIParent" and _G[frameName] then
		--		if not LUF.db.profile.units[_G[frameName].unitType].enabled then
		--			tbl[frameName] = nil
		--		end
			elseif not _G[frameName] then
				tbl[frameName] = nil
			end
		end
		return tbl
	end

	local function SetAnchorTo(info, value)
		local frame
		if info[#info-2] == "raid" then
			local nbr = strmatch(info[#info], "%d+")
			LUF.db.profile.units.raid.positions[tonumber(nbr)].anchorTo = value
			frame = LUF.frameIndex["raid"..nbr]
		else
			LUF.db.profile.units[info[#info-2]].anchorTo = value
			frame = _G[UnitToFrame[info[#info-2]]]
		end
		LUF:CorrectPosition(frame)
		-- Notify the configuration it can update itself now
		if( ACR ) then
			ACR:NotifyChange("LunaUnitFrames")
		end
	end

	local moduleBlacklist = {
		["range"] = {
			["player"] = true,
		},
		["castBar"] = {
			--["pet"] = true,
			["pettarget"] = true,
			["pettargettarget"] = true,
			["targettarget"] = true,
			["targettargettarget"] = true,
			["partytarget"] = true,
			["focustarget"] = true,
			["focustargettarget"] = true,
			["partypet"] = true,
			["raidpet"] = true,
			["maintanktarget"] = true,
			["maintanktargettarget"] = true,
			["mainassisttarget"] = true,
			["mainassisttargettarget"] = true,
			["arenapet"] = true,
			["arenatarget"] = true,
		},
		["fader"] = {
			["target"] = true,
			["targettarget"] = true,
			["targettargettarget"] = true,
			["arena"] = true,
			["arenapet"] = true,
			["arenatarget"] = true,
		},
		["incHeal"] = {
			["arena"] = true,
			["arenapet"] = true,
			["arenatarget"] = true,
		},
	}

	local SQUARE_AURA_TYPES = { aura = true, ownaura = true }

	local SQUARE_TYPE_VALUES = {
		["aggro"] = L["Aggro"],
		["legacythreat"] = L["Aggro"] .. " (" .. L["targettarget"] .. ")",
		["aura"] = L["Buff/Debuff"],
		["ownaura"] = L["Own buff/debuff"],
		["dispel"] = DISPELS,
		["missing"] = L["Missing Buff"],
	}

	local function squareConfig(info)
		return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]]
	end

	local function squareIsAuraMatchType(info)
		return SQUARE_AURA_TYPES[squareConfig(info).type]
	end

	local function squareUsesExactMatch(info)
		return squareIsAuraMatchType(info) and squareConfig(info).matchMode == "exact"
	end

	local SQUARE_MATCH_MODE_VALUES = {
		["partial"] = L["Partial (slow)"],
		["exact"] = L["Exact (fast)"],
	}

	local SQUARE_MATCH_MODE_SORTING = { "partial", "exact" }

	local function squareMatchModeGet(info)
		if squareConfig(info).matchMode == "exact" then
			return "exact"
		end
		return "partial"
	end

	local function squareMatchModeSet(info, value)
		set(info, value == "exact" and "exact" or nil)
	end

	local function squareValueLabel(info)
		local squareType = squareConfig(info).type
		if squareType == "dispel" then
			return L["IndexOfDispel"]
		end
		if squareType == "missing" or squareUsesExactMatch(info) then
			return L["Name (exact) or ID"]
		end
		return L["Name (partial) or ID"]
	end

	local function squareValueDesc(info)
		local squareType = squareConfig(info).type
		if squareType == "dispel" then
			return L["IndexOfDispelDesc"]
		end
		if squareType == "missing" then
			return L["Name (exact) or ID of the effect to track. Use ; as a logical AND and / as logical OR. Also supports [mana] to only check on mana classes. Example: Arcane Intellect[mana]/Arcane Brilliance[mana];Dampen Magic"]
		end
		if squareUsesExactMatch(info) then
			return L["Name (exact) or ID of the effect to track. Use ; as a seperator for multiple auras"]
		end
		return L["Name (partial) or ID of the effect to track. Use ; as a seperator for multiple auras"]
	end

	local function validateMissingBuffInput(info, value)
		if LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type ~= "missing" then return true end
		local spellGroups = {strsplit(";",value)}
		local j
		for j,spellGroup in ipairs(spellGroups) do
			local localSpells = {strsplit("/",spellGroup)}
			local k
			for k,spell in ipairs(localSpells) do
				spell = spell:gsub("%[mana%]", "")
				if spell ~="" and not tonumber(spell) and not C_Spell.GetSpellInfo(spell) then
					return L["You can only use Spellnames for Spells your Character knows otherwise please use Spell IDs"]
				end
			end
		end
		return true
	end

	local moduleOptions = {
		healthBar = {
			name = L["Health bar"],
			type = "group",
			order = 3,
			--inline = true,
			args = {
				enabled = {
					name = ENABLE,
					desc = string.format(L["Enable or disable the %s."], L["Health bar"]),
					type = "toggle",
					order = 1,
				},
				background = {
					name = BACKGROUND,
					desc = string.format(L["Enable or disable the %s."], BACKGROUND),
					type = "toggle",
					order = 2,
				},
				backgroundAlpha = {
					name = L["Background alpha"],
					desc = L["Set the background alpha."],
					type = "range",
					order = 3,
					min = 0,
					max = 1,
					step = 0.01,
				},
				colorType = {
					name = L["Color by type"],
					--desc = L["Color by type"],
					type = "select",
					order = 4,
					values = function(info) if info[1] ~= "pet" then return {["class"] = CLASS, ["static"] = L["Static"], ["percent"] = L["Health percent"]} else return {["happiness"] = HAPPINESS, ["static"] = L["Static"], ["percent"] = L["Health percent"]} end end,
				},
				reactionType = {
					name = L["Color by reaction"],
					--desc = L["Color by reaction"],
					type = "select",
					order = 5,
					values = {["none"] = L["Never (Disabled)"], ["player"] = L["Players only"], ["npc"] = L["NPCs only"], ["both"] = STATUS_TEXT_BOTH},
				},
				height = {
					name = L["Height"],
					desc = L["Set the height."],
					type = "range",
					order = 6,
					min = 1,
					max = 10,
					step = 0.1,
				},
				order = {
					name = L["Order"],
					desc = L["Set the order priority."],
					type = "range",
					order = 7,
					min = 0,
					max = 100,
					step = 5,
				},
				statusbar = {
					order = 8,
					type = "select",
					name = L["Bar texture"],
					dialogControl = "LSM30_Statusbar",
					values = getMediaData,
					get = function(info) return get(info) or LUF.db.profile.statusbar or SML.DefaultMedia.statusbar end,
				},
				vertical = {
					name = L["Vertical"],	
					desc = L["Set the bar vertical."],
					type = "toggle",
					order = 9,
				},
				posSlot = {
					name = L["Bar Group"],
					desc = L["Select the bar stack"],
					type = "select",
					order = 10,
					values = {["LEFT"] = L["Left Group"], ["RIGHT"] = L["Right Group"], ["CENTER"] = L["Center Group"]},
				},
				invert = {
					name = L["Invert"],
					desc = L["Kind of inverts the color scheme."],
					type = "toggle",
					order = 11,
				},
			},
		},
		["powerBar"] = {
			name = L["Power bar"],
			type = "group",
			order = 4,
			--inline = true,
			args = {
				enabled = {
					name = ENABLE,
					desc = string.format(L["Enable or disable the %s."], L["Power bar"]),
					type = "toggle",
					order = 1,
				},
				ticker = {
					name = L["Ticker"],
					desc = L["Since mana/energy regenerate in ticks, show a timer for it"],
					type = "toggle",
					order = 2,
					hidden = function(info) return info[1] ~= "player" or select(2, UnitClass("player")) == "WARRIOR" end
				},
				hideticker = {
					name = L["Autohide ticker"],
					desc = L["Hide the ticker when it's not needed"],
					type = "toggle",
					order = 3,
					hidden = function(info) return info[1] ~= "player" or select(2, UnitClass("player")) == "WARRIOR" end
				},
				fivesecond = {
					name = L["Five second rule"],
					desc = L["Show a timer for the five second rule"],
					type = "toggle",
					order = 4,
					hidden = function(info) return info[1] ~= "player" or select(2, UnitClass("player")) == "WARRIOR" end
				},
				background = {
					name = BACKGROUND,
					desc = string.format(L["Enable or disable the %s."], BACKGROUND),
					type = "toggle",
					order = 5,
				},
				backgroundAlpha = {
					name = L["Background alpha"],
					desc = L["Set the background alpha."],
					type = "range",
					order = 6,
					min = 0,
					max = 1,
					step = 0.01,
				},
				colorType = {
					name = L["Color by type"],
					--desc = L["Color by type"],
					type = "select",
					order = 7,
					values = {["class"] = CLASS, ["type"] = L["Power Type"]},
				},
				height = {
					name = L["Height"],
					desc = L["Set the height."],
					type = "range",
					order = 8,
					min = 1,
					max = 10,
					step = 0.1,
				},
				order = {
					name = L["Order"],
					desc = L["Set the order priority."],
					type = "range",
					order = 9,
					min = 0,
					max = 100,
					step = 5,
				},
				statusbar = {
					order = 10,
					type = "select",
					name = L["Bar texture"],
					dialogControl = "LSM30_Statusbar",
					values = getMediaData,
					get = function(info) return get(info) or LUF.db.profile.statusbar or SML.DefaultMedia.statusbar end,
				},
				vertical = {
					name = L["Vertical"],
					desc = L["Set the bar vertical."],
					type = "toggle",
					order = 11,
				},
				posSlot = {
					name = L["Bar Group"],
					desc = L["Select the bar stack"],
					type = "select",
					order = 12,
					values = {["LEFT"] = L["Left Group"], ["RIGHT"] = L["Right Group"], ["CENTER"] = L["Center Group"]},
				},
			},
		},
		["manaPrediction"] = {
			name = L["Mana Prediction"],
			type = "group",
			order = 5,
			--inline = true,
			hidden = function(info) return not (info[1] == "player") end,
			args = {
				enabled = {
					name = ENABLE,
					desc = string.format(L["Enable or disable the %s."],L["Mana Prediction"]),
					type = "toggle",
					order = 1,
				},
				color = {
					name = COLOR,
					type = "color",
					order = 2,
					width = "half",
					hasAlpha = true,
					get = function(info) local db = LUF.db.profile.units.player.manaPrediction.color return db.r, db.g ,db.b, db.a end,
					set = function(info, r, g, b, a) local db = LUF.db.profile.units.player.manaPrediction.color db.r = r db.g = g db.b = b db.a = a LUF:Reload(info[1]) end,
				},
			},
		},
		["castBar"] = {
			name = SHOW_ARENA_ENEMY_CASTBAR_TEXT,
			type = "group",
			order = 6,
			--inline = true,
			args = {
				enabled = {
					name = ENABLE,
					desc = string.format(L["Enable or disable the %s."],SHOW_ARENA_ENEMY_CASTBAR_TEXT),
					type = "toggle",
					order = 1,
				},	
				autoHide = {
					name = L["Auto hide"],
					desc = string.format(L["Hide when inactive"]),
					type = "toggle",
					order = 2,
				},
				icon = {
					name = L["Cast icon"],
					desc = L["Set the behaviour of the cast icon"],
					type = "select",
					order = 3,
					values = {["HIDE"] = HIDE, ["LEFT"] = L["Left"], ["RIGHT"] = L["Right"]},
				},
				shield = {
					name = L["Shield icon"],
					desc = L["Shield icon desc"],
					type = "toggle",
					order = 4,
				},
				height = {
					name = L["Height"],
					desc = L["Set the height."],
					type = "range",
					order = 6,
					min = 1,
					max = 10,
					step = 0.1,
				},
				order = {
					name = L["Order"],
					desc = L["Set the order priority."],
					type = "range",
					order = 7,
					min = 0,
					max = 100,
					step = 5,
				},
				statusbar = {
					order = 8,
					type = "select",
					name = L["Bar texture"],
					dialogControl = "LSM30_Statusbar",
					values = getMediaData,
					get = function(info) return get(info) or LUF.db.profile.statusbar or SML.DefaultMedia.statusbar end,
				},
				posSlot = {
					name = L["Bar Group"],
					desc = L["Select the bar stack"],
					type = "select",
					order = 9,
					values = {["LEFT"] = L["Left Group"], ["RIGHT"] = L["Right Group"], ["CENTER"] = L["Center Group"]},
				},
			},
		},
		["emptyBar"] = {
			name = L["Empty bar"],
			type = "group",
			order = 7,
			--inline = true,
			args = {
				enabled = {
					name = ENABLE,
					desc = string.format(L["Enable or disable the %s."], L["Empty bar"]),
					type = "toggle",
					order = 1,
				},
				alpha = {
					name = OPACITY,
					desc = L["Set the alpha."],
					type = "range",
					order = 2,
					min = 0,
					max = 1,
					step = 0.01,
				},
				reactionType = {
					name = L["Color by reaction"],
					--desc = L["Color by reaction"],
					type = "select",
					order = 3,
					values = {["none"] = L["Never (Disabled)"], ["player"] = L["Players only"], ["NPC/hostile player"] = L["NPCs and Hostile players"], ["npc"] = L["NPCs only"], ["both"] = STATUS_TEXT_BOTH},
				},
				class = {
					name = UNIT_COLORS,
					desc = L["Color by class."],
					type = "toggle",
					order = 4,
				},
				height = {
					name = L["Height"],
					desc = L["Set the height."],
					type = "range",
					order = 5,
					min = 1,
					max = 10,
					step = 0.1,
				},
				order = {
					name = L["Order"],
					desc = L["Set the order priority."],
					type = "range",
					order = 6,
					min = 0,
					max = 100,
					step = 5,
				},
				statusbar = {
					order = 7,
					type = "select",
					name = L["Bar texture"],
					dialogControl = "LSM30_Statusbar",
					values = getMediaData,
					get = function(info) return get(info) or LUF.db.profile.statusbar or SML.DefaultMedia.statusbar end,
				},
				vertical = {
					name = L["Vertical"],
					desc = L["Set the bar vertical."],
					type = "toggle",
					order = 8,
				},
				posSlot = {
					name = L["Bar Group"],
					desc = L["Select the bar stack"],
					type = "select",
					order = 9,
					values = {["LEFT"] = L["Left Group"], ["RIGHT"] = L["Right Group"], ["CENTER"] = L["Center Group"]},
				},
			},
		},
		["range"] = {
			name = L["Range"],
			type = "group",
			order = 8,
			--inline = true,
			hidden = function(info) if info[1] == "player" then return true end end,
			args = {
				enabled = {
					name = ENABLE,
					desc = L["Enable or disable range checking."],
					type = "toggle",
					order = 10,
				},
				partyraidH = {
					name = RAID .. "/" .. PARTY .. " " .. L["Range"],
					type = "header",
					order = 20,
				},
				partyraid = {
					name = function() return "|cff00ff00" .. L["Range"].. ":40 UnitInRange(unit)|r" end,
					type = "description",
					order = 30,
				},
				friendlyH = {
					name = FRIENDLY .. " " .. L["Range"],
					type = "header",
					order = 40,
				},
				friendly = {
					name = function() return buildCheckerList("friend") end,
					type = "description",
					order = 50,
				},
				friendlyCH = {
					name = FRIENDLY .." " .. COMBAT .. " " .. L["Range"],
					type = "header",
					order = 60,
				},
				friendlyC = {
					name = function() return buildCheckerList("friend", true) end,
					type = "description",
					order = 70,
				},
				resH = {
					name = RESURRECT .. " " .. L["Range"],
					type = "header",
					order = 80,
				},
				res = {
					name = function() return buildCheckerList("res") end,
					type = "description",
					order = 90,
				},
				resCH = {
					name = RESURRECT .." " .. COMBAT .. " " .. L["Range"],
					type = "header",
					order = 100,
				},
				resC = {
					name = function() return buildCheckerList("res", true) end,
					type = "description",
					order = 110,
				},
				enemyH = {
					name = ENEMY .. " " .. L["Range"],
					type = "header",
					order = 120,
				},
				enemy = {
					name = function() return buildCheckerList("harm", false) end,
					type = "description",
					order = 130,
				},
				enemyCH = {
					name = ENEMY .." " .. COMBAT .. " " .. L["Range"],
					type = "header",
					order = 140,
				},
				enemyC = {
					name = function() return buildCheckerList("harm", true) end,
					type = "description",
					order = 150,
				},
				petH = {
					name = PET .. " " .. L["Range"],
					type = "header",
					order = 160,
				},
				pet = {
					name = function() return buildCheckerList("pet") end,
					type = "description",
					order = 170,
				},
				petCH = {
					name = PET .." " .. COMBAT .. " " .. L["Range"],
					type = "header",
					order = 180,
				},
				petC = {
					name = function() return buildCheckerList("pet", true) end,
					type = "description",
					order = 190,
				},
				miscH = {
					name = NPC_NAMES_DROPDOWN_ALL  .. "/" .. DEAD .. " " .. L["Range"],
					type = "header",
					order = 200,
				},
				misc = {
					name = function() return buildCheckerList("misc") end,
					type = "description",
					order = 210,
				},
				miscCH = {
					name = NPC_NAMES_DROPDOWN_ALL  .. "/" .. DEAD .. " " .. COMBAT .. " " .. L["Range"],
					type = "header",
					order = 220,
				},
				miscC = {
					name = function() return buildCheckerList("misc", true) end,
					type = "description",
					order = 230,
				},
			},
		},
		["portrait"] = {
			name = L["Portrait"],
			type = "group",
			order = 9,
			--inline = true,
			args = {
				enabled = {
					name = ENABLE,
					desc = string.format(L["Enable or disable the %s."],L["Portrait"]),
					type = "toggle",
					order = 1,
				},
				showStatus = {
					name = L["Show Status"],
					desc = L["Show unit status on the portrait with a cooldown animation."],
					type = "toggle",
					order = 2,
				},
				verboseStatus = {
					name = L["Verbose Status"],
					desc = L["Show more unit statuses on the portrait."],
					type = "toggle",
					order = 3,
				},
				type = {
					name = TYPE,
					desc = L["Portrait type"],
					type = "select",
					order = 4,
					values = {["3D"] = L["3D"], ["3D/2D"] = L["3D2D"], ["2D"] = L["2D"], ["class"] = CLASS, ["2dclass"] = L["2D Class"]},
				},
				alignment = {
					name = L["Alignment"],
					desc = L["Portrait alignment"],
					type = "select",
					order = 5,
					values = {["LEFT"] = L["Left"], ["RIGHT"] = L["Right"], ["CENTER"] = L["Bar"]},
				},
				posSlot = {
					name = L["Bar Group"],
					desc = L["Select the bar stack"],
					type = "select",
					order = 6,
					hidden =  function(info) return LUF.db.profile.units[info[1]].portrait.alignment ~= "CENTER" end,
					values = {["LEFT"] = L["Left Group"], ["RIGHT"] = L["Right Group"], ["CENTER"] = L["Center Group"]},
				},
				width = {
					name = L["Width"],
					desc = L["Set the width of the portrait."],
					type = "range",
					order = 7,
					min = 0,
					max = 1,
					step = 0.01,
				},
				height = {
					name = L["Height"],
					desc = L["Set the height when in bar mode."],
					type = "range",
					order = 8,
					min = 1,
					max = 10,
					step = 0.1,
				},
				order = {
					name = L["Order"],
					desc = L["Set the order priority."],
					type = "range",
					order = 9,
					min = 0,
					max = 100,
					step = 5,
				},
			},
		},
		["incHeal"] = {
			name = L["Incoming heals"],
			type = "group",
			order = 10,
			--inline = true,
			args = {
				enabled = {
					name = ENABLE,
					desc = string.format(L["Enable or disable the %s."],L["Incoming heals"]),
					type = "toggle",
					order = 1,
				},
				cap = {
					name = L["Inc Heal Cap"],
					desc = L["Let the prediction overgrow the bar."],
					type = "range",
					order = 2,
					min = 1,
					max = 1.3,
					step = 0.01,
				},
				alpha = {
					name = OPACITY,
					desc = L["Set the alpha."],
					type = "range",
					order = 3,
					min = 0,
					max = 1,
					step = 0.01,
				},
			},
		},
		["auras"] = {
			name = AURAS,
			type = "group",
			order = 11,
			--inline = true,
			disabled = Lockdown,
			args = {
				generalheader = {
					name = GENERAL,
					type = "header",
					order = 1,
				},
				weaponbuffs = {
					name = L["Weaponbuffs"],
					desc = string.format(L["Enable or disable the %s."],L["Weaponbuffs"]),
					type = "toggle",
					order = 2,
					hidden = function(info) return info[1] ~= "player" end
				},
				bordercolor = {
					name = L["Bordercolor"],
					desc = string.format(L["Enable or disable the %s."],L["Bordercolor"]),
					type = "toggle",
					order = 3,
				},
				padding = {
					name = L["Padding"],
					desc = L["Distance between aura icons."],
					type = "range",
					order = 4,
					min = 0,
					max = 10,
					step = 1,
				},
				timer = {
					name = L["Timers"],
					desc = L["Limit timers to..."],
					type = "select",
					order = 5,
					values = {["all"] = ACHIEVEMENTFRAME_FILTER_ALL, ["self"] = L["Own"], ["none"] = NONE},
				},
				buffcountfontsize = {
					name = L["BuffCountFontSize"],
					desc = L["BuffCountFontSizeText"],
					type = "range",
					order = 6,
					min = 4,
					max = 40,
					step = 1,
				},
				buffheader = {
					name = L["Buffs"],
					type = "header",
					order = 7,
				},
				buffs = {
					name = L["Buffs"],
					desc = string.format(L["Enable or disable the %s."],L["Buffs"]),
					type = "toggle",
					order = 8,
				},
				filterbuffs = {
					name = string.format(L["Filter %s"],L["Buffs"]),
					desc = L["Show only buffs that you or everyone of your class can apply"],
					type = "select",
					order = 9,
					values = {[1] = OFF, [2] = L["Your own"], [3] = CLASS},
				},
				buffsize = {
					name = L["Size"],
					desc = L["Set the buffsize."],
					type = "range",
					order = 10,
					min = 4,
					max = 50,
					step = 1,
				},
				enlargedbuffsize = {
					name = L["Bigger buffs"],
					desc = EMPHASIZE_MY_SPELLS_TEXT,
					type = "range",
					order = 11,
					min = 0,
					max = 20,
					step = 1,
					hidden = function(info) return (LUF.db.profile.units[info[1]].auras.buffpos == "INFRAME" or LUF.db.profile.units[info[1]].auras.buffpos == "INFRAMECENTER") end
				},
				showSteal = {
					name = L["Show stealable"],
					desc = L["Highlight stealable Buffs"],
					type = "toggle",
					order = 12,
					hidden = function(info) return LUF.isClassic end,
				},
				buffpos = {
					name = L["Position"],
					desc = string.format(L["Position of the %s."],L["Buffs"]),
					type = "select",
					order = 13,
					values = {["LEFT"] = L["Left"], ["RIGHT"] = L["Right"], ["TOP"] = L["Top"], ["BOTTOM"] = L["Bottom"], ["INFRAME"] = L["Inside"], ["INFRAMECENTER"] = L["Inside Center"]},
				},
				buffOffset = {
					name = L["Y Position"],
					desc = L["Offset"],
					type = "range",
					order = 14,
					min = -50,
					max = 50,
					step = 1,
					hidden = function(info) return (LUF.db.profile.units[info[1]].auras.buffpos ~= "INFRAMECENTER" and LUF.db.profile.units[info[1]].auras.buffpos ~= "INFRAME") end,
				},
				wrapbuffside = {
					name = L["Horizontal Limit Side"],
					desc = L["Side on which to cut shorter than the frame"],
					type = "select",
					order = 15,
					values = {["LEFT"] = L["Left"], ["RIGHT"] = L["Right"]},
					hidden = function(info) return (LUF.db.profile.units[info[1]].auras.buffpos ~= "TOP" and LUF.db.profile.units[info[1]].auras.buffpos ~= "BOTTOM") end,
				},
				wrapbuff = {
					name = L["Horizontal Limit"],
					desc = L["Limit to a percentage of the frame"],
					type = "range",
					order = 16,
					min = 0.2,
					max = 1.5,
					step = 0.01,
					width = "double",
					isPercent = true,
					hidden = function(info) return (LUF.db.profile.units[info[1]].auras.buffpos ~= "TOP" and LUF.db.profile.units[info[1]].auras.buffpos ~= "BOTTOM") end,
				},
				buffcount = {
					name = "Maximum Number of Buffs",
					desc = "Limit the maximum number of shown buffs",
					type = "range",
					order = 17,
					min = 1,
					max = 32,
					step = 1,
				},
				debuffheader = {
					name = L["Debuffs"],
					type = "header",
					order = 18,
				},
				debuffs = {
					name = L["Debuffs"],
					desc = string.format(L["Enable or disable the %s."],L["Debuffs"]),
					type = "toggle",
					order = 19,
				},
				filterdebuffs = {
					name = string.format(L["Filter %s"],L["Debuffs"]),
					desc = L["Show only debuffs that you can dispel or cast"],
					type = "select",
					order = 20,
					values = {[1] = OFF, [2] = L["Your own"], [3] = DISPELS},
				},
				debuffsize = {
					name = L["Size"],
					desc = L["Set the debuffsize."],
					type = "range",
					order = 21,
					min = 4,
					max = 50,
					step = 1,
				},
				enlargeddebuffsize = {
					name = L["Bigger debuffs"],
					desc = EMPHASIZE_MY_SPELLS_TEXT,
					type = "range",
					order = 22,
					min = 0,
					max = 20,
					step = 1,
					hidden = function(info) return (LUF.db.profile.units[info[1]].auras.debuffpos == "INFRAME" or LUF.db.profile.units[info[1]].auras.debuffpos == "INFRAMECENTER") end,
				},
				debuffpos = {
					name = L["Position"],
					desc = string.format(L["Position of the %s."],L["Debuffs"]),
					type = "select",
					order = 23,
					values = {["LEFT"] = L["Left"], ["RIGHT"] = L["Right"], ["TOP"] = L["Top"], ["BOTTOM"] = L["Bottom"], ["INFRAME"] = L["Inside"], ["INFRAMECENTER"] = L["Inside Center"]},
				},
				debuffOffset = {
					name = L["Y Position"],
					desc = L["Offset"],
					type = "range",
					order = 24,
					min = -50,
					max = 50,
					step = 1,
					hidden = function(info) return (LUF.db.profile.units[info[1]].auras.debuffpos ~= "INFRAMECENTER" and LUF.db.profile.units[info[1]].auras.debuffpos ~= "INFRAME") end,
				},
				wrapdebuffside = {
					name = L["Horizontal Limit Side"],
					desc = L["Side on which to cut shorter than the frame"],
					type = "select",
					order = 25,
					hidden = function(info) return (LUF.db.profile.units[info[1]].auras.debuffpos ~= "TOP" and LUF.db.profile.units[info[1]].auras.debuffpos ~= "BOTTOM") end,
					values = {["LEFT"] = L["Left"], ["RIGHT"] = L["Right"]},
				},
				wrapdebuff = {
					name = L["Horizontal Limit"],
					desc = L["Limit to a percentage of the frame."],
					type = "range",
					order = 26,
					min = 0.2,
					max = 1.5,
					step = 0.01,
					width = "double",
					isPercent = true,
					hidden = function(info) return (LUF.db.profile.units[info[1]].auras.debuffpos ~= "TOP" and LUF.db.profile.units[info[1]].auras.debuffpos ~= "BOTTOM") end,
				},
				debuffcount = {
					name = "Maximum Number of Debuffs",
					desc = "Limit the maximum number of shown debuffs",
					type = "range",
					order = 27,
					min = 1,
					max = 40,
					step = 1,
				},
				filterheader = {
					name = L["Filter Lists"],
					type = "header",
					order = 28,
				},
				filterbuffgroup = {
					name = L["Buff Filter List"],
					type = "group",
					order = 29,
					inline = true,
					args = {
						filterbufflist = {
							name = L["Select filter lists to apply to buffs"],
							type = "multiselect",
							order = 1,
							width = "double",
							values = function()
								local t = {}
								for name in pairs(LUF.db.profile.filters or {}) do
									t[name] = name
								end
								return t
							end,
							get = function(info, key)
								return LUF:AuraFilterAssignmentHas(LUF.db.profile.units[info[1]].auras.filters, "buffs", key)
							end,
							set = function(info, key, value)
								LUF:SetAuraFilterAssignment(info[1], "buffs", key, value)
								LUF:RefreshAuraFilters(info[1])
							end,
						},
						filterbuffmode = {
							name = L["Buff Filter Mode"],
							desc = L["How to apply the buff filter list"],
							type = "select",
							order = 2,
							values = {["disabled"] = L["Disabled"], ["whitelist"] = L["Whitelist"], ["blacklist"] = L["Blacklist"]},
							get = function(info)
								local db = LUF.db.profile.units[info[1]].auras.filters
								return db and db.buffMode or "disabled"
							end,
							set = function(info, value)
								local filters = LUF:EnsureUnitAuraFilters(info[1])
								if filters then
									filters.buffMode = value
									LUF:RefreshAuraFilters(info[1])
								end
							end,
							hidden = function(info) return auraFilterAssignmentEmpty(info, "buffs") end,
						},
						filterbuffmatch = {
							name = L["Buff Filter Match"],
							desc = L["How to match the filter list"],
							type = "select",
							order = 3,
							values = {["id"] = L["Spell ID"], ["name"] = L["Aura Name"]},
							get = function(info)
								local db = LUF.db.profile.units[info[1]].auras.filters
								return db and db.buffMatchBy or "name"
							end,
							set = function(info, value)
								local filters = LUF:EnsureUnitAuraFilters(info[1])
								if filters then
									filters.buffMatchBy = value
									LUF:RefreshAuraFilters(info[1])
								end
							end,
							hidden = function(info)
								if auraFilterAssignmentEmpty(info, "buffs") then return true end
								local db = LUF.db.profile.units[info[1]].auras.filters
								return not db or db.buffMode == "disabled" or not db.buffMode
							end,
						},
					},
				},
				filterdebuffgroup = {
					name = L["Debuff Filter List"],
					type = "group",
					order = 30,
					inline = true,
					args = {
						filterdebufflist = {
							name = L["Select filter lists to apply to debuffs"],
							type = "multiselect",
							order = 1,
							width = "double",
							values = function()
								local t = {}
								for name in pairs(LUF.db.profile.filters or {}) do
									t[name] = name
								end
								return t
							end,
							get = function(info, key)
								return LUF:AuraFilterAssignmentHas(LUF.db.profile.units[info[1]].auras.filters, "debuffs", key)
							end,
							set = function(info, key, value)
								LUF:SetAuraFilterAssignment(info[1], "debuffs", key, value)
								LUF:RefreshAuraFilters(info[1])
							end,
						},
						filterdebuffmode = {
							name = L["Debuff Filter Mode"],
							desc = L["How to apply the debuff filter list"],
							type = "select",
							order = 2,
							values = {["disabled"] = L["Disabled"], ["whitelist"] = L["Whitelist"], ["blacklist"] = L["Blacklist"]},
							get = function(info)
								local db = LUF.db.profile.units[info[1]].auras.filters
								return db and db.debuffMode or "disabled"
							end,
							set = function(info, value)
								local filters = LUF:EnsureUnitAuraFilters(info[1])
								if filters then
									filters.debuffMode = value
									LUF:RefreshAuraFilters(info[1])
								end
							end,
							hidden = function(info) return auraFilterAssignmentEmpty(info, "debuffs") end,
						},
						filterdebuffmatch = {
							name = L["Debuff Filter Match"],
							desc = L["How to match the filter list"],
							type = "select",
							order = 3,
							values = {["id"] = L["Spell ID"], ["name"] = L["Aura Name"]},
							get = function(info)
								local db = LUF.db.profile.units[info[1]].auras.filters
								return db and db.debuffMatchBy or "name"
							end,
							set = function(info, value)
								local filters = LUF:EnsureUnitAuraFilters(info[1])
								if filters then
									filters.debuffMatchBy = value
									LUF:RefreshAuraFilters(info[1])
								end
							end,
							hidden = function(info)
								if auraFilterAssignmentEmpty(info, "debuffs") then return true end
								local db = LUF.db.profile.units[info[1]].auras.filters
								return not db or db.debuffMode == "disabled" or not db.debuffMode
							end,
						},
					},
				},
			},
		},
		["borders"] = {
			name = L["Borders"],
			type = "group",
			order = 12,
			--inline = true,
			args = {
				target = {
					name = L["On target"],
					desc = string.format(L["Highlight the frames borders when the unit is targeted"]),
					type = "toggle",
					hidden = function(info) return info[1] == "target" end,
					order = 1,
				},
				mouseover = {
					name = L["On mouseover"],
					desc = string.format(L["Highlight the frames borders when the unit is moused over"]),
					type = "toggle",
					order = 2,
				},
				aggro = {
					name = L["On aggro"],
					desc = string.format(L["Highlight the frames borders when the unit has aggro"]),
					type = "toggle",
					order = 3,
				},
				debuff = {
					name = L["On debuff"],
					desc = string.format(L["Highlight the frames borders when the unit has a debuff you or someone can remove"]),
					type = "select",
					order = 4,
					values = {[1] = OFF, [2] = L["Your own"], [3] = ACHIEVEMENTFRAME_FILTER_ALL},
				},
				size = {
					name = L["Size"],
					desc = L["Set the size."],
					type = "range",
					order = 5,
					min = 1,
					max = 10,
					step = 1,
				},
				ontop = {
					name = L["Always on Top"],
					desc = L["Border will always be on top of Frames"],
					type = "toggle",
					order = 6,
				},
			},
		},
		["highlight"] = {
			name = L["Highlight"],
			type = "group",
			order = 13,
			--inline = true,
			args = {
				target = {
					name = L["On target"],
					desc = string.format(BINDING_NAME_INTERACTTARGET),
					type = "toggle",
					hidden = function(info) return info[1] == "target" end,
					order = 1,
				},
				mouseover = {
					name = L["On mouseover"],
					desc = string.format(BINDING_NAME_INTERACTMOUSEOVER),
					type = "toggle",
					order = 2,
				},
				aggro = {
					name = L["On aggro"],
					desc = string.format(L["Highlight the frame when the unit has aggro"]),
					type = "toggle",
					order = 3,
				},
				debuff = {
					name = L["On debuff"],
					desc = string.format(L["Highlight the frame when the unit has a debuff you or someone can remove"]),
					type = "select",
					order = 4,
					values = {[1] = OFF, [2] = L["Your own"], [3] = ACHIEVEMENTFRAME_FILTER_ALL},
				},
			},
		},
		["fader"] = {
			name = L["Combat fader"],
			type = "group",
			order = 14,
			--inline = true,
			args = {
				enabled = {
					name = ENABLE,
					desc = string.format(L["Enable or disable the %s."],L["Combat fader"]),
					type = "toggle",
					order = 1,
				},
				combatAlpha = {
					name = L["Combat alpha"],
					desc = L["Set the alpha."],
					type = "range",
					order = 2,
					min = 0,
					max = 1,
					step = 0.01,
				},
				inactiveAlpha = {
					name = L["Inactive alpha"],
					desc = L["Set the alpha."],
					type = "range",
					order = 3,
					min = 0,
					max = 1,
					step = 0.01,
				},
				speedyFade = {
					name = L["Speedy fade"],
					desc = string.format(L["Enable or disable the %s."],L["Speedy fade"]),
					type = "toggle",
					order = 4,
				},
			},
		},
		["tags"] = {
			name = L["Tags"],
			type = "group",
			order = 15,
			--inline = true,
			args = {
				top = {
					name = L["Top"],
					type = "group",
					order = 1,
					inline = true,
					args = {
						left = {
							name = L["Left"],
							type = "group",
							order = 1,
							inline = true,
							args = {
								tagline = {
									name = L["Left"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						center = {
							name = L["Center"],
							type = "group",
							order = 2,
							inline = true,
							args = {
								tagline = {
									name = L["Center"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						right = {
							name = L["Right"],
							type = "group",
							order = 3,
							inline = true,
							args = {
								tagline = {
									name = L["Right"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						size = {
							name = FONT_SIZE,
							desc = L["Set the font size."],
							type = "range",
							order = 4,
							width = "double",
							min = 5,
							max = 24,
							step = 1,
						},
						font = {
							order = 5,
							type = "select",
							name = L["Font"],
							dialogControl = "LSM30_Font",
							values = getMediaData,
							get = function(info) return get(info) or LUF.db.profile.font or SML.DefaultMedia.font end,
						},
						shadow = {
							name = L["Fontshadow"],
							desc = L["Display a shadow behind the text"],
							type = "toggle",
							order = 6,
						},
						outline = {
							name = L["Fontoutline"],
							desc = L["Display an outline around the text"],
							type = "toggle",
							order = 7,
						},
					},
				},
				healthBar = {
					name = L["Health bar"],
					type = "group",
					order = 2,
					inline = true,
					args = {
						left = {
							name = L["Left"],
							type = "group",
							order = 1,
							inline = true,
							args = {
								tagline = {
									name = L["Left"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						center = {
							name = L["Center"],
							type = "group",
							order = 2,
							inline = true,
							args = {
								tagline = {
									name = L["Center"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						right = {
							name = L["Right"],
							type = "group",
							order = 3,
							inline = true,
							args = {
								tagline = {
									name = L["Right"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						size = {
							name = FONT_SIZE,
							desc = L["Set the font size."],
							type = "range",
							order = 4,
							width = "double",
							min = 5,
							max = 24,
							step = 1,
						},
						font = {
							order = 5,
							type = "select",
							name = L["Font"],
							dialogControl = "LSM30_Font",
							values = getMediaData,
							get = function(info) return get(info) or LUF.db.profile.font or SML.DefaultMedia.font end,
						},
						shadow = {
							name = L["Fontshadow"],
							desc = L["Display a shadow behind the text"],
							type = "toggle",
							order = 6,
						},
						outline = {
							name = L["Fontoutline"],
							desc = L["Display an outline around the text"],
							type = "toggle",
							order = 7,
						},
					},
				},
				powerBar = {
					name = L["Power bar"],
					type = "group",
					order = 3,
					inline = true,
					args = {
						left = {
							name = L["Left"],
							type = "group",
							order = 1,
							inline = true,
							args = {
								tagline = {
									name = L["Left"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						center = {
							name = L["Center"],
							type = "group",
							order = 2,
							inline = true,
							args = {
								tagline = {
									name = L["Center"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						right = {
							name = L["Right"],
							type = "group",
							order = 3,
							inline = true,
							args = {
								tagline = {
									name = L["Right"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						size = {
							name = FONT_SIZE,
							desc = L["Set the font size."],
							type = "range",
							order = 4,
							width = "double",
							min = 5,
							max = 24,
							step = 1,
						},
						font = {
							order = 5,
							type = "select",
							name = L["Font"],
							dialogControl = "LSM30_Font",
							values = getMediaData,
							get = function(info) return get(info) or LUF.db.profile.font or SML.DefaultMedia.font end,
						},
						shadow = {
							name = L["Fontshadow"],
							desc = L["Display a shadow behind the text"],
							type = "toggle",
							order = 6,
						},
						outline = {
							name = L["Fontoutline"],
							desc = L["Display an outline around the text"],
							type = "toggle",
							order = 7,
						},
					},
				},
				castBar = {
					name = SHOW_ARENA_ENEMY_CASTBAR_TEXT,
					type = "group",
					order = 4,	
					inline = true,
					hidden = function(info) return moduleBlacklist.castBar[info[#info-2]] end,
					args = {
						left = {
							name = L["Left"],
							type = "group",
							order = 1,
							inline = true,
							args = {
								tagline = {
									name = L["Left"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						center = {
							name = L["Center"],
							type = "group",
							order = 2,
							inline = true,
							args = {
								tagline = {
									name = L["Center"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						right = {
							name = L["Right"],
							type = "group",
							order = 3,
							inline = true,
							args = {
								tagline = {
									name = L["Right"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						size = {
							name = FONT_SIZE,
							desc = L["Set the font size."],
							type = "range",
							order = 4,
							width = "double",
							min = 5,
							max = 24,
							step = 1,
						},
						font = {
							order = 5,
							type = "select",
							name = L["Font"],
							dialogControl = "LSM30_Font",
							values = getMediaData,
							get = function(info) return get(info) or LUF.db.profile.font or SML.DefaultMedia.font end,
						},
						shadow = {
							name = L["Fontshadow"],
							desc = L["Display a shadow behind the text"],
							type = "toggle",
							order = 6,
						},
						outline = {
							name = L["Fontoutline"],
							desc = L["Display an outline around the text"],
							type = "toggle",
							order = 7,
						},
					},
				},
				emptyBar = {
					name = L["Empty bar"],
					type = "group",
					order = 5,
					inline = true,
					args = {
						left = {
							name = L["Left"],
							type = "group",
							order = 1,
							inline = true,
							args = {
								tagline = {
									name = L["Left"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						center = {
							name = L["Center"],
							type = "group",
							order = 2,
							inline = true,
							args = {
								tagline = {
									name = L["Center"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						right = {
							name = L["Right"],
							type = "group",
							order = 3,
							inline = true,
							args = {
								tagline = {
									name = L["Right"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						size = {
							name = FONT_SIZE,
							desc = L["Set the font size."],
							type = "range",
							order = 4,
							width = "double",
							min = 5,
							max = 24,
							step = 1,
						},
						font = {
							order = 5,
							type = "select",
							name = L["Font"],
							dialogControl = "LSM30_Font",
							values = getMediaData,
							get = function(info) return get(info) or LUF.db.profile.font or SML.DefaultMedia.font end,
						},
						shadow = {
							name = L["Fontshadow"],
							desc = L["Display a shadow behind the text"],
							type = "toggle",
							order = 6,
						},
						outline = {
							name = L["Fontoutline"],
							desc = L["Display an outline around the text"],
							type = "toggle",
							order = 7,
						},
					},
				},
				druidBar = {
					name = L["Druid bar"],
					type = "group",
					order = 6,
					inline = true,
					hidden = function(info) return info[1] ~= "player" or select(2,UnitClass("player")) ~= "DRUID" end,
					args = {
						left = {
							name = L["Left"],
							type = "group",
							order = 1,
							inline = true,
							args = {
								tagline = {
									name = L["Left"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						center = {
							name = L["Center"],
							type = "group",
							order = 2,
							inline = true,
							args = {
								tagline = {
									name = L["Center"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						right = {
							name = L["Right"],
							type = "group",
							order = 3,
							inline = true,
							args = {
								tagline = {
									name = L["Right"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						size = {
							name = FONT_SIZE,
							desc = L["Set the font size."],
							type = "range",
							order = 4,
							width = "double",
							min = 5,
							max = 24,
							step = 1,
						},
						font = {
							order = 5,
							type = "select",
							name = L["Font"],
							dialogControl = "LSM30_Font",
							values = getMediaData,
							get = function(info) return get(info) or LUF.db.profile.font or SML.DefaultMedia.font end,
						},
						shadow = {
							name = L["Fontshadow"],
							desc = L["Display a shadow behind the text"],
							type = "toggle",
							order = 6,
						},
						outline = {
							name = L["Fontoutline"],
							desc = L["Display an outline around the text"],
							type = "toggle",
							order = 7,
						},
					},
				},
				xpBar = {
					name = L["Xp bar"],
					type = "group",
					order = 7,
					inline = true,
					hidden = function(info) return info[1] ~= "player" and info[1] ~= "pet" end,
					args = {
						left = {
							name = L["Left"],
							type = "group",
							order = 1,
							inline = true,
							args = {
								tagline = {
									name = L["Left"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						center = {
							name = L["Center"],
							type = "group",
							order = 2,
							inline = true,
							args = {
								tagline = {
									name = L["Center"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						right = {
							name = L["Right"],
							type = "group",
							order = 3,
							inline = true,
							args = {
								tagline = {
									name = L["Right"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						size = {
							name = FONT_SIZE,
							desc = L["Set the font size."],
							type = "range",
							order = 4,
							width = "double",
							min = 5,
							max = 24,
							step = 1,
						},
						font = {
							order = 5,
							type = "select",
							name = L["Font"],
							dialogControl = "LSM30_Font",
							values = getMediaData,
							get = function(info) return get(info) or LUF.db.profile.font or SML.DefaultMedia.font end,
						},
						shadow = {
							name = L["Fontshadow"],
							desc = L["Display a shadow behind the text"],
							type = "toggle",
							order = 6,
						},
						outline = {
							name = L["Fontoutline"],
							desc = L["Display an outline around the text"],
							type = "toggle",
							order = 7,
						},
					},
				},
				bottom = {
					name = L["Bottom"],
					type = "group",
					order = 8,
					inline = true,
					args = {
						left = {
							name = L["Left"],
							type = "group",
							order = 1,
							inline = true,
							args = {
								tagline = {
									name = L["Left"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						center = {
							name = L["Center"],
							type = "group",
							order = 2,
							inline = true,
							args = {
								tagline = {
									name = L["Center"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						right = {
							name = L["Right"],
							type = "group",
							order = 3,
							inline = true,
							args = {
								tagline = {
									name = L["Right"],
									desc = L["Set the tags."],
									type = "input",
									order = 1,
								},
								size = {
									name = L["Limit"],
									desc = L["Set after which percentage of the bar to cut off."],
									type = "range",
									order = 2,
									min = 1,
									max = 100,
									step = 1,
								},
								offset = {
									name = L["Offset"],
									desc = L["Set the height."],
									type = "range",
									order = 3,
									min = -20,
									max = 20,
									step = 1,
								},
							},
						},
						size = {
							name = FONT_SIZE,
							desc = L["Set the font size."],
							type = "range",
							order = 4,
							width = "double",
							min = 5,
							max = 24,
							step = 1,
						},
						font = {
							order = 5,
							type = "select",
							name = L["Font"],
							dialogControl = "LSM30_Font",
							values = getMediaData,
							get = function(info) return get(info) or LUF.db.profile.font or SML.DefaultMedia.font end,
						},
						shadow = {
							name = L["Fontshadow"],
							desc = L["Display a shadow behind the text"],
							type = "toggle",
							order = 6,
						},
						outline = {
							name = L["Fontoutline"],
							desc = L["Display an outline around the text"],
							type = "toggle",
							order = 7,
						},
					},
				},
			},
		},
		["indicators"] = {
			name = L["Indicators"],
			type = "group",
			order = 16,
			--inline = true,
			args = {
				raidTarget = {
					name = RAID_TARGET_ICON,
					type = "group",
					order = 1,
					inline = true,
					hidden = function(info) return not LUF.db.profile.units[info[1]].indicators[info[3]] end,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],RAID_TARGET_ICON),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 5,
							max = 40,
							step = 1,
						},
						anchorPoint = {
							name = L["Point"],
							desc = L["Anchor point"],
							type = "select",
							order = 3,
							values = {["TOPLEFT"] = L["Top left"], ["LEFT"] = L["Left"], ["BOTTOMLEFT"] = L["Bottom left"], ["TOP"] = L["Top"], ["CENTER"] = L["Center"], ["BOTTOM"] = L["Bottom"], ["TOPRIGHT"] = L["Top right"], ["RIGHT"] = L["Right"], ["BOTTOMRIGHT"] = L["Bottom right"]},
						},
						x = {
							name = L["X Position"],
							desc = L["Set the X coordinate."],
							type = "range",
							order = 4,
							min = -50,
							max = 50,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Set the Y coordinate."],
							type = "range",
							order = 5,
							min = -100,
							max = 100,
							step = 1,
						},
					},
				},
				class = {
					name = CLASS,
					type = "group",
					order = 2,
					inline = true,
					hidden = function(info) return not LUF.db.profile.units[info[1]].indicators[info[3]] end,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],CLASS),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 5,
							max = 40,
							step = 1,
						},
						anchorPoint = {
							name = L["Point"],
							desc = L["Anchor point"],
							type = "select",
							order = 3,
							values = {["TOPLEFT"] = L["Top left"], ["LEFT"] = L["Left"], ["BOTTOMLEFT"] = L["Bottom left"], ["TOP"] = L["Top"], ["CENTER"] = L["Center"], ["BOTTOM"] = L["Bottom"], ["TOPRIGHT"] = L["Top right"], ["RIGHT"] = L["Right"], ["BOTTOMRIGHT"] = L["Bottom right"]},
						},
						x = {
							name = L["X Position"],
							desc = L["Set the X coordinate."],
							type = "range",
							order = 4,
							min = -50,
							max = 50,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Set the Y coordinate."],
							type = "range",
							order = 5,
							min = -100,
							max = 100,
							step = 1,
						},
					},
				},
				masterLoot = {
					name = MASTER_LOOTER,
					type = "group",
					order = 3,
					inline = true,
					hidden = function(info) return not LUF.db.profile.units[info[1]].indicators[info[3]] end,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],MASTER_LOOTER),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 5,
							max = 40,
							step = 1,
						},
						anchorPoint = {
							name = L["Point"],
							desc = L["Anchor point"],
							type = "select",
							order = 3,
							values = {["TOPLEFT"] = L["Top left"], ["LEFT"] = L["Left"], ["BOTTOMLEFT"] = L["Bottom left"], ["TOP"] = L["Top"], ["CENTER"] = L["Center"], ["BOTTOM"] = L["Bottom"], ["TOPRIGHT"] = L["Top right"], ["RIGHT"] = L["Right"], ["BOTTOMRIGHT"] = L["Bottom right"]},
						},
						x = {
							name = L["X Position"],
							desc = L["Set the X coordinate."],
							type = "range",
							order = 4,
							min = -50,
							max = 50,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Set the Y coordinate."],
							type = "range",
							order = 5,
							min = -100,
							max = 100,
							step = 1,
						},
					},
				},
				leader = {
					name = LEADER,
					type = "group",
					order = 4,
					inline = true,
					hidden = function(info) return not LUF.db.profile.units[info[1]].indicators[info[3]] end,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],LEADER),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 5,
							max = 40,
							step = 1,
						},
						anchorPoint = {
							name = L["Point"],
							desc = L["Anchor point"],
							type = "select",
							order = 3,
							values = {["TOPLEFT"] = L["Top left"], ["LEFT"] = L["Left"], ["BOTTOMLEFT"] = L["Bottom left"], ["TOP"] = L["Top"], ["CENTER"] = L["Center"], ["BOTTOM"] = L["Bottom"], ["TOPRIGHT"] = L["Top right"], ["RIGHT"] = L["Right"], ["BOTTOMRIGHT"] = L["Bottom right"]},
						},
						x = {
							name = L["X Position"],
							desc = L["Set the X coordinate."],
							type = "range",
							order = 4,
							min = -50,
							max = 50,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Set the Y coordinate."],
							type = "range",
							order = 5,
							min = -100,
							max = 100,
							step = 1,
						},
					},
				},
				pvp = {
					name = PVP_FLAG,
					type = "group",
					order = 5,
					inline = true,
					hidden = function(info) return not LUF.db.profile.units[info[1]].indicators[info[3]] end,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],PVP_FLAG),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 5,
							max = 40,
							step = 1,
						},
						anchorPoint = {
							name = L["Point"],
							desc = L["Anchor point"],
							type = "select",
							order = 3,
							values = {["TOPLEFT"] = L["Top left"], ["LEFT"] = L["Left"], ["BOTTOMLEFT"] = L["Bottom left"], ["TOP"] = L["Top"], ["CENTER"] = L["Center"], ["BOTTOM"] = L["Bottom"], ["TOPRIGHT"] = L["Top right"], ["RIGHT"] = L["Right"], ["BOTTOMRIGHT"] = L["Bottom right"]},
						},
						x = {
							name = L["X Position"],
							desc = L["Set the X coordinate."],
							type = "range",
							order = 4,
							min = -50,
							max = 50,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Set the Y coordinate."],
							type = "range",
							order = 5,
							min = -100,
							max = 100,
							step = 1,
						},
					},
				},
				pvprank = {
					name = RANK,
					type = "group",
					order = 6,
					inline = true,
					hidden = function(info) return not LUF.db.profile.units[info[1]].indicators[info[3]] end,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],RANK),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 5,
							max = 40,
							step = 1,
						},
						anchorPoint = {
							name = L["Point"],
							desc = L["Anchor point"],
							type = "select",
							order = 3,
							values = {["TOPLEFT"] = L["Top left"], ["LEFT"] = L["Left"], ["BOTTOMLEFT"] = L["Bottom left"], ["TOP"] = L["Top"], ["CENTER"] = L["Center"], ["BOTTOM"] = L["Bottom"], ["TOPRIGHT"] = L["Top right"], ["RIGHT"] = L["Right"], ["BOTTOMRIGHT"] = L["Bottom right"]},
						},
						x = {
							name = L["X Position"],
							desc = L["Set the X coordinate."],
							type = "range",
							order = 4,
							min = -50,
							max = 50,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Set the Y coordinate."],
							type = "range",
							order = 5,
							min = -100,
							max = 100,
							step = 1,
						},
					},
				},
				ready = {
					name = READY_CHECK,
					type = "group",
					order = 7,
					inline = true,
					hidden = function(info) return not LUF.db.profile.units[info[1]].indicators[info[3]] end,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],READY_CHECK),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 5,
							max = 40,
							step = 1,
						},
						anchorPoint = {
							name = L["Point"],
							desc = L["Anchor point"],
							type = "select",
							order = 3,
							values = {["TOPLEFT"] = L["Top left"], ["LEFT"] = L["Left"], ["BOTTOMLEFT"] = L["Bottom left"], ["TOP"] = L["Top"], ["CENTER"] = L["Center"], ["BOTTOM"] = L["Bottom"], ["TOPRIGHT"] = L["Top right"], ["RIGHT"] = L["Right"], ["BOTTOMRIGHT"] = L["Bottom right"]},
						},
						x = {
							name = L["X Position"],
							desc = L["Set the X coordinate."],
							type = "range",
							order = 4,
							min = -50,
							max = 50,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Set the Y coordinate."],
							type = "range",
							order = 5,
							min = -100,
							max = 100,
							step = 1,
						},
					},
				},
				status = {
					name = PLAYER_STATUS,
					type = "group",
					order = 8,
					inline = true,
					hidden = function(info) return not LUF.db.profile.units[info[1]].indicators[info[3]] end,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],PLAYER_STATUS),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 5,
							max = 40,
							step = 1,
						},
						anchorPoint = {
							name = L["Point"],
							desc = L["Anchor point"],
							type = "select",
							order = 3,
							values = {["TOPLEFT"] = L["Top left"], ["LEFT"] = L["Left"], ["BOTTOMLEFT"] = L["Bottom left"], ["TOP"] = L["Top"], ["CENTER"] = L["Center"], ["BOTTOM"] = L["Bottom"], ["TOPRIGHT"] = L["Top right"], ["RIGHT"] = L["Right"], ["BOTTOMRIGHT"] = L["Bottom right"]},
						},
						x = {
							name = L["X Position"],
							desc = L["Set the X coordinate."],
							type = "range",
							order = 4,
							min = -50,
							max = 50,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Set the Y coordinate."],
							type = "range",
							order = 5,
							min = -100,
							max = 100,
							step = 1,
						},
					},
				},
				rezz = {
					name = RESURRECT,
					type = "group",
					order = 9,
					inline = true,
					hidden = function(info) return not LUF.db.profile.units[info[1]].indicators[info[3]] end,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],RESURRECT),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 5,
							max = 40,
							step = 1,
						},
						anchorPoint = {
							name = L["Point"],
							desc = L["Anchor point"],
							type = "select",
							order = 3,
							values = {["TOPLEFT"] = L["Top left"], ["LEFT"] = L["Left"], ["BOTTOMLEFT"] = L["Bottom left"], ["TOP"] = L["Top"], ["CENTER"] = L["Center"], ["BOTTOM"] = L["Bottom"], ["TOPRIGHT"] = L["Top right"], ["RIGHT"] = L["Right"], ["BOTTOMRIGHT"] = L["Bottom right"]},
						},
						x = {
							name = L["X Position"],
							desc = L["Set the X coordinate."],
							type = "range",
							order = 4,
							min = -50,
							max = 50,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Set the Y coordinate."],
							type = "range",
							order = 5,
							min = -100,
							max = 100,
							step = 1,
						},
					},
				},
				happiness = {
					name = HAPPINESS,
					type = "group",
					order = 10,
					inline = true,
					hidden = function(info) return not LUF.db.profile.units[info[1]].indicators[info[3]] end,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],HAPPINESS),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 5,
							max = 40,
							step = 1,
						},
						anchorPoint = {
							name = L["Point"],
							desc = L["Anchor point"],
							type = "select",
							order = 3,
							values = {["TOPLEFT"] = L["Top left"], ["LEFT"] = L["Left"], ["BOTTOMLEFT"] = L["Bottom left"], ["TOP"] = L["Top"], ["CENTER"] = L["Center"], ["BOTTOM"] = L["Bottom"], ["TOPRIGHT"] = L["Top right"], ["RIGHT"] = L["Right"], ["BOTTOMRIGHT"] = L["Bottom right"]},
						},
						x = {
							name = L["X Position"],
							desc = L["Set the X coordinate."],
							type = "range",
							order = 4,
							min = -50,
							max = 50,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Set the Y coordinate."],
							type = "range",
							order = 5,
							min = -100,
							max = 100,
							step = 1,
						},
					},
				},
				elite = {
					name = ELITE,
					type = "group",
					order = 11,
					inline = true,
					hidden = function(info) return not LUF.db.profile.units[info[1]].indicators[info[3]] end,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],ELITE),
							type = "toggle",
							order = 1,
							set = function(info, value)
								set(info, value)
								if info[1] == "player" then
									LUF.oUF.LUF_fakePlayerClassification = LUF.db.profile.units.player.indicators.elite.enabled and LUF.db.profile.units.player.indicators.elite.type or nil
								elseif info[1] == "pet" then
									LUF.oUF.LUF_fakePetClassification = LUF.db.profile.units.pet.indicators.elite.enabled and LUF.db.profile.units.pet.indicators.elite.type or nil
								else
									return
								end
								LUF:ReloadAll()
							end,
						},
						side = {
							name = L["Side"],
							desc = L["Elite indicator alignment"],
							type = "select",
							order = 2,
							values = {["LEFT"] = L["Left"], ["RIGHT"] = L["Right"]},
						},
						type = {
							name = TYPE,
							desc = TYPE,
							type = "select",
							order = 3,
							hidden = function(info) return (info[1] ~= "player" and info[1] ~= "pet") end,
							values = {["elite"] = ELITE, ["rare"] = ITEM_QUALITY3_DESC},
							set = function(info, value)
								set(info, value)
								if info[1] == "player" then
									LUF.oUF.LUF_fakePlayerClassification = LUF.db.profile.units.player.indicators.elite.enabled and LUF.db.profile.units.player.indicators.elite.type or nil
								elseif info[1] == "pet" then
									LUF.oUF.LUF_fakePetClassification = LUF.db.profile.units.pet.indicators.elite.enabled and LUF.db.profile.units.pet.indicators.elite.type or nil
								else
									return
								end
								LUF:ReloadAll()
							end,
						},
					},
				},
				role = {
					name = RAID.." "..ROLE,
					type = "group",
					order = 12,
					inline = true,
					hidden = function(info) return not LUF.db.profile.units[info[1]].indicators[info[3]] end,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."] .. "\n%s, %s", ROLE, MAINTANK, MAINASSIST),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 5,
							max = 40,
							step = 1,
						},
						anchorPoint = {
							name = L["Point"],
							desc = L["Anchor point"],
							type = "select",
							order = 3,
							values = {["TOPLEFT"] = L["Top left"], ["LEFT"] = L["Left"], ["BOTTOMLEFT"] = L["Bottom left"], ["TOP"] = L["Top"], ["CENTER"] = L["Center"], ["BOTTOM"] = L["Bottom"], ["TOPRIGHT"] = L["Top right"], ["RIGHT"] = L["Right"], ["BOTTOMRIGHT"] = L["Bottom right"]},
						},
						x = {
							name = L["X Position"],
							desc = L["Set the X coordinate."],
							type = "range",
							order = 4,
							min = -50,
							max = 50,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Set the Y coordinate."],
							type = "range",
							order = 5,
							min = -100,
							max = 100,
							step = 1,
						},
					},
				},
				groupRole = {
					name = GROUP.." "..ROLE,
					type = "group",
					order = 13,
					inline = true,
					hidden = function(info) return not LUF.db.profile.units[info[1]].indicators[info[3]] end,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."] .. "\n%s, %s, %s", ROLE, DAMAGER, HEALER, TANK),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 5,
							max = 40,
							step = 1,
						},
						anchorPoint = {
							name = L["Point"],
							desc = L["Anchor point"],
							type = "select",
							order = 3,
							values = {["TOPLEFT"] = L["Top left"], ["LEFT"] = L["Left"], ["BOTTOMLEFT"] = L["Bottom left"], ["TOP"] = L["Top"], ["CENTER"] = L["Center"], ["BOTTOM"] = L["Bottom"], ["TOPRIGHT"] = L["Top right"], ["RIGHT"] = L["Right"], ["BOTTOMRIGHT"] = L["Bottom right"]},
						},
						x = {
							name = L["X Position"],
							desc = L["Set the X coordinate."],
							type = "range",
							order = 4,
							min = -50,
							max = 50,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Set the Y coordinate."],
							type = "range",
							order = 5,
							min = -100,
							max = 100,
							step = 1,
						},
					},
				},
			},
		},
		["combatText"] = {
			name = L["Combat text"],
			type = "group",
			order = 17,
			hidden = function(info) return LUF.fakeUnits[info[1]] end,
			--inline = true,
			args = {
				enabled = {
					name = ENABLE,
					desc = string.format(L["Enable or disable the %s."],L["Combat text"]),
					type = "toggle",
					order = 1,
				},
				font = {
					name = L["Font"],
					desc = L["Set the font"],
					type = "select",
					order = 2,
					dialogControl = "LSM30_Font",
					values = getMediaData,
					get = function(info) return get(info) or LUF.db.profile.font or SML.DefaultMedia.font end,
				},
				size = {
					name = FONT_SIZE,
					desc = L["Set the font size."],
					type = "range",
					order = 3,
					min = 5,
					max = 40,
					step = 1,
				},
				x = {
					name = L["X Position"],
					desc = L["Offset"],
					type = "range",
					min = -100,
					max = 100,
					order = 4,
					step = 1,
				},
				y = {
					name = L["Y Position"],
					desc = L["Offset"],
					type = "range",
					min = -100,
					max = 100,
					order = 5,
					step = 1,
				},
			},
		},
		["squares"] = {
			name = L["Squares"],
			type = "group",
			order = 18,
			--inline = true,
			args = {
				topleft = {
					name = L["Top left"],
					type = "group",
					order = 1,
					inline = true,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],L["Top left"]),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 4,
							max = 40,
							step = 1,
						},
						type = {
							name = TYPE,
							desc = L["What the indicator should display."],
							type = "select",
							order = 3,
							values = SQUARE_TYPE_VALUES,
							set = function(info, value) set(info,value) LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].value = nil ACR:NotifyChange("LunaUnitFrames") end,
						},
						matchMode = {
							name = L["Match"],
							desc = L["Exact uses spell ID or full name (fast). Partial matches substrings (slow)."],
							type = "select",
							order = 5,
							values = SQUARE_MATCH_MODE_VALUES,
							sorting = SQUARE_MATCH_MODE_SORTING,
							get = squareMatchModeGet,
							set = squareMatchModeSet,
							hidden = function(info) return not squareIsAuraMatchType(info) end,
						},
						value = {
							name = squareValueLabel,
							desc = squareValueDesc,
							type = "input",
							order = 4,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" end,
							validate = validateMissingBuffInput,
						},
						timer = {
							name = L["Timer"],
							desc = string.format(L["Enable or disable the %s."],L["Timer"]),
							type = "toggle",
							order = 6,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "missing" end,
						},
						texture = {
							name = L["Texture"],
							desc = L["Show the spell texture instead of its type color."],
							type = "toggle",
							order = 7,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" end,
						},
						x = {
							name = L["X Position"],
							desc = L["Offset"],
							type = "range",
							min = -50,
							max = 50,
							order = 8,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Offset"],
							type = "range",
							min = -50,
							max = 50,
							order = 9,
							step = 1,
						},
					},
				},
				top = {
					name = L["Top"],
					type = "group",
					order = 2,
					inline = true,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],L["Bottom right"]),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 4,
							max = 40,
							step = 1,
						},
						type = {
							name = TYPE,
							desc = L["What the indicator should display."],
							type = "select",
							order = 3,
							values = SQUARE_TYPE_VALUES,
							set = function(info, value) set(info,value) LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].value = nil ACR:NotifyChange("LunaUnitFrames") end,
						},
						matchMode = {
							name = L["Match"],
							desc = L["Exact uses spell ID or full name (fast). Partial matches substrings (slow)."],
							type = "select",
							order = 5,
							values = SQUARE_MATCH_MODE_VALUES,
							sorting = SQUARE_MATCH_MODE_SORTING,
							get = squareMatchModeGet,
							set = squareMatchModeSet,
							hidden = function(info) return not squareIsAuraMatchType(info) end,
						},
						value = {
							name = squareValueLabel,
							desc = squareValueDesc,
							type = "input",
							order = 4,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" end,
							validate = validateMissingBuffInput,
						},
						timer = {
							name = L["Timer"],
							desc = string.format(L["Enable or disable the %s."],L["Timer"]),
							type = "toggle",
							order = 6,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "missing" end,
						},
						texture = {
							name = L["Texture"],
							desc = L["Show the spell texture instead of its type color."],
							type = "toggle",
							order = 7,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" end,
						},
						x = {
							name = L["X Position"],
							desc = L["Offset"],
							type = "range",
							min = -50,
							max = 50,
							order = 8,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Offset"],
							type = "range",
							min = -50,
							max = 50,
							order = 9,
							step = 1,
						},
					},
				},
				topright = {
					name = L["Top right"],
					type = "group",
					order = 3,
					inline = true,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],L["Top right"]),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 4,
							max = 40,
							step = 1,
						},
						type = {
							name = TYPE,
							desc = L["What the indicator should display."],
							type = "select",
							order = 3,
							values = SQUARE_TYPE_VALUES,
							set = function(info, value) set(info,value) LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].value = nil ACR:NotifyChange("LunaUnitFrames") end,
						},
						matchMode = {
							name = L["Match"],
							desc = L["Exact uses spell ID or full name (fast). Partial matches substrings (slow)."],
							type = "select",
							order = 5,
							values = SQUARE_MATCH_MODE_VALUES,
							sorting = SQUARE_MATCH_MODE_SORTING,
							get = squareMatchModeGet,
							set = squareMatchModeSet,
							hidden = function(info) return not squareIsAuraMatchType(info) end,
						},
						value = {
							name = squareValueLabel,
							desc = squareValueDesc,
							type = "input",
							order = 4,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" end,
							validate = validateMissingBuffInput,
						},
						timer = {
							name = L["Timer"],
							desc = string.format(L["Enable or disable the %s."],L["Timer"]),
							type = "toggle",
							order = 6,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "missing" end,
						},
						texture = {
							name = L["Texture"],
							desc = L["Show the spell texture instead of its type color."],
							type = "toggle",
							order = 7,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" end,
						},
						x = {
							name = L["X Position"],
							desc = L["Offset"],
							type = "range",
							min = -50,
							max = 50,
							order = 8,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Offset"],
							type = "range",
							min = -50,
							max = 50,
							order = 9,
							step = 1,
						},
					},
				},
				leftcenter = {
					name = L["Left Center"],
					type = "group",
					order = 4,
					inline = true,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],L["Left Center"]),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 4,
							max = 40,
							step = 1,
						},
						type = {
							name = TYPE,
							desc = L["What the indicator should display."],
							type = "select",
							order = 3,
							values = SQUARE_TYPE_VALUES,
							set = function(info, value) set(info,value) LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].value = nil ACR:NotifyChange("LunaUnitFrames") end,
						},
						matchMode = {
							name = L["Match"],
							desc = L["Exact uses spell ID or full name (fast). Partial matches substrings (slow)."],
							type = "select",
							order = 5,
							values = SQUARE_MATCH_MODE_VALUES,
							sorting = SQUARE_MATCH_MODE_SORTING,
							get = squareMatchModeGet,
							set = squareMatchModeSet,
							hidden = function(info) return not squareIsAuraMatchType(info) end,
						},
						value = {
							name = squareValueLabel,
							desc = squareValueDesc,
							type = "input",
							order = 4,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" end,
							validate = validateMissingBuffInput,
						},
						timer = {
							name = L["Timer"],
							desc = string.format(L["Enable or disable the %s."],L["Timer"]),
							type = "toggle",
							order = 6,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "missing" end,
						},
						texture = {
							name = L["Texture"],
							desc = L["Show the spell texture instead of its type color."],
							type = "toggle",
							order = 7,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" end,
						},
						x = {
							name = L["X Position"],
							desc = L["Offset"],
							type = "range",
							min = -50,
							max = 50,
							order = 8,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Offset"],
							type = "range",
							min = -50,
							max = 50,
							order = 9,
							step = 1,
						},
					},
				},
				center = {
					name = L["Center"],
					type = "group",
					order = 5,
					inline = true,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],L["Center"]),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 4,
							max = 40,
							step = 1,
						},
						type = {
							name = TYPE,
							desc = L["What the indicator should display."],
							type = "select",
							order = 3,
							values = SQUARE_TYPE_VALUES,
							set = function(info, value) set(info,value) LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].value = nil ACR:NotifyChange("LunaUnitFrames") end,
						},
						matchMode = {
							name = L["Match"],
							desc = L["Exact uses spell ID or full name (fast). Partial matches substrings (slow)."],
							type = "select",
							order = 5,
							values = SQUARE_MATCH_MODE_VALUES,
							sorting = SQUARE_MATCH_MODE_SORTING,
							get = squareMatchModeGet,
							set = squareMatchModeSet,
							hidden = function(info) return not squareIsAuraMatchType(info) end,
						},
						value = {
							name = squareValueLabel,
							desc = squareValueDesc,
							type = "input",
							order = 4,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" end,
							validate = validateMissingBuffInput,
						},
						timer = {
							name = L["Timer"],
							desc = string.format(L["Enable or disable the %s."],L["Timer"]),
							type = "toggle",
							order = 6,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "missing" end,
						},
						texture = {
							name = L["Texture"],
							desc = L["Show the spell texture instead of its type color."],
							type = "toggle",
							order = 7,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" end,
						},
						x = {
							name = L["X Position"],
							desc = L["Offset"],
							type = "range",
							min = -50,
							max = 50,
							order = 8,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Offset"],
							type = "range",
							min = -50,
							max = 50,
							order = 9,
							step = 1,
						},
					},
				},
				rightcenter = {
					name = L["Right Center"],
					type = "group",
					order = 6,
					inline = true,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],L["Right Center"]),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 4,
							max = 40,
							step = 1,
						},
						type = {
							name = TYPE,
							desc = L["What the indicator should display."],
							type = "select",
							order = 3,
							values = SQUARE_TYPE_VALUES,
							set = function(info, value) set(info,value) LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].value = nil ACR:NotifyChange("LunaUnitFrames") end,
						},
						matchMode = {
							name = L["Match"],
							desc = L["Exact uses spell ID or full name (fast). Partial matches substrings (slow)."],
							type = "select",
							order = 5,
							values = SQUARE_MATCH_MODE_VALUES,
							sorting = SQUARE_MATCH_MODE_SORTING,
							get = squareMatchModeGet,
							set = squareMatchModeSet,
							hidden = function(info) return not squareIsAuraMatchType(info) end,
						},
						value = {
							name = squareValueLabel,
							desc = squareValueDesc,
							type = "input",
							order = 4,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" end,
							validate = validateMissingBuffInput,
						},
						timer = {
							name = L["Timer"],
							desc = string.format(L["Enable or disable the %s."],L["Timer"]),
							type = "toggle",
							order = 6,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "missing" end,
						},
						texture = {
							name = L["Texture"],
							desc = L["Show the spell texture instead of its type color."],
							type = "toggle",
							order = 7,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" end,
						},
						x = {
							name = L["X Position"],
							desc = L["Offset"],
							type = "range",
							min = -50,
							max = 50,
							order = 8,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Offset"],
							type = "range",
							min = -50,
							max = 50,
							order = 9,
							step = 1,
						},
					},
				},
				bottomleft = {
					name = L["Bottom left"],
					type = "group",
					order = 7,
					inline = true,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],L["Bottom left"]),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 4,
							max = 40,
							step = 1,
						},
						type = {
							name = TYPE,
							desc = L["What the indicator should display."],
							type = "select",
							order = 3,
							values = SQUARE_TYPE_VALUES,
							set = function(info, value) set(info,value) LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].value = nil ACR:NotifyChange("LunaUnitFrames") end,
						},
						matchMode = {
							name = L["Match"],
							desc = L["Exact uses spell ID or full name (fast). Partial matches substrings (slow)."],
							type = "select",
							order = 5,
							values = SQUARE_MATCH_MODE_VALUES,
							sorting = SQUARE_MATCH_MODE_SORTING,
							get = squareMatchModeGet,
							set = squareMatchModeSet,
							hidden = function(info) return not squareIsAuraMatchType(info) end,
						},
						value = {
							name = squareValueLabel,
							desc = squareValueDesc,
							type = "input",
							order = 4,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" end,
							validate = validateMissingBuffInput,
						},
						timer = {
							name = L["Timer"],
							desc = string.format(L["Enable or disable the %s."],L["Timer"]),
							type = "toggle",
							order = 6,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "missing" end,
						},
						texture = {
							name = L["Texture"],
							desc = L["Show the spell texture instead of its type color."],
							type = "toggle",
							order = 7,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" end,
						},
						x = {
							name = L["X Position"],
							desc = L["Offset"],
							type = "range",
							min = -50,
							max = 50,
							order = 8,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Offset"],
							type = "range",
							min = -50,
							max = 50,
							order = 9,
							step = 1,
						},
					},
				},
				bottom = {
					name = L["Bottom"],
					type = "group",
					order = 8,
					inline = true,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],L["Bottom right"]),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 4,
							max = 40,
							step = 1,
						},
						type = {
							name = TYPE,
							desc = L["What the indicator should display."],
							type = "select",
							order = 3,
							values = SQUARE_TYPE_VALUES,
							set = function(info, value) set(info,value) LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].value = nil ACR:NotifyChange("LunaUnitFrames") end,
						},
						matchMode = {
							name = L["Match"],
							desc = L["Exact uses spell ID or full name (fast). Partial matches substrings (slow)."],
							type = "select",
							order = 5,
							values = SQUARE_MATCH_MODE_VALUES,
							sorting = SQUARE_MATCH_MODE_SORTING,
							get = squareMatchModeGet,
							set = squareMatchModeSet,
							hidden = function(info) return not squareIsAuraMatchType(info) end,
						},
						value = {
							name = squareValueLabel,
							desc = squareValueDesc,
							type = "input",
							order = 4,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" end,
							validate = validateMissingBuffInput,
						},
						timer = {
							name = L["Timer"],
							desc = string.format(L["Enable or disable the %s."],L["Timer"]),
							type = "toggle",
							order = 6,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "missing" end,
						},
						texture = {
							name = L["Texture"],
							desc = L["Show the spell texture instead of its type color."],
							type = "toggle",
							order = 7,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" end,
						},
						x = {
							name = L["X Position"],
							desc = L["Offset"],
							type = "range",
							min = -50,
							max = 50,
							order = 8,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Offset"],
							type = "range",
							min = -50,
							max = 50,
							order = 9,
							step = 1,
						},
					},
				},
				bottomright = {
					name = L["Bottom right"],
					type = "group",
					order = 9,
					inline = true,
					args = {
						enabled = {
							name = ENABLE,
							desc = string.format(L["Enable or disable the %s."],L["Bottom right"]),
							type = "toggle",
							order = 1,
						},
						size = {
							name = L["Size"],
							desc = L["Set the size."],
							type = "range",
							order = 2,
							min = 4,
							max = 40,
							step = 1,
						},
						type = {
							name = TYPE,
							desc = L["What the indicator should display."],
							type = "select",
							order = 3,
							values = SQUARE_TYPE_VALUES,
							set = function(info, value) set(info,value) LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].value = nil ACR:NotifyChange("LunaUnitFrames") end,
						},
						matchMode = {
							name = L["Match"],
							desc = L["Exact uses spell ID or full name (fast). Partial matches substrings (slow)."],
							type = "select",
							order = 5,
							values = SQUARE_MATCH_MODE_VALUES,
							sorting = SQUARE_MATCH_MODE_SORTING,
							get = squareMatchModeGet,
							set = squareMatchModeSet,
							hidden = function(info) return not squareIsAuraMatchType(info) end,
						},
						value = {
							name = squareValueLabel,
							desc = squareValueDesc,
							type = "input",
							order = 4,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" end,
							validate = validateMissingBuffInput,
						},
						timer = {
							name = L["Timer"],
							desc = string.format(L["Enable or disable the %s."],L["Timer"]),
							type = "toggle",
							order = 6,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "missing" end,
						},
						texture = {
							name = L["Texture"],
							desc = L["Show the spell texture instead of its type color."],
							type = "toggle",
							order = 7,
							hidden = function(info) return LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "aggro" or LUF.db.profile.units[info[#info-3]].squares[info[#info-1]].type == "legacythreat" end,
						},
						x = {
							name = L["X Position"],
							desc = L["Offset"],
							type = "range",
							min = -50,
							max = 50,
							order = 8,
							step = 1,
						},
						y = {
							name = L["Y Position"],
							desc = L["Offset"],
							type = "range",
							min = -50,
							max = 50,
							order = 9,
							step = 1,
						},
					},
				},
			},
		},
		["xpBar"] = {
			name = L["Xp bar"],
			type = "group",
			order = -6,
			--inline = true,
			hidden = function(info) return not (info[1] == "player" or info[1] == "pet") end,
			args = {
				enabled = {
					name = ENABLE,
					desc = string.format(L["Enable or disable the %s."],L["Xp bar"]),
					type = "toggle",
					order = 1,
				},
				background = {
					name = BACKGROUND,
					desc = string.format(L["Enable or disable the %s."], BACKGROUND),
					type = "toggle",
					order = 2,
				},
				backgroundAlpha = {
					name = L["Background alpha"],
					desc = L["Set the background alpha."],
					type = "range",
					order = 3,
					min = 0,
					max = 1,
					step = 0.01,
				},
				height = {
					name = L["Height"],
					desc = L["Set the height."],
					type = "range",
					order = 4,
					min = 1,
					max = 10,
					step = 0.1,
				},
				order = {
					name = L["Order"],
					desc = L["Set the order priority."],
					type = "range",
					order = 5,
					min = 0,
					max = 100,
					step = 5,
				},
				alpha = {
					name = OPACITY,
					desc = L["Set the alpha."],
					type = "range",
					order = 6,
					min = 0,
					max = 1,
					step = 0.01,
				},
				mouse = {
					name = L["Mouse interaction"],
					desc = L["This enables xp tooltips but disables clicks or vice versa"],
					type = "toggle",
					disabled = Lockdown,
					order = 7,
				},
				statusbar = {
					order = 8,
					type = "select",
					name = L["Bar texture"],
					dialogControl = "LSM30_Statusbar",
					values = getMediaData,
					get = function(info) return get(info) or LUF.db.profile.statusbar or SML.DefaultMedia.statusbar end,
				},
				posSlot = {
					name = L["Bar Group"],
					desc = L["Select the bar stack"],
					type = "select",
					order = 9,
					values = {["LEFT"] = L["Left Group"], ["RIGHT"] = L["Right Group"], ["CENTER"] = L["Center Group"]},
				},
			},
		},
		["druidBar"] = {
			name = L["Druid bar"],
			type = "group",
			order = -5,
			--inline = true,
			hidden = function(info) return info[1] ~= "player" or select(2,UnitClass("player")) ~= "DRUID" end,
			args = {
				enabled = {
					name = ENABLE,
					desc = string.format(L["Enable or disable the %s."],L["Druid bar"]),
					type = "toggle",
					order = 1,
				},
				autoHide = {
					name = L["Auto hide"],
					desc = string.format(L["Hide when inactive"]),
					type = "toggle",
					order = 2,
				},
				ticker = {
					name = L["Ticker"],
					desc = L["Since mana/energy regenerate in ticks, show a timer for it"],
					type = "toggle",
					order = 3,
				},
				hideticker = {
					name = L["Autohide ticker"],
					desc = L["Hide the ticker when it's not needed"],
					type = "toggle",
					order = 4,
				},
				fivesecond = {
					name = L["Five second rule"],
					desc = L["Show a timer for the five second rule"],
					type = "toggle",
					order = 5,
				},
				background = {
					name = BACKGROUND,
					desc = string.format(L["Enable or disable the %s."], BACKGROUND),
					type = "toggle",
					order = 6,
				},
				backgroundAlpha = {
					name = L["Background alpha"],
					desc = L["Set the background alpha."],
					type = "range",
					order = 7,
					min = 0,
					max = 1,
					step = 0.01,
				},
				height = {
					name = L["Height"],
					desc = L["Set the height."],
					type = "range",
					order = 8,
					min = 1,
					max = 10,
					step = 0.1,
				},
				order = {
					name = L["Order"],
					desc = L["Set the order priority."],
					type = "range",
					order = 9,
					min = 0,
					max = 100,
					step = 5,
				},
				statusbar = {
					order = 10,
					type = "select",
					name = L["Bar texture"],
					dialogControl = "LSM30_Statusbar",
					values = getMediaData,
					get = function(info) return get(info) or LUF.db.profile.statusbar or SML.DefaultMedia.statusbar end,
				},
				vertical = {
					name = L["Vertical"],
					desc = L["Set the bar vertical."],
					type = "toggle",
					order = 11,
				},
				posSlot = {
					name = L["Bar Group"],
					desc = L["Select the bar stack"],
					type = "select",
					order = 12,
					values = {["LEFT"] = L["Left Group"], ["RIGHT"] = L["Right Group"], ["CENTER"] = L["Center Group"]},
				},
			},
		},
		["reckStacks"] = {
			name = L["Reckoning stacks"],
			type = "group",
			order = -4,
			--inline = true,
			hidden = function(info) return info[1] ~= "player" or select(2,UnitClass("player")) ~= "PALADIN" end,
			args = {
				enabled = {
					name = ENABLE,
					desc = string.format(L["Enable or disable the %s."],L["Reckoning stacks"]),
					type = "toggle",
					order = 1,
				},
				autoHide = {
					name = L["Auto hide"],
					desc = string.format(L["Hide when inactive"]),
					type = "toggle",
					order = 3,
				},
				background = {
					name = BACKGROUND,
					desc = string.format(L["Enable or disable the %s."], BACKGROUND),
					type = "toggle",
					order = 4,
				},
				backgroundAlpha = {
					name = L["Background alpha"],
					desc = L["Set the background alpha."],
					type = "range",
					order = 5,
					min = 0,
					max = 1,
					step = 0.01,
				},
				height = {
					name = L["Height"],
					desc = L["Set the height."],
					type = "range",
					order = 6,
					min = 1,
					max = 10,
					step = 0.1,
				},
				order = {
					name = L["Order"],
					desc = L["Set the order priority."],
					type = "range",
					order = 7,
					min = 0,
					max = 100,
					step = 5,
				},
				growth = {
					name = L["Growth direction"],
					desc = L["Growth direction"],
					type = "select",
					order = 8,
					values = {["LEFT"] = L["Left"], ["RIGHT"] = L["Right"]},
				},
				statusbar = {
					order = 9,
					type = "select",
					name = L["Bar texture"],
					dialogControl = "LSM30_Statusbar",
					values = getMediaData,
					get = function(info) return get(info) or LUF.db.profile.statusbar or SML.DefaultMedia.statusbar end,
				},
				posSlot = {
					name = L["Bar Group"],
					desc = L["Select the bar stack"],
					type = "select",
					order = 10,
					values = {["LEFT"] = L["Left Group"], ["RIGHT"] = L["Right Group"], ["CENTER"] = L["Center Group"]},
				},
			},
		},
		["totemBar"] = {
			name = L["Totem bar"],
			type = "group",
			order = -3,
			--inline = true,
			hidden = function(info) return info[1] ~= "player" or select(2,UnitClass("player")) ~= "SHAMAN" end,
			args = {
				enabled = {
					name = ENABLE,
					desc = string.format(L["Enable or disable the %s."],L["Totem bar"]),
					type = "toggle",
					order = 1,
				},
				autoHide = {
					name = L["Auto hide"],
					desc = string.format(L["Hide when inactive"]),
					type = "toggle",
					order = 2,
				},
				timer = {
					name = L["Timer"],
					desc = string.format(L["Enable or disable the %s."],L["Timer"]),
					type = "toggle",
					order = 3,
				},
				font = {
					order = 4,
					type = "select",
					name = L["Font"],
					dialogControl = "LSM30_Font",
					values = getMediaData,
					get = function(info) return get(info) or LUF.db.profile.font or SML.DefaultMedia.font end,
				},
				fontsize = {
					name = FONT_SIZE,
					desc = L["Set the font size."],
					type = "range",
					order = 5,
					min = 5,
					max = 24,
					step = 1,
				},
				background = {
					name = BACKGROUND,
					desc = string.format(L["Enable or disable the %s."], BACKGROUND),
					type = "toggle",
					order = 6,
				},
				backgroundAlpha = {
					name = L["Background alpha"],
					desc = L["Set the background alpha."],
					type = "range",
					order = 7,
					min = 0,
					max = 1,
					step = 0.01,
				},
				height = {
					name = L["Height"],
					desc = L["Set the height."],
					type = "range",
					order = 8,
					min = 1,
					max = 10,
					step = 0.1,
				},
				order = {
					name = L["Order"],
					desc = L["Set the order priority."],
					type = "range",
					order = 9,
					min = 0,
					max = 100,
					step = 5,
				},
				statusbar = {
					order = 10,
					type = "select",
					name = L["Bar texture"],
					dialogControl = "LSM30_Statusbar",
					values = getMediaData,
					get = function(info) return get(info) or LUF.db.profile.statusbar or SML.DefaultMedia.statusbar end,
				},
				posSlot = {
					name = L["Bar Group"],
					desc = L["Select the bar stack"],
					type = "select",
					order = 11,
					values = {["LEFT"] = L["Left Group"], ["RIGHT"] = L["Right Group"], ["CENTER"] = L["Center Group"]},
				},
				gap1 = {
					type = "description",
					name = " ",
					order = 12,
				},
				colorMode = {
					name = COLOR .. " " .. TYPE,
					type = "select",
					order = 13,
					values = {
						classic = CLASSIC_STYLE,
						matchTotems = "Match Totem Colors",
						custom  = CUSTOM,
						totemCaddy = "Totem Caddy",
					},
					get = function()
						return LUF.db.profile.units.player.totemBar.colorMode
					end,
					set = function(info, v)
						LUF.db.profile.units.player.totemBar.colorMode = v
						if v == "matchTotems" then
							LUF.db.profile.colors.totems = CopyTable(LUF.defaults.profile.colors.totems)
						elseif v == "classic" then
							LUF.db.profile.colors.totems = CopyTable(LUF.defaults.profile.colors.totemsClassic)
						elseif v == "totemCaddy" then
							LUF.db.profile.colors.totems = CopyTable(LUF.defaults.profile.colors.totemsCaddy)
						end
						LUF:ReloadAll()
					end,
				},
				gap2 = {
					type = "description",
					name = " ",
					order = 14,
				},
				fireColor = {
					name = BINDING_NAME_MULTICASTACTIONBUTTON2 or "Fire Totem",
					type = "color",
					order = 15,
					disabled = function() return LUF.db.profile.units.player.totemBar.colorMode ~= "custom" end,
					get = function()
						local c = LUF.db.profile.colors.totems[1]; return c[1],c[2],c[3]
					end,
					set = function(info,r,g,b)
						local c = LUF.db.profile.colors.totems[1]; c[1],c[2],c[3] = r,g,b
						LUF:ReloadAll()
					end,
				},

				earthColor = {
					name = BINDING_NAME_MULTICASTACTIONBUTTON5 or "Earth Totem",
					type = "color",
					order = 16,
					disabled = function() return LUF.db.profile.units.player.totemBar.colorMode ~= "custom" end,
					get = function()
						local c = LUF.db.profile.colors.totems[2]; return c[1],c[2],c[3]
					end,
					set = function(info,r,g,b)
						local c = LUF.db.profile.colors.totems[2]; c[1],c[2],c[3] = r,g,b
						LUF:ReloadAll()
					end,
				},

				waterColor = {
					name = BINDING_NAME_MULTICASTACTIONBUTTON3 or "Water Totem",
					type = "color",
					order = 17,
					disabled = function() return LUF.db.profile.units.player.totemBar.colorMode ~= "custom" end,
					get = function()
						local c = LUF.db.profile.colors.totems[3]; return c[1],c[2],c[3]
					end,
					set = function(info,r,g,b)
						local c = LUF.db.profile.colors.totems[3]; c[1],c[2],c[3] = r,g,b
						LUF:ReloadAll()
					end,
				},

				airColor = {
					name = BINDING_NAME_MULTICASTACTIONBUTTON4 or "Air Totem",
					type = "color",
					order = 18,
					disabled = function() return LUF.db.profile.units.player.totemBar.colorMode ~= "custom" end,
					get = function()
						local c = LUF.db.profile.colors.totems[4]; return c[1],c[2],c[3]
					end,
					set = function(info,r,g,b)
						local c = LUF.db.profile.colors.totems[4]; c[1],c[2],c[3] = r,g,b
						LUF:ReloadAll()
					end,
				},
			},
		},
		["comboPoints"] = {
			name = COMBO_POINTS,
			type = "group",
			order = -2,
			--inline = true,
			hidden = function(info) return (info[1] ~= "target" and info[1] ~= "player") or (select(2,UnitClass("player")) ~= "ROGUE" and select(2,UnitClass("player")) ~= "DRUID") end,
			args = {
				enabled = {
					name = ENABLE,
					desc = string.format(L["Enable or disable the %s."],COMBO_POINTS),
					type = "toggle",
					order = 1,
				},
				autoHide = {
					name = L["Auto hide"],
					desc = L["Hide when inactive"],
					type = "toggle",
					order = 2,
				},
				growth = {
					name = L["Growth direction"],
					desc = L["Growth direction"],
					type = "select",
					order = 3,
					values = {["LEFT"] = L["Left"], ["RIGHT"] = L["Right"]},
				},
				background = {
					name = BACKGROUND,
					desc = string.format(L["Enable or disable the %s."], BACKGROUND),
					type = "toggle",
					order = 4,
				},
				backgroundAlpha = {
					name = L["Background alpha"],
					desc = L["Set the background alpha."],
					type = "range",
					order = 5,
					min = 0,
					max = 1,
					step = 0.01,
				},
				height = {
					name = L["Height"],
					desc = L["Set the height."],
					type = "range",
					order = 6,
					min = 1,
					max = 10,
					step = 0.1,
				},
				order = {
					name = L["Order"],
					desc = L["Set the order priority."],
					type = "range",
					order = 7,
					min = 0,
					max = 100,
					step = 5,
				},
				statusbar = {
					order = 8,
					type = "select",
					name = L["Bar texture"],
					dialogControl = "LSM30_Statusbar",
					values = getMediaData,
					get = function(info) return get(info) or LUF.db.profile.statusbar or SML.DefaultMedia.statusbar end,
				},
				posSlot = {
					name = L["Bar Group"],
					desc = L["Select the bar stack"],
					type = "select",
					order = 9,
					values = {["LEFT"] = L["Left Group"], ["RIGHT"] = L["Right Group"], ["CENTER"] = L["Center Group"]},
				},
			},
		},
		["trinket"] = {
			name = INVTYPE_TRINKET,
			type = "group",
			order = -1,
			hidden = function(info) return info[1] ~= "arena" end,
			args = {
				enabled = {
					name = ENABLE,
					type = "toggle",
					order = 1,
				},
				anchorPoint = {
					name = L["Point"],
					desc = L["Anchor point"],
					type = "select",
					order = 2,
					values = {["LEFT"] = L["Left"], ["TOP"] = L["Top"], ["CENTER"] = L["Center"], ["BOTTOM"] = L["Bottom"], ["RIGHT"] = L["Right"]},
				},
				x = {
					name = L["X Position"],
					desc = L["Offset"],
					type = "range",
					order = 3,
					min = 0,
					max = 40,
					step = 1,
				},
				y = {
					name = L["Y Position"],
					desc = L["Offset"],
					type = "range",
					order = 4,
					min = 0,
					max = 40,
					step = 1,
				},
				size = {
					name = L["Size"],
					desc = L["Set the size."],
					type = "range",
					order = 5,
					min = 5,
					max = 100,
					step = 1,
				},
			},
		},
	}

	local aceoptions = {
		name = "Luna Unit Frames",
		type = "group",
		get = get,
		set = set,
		icon = "Interface\\AddOns\\LunaUnitFrames\\media\\textures\\icon",
		args = {
			general = {
				name = GENERAL,
				type = "group",
				order = 1,
				get = getGeneral,
				set = setGeneral,
				args = {
					description = {
						name = "",
						type = "description",
						image = "Interface\\AddOns\\LunaUnitFrames\\media\\textures\\icon",
						imageWidth = 64,
						imageHeight = 64,
						width = "half",
						order = 1,
					},
					descriptiontext = {
						name = function()
							local text = "Luna Unit Frames by "..C_AddOns.GetAddOnMetadata("LunaUnitFrames", "Author").."\nDonate: "..C_AddOns.GetAddOnMetadata("LunaUnitFrames", "X-Donate").."\n".."Version: "..LUF.version
							if LUF.loadTimeFrame1Ms and LUF.loadTimeFrame2Ms then
								text = text.."\n"..string.format("%s %.1f %s (%s 1: %.1f %s, %s 2: %.1f %s)", TIME_ELAPSED, LUF.loadTimeMs or 0, MILLISECONDS_ABBR, UNITFRAME_LABEL, LUF.loadTimeFrame1Ms, MILLISECONDS_ABBR, UNITFRAME_LABEL, LUF.loadTimeFrame2Ms, MILLISECONDS_ABBR)
							end
							return text
						end,
						type = "description",
						width = "full",
						order = 2,
					},
					header = {
						name = L["Global Settings"],
						type = "header",
						width = "double",
						order = 3,
					},
					locked = {
						name = LOCK,
						desc = LOCK_FOCUS_FRAME,
						type = "toggle",
						order = 4,
						disabled = Lockdown,
						set = setLockedOption,
					},
					previewauras = {
						name = PREVIEW .. " " .. AURAS,
						desc = MAXIMUM .. " " .. AURAS,
						type = "toggle",
						order = 5,
						disabled = Lockdown,
						set = setPreviewAurasOption,
					},
					tooltipCombat = {
						name = L["Tooltip in Combat"],
						desc = L["Show unitframe tooltips in combat"],
						type = "toggle",
						order = 6,
					},
					headerGlobalSettings = {
						name = L["Global Unit Settings"],
						type = "header",
						order = 7,
					},
					statusbar = {
						order = 8,
						type = "select",
						name = L["Bar texture"],
						dialogControl = "LSM30_Statusbar",
						values = getMediaData,
						confirm = function(info) return L["WARNING! This will set ALL bars to this texture."] end,
						set = function(info, value) wipeTextures() setGeneral(info, value) LUF:ReloadAll() end,
						get = function(info) return LUF.db.profile.statusbar or SML.DefaultMedia.statusbar end,
					},
					font = {
						order = 9,
						type = "select",
						name = L["Font"],
						dialogControl = "LSM30_Font",
						values = getMediaData,
						confirm = function(info) return L["WARNING! This will set ALL texts to this font."] end,
						set = function(info, value) wipeFonts() setGeneral(info, value) LUF:ReloadAll() end,
						get = function(info) return LUF.db.profile.font or SML.DefaultMedia.font end,
					},
					fontshadow = {
						name = L["Fontshadow"],
						desc = L["Display a shadow behind the text"],
						type = "toggle",
						order = 11,
						set = function(info, value) setGeneral(info, value) LUF:ReloadAll() end,
					},
					fontoutline = {
						name = L["Fontoutline"],
						desc = L["Display an outline around the text"],
						type = "toggle",
						order = 12,
						set = function(info, value) setGeneral(info, value) LUF:ReloadAll() end,
					},
					auraborderType = {
						order = 13,
						type = "select",
						name = L["Aura border"],
						values = {["none"] = NONE, ["blizzard"] = "Blizzard", ["light"] = L["Light"], ["dark"] = L["Dark"], ["black"] = L["Black"], ["light-thin"] = L["Light thin"], ["dark-thin"] = L["Dark thin"], ["black-thin"] = L["Black thin"]},
						set = function(info, value) setGeneral(info, value) LUF:ReloadAll() end,
					},
					inchealTime = {
						name = L["Heal prediction timeframe"],
						desc = L["Set how long into the future heals are predicted."],
						type = "range",
						order = 14,
						min = 3,
						max = 21,
						step = 0.5,
						set = function(info, value) setGeneral(info, value) LUF:LoadoUFSettings() LUF:ReloadAll() end,
					},
					blizzDirectHeals = {
						name = L["Blizz Heal Prediction"],
						desc = L["Use Blizzard heal prediction for direct heals"] ,
						type = "toggle",
						order = 15,
						set = function(info, value) setGeneral(info, value) LUF:LoadoUFSettings() LUF:ReloadAll() end,
					},
					disablehots = {
						name = L["Disable hots"],
						desc = L["Disable hots in heal prediction"],
						type = "toggle",
						order = 16,
						set = function(info, value) setGeneral(info, value) LUF:LoadoUFSettings() LUF:ReloadAll() end,
					},
					omnicc = {
						name = L["Disable OmniCC"],
						desc = L["Prevent OmniCC from putting numbers on cooldown animations (Requires UI reload)"],
						type = "toggle",
						order = 17,
						disabled = Lockdown,
						set = function(info, value) setGeneral(info, value) LUF:ReloadAll() end,
					},
					blizzardcc = {
						name = L["Disable Blizzard cooldown count"],
						desc = L["Prevent the default UI from putting numbers on cooldown animations"],
						type = "toggle",
						order = 18,
						disabled = Lockdown,
						set = function(info, value) setGeneral(info, value) LUF:ReloadAll() end,
					},
					strata = {
						order = 19,
						type = "select",
						name = "Strata",
						values = {["BACKGROUND"] = "BACKGROUND", ["LOW"] = "LOW", ["MEDIUM"] = "MEDIUM", ["HIGH"] = "HIGH", ["DIALOG"] = "DIALOG", ["FULLSCREEN"] = "FULLSCREEN", ["FULLSCREEN_DIALOG"] = "FULLSCREEN_DIALOG", ["TOOLTIP"] = "TOOLTIP"},
						sorting = {[1] = "BACKGROUND", [2] = "LOW", [3] = "MEDIUM", [4] = "HIGH", [5] = "DIALOG", [6] = "FULLSCREEN", [7] = "FULLSCREEN_DIALOG", [8] = "TOOLTIP"},
						set = function(info, value) setGeneral(info, value) for unit,frame in pairs(LUF.frameIndex) do frame:SetFrameStrata(value) end end,
					},
					headerRange = {
						name = L["Range"],
						type = "header",
						order = 20,
					},
					range = {
						name = L["Distance"],
						desc = L["Distance to measure"] .. "\nLibRangeCheck-3.0." .. RCminor,
						type = "range",
						order = 21,
						min = 10,        -- minimum value
						max = 100,       -- maximum value
						step = 1,        -- increment step
						bigStep = 5,     -- optional, for dragging
						get = function(info) return LUF.db.profile.range.dist end,
						set = function(info, value) LUF.db.profile.range.dist = value LUF:ReloadAll() end,
					},
					rangeNoItems = {
						name = L["Distance"].. " ".. TYPE ,
						type = "select",
						order = 22,
						values = {[true] = L["Spell based"], [false] = L["Spell based"].. " / " .. ITEMS .. " (" .. SLOW .. ")"},
						get = function(info) return LUF.db.profile.range.noItems end, 
						set = function(info, value) LUF.db.profile.range.noItems = value LUF:ReloadAll() end,
					},
					alpha = {
						name = OPACITY,
						desc = L["Set the alpha."],
						type = "range",
						order = 23,
						min = 0,
						max = 1,
						step = 0.01,
						get = function(info) return LUF.db.profile.range.alpha end,
						set = function(info, value) LUF.db.profile.range.alpha = value LUF:ReloadAll() end,
					},
				},
			},
			testing = {
				name = L["Testing"],
				type = "group",
				order = 30,
				get = getGeneral,
				set = setGeneral,
				args = {
					description = {
						name = UNLOCK_FRAME .. "\n" .. PREVIEW .. " " .. AURAS,
						type = "description",
						order = 1,
						width = "full",
					},
					locked = {
						name = LOCK,
						desc = LOCK_FOCUS_FRAME,
						type = "toggle",
						order = 2,
						disabled = Lockdown,
						set = setLockedOption,
					},
					frametime = {
						name = " ",
						type = "description",
						dialogControl = "LUF_FrameTime",
						fontSize = "medium",
						order = 10,
						width = "full",
					},
					auratestHeader = {
						name = L["Testing"] .. " " .. AURAS,
						type = "header",
						width = "double",
						order = 90,
					},
					auratest = {
						name = L["Testing"] .. " " .. AURAS,
						desc = L["Test Auras"],
						type = "toggle",
						order = 91,
						disabled = auraTestDisabled,
						get = getGeneral,
						set = function(info, value)
							if value then
								if InCombatLockdown() then
									LUF:Print(ERR_NOT_IN_COMBAT)
									return
								end
								if not anyAuraTestType() then
									LUF:Print(ENABLE .. " " .. SHOW_BUFFS .. " / " .. SHOW_DEBUFFS)
									return
								end
								if not (LUF.AuraCache and LUF.AuraCache.test.Start()) then return end
								setGeneral(info, true)
							else
								setGeneral(info, false)
								if LUF.AuraCache then
									LUF.AuraCache.test.Stop()
								end
							end
						end,
					},
					auratestBuffs = {
						name = SHOW_BUFFS,
						desc = AURAS,
						type = "toggle",
						order = 92,
						disabled = auraTestDisabled,
						set = setAuraTestOption,
					},
					auratestDebuffs = {
						name = SHOW_DEBUFFS,
						desc = AURAS,
						type = "toggle",
						order = 93,
						disabled = auraTestDisabled,
						set = setAuraTestOption,
					},
					auratestDispels = {
						name = SHOW_DISPELLABLE_DEBUFFS_TEXT,
						desc = DISPLAY_ONLY_DISPELLABLE_DEBUFFS,
						type = "toggle",
						order = 94,
						disabled = function()
							return auraTestDisabled() or not LUF.db.profile.auratestDebuffs
						end,
						set = setAuraTestOption,
					},
					auratestUseFrameMax = {
						name = MAXIMUM,
						desc = BUFFOPTIONS_LABEL,
						type = "toggle",
						order = 95,
						disabled = auraTestDisabled,
						set = setAuraTestOption,
					},
					auratestMaxBuffs = {
						name = SHOW_BUFFS,
						desc = MAXIMUM .. " " .. SHOW_BUFFS,
						type = "range",
						order = 96,
						min = 1,
						max = 32,
						step = 1,
						disabled = function()
							return auraTestDisabled() or LUF.db.profile.auratestUseFrameMax
						end,
						set = setAuraTestOption,
					},
					auratestMaxDebuffs = {
						name = SHOW_DEBUFFS,
						desc = MAXIMUM .. " " .. SHOW_DEBUFFS,
						type = "range",
						order = 97,
						min = 1,
						max = 40,
						step = 1,
						disabled = function()
							return auraTestDisabled() or LUF.db.profile.auratestUseFrameMax
						end,
						set = setAuraTestOption,
					},
					auratestRefreshAuras = {
						name = REFRESH .. " " .. AURAS,
						desc = REFRESH,
						type = "toggle",
						order = 98,
						disabled = auraTestDisabled,
						set = setAuraTestOption,
					},
				},
			},
			colors = {
				name = COLORS,
				type = "group",
				order = 2,
				get = getColor,
				set = setColor,
				childGroups = "tab",
				args = {
					ResetColors = {
						name = L["Reset Colors"],
						type = "execute",
						func = function(info) LUF:ResetColors() end,
						confirm = function(info) return L["WARNING! This will set ALL colors back to default."] end,
						order = 1,
					},
					ClassColors = {
						name = CLASS_COLORS,
						type = "group",
						order = 2,
						args = {
							HUNTER = {
								name = LOCALIZED_CLASS_NAMES_MALE["HUNTER"],
								type = "color",
								order = 1,
							},
							WARLOCK = {
								name = LOCALIZED_CLASS_NAMES_MALE["WARLOCK"],
								type = "color",
								order = 2,
							},
							PRIEST = {
								name = LOCALIZED_CLASS_NAMES_MALE["PRIEST"],
								type = "color",
								order = 3,
							},
							PALADIN = {
								name = LOCALIZED_CLASS_NAMES_MALE["PALADIN"],
								type = "color",
								order = 4,
							},
							MAGE = {
								name = LOCALIZED_CLASS_NAMES_MALE["MAGE"],
								type = "color",
								order = 5,
							},
							ROGUE = {
								name = LOCALIZED_CLASS_NAMES_MALE["ROGUE"],
								type = "color",
								order = 6,
							},
							DRUID = {
								name = LOCALIZED_CLASS_NAMES_MALE["DRUID"],
								type = "color",
								order = 7,
							},
							SHAMAN = {
								name = LOCALIZED_CLASS_NAMES_MALE["SHAMAN"],
								type = "color",
								order = 8,
							},
							WARRIOR = {
								name = LOCALIZED_CLASS_NAMES_MALE["WARRIOR"],
								type = "color",
								order = 9,
							},
						},
					},
					PowerColors = {
						name = L["Power Type"],
						type = "group",
						order = 2,
						args = {
							MANA = {
								name = MANA,
								type = "color",
								order = 1,
							},
							RAGE = {
								name = RAGE,
								type = "color",
								order = 2,
							},
							FOCUS = {
								name = FOCUS,
								type = "color",
								order = 3,
							},
							ENERGY = {
								name = ENERGY,
								type = "color",
								order = 4,
							},
							COMBOPOINTS = {
								name = COMBO_POINTS,
								type = "color",
								order = 5,
							},
						},
					},
					GradientColors = {
						name = L["Gradient Colors"],
						type = "group",
						order = 3,
						args = {
							red = {
								name = L["Red"],
								type = "color",
								order = 1,
							},
							yellow = {
								name = L["Yellow"],
								type = "color",
								order = 2,
							},
							green = {
								name = L["Green"],
								type = "color",
								order = 3,
							},
						},
					},
					HappinessColors = {
						name = HAPPINESS,
						type = "group",
						order = 4,
						args = {
							unhappy = {
								name = PET_HAPPINESS1,
								type = "color",
								order = 1,
							},
							content = {
								name = PET_HAPPINESS2,
								type = "color",
								order = 2,
							},
							happy = {
								name = PET_HAPPINESS3,
								type = "color",
								order = 3,
							},
						},
					},
					ReactionColors = {
						name = L["Reaction Colors"],
						type = "group",
						order = 5,
						args = {
							hated = {
								name = FACTION_STANDING_LABEL1,
								type = "color",
								order = 1,
							},
							hostile = {
								name = FACTION_STANDING_LABEL2,
								type = "color",
								order = 2,
							},
							unfriendly = {
								name = FACTION_STANDING_LABEL3,
								type = "color",
								order = 3,
							},
							neutral = {
								name = FACTION_STANDING_LABEL4,
								type = "color",
								order = 4,
							},
							friendly = {
								name = FACTION_STANDING_LABEL5,
								type = "color",
								order = 5,
							},
							honored = {
								name = FACTION_STANDING_LABEL6,
								type = "color",
								order = 6,
							},
							revered = {
								name = FACTION_STANDING_LABEL7,
								type = "color",
								order = 7,
							},
							exalted = {
								name = FACTION_STANDING_LABEL8,
								type = "color",
								order = 8,
							},
						},
					},
					StatusColors = {
						name = L["Status Colors"],
						type = "group",
						order = 6,
						args = {
							static = {
								name = L["Static"],
								type = "color",
								order = 1,
							},
							enemyCivilian = {
								name = L["Enemy civilian"],
								type = "color",
								order = 2,
							},
							tapped = {
								name = L["Tapped"],
								type = "color",
								order = 3,
							},
							offline = {
								name = FRIENDS_LIST_OFFLINE,
								type = "color",
								order = 4,
							},
						},
					},
					HealColors = {
						name = L["Incoming heals"],
						type = "group",
						order = 7,
						args = {
							incheal = {
								name = L["Incoming heals"],
								type = "color",
								order = 1,
							},
							incownheal = {
								name = L["Inc Own Heal"],
								type = "color",
								order = 2,
							},
							inchots = {
								name = L["Inc Hots"],
								type = "color",
								order = 3,
							},
						},
					},
					CastColors = {
						name = SPELL_CASTING ,
						type = "group",
						order = 8,
						args = {
							channel = {
								name = CHANNELING,
								type = "color",
								order = 1,
							},
							cast = {
								name = SPELL_CASTING,
								type = "color",
								order = 2,
							},
							castnotinterruptible = {
								name = L["Not interruptible cast"],
								desc = L["Color of cast bar when cast not interruptible"],
								type = "color",
								order = 3,
							},
							castnotinterruptibletext = {
								name = L["Not interruptible cast text"],
								desc = L["Color of cast bar text when cast not interruptible"],
								type = "color",
								order = 4,
							},
						},
					},
					XPColors = {
						name = L["XP Colors"],
						type = "group",
						order = 9,
						args = {
							normal = {
								name = VOICE_CHAT_NORMAL,
								type = "color",
								order = 1,
							},
							rested = {
								name = TUTORIAL_TITLE26,
								type = "color",
								order = 2,
							},
						},
					},
					miscColors = {
						name = L["Misc Colors"],
						type = "group",
						order = 10,
						args = {
							background = {
								name = BACKGROUND,
								type = "color",
								order = 1,
								hasAlpha = true,
								set = setAlphaColor,
							},
							mouseover = {
								name = L["Mouseover"],
								type = "color",
								order = 2,
							},
							target = {
								name = TARGET,
								type = "color",
								order = 3,
							},
							ticker = {
								name = L["Ticker"],
								type = "color",
								hasAlpha = true,
								order = 4,
								set = setAlphaColor,
							},
							tickerBG = {
								name = L["Ticker Background"],
								type = "color",
								hasAlpha = true,
								order = 5,
								set = setAlphaColor,
							},
						},
					},
				},
			},
			player = {
				name = PLAYER,
				type = "group",
				order = 3,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], PLAYER),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						set = function(info, value) set(info, value) LUF:PlaceFrame(_G["LUFUnitplayer"]) end,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 2.1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2.2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 2.3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.4,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.5,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 2.7,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			},
			pet = {
				name = PET,
				type = "group",
				order = 4,
				arg = LUF.db.profile.units.pet,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], PET),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						set = function(info, value) set(info, value) LUF:PlaceFrame(_G["LUFUnitpet"]) end,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 2.1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2.2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 2.3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.4,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.5,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 2.7,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			},
			pettarget = {
				name = L["pettarget"],
				type = "group",
				order = 5,
				arg = LUF.db.profile.units.pettarget,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], L["pettarget"]),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						set = function(info, value) set(info, value) LUF:PlaceFrame(_G["LUFUnitpettarget"]) end,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 2.1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2.2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 2.3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.4,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.5,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 2.7,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			},
			pettargettarget = {
				name = L["pettargettarget"],
				type = "group",
				order = 5,
				arg = LUF.db.profile.units.pettargettarget,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], L["pettargettarget"]),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						set = function(info, value) set(info, value) LUF:PlaceFrame(_G["LUFUnitpettargettarget"]) end,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 2.1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2.2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 2.3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.4,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.5,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 2.7,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			},
			target = {
				name = TARGET,
				type = "group",
				order = 7,
				arg = LUF.db.profile.units.target,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], TARGET),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						set = function(info, value) set(info, value) LUF:PlaceFrame(_G["LUFUnittarget"]) end,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 2.1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2.2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 2.3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.4,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.5,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							sound = {
								name = L["Targeting sound"],
								desc = L["Enable the sound when switching target"],
								type = "toggle",
								order = 2.7,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 2.8,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			},
			targettarget = {
				name = L["targettarget"],
				type = "group",
				order = 8,
				arg = LUF.db.profile.units.targettarget,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], L["targettarget"]),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						set = function(info, value) set(info, value) LUF:PlaceFrame(_G["LUFUnittargettarget"]) end,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 2.1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2.2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 2.3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.4,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.5,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 2.7,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			},
			targettargettarget = {
				name = L["targettargettarget"],
				type = "group",
				order = 9,
				arg = LUF.db.profile.units.targettargettarget,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], L["targettargettarget"]),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						set = function(info, value) set(info, value) LUF:PlaceFrame(_G["LUFUnittargettargettarget"]) end,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 2.1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2.2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 2.3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.4,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.5,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 2.7,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			},
			focus = ArenaAndFocusExists and {
				name = FOCUS,
				type = "group",
				order = 10,
				arg = LUF.db.profile.units.focus,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], FOCUS),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						set = function(info, value) set(info, value) LUF:PlaceFrame(_G["LUFUnitfocus"]) end,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 2.1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2.2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 2.3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.4,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.5,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 2.7,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			} or nil,
			focustarget = ArenaAndFocusExists and {
				name = L["focustarget"],
				type = "group",
				order = 11,
				arg = LUF.db.profile.units.focustarget,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], L["focustarget"]),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						set = function(info, value) set(info, value) LUF:PlaceFrame(_G["LUFUnitfocustarget"]) end,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 2.1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2.2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 2.3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.4,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.5,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 2.7,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			} or nil,
			focustargettarget = ArenaAndFocusExists and {
				name = L["focustargettarget"],
				type = "group",
				order = 12,
				arg = LUF.db.profile.units.focustargettarget,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], L["focustargettarget"]),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						set = function(info, value) set(info, value) LUF:PlaceFrame(_G["LUFUnitfocustargettarget"]) end,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 2.1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2.2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 2.3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.4,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.5,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 2.7,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			} or nil,
			party = {
				name = PARTY,
				type = "group",
				order = 13,
				arg = LUF.db.profile.units.party,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], PARTY),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 2.1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2.2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 2.3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
								set = setHeader,
							},
							offset = {
								name = L["Offset"],
								desc = L["Set the space between units."],
								type = "range",
								order = 2.4,
								min = 0,
								max = 200,
								step = 1,
								disabled = Lockdown,
								set = setHeader,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.5,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.7,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							attribPoint = {
								name = L["Growth direction"],
								desc = L["The direction in which new frames are added."],
								type = "select",
								order = 2.8,
								values = {["RIGHT"] = L["Left"],["LEFT"] = L["Right"],["BOTTOM"] = L["Up"],["TOP"] = L["Down"]},
								set = setGrowthDir,
								disabled = Lockdown,
							},
							hideraid = {
								name = L["Hide in raid"],
								desc = L["Hide while in a raid group."],
								type = "select",
								order = 2.9,
								values = {["never"] = NEVER,["5man"] = L["Raid > 5 man"],["always"] = L["Any Raid"]},
								set = setHideRaid,
								disabled = Lockdown,
							},
							sortMethod = {
								name = L["Sort by"],
								desc = L["Sort by name or index"],
								type = "select",
								order = 2.91,
								values = {["INDEX"] = L["Index"],["NAME"] = NAME},
								set = setSortMethod,
								disabled = Lockdown,
							},
							sortOrder = {
								name = L["Sort order"],
								desc = L["Sort ascending or descending"],
								type = "select",
								order = 2.92,
								values = {["ASC"] = L["Ascending"],["DESC"] = L["Descending"]},
								set = setSortOrder,
								disabled = Lockdown,
							},
							showPlayer = {
								name = L["Show player"],
								desc = L["Show player in the party frame."],
								type = "toggle",
								order = 2.93,
								disabled = function(info) return Lockdown() or LUF.db.profile.units.party.showSolo end,
								get = function(info) return LUF.db.profile.units.party.showSolo or get(info) end,
								set = function(info, value)
									LUF.db.profile.units.party.showPlayer = value
									LUF.db.profile.units.partytarget.showPlayer = value
									LUF.db.profile.units.partypet.showPlayer = value
									LUF:SetupHeader("party")
									LUF:SetupHeader("partytarget")
									LUF:SetupHeader("partypet")
								end,
							},
							showSolo = {
								name = L["Show solo"],
								desc = L["Show player in the party frame when solo."],
								type = "toggle",
								order = 2.94,
								disabled = Lockdown,
								set = function(info, value)
									LUF.db.profile.units.party.showSolo = value
									LUF.db.profile.units.partytarget.showSolo = value
									LUF.db.profile.units.partypet.showSolo = value
									LUF:SetupHeader("party")
									LUF:SetupHeader("partytarget")
									LUF:SetupHeader("partypet")
									ACR:NotifyChange("LunaUnitFrames")
								end,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 2.95,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			},
			partytarget = {
				name = L["partytarget"],
				type = "group",
				order = 14,
				arg = LUF.db.profile.units.partytarget,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], L["partytarget"]),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 2.1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2.2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 2.3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
								set = setHeader,
							},
							offset = {
								name = L["Offset"],
								desc = L["Set the space between units."],
								type = "range",
								order = 2.4,
								min = 0,
								max = 200,
								step = 1,
								disabled = Lockdown,
								set = setHeader,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.5,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.7,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							attribPoint = {
								name = L["Growth direction"],
								desc = string.format(L["This is set through %s options."],PARTY),
								type = "select",
								order = 2.8,
								values = {["RIGHT"] = L["Left"],["LEFT"] = L["Right"],["BOTTOM"] = L["Up"],["TOP"] = L["Down"]},
								get = function(info) return LUF.db.profile.units["party"].attribPoint end,
								disabled = true,
							},
							hideraid = {
								name = L["Hide in raid"],
								desc = string.format(L["This is set through %s options."],PARTY),
								type = "select",
								order = 2.9,
								values = {["never"] = NEVER,["5man"] = L["Raid > 5 man"],["always"] = L["Any Raid"]},
								get = function() return LUF.db.profile.units.party.hideraid end,
								set = setHideRaid,
								disabled = true,
							},
							sortMethod = {
								name = L["Sort by"],
								desc = string.format(L["This is set through %s options."],PARTY),
								type = "select",
								order = 2.91,
								values = {["INDEX"] = L["Index"],["NAME"] = NAME},
								set = setSortMethod,
								disabled = true,
							},
							sortOrder = {
								name = L["Sort order"],
								desc = string.format(L["This is set through %s options."],PARTY),
								type = "select",
								order = 2.92,
								values = {["ASC"] = L["Ascending"],["DESC"] = L["Descending"]},
								set = setSortOrder,
								disabled = true,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 2.93,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			},
			partypet = {
				name = L["partypet"],
				type = "group",
				order = 15,
				arg = LUF.db.profile.units.partypet,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], L["partypet"]),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 2.1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2.2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 2.3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
								set = setHeader,
							},
							offset = {
								name = L["Offset"],
								desc = L["Set the space between units."],
								type = "range",
								order = 2.4,
								min = 0,
								max = 200,
								step = 1,
								disabled = Lockdown,
								set = setHeader,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.5,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.7,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							attribPoint = {
								name = L["Growth direction"],
								desc = string.format(L["This is set through %s options."],PARTY),
								type = "select",
								order = 2.8,
								values = {["RIGHT"] = L["Left"],["LEFT"] = L["Right"],["BOTTOM"] = L["Up"],["TOP"] = L["Down"]},
								get = function(info) return LUF.db.profile.units["party"].attribPoint end,
								disabled = true,
							},
							hideraid = {
								name = L["Hide in raid"],
								desc = string.format(L["This is set through %s options."],PARTY),
								type = "select",
								order = 2.9,
								values = {["never"] = NEVER,["5man"] = L["Raid > 5 man"],["always"] = L["Any Raid"]},
								get = function() return LUF.db.profile.units.party.hideraid end,
								set = setHideRaid,
								disabled = true,
							},
							sortMethod = {
								name = L["Sort by"],
								desc = string.format(L["This is set through %s options."],PARTY),
								type = "select",
								order = 2.91,
								values = {["INDEX"] = L["Index"],["NAME"] = NAME},
								set = setSortMethod,
								disabled = true,
							},
							sortOrder = {
								name = L["Sort order"],
								desc = string.format(L["This is set through %s options."],PARTY),
								type = "select",
								order = 2.92,
								values = {["ASC"] = L["Ascending"],["DESC"] = L["Descending"]},
								set = setSortOrder,
								disabled = true,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 2.93,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			},
			raid = {
				name = RAID,
				type = "group",
				order = 16,
				arg = LUF.db.profile.units.raid,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], RAID),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 2.1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2.2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 2.3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
								set = setHeader,
							},
							offset = {
								name = L["Offset"],
								desc = L["Set the space between units."],
								type = "range",
								order = 2.31,
								min = 0,
								max = 200,
								step = 1,
								disabled = Lockdown,
								set = setHeader,
							},
							attribPoint = {
								name = L["Growth direction"],
								desc = L["The direction in which new frames are added."],
								type = "select",
								order = 2.32,
								values = {["RIGHT"] = L["Left"],["LEFT"] = L["Right"],["BOTTOM"] = L["Up"],["TOP"] = L["Down"]},
								set = setGrowthDir,
								disabled = Lockdown,
							},
							groupBy = {
								name = L["Group by"],
								desc = L["Group by class or group"],
								type = "select",
								order = 2.33,
								values = {["GROUP"] = GROUP,["CLASS"] = CLASS},
								disabled = Lockdown,
								set = function(info, value) setHeader(info, value) LUF:UpdateMovers() end,
							},
							sortMethod = {
								name = L["Sort by"],
								desc = L["Sort by name or index"],
								type = "select",
								order = 2.331,
								values = {["INDEX"] = L["Index"],["NAME"] = NAME},
								set = setSortMethod,
								disabled = Lockdown,
							},
							sortOrder = {
								name = L["Sort order"],
								desc = L["Sort ascending or descending"],
								type = "select",
								order = 2.332,
								values = {["ASC"] = L["Ascending"],["DESC"] = L["Descending"]},
								set = setSortOrder,
								disabled = Lockdown,
							},
							showWhen = {
								name = L["Show when"],
								desc = L["Show even smaller groups than a raid in the raidframe"],
								type = "select",
								order = 2.34,
								values = {["ALWAYS"] = ALWAYS,["PARTY"] = PARTY, ["RAID"] = RAID},
								get = getShowWhen,
								set = setShowWhen,
								disabled = Lockdown,
							},
							hideParty = {
								name = L["Hide < 6 Raid"],
								desc = L["Hide when 5 or less people in raid"],
								type = "toggle",
								order = 2.35,
								disabled = function() return LUF.db.profile.units.raid.showParty or (LUF.db.profile.units.raid.showSolo and LUF.db.profile.units.raid.showPlayer) or Lockdown() end,
								set = function(info, value) set(info, value) LUF.stateMonitor:SetAttribute("hideParty", LUF.db.profile.units.raid.hideParty) end,
							},
							groupnumbers = {
								name = L["Groupnumbers"],
								desc = L["Show Groupnumbers next to the group"],
								type = "toggle",
								order = 2.36,
								disabled = Lockdown,
								set = function(info, value) set(info,value) LUF:SetupHeader("raid") LUF:SetupHeader("raidpet") end,
							},
							fontsize = {
								name = FONT_SIZE,
								desc = L["Set the size of the group number."],
								type = "range",
								order = 2.37,
								min = 1,
								max = 20,
								step = 1,
								disabled = Lockdown,
								set = function(info, value) set(info,value) LUF:SetupHeader("raid") LUF:SetupHeader("raidpet") end,
							},
							font = {
								order = 2.38,
								type = "select",
								name = L["Groupnumberfont"],
								dialogControl = "LSM30_Font",
								values = getMediaData,
								get = function(info) return get(info) or LUF.db.profile.font or SML.DefaultMedia.font end,
								set = function(info, value) set(info,value) LUF:SetupHeader("raid") LUF:SetupHeader("raidpet") end,
							},
							headerraid1 = {
								name = RAID.."1",
								type = "header",
								order = 2.41,
							},
							enabled1 = {
								name = ENABLE,
								desc = L["Enable this group"],
								type = "toggle",
								order = 2.411,
								width = "half",
								disabled = Lockdown,
								set = function(info, value) LUF.db.profile.units.raid.filters[1] = value LUF:SetupHeader("raid1") LUF:UpdateMovers() end,
								get = function(info, value) return LUF.db.profile.units.raid.filters[1] end,
							},
							raid1 = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.412,
								values = getAnchors,
								get = function() return LUF.db.profile.units.raid.positions[1].anchorTo end,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x1 = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.413,
								width = 0.8,
								validate = nbrValidate,
								get = function() return tostring(LUF.db.profile.units.raid.positions[1].x) end,
								set = function(info, value) LUF.db.profile.units.raid.positions[1].x = tonumber(value) LUF:PlaceFrame(LUF.frameIndex["raid1"]) end,
								disabled = Lockdown,
							},
							y1 = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.414,
								width = 0.8,
								validate = nbrValidate,
								get = function() return tostring(LUF.db.profile.units.raid.positions[1].y) end,
								set = function(info, value) LUF.db.profile.units.raid.positions[1].y = tonumber(value) LUF:PlaceFrame(LUF.frameIndex["raid1"]) end,
								disabled = Lockdown,
							},
							headerraid2 = {
								name = RAID.."2",
								type = "header",
								order = 2.42,
							},
							enabled2 = {
								name = ENABLE,
								desc = L["Enable this group"],
								type = "toggle",
								order = 2.421,
								width = "half",
								disabled = Lockdown,
								set = function(info, value) LUF.db.profile.units.raid.filters[2] = value LUF:SetupHeader("raid2") LUF:UpdateMovers() end,
								get = function(info, value) return LUF.db.profile.units.raid.filters[2] end,
							},
							raid2 = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.422,
								values = getAnchors,
								get = function() return LUF.db.profile.units.raid.positions[2].anchorTo end,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x2 = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.423,
								width = 0.8,
								validate = nbrValidate,
								get = function() return tostring(LUF.db.profile.units.raid.positions[2].x) end,
								set = function(info, value) LUF.db.profile.units.raid.positions[2].x = tonumber(value) LUF:PlaceFrame(LUF.frameIndex["raid2"]) end,
								disabled = Lockdown,
							},
							y2 = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.424,
								width = 0.8,
								validate = nbrValidate,
								get = function() return tostring(LUF.db.profile.units.raid.positions[2].y) end,
								set = function(info, value) LUF.db.profile.units.raid.positions[2].y = tonumber(value) LUF:PlaceFrame(LUF.frameIndex["raid2"]) end,
								disabled = Lockdown,
							},
							headerraid3 = {
								name = RAID.."3",
								type = "header",
								order = 2.43,
							},
							enabled3 = {
								name = ENABLE,
								desc = L["Enable this group"],
								type = "toggle",
								order = 2.431,
								width = "half",
								disabled = Lockdown,
								set = function(info, value) LUF.db.profile.units.raid.filters[3] = value LUF:SetupHeader("raid3") LUF:UpdateMovers() end,
								get = function(info, value) return LUF.db.profile.units.raid.filters[3] end,
							},
							raid3 = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.432,
								values = getAnchors,
								get = function() return LUF.db.profile.units.raid.positions[3].anchorTo end,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x3 = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.433,
								width = 0.8,
								validate = nbrValidate,
								get = function() return tostring(LUF.db.profile.units.raid.positions[3].x) end,
								set = function(info, value) LUF.db.profile.units.raid.positions[3].x = tonumber(value) LUF:PlaceFrame(LUF.frameIndex["raid3"]) end,
								disabled = Lockdown,
							},
							y3 = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.434,
								width = 0.8,
								validate = nbrValidate,
								get = function() return tostring(LUF.db.profile.units.raid.positions[3].y) end,
								set = function(info, value) LUF.db.profile.units.raid.positions[3].y = tonumber(value) LUF:PlaceFrame(LUF.frameIndex["raid3"]) end,
								disabled = Lockdown,
							},
							headerraid4 = {
								name = RAID.."4",
								type = "header",
								order = 2.44,
							},
							enabled4 = {
								name = ENABLE,
								desc = L["Enable this group"],
								type = "toggle",
								order = 2.441,
								width = "half",
								disabled = Lockdown,
								set = function(info, value) LUF.db.profile.units.raid.filters[4] = value LUF:SetupHeader("raid4") LUF:UpdateMovers() end,
								get = function(info, value) return LUF.db.profile.units.raid.filters[4] end,
							},
							raid4 = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.442,
								values = getAnchors,
								get = function() return LUF.db.profile.units.raid.positions[4].anchorTo end,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x4 = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.443,
								width = 0.8,
								validate = nbrValidate,
								get = function() return tostring(LUF.db.profile.units.raid.positions[4].x) end,
								set = function(info, value) LUF.db.profile.units.raid.positions[4].x = tonumber(value) LUF:PlaceFrame(LUF.frameIndex["raid4"]) end,
								disabled = Lockdown,
							},
							y4 = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.444,
								width = 0.8,
								validate = nbrValidate,
								get = function() return tostring(LUF.db.profile.units.raid.positions[4].y) end,
								set = function(info, value) LUF.db.profile.units.raid.positions[4].y = tonumber(value) LUF:PlaceFrame(LUF.frameIndex["raid4"]) end,
								disabled = Lockdown,
							},
							headerraid5 = {
								name = RAID.."5",
								type = "header",
								order = 2.45,
							},
							enabled5 = {
								name = ENABLE,
								desc = L["Enable this group"],
								type = "toggle",
								order = 2.451,
								width = "half",
								disabled = Lockdown,
								set = function(info, value) LUF.db.profile.units.raid.filters[5] = value LUF:SetupHeader("raid5") LUF:UpdateMovers() end,
								get = function(info, value) return LUF.db.profile.units.raid.filters[5] end,
							},
							raid5 = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.452,
								values = getAnchors,
								get = function() return LUF.db.profile.units.raid.positions[5].anchorTo end,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x5 = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.453,
								width = 0.8,
								validate = nbrValidate,
								get = function() return tostring(LUF.db.profile.units.raid.positions[5].x) end,
								set = function(info, value) LUF.db.profile.units.raid.positions[5].x = tonumber(value) LUF:PlaceFrame(LUF.frameIndex["raid5"]) end,
								disabled = Lockdown,
							},
							y5 = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.454,
								width = 0.8,
								validate = nbrValidate,
								get = function() return tostring(LUF.db.profile.units.raid.positions[5].y) end,
								set = function(info, value) LUF.db.profile.units.raid.positions[5].y = tonumber(value) LUF:PlaceFrame(LUF.frameIndex["raid5"]) end,
								disabled = Lockdown,
							},
							headerraid6 = {
								name = RAID.."6",
								type = "header",
								order = 2.46,
							},
							enabled6 = {
								name = ENABLE,
								desc = L["Enable this group"],
								type = "toggle",
								order = 2.461,
								width = "half",
								disabled = Lockdown,
								set = function(info, value) LUF.db.profile.units.raid.filters[6] = value LUF:SetupHeader("raid6") LUF:UpdateMovers() end,
								get = function(info, value) return LUF.db.profile.units.raid.filters[6] end,
							},
							raid6 = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.462,
								values = getAnchors,
								get = function() return LUF.db.profile.units.raid.positions[6].anchorTo end,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x6 = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.463,
								width = 0.8,
								validate = nbrValidate,
								get = function() return tostring(LUF.db.profile.units.raid.positions[6].x) end,
								set = function(info, value) LUF.db.profile.units.raid.positions[6].x = tonumber(value) LUF:PlaceFrame(LUF.frameIndex["raid6"]) end,
								disabled = Lockdown,
							},
							y6 = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.464,
								width = 0.8,
								validate = nbrValidate,
								get = function() return tostring(LUF.db.profile.units.raid.positions[6].y) end,
								set = function(info, value) LUF.db.profile.units.raid.positions[6].y = tonumber(value) LUF:PlaceFrame(LUF.frameIndex["raid6"]) end,
								disabled = Lockdown,
							},
							headerraid7 = {
								name = RAID.."7",
								type = "header",
								order = 2.47,
							},
							enabled7 = {
								name = ENABLE,
								desc = L["Enable this group"],
								type = "toggle",
								order = 2.471,
								width = "half",
								disabled = Lockdown,
								set = function(info, value) LUF.db.profile.units.raid.filters[7] = value LUF:SetupHeader("raid7") LUF:UpdateMovers() end,
								get = function(info, value) return LUF.db.profile.units.raid.filters[7] end,
							},
							raid7 = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.472,
								values = getAnchors,
								get = function() return LUF.db.profile.units.raid.positions[7].anchorTo end,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x7 = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.473,
								width = 0.8,
								validate = nbrValidate,
								get = function() return tostring(LUF.db.profile.units.raid.positions[7].x) end,
								set =  function(info, value) LUF.db.profile.units.raid.positions[7].x = tonumber(value) LUF:PlaceFrame(LUF.frameIndex["raid7"]) end,
								disabled = Lockdown,
							},
							y7 = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.474,
								width = 0.8,
								validate = nbrValidate,
								get = function() return tostring(LUF.db.profile.units.raid.positions[7].y) end,
								set = function(info, value) LUF.db.profile.units.raid.positions[7].y = tonumber(value) LUF:PlaceFrame(LUF.frameIndex["raid7"]) end,
								disabled = Lockdown,
							},
							headerraid8 = {
								name = RAID.."8",
								type = "header",
								order = 2.48,
							},
							enabled8 = {
								name = ENABLE,
								desc = L["Enable this group"],
								type = "toggle",
								order = 2.481,
								width = "half",
								disabled = Lockdown,
								set = function(info, value) LUF.db.profile.units.raid.filters[8] = value LUF:SetupHeader("raid8") LUF:UpdateMovers() end,
								get = function(info, value) return LUF.db.profile.units.raid.filters[8] end,
							},
							raid8 = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.482,
								values = getAnchors,
								get = function() return LUF.db.profile.units.raid.positions[8].anchorTo end,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x8 = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.483,
								width = 0.8,
								validate = nbrValidate,
								get = function() return tostring(LUF.db.profile.units.raid.positions[8].x) end,
								set = function(info, value) LUF.db.profile.units.raid.positions[8].x = tonumber(value) LUF:PlaceFrame(LUF.frameIndex["raid8"]) end,
								disabled = Lockdown,
							},
							y8 = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.484,
								width = 0.8,
								validate = nbrValidate,
								get = function() return tostring(LUF.db.profile.units.raid.positions[8].y) end,
								set = function(info, value) LUF.db.profile.units.raid.positions[8].y = tonumber(value) LUF:PlaceFrame(LUF.frameIndex["raid8"]) end,
								disabled = Lockdown,
							},
							headerraid9 = {
								name = RAID.."9",
								type = "header",
								order = 2.49,
								hidden = function() return LUF.isClassic or LUF.db.profile.units.raid.groupBy ~= "CLASS" end,
							},
							enabled9 = {
								name = ENABLE,
								desc = L["Enable this group"],
								type = "toggle",
								order = 2.491,
								width = "half",
								disabled = Lockdown,
								set = function(info, value) LUF.db.profile.units.raid.filters[9] = value LUF:SetupHeader("raid9") LUF:UpdateMovers() end,
								get = function(info, value) return LUF.db.profile.units.raid.filters[9] end,
								hidden = function() return LUF.isClassic or LUF.db.profile.units.raid.groupBy ~= "CLASS" end,
							},
							raid9 = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.492,
								values = getAnchors,
								get = function() return LUF.db.profile.units.raid.positions[9].anchorTo end,
								set = SetAnchorTo,
								disabled = Lockdown,
								hidden = function() return LUF.isClassic or LUF.db.profile.units.raid.groupBy ~= "CLASS" end,
							},
							x9 = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.493,
								width = 0.8,
								validate = nbrValidate,
								get = function() return tostring(LUF.db.profile.units.raid.positions[9].x) end,
								set = function(info, value) LUF.db.profile.units.raid.positions[9].x = tonumber(value) LUF:PlaceFrame(LUF.frameIndex["raid9"]) end,
								disabled = Lockdown,
								hidden = function() return LUF.isClassic or LUF.db.profile.units.raid.groupBy ~= "CLASS" end,
							},
							y9 = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.494,
								width = 0.8,
								validate = nbrValidate,
								get = function() return tostring(LUF.db.profile.units.raid.positions[9].y) end,
								set = function(info, value) LUF.db.profile.units.raid.positions[9].y = tonumber(value) LUF:PlaceFrame(LUF.frameIndex["raid9"]) end,
								disabled = Lockdown,
								hidden = function() return LUF.isClassic or LUF.db.profile.units.raid.groupBy ~= "CLASS" end,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 2.5,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			},
			raidpet = {
				name = L["raidpet"],
				type = "group",
				order = 17,
				arg = LUF.db.profile.units.raidpet,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], L["raidpet"]),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 2.1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2.2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 2.3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
								set = setHeader,
							},
							offset = {
								name = L["Offset"],
								desc = L["Set the space between units."],
								type = "range",
								order = 2.4,
								min = 0,
								max = 200,
								step = 1,
								disabled = Lockdown,
								set = setHeader,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 2.5,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 2.7,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							attribPoint = {
								name = L["Growth direction"],
								desc = L["The direction in which new frames are added."],
								type = "select",
								order = 2.8,
								values = {["RIGHT"] = L["Left"],["LEFT"] = L["Right"],["BOTTOM"] = L["Up"],["TOP"] = L["Down"]},
								--get = function(info) return LUF.db.profile.units["raid"].attribPoint end,
								set = setGrowthDir,
							},
							sortMethod = {
								name = L["Sort by"],
								desc = L["Sort by name or index"],
								type = "select",
								order = 2.9,
								values = {["INDEX"] = L["Index"],["NAME"] = NAME},
								set = setSortMethod,
								disabled = Lockdown,
							},
							sortOrder = {
								name = L["Sort order"],
								desc = L["Sort ascending or descending"],
								type = "select",
								order = 2.91,
								values = {["ASC"] = L["Ascending"],["DESC"] = L["Descending"]},
								set = setSortOrder,
								disabled = Lockdown,
							},
							showWhen = {
								name = L["Show when"],
								desc = string.format(L["This is set through %s options."],RAID),
								type = "select",
								order = 2.921,
								values = {["ALWAYS"] = ALWAYS,["PARTY"] = PARTY, ["RAID"] = RAID},
								get = getShowWhen,
								set = function(info,value) end,
								disabled = true,
							},
							hideParty = {
								name = L["Hide < 6 Raid"],
								desc = string.format(L["This is set through %s options."],RAID),
								type = "toggle",
								order = 2.922,
								get = function(info) return LUF.db.profile.units.raid.hideParty end,
								disabled = true,
							},
							unitsPerColumn = {
								name = L["Units per column"],
								desc = L["The amount of units until a new column is started"],
								type = "range",
								order = 2.93,
								min = 1,
								max = 40,
								step = 1,
								disabled = Lockdown,
								set = function(info, value) set(info,value) LUF:SetupHeader("raidpet") end,
							},
							maxColumns = {
								name = L["Max columns"],
								desc = L["The maximum amount of columns"],
								type = "range",
								order = 2.94,
								min = 1,
								max = 40,
								step = 1,
								disabled = Lockdown,
								set = function(info, value) set(info,value) LUF:SetupHeader("raidpet") end,
							},
							columnSpacing = {
								name = L["Column spacing"],
								desc = L["The space between each column"],
								type = "range",
								order = 2.95,
								min = 0,
								max = 200,
								step = 1,
								disabled = Lockdown,
								set = function(info, value) set(info,value) LUF:SetupHeader("raidpet") end,
							},
							attribAnchorPoint = {
								name = L["Column Growth direction"],
								desc = L["Where a new column is started"],
								type = "select",
								order = 2.96,
								values = {["RIGHT"] = L["Left"],["LEFT"] = L["Right"],["BOTTOM"] = L["Up"],["TOP"] = L["Down"]},
								get = function(info) return LUF.db.profile.units["raidpet"].attribAnchorPoint end,
								set = function(info, value) LUF.db.profile.units["raidpet"].attribAnchorPoint = value LUF:SetupHeader("raidpet") end,
								disabled = Lockdown,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 2.97,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			},
			maintank = {
				name = MAINTANK,
				type = "group",
				order = 18,
				arg = LUF.db.profile.units.maintank,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], MAINTANK),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
								set = setHeader,
							},
							offset = {
								name = L["Offset"],
								desc = L["Set the space between units."],
								type = "range",
								order = 4,
								min = 0,
								max = 200,
								step = 1,
								disabled = Lockdown,
								set = setHeader,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 5,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 7,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							attribPoint = {
								name = L["Growth direction"],
								desc = L["The direction in which new frames are added."],
								type = "select",
								order = 8,
								values = {["RIGHT"] = L["Left"],["LEFT"] = L["Right"],["BOTTOM"] = L["Up"],["TOP"] = L["Down"]},
								set = setGrowthDir,
								disabled = Lockdown,
							},
							sortMethod = {
								name = L["Sort by"],
								desc = L["Sort by name or index"],
								type = "select",
								order = 9,
								values = {["INDEX"] = L["Index"],["NAME"] = NAME},
								set = setSortMethod,
								disabled = Lockdown,
							},
							sortOrder = {
								name = L["Sort order"],
								desc = L["Sort ascending or descending"],
								type = "select",
								order = 10,
								values = {["ASC"] = L["Ascending"],["DESC"] = L["Descending"]},
								set = setSortOrder,
								disabled = Lockdown,
							},
							unitsPerColumn = {
								name = L["Limit"],
								desc = L["The maximum amount to show"],
								type = "range",
								order = 11,
								min = 1,
								max = 40,
								step = 1,
								disabled = Lockdown,
								set = function(info, value) setHeader(info, value) LUF:SetupHeader("maintanktarget") LUF:SetupHeader("maintanktargettarget") end,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 12,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			},
			maintanktarget = {
				name = L["maintanktarget"],
				type = "group",
				order = 19,
				arg = LUF.db.profile.units.maintanktarget,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], L["maintanktarget"]),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
								set = setHeader,
							},
							offset = {
								name = L["Offset"],
								desc = L["Set the space between units."],
								type = "range",
								order = 4,
								min = 0,
								max = 200,
								step = 1,
								disabled = Lockdown,
								set = setHeader,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 5,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 7,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							attribPoint = {
								name = L["Growth direction"],
								desc = L["The direction in which new frames are added."],
								type = "select",
								order = 8,
								values = {["RIGHT"] = L["Left"],["LEFT"] = L["Right"],["BOTTOM"] = L["Up"],["TOP"] = L["Down"]},
								set = setGrowthDir,
								disabled = Lockdown,
							},
							sortMethod = {
								name = L["Sort by"],
								desc = L["Sort by name or index"],
								type = "select",
								order = 9,
								values = {["INDEX"] = L["Index"],["NAME"] = NAME},
								set = setSortMethod,
								disabled = Lockdown,
							},
							sortOrder = {
								name = L["Sort order"],
								desc = L["Sort ascending or descending"],
								type = "select",
								order = 10,
								values = {["ASC"] = L["Ascending"],["DESC"] = L["Descending"]},
								set = setSortOrder,
								disabled = Lockdown,
							},
							unitsPerColumn = {
								name = L["Limit"],
								desc = string.format(L["This is set through %s options."],MAINTANK),
								type = "range",
								order = 11,
								min = 1,
								max = 40,
								step = 1,
								disabled = function() return true end,
								get = function() return LUF.db.profile.units.maintank.unitsPerColumn end,
								set = setHeader,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 12,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			},
			maintanktargettarget = {
				name = L["maintanktargettarget"],
				type = "group",
				order = 20,
				arg = LUF.db.profile.units.maintanktargettarget,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], L["maintanktargettarget"]),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
								set = setHeader,
							},
							offset = {
								name = L["Offset"],
								desc = L["Set the space between units."],
								type = "range",
								order = 4,
								min = 0,
								max = 200,
								step = 1,
								disabled = Lockdown,
								set = setHeader,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 5,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 7,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							attribPoint = {
								name = L["Growth direction"],
								desc = L["The direction in which new frames are added."],
								type = "select",
								order = 8,
								values = {["RIGHT"] = L["Left"],["LEFT"] = L["Right"],["BOTTOM"] = L["Up"],["TOP"] = L["Down"]},
								set = setGrowthDir,
								disabled = Lockdown,
							},
							sortMethod = {
								name = L["Sort by"],
								desc = L["Sort by name or index"],
								type = "select",
								order = 9,
								values = {["INDEX"] = L["Index"],["NAME"] = NAME},
								set = setSortMethod,
								disabled = Lockdown,
							},
							sortOrder = {
								name = L["Sort order"],
								desc = L["Sort ascending or descending"],
								type = "select",
								order = 10,
								values = {["ASC"] = L["Ascending"],["DESC"] = L["Descending"]},
								set = setSortOrder,
								disabled = Lockdown,
							},
							unitsPerColumn = {
								name = L["Limit"],
								desc = string.format(L["This is set through %s options."],MAINTANK),
								type = "range",
								order = 11,
								min = 1,
								max = 40,
								step = 1,
								disabled = function() return true end,
								get = function() return LUF.db.profile.units.maintank.unitsPerColumn end,
								set = setHeader,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 12,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			},
			mainassist = {
				name = MAIN_ASSIST,
				type = "group",
				order = 21,
				arg = LUF.db.profile.units.mainassist,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], MAIN_ASSIST),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
								set = setHeader,
							},
							offset = {
								name = L["Offset"],
								desc = L["Set the space between units."],
								type = "range",
								order = 4,
								min = 0,
								max = 200,
								step = 1,
								disabled = Lockdown,
								set = setHeader,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 5,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 7,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							attribPoint = {
								name = L["Growth direction"],
								desc = L["The direction in which new frames are added."],
								type = "select",
								order = 8,
								values = {["RIGHT"] = L["Left"],["LEFT"] = L["Right"],["BOTTOM"] = L["Up"],["TOP"] = L["Down"]},
								set = setGrowthDir,
								disabled = Lockdown,
							},
							sortMethod = {
								name = L["Sort by"],
								desc = L["Sort by name or index"],
								type = "select",
								order = 9,
								values = {["INDEX"] = L["Index"],["NAME"] = NAME},
								set = setSortMethod,
								disabled = Lockdown,
							},
							sortOrder = {
								name = L["Sort order"],
								desc = L["Sort ascending or descending"],
								type = "select",
								order = 10,
								values = {["ASC"] = L["Ascending"],["DESC"] = L["Descending"]},
								set = setSortOrder,
								disabled = Lockdown,
							},
							unitsPerColumn = {
								name = L["Limit"],
								desc = L["The maximum amount to show"],
								type = "range",
								order = 11,
								min = 1,
								max = 40,
								step = 1,
								disabled = Lockdown,
								set = function(info, value) setHeader(info,value) LUF:SetupHeader("mainassisttarget") LUF:SetupHeader("mainassisttargettarget") end,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 12,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			},
			mainassisttarget = {
				name = L["mainassisttarget"],
				type = "group",
				order = 22,
				arg = LUF.db.profile.units.mainassisttarget,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], L["mainassisttarget"]),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
								set = setHeader,
							},
							offset = {
								name = L["Offset"],
								desc = L["Set the space between units."],
								type = "range",
								order = 4,
								min = 0,
								max = 200,
								step = 1,
								disabled = Lockdown,
								set = setHeader,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 5,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 7,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							attribPoint = {
								name = L["Growth direction"],
								desc = L["The direction in which new frames are added."],
								type = "select",
								order = 8,
								values = {["RIGHT"] = L["Left"],["LEFT"] = L["Right"],["BOTTOM"] = L["Up"],["TOP"] = L["Down"]},
								set = setGrowthDir,
								disabled = Lockdown,
							},
							sortMethod = {
								name = L["Sort by"],
								desc = L["Sort by name or index"],
								type = "select",
								order = 9,
								values = {["INDEX"] = L["Index"],["NAME"] = NAME},
								set = setSortMethod,
								disabled = Lockdown,
							},
							sortOrder = {
								name = L["Sort order"],
								desc = L["Sort ascending or descending"],
								type = "select",
								order = 10,
								values = {["ASC"] = L["Ascending"],["DESC"] = L["Descending"]},
								set = setSortOrder,
								disabled = Lockdown,
							},
							unitsPerColumn = {
								name = L["Limit"],
								desc = string.format(L["This is set through %s options."],MAIN_ASSIST),
								type = "range",
								order = 11,
								min = 1,
								max = 40,
								step = 1,
								disabled = function() return true end,
								get = function() return LUF.db.profile.units.mainassist.unitsPerColumn end,
								set = setHeader,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 12,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			},
			mainassisttargettarget = {
				name = L["mainassisttargettarget"],
				type = "group",
				order = 23,
				arg = LUF.db.profile.units.mainassisttargettarget,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], L["mainassisttargettarget"]),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
								set = setHeader,
							},
							offset = {
								name = L["Offset"],
								desc = L["Set the space between units."],
								type = "range",
								order = 4,
								min = 0,
								max = 200,
								step = 1,
								disabled = Lockdown,
								set = setHeader,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 5,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 7,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							attribPoint = {
								name = L["Growth direction"],
								desc = L["The direction in which new frames are added."],
								type = "select",
								order = 8,
								values = {["RIGHT"] = L["Left"],["LEFT"] = L["Right"],["BOTTOM"] = L["Up"],["TOP"] = L["Down"]},
								set = setGrowthDir,
								disabled = Lockdown,
							},
							sortMethod = {
								name = L["Sort by"],
								desc = L["Sort by name or index"],
								type = "select",
								order = 9,
								values = {["INDEX"] = L["Index"],["NAME"] = NAME},
								set = setSortMethod,
								disabled = Lockdown,
							},
							sortOrder = {
								name = L["Sort order"],
								desc = L["Sort ascending or descending"],
								type = "select",
								order = 10,
								values = {["ASC"] = L["Ascending"],["DESC"] = L["Descending"]},
								set = setSortOrder,
								disabled = Lockdown,
							},
							unitsPerColumn = {
								name = L["Limit"],
								desc = string.format(L["This is set through %s options."],MAIN_ASSIST),
								type = "range",
								order = 11,
								min = 1,
								max = 40,
								step = 1,
								disabled = function() return true end,
								get = function() return LUF.db.profile.units.mainassist.unitsPerColumn end,
								set = setHeader,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 12,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			},
			arena = ArenaAndFocusExists and {
				name = L["arena"],
				type = "group",
				order = 24,
				arg = LUF.db.profile.units.arena,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], L["arena"]),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
								set = setHeader,
							},
							offset = {
								name = L["Offset"],
								desc = L["Set the space between units."],
								type = "range",
								order = 4,
								min = 0,
								max = 200,
								step = 1,
								disabled = Lockdown,
								set = setHeader,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 5,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 7,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							attribPoint = {
								name = L["Growth direction"],
								desc = L["The direction in which new frames are added."],
								type = "select",
								order = 8,
								values = {["RIGHT"] = L["Left"],["LEFT"] = L["Right"],["BOTTOM"] = L["Up"],["TOP"] = L["Down"]},
								set = setGrowthDir,
								disabled = Lockdown,
							},
							enableFocus = {
								name = L["Right click to focus"],
								desc = L["Focus the unit upon right clicking"],
								type = "toggle",
								order = 9,
								disabled = Lockdown,
								set = function(info, value) set(info, value) LUF:SetupHeader("arena") end,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 10,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			} or nil,
			arenapet = ArenaAndFocusExists and {
				name = L["arenapet"],
				type = "group",
				order = 25,
				arg = LUF.db.profile.units.arenapet,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], L["arenapet"]),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
								set = setHeader,
							},
							offset = {
								name = L["Offset"],
								desc = L["Set the space between units."],
								type = "range",
								order = 4,
								min = 0,
								max = 200,
								step = 1,
								disabled = Lockdown,
								set = setHeader,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 5,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 7,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							attribPoint = {
								name = L["Growth direction"],
								desc = L["The direction in which new frames are added."],
								type = "select",
								order = 8,
								values = {["RIGHT"] = L["Left"],["LEFT"] = L["Right"],["BOTTOM"] = L["Up"],["TOP"] = L["Down"]},
								set = setGrowthDir,
								disabled = Lockdown,
							},
							enableFocus = {
								name = L["Right click to focus"],
								desc = L["Focus the unit upon right clicking"],
								type = "toggle",
								order = 9,
								disabled = Lockdown,
								set = function(info, value) set(info, value) LUF:SetupHeader("arenapet") end,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 10,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			} or nil,
			arenatarget = ArenaAndFocusExists and{
				name = L["arenatarget"],
				type = "group",
				order = 26,
				arg = LUF.db.profile.units.arenatarget,
				childGroups = "tab",
				args = {
					enabled = {
						name = ENABLE,
						desc = string.format(L["Enable the %s frame(s)"], L["arenatarget"]),
						type = "toggle",
						order = 1,
						disabled = Lockdown,
						set = setEnableUnit,
					},
					GeneralOptions = {
						name = GENERAL,
						type = "group",
						order = 2,
						args = {
							height = {
								name = L["Height"],
								desc = L["Set the height of the frame."],
								type = "range",
								order = 1,
								min = 10,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							width = {
								name = L["Width"],
								desc = L["Set the width of the frame."],
								type = "range",
								order = 2,
								min = 20,
								max = 600,
								step = 1,
								width = "full",
								disabled = Lockdown,
								set = setHeader,
							},
							scale = {
								name = L["Scale"],
								desc = L["Set the scale of the frame."],
								type = "range",
								order = 3,
								min = 0.5,
								max = 3,
								step = 0.01,
								isPercent = true,
								width = "double",
								disabled = Lockdown,
								set = setHeader,
							},
							offset = {
								name = L["Offset"],
								desc = L["Set the space between units."],
								type = "range",
								order = 4,
								min = 0,
								max = 200,
								step = 1,
								disabled = Lockdown,
								set = setHeader,
							},
							anchorTo = {
								name = L["Anchor To"],
								desc = L["Anchor to another frame."],
								type = "select",
								order = 5,
								values = getAnchors,
								set = SetAnchorTo,
								disabled = Lockdown,
							},
							x = {
								name = L["X Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 6,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							y = {
								name = L["Y Position"],
								desc = L["Set the position of the frame."],
								type = "input",
								order = 7,
								validate = nbrValidate,
								get = getPos,
								set = setPos,
								disabled = Lockdown,
							},
							attribPoint = {
								name = L["Growth direction"],
								desc = L["The direction in which new frames are added."],
								type = "select",
								order = 8,
								values = {["RIGHT"] = L["Left"],["LEFT"] = L["Right"],["BOTTOM"] = L["Up"],["TOP"] = L["Down"]},
								set = setGrowthDir,
								disabled = Lockdown,
							},
							slots = {
								name = L["Bars"],
								type = "group",
								order = 9,
								set = set,
								inline = true,
								args = {
									left = {
										name = L["Left"],
										type = "group",
										order = 1,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									center = {
										name = L["Center"],
										type = "group",
										order = 2,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
									right = {
										name = L["Right"],
										type = "group",
										order = 3,
										args = {
											orientation = {
												name = L["Stacking"],
												desc = L["Direction for stacking"],
												type = "select",
												order = 1,
												values = {["vertical"] = L["Vertical"], ["horizontal"] = L["Horizontal"]},
											},
											value = {
												name = L["Width"],
												desc = L["Set the width of the bars."],
												type = "range",
												order = 2,
												min = 1,
												max = 10,
												step = 0.1,
											},
										},
									},
								},
							},
						},
					},
				},
			} or nil,
			filters = {
				name = L["Filters"],
				type = "group",
				order = 26.5,
				args = {
					desc = {
						name = L["Create and manage reusable aura filter lists"],
						type = "description",
						order = 0.5,
						fontSize = "medium",
					},
					helptip = {
						name = "|cff888888" .. L["Filters help tip"] .. "|r",
						type = "description",
						order = 0.6,
					},
					togglecreate = {
						name = function() return LUF._showCreateForm and L["Hide Create Form"] or L["New Filter List"] end,
						type = "execute",
						order = 1,
						width = "normal",
						func = function()
							LUF._showCreateForm = not LUF._showCreateForm
							LUF._filterNameError = nil
							ACR:NotifyChange("LunaUnitFrames")
						end,
					},
					toggleimport = {
						name = function() return LUF._showImportForm and L["Hide Import"] or L["Import"] end,
						type = "execute",
						order = 1.1,
						width = "normal",
						func = function()
							LUF._showImportForm = not LUF._showImportForm
							LUF._importError = nil
							ACR:NotifyChange("LunaUnitFrames")
						end,
					},
					creategroup = {
						name = L["New Filter List"],
						type = "group",
						order = 2,
						inline = true,
						hidden = function() return not LUF._showCreateForm end,
						args = {
							newname = {
								name = L["Name for the new filter list"],
								type = "input",
								order = 1,
								get = function() return LUF._newFilterName or "" end,
								set = function(info, value)
									LUF._newFilterName = value
									LUF._filterNameError = nil
									ACR:NotifyChange("LunaUnitFrames")
								end,
							},
							create = {
								name = L["Create"],
								type = "execute",
								order = 2,
								width = "half",
								disabled = function() return not LUF._newFilterName or LUF._newFilterName == "" end,
								func = function()
									local name = LUF._newFilterName
									if not name or name == "" then return end
									if not LUF.db.profile.filters then LUF.db.profile.filters = {} end
									if LUF.db.profile.filters[name] then
										LUF._filterNameError = L["Filter name already exists"]
										ACR:NotifyChange("LunaUnitFrames")
										return
									end
									LUF.db.profile.filters[name] = {}
									LUF._newFilterName = nil
									LUF._filterNameError = nil
									LUF._selectedFilter = name
									LUF._showCreateForm = false
									notifyFilterUI()
								end,
							},
							nameerror = {
								name = function() return "|cffff4444" .. (LUF._filterNameError or "") .. "|r" end,
								type = "description",
								order = 3,
								hidden = function() return not LUF._filterNameError end,
							},
						},
					},
					importgroup = {
						name = L["Import"],
						type = "group",
						order = 2.5,
						inline = true,
						hidden = function() return not LUF._showImportForm end,
						args = {
							importdesc = {
								name = "|cff888888" .. L["Import desc"] .. "|r",
								type = "description",
								order = 0,
							},
							importstring = {
								name = L["Import"],
								type = "input",
								order = 1,
								width = "double",
								get = function() return "" end,
								set = function(info, value)
									if not value or value == "" then return end
									local name, idStr = value:match("^(.+):(.+)$")
									if not name or not idStr then
										LUF._importError = L["Import format error"]
										ACR:NotifyChange("LunaUnitFrames")
										return
									end
									name = strtrim(name)
									if name == "" then
										LUF._importError = L["Import format error"]
										ACR:NotifyChange("LunaUnitFrames")
										return
									end
									local newList = {}
									local count = 0
									for idPart in idStr:gmatch("[^,]+") do
										local id = tonumber(strtrim(idPart))
										if id then
											newList[id] = true
											count = count + 1
										end
									end
									if count == 0 then
										LUF._importError = L["Import format error"]
										ACR:NotifyChange("LunaUnitFrames")
										return
									end
									if not LUF.db.profile.filters then LUF.db.profile.filters = {} end
									LUF.db.profile.filters[name] = newList
									LUF._selectedFilter = name
									LUF._importError = nil
									LUF._showImportForm = false
									LUF:RefreshAuraFilters()
									notifyFilterUI()
								end,
							},
							importerror = {
								name = function() return "|cffff4444" .. (LUF._importError or "") .. "|r" end,
								type = "description",
								order = 2,
								hidden = function() return not LUF._importError end,
							},
						},
					},
					listheader = {
						name = L["Filter Lists"],
						type = "header",
						order = 3,
						hidden = function()
							return not (LUF.db.profile.filters and next(LUF.db.profile.filters))
						end,
					},
					selectfilter = {
						name = L["Filter Lists"],
						desc = L["Select a filter list to edit"],
						type = "select",
						order = 4,
						hidden = function()
							return not (LUF.db.profile.filters and next(LUF.db.profile.filters))
						end,
						values = function()
							local t = {}
							for name in pairs(LUF.db.profile.filters or {}) do
								t[name] = name
							end
							return t
						end,
						get = function() return LUF._selectedFilter end,
						set = function(info, value)
							LUF._selectedFilter = value
							LUF._spellSearchText = nil
							LUF._spellSearchResultsList = nil
							LUF._spellSearchSelected = nil
							LUF._searchListOffset = 0
							LUF._renameFilterName = nil
							LUF._renameFilterError = nil
							LUF._exportString = nil
							notifyFilterUI()
						end,
					},
					deletefilter = {
						name = DELETE,
						desc = L["Delete this filter list"],
						type = "execute",
						order = 4.1,
						width = "half",
						confirm = true,
						hidden = function() return not LUF._selectedFilter end,
						func = function()
							if not (LUF._selectedFilter and LUF.db.profile.filters) then return end
							local delName = LUF._selectedFilter
							LUF.db.profile.filters[delName] = nil
							LUF:ClearAuraFilterName(delName)
							LUF._selectedFilter = nil
							LUF:RefreshAuraFilters()
							notifyFilterUI()
						end,
					},
					exportbtn = {
						name = L["Export"],
						desc = L["Export string desc"],
						type = "execute",
						order = 4.2,
						width = "half",
						hidden = function() return not LUF._selectedFilter end,
						func = function()
							if LUF._exportString then
								LUF._exportString = nil
								ACR:NotifyChange("LunaUnitFrames")
								return
							end
							if not LUF._selectedFilter or not LUF.db.profile.filters then return end
							local list = LUF.db.profile.filters[LUF._selectedFilter]
							if not list then return end
							local ids = {}
							for id in pairs(list) do
								tinsert(ids, tostring(id))
							end
							table.sort(ids, function(a, b) return tonumber(a) < tonumber(b) end)
							LUF._exportString = LUF._selectedFilter .. ":" .. table.concat(ids, ",")
							ACR:NotifyChange("LunaUnitFrames")
						end,
					},
					renameinput = {
						name = L["Rename"],
						desc = L["Rename this filter list"],
						type = "input",
						order = 4.5,
						hidden = function() return not LUF._selectedFilter end,
						get = function() return LUF._renameFilterName or "" end,
						set = function(info, value) LUF._renameFilterName = value LUF._renameFilterError = nil end,
					},
					renameconfirm = {
						name = L["Rename"],
						type = "execute",
						order = 4.6,
						width = "half",
						hidden = function() return not LUF._selectedFilter end,
						disabled = function() return not LUF._renameFilterName or LUF._renameFilterName == "" end,
						func = function()
							local oldName = LUF._selectedFilter
							local newName = LUF._renameFilterName
							if not oldName or not newName or newName == "" then return end
							if not LUF.db.profile.filters or not LUF.db.profile.filters[oldName] then return end
							if newName == oldName then return end
							if LUF.db.profile.filters[newName] then
								LUF._renameFilterError = L["Filter name already exists"]
								ACR:NotifyChange("LunaUnitFrames")
								return
							end
							LUF.db.profile.filters[newName] = LUF.db.profile.filters[oldName]
							LUF.db.profile.filters[oldName] = nil
							LUF:ReplaceAuraFilterName(oldName, newName)
							LUF._selectedFilter = newName
							LUF._renameFilterName = nil
							LUF._renameFilterError = nil
							LUF:RefreshAuraFilters()
							notifyFilterUI()
						end,
					},
					renameerror = {
						name = function() return "|cffff4444" .. (LUF._renameFilterError or "") .. "|r" end,
						type = "description",
						order = 4.7,
						hidden = function() return not LUF._renameFilterError end,
					},
					exportcopybox = {
						name = L["Export"],
						type = "input",
						order = 4.8,
						width = "full",
						hidden = function() return not LUF._exportString end,
						get = function() return LUF._exportString or "" end,
						set = function() LUF._exportString = nil ACR:NotifyChange("LunaUnitFrames") end,
					},
					spellsheader = {
						name = L["Add Aura"],
						type = "header",
						order = 10,
						hidden = function() return not LUF._selectedFilter end,
					},
					searchinput = {
						name = L["Search by aura name or enter an aura ID"],
						desc = L["Aura search desc"],
						type = "input",
						order = 11,
						width = "double",
						hidden = function() return not LUF._selectedFilter end,
						get = function() return LUF._spellSearchText or "" end,
						set = function(info, value)
							if not LUF._selectedFilter then return end
							LUF._spellSearchText = value
							LUF._spellSearchSelected = nil
							LUF._searchListOffset = 0
							LUF:SearchAuras(value, function()
								if ACR then ACR:NotifyChange("LunaUnitFrames") end
							end)
							ACR:NotifyChange("LunaUnitFrames")
						end,
					},
					searchindexstatus = {
						name = function()
							local p = LUF._spellIndexProgress
							if not p then return "" end
							return "|cffcccccc" .. string.format(L["Building aura index"], math.floor(p * 100)) .. "|r"
						end,
						type = "description",
						order = 11.4,
						hidden = function() return not LUF:IsAuraIndexBuilding() end,
					},
					searchresults = {
						name = function()
							local results = LUF._spellSearchResultsList
							local n = results and #results or 0
							if n > 0 then
								return L["Search Results"] .. " (" .. n .. ")"
							end
							return L["Search Results"]
						end,
						type = "select",
						dialogControl = "LUF_ScrollSelect",
						order = 12,
						width = "full",
						hidden = function() return not LUF._selectedFilter or not LUF._spellSearchResultsList or #LUF._spellSearchResultsList == 0 end,
						values = function()
							local t = {}
							local results = LUF._spellSearchResultsList
							if not results then return t end
							for i = 1, #results do
								local entry = results[i]
								if entry then
									t[tostring(entry.id)] = "|T" .. (entry.icon or 134400) .. ":16:16:0:0|t " .. entry.name .. " |cff888888(ID: " .. entry.id .. ")|r"
								end
							end
							return t
						end,
						sorting = function()
							local t = {}
							local results = LUF._spellSearchResultsList
							if not results then return t end
							for i = 1, #results do
								local entry = results[i]
								if entry then
									t[#t + 1] = tostring(entry.id)
								end
							end
							return t
						end,
						get = function() return LUF._spellSearchSelected end,
						set = function(info, value)
							LUF._spellSearchSelected = value
						end,
					},
					addselected = {
						name = ADD,
						desc = L["Add this aura to the filter list"],
						type = "execute",
						order = 13,
						width = "half",
						hidden = function() return not LUF._selectedFilter or not LUF._spellSearchResultsList or #LUF._spellSearchResultsList == 0 end,
						disabled = function() return not LUF._spellSearchSelected end,
						func = function()
							if not LUF._selectedFilter or not LUF._spellSearchSelected then return end
							local list = LUF.db.profile.filters[LUF._selectedFilter]
							if not list then return end
							local id = tonumber(LUF._spellSearchSelected)
							if id then
								list[id] = true
							end
							LUF._spellSearchText = nil
							LUF._spellSearchResultsList = nil
							LUF._spellSearchSelected = nil
							LUF._searchListOffset = 0
							LUF:RefreshAuraFilters()
							notifyFilterUI()
						end,
					},
					spelllistheader = {
						name = L["Auras in Filter"],
						type = "header",
						order = 19,
						hidden = function() return not LUF._selectedFilter end,
					},
					spelllist = {
						name = "",
						type = "group",
						order = 20,
						inline = true,
						hidden = function() return not LUF._selectedFilter end,
						args = {},
						plugins = {
							spells = {},
						},
					},
				},
			},
			hidden = {
				name = L["Hide Blizzard"],
				type = "group",
				order = 27,
				get = function(info) return LUF.db.profile.hidden[info[#info]] end,
				disabled = Lockdown,
				set = function(info, value) LUF.db.profile.hidden[info[#info]] = value LUF:HideBlizzardFrames() end,
				args = {
					ReloadUI = {
						name = RELOADUI,
						type = "execute",
						func = function(info) ReloadUI() end,
						order = 1,
						disabled = function() end,
					},
					help = {
						order = 2,
						type = "group",
						name = L["Hint"],
						inline = true,
						args = {
							description = {
								type = "description",
								name = L["You will need to do a /console reloadui before a hidden frame becomes visible again."],
								width = "full",
							},
						},
					},
					player = {
						name = PLAYER,
						desc = string.format(L["Hides the default %s frame"], PLAYER),
						type = "toggle",
						order = 3,
					},
					pet = {
						name = PET,
						desc = string.format(L["Hides the default %s frame"], PET),
						type = "toggle",
						order = 4,
					},
					cast = {
						name = SHOW_ARENA_ENEMY_CASTBAR_TEXT,
						desc = string.format(L["Hides the default %s frame"], SHOW_ARENA_ENEMY_CASTBAR_TEXT),
						type = "toggle",
						order = 5,
					},
					buffs = {
						name = L["Buffs"],
						desc = string.format(L["Hides the default %s frame"], L["Buffs"]),
						type = "toggle",
						order = 6,
					},
					target = {
						name = TARGET,
						desc = string.format(L["Hides the default %s frame"], TARGET),
						type = "toggle",
						order = 7,
					},
					focus = ArenaAndFocusExists and {
						name = FOCUS,
						desc = string.format(L["Hides the default %s frame"], FOCUS),
						type = "toggle",
						order = 8,
					} or nil,
					party = {
						name = PARTY,
						desc = string.format(L["Hides the default %s frame"], PARTY),
						type = "toggle",
						order = 9,
					},
					raid = {
						name = RAID,
						desc = string.format(L["Hides the default %s frame"], RAID),
						type = "toggle",
						order = 10,
						set = function(info, value)
							LUF.db.profile.hidden.raid = value
							if not value then
								LUF.db.profile.hidden.raidManager = false
							end
							LUF:HideBlizzardFrames()
						end,
					},
					raidManager = {
						name = L["RaidManager"],
						desc = string.format(L["Hides the default %s frame"], L["RaidManager"]),
						type = "toggle",
						order = 11,
						get = function()
							return LUF.db.profile.hidden.raidManager
						end,
						set = function(info, value)
							LUF.db.profile.hidden.raidManager = value
							if value then
								LUF.db.profile.hidden.raid = true
							end
							LUF:HideBlizzardFrames()
						end,
					},
					arena = ArenaAndFocusExists and {
						name = ARENA,
						desc = string.format(L["Hides the default %s frame"], ARENA),
						type = "toggle",
						order = 20,
					} or nil,
				},
			},
			help = {
				name = L["Tag Help"],
				type = "group",
				order = 28,
				args = {
					help = {
						order = 1,
						type = "group",
						name = L["Tags - Help"],
						inline = true,
						args = {
							description = {
								type = "description",
								name = L["You can use tags to change the text information displayed on each frame. Just go to the tag section of the frame you want to change and put in some tags."],
								width = "full",
							},
						},
					},
					infoheader = {
						name = L["Info tags"],
						type = "header",
						order = 2,
					},
				},
			},
			autoprofiles = {
				name = L["Auto Profiles"],
				type = "group",
				order = 29,
				args = {
					help = {
						order = 1,
						type = "group",
						name = L["Auto Profiles - Help"],
						inline = true,
						args = {
							description = {
								type = "description",
								name = L["You can set up here which profiles should be automatically loaded on certain conditions."],
								width = "full",
							},
						},
					},
					switchtype = {
						name = L["Switch by"],
						desc = L["Type of event to switch to"],
						type = "select",
						order = 2,
						values = {["DISABLED"] = ADDON_DISABLED, ["GROUP"] = L["Size of Group"]},
						get = function(info) return LUF.db.char.switchtype end,
						set = function(info, value) LUF.db.char.switchtype = value LUF:AutoswitchProfileSetup() end,
					},
					groupselect = {
						name = L["Size of Group"],
						desc = L["Size of group to assign a profile to"],
						type = "select",
						order = 4,
						hidden = function() return LUF.db.char.switchtype ~= "GROUP" end,
						values = {["RAID40"]=L["Raid40"],["RAID25"]=L["Raid25"],["RAID20"]=L["Raid20"],["RAID15"]=L["Raid15"],["RAID10"]=L["Raid10"],["RAID5"]=L["Raid5"],["PARTY"]=PARTY,["SOLO"]=SOLO},
						get = function(info) return groupselectvalue end,
						set = function(info, value) groupselectvalue = value end,
					},
					profileselect = {
						name = L["Profile"],
						desc = L["Name of the profile which to switch to"],
						type = "select",
						order = 5,
						values = function() LUF.db:GetProfiles(profiledb) profiledb["NIL"] = NONE return profiledb end,
						hidden = function() return LUF.db.char.switchtype == "DISABLED" end,
						get = function(info)
							LUF.db:GetProfiles(profiledb)
							profiledb["NIL"] = NONE
							for k,v in pairs(profiledb) do
								if v == LUF.db.char.grpdb[groupselectvalue] then
									return k
								end
							end
							return "NIL"
							
						end,
						set = function(info, value)
							LUF.db:GetProfiles(profiledb)
							profiledb["NIL"] = NONE
							LUF.db.char.grpdb[groupselectvalue] = value ~= "NIL" and profiledb[value] or nil
						end,
					},
				},
			},
		},
	}
	for mod, tbl in pairs(moduleOptions) do
		for _,unit in ipairs(LUF.unitList) do
			if not (moduleBlacklist[mod] and moduleBlacklist[mod][unit]) then
				aceoptions.args[unit].args[mod] = tbl
			end
		end
	end

	local updatingFilterList = false
	UpdateFilterSpellList = function()
		if updatingFilterList then return end
		updatingFilterList = true
		local spells = {}
		local filterName = LUF._selectedFilter
		if filterName and LUF.db.profile.filters and LUF.db.profile.filters[filterName] then
			local order = 1
			for spellId in pairs(LUF.db.profile.filters[filterName]) do
				local spellName, spellIcon = LUF:GetSpellNameIcon(spellId)
				spellName = spellName or ("Aura #" .. spellId)
				spellIcon = spellIcon or 134400
				spells["info_" .. spellId] = {
					name = "|T" .. spellIcon .. ":18:18:0:0|t " .. spellName .. " |cff888888(" .. spellId .. ")|r",
					type = "description",
					order = order,
					width = "normal",
					fontSize = "medium",
				}
				spells["del_" .. spellId] = {
					name = "",
					desc = L["Remove this aura from the filter list"],
					type = "execute",
					image = "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
					imageWidth = 14,
					imageHeight = 14,
					order = order + 0.1,
					width = "half",
					confirm = true,
					func = function()
						LUF.db.profile.filters[filterName][spellId] = nil
						LUF:RefreshAuraFilters()
						notifyFilterUI()
					end,
				}
				order = order + 1
			end
			if order == 1 then
				spells["empty"] = {
					name = "|cff666666" .. L["No auras added yet"] .. "|r",
					type = "description",
					order = 1,
				}
			end
		end
		aceoptions.args.filters.args.spelllist.plugins.spells = spells
		updatingFilterList = false
	end
	UpdateFilterSpellList()
	local i = 3
	for k in pairs(InfoTags) do
		aceoptions.args.help.args[k] = {
			order = i,
			type = "description",
			name = "["..k.."] = "..(L[k.."desc"] or L[k]),
			width = "full",
		}
		i = i + 1
	end
	aceoptions.args.help.args["healthnpowerheader"] = {
		order = i,
		type = "header",
		name = L["Health and power tags"],
	}
	i = i + 1
	for k in pairs(HealthnPowerTags) do
		aceoptions.args.help.args[k] = {
			order = i,
			type = "description",
			name = "["..k.."] = "..L[k],
			width = "full",
		}
		i = i + 1
	end
	aceoptions.args.help.args["colorheader"] = {
		order = i,
		type = "header",
		name = L["Color tags"],
	}
	i = i + 1
	for k in pairs(ColorTags) do
		aceoptions.args.help.args[k] = {
			order = i,
			type = "description",
			name = "["..k.."] = "..L[k],
			width = "full",
		}
		i = i + 1
	end
	ACR:RegisterOptionsTable(Addon, aceoptions, true)
	aceoptions.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)


	AceConfigDialog:AddToBlizOptions(Addon, nil, nil, "general")
	AceConfigDialog:AddToBlizOptions(Addon, COLORS, Addon, "colors")
	for _,unit in ipairs(LUF.unitList) do
		AceConfigDialog:AddToBlizOptions(Addon, L[unit], Addon, unit)
	end
	AceConfigDialog:AddToBlizOptions(Addon, L["Hide Blizzard"], Addon, "hidden")
	AceConfigDialog:AddToBlizOptions(Addon, L["Filters"], Addon, "filters")
	AceConfigDialog:AddToBlizOptions(Addon, L["Tag Help"], Addon, "help")
	AceConfigDialog:AddToBlizOptions(Addon, L["Auto Profiles"], Addon, "autoprofiles")
	AceConfigDialog:AddToBlizOptions(Addon, L["Testing"], Addon, "testing")
	AceConfigDialog:AddToBlizOptions(Addon, L["Profiles"], Addon, "profile")

	AceConfigDialog:SetDefaultSize(Addon, 895, 570)
end

SLASH_LUNAUF1 = "/luf"
SLASH_LUNAUF2 = "/luna"
SLASH_LUNAUF3 = "/lunauf"
SLASH_LUNAUF4 = "/lunaunitframes"
SlashCmdList["LUNAUF"] = function(msg)
	msg = msg and string.lower(msg)
	if( msg and string.match(msg, "^profile (.+)") ) then
		local profile = string.match(msg, "^profile (.+)")
		
		for id, name in pairs(LUF.db:GetProfiles()) do
			if( string.lower(name) == profile ) then
				LUF.db:SetProfile(name)
				LUF:Print(string.format(L["Changed profile to %s."], name))
				return
			end
		end
		LUF:Print(string.format(L["Cannot find any profiles named \"%s\"."], profile))
		return
	end

	LUF:CreateConfig()
	AceConfigDialog:Open(Addon)
end

-- Build options the first time Interface Options is opened, not at login.
if InterfaceOptionsFrame then
	InterfaceOptionsFrame:HookScript("OnShow", function()
		LUF:CreateConfig()
	end)
end