-- Shared per-GUID aura snapshot cache. Records are recycled across rebuilds
-- and must not be stored by consumers.
local _, ns = ...

local AuraCache = {}
ns.AuraCache = AuraCache
LUF.AuraCache = AuraCache

local tokenGUID = {}
local guidTokens = {}
local snapshots = {}
local dirtyGUIDs = {}
local rebuiltThisFrame = {}
local recordPool = {}
local testOpts = {}

local serial = 0
AuraCache.generation = 0
AuraCache.canCure = {}

local playerClass = select(2, UnitClass("player"))
local cures = {
	["DRUID"] = {[2782] = {"Curse"}, [2893] = {"Poison"}, [8946] = {"Poison"}},
	["PRIEST"] = {[528] = {"Disease"}, [552] = {"Disease"}, [527] = {"Magic"}, [988] = {"Magic"}},
	["PALADIN"] = {[4987] = {"Poison", "Disease", "Magic"}, [1152] = {"Poison", "Disease"}},
	["SHAMAN"] = {[2870] = {"Disease"}, [526] = {"Poison"}},
	["MAGE"] = {[475] = {"Curse"}},
}
cures = cures[playerClass]

local function newSnapshot()
	return {
		helpful = {},
		harmful = {},
		helpfulByID = {},
		harmfulByID = {},
		helpfulByIDPlayer = {},
		harmfulByIDPlayer = {},
		dispels = {},
		helpfulCount = 0,
		harmfulCount = 0,
		dispelCount = 0,
	}
end

local EMPTY_SNAP = newSnapshot()

local auraSource
local LCD = LibStub and LibStub("LibClassicDurations", true)

local recordPoolN = 0

local function acquireRecord()
	if recordPoolN > 0 then
		local record = recordPool[recordPoolN]
		recordPool[recordPoolN] = nil
		recordPoolN = recordPoolN - 1
		return record
	end
	return {}
end

local function releaseArray(arr, count)
	for i = 1, count do
		recordPoolN = recordPoolN + 1
		recordPool[recordPoolN] = arr[i]
		arr[i] = nil
	end
end

local function releaseSnapshotRecords(snap)
	-- dispels aliases harmful records; never pool them separately.
	releaseArray(snap.helpful, snap.helpfulCount)
	releaseArray(snap.harmful, snap.harmfulCount)
	for i = 1, snap.dispelCount do
		snap.dispels[i] = nil
	end
end

local function resolveUnit(guid)
	local tokens = guidTokens[guid]
	if not tokens then return end
	for token in pairs(tokens) do
		if UnitGUID(token) == guid then
			return token
		end
	end
	for token in pairs(tokens) do
		return token
	end
end

local function fillRecord(record, index, filter, name, icon, count, debuffType, duration, expirationTime, caster, isStealable, spellID)
	record.name = name
	record.lowerName = name and strlower(name) or nil
	record.icon = icon
	record.count = count
	record.debuffType = debuffType
	record.duration = duration
	record.expirationTime = expirationTime
	record.caster = caster
	record.isStealable = isStealable
	record.isPlayer = caster == "player" or caster == "vehicle" or (caster and UnitIsUnit(caster, "player")) or false
	record.spellID = spellID
	record.index = index
	record.filter = filter
end

local function indexByID(byID, byIDPlayer, record)
	local spellID = record.spellID
	if spellID and not byID[spellID] then
		byID[spellID] = record
	end
	if spellID and record.isPlayer and not byIDPlayer[spellID] then
		byIDPlayer[spellID] = record
	end
end

local function addRecord(snap, record, harmful)
	if harmful then
		local count = snap.harmfulCount + 1
		snap.harmfulCount = count
		snap.harmful[count] = record
		indexByID(snap.harmfulByID, snap.harmfulByIDPlayer, record)
		if record.debuffType and not snap.firstDebuffType then
			snap.firstDebuffType = record.debuffType
		end
		if AuraCache.canCure[record.debuffType] then
			local dispelCount = snap.dispelCount + 1
			snap.dispelCount = dispelCount
			snap.dispels[dispelCount] = record
		end
	else
		local count = snap.helpfulCount + 1
		snap.helpfulCount = count
		snap.helpful[count] = record
		indexByID(snap.helpfulByID, snap.helpfulByIDPlayer, record)
	end
end

