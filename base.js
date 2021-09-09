/*
基础类，控制页面执行流程，每个页面都必须引用:
1.登录验证
2.记录最后访问页面，刷新恢复
3.多语言翻译
Cookie：
1.userInfo:admin;base64(123456);admin//登录用户验证信息
2.menu_1:m_LiveMonitor//一级菜单
3.menu_2:basicInfo//子级菜单（菜单树节点ID）
3.tab:
*/

//var dataServiceBase = "http://192.168.3.211:80/";
var dataServiceBase = "/";

var serverIp = window.top.location.hostname;
//var serverIp = "192.168.3.211";
var serverHost = window.top.location.host;
var webBase = "/";
var cfgMinHeight = 600; //配置页面最小高度
var xmlHeader = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>";
var protocolVer = "1.0", systemType = "NVMS-9000";
var emptyRequest = xmlHeader + "<request version=\"" + protocolVer + "\" systemType=\"" + systemType + "\" clientType=\"WEB\"/>";
var requestHeader = xmlHeader + "<request version=\"" + protocolVer + "\" systemType=\"" + systemType + "\" clientType=\"WEB\">";
var heightFix = 52; //config_content的上下留空高度
var onPageLoadHander; //叶子节点页面加载完成处理接口---解决IE8刷新浏览器会刷新两次框架内页面的问题
var nameByteMaxLen = 256; //名字的最大字节长度;
var pwdByteMaxLen = 16; //用户名密码的最大字节长度;
var systemAuthList = [ "localChlMgr", "remoteChlMgr", "remoteLogin", "diskMgr", "talk", "alarmMgr",
	"net", "scheduleMgr", "rec", "localSysCfgAndMaintain", "remoteSysCfgAndMaintain", "securityMgr"]; // 系统权限列表
//页面语言Key
var pageLangKeys = null;
//公用语言Key
var commLangKeys = ["IDCS_UNKNOWN_ERROR_CODE", "IDCS_NO_AUTH", "IDCS_APPLY", "IDCS_OK", "IDCS_CANCEL", "IDCS_FUNCTION_PANEL", "IDCS_QUERY_DATA_FAIL", "IDCS_SAVE_DATA_FAIL", "IDCS_SAVE_DATA_SUCCESS", "IDCS_DEVC_REQUESTING_DATA", "IDCS_SUCCESS_TIP", "IDCS_ERROR_TIP", "IDCS_INFO_TIP", "IDCS_DELETE_FAIL", "IDCS_DELETE_SUCCESS", "IDCS_INVALID_CHAR", "IDCS_NAME_EXISTED", "IDCS_RESOURCE_NOT_EXIST", "IDCS_CLOSE", "IDCS_LOGIN_FAIL_REASON_U_P_ERROR", "IDCS_LOGIN_FAIL_USER_LOCKED", "IDCS_ON", "IDCS_OFF", "IDCS_ADD", "IDCS_NO_PLUGIN_FOR_WINDOWS", "IDCS_NO_PLUGIN_FOR_MAC", "IDCS_NPAPI_NOT_SUPPORT"];

//错误码定义
var nodeExist = 536870913; //0x20000000+0x01 // 节点已存在（目前用于判断ip 端口重复）
var resourceNotExist = 536870923; //0x20000000+0x0B // 资源不存在
var nameExist = 536870970; //0x20000000+0x3a // 名称已存在
var ipError = 536870992; //0x20000000+0x50 // IP地址格式错误
var outOfRange = 536871004; //0x20000000+0x5C // 超出范围
var noConfigData = 536870962; //没有产生任何配置数据（当做是成功的）

//设置配置页面最小高度
function setMiniHeight(h) {
	h = (h > cfgMinHeight ? h : cfgMinHeight);
	$("#Content", window.top.document).css("min-height", h + "px");
}

function clearMiniHeight() {
	$("#Content", window.top.document).css("min-height", "0px");
}

//菜单类
function Menu(level, url, lk, nav, frame) {
	this.level = level; //目录级别
	this.url = url;
	this.lk = lk; //翻译key
	this.nav = nav; //导航路径
	this.frame = frame; //所属iframe
}

