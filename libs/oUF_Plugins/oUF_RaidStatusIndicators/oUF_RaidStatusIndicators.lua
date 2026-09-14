--[[
# Element: Raid Status Indicators

Shows different statuses for group play (aggro, auras, dispel).

## Widget

RaidStatusIndicators - A `table` containing frames with a .texture to show the status on.

## Sub Widget Options

.texture     - The texture object (texture)
.type        - Type of indicator (string)
               "aggro", "legacythreat", "aura", "dispel", "missing", "ownaura"
.showTexture - Show corresponding icon on aura / dispel type instead of a color (boolean)
.timer       - Show spinning timer (boolean)
.value      .- Table containing string buff/debuff names. For missing its a table of tables of strings. Tables are logically linked "AND" and strings in the tables themselves are logically linked "OR"

## Notes

???

## Examples

    -- Position and size
    local RaidStatusIndicators = {}

    local indicator = CreateFrame("Frame", nil, self)
    indicator.texture = indicator:CreateTexture(nil, "OVERLAY")
    indicator.texture:SetAllPoints(indicator)
    indicator.type = "aggro"

    -- Register with oUF
    self.RaidStatusIndicators = {
        indicator = indicator,
    }
--]]

local _, ns = ...
local oUF = ns.oUF
local AuraCache = ns.AuraCache

local Vex = LibStub("LibVexation-1.0")

local WHITE_TEX = [[Interface\Buttons\WHITE8X8]]

local function compileAuraEntries(nameID)
	local compiled = { n = 0, entries = {} }
	for _, spell in ipairs(nameID) do
		local id = tonumber(spell)
		if id then
			compiled.n = compiled.n + 1
			compiled.entries[compiled.n] = { id = id }
		elseif type(spell) == "string" and spell ~= "" then
			compiled.n = compiled.n + 1
			compiled.entries[compiled.n] = { lower = strlower(spell) }
		end
	end
	return compiled
end