local function scanAuras(snap, unit, src, filter, harmful)
	for i = 1, 40 do
		local name, icon, count, debuffType, duration, expirationTime, caster, isStealable, _, spellID = src(unit, i, filter)
		if not name then break end
		local record = acquireRecord()
		fillRecord(record, i, filter, name, icon, count, debuffType, duration, expirationTime, caster, isStealable, spellID)
		addRecord(snap, record, harmful)
	end
end

local function enrichSnapshotLCD(snap, unit)
	if not LCD or AuraCache.test.active or UnitIsUnit("player", unit) then return end
	for i = 1, snap.helpfulCount do
		local record = snap.helpful[i]
		if record.spellID then
			local durationNew, expirationTimeNew = LCD:GetAuraDurationByUnit(unit, record.spellID, record.caster, record.name)
			if durationNew and durationNew > 0 then
				record.duration = durationNew
				record.expirationTime = expirationTimeNew
			end
		end
	end
end

local function rebuildSnapshot(guid, unit)
	unit = unit or resolveUnit(guid)
	if not unit then return end
	if not AuraCache.test.active and not UnitExists(unit) then return end

	local snap = snapshots[guid]
	if not snap then
		snap = newSnapshot()
		snapshots[guid] = snap
	else
		releaseSnapshotRecords(snap)
	end

	snap.guid = guid
	serial = serial + 1
	snap.serial = serial
	snap.helpfulCount = 0
	snap.harmfulCount = 0
	snap.dispelCount = 0
	snap.firstDebuffType = nil
	table.wipe(snap.helpfulByID)
	table.wipe(snap.harmfulByID)
	table.wipe(snap.helpfulByIDPlayer)
	table.wipe(snap.harmfulByIDPlayer)

	if AuraCache.test.active and not UnitExists(unit) then
		snap.canAssist = true
		snap.isFriend = true
		snap.isManaUser = true
	else
		snap.canAssist = UnitCanAssist("player", unit)
		snap.isFriend = UnitIsFriend(unit, "player")
		local unitClass = select(2, UnitClass(unit))
		snap.isManaUser = unitClass ~= "ROGUE" and unitClass ~= "WARRIOR"
	end

	if AuraCache.test.active then
		testOpts.now = GetTime()
	end
	local src = auraSource or ns.UnitAura
	scanAuras(snap, unit, src, "HELPFUL", false)
	scanAuras(snap, unit, src, "HARMFUL", true)
	enrichSnapshotLCD(snap, unit)
	snap.generation = AuraCache.generation
	snap.dirty = false
end

local function markGUIDDirty(guid)
	if guid then
		dirtyGUIDs[guid] = true
	end
end

local function trackUnit(unit)
	local guid = UnitGUID(unit)
	local oldGuid = tokenGUID[unit]
	if oldGuid and oldGuid ~= guid then
		if guidTokens[oldGuid] then
			guidTokens[oldGuid][unit] = nil
		end
		markGUIDDirty(oldGuid)
	end
	if guid then
		tokenGUID[unit] = guid
		if not guidTokens[guid] then guidTokens[guid] = {} end
		guidTokens[guid][unit] = true
	end
end

local function markUnitDirty(unit)
	trackUnit(unit)
	markGUIDDirty(tokenGUID[unit])
	local guid = UnitGUID(unit)
	if guid ~= tokenGUID[unit] then
		markGUIDDirty(guid)
	end
end

local function onDriverUpdate()
	for guid in pairs(dirtyGUIDs) do
		if not rebuiltThisFrame[guid] then
			local snap = snapshots[guid]
			if snap then
				snap.dirty = true
			end
		end
		dirtyGUIDs[guid] = nil
	end
	table.wipe(rebuiltThisFrame)
end

local function remapTokens()
	for token, guid in pairs(tokenGUID) do
		if UnitExists(token) then
			local current = UnitGUID(token)
			if current and current ~= guid then
				if guidTokens[guid] then
					guidTokens[guid][token] = nil
				end
				tokenGUID[token] = current
				if not guidTokens[current] then guidTokens[current] = {} end
				guidTokens[current][token] = true
				markGUIDDirty(current)
			end
		end
	end
end