var MenuCtrl = {
	menuList: {
		"login": new Menu(0, "login.htm", "", [], null),
		"main": new Menu(0, "main.htm", "", [], null),
		"live": new Menu(1, "Live/live.htm", "", [], "main"),
		"rec": new Menu(1, "Rec/rec.htm", "", [], "main"),
		"cfgHome": new Menu(1, "cfgHome.htm", "", [], "main"),
		"localConfig": new Menu(1, "localConfig.htm", "", [], "main"),
		"recBackUp": new Menu(1, "Rec/recBackUp.htm", "", [], "main"),
		"chlCfgFrame": new Menu(1, "ChlCfg/chlCfgFrame.htm", "", [], "main"),
		"chlMgr": new Menu(2, "ChlCfg/chlMgr.htm", "IDCS_CHANGE_OR_DELETE_CHANNEL", [], "chlCfgFrame"),
		"addChl": new Menu(2, "ChlCfg/addChl.htm", "IDCS_ADD_CHANNEL", ["chlMgr"], "chlCfgFrame"),
//		"editChl": new Menu(2, "ChlCfg/editChl.htm", "editChl", ["chlMgr"], "chlCfgFrame"),
		"chlGroupMgr": new Menu(2, "ChlCfg/chlGroupMgr.htm", "IDCS_CHANGE_OR_DELETE_CHANNEL_GROUP", [], "chlCfgFrame"),
		"addChlGroup": new Menu(2, "ChlCfg/addChlGroup.htm", "IDCS_ADD_GROUP", ["chlGroupMgr"], "chlCfgFrame"),
		"dwell": new Menu(2, "ChlCfg/dwell.htm", "dwell", ["chlGroupMgr"], "chlCfgFrame"),
		"displaySet": new Menu(2, "ChlCfg/displaySet.htm", "IDCS_IMAGE_PARAMETER_SETTING", [], "chlCfgFrame"),
		"osd": new Menu(2, "ChlCfg/osd.htm", "IDCS_OSD_SETTING", [], "chlCfgFrame"),
		"videoMask": new Menu(2, "ChlCfg/videoMask.htm", "IDCS_VIDEO_MASK_SETTING", [], "chlCfgFrame"),
		"signalShelter": new Menu(2, "ChlCfg/signalShelter.htm", "IDCS_SIGNAL_SHELTER_SETTING", [], "chlCfgFrame"),
		"motion": new Menu(2, "ChlCfg/motion.htm", "IDCS_MOTION_SETTING", [], "chlCfgFrame"),
		"ptzProtocol": new Menu(2, "ChlCfg/ptzProtocol.htm", "IDCS_PROTOCOL", [], "chlCfgFrame"),
		"preset": new Menu(2, "ChlCfg/preset.htm", "IDCS_PRESET", [], "chlCfgFrame"),
		"cruise": new Menu(2, "ChlCfg/cruise.htm", "IDCS_CRUISE", [], "chlCfgFrame"),
		"diskCfgFrame": new Menu(1, "DiskCfg/diskCfgFrame.htm", "IDCS_DISK_MANAGE", [], "main"),
		"diskMgr": new Menu(2, "DiskCfg/diskMgr.htm", "IDCS_CHANGE_OR_DELETE_ARRAY", [], "diskCfgFrame"),
		"addRaid": new Menu(2, "DiskCfg/addRaid.htm", "IDCS_ADD_ARRAY", ["diskMgr"], "diskCfgFrame"),
		"setDedicatedSpare": new Menu(2, "DiskCfg/setDedicatedSpare.htm", "IDCS_SET_UNIQUE_DISK", ["diskMgr"], "diskCfgFrame"),
		"setGlobalSpare": new Menu(2, "DiskCfg/setGlobalSpare.htm", "IDCS_SET_WHOLE_HOT_DISK", ["diskMgr"], "diskCfgFrame"),
		"setFreeDisk": new Menu(2, "DiskCfg/setFreeDisk.htm", "IDCS_SET_FREE_DISK", ["diskMgr"], "diskCfgFrame"),
		"storageModeCfg": new Menu(2, "DiskCfg/storageModeCfg.htm", "IDCS_STORAGE_MODE_SET", [], "diskCfgFrame"),
		"viewDiskInfo": new Menu(2, "DiskCfg/viewDiskInfo.htm", "IDCS_VIEW_DISK_INFORMATION", [], "diskCfgFrame"),
		"viewRaidInfo": new Menu(2, "DiskCfg/viewRaidInfo.htm", "IDCS_VIEW_ARRAY_INFORMATION", [], "diskCfgFrame"),
		"viewSmartInfo": new Menu(2, "DiskCfg/viewSmartInfo.htm", "IDCS_DISK_SMART_INFO", [], "diskCfgFrame"),
		"netCfgFrame": new Menu(1, "NetCfg/netCfgFrame.htm", "", [], "main"),
		"netBase": new Menu(2, "NetCfg/netBase.htm", "TCP/IPv4", [], "netCfgFrame"),
		"port": new Menu(2, "NetCfg/port.htm", "IDCS_PORT", [], "netCfgFrame"),
		"ddns": new Menu(2, "NetCfg/ddns.htm", "DDNS", [], "netCfgFrame"),
		"email": new Menu(2, "NetCfg/email.htm", "Email", [], "netCfgFrame"),
		"upnp": new Menu(2, "NetCfg/upnp.htm", "UPnP", [], "netCfgFrame"),
		"ftp": new Menu(2, "NetCfg/ftp.htm", "FTP", [], "netCfgFrame"),
		"nat": new Menu(2, "NetCfg/nat.htm", "IDCS_NAT", [], "netCfgFrame"),
		"platform": new Menu(2, "NetCfg/platform.htm", "IDCS_PLATFORM_ACCESS", [], "netCfgFrame"),
		"netStatus": new Menu(2, "NetCfg/netStatus.htm", "IDCS_VIEW_NETWORK_STATE", [], "netCfgFrame"),
		"onlineVideo": new Menu(2, "NetCfg/onlineVideo.htm", "onlineVideo", [], "netCfgFrame"),
		"systemFrame": new Menu(1, "System/systemFrame.htm", "", [], "main"),
		"commonCfg": new Menu(2, "System/commonCfg.htm", "IDCS_GENERAL_SET", [], "systemFrame"),
		"dateAndTime": new Menu(2, "System/dateAndTime.htm", "IDCS_DATE_AND_TIME", [], "systemFrame"),
		"viewLog": new Menu(2, "System/viewLog.htm", "IDCS_VIEW_LOG", [], "systemFrame"),
		"reboot": new Menu(2, "System/reboot.htm", "IDCS_SYSTEM_REBOOT", [], "systemFrame"),
		"factoryReset": new Menu(2, "System/factoryReset.htm", "IDCS_DEFAULT_SET", [], "systemFrame"),
		"upgrade": new Menu(2, "System/upgrade.htm", "IDCS_UPGRADE", [], "systemFrame"),
		"backupRestore": new Menu(2, "System/backupRestore.htm", "IDCS_BACKUP_AND_RESTORE_SET", [], "systemFrame"),
		"devBasicInfo": new Menu(2, "System/devBasicInfo.htm", "IDCS_DEVICE_BASIC_INFORMATION", [], "systemFrame"),
		"chlStatus": new Menu(2, "System/chlStatus.htm", "IDCS_CHANNEL_STATE", [], "systemFrame"),
		"userFrame": new Menu(1, "UserMgr/userFrame.htm", "", [], "main"),
		"addUser": new Menu(2, "UserMgr/addUser.htm", "IDCS_ADD_USER", ["userMgr"], "userFrame"),
		"userMgr": new Menu(2, "UserMgr/userMgr.htm", "IDCS_CHANGE_OR_DELETE_USER", [], "userFrame"),
		"addAuthGroup": new Menu(2, "UserMgr/addAuthGroup.htm", "IDCS_ADD_USER_RIGHT", ["authGroupMgr"], "userFrame"),
		"authGroupMgr": new Menu(2, "UserMgr/authGroupMgr.htm", "IDCS_CHANGE_OR_DELETE_RIGHT_GROUP", [], "userFrame"),
		"filterRule": new Menu(2, "UserMgr/filterRule.htm", "IDCS_BLACK_AND_WHITE_LIST", [], "userFrame"),
		"alarmCfgFrame": new Menu(1, "AlarmCfg/alarmCfgFrame.htm", "", [], "main"),
		"alarmOut": new Menu(2, "AlarmCfg/alarmOut.htm", "IDCS_ALARM_OUT", [], "alarmCfgFrame"),
		"alarmEmail": new Menu(2, "AlarmCfg/alarmEmail.htm", "Email", [], "alarmCfgFrame"),
		"alarmDisplay": new Menu(2, "AlarmCfg/alarmDisplay.htm", "IDCS_DISPLAY", [], "alarmCfgFrame"),
		"beeper": new Menu(2, "AlarmCfg/beeper.htm", "IDCS_BUZZER", [], "alarmCfgFrame"),
		"alarmAddSchedule": new Menu(2, "AlarmCfg/alarmAddSchedule.htm", "IDCS_ADD_SCHEDULE", ["alarmScheduleMgr"], "alarmCfgFrame"),
		"alarmScheduleMgr": new Menu(2, "AlarmCfg/alarmScheduleMgr.htm", "IDCS_SCHEDULE_MANAGE", [], "alarmCfgFrame"),
		"motionAlarmCfg": new Menu(2, "AlarmCfg/motionAlarmCfg.htm", "IDCS_MOTION_DETECT_ALARM", [], "alarmCfgFrame"),
		"sensorAlarmCfg": new Menu(2, "AlarmCfg/sensorAlarmCfg.htm", "IDCS_SENSOR_ALARM", [], "alarmCfgFrame"),
		"abnormalAlarmCfg": new Menu(2, "AlarmCfg/abnormalAlarmCfg.htm", "IDCS_SYSTEM_ABNORMAL_DISPOSE_WAY_SET", [], "alarmCfgFrame"),
		"devOfflineAlarmCfg": new Menu(2, "AlarmCfg/devOfflineAlarmCfg.htm", "IDCS_FRONT_OFFLINE", [], "alarmCfgFrame"),
		"videoLossAlarmCfg": new Menu(2, "AlarmCfg/videoLossAlarmCfg.htm", "IDCS_VLOSS", [], "alarmCfgFrame"),
		"viewAlarmStatus": new Menu(2, "AlarmCfg/viewAlarmStatus.htm", "IDCS_VIEW_ALARM_STATE", [], "alarmCfgFrame"),
		"recCfgFrame": new Menu(1, "RecCfg/recCfgFrame.htm", "", [], "main"),
		"recModeCfg": new Menu(2, "RecCfg/recModeCfg.htm", "IDCS_MODE_SET", [], "recCfgFrame"),
		"recParamCfg": new Menu(2, "RecCfg/recParamCfg.htm", "IDCS_PARAM_SET", [], "recCfgFrame"),
		"recSnapCfg": new Menu(2, "RecCfg/recSnapCfg.htm", "IDCS_SNAP_SET", [], "recCfgFrame"),
		"eventRecStream": new Menu(2, "RecCfg/eventRecStream.htm", "IDCS_EVENT_RECORD_CODE_STREAM", [], "recCfgFrame"),
		"timingRecStream": new Menu(2, "RecCfg/timingRecStream.htm", "IDCS_TIME_RECORD_CODE_STREAM", [], "recCfgFrame"),
		"scheduleRecCfg": new Menu(2, "RecCfg/scheduleRecCfg.htm", "IDCS_SCHEDULE_OF_RECORD_SET", [], "recCfgFrame"),
		"addSchedule": new Menu(2, "RecCfg/addSchedule.htm", "IDCS_ADD_SCHEDULE", ["scheduleMgr"], "recCfgFrame"),
		"scheduleMgr": new Menu(2, "RecCfg/scheduleMgr.htm", "IDCS_SCHEDULE_MANAGE", [], "recCfgFrame"),
		"subStream": new Menu(2, "RecCfg/subStream.htm", "IDCS_SUB_STREAM_SET", [], "recCfgFrame"),
		"ftpRecStream": new Menu(2, "RecCfg/ftpRecStream.htm", "IDCS_FTP_STREAM_SET", [], "recCfgFrame"),
		"eventRecCfg": new Menu(2, "RecCfg/eventRecCfg.htm", "IDCS_EVENT_RECORD_SET", [], "recCfgFrame"),
		"viewRecStatus": new Menu(2, "RecCfg/viewRecStatus.htm", "IDCS_VIEW_RECORD_STATE", [], "recCfgFrame")
	},
	setMenuCookie: function () {
		var menuId = PageCtrl.getPageName();
		var menu = MenuCtrl.menuList[menuId];
		if (!menu) return;
		switch (menu.level) {
			case 1:
				$.cookie('menu_1', menuId);
				window.top.MainCtrl.setMainMenu(menuId);
				break;
			case 2:
				$.cookie('menu_2', menuId);
				window.top.MainCtrl.setMainMenu(menuId);
				if ("selectModel" in window.parent) {
					window.parent.selectModel(menuId);
				}
				var navList = MenuCtrl["menuList"][menuId]["nav"];
				navList.push(menuId);
				setCfgNavBar(navList);
				break;
		}
	}
};

