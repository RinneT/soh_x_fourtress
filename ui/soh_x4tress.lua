-- Load the required libraries
local ffi = require ("ffi")
local C = ffi.C
local Lib = require ("extensions.sn_mod_support_apis.lua_interface").Library
local mapMenu = {
	name = "TimelineMenu",
	dateFormat = "nt",
	encyclopediaMode = "timeline",
}
local origFuncs = {}
local newFuncs = {}
--newFuncs.objectHistory = {}
newFuncs.objectHistory = {{headline = "This is the first headline",text = "This is a\ntest text initialized", date = 819.0},
							{headline = "This is the second headline",text = "This is another text", date = 820.0}}

local config = {
	leftBar = {
		[1] = { name = ReadText(1001, 2400),	icon = "tlt_encyclopedia",	mode = "encyclopedia" },
		[2] = { name = ReadText(1001, 8201),	icon = "ency_timeline_01",	mode = "timeline" },
		[3] = { name = ReadText(1001, 3700),	icon = "ency_ship_comparison_01",	mode = "shipcomparison" },
	},
	dateFormats = {
		{ id = "nt", text = ReadText(1001, 8203), mouseovertext = ReadText(1001, 8208), icon = "", displayremoveoption = false },
		{ id = "zt", text = ReadText(1001, 8205), mouseovertext = ReadText(1001, 8210), icon = "", displayremoveoption = false },
		{ id = "ad", text = ReadText(1001, 8204), mouseovertext = ReadText(1001, 8209), icon = "", displayremoveoption = false },
		{ id = "he", text = ReadText(1001, 8207), mouseovertext = ReadText(1001, 8211), icon = "", displayremoveoption = false },
	},
	gapHeight = Helper.standardTextHeight * 1.5,
	minDescriptionRows = 4,
}

-- Register the functions
local function init ()
    -- DebugError ("soh_x4tress.init")
	RegisterEvent ("X4tress.OnInfoMenuOpen", newFuncs.OnInfoMenuOpen)
	RegisterEvent ("X4tress.OnInfoMenuClose", newFuncs.OnInfoMenuClose)
    newFuncs.player_id = ConvertStringTo64Bit (tostring (C.GetPlayerID ()))
    -- DebugError ("C.GetPlayerID (): " .. tostring (C.GetPlayerID ()))
    mapMenu = Lib.Get_Egosoft_Menu ("MapMenu")
    mapMenu.registerCallback ("createOrdersMenuHeader_on_addorderHeaderRow", newFuncs.createOrdersMenuHeader_on_addorderHeaderRow)
	mapMenu.registerCallback ("createInfoFrame_on_menu_infoTable_info", newFuncs.createSohHistory)
end

-- Load the history text for the current object when the menu is opened
function newFuncs.OnInfoMenuOpen (_, params)
	DebugError ("Entering newFuncs.OnInfoMenuOpen")
	newFuncs.objectHistory = params
end

-- Unload the history text for the current object when the menu is closed
function newFuncs.OnInfoMenuClose ()
	DebugError ("Entering newFuncs.OnInfoMenuClose")
	--newFuncs.objectHistory = {}
end

-- Create the Menu Button if it does not yet exist
function newFuncs.createOrdersMenuHeader_on_addorderHeaderRow (row, count, instance)
    DebugError("Entering createOrdersMenuHeader_on_addorderHeaderRow")

	-- Following provided by Forleyor
    -- original createButton code
    -- row[count]:createButton({ active = menu.isInfoModeValidFor(menu.infoSubmenuObject, entry.category), height = menu.sideBarWidth, bgColor = bgcolor, mouseOverText = entry.name, scaling = false, helpOverlayID = entry.helpOverlayID, helpOverlayText = entry.helpOverlayText }):setIcon(entry.icon, { color = color})

	-- new createButtonCode
    row[count]:createButton({ active = true, height = mapMenu.sideBarWidth, bgColor = Helper.defaultTitleBackgroundColor, mouseOverText = ReadText (211820, 7), scaling = false, helpOverlayID = "mapst_ao_soh_History", helpOverlayText = ReadText (211820, 7) }):setIcon("ency_timeline_01", { color = color})
    row[count].handlers.onClick = function () return mapMenu.buttonInfoSubMode("soh_history", count, instance) end
