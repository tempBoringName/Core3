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

------------------------------Ethan Edits 8/13/23: Cloned from eventPromoter.lua screenplay


function JunkDealer:sendSaleSui(pNpc, pPlayer, screenID)
	
	printf("calling sendSaleSui and screenID is: ")
	printf(screenID)
	printf("\n")
	
	if (pPlayer == nil or pNpc == nil) then
		return
	end


	writeStringData(CreatureObject(pPlayer):getObjectID() .. ":junk_dealer_purchase", screenID)
	local suiManager = LuaSuiManager()
	local perkData = self:getPerkTable(screenID)

	local options = { }
	for i = 1, #perkData, 1 do
		local perk = {getStringId(perkData[i].displayName) .. " (Cost: " .. perkData[i].cost .. ")", 0}
		table.insert(options, perk)
	end

	suiManager:sendListBox(pNpc, pPlayer, "@event_perk:pro_show_list_title", "@event_perk:pro_show_list_desc", 2, "@cancel", "", "@ok", "JunkDealer", "handleSuiPurchase", 32, options)
end

function JunkDealer:getPerkTable(category)
	
	printf("calling getPerkTable and category is: ")
	printf(category)
	printf("\n")

	if category == "wares_weapon" then
		return genericJunkData.junkWeapon
	elseif category == "wares_armor" then
		return genericJunkData.junkArmor
	elseif category == "wares_hireling" then
		return genericJunkData.junkHireling
	end
end

function JunkDealer:handleSuiPurchase(pPlayer, pSui, eventIndex, arg0)
	local cancelPressed = (eventIndex == 1)

	if (pPlayer == nil) then
		return
	end

	if (cancelPressed) then
		deleteStringData(CreatureObject(pPlayer):getObjectID() .. ":junk_dealer_purchase")
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local purchaseCategory = readStringData(playerID .. ":junk_dealer_purchase")
	local purchaseIndex = arg0 + 1
	local perkData = self:getPerkTable(purchaseCategory)

	printf("purchseCategory is: ")
	printf(purchaseCategory)
	printf("\n")


	
	if (perkData == nil or purchaseIndex < 1 or purchaseIndex > #perkData) then
		return
	end

	if(purchaseCategory == "wares_weapon" or purchaseCategory == "wares_armor") then
		local deedData = perkData[purchaseIndex]
		deleteStringData(playerID .. ":junk_dealer_purchase")
		self:giveItem(pPlayer, deedData)
	end
	--PROBABLY BROKEN FUCKERY HERE:
	if(purchaseCategory == "wares_hireling") then
		local hirelingItem = perkData[purchaseIndex]
		local hirelingTemplatePath = hirelingItem.template
		local hirelingDisplayName = hirelingItem.displayName
		local pDatapad = SceneObject(pPlayer):getSlottedObject("datapad")
		deleteStringData(playerID .. ":junk_dealer_purchase")
		self:awardHireling(pPlayer,pDatapad,hirelingItem)
	end
	
end

--PROBABLY A BROKEN ASS FUNCTION
function JunkDealer:awardHireling(pPlayer, pDatapad, hirelingItem)
	
	local templatePath = hirelingItem.template
	local displayName = hirelingItem.displayName
	local cost = hirelingItem.cost
	
	printf("doing transfer data now\n")
	printf("template path: ")
	printf(templatePath)
	printf("\n")
	printf("display name: ")
	printf(displayName)
	printf("\n")
	
	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")


	if (checkTooManyHirelings(pDatapad)) then
		return self.errorCodes.TOOMANYHIRELINGS
	end

	if (CreatureObject(pPlayer):getCashCredits() < cost) then
		CreatureObject(pPlayer):sendSystemMessage("@dispenser:insufficient_funds")
		return
	end

	CreatureObject(pPlayer):subtractCashCredits(cost)

	local messageString = LuaStringIdChatParameter("You purchase %TT for %DI credits.") -- You sell %TT for %DI credits.
	messageString:setTT(displayName)
	messageString:setDI(cost)
	CreatureObject(pPlayer):sendSystemMessage(messageString:_getObject())


	local pItem
	pItem = giveControlDevice(pDatapad, "object/intangible/pet/pet_control.iff", templatePath, -1, true)
	SceneObject(pItem):sendTo(pPlayer)

	printf("giving control device:")
	printf("\n")


	return
end

function JunkDealer:giveItem(pPlayer, deedData)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")

	if (pInventory == nil) then
		return
	end

	if (CreatureObject(pPlayer):getCashCredits() < deedData.cost) then
		CreatureObject(pPlayer):sendSystemMessage("@dispenser:insufficient_funds")
		return
	elseif (SceneObject(pInventory):isContainerFullRecursive()) then
		CreatureObject(pPlayer):sendSystemMessage("@event_perk:promoter_full_inv")
		return
	end

	CreatureObject(pPlayer):subtractCashCredits(deedData.cost)

	local messageString = LuaStringIdChatParameter("You purchase %TT for %DI credits.")
	messageString:setTT(deedData.displayName)
	messageString:setDI(cost)
	CreatureObject(pPlayer):sendSystemMessage(messageString:_getObject())


	local templatePath

	templatePath = deedData.template

	local pItem = giveItem(pInventory, templatePath, -1)

	if (pItem ~= nil) then
		PlayerObject(pGhost):addEventPerk(pItem)
	end
end



------------------------- END ETHAN EDIT


return JunkDealer