function doNav(menuId) {
	var curMenuId = PageCtrl.getPageName();
	switch (MenuCtrl["menuList"][menuId]["level"]) {
		case 1:
			$("#mainFrame", window.top.document).attr("src", webBase + "Pages/" + MenuCtrl["menuList"][menuId]["url"]);
			break;
		case 2:
			if (MenuCtrl["menuList"][menuId]["frame"] == curMenuId) {
				$("#configRightFrame").attr("src", webBase + "Pages/" + MenuCtrl["menuList"][menuId]["url"]);
			}
			else {
				$.cookie('menu_2', menuId);
				$("#mainFrame", window.top.document).attr("src", webBase + "Pages/" + MenuCtrl["menuList"][MenuCtrl["menuList"][menuId]["frame"]]["url"]);
			}
			break;
	}
}

function setCfgNavBar(navList) {
	var navBarHtml = "<a href=\"" + webBase + "Pages/cfgHome.htm\" target=\"mainFrame\">" + window.parent.LangCtrl._L_('IDCS_FUNCTION_PANEL') + "</a>";

	for (var i in navList) {
		navBarHtml += "<div alt=\"nav\"></div><a href=\"javascript:doNav('" + navList[i] + "')\" >" + window.parent.LangCtrl._L_(MenuCtrl["menuList"][navList[i]]["lk"]) + "</a>";
	}

	$("#navBar", window.parent.document).html(navBarHtml);
}

