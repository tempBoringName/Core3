includeFile("junk_dealer/junkDealerData.lua") --Ethan edit. Pulling in junk dealer data
local ObjectManager = require("managers.object.object_manager") -- Ethan edit

----------------------------------------------------
--Ethan Edit 8-9-23: These are necessary for some stuff with the ware purchases

junkDealerScreenplay= ScreenPlay:new {
	errorCodes =  {
		SUCCESS = 0, INVENTORYFULL = 1,  NOTENOUGHCREDITS = 2, GENERALERROR = 3, ITEMCOST = 4, INVENTORYERROR = 5,
		TEMPLATEPATHERROR = 6, GIVEERROR = 7, DATAPADFULL = 8, DATAPADERROR = 9, TOOMANYHIRELINGS = 10, SCHEMATICERROR = 11,
	}
}


--End Ethan edit
----------------------------------------------------

JunkDealer = {
	junkTypes = {
		{"generic", 1},
		{"finery", 2},
		{"arms", 4},
		{"geo", 8},
		{"tusken", 16},
		{"jedi", 32},
		{"jawa", 64},
		{"gungan", 128},
		{"corsec", 256}
	}
}

function JunkDealer:sendSellJunkSelection(pPlayer, pNpc, dealerType, skipItem)
	if pPlayer == nil or pNpc == nil then
		return
	end

	local junkList = self:getEligibleJunk(pPlayer, dealerType, skipItem)

	if #junkList == 0 then
		CreatureObject(pPlayer):sendSystemMessage("@loot_dealer:no_items") -- You have no items that the junk dealer wishes to buy.
		deleteStringData(SceneObject(pPlayer):getObjectID() .. ":junkDealerType")
		return
	end

	local suiManager = LuaSuiManager()
	suiManager:sendListBox(pNpc, pPlayer, "@loot_dealer:sell_title", "@loot_dealer:sell_prompt", 3, "@cancel", "@loot_dealer:btn_sell_all", "@loot_dealer:btn_sell", "JunkDealer", "sellListSuiCallback", 10, junkList)
end

function JunkDealer:getDealerNum(dealerType)
	local dealerNum = 0

	for i = 1, #self.junkTypes, 1 do
		if string.find(dealerType, self.junkTypes[i][1]) ~= nil then
			dealerNum = self.junkTypes[i][2]
		end
	end

	return dealerNum
end

function JunkDealer:getEligibleJunk(pPlayer, dealerType, skipItem)
	local junkList = {}

	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")

	if pInventory == nil then
		return junkList
	end

	local dealerNum = self:getDealerNum(dealerType)

	if dealerNum == 0 then
		return junkList
	end

	for i = 0, SceneObject(pInventory):getContainerObjectsSize() - 1, 1 do
		local pItem = SceneObject(pInventory):getContainerObject(i)

		if pItem ~= nil then
			local tano = TangibleObject(pItem)
			local sceno = SceneObject(pItem)
--6-24-23 Edit: removing the line "and tano:getCraftersName() == "" below...
			if sceno:getObjectID() ~= skipItem then
				if tano:getJunkDealerNeeded() & dealerNum > 0 and not tano:isBroken() and not tano:isSliced() and not tano:isNoTrade() and sceno:getContainerObjectsSize() == 0 then
					local name = sceno:getDisplayedName()
					local value = tano:getJunkValue()
					local textTable = {"[" .. value .. "] " .. name, sceno:getObjectID()}
					table.insert(junkList, textTable)
				end
			end
		end
	end

	return junkList
end

function JunkDealer:sellListSuiCallback(pPlayer, pSui, eventIndex, otherPressed, rowIndex)
	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")

	if pInventory == nil or eventIndex == 1 then
		deleteStringData(SceneObject(pPlayer):getObjectID() .. ":junkDealerType")
		return
	end

	if (otherPressed == "true") then
		self:sellAllItems(pPlayer, pSui, pInventory)
	else
		rowIndex = tonumber(rowIndex)

		if (rowIndex == -1) then
			deleteStringData(SceneObject(pPlayer):getObjectID() .. ":junkDealerType")
			return
		end

		self:sellItem(pPlayer, pSui, rowIndex, pInventory)
	end