end

-- Most of it is taken from menu_timeline.lua function menu.createTimelineTable(frame)
-- TODO: Add Map menu
-- TODO: Add scroll bar
-- TODO: fix dates not being shown
-- TODO: fix linesize
-- TODO: Only show History when tab is actually selected
function newFuncs.createSohHistory(inputframe, instance)
	DebugError("Entering createSohHistory")
	-- Render the Menu header
	local table_header = mapMenu.createOrdersMenuHeader(inputframe, instance)

	local tableEntries = newFuncs.objectHistory

	-- Init some values
	mapMenu.sidebarWidth = Helper.scaleX(Helper.sidebarWidth)
	mapMenu.topLevelOffsetY = Helper.createTopLevelTab(mapMenu, "map", inputframe, "", nil, true)
	-- the y coordiante of the line connecting all dots
	local lineoffsetY = 0

	-- Initialize the table
	DebugError("createSohHistory: Creating table")
	local ftable = inputframe:addTable(3, { 
		tabOrder = 1
		--width = 0.3 * Helper.viewWidth,
		--x = Helper.frameBorder + mapMenu.sidebarWidth + Helper.borderSize,
		--y = mapMenu.topLevelOffsetY + Helper.borderSize,
		--maxVisibleHeight = Helper.viewHeight - mapMenu.topLevelOffsetY - Helper.borderSize - Helper.frameBorder,
	})

	ftable:setColWidth(1, Helper.standardTextHeight)
	ftable:setColWidthPercent(2, 15)


	-- Add the Dropdown selection for the date format
	-- Assemble the dropdown selection
	DebugError("createSohHistory: Adding Dropdown")
	local row = ftable:addRow(true, { fixed = true, bgColor = Helper.color.transparent })
	local format = ""
	for _, entry in ipairs(config.dateFormats) do
		if entry.id == mapMenu.dateFormat then
			format = entry.text
		end
	end

	-- Add the dropdowns
	row[1]:setColSpan(2):createDropDown(config.dateFormats, {startOption = mapMenu.dateFormat, height = Helper.standardTextHeight, textOverride = ReadText(1001, 8206) .. " (" .. format .. ")" }):setTextProperties({ font = Helper.standardFontBold })
	row[1].handlers.onDropDownConfirmed = newFuncs.dropdownDate
	row[3]:createText(ReadText(1001, 8202), { font = Helper.standardFontBold })
	--lineoffsetY = lineoffsetY + row:getHeight() + Helper.borderSize

	-- Add the table
	DebugError("createSohHistory: Adding entries")
	local tmpDate = 100.0
	for _, entry in ipairs(tableEntries) do
		-- The event headline contains the dot and the date
		local hRow = ftable:addRow(entry, { bgColor = Helper.color.transparent })
		hRow[1]:createIcon("ency_timeline_dot_01", { width = Helper.standardTextHeight, height = Helper.standardTextHeight })
		hRow[2]:createText(newFuncs.convertDate(tmpDate), { halign = "right", font = Helper.standardFontBold })
		--DebugError("createSohHistory: tmpDate is:" .. tostring(tmpDate) .. " converted: " .. tostring(newFuncs.convertDate(tmpDate)))
		hRow[3]:createText(entry.headline, { wordwrap = true, font = Helper.standardFontBold })
		-- The event text contains the line and the text
		local tRow = ftable:addRow(entry, { bgColor = Helper.color.transparent })
		tRow[3]:createText(entry.text, { wordwrap = true, font = Helper.standardFont })
	end

	DebugError("createSohHistory: Drawing line")
	-- Draw the vertical line connecting all the dots
	local linethickness = Helper.scaleX(2)
	if linethickness % 2 == 0 then
		linethickness = linethickness - 1
	end
	DebugError("Linethickness: "..tostring(linethickness))
	local lineoffsetX = (Helper.scaleX(Helper.standardTextHeight) / 2) + Helper.frameBorder + mapMenu.sidebarWidth + ( Helper.borderSize * 2)
	local tabPosY = mapMenu.topLevelOffsetY + Helper.borderSize
	--local lineend = tabPosY + ftable.properties.maxVisibleHeight
	local lineend = tabPosY + ftable.properties.maxVisibleHeight + Helper.viewHeight - mapMenu.topLevelOffsetY - Helper.borderSize - Helper.frameBorder
	Helper.drawLine( { x = lineoffsetX, y = tabPosY + lineoffsetY }, { x = lineoffsetX, y = lineend }, linethickness, nil, Helper.color.white, true )

	DebugError("createSohHistory: Reached end")