var PageCtrl = {
	getPageName: function () {
		var id = window.location.href.match(/.*\/(.+)\.htm/);
		if (id)
			return id[1];
	},
	getPagePath: function () {
		var reg = new RegExp(".*://[^/]*" + webBase + "Pages(/.+\\.htm)");
		//		var re = /.*:\/\/[^\/]*\/ipcweb\/Pages(\/.+\.htm)/;
		var path = window.location.href.match(reg);
		if (path)
			return path[1];
	}
};
/**
* 多语言
*/
var langMap = { "en-us": "0x0409", "zh-cn": "0x0804", "zh-tw": "0x0404", "zh-hant": "0x7C04", "cs-cz": "0x0405", "fr-fr": "0x040C", "pt-pt": "0x0816", "es-es": "0x0C0A", "tr-tr": "0x041F"
	, "bg-bg": "0x0402", "el-gr": "0x0408", "he-il": "0x040D", "it-it": "0x0410", "de-de": "0x0407", "ru-ru": "0x0419", "pl-pl": "0x0415", "ja-jp": "0x0411", "id-id": "0x0421", "th-th": "0x041E"
	, "hu-hu": "0x040E", "lt-lt": "0x0427", "vi-vn": "0x042A", "nl-nl": "0x0413", "fi-fi": "0x040B", "sv-se": "0x041D", "da-dk": "0x0406", "nb-no": "0x0414", "fa-ir": "0x0429", "ko-kr": "0x0412"
	, "ar": "0x0001", "ro-ro": "0x0418", "hr-hr": "0x041A", "mk-mk": "0x042F", "sk-sk": "0x041B", "sl-si": "0x0424", "es-mx": "0x080A", "es-es": "0x0C0A", "nl": "0x0013", "sr-cyrl-sp": "0x0C1A"
	, "kk-kz": "0x043F", "ar-eg": "0x0C01", "af-za": "0x0436"
};
var LangCtrl = {
	//语言包XML文档JQuery对象，第一次使用时加载，全局保存
	languageXMLDoc: null,
	//是否需要重新加载语言包，当重新选择了语言类型后，需要重新加载语言包
	isNeedLoadLang: true,
	//改变语言后执行的方法堆栈
	_callBack: {},
	_version: '20141009.00',
	//根据标签id获取对应语言的标签值
	_L_: function (tagID) {
		LangCtrl.loadLanguageXMLDoc();
		var tagText = tagID;
		var tag = $("response>content>langItems>item[id='" + replaceWithEntity(tagID) + "']", LangCtrl.languageXMLDoc);
		if (tag.length > 0)
			tagText = $(tag[0]).text();
		return tagText;
	},
	//加载语言XML文档
	loadLanguageXMLDoc: function () {
		if (!LangCtrl.languageXMLDoc || LangCtrl.isNeedLoadLang) {
			var langKeys = commLangKeys;
			if (pageLangKeys)
				langKeys = langKeys.concat(pageLangKeys);
			//			var langType = LangCtrl.getLang();
			var sendXml = requestHeader +
			  "<condition>" +
			  "  <langType>" + ($.cookie("lang_id") ? $.cookie("lang_id") : langMap[(navigator.userLanguage || navigator.language).toLowerCase()]) + "</langType>" +
			  "  <langKeys type=\"list\">";
			$.each(langKeys, function (i, elem) {
				sendXml += "	<item>" + elem + "</item>";
			});
			sendXml += "  </langKeys>" +
			  "</condition>" +
			"</request>";

			try {
				XmlHttpClient.SendHttpRequest({
					url: dataServiceBase + "getLangContent",
					type: "POST",
					async: false,
					data: sendXml,
					checkCommonErrorSwitch: false,
					callback: function (result) {
						if ($("response>status", result).text() == "success") {
							LangCtrl.languageXMLDoc = result;
							var langId = $.trim($("response>content>langType", result).text());
							var langType = "en-us";
							$.each(langMap, function (key, value) {
								if (value.toLowerCase() == langId) {
									langType = key;
									return;
								}
							});
							$.cookie('lang_type', langType);
						}
						else {
							$(window.top.document.body).html("");
							//							alert($("response>errorCode", result).text());
							LangCtrl.languageXMLDoc = null;
						}
					},
					error: function (msg) {
						$(window.top.document.body).html("");
						//						window.top.location.reload();
					}
				});
			} catch (ex) {
				$(window.top.document.body).html("");
			}
			LangCtrl.isNeedLoadLang = false;
		}
	},
	//改变语言
	changLang: function (lang, langId) {
		$.cookie('lang_type', lang, { expires: 36500 });
		$.cookie('lang_id', langId, { expires: 36500 });
		LangCtrl.isNeedLoadLang = true;
		window.top.location.reload();
	},
	setLang: function (drp) {
		var type = $.cookie('lang_type');
		if (type) drp.val(type);
	},
	getLang: function () {
		var langType = $.cookie('lang_type');
		if (!langType) {
			var sendXml = requestHeader +
			  "<types>" +
			  "  <langType>" +
			  "	<enum>zh-cn</enum>" +
			  "	<enum>en-us</enum>" +
			  "  </langType>" +
			  "</types>" +
			  "<condition>" +
			  "  <langType type=\"langType\"></langType>" +
			  "  <langKeys type=\"list\"></langKeys>" +
			  "</condition>" +
			"</request>";
			try {
				XmlHttpClient.SendHttpRequest({
					url: dataServiceBase + "getLangContent",
					type: "POST",
					async: false,
					data: sendXml,
					checkCommonErrorSwitch: false,
					callback: function (result) {
						if ($("response>status", result).text() == "success") {
							var langId = $.trim($("response>content>langType", result).text());
							$.each(langMap, function (key, value) {
								if (value.toLowerCase() == langId) {
									langtype = key;
									return;
								}
							});
						}
						else if ($("response>status", result).text() == "fail") {
							langType = "en-us";
						}
						$.cookie('lang_type', langType);
					}
				});
			} catch (ex) {
				$.cookie('lang_type', "en-us");
			}
		}
		return langType;
	},
	//添加改变语言后执行的方法
	addCallBack: function (key, fun) {
		if (key in LangCtrl._callBack) {
		}
		else {
			LangCtrl._callBack[key] = fun;
		}
	},
	//翻译页面
	translate: function (context) {
		var tranObj = context ? $("[lc]", context) : $("[lc]");
		tranObj.each(function (index, domEle) {
			var $domEle = $(domEle);
			var lcArr = $domEle.attr("lc").split(',');
			for (var i in lcArr) {
				switch (lcArr[i]) {
					case "html":
						$domEle.html(LangCtrl._L_($domEle.attr("lk")));
						break;
					case "value":
						$domEle.val(LangCtrl._L_($domEle.attr("lk")));
						break;
					case "title":
						$domEle.attr("title", LangCtrl._L_($domEle.attr("lk")));
						break;
				}
			}
		});
	}
};