end

function JunkDealer:sellAllItems(pPlayer, pSui, pInventory)
	deleteStringData(SceneObject(pPlayer):getObjectID() .. ":junkDealerType")
	local listBox = LuaSuiListBox(pSui)
	local pNpc = listBox:getUsingObject()

	if pNpc == nil then
		return
	end

	local name = SceneObject(pNpc):getDisplayedName()
	local amount = 0

	for i = 0, listBox:getMenuSize() - 1, 1 do
		local oid = listBox:getMenuObjectID(i)
		local pItem = SceneObject(pInventory):getContainerObjectById(oid)

		if pItem ~= nil then
			local value = TangibleObject(pItem):getJunkValue()
			createEvent(10, "JunkDealer", "destroyItem", pItem, "")

			amount = amount + value
		end
	end

	CreatureObject(pPlayer):addCashCredits(amount, true)

	local messageString = LuaStringIdChatParameter("@loot_dealer:prose_sold_all_junk") -- You sell all of your loot to %TT for %DI credits
	messageString:setTT(name)
	messageString:setDI(amount)
	CreatureObject(pPlayer):sendSystemMessage(messageString:_getObject())
end

function JunkDealer:destroyItem(pItem)
	if (pItem == nil) then
		return
	end

	SceneObject(pItem):destroyObjectFromWorld()
	SceneObject(pItem):destroyObjectFromDatabase()
end

function JunkDealer:sellItem(pPlayer, pSui, rowIndex, pInventory)
	local listBox = LuaSuiListBox(pSui)
	local pNpc = listBox:getUsingObject()
	local oid = listBox:getMenuObjectID(rowIndex)
	local pItem = SceneObject(pInventory):getContainerObjectById(oid)

	if pItem == nil or pNpc == nil then
		deleteStringData(SceneObject(pPlayer):getObjectID() .. ":junkDealerType")
		return
	end

	local item = SceneObject(pItem)
	local skipItem = item:getObjectID()
	local name = item:getDisplayedName()
	local value = TangibleObject(pItem):getJunkValue()

	createEvent(10, "JunkDealer", "destroyItem", pItem, "")

	CreatureObject(pPlayer):addCashCredits(value, true)

	local messageString = LuaStringIdChatParameter("@loot_dealer:prose_sold_junk") -- You sell %TT for %DI credits.
	messageString:setTT(name)
	messageString:setDI(value)
	CreatureObject(pPlayer):sendSystemMessage(messageString:_getObject())

	local dealerType = readStringData(SceneObject(pPlayer):getObjectID() .. ":junkDealerType")
	self:sendSellJunkSelection(pPlayer, pNpc, dealerType, skipItem)
end

--Ethan Edits 8/10/23: Cloned from recruiterScreenplay.lua:

function JunkDealer:sendPurchaseSui(pNpc, pPlayer, screenID)
	if (pNpc == nil or pPlayer == nil) then
		return
	end

	local dealerType = readStringData(SceneObject(pPlayer):getObjectID() .. ":junkDealerType")

	writeStringData(CreatureObject(pPlayer):getObjectID() .. ":junk_wares_purchase", screenID)
	local suiManager = LuaSuiManager()
	local options = { }
	if screenID == "wares_weapons" then
		options = self:getWeaponsOptions(dealerType)
	elseif screenID == "wares_armor" then
		options = self:getArmorOptions(dealerType)
	elseif screenID == "wares_hirelings" then
		options = self:getHirelingsOptions(dealerType)
	end

	suiManager:sendListBox(pNpc, pPlayer, "junk_wares_purchase", "Purchase Wares", 2, "@cancel", "", "@ok", "junkDealerScreenplay", "handleSuiPurchase", 32, options)
end


-------------------------------------
--Various data table pulling functions
--Ethan Edit 8/9/23:
function JunkDealer:getWaresDataTable(dealerType)
	
	return genericJunkData --TESTING. Below is broken!
	--if (dealerType == "generic") then
	--	return genericJunkData
	--elseif (dealerType == "arms") then
	--	return armsJunkData
	--else
	--	return nil
	--end