local function rebuildCanCure()
	table.wipe(AuraCache.canCure)
	if playerClass == "WARLOCK" then
		if C_Spell.IsSpellUsable(19505) then
			AuraCache.canCure["Magic"] = true
		end
	elseif cures then
		for spellID, types in pairs(cures) do
			if C_SpellBook.IsSpellKnown(spellID) then
				for _, debuffType in pairs(types) do
					AuraCache.canCure[debuffType] = true
				end
			end
		end
	end
	AuraCache.generation = AuraCache.generation + 1
	for guid in pairs(snapshots) do
		markGUIDDirty(guid)
	end
end

local function onDriverEvent(_, event, unit)
	if event == "UNIT_AURA" then
		if tokenGUID[unit] then
			markUnitDirty(unit)
		end
	elseif event == "UNIT_PET" then
		if unit == "player" then
			rebuildCanCure()
		end
		remapTokens()
	elseif event == "SPELLS_CHANGED" or event == "PLAYER_LOGIN" then
		rebuildCanCure()
	elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_TARGET_CHANGED"
		or event == "UNIT_TARGET" or event == "PLAYER_ENTERING_WORLD" then
		remapTokens()
	elseif event == "PLAYER_REGEN_DISABLED" and AuraCache.test.active then
		AuraCache.test.Stop()
	end
end

local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", onDriverUpdate)
driver:RegisterEvent("UNIT_AURA")
driver:RegisterEvent("GROUP_ROSTER_UPDATE")
driver:RegisterEvent("PLAYER_TARGET_CHANGED")
driver:RegisterEvent("UNIT_TARGET")
driver:RegisterEvent("UNIT_PET")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("SPELLS_CHANGED")
driver:RegisterEvent("PLAYER_LOGIN")
driver:SetScript("OnEvent", onDriverEvent)

if LCD and LCD.RegisterCallback then
	LCD.RegisterCallback("LUF_AuraCache", "UNIT_BUFF", function(_, unit)
		if tokenGUID[unit] then
			markUnitDirty(unit)
		end
	end)
end

rebuildCanCure()

-- Multiple Touch calls for the same GUID in one frame share a single rebuild
-- so UNIT_AURA on raid1/raid2/target stays one scan, not three.
local function resolveTouchGUID(unit)
	if AuraCache.test.active then
		if testOpts.useFrameMax and testOpts.activeFrame then
			return "LUFTEST-" .. testOpts.activeFrame
		end
		return "LUFTEST"
	end
	return UnitGUID(unit)
end

function AuraCache:Touch(unit)
	if not unit then
		return EMPTY_SNAP
	end
	if not AuraCache.test.active and not UnitExists(unit) then
		return EMPTY_SNAP
	end
	trackUnit(unit)
	local guid = resolveTouchGUID(unit)
	if not guid then
		return EMPTY_SNAP
	end
	local snap = snapshots[guid]
	local needsRebuild = dirtyGUIDs[guid] or not snap or snap.dirty or snap.generation ~= AuraCache.generation
	if needsRebuild and not rebuiltThisFrame[guid] then
		rebuildSnapshot(guid, unit)
		dirtyGUIDs[guid] = nil
		rebuiltThisFrame[guid] = true
	elseif needsRebuild then
		dirtyGUIDs[guid] = nil
	end
	return snapshots[guid] or EMPTY_SNAP
end

function AuraCache:InvalidateAll()
	for guid, snap in pairs(snapshots) do
		markGUIDDirty(guid)
		snap.dirty = true
	end
end

