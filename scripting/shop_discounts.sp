#pragma semicolon 1

#include <sourcemod>
#include <shop>

public Plugin myinfo =
{
	name = "[SHOP] Discounts",
	author = "PISEX",
	version = "1.0.0",
	url = "Discord => Pisex#0023"
};

int g_iDiscount;
char g_sEItems[1024],
	g_sECategories[1024],
	g_sItems[1024],
	g_sCategories[1024];

public void OnMapStart()
{
	g_iDiscount 	 = 0;
	g_sEItems[0] 	 = 0;
	g_sECategories[0] = 0;
	g_sItems[0] 	 = 0;
	g_sCategories[0] = 0;
	char szBuffer[PLATFORM_MAX_PATH];
	KeyValues KV = new KeyValues("Discounts");
	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "configs/shop/discounts.ini");
	if(!KV.ImportFromFile(szBuffer))
		LogError("Файл конфигураций не найден. \"configs/shop/discounts.ini\"");
	else
	{
		char convert_Date[16], szDate[64];
		KV.Rewind();
		FormatTime(szBuffer, sizeof(szBuffer), "%Y.%m.%d", GetTime());
		strcopy(convert_Date, sizeof(convert_Date), szBuffer);
		ReplaceString(convert_Date, sizeof(convert_Date), ".", "", false);
		int iDateServer = StringToInt(convert_Date);
		if(KV.GotoFirstSubKey(false))
		{
			do 
			{
				if(KV.GetSectionName(szDate, sizeof(szDate)))
				{
					if(StrEqual(szDate, szBuffer, true))
					{
						g_iDiscount = KV.GetNum("size");
						KV.GetString("Items",g_sItems,sizeof g_sItems);
						KV.GetString("Categories",g_sCategories,sizeof g_sCategories);
						if(!g_sItems[0] || !g_sCategories[0])
						{
							KV.GetString("Exception_Items",g_sEItems,sizeof g_sEItems);
							KV.GetString("Exception_Categories",g_sECategories,sizeof g_sECategories);
						}
						break;
					}
					else
					{
						if(StrContains(szDate, "-", true) > -1)
						{
							char sDate[2][16];
							ExplodeString(szDate, "-", sDate, sizeof sDate, sizeof(sDate[]), false);
							ReplaceString(sDate[0], sizeof(sDate[]), ".", "", false);
							ReplaceString(sDate[1], sizeof(sDate[]), ".", "", false);
							if(StringToInt(sDate[0]) < StringToInt(sDate[1]))
							{
								if(StringToInt(sDate[0]) <= iDateServer <= StringToInt(sDate[1]))
								{
									g_iDiscount = KV.GetNum("size");
									KV.GetString("Items",g_sItems,sizeof g_sItems);
									KV.GetString("Categories",g_sCategories,sizeof g_sCategories);if(!g_sItems[0] || !g_sCategories[0])
									if(!g_sItems[0] || !g_sCategories[0])
									{
										KV.GetString("Exception_Items",g_sEItems,sizeof g_sEItems);
										KV.GetString("Exception_Categories",g_sECategories,sizeof g_sECategories);
									}
									break;
								}
							}
							else
								LogError("Некорректная скидка \"%s\"",szDate);
						}
					}
				}
			} while (KV.GotoNextKey(false));
		}
	}
	delete KV;
}

public Action Shop_OnItemBuy(int iClient, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ItemType type, int &price, int &sell_price, int &value)
{
	if(100 >= g_iDiscount > 0)
	{
		char sBuffer[128];
		if((g_sCategories[0] || g_sItems[0]) && StrContains(g_sItems, sBuffer, false) != -1 || (Shop_GetCategoryNameById(category_id, sBuffer, sizeof sBuffer) && StrContains(g_sCategories, sBuffer, false) != -1))
		{
			price -= (price*g_iDiscount)/100;
			sell_price -= (sell_price*g_iDiscount)/100;
		}
		else if((g_sECategories[0] || g_sEItems[0]) && StrContains(g_sEItems, sBuffer, false) == -1 || (Shop_GetCategoryNameById(category_id, sBuffer, sizeof sBuffer) && StrContains(g_sECategories, sBuffer, false) == -1))
		{
			price -= (price*g_iDiscount)/100;
			sell_price -= (sell_price*g_iDiscount)/100;
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public bool Shop_OnItemDisplay(iClient, ShopMenu menu_action, CategoryId category_id, ItemId item_id, const char[] display, char[] sBuffer, int maxlength)
{
	Shop_GetItemNameById(item_id, sBuffer, maxlength);
	if(100 >= g_iDiscount > 0)
	{
		if((g_sCategories[0] || g_sItems[0]) && StrContains(g_sItems, sBuffer, false) != -1 || (Shop_GetCategoryNameById(category_id, sBuffer, maxlength) && StrContains(g_sCategories, sBuffer, false) != -1))
			FormatEx(sBuffer, maxlength, "%s (Скидка %i %%)", display, g_iDiscount);
		else if((g_sECategories[0] || g_sEItems[0]) && StrContains(g_sEItems, sBuffer, false) == -1 || (Shop_GetCategoryNameById(category_id, sBuffer, maxlength) && StrContains(g_sECategories, sBuffer, false) == -1))
			FormatEx(sBuffer, maxlength, "%s (Скидка %i %%)", display, g_iDiscount);
		return true;
	}
	return false;
}