end
--End Ethan edit

--Various functions for various item type options
--Ethan Edits 8/10/23: Cloned from recruiterScreenplay.lua, function to list the weapon items in the SUI box
function JunkDealer:getWeaponsOptions(dealerType)
	local optionsTable = { }
	local junkWaresData = self:getWaresDataTable(dealerType)
	for k,v in pairs(junkWaresData.junkWeaponsList) do
		if ( junkWaresData.junkWeapons[v] ~= nil and junkWaresData.junkWeapons[v].display ~= nil and junkWaresData.junkWeapons[v].cost ~= nil ) then
			local option = {self:generateSuiString(junkWaresData.junkWeapons[v].display, math.ceil(junkWaresData.junkWeapons[v].cost)), 0}
			table.insert(optionsTable, option)
		end
	end
	return optionsTable
end
--End Ethan edits

function JunkDealer:getArmorOptions(dealerType)
	local optionsTable = { }
	local junkWaresData = self:getWaresDataTable(dealerType)
	for k,v in pairs(junkWaresData.junkArmorList) do
		if ( junkWaresData.junkArmor[v] ~= nil and junkWaresData.junkArmor[v].display ~= nil and junkWaresData.junkArmor[v].cost ~= nil ) then
			local option = {self:generateSuiString(junkWaresData.junkArmor[v].display, math.ceil(junkWaresData.junkArmor[v].cost)), 0}
			table.insert(optionsTable, option)
		end
	end
	return optionsTable
end


function JunkDealer:getHirelingsOptions(dealerType)
	local optionsTable = { }
	local junkWaresData = self:getWaresDataTable(dealerType)
	for k,v in pairs(junkWaresData.hirelingsList) do
		if ( junkWaresData.hirelings[v] ~= nil and junkWaresData.hirelings[v].display ~= nil and junkWaresData.hirelings[v].cost ~= nil ) then
			local option = {self:generateSuiString(junkWaresData.hirelings[v].display, math.ceil(junkWaresData.hirelings[v].cost)), 0}
			table.insert(optionsTable, option)
		end
	end
	return optionsTable
end

-------------------------------------



--Ethan Edit 8/10/23: Stolen from recruiterScreenplay.lua
function JunkDealer:generateSuiString(item, cost)
	return getStringId(item) .. " (Cost: " .. cost .. ")"
end
--End Ethan edit

--Ethan Edit 8/10/23: Stolen from recruiterScreenplay.lua
function JunkDealer:getItemCost(dealerType, itemString)
	local junkWaresData = self:getWaresDataTable(dealerType)
	if self:isWeapon(dealerType, itemString)  and junkWaresData.junkWeapons[itemString] ~= nil then
		return junkWaresData.junkWeapons[itemString].cost
	elseif self:isArmor(dealerType, itemString) and junkWaresData.junkArmor[itemString].cost ~= nil then
		return junkWaresData.junkArmor[itemString].cost
	--NOTE: Will need to add other item types in here
	end
	return nil
end
--End Ethan edit

-------------------------------------
--Various functions depending on the type of ware item:

--NOTE: Will need to add other item types in here
--Ethan edit 8/10/23 JESUS CHRIST WHY ARE THERE SO MANY FUCKING FUNCTIONS FOR SOMETHING SO SIMPLE
function JunkDealer:isWeapon(dealerType, strItem)
	local junkWaresData = self:getWaresDataTable(dealerType)
	return junkWaresData.junkWeapons[strItem] ~= nil and junkWareType.junkWeapons[strItem].type == junkWareType.weapon
end
--End Ethan edit

--Ethan edit 8/10/23 JESUS CHRIST WHY ARE THERE SO MANY FUCKING FUNCTIONS FOR SOMETHING SO SIMPLE
function JunkDealer:isArmor(dealerType, strItem)
	local junkWaresData = self:getWaresDataTable(dealerType)
	return junkWaresData.junkArmor[strItem] ~= nil and junkWareType.junkArmor[strItem].type == junkWareType.armor
end
--End Ethan edit

