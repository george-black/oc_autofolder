string g_sAppVersion = "1.0";

string  g_sSubMenu              = "AutoFolder";
string  g_sParentMenu          = "Apps";
string  PLUGIN_CHAT_CMD             = "af";
string  PLUGIN_CHAT_CMD_ALT         = "autofolder";
integer IN_DEBUG_MODE               = TRUE;
string  g_sCard                     = ".autofolder";
//integer g_iRLVOn = FALSE; //Assume RLV is off until we hear otherwise

list g_lMenuIDs;//3-strided list of avkey, dialogid, menuname
integer g_iMenuStride = 3;

list PLUGIN_BUTTONS = ["SAVE", "PRINT", "REMOVE"];
string UPMENU = "BACK";

integer CMD_OWNER                   = 500;
//integer CMD_TRUSTED               = 501;
integer CMD_GROUP                   = 502;
integer CMD_WEARER                  = 503;

integer NOTIFY = 1002;
integer REBOOT = -1000;

integer LINK_DIALOG = 3;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;
integer MENUNAME_REQUEST           = 3000;
integer MENUNAME_RESPONSE          = 3001;
integer MENUNAME_REMOVE            = 3003;
integer DIALOG                     = -9000;
integer DIALOG_RESPONSE            = -9001;
integer DIALOG_TIMEOUT             = -9002;

Debug(string sStr) {
    if (!IN_DEBUG_MODE) {
        return;
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sMenuType) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, sMenuType], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kRCPT, kMenuID, sMenuType];
}

DoMenu(key keyID, integer iAuth) {
    string sPrompt = "\nAutoFolder\t"+g_sAppVersion+"\n\nWear this!";
    //list lMyButtons = PLUGIN_BUTTONS + g_lDestinations + g_lVolatile_Destinations;
    list lMyButtons = PLUGIN_BUTTONS;
    Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth, "autofolder");
}

UserCommand(integer iNum, string sStr, key kID) {
    list lParams = llParseString2List(sStr, [" "], []);
    if (sStr == "reset") {
        // it is a request for a reset
        if (iNum == CMD_WEARER || iNum == CMD_OWNER)
            //only owner and wearer may reset
            llResetScript();
    } else if (sStr == PLUGIN_CHAT_CMD || llToLower(sStr) == "menu " + PLUGIN_CHAT_CMD_ALT || llToLower(sStr) == PLUGIN_CHAT_CMD_ALT) {
        if (iNum==CMD_GROUP) {
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        }
        // an authorized user requested the plugin menu by typing the menus chat command
        DoMenu(kID, iNum);
    }
}

default {
    link_message(integer iSender, integer iNum, string sStr, key kID) {
    Debug((string)iSender + "|" + (string)iNum + "|" + sStr + "|" + (string)kID);
    if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
        llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
    } else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) {
      UserCommand(iNum, sStr, kID);
    } else if(iNum == DIALOG_RESPONSE) {
      integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
      if (iMenuIndex != -1) {
        list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
        key kAv = (key)llList2String(lMenuParams, 0); // avatar using the menu
        string sMessage = llList2String(lMenuParams, 1); // button label
        integer iPage = (integer)llList2String(lMenuParams, 2); // menu page
        integer iAuth = (integer)llList2String(lMenuParams, 3); // auth level of avatar
        list lParams =  llParseStringKeepNulls(sStr, ["|"], []);
        string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
        g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        if(sMessage == UPMENU) {
            llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sParentMenu, kAv);
        }
      }
    } else if (iNum == LINK_UPDATE) {
        if (sStr == "LINK_DIALOG") {
            LINK_DIALOG = iSender;
        }
        else if (sStr == "LINK_SAVE")  {
            LINK_SAVE = iSender;
        }
    } else if (iNum == DIALOG_TIMEOUT) {
        integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
        g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
    } else if (iNum == REBOOT && sStr == "reboot") {
        llResetScript();
    }
  }
}
