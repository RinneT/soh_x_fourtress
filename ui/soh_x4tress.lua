-- Load the required libraries
local ffi = require ("ffi")
local C = ffi.C
local Lib = require ("extensions.sn_mod_support_apis.lua_interface").Library
local mapMenu = nil
local origFuncs = {}
local newFuncs = {}
newFuncs.objectHistory = {}

-- Register the functions
local function init ()
    -- DebugError ("soh_x4tress.init")
	RegisterEvent ("X4tress.OnInfoMenuOpen", newFuncs.OnInfoMenuOpen)
	RegisterEvent ("X4tress.OnInfoMenuClose", newFuncs.OnInfoMenuClose)
    newFuncs.player_id = ConvertStringTo64Bit (tostring (C.GetPlayerID ()))
    -- DebugError ("C.GetPlayerID (): " .. tostring (C.GetPlayerID ()))
    mapMenu = Lib.Get_Egosoft_Menu ("MapMenu")
    mapMenu.registerCallback ("createOrdersMenuHeader_on_addorderHeaderRow", newFuncs.createOrdersMenuHeader_on_addorderHeaderRow)
	mapMenu.registerCallback ("createInfoFrame_on_menu_infoTable_info", newFuncs.creteSohHistory)
end

-- Load the history text for the current object when the menu is opened
function newFuncs.OnInfoMenuOpen (_, params)
	-- DebugError ("newFuncs.OnInfoMenuOpen")
	newFuncs.objectHistory = params
end

-- Unload the history text for the current object when the menu is closed
function newFuncs.OnInfoMenuClose ()
	-- DebugError ("newFuncs.OnInfoMenuClose")
	newFuncs.objectHistory = {}
end

-- Create the Menu Button if it does not yet exist
function newFuncs.createOrdersMenuHeader_on_addorderHeaderRow (row, count, instance)
    DebugError("createOrdersMenuHeader_on_addorderHeaderRow")

	-- Following provided by Forleyor
    -- original createButton code
    -- row[count]:createButton({ active = menu.isInfoModeValidFor(menu.infoSubmenuObject, entry.category), height = menu.sideBarWidth, bgColor = bgcolor, mouseOverText = entry.name, scaling = false, helpOverlayID = entry.helpOverlayID, helpOverlayText = entry.helpOverlayText }):setIcon(entry.icon, { color = color})

	-- new createButtonCode
    row[count]:createButton({ active = true, height = mapMenu.sideBarWidth, bgColor = Helper.defaultTitleBackgroundColor, mouseOverText = ReadText (211820, 7), scaling = false, helpOverlayID = "mapst_ao_soh_History", helpOverlayText = ReadText (211820, 7) }):setIcon("ency_timeline_01", { color = color})
    row[count].handlers.onClick = function () return mapMenu.buttonInfoSubMode("soh_history", count, instance) end
end

function newFuncs.creteSohHistory(inputframe, instance)
	local description = newFuncs.objectHistory
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