function JunkDealer:isHireling(dealerType, strItem)
	local junkWaresData = self:getWaresDataTable(dealerType)
	return junkWaresData.hirelings[strItem] ~= nil
end



-------------------------------------
--ITEM TRANSFER FUNCTIONS:

--Ethan Edit 8/10/23: Stolen from recruiterScreenplay.lua, long function that is called within the purchaseSUI thingie

function JunkDealer:awardItem(pPlayer, dealerType, itemString)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return self.errorCodes.INVENTORYERROR
	end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")

	if (pInventory == nil) then
		return self.errorCodes.INVENTORYERROR
	end

	local playerCash = CreatureObject(pPlayer):getCashCredits()
	local itemCost = self:getItemCost(dealerType, itemString)

	if itemCost == nil then
		return self.errorCodes.ITEMCOST
	end

	itemCost = math.ceil(itemCost)

	if (playerCash < itemCost) then
		return self.errorCodes.NOTENOUGHCREDITS
	end

	local slotsremaining = SceneObject(pInventory):getContainerVolumeLimit() - SceneObject(pInventory):getCountableObjectsRecursive()

	if (slotsremaining < 1) then
		return self.errorCodes.INVENTORYFULL
	end

	--Note: Need to add "transferItem" function... UGH
	local transferResult =  self:transferItem(pPlayer, pInventory, dealerType, itemString)

	if (transferResult ~= self.errorCodes.SUCCESS) then
		return transferResult
	end
	--Need to change to credits
	CreatureObject(pPlayer):subtractCashCredits(cost)

	local messageString = LuaStringIdChatParameter("Your purchase of %TT is complete") -- Your requisition of %TT is complete.
	messageString:setTT(self:getDisplayName(dealerType, itemString))
	CreatureObject(pPlayer):sendSystemMessage(messageString:_getObject())

	return self.errorCodes.SUCCESS
end
--End Ethan edit

--Ethan edit 8/10/23: Stolen from recruiterScreenplay.lua, transfers simple items (weapon, furniture, etc., NOT datapad items) to the player
function JunkDealer:transferItem(pPlayer, pInventory, dealerType, itemString)
	local templatePath = self:getTemplatePath(dealerType, itemString)

	if templatePath == nil then
		return self.errorCodes.TEMPLATEPATHERROR
	end

	local pItem = giveItem(pInventory, templatePath, -1)

	if (pItem == nil) then
		return self.errorCodes.GIVEERROR
	end

	if (self:isInstallation(dealerType, itemString)) then
		SceneObject(pItem):setObjectName("deed", itemString, true)
		local deed = LuaDeed(pItem)
		local genPath = self:getGeneratedObjectTemplate(dealerType, itemString)

		if genPath == nil then
			return self.errorCodes.TEMPLATEPATHERROR
		end

		deed:setGeneratedObjectTemplate(genPath)
	end

	return self.errorCodes.SUCCESS
end
--End Ethan edit

--Function stolen from recruiterScreenplay.lua, transfers datapad items (like hirelings) to the player
function JunkDealer:transferData(pPlayer, pDatapad, dealerType, itemString)
	local pItem
	local templatePath = self:getTemplatePath(dealerType, itemString)

	if templatePath == nil then
		return self.errorCodes.TEMPLATEPATHERROR
	end

	local genPath = self:getControlledObjectTemplate(dealerType, itemString)

	if genPath == nil then
		return self.errorCodes.TEMPLATEPATHERROR
	end

	if (self:isHireling(dealerType, itemString)) then
		if (checkTooManyHirelings(pDatapad)) then
			return self.errorCodes.TOOMANYHIRELINGS
		end

		pItem = giveControlDevice(pDatapad, templatePath, genPath, -1, true)
	else
		pItem = giveControlDevice(pDatapad, templatePath, genPath, -1, false)
	end

	if pItem ~= nil then
		SceneObject(pItem):sendTo(pPlayer)
	else
		return self.errorCodes.GIVEERROR
	end

	return self.errorCodes.SUCCESS
end


-----------------------------
--Ethan edit 8/10/23: Okay, the big daddy function that handles everything...

