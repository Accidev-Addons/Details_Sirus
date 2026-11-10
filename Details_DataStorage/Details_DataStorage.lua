DETAILS_STORAGE_VERSION = 6

function _detalhes:CreateStorageDB()
	DetailsDataStorage = {
		VERSION = DETAILS_STORAGE_VERSION,
		[1] = {},
		[2] = {},
		[3] = {},
		[4] = {},
	}
	return DetailsDataStorage
end

local f = CreateFrame ("frame", nil, UIParent)
f:Hide()
f:RegisterEvent ("ADDON_LOADED")

f:SetScript("OnEvent", function (self, event, addonName)
	if addonName == "Details_DataStorage" then
		DetailsDataStorage = DetailsDataStorage or _detalhes:CreateStorageDB()

		if DetailsDataStorage.VERSION < DETAILS_STORAGE_VERSION then
			table.wipe(DetailsDataStorage)
			DetailsDataStorage = _detalhes:CreateStorageDB()
		end

		if _detalhes and _detalhes.debug then
			print ("|cFFFFFF00Details! Storage|r: loaded!")
		end
	end
end)