local function compileMissingEntries(nameID)
	local compiled = { groups = {} }
	for _, spellGroup in ipairs(nameID) do
		local group = { n = #spellGroup }
		compiled.groups[#compiled.groups + 1] = group
		for j, spell in ipairs(spellGroup) do
			local manaOnly = false
			if strfind(spell, "%[mana%]") then
				spell = spell:gsub("%[mana%]", "")
				manaOnly = true
			end
			local spellInfo = C_Spell.GetSpellInfo(spell)
			local spellID = tonumber(spell) or (spellInfo and spellInfo.spellID)
			group[j] = {
				id = spellID,
				unresolvable = not spellID,
				manaOnly = manaOnly,
				missingName = spell,
			}
		end
	end
	return compiled
end

local function ensureCompiled(indicator)
	if indicator._compiled and indicator._compileGen == AuraCache.generation then
		return indicator._compiled
	end
	if indicator.type == "aura" or indicator.type == "ownaura" then
		if indicator.nameID then
			indicator._compiled = compileAuraEntries(indicator.nameID)
		end
	elseif indicator.type == "missing" and indicator.nameID then
		indicator._compiled = compileMissingEntries(indicator.nameID)
	end
	indicator._compileGen = AuraCache.generation
	return indicator._compiled
end

local function rebuildBuckets(element)
	element._threat = element._threat or {}
	element._aura = element._aura or {}
	for i = #element._threat, 1, -1 do element._threat[i] = nil end
	for i = #element._aura, 1, -1 do element._aura[i] = nil end
	for _, indicator in pairs(element) do
		if type(indicator) == "table" and indicator.type then
			if indicator.type == "aggro" or indicator.type == "legacythreat" then
				element._threat[#element._threat + 1] = indicator
			elseif indicator.type == "aura" or indicator.type == "ownaura"
				or indicator.type == "missing" or indicator.type == "dispel" then
				element._aura[#element._aura + 1] = indicator
			end
		end
	end
	element._bucketsDirty = false
end

local function findAuraRecord(snap, entry, playeronly)
	if not entry then return end
	if entry.id then
		if playeronly then
			return snap.helpfulByIDPlayer[entry.id] or snap.harmfulByIDPlayer[entry.id]
		end
		return snap.helpfulByID[entry.id] or snap.harmfulByID[entry.id]
	end
	if entry.lower and entry.lower ~= "" then
		for i = 1, snap.helpfulCount do
			local record = snap.helpful[i]
			local lowerName = record and record.lowerName
			if lowerName and strmatch(lowerName, entry.lower) and (not playeronly or record.isPlayer) then
				return record
			end
		end
		for i = 1, snap.harmfulCount do
			local record = snap.harmful[i]
			local lowerName = record and record.lowerName
			if lowerName and strmatch(lowerName, entry.lower) and (not playeronly or record.isPlayer) then
				return record
			end
		end
	end
end

local function checkAuraSnap(snap, compiled, playeronly)
	if not compiled then return end
	for i = 1, compiled.n do
		local record = findAuraRecord(snap, compiled.entries[i], playeronly)
		if record then
			return record
		end
	end
end

local function checkDispelSnap(snap, index)
	if not snap.canAssist then return end
	index = index or 1
	if index < 1 or index > (snap.dispelCount or 0) then return end
	return snap.dispels[index]
end

local function checkMissingSnap(snap, compiled)
	if not compiled then return end
	local found, missingSpell
	for _, group in ipairs(compiled.groups) do
		for j = 1, group.n do
			local entry = group[j]
			if entry.manaOnly and not snap.isManaUser then
				found = true
			end
			if not found then
				missingSpell = entry.missingName
				if entry.unresolvable then
					found = true
				elseif snap.helpfulByID[entry.id] then
					found = true
				end
			end
		end
		if found or not missingSpell then
			found = nil
		else
			return missingSpell
		end
	end
end

local function setShown(indicator, shown)
	indicator._shown = shown
	if shown then
		indicator:Show()
	else
		indicator:Hide()
	end
end

local function setTexture(indicator, tex)
	if indicator._tex ~= tex then
		indicator._tex = tex
		indicator.texture:SetTexture(tex)
	end
end

local function setVertexColor(indicator, r, g, b)
	if indicator._r ~= r or indicator._g ~= g or indicator._b ~= b then
		indicator._r, indicator._g, indicator._b = r, g, b
		indicator.texture:SetVertexColor(r, g, b)
	end
end

local function setCooldown(indicator, shown, start, duration)
	if indicator._cdShown ~= shown then
		indicator._cdShown = shown
		if shown then
			indicator.cd:Show()
		else
			indicator.cd:Hide()
		end
	end
	if shown and (indicator._cdStart ~= start or indicator._cdDur ~= duration) then
		indicator._cdStart = start
		indicator._cdDur = duration
		indicator.cd:SetCooldown(start, duration)
	end
end

local function setCount(indicator, text)
	if indicator._countText ~= text then
		indicator._countText = text
		indicator.count:Show()
		indicator.count:SetText(text)
	end
end

local function setDispelColor(indicator, debuffType)
	local color = oUF.colors.dispel[debuffType]
	setTexture(indicator, WHITE_TEX)
	if color then
		setVertexColor(indicator, color[1], color[2], color[3])
	else
		setVertexColor(indicator, 0, 0, 0)
	end
end

local function paintRecord(indicator, record, withCount, hideCountdown)
	if not record then
		setShown(indicator, false)
		return false
	end
	setShown(indicator, true)
	if indicator.showTexture then
		setTexture(indicator, record.icon)
		setVertexColor(indicator, 1, 1, 1)
	else
		setDispelColor(indicator, record.debuffType)
	end
	if indicator.timer then
		setCooldown(indicator, true, record.expirationTime - record.duration, record.duration)
	else
		setCooldown(indicator, false)
	end
	if hideCountdown then
		indicator.cd:SetHideCountdownNumbers(true)
	end
	if withCount then
		setCount(indicator, record.count > 1 and record.count or "")
	end
	return true
end

local function updateThreatIndicators(self, element, unit)
	local hasAggro = UnitThreatSituation(UnitExists(unit) and unit or "player")
	local legacyThreat = Vex and Vex:GetUnitAggroByUnitId(unit)

	for _, indicator in ipairs(element._threat) do
		if indicator.type == "aggro" then
			if hasAggro and hasAggro > 0 then
				setShown(indicator, true)
				setCooldown(indicator, false)
				setTexture(indicator, WHITE_TEX)
				local color = hasAggro == 1 and oUF.colors.reaction[4] or oUF.colors.reaction[1]
				setVertexColor(indicator, color[1], color[2], color[3])
			else
				setShown(indicator, false)
			end
		elseif indicator.type == "legacythreat" then
			if legacyThreat then
				setShown(indicator, true)
				setCooldown(indicator, false)
				setTexture(indicator, WHITE_TEX)
				local color = oUF.colors.reaction[1]
				setVertexColor(indicator, color[1], color[2], color[3])
			else
				setShown(indicator, false)
			end
		end
	end

	return hasAggro, legacyThreat
end

local function updateAuraIndicators(element, snap)
	local hasAura, isMissing, hasOwn

	for _, indicator in ipairs(element._aura) do
		if indicator.type == "aura" and indicator.nameID then
			if paintRecord(indicator, checkAuraSnap(snap, ensureCompiled(indicator), false), true, true) then
				hasAura = true
			end
		elseif indicator.type == "ownaura" and indicator.nameID then
			if paintRecord(indicator, checkAuraSnap(snap, ensureCompiled(indicator), true), true) then
				hasOwn = true
			end
		elseif indicator.type == "dispel" then
			paintRecord(indicator, checkDispelSnap(snap, indicator.dispel_index))
		elseif indicator.type == "missing" and indicator.nameID then
			isMissing = checkMissingSnap(snap, ensureCompiled(indicator))
			if isMissing then
				setShown(indicator, true)
				setCooldown(indicator, false)
				if indicator.showTexture then
					setTexture(indicator, C_Spell.GetSpellTexture(isMissing))
					setVertexColor(indicator, 1, 1, 1)
				else
					setDispelColor(indicator, "None")
				end
			else
				setShown(indicator, false)
			end
		else
			setShown(indicator, false)
		end
	end

	return hasAura, isMissing, hasOwn
end

local function runUpdate(self, unit, doThreat, doAura)
	unit = unit or self.unit
	if not unit then return end
	local element = self.RaidStatusIndicators
	if element.PreUpdate then
		element:PreUpdate(unit)
	end
	if element._bucketsDirty then
		rebuildBuckets(element)
	end

	local hasAggro, hasAura, isMissing, hasOwn
	if doThreat then
		hasAggro = updateThreatIndicators(self, element, unit)
	else
		hasAggro = UnitThreatSituation(UnitExists(unit) and unit or "player")
	end
	if doAura then
		hasAura, isMissing, hasOwn = updateAuraIndicators(element, AuraCache:Touch(unit))
	end
	if element.PostUpdate then
		return element:PostUpdate(unit, hasAggro, nil, hasAura, isMissing, hasOwn)
	end
end

local function Update(self, event, unit)
	if event == "UNIT_PET" and unit and unit ~= "player" then return end
	if event == "SPELLS_CHANGED" or event == "UNIT_PET" then
		return runUpdate(self, self.unit, false, true)
	end
	if unit and self.unit ~= unit then return end
	unit = unit or self.unit
	if event == "UNIT_AURA" then
		return runUpdate(self, unit, false, true)
	elseif event == "ForceUpdate" or event == "RefreshUnit" or event == "OnShow" then
		return runUpdate(self, unit, true, true)
	end
	return runUpdate(self, unit, true, false)
end

local function Path(self, ...)
	return (self.RaidStatusIndicators.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function Enable(self)
	local element = self.RaidStatusIndicators
	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate
		element._bucketsDirty = true

		for name, indicator in pairs(element) do
			if type(indicator) == "table" then
				indicator._shown = false
				indicator:Hide()
				if not indicator.cd then
					indicator.cd = CreateFrame("Cooldown", self:GetName()..name.."RaidStatusCD", indicator, "CooldownFrameTemplate")
					indicator.cd:SetDrawEdge(false)
					indicator.cd:SetDrawSwipe(true)
					indicator.cd:SetReverse(true)
					indicator.cd:SetSwipeColor(0, 0, 0, 0.8)
					indicator.cd:SetAllPoints(indicator)
				end

				if not indicator.count then
					local countFrame = CreateFrame("Frame", nil, indicator)
					countFrame:SetAllPoints(indicator)
					countFrame:SetFrameLevel(indicator.cd:GetFrameLevel() + 1)

					indicator.count = countFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
					local fontName = indicator.count:GetFont()
					indicator.count:SetFont(fontName, 10, "OUTLINE")
					indicator.count:SetPoint("BOTTOMRIGHT", countFrame, "BOTTOMRIGHT", -1, 0)
				end
			end
		end

		local function LegacyThreatUpdate(_, guid)
			if guid == UnitGUID(self.unit) then
				runUpdate(self, self.unit, true, false)
			end
		end

		if Vex then
			Vex.RegisterCallback(element, "Vexation_gained", LegacyThreatUpdate)
			Vex.RegisterCallback(element, "Vexation_lost", LegacyThreatUpdate)
		end

		self:RegisterEvent("UNIT_AURA", Path)
		self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", Path)
		self:RegisterEvent("SPELLS_CHANGED", Path, true)
		self:RegisterEvent("UNIT_PET", Path)

		Update(self, "ForceUpdate", self.unit)

		return true
	end
end

local function Disable(self)
	local element = self.RaidStatusIndicators
	if element then
		if Vex then
			Vex.UnregisterCallback(element, "Vexation_gained")
			Vex.UnregisterCallback(element, "Vexation_lost")
		end

		self:UnregisterEvent("UNIT_AURA", Path)
		self:UnregisterEvent("UNIT_THREAT_SITUATION_UPDATE", Path)
		self:UnregisterEvent("SPELLS_CHANGED", Path)
		self:UnregisterEvent("UNIT_PET", Path)
	end
end

oUF:AddElement("RaidStatusIndicators", Path, Enable, Disable)
