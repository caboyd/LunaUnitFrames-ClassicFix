local _, LUF = ...

local compiledLists = {}
local mergedCache = {}

local INDEX_CHUNK = 400
local INDEX_START_SCAN = 20000
local INDEX_EMPTY_STOP = 5000
local INDEX_HARD_CAP = 80000

local spellIndex
local indexBuild
local indexing
local indexFrom
local emptyStreak
local pendingQuery
local pendingOnDone

local function spellNameIcon(idOrName)
	local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(idOrName)
	if type(info) == "table" and info.name then
		return info.name, info.iconID or info.originalIconID, info.spellID
	end
	local name, _, icon, _, _, _, spellID = GetSpellInfo(idOrName)
	return name, icon, spellID
end

local function wipeCache(cache)
	for k in pairs(cache) do
		cache[k] = nil
	end
end

function LUF:InvalidateAuraFilterCache()
	wipeCache(compiledLists)
	wipeCache(mergedCache)
end

local function compileNamedList(listName)
	local compiled = compiledLists[listName]
	if compiled then
		return compiled
	end
	local raw = LUF.db.profile.filters and LUF.db.profile.filters[listName]
	if type(raw) ~= "table" then
		return nil
	end
	compiled = { ids = {}, names = {} }
	local hasAny = false
	for spellId in pairs(raw) do
		local id = tonumber(spellId)
		if id then
			compiled.ids[id] = true
			hasAny = true
			local name = spellNameIcon(id)
			if name then
				compiled.names[strlower(name)] = true
			end
		end
	end
	if not hasAny then
		return nil
	end
	compiledLists[listName] = compiled
	return compiled
end