-- [[ TEST MODE
AuraCache.test = {}

function AuraCache.test.ResetSettings(profile)
	if not profile then return end
	profile.auratest = false
	profile.auratestPerUnit = nil
end

local testTicker = CreateFrame("Frame")
local defaultSpells = {
	1126, 21562, 1243, 7302, 168, 1459, 19740, 1022, 2767, 2096,
	172, 980, 1014, 8050, 589, 702, 2136, 118, 122, 8643,
}
local debuffTypes = { nil, "Magic", "Curse", "Poison", "Disease" }
local testIcons = { 136116, 136243, 135940, 1361168, 135915, 136048, 135753, 136202 }
local TICK_INTERVAL = 0.4
local TEST_ELEMENTS = { "RaidStatusIndicators", "Highlight", "BorderHighlight", "SimpleAuras" }

local function unitSalt(unit)
	local salt = 0
	if unit then
		for i = 1, #unit do
			salt = (salt * 31 + unit:byte(i)) % 100000
		end
	end
	return salt
end

local function isFilter(filter, kind)
	return filter == kind or (type(filter) == "string" and strsub(filter, 1, #kind) == kind)
end

local function rebuildCurableTypes()
	testOpts.curableTypes = {}
	for debuffType in pairs(AuraCache.canCure) do
		testOpts.curableTypes[#testOpts.curableTypes + 1] = debuffType
	end
	table.sort(testOpts.curableTypes)
end

local function getSpellIcon(spellID, iconIndex)
	if spellID and C_Spell.GetSpellTexture then
		local texture = C_Spell.GetSpellTexture(spellID)
		if texture then
			return texture
		end
	end
	return testIcons[(iconIndex % #testIcons) + 1]
end

local function resolveSpellPool(rawPool)
	local resolved = {}
	for i, pick in ipairs(rawPool) do
		if type(pick) == "number" then
			resolved[i] = {
				spellID = pick,
				name = (C_Spell.GetSpellName and C_Spell.GetSpellName(pick)) or ("Spell" .. pick),
				icon = getSpellIcon(pick, i),
			}
		else
			resolved[i] = {
				spellID = 90000 + i,
				name = pick,
				icon = getSpellIcon(nil, i),
			}
		end
	end
	return resolved
end

local function pickDebuffType(unit, index, tick)
	if not testOpts.dispels then
		return nil
	end
	local typeIndex = ((tick + index + unitSalt(unit)) % #debuffTypes) + 1
	local debuffType = debuffTypes[typeIndex]
	local curable = testOpts.curableTypes
	if curable and #curable > 0 and index % 3 == 0 then
		debuffType = curable[((tick + index) % #curable) + 1]
	end
	return debuffType
end

local function harvestSpellPool()
	local pool, seen = {}, {}
	local function add(value)
		value = tonumber(value) or value
		if value and value ~= "" and not seen[value] then
			seen[value] = true
			pool[#pool + 1] = value
		end
	end
	if LUF and LUF.frameIndex then
		for _, frame in pairs(LUF.frameIndex) do
			local element = frame.RaidStatusIndicators
			if element then
				for _, indicator in pairs(element) do
					if type(indicator) == "table" and indicator.nameID then
						for _, spell in ipairs(indicator.nameID) do
							if type(spell) == "table" then
								for _, sub in ipairs(spell) do
									add(sub:gsub("%[mana%]", ""))
								end
							else
								add(spell)
							end
						end
					end
				end
			end
		end
	end
	for _, id in ipairs(defaultSpells) do
		add(id)
	end
	return pool
end

local function getTestMaxAuras(filter)
	if testOpts.useFrameMax and testOpts.activeFrame then
		local auras = _G[testOpts.activeFrame] and _G[testOpts.activeFrame].SimpleAuras
		if auras then
			return isFilter(filter, "HELPFUL") and (auras.maxBuffs or 32) or (auras.maxDebuffs or 40)
		end
	end
	return isFilter(filter, "HELPFUL") and (testOpts.maxBuffs or 32) or (testOpts.maxDebuffs or 40)
end

local function fakeAura(unit, index, filter)
	if isFilter(filter, "HELPFUL") and not testOpts.buffs then return end
	if isFilter(filter, "HARMFUL") and not testOpts.debuffs then return end

	local tick = testOpts.tick or 0
	if index > getTestMaxAuras(filter) then return end

	local pool = testOpts.pool
	if not pool or #pool == 0 then return end

	local salt = unitSalt(unit) + index
	local poolIndex
	if testOpts.refreshAuras then
		poolIndex = ((tick * 7 + index * 3 + salt + tick * 17) % #pool) + 1
	else
		poolIndex = ((index * 3 + salt) % #pool) + 1
	end
	local pick = pool[poolIndex]
	local debuffType = isFilter(filter, "HARMFUL") and pickDebuffType(unit, index, testOpts.refreshAuras and tick or 0) or nil
	local duration, expirationTime, count
	if testOpts.refreshAuras then
		duration = 6 + ((tick + index) % 24)
		expirationTime = (testOpts.now or GetTime()) + duration
		count = 1 + ((tick + index) % 5)
	else
		duration = 300
		expirationTime = (testOpts.baseTime or testOpts.now or GetTime()) + duration - index
		count = 1 + (index % 5)
	end
	return pick.name, pick.icon, count, debuffType, duration, expirationTime, "player", nil, nil, pick.spellID
end

local function refreshFrameElements(frame)
	if not frame:IsVisible() or not frame.unit then return end
	testOpts.activeFrame = frame:GetName()
	for i = 1, #TEST_ELEMENTS do
		local element = frame[TEST_ELEMENTS[i]]
		if element and element.ForceUpdate then
			element.ForceUpdate(element)
		end
	end
	testOpts.activeFrame = nil
end

local function refreshVisibleFrames()
	local objects = ns.oUF and ns.oUF.objects
	if not objects then return end
	for i = 1, #objects do
		refreshFrameElements(objects[i])
	end
end

local function timedRefresh()
	local refreshStart = debugprofilestop()
	refreshVisibleFrames()
	AuraCache.test.refreshMs = debugprofilestop() - refreshStart
	AuraCache.test.refreshAt = debugprofilestop()
end

local function syncProfileActive(active)
	if not LUF or not LUF.db or not LUF.db.profile then return end
	if LUF.db.profile.auratest == active then return end
	LUF.db.profile.auratest = active
	local ACR = LibStub("AceConfigRegistry-3.0", true)
	if ACR then
		ACR:NotifyChange("LunaUnitFrames")
	end
end

local function tickTestMode(_, elapsed)
	testTicker.elapsed = (testTicker.elapsed or 0) + elapsed
	if testTicker.elapsed < TICK_INTERVAL or not AuraCache.test.active then return end
	testTicker.elapsed = 0
	testOpts.tick = (testOpts.tick or 0) + 1
	table.wipe(rebuiltThisFrame)
	AuraCache:InvalidateAll()
	timedRefresh()
end

testTicker:Hide()
testTicker:SetScript("OnUpdate", tickTestMode)

local function syncTestOptsFromProfile()
	local profile = LUF and LUF.db and LUF.db.profile
	if not profile then return false end
	testOpts.buffs = profile.auratestBuffs
	testOpts.debuffs = profile.auratestDebuffs
	testOpts.dispels = profile.auratestDispels
	testOpts.useFrameMax = profile.auratestUseFrameMax
	testOpts.maxBuffs = profile.auratestMaxBuffs or profile.auratestPerUnit or 32
	testOpts.maxDebuffs = profile.auratestMaxDebuffs or profile.auratestPerUnit or 40
	testOpts.refreshAuras = profile.auratestRefreshAuras ~= false
	return true
end

local function setRefreshTicker(enabled)
	if enabled then
		testTicker.elapsed = 0
		testTicker:Show()
	else
		testTicker:Hide()
	end
end

function AuraCache.test.Start()
	if InCombatLockdown() then
		return false
	end
	if not syncTestOptsFromProfile() then
		return false
	end
	if not testOpts.buffs and not testOpts.debuffs and not testOpts.dispels then
		return false
	end
	testOpts.tick = 0
	testOpts.baseTime = GetTime()
	testOpts.pool = resolveSpellPool(harvestSpellPool())
	rebuildCurableTypes()
	auraSource = fakeAura
	AuraCache.test.active = true
	AuraCache:InvalidateAll()
	driver:RegisterEvent("PLAYER_REGEN_DISABLED")
	timedRefresh()
	setRefreshTicker(testOpts.refreshAuras)
	return true
end

function AuraCache.test.Stop()
	if not AuraCache.test.active then return end
	testTicker:Hide()
	auraSource = nil
	AuraCache.test.active = false
	testOpts.tick = 0
	table.wipe(snapshots)
	table.wipe(dirtyGUIDs)
	table.wipe(rebuiltThisFrame)
	driver:UnregisterEvent("PLAYER_REGEN_DISABLED")
	AuraCache.test.refreshAt = nil
	AuraCache.test.refreshMs = nil
	syncProfileActive(false)
	refreshVisibleFrames()
end

function AuraCache.test.IsActive()
	return AuraCache.test.active
end

function AuraCache.test.Refresh()
	if not AuraCache.test.active then return end
	syncTestOptsFromProfile()
	table.wipe(rebuiltThisFrame)
	AuraCache:InvalidateAll()
	timedRefresh()
	setRefreshTicker(testOpts.refreshAuras)
end

local baseUnitAura
do
	local lazyInit = LUF.UnitAura
	lazyInit("player", 1, "HELPFUL")
	baseUnitAura = LUF.UnitAura
end

function LUF.UnitAura(unit, index, filter)
	if auraSource then
		return auraSource(unit, index, filter)
	end
	return baseUnitAura(unit, index, filter)
end

-- TEST MODE ]]