end

-- copied and adapted from menu_timeline.lua 
function newFuncs.convertDate(date)
	local year = math.modf(date)
	if mapMenu.dateFormat == "nt" then
		return year
	elseif mapMenu.dateFormat == "ad" then
		return year + 2170
	elseif mapMenu.dateFormat == "he" then
		return year + 12170
	elseif mapMenu.dateFormat == "zt" then
		return year - 200 --math.floor((year - 750) * 1.36 + 550) -- 750nt == 550zt
	end
end

-- copied and adapted from menu_timeline.lua 
function newFuncs.dropdownDate(_, newid)
	if newid ~= mapMenu.dateFormat then
		mapMenu.dateFormat = newid
		mapMenu.refresh = true
	end
end

-- Deprecated
function newFuncs.createSohHistory_Old(inputframe, instance)
	local description = newFuncs.objectHistory

	-- addTable(NumberOfRows, {tabOrder = 1, highlightMode = "off"})
	-- NumberOfColumns:
	-- tabOrder: Has to be unique in the view. Defines the order in which you tab through objects in a view with the Tab key
	-- highlightMode:

    local table_description = inputframe:addTable(1, { tabOrder = 3, highlightMode = "off" })
	row = table_description:addRow(false, { fixed = true, bgColor = Helper.defaultTitleBackgroundColor })
    -- Heading
	row[1]:createText(ReadText(1001, 2404), Helper.headerRowCenteredProperties)

	local descriptiontext = GetTextLines(description, Helper.standardFont, Helper.scaleFont(Helper.standardFont, Helper.standardFontSize), inputframe.properties.width - 2 * Helper.scaleX(Helper.standardTextOffsetx))
	if descriptiontext ~=nil then
		if #descriptiontext > 14 then
			-- scrollbar case
			descriptiontext = GetTextLines(description, Helper.standardFont, Helper.scaleFont(Helper.standardFont, Helper.standardFontSize), inputframe.properties.width - 2 * Helper.scaleX(Helper.standardTextOffsetx) - Helper.scrollbarWidth)
		end
		for linenum, descline in ipairs(descriptiontext) do
			local row = table_description:addRow(true, { bgColor = Helper.color.transparent })
			row[1]:createText(descline)
			if linenum == 14 then
				visibleHeight = table_description:getFullHeight()
			end
		end
	end

	if mapMenu.selectedRows["infotable3" .. instance] then
		table_description:setSelectedRow(mapMenu.selectedRows["infotable3" .. instance])
		mapMenu.selectedRows["infotable3" .. instance] = nil
		if mapMenu.topRows["infotable3" .. instance] then
			table_description:setTopRow(mapMenu.topRows["infotable3" .. instance])
			mapMenu.topRows["infotable3" .. instance] = nil
		end
	end

	if visibleHeight then
		table_description.properties.maxVisibleHeight = visibleHeight
	else
		table_description.properties.maxVisibleHeight = table_description:getFullHeight()
	end

	local table_header = mapMenu.createOrdersMenuHeader(inputframe, instance)

	table_description.properties.y = table_description:getVisibleHeight() - Helper.borderSize

	table_header:addConnection(1, (instance == "left") and 2 or 3, true)
	table_description:addConnection(3, (instance == "left") and 2 or 3)
	
end

-- Calls the init function of this script
init ()