local function listNamesFromAssignment(listNames)
	if not listNames then
		return nil
	end
	if type(listNames) == "string" then
		if listNames == "" then
			return nil
		end
		return { listNames }
	end
	if type(listNames) ~= "table" then
		return nil
	end
	local names = {}
	for k, v in pairs(listNames) do
		if type(v) == "string" and v ~= "" then
			names[#names + 1] = v
		elseif v == true and type(k) == "string" then
			names[#names + 1] = k
		end
	end
	if #names == 0 then
		return nil
	end
	table.sort(names)
	return names
end

function LUF:GetMergedAuraFilter(listNames, mode)
	if not listNames or not mode or mode == "disabled" then
		return nil
	end
	local names = listNamesFromAssignment(listNames)
	if not names then
		return nil
	end
	local key = mode .. "\1" .. table.concat(names, "\1")
	local cached = mergedCache[key]
	if cached ~= nil then
		return cached or nil
	end
	local merged = { ids = {}, names = {} }
	local hasAny = false
	for i = 1, #names do
		local list = compileNamedList(names[i])
		if list then
			for id in pairs(list.ids) do
				merged.ids[id] = true
				hasAny = true
			end
			for lower in pairs(list.names) do
				merged.names[lower] = true
			end
		end
	end
	if not hasAny then
		mergedCache[key] = false
		return nil
	end
	mergedCache[key] = merged
	return merged
end

function LUF.ApplyAuraFilters(frame)
	local Auras = frame.SimpleAuras
	if not Auras then
		return
	end
	local unit = frame.GetAttribute and frame:GetAttribute("oUF-guessUnit")
	local config = unit and LUF.db.profile.units[unit]
	local auraFilters = config and config.auras and config.auras.filters
	if not auraFilters then
		Auras.buffSpellFilter = nil
		Auras.buffSpellFilterMode = "disabled"
		Auras.debuffSpellFilter = nil
		Auras.debuffSpellFilterMode = "disabled"
		return
	end
	local buffMode = auraFilters.buffMode or "disabled"
	local debuffMode = auraFilters.debuffMode or "disabled"
	Auras.buffSpellFilter = LUF:GetMergedAuraFilter(auraFilters.buffs, buffMode)
	Auras.buffSpellFilterMode = Auras.buffSpellFilter and buffMode or "disabled"
	Auras.debuffSpellFilter = LUF:GetMergedAuraFilter(auraFilters.debuffs, debuffMode)
	Auras.debuffSpellFilterMode = Auras.debuffSpellFilter and debuffMode or "disabled"
end

function LUF:RefreshAuraFilters(unitType)
	self:InvalidateAuraFilterCache()
	local objects = self.oUF and self.oUF.objects
	if not objects then
		return
	end
	for i = 1, #objects do
		local frame = objects[i]
		if frame and frame.SimpleAuras then
			local guess = frame.GetAttribute and frame:GetAttribute("oUF-guessUnit")
			if not unitType or guess == unitType then
				self.ApplyAuraFilters(frame)
				if frame.IsElementEnabled and frame:IsElementEnabled("SimpleAuras") and frame.SimpleAuras.ForceUpdate then
					frame.SimpleAuras:ForceUpdate()
				end
			end
		end
	end
end

function LUF:EnsureUnitAuraFilters(unit)
	local auras = LUF.db.profile.units[unit] and LUF.db.profile.units[unit].auras
	if not auras then
		return nil
	end
	if not auras.filters then
		auras.filters = {
			buffs = {},
			debuffs = {},
			buffMode = "disabled",
			debuffMode = "disabled",
		}
	end
	local filters = auras.filters
	if type(filters.buffs) == "string" then
		local old = filters.buffs
		filters.buffs = {}
		if old ~= "" then
			tinsert(filters.buffs, old)
		end
	elseif type(filters.buffs) ~= "table" then
		filters.buffs = {}
	end
	if type(filters.debuffs) == "string" then
		local old = filters.debuffs
		filters.debuffs = {}
		if old ~= "" then
			tinsert(filters.debuffs, old)
		end
	elseif type(filters.debuffs) ~= "table" then
		filters.debuffs = {}
	end
	return filters
end

function LUF:AuraFilterAssignmentHas(filters, field, key)
	if not filters then
		return false
	end
	local assigned = filters[field]
	if type(assigned) == "string" then
		return assigned == key
	end
	if type(assigned) ~= "table" then
		return false
	end
	for _, name in pairs(assigned) do
		if name == key then
			return true
		end
	end
	return false
end

function LUF:SetAuraFilterAssignment(unit, field, key, enabled)
	local filters = self:EnsureUnitAuraFilters(unit)
	if not filters then
		return
	end
	if type(filters[field]) ~= "table" then
		self:EnsureUnitAuraFilters(unit)
	end
	local list = filters[field]
	if enabled then
		for _, name in pairs(list) do
			if name == key then
				return
			end
		end
		tinsert(list, key)
	else
		for i, name in ipairs(list) do
			if name == key then
				tremove(list, i)
				break
			end
		end
	end
end

function LUF:ReplaceAuraFilterName(oldName, newName)
	for _, unitCfg in pairs(LUF.db.profile.units) do
		local filters = unitCfg.auras and unitCfg.auras.filters
		if filters then
			for _, field in ipairs({ "buffs", "debuffs" }) do
				local assigned = filters[field]
				if type(assigned) == "string" and assigned == oldName then
					filters[field] = newName
				elseif type(assigned) == "table" then
					for i, name in ipairs(assigned) do
						if name == oldName then
							assigned[i] = newName
							break
						end
					end
				end
			end
		end
	end
end

function LUF:ClearAuraFilterName(delName)
	for _, unitCfg in pairs(LUF.db.profile.units) do
		local filters = unitCfg.auras and unitCfg.auras.filters
		if filters then
			if type(filters.buffs) == "string" and filters.buffs == delName then
				filters.buffs = {}
				filters.buffMode = "disabled"
			elseif type(filters.buffs) == "table" then
				for i, name in ipairs(filters.buffs) do
					if name == delName then
						tremove(filters.buffs, i)
						break
					end
				end
				if not next(filters.buffs) then
					filters.buffMode = "disabled"
				end
			end
			if type(filters.debuffs) == "string" and filters.debuffs == delName then
				filters.debuffs = {}
				filters.debuffMode = "disabled"
			elseif type(filters.debuffs) == "table" then
				for i, name in ipairs(filters.debuffs) do
					if name == delName then
						tremove(filters.debuffs, i)
						break
					end
				end
				if not next(filters.debuffs) then
					filters.debuffMode = "disabled"
				end
			end
		end
	end
end

function LUF:GetSpellNameIcon(idOrName)
	return spellNameIcon(idOrName)
end

local function addSearchEntry(results, seen, id, name, icon)
	if not id or seen[id] then
		return
	end
	seen[id] = true
	results[#results + 1] = { id = id, name = name, icon = icon or 134400 }
end

local function searchSpellbook(results, seen, queryLower)
	if not GetNumSpellTabs or not GetSpellTabInfo then
		return
	end
	local bank = BOOKTYPE_SPELL or "spell"
	local tabs = GetNumSpellTabs()
	for t = 1, tabs do
		local _, _, offset, numSpells = GetSpellTabInfo(t)
		if offset and numSpells then
			for i = offset + 1, offset + numSpells do
				local name = GetSpellBookItemName(i, bank)
				if name and strfind(strlower(name), queryLower, 1, true) then
					local id
					if GetSpellBookItemInfo then
						local slotType, spellId = GetSpellBookItemInfo(i, bank)
						if slotType == "SPELL" or slotType == "FUTURESPELL" then
							id = spellId
						end
					end
					if not id then
						local _, _, spellID = spellNameIcon(name)
						id = spellID
					end
					if id then
						local _, icon = spellNameIcon(id)
						addSearchEntry(results, seen, id, name, icon)
					end
				end
			end
		end
	end
end

local function searchIndex(results, seen, queryLower)
	if not spellIndex then
		return
	end
	for i = 1, #spellIndex do
		local entry = spellIndex[i]
		if strfind(entry.lower, queryLower, 1, true) then
			addSearchEntry(results, seen, entry.id, entry.name, entry.icon)
		end
	end
end

local function sortResults(results)
	table.sort(results, function(a, b)
		if a.name == b.name then
			return a.id < b.id
		end
		return a.name < b.name
	end)
end

local function finishIndex()
	spellIndex = indexBuild
	indexBuild = nil
	indexing = nil
	LUF._spellIndexProgress = nil
	if pendingQuery then
		local query = pendingQuery
		local onDone = pendingOnDone
		pendingQuery = nil
		pendingOnDone = nil
		LUF:SearchAuras(query, onDone)
		if onDone then
			onDone()
		end
	end
end

local function indexChunk()
	if not indexing then
		return
	end
	local to = math.min(indexFrom + INDEX_CHUNK - 1, INDEX_HARD_CAP)
	for id = indexFrom, to do
		local name, icon = spellNameIcon(id)
		if name then
			emptyStreak = 0
			indexBuild[#indexBuild + 1] = {
				id = id,
				name = name,
				icon = icon or 134400,
				lower = strlower(name),
			}
		else
			emptyStreak = emptyStreak + 1
			if id > INDEX_START_SCAN and emptyStreak >= INDEX_EMPTY_STOP then
				indexFrom = INDEX_HARD_CAP + 1
				break
			end
		end
	end
	if indexFrom <= INDEX_HARD_CAP then
		indexFrom = to + 1
	end
	if indexFrom > INDEX_HARD_CAP then
		LUF._spellIndexProgress = 1
		finishIndex()
		return
	end
	LUF._spellIndexProgress = indexFrom / INDEX_HARD_CAP
	C_Timer.After(0, indexChunk)
end

local function ensureIndex(query, onDone)
	if spellIndex then
		return true
	end
	pendingQuery = query
	pendingOnDone = onDone
	if indexing then
		return false
	end
	indexing = true
	indexBuild = {}
	indexFrom = 1
	emptyStreak = 0
	LUF._spellIndexProgress = 0
	C_Timer.After(0, indexChunk)
	return false
end

function LUF:SearchAuras(query, onDone)
	local results = {}
	LUF._spellSearchResultsList = results
	if not query or query == "" then
		return results
	end
	local seen = {}
	local id = tonumber(query)
	if id then
		local name, icon = spellNameIcon(id)
		addSearchEntry(results, seen, id, name or ("Aura #" .. id), icon)
		return results
	end
	local exactName, exactIcon, exactID = spellNameIcon(query)
	if exactName and exactID then
		addSearchEntry(results, seen, exactID, exactName, exactIcon)
	end
	local queryLower = strlower(query)
	searchSpellbook(results, seen, queryLower)
	if spellIndex then
		searchIndex(results, seen, queryLower)
	else
		ensureIndex(query, onDone)
	end
	sortResults(results)
	return results
end

function LUF:IsAuraIndexBuilding()
	return indexing and true or false
end