function JunkDealer:handleSuiPurchase(pCreature, pSui, eventIndex, arg0)
	local cancelPressed = (eventIndex == 1)

	if pCreature == nil then
		return
	end

	if cancelPressed then
		deleteStringData(CreatureObject(pCreature):getObjectID() .. ":junk_wares_purchase")
		return
	end

	local playerID = SceneObject(pCreature):getObjectID()
	local purchaseCategory = readStringData(playerID .. ":junk_wares_purchase")

	if purchaseCategory == "" then
		return
	end

	local purchaseIndex = arg0 + 1
	local dealerType = readStringData(SceneObject(pPlayer):getObjectID() .. ":junkDealerType")
	local junkWaresData = self:getWaresDataTable(dealerType)
	--NOTE: I don't know wtf purchaseCategory is...
	local itemListTable = self:getItemListTable(dealerType, purchaseCategory)
	local itemString = itemListTable[purchaseIndex]
	deleteStringData(playerID .. ":junk_wares_purchase")

	local awardResult = nil

	if (self:isHireling(dealerType, itemString)) then
		awardResult = self:awardData(pCreature, dealerType, itemString)
	elseif (self:isSchematic(dealerType, itemString)) then
		awardResult = self:awardSchematic(pCreature, dealerType, itemString)
	else
		awardResult = self:awardItem(pCreature, dealerType, itemString)
	end

	if (awardResult == self.errorCodes.SUCCESS) then
		return
	elseif (awardResult == self.errorCodes.INVENTORYFULL) then
		CreatureObject(pCreature):sendSystemMessage("Your inventory is full. You must make some room before you can purchase.") -- Your inventory is full. You must make some room before you can purchase.
	elseif (awardResult == self.errorCodes.DATAPADFULL) then
		CreatureObject(pCreature):sendSystemMessage("Your datapad is full. You must first free some space.") -- Your datapad is full. You must first free some space.
	elseif (awardResult == self.errorCodes.TOOMANYHIRELINGS) then
		CreatureObject(pCreature):sendSystemMessage("You already have too much under your command.") -- You already have too much under your command.
	elseif (awardResult == self.errorCodes.NOTENOUGHCREDITS) then
		CreatureObject(pCreature):sendSystemMessage("Don't have enough cash credits to complete this purchase.") -- You already have too much under your command.
	elseif (awardResult == self.errorCodes.ITEMCOST) then
		CreatureObject(pCreature):sendSystemMessage("Error determining cost of item. Please post a bug report regarding the item you attempted to purchase.")
	elseif (awardResult == self.errorCodes.INVENTORYERROR or awardResult == self.DATAPADERROR) then
		CreatureObject(pCreature):sendSystemMessage("Error finding location to put item. Please post a report.")
	elseif (awardResult == self.errorCodes.TEMPLATEPATHERROR) then
		CreatureObject(pCreature):sendSystemMessage("Error determining data for item. Please post a bug report regarding the item you attempted to purchase..")
	elseif (awardResult == self.errorCodes.SCHEMATICERROR) then
		CreatureObject(pCreature):sendSystemMessage("@loot_schematic:already_have_schematic")
	end
end

---------------------------
--Ethan edit 8/10/23 : OMFG IT NEVER ENDS

function JunkDealer:getItemListTable(dealerType, screenID)
	local junkWaresData = self:getWaresDataTable(dealerType)
	if screenID == "wares_weapons" then
		return junkWaresData.junkWeaponsList
	elseif screenID == "wares_armor" then
		return junkWaresData.junkArmorList
	elseif screenID == "wares_hirelings" then
		return junkWaresData.hirelingList
	end
end

---------------------------

--Ethan Edit: These are some fucking redos based on the event promoter code...

function JunkDealer:getPerkTable(category)
	
	local junkWaresData = self:getWaresDataTable(dealerType)
	if category == "wares_weapons" then
		return selfjunkWaresData.junkWeapons
	elseif category == "wares_armor" then
		return junkWaresData.junkArmor
	elseif category == "sale_rebel_decorations" then
		return junkWaresData.hirelings
	end
end

-------------------------


return JunkDealer