function checkLogout() {
	var userInfo = $.cookie('userInfo');
	if (userInfo == null) {
		window.top.location.href = webBase + "Pages/login.htm";
	}
}

function cleareDislog(context) {
	if (!context) {
		context = document;
	}
	$("div.tvt_dialog_background", context).remove();
	$("div.tvt_dialog", context).remove();
}

$(function () {
	cleareDislog(window.top.document);
	//	$("#toolBar").empty();
	if (window.top.TopFloatMsg)
		window.top.TopFloatMsg.hide();
	$("#toolBar", window.parent.document).empty();
	$("#Content,#divCopyRight", window.top.document).css("min-width", "1100px");
	MenuCtrl.setMenuCookie();
	LangCtrl.translate();

	var curMenuId = PageCtrl.getPageName();

	//只有2级页面才有加载处理接口
	if (MenuCtrl["menuList"][curMenuId]["level"] == 2) {
		//window.top.IE8RefreshHack 为假值时，表示在刷新顶层页面前的无效的框架内页面刷新，不执行页面的加载处理接口
		if (window.top.IE8RefreshHack) {
			if (onPageLoadHander)
				onPageLoadHander();
		}
	}
});

function commSaveResponseHadler($response, successHandler, failedHandler) {
	if ($("response>status", $response).text() == "success") {
		window.top.MsgBoxHelper.Show("success", LangCtrl._L_("IDCS_SUCCESS_TIP"), LangCtrl._L_("IDCS_SAVE_DATA_SUCCESS"), function () {
			if (successHandler)
				successHandler();
		});
	}
	else {
		window.top.MsgBoxHelper.Show("info", LangCtrl._L_("IDCS_INFO_TIP"), LangCtrl._L_("IDCS_SAVE_DATA_FAIL"), function () {
			if (failedHandler)
				failedHandler();
		});
	}
}

function commLoadResponseHandler($response, successHandler, failedHandler) {
	if ($("response>status", $response).text() == "success") {
		if (typeof successHandler == "function") {
			successHandler($response);
		}
	} else {
	window.top.MsgBoxHelper.Show("info", LangCtrl._L_("IDCS_INFO_TIP"), LangCtrl._L_("IDCS_QUERY_DATA_FAIL"), function () {
			if (typeof failedHandler == "function") {
				failedHandler($response);
			}
		});
	}
}

function autoHeight() {
	$("#Content", window.top.document).height(window.top.document.body.clientHeight - 118);
}

//获得配置页面可见区域高度：配置导航条到网页底部的高度
function getCfgContentHeight() {
	return $("#Content", window.top.document).height() - 108;
}

// 判断是否有某个权限（可选值见顶部systemAuthList）
function hasAuth(authName) {
	if ($.cookie("authEffective") == "false")
		return true;
	var authIndex = $.inArray(authName, systemAuthList);
	return authIndex != -1 && ($.cookie("authMask") * 1 & Math.pow(2, authIndex)) != 0;
}