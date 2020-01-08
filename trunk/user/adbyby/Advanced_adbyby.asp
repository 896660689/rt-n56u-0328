<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - <#menu5_13_2#></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">

<link rel="shortcut icon" href="images/favicon.ico">
<link rel="icon" href="images/favicon.png">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/bootstrap.min.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/main.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/engage.itoggle.css">

<script type="text/javascript" src="/jquery.js"></script>
<script type="text/javascript" src="/bootstrap/js/bootstrap.min.js"></script>
<script type="text/javascript" src="/bootstrap/js/engage.itoggle.min.js"></script>
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/itoggle.js"></script>
<script type="text/javascript" src="/client_function.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script>
var $j = jQuery.noConflict();

$j(document).ready(function() {
	init_itoggle('adbyby_enable');
	init_itoggle('hosts_ad');
	init_itoggle('tv_hosts');
	init_itoggle('adbyby_adb_update');
	init_itoggle('adbyby_rules_x');
	var i=0;
    var z=0;
    var adbyby_update_hour = '<% nvram_get_x("", "adbyby_update_hour"); %>';
    var adbyby_update_min = '<% nvram_get_x("", "adbyby_update_min"); %>';
    while (i<24){
	i=i>9?i:"0"+i;
$j("#adbyby_update_hour").append("<option value='"+i+"'>"+i+"</option>");
i++;
}
$j("#adbyby_update_hour").val(adbyby_update_hour);
while (z<60)
{
z=z>9?z:"0"+z;
$j("#adbyby_update_min").append("<option value='"+z+"'>"+z+"</option>");
z++;
}
$j("#adbyby_update_min").val(adbyby_update_min);
});

</script>
<script>
<% adbyby_status(); %>
<% login_state_hook(); %>

var ipmonitor = [<% get_static_client(); %>];
var m_dhcp = [<% get_nvram_list("AdbybyConf", "AdIPList"); %>];
var m_rules = [<% get_nvram_list("AdbybyConf", "AdRULESList"); %>];
var mdhcp_ifield = 4;
if(m_dhcp.length > 0){
	var m_dhcp_ifield = m_dhcp[0].length;
	for (var i = 0; i < m_dhcp.length; i++) {
		m_dhcp[i][mdhcp_ifield] = i;
	}
}

var mrules_ifield = 2;
if(m_rules.length > 0){
	var m_rules_ifield = m_rules[0].length;
	for (var i = 0; i < m_rules.length; i++) {
		m_rules[i][mrules_ifield] = i;
	}
}

var isMenuopen = 0;

function initial(){
	show_banner(2);
	show_menu(5,12,1);
	show_footer();
	fill_adbyby_status(adbyby_status());
	if (!login_safe())
		textarea_scripts_enabled(0);
}

function textarea_scripts_enabled(v){
	inputCtrl(document.form['scripts.ad_blacklist.sh'], v);
	inputCtrl(document.form['scripts.ad_watchcat.sh'], v);
	inputCtrl(document.form['scripts.ad_custom.sh'], v);
}

function applyRule(){
	showLoading();
	document.form.bkye.name = "group_id2";
	document.form.action_mode.value = " Restart ";
	document.form.action_mode.value = " Apply ";
	document.form.current_page.value = "/Advanced_adbyby.asp";
	document.form.next_page.value = "";

	document.form.submit();
}

function submitInternet(v){
	showLoading();
	document.adbyby_action.action = "Ad_action.asp";
	document.adbyby_action.connect_action.value = v;
	document.adbyby_action.submit();
}

function fill_adbyby_status(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("adbyby_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}



function setClientMAC(num){
	document.form.adbybyip_mac_x_0.value = clients_info[num][2];
	document.form.adbybyip_ip_x_0.value = clients_info[num][1];
	document.form.adbybyip_name_x_0.value = clients_info[num][0];
	hideClients_Block();
}

function showLANIPList(){
	var code = "";
	var show_name = "";

	if(clients_info[i][0] && clients_info[i][0].length > 20)
		show_name = clients_info[i][0].substring(0, 18) + "..";
	else
		show_name = clients_info[i][0];

	if(clients_info[i][2]){
		code += '<a href="javascript:void(0)"><div onclick="setClientMAC('+i+');"><strong>'+clients_info[i][1]+'</strong>';
		code += ' ['+clients_info[i][2]+']';
		if(show_name && show_name.length > 0)
			code += ' ('+show_name+')';
		code += ' </div></a>';
	}
	if (code == "")
		code = '<div style="text-align: center;" onclick="hideClients_Block();"><#Nodata#></div>';
	code +='<!--[if lte IE 6.5]><iframe class="hackiframe2"></iframe><![endif]-->';
	$("ClientList_Block").innerHTML = code;
}

function hideClients_Block(){
	$j("#chevron").children('i').removeClass('icon-chevron-up').addClass('icon-chevron-down');
	$('ClientList_Block').style.display='none';
	isMenuopen = 0;
}

function pullLANIPList(obj){
	if(isMenuopen == 0){
		$j(obj).children('i').removeClass('icon-chevron-down').addClass('icon-chevron-up');
		$("ClientList_Block").style.display = 'block';
		document.form.adbybyip_mac_x_0.focus();
		isMenuopen = 1;
	}
	else
		hideClients_Block();
}

function done_validating(action){
	refreshpage();
}

function markGroupMDHCP(o, c, b) {
	document.form.group_id.value = "AdIPList";
	if(b == " Add "){
		if (document.form.adbybyip_staticnum_x_0.value >= c){
			alert("<#JS_itemlimit1#> " + c + " <#JS_itemlimit2#>");
			return false;
		}else if (document.form.adbybyip_mac_x_0.value==""){
			alert("<#JS_fieldblank#>");
			document.form.adbybyip_mac_x_0.focus();
			document.form.adbybyip_mac_x_0.select();
			return false;
		}else if(document.form.adbybyip_ip_x_0.value==""){
			alert("<#JS_fieldblank#>");
			document.form.adbybyip_ip_x_0.focus();
			document.form.adbybyip_ip_x_0.select();
			return false;
		}else if (!validate_hwaddr(document.form.adbybyip_mac_x_0)){
			return false;
		}else if (!validate_ipaddr_final(document.form.adbybyip_ip_x_0, 'staticip')){
			return false;
		}else{
			for(i=0; i<m_dhcp.length; i++){
				if(document.form.adbybyip_mac_x_0.value==m_dhcp[i][0]) {
					alert('<#JS_duplicate#>' + ' (' + m_dhcp[i][0] + ')' );
					document.form.adbybyip_mac_x_0.focus();
					document.form.adbybyip_mac_x_0.select();
					return false;
				}
				if(document.form.adbybyip_ip_x_0.value.value==m_dhcp[i][1]) {
					alert('<#JS_duplicate#>' + ' (' + m_dhcp[i][1] + ')' );
					document.form.adbybyip_ip_x_0.focus();
					document.form.adbybyip_ip_x_0.select();
					return false;
				}
			}
		}
	}
	pageChanged = 0;
	document.form.action_mode.value = b;
	return true;
}

function markGroupRULES(o, c, b) {
	document.form.group_id.value = "AdRULESList";
	if(b == " Add "){
		if (document.form.adbybyrules_staticnum_x_0.value >= c){
			alert("<#JS_itemlimit1#> " + c + " <#JS_itemlimit2#>");
			return false;
		}else if (document.form.adbybyrules_x_0.value==""){
			alert("<#JS_fieldblank#>");
			document.form.adbybyrules_x_0.focus();
			document.form.adbybyrules_x_0.select();
			return false;
		}else if(document.form.adbybyrules_road_x_0.value==""){
			alert("<#JS_fieldblank#>");
			document.form.adbybyrules_road_0.focus();
			document.form.adbybyrules_road_0.select();
			return false;
		}else{
			for(i=0; i<m_rules.length; i++){
				if(document.form.adbybyrules_x_0.value==m_rules[i][0]) {
					alert('<#JS_duplicate#>' + ' (' + m_rules[i][0] + ')' );
					document.form.adbybyrules_x_0.focus();
					document.form.adbybyrules_x_0.select();
					return false;
				}
				if(document.form.adbybyrules_road_x_0.value.value==m_rules[i][1]) {
					alert('<#JS_duplicate#>' + ' (' + m_rules[i][1] + ')' );
					document.form.adbybyrules_road_0.focus();
					document.form.adbybyrules_road_0.select();
					return false;
				}
			}
		}
	}
	pageChanged = 0;
	document.form.action_mode.value = b;
	return true;
}

function changeBgColor(obj, num){
	$("row" + num).style.background=(obj.checked)?'#D9EDF7':'whiteSmoke';
}
function changeBgColorrl(obj, num){
	$("rowrl" + num).style.background=(obj.checked)?'#D9EDF7':'whiteSmoke';
}

</script>
</head>

<body onload="initial();" onunLoad="return unload_body();">
    <div class="wrapper">
        <div class="container-fluid" style="padding-right: 0px">
            <div class="row-fluid">
                <div class="span3"><center><div id="logo"></div></center></div>
                <div class="span9" >
                    <div id="TopBanner"></div>
                </div>
            </div>
        </div>
        <div id="Loading" class="popup_bg"></div>
        <iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
        <form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">
        <input type="hidden" name="current_page" value="/Advanced_adbyby.asp">
        <input type="hidden" name="next_page" value="">
        <input type="hidden" name="next_host" value="">
        <input type="hidden" name="sid_list" value="AdbybyConf;">
        <input type="hidden" name="group_id" value="AdIPList;">
        <input type="hidden" name="bkye" value="AdRULESList;">
        <input type="hidden" name="action_mode" value="">
        <input type="hidden" name="action_script" value="">
        <input type="hidden" name="adbybyip_staticnum_x_0" value="<% nvram_get_x("AdIPList", "adbybyip_staticnum_x"); %>" readonly="1" />
        <input type="hidden" name="adbybyrules_staticnum_x_0" value="<% nvram_get_x("AdRULESList", "adbybyrules_staticnum_x"); %>" readonly="1" />
        <div class="container-fluid">
            <div class="row-fluid">
                <div class="span3">
                    <!--Sidebar content-->
                    <!--=====Beginning of Main Menu=====-->
                    <div class="well sidebar-nav side_nav" style="padding: 0px;">
                        <ul id="mainMenu" class="clearfix"></ul>
                        <ul class="clearfix">
                            <li>
                                <div id="subMenu" class="accordion"></div>
                            </li>
                        </ul>
                    </div>
                </div>

                <div class="span9">
                    <!--Body content-->
                    <div class="row-fluid">
                        <div class="span12">
                            <div class="box well grad_colour_dark_blue">
                                <h2 class="box_head round_top"><#menu5_20#> - <#menu5_13_2#></h2>
                                <div class="round_bottom">
                                    <div class="row-fluid">
                                        <div id="tabMenu" class="submenuBlock"></div>
                                        <div class="alert alert-info" style="margin: 10px;">广告屏蔽大师.过滤各种横幅.弹窗.视频广告 - Adblock Host 结合方式运行,屏蔽恶意网站<br />
											<div>AD规则：【<% nvram_get_x("", "adbyby_ltime"); %>】 &nbsp; &nbsp; |&nbsp; 视频规则：【<% nvram_get_x("", "adbyby_vtime"); %>】</div>
                                            <div>Adb List:【 <% nvram_get_x("", "adbyby_adb"); %> 】条 &nbsp; &nbsp; |&nbsp; Hosts AD:【 <% nvram_get_x("", "adbyby_hostsad"); %> 】条 &nbsp; &nbsp; |&nbsp; TV box:【 <% nvram_get_x("", "adbyby_tvbox"); %> 】条</div>
                                        </div>
                                        <table width="50%" align="center" cellpadding="4" cellspacing="0" class="table">
                                            <tr> <th>运行状态:</th>
                                                <td id="adbyby_status" colspan="3"></td>
                                            </tr>
                                            <tr >
                                                <th width="50%" style="border-top: 0 none">启用 Adbyby 功能 &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;</th>
                                                <td style="border-top: 0 none">
                                                    <div class="main_itoggle">
                                                        <div id="adbyby_enable_on_of">
                                                            <input type="checkbox" id="adbyby_enable_fake" <% nvram_match_x("", "adbyby_enable", "1", "value=1 checked"); %><% nvram_match_x("", "adbyby_enable", "0", "value=0"); %>>
                                                        </div>
                                                    </div>
                                                    <div style="position: absolute; margin-left: -10000px;">
                                                        <input type="radio" value="1" name="adbyby_enable" id="adbyby_enable_1" class="input" <% nvram_match_x("", "adbyby_enable", "1", "checked"); %>><#checkbox_Yes#>
                                                        <input type="radio" value="0" name="adbyby_enable" id="adbyby_enable_0" class="input" <% nvram_match_x("", "adbyby_enable", "0", "checked"); %>><#checkbox_No#>
                                                    </div>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th width="50%">过滤方案选择</th>
                                                <td>
                                                    <select name="adbyby_set" class="input">
                                                        <option value="0" <% nvram_match_x("","adbyby_set", "0","selected"); %>>模式一:全局模式(全部IP过滤)</option>
                                                        <option value="1" <% nvram_match_x("","adbyby_set", "1","selected"); %>>模式二:HOSTS IP 域名屏蔽过滤)</option>
                                                    </select>
                                                    <div><span style="color:#888;">HOSTS 模式,过滤效果稍差,推荐模式一</span></div>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th width="50%">加载 Adblock Host List &nbsp;&nbsp;
                                                    <input id="adbyby_update_b" class="btn btn-success" style="width:110px display:none;" type="button" name="updateadb" value="强制更新" onclick="submitInternet('updateadb');" />
                                                </th>
                                                <td>
                                                    <div class="main_itoggle">
                                                        <div id="adbyby_adb_update_on_of">
                                                            <input type="checkbox" id="adbyby_adb_update_fake" <% nvram_match_x("", "adbyby_adb_update", "1", "value=1 checked"); %><% nvram_match_x("", "adbyby_adb_update", "0", "value=0"); %>>
                                                        </div>
                                                    </div>
                                                    <div style="position: absolute; margin-left: -10000px;">
                                                        <input type="radio" value="1" name="adbyby_adb_update" id="adbyby_adb_update_1" class="input" value="1" <% nvram_match_x("", "adbyby_adb_update", "1", "checked"); %>><#checkbox_Yes#>
                                                        <input type="radio" value="0" name="adbyby_adb_update" id="adbyby_adb_update_0" class="input" value="0" <% nvram_match_x("", "adbyby_adb_update", "0", "checked"); %>><#checkbox_No#>
                                                    </div>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th width="50%">加载 AD hosts </th>
                                                <td>
                                                    <div class="main_itoggle">
                                                        <div id="hosts_ad_on_of">
                                                            <input type="checkbox" id="hosts_ad_fake" <% nvram_match_x("", "hosts_ad", "1", "value=1 checked"); %><% nvram_match_x("", "hosts_ad", "0", "value=0"); %>>
                                                        </div>
                                                    </div>
                                                    <div style="position: absolute; margin-left: -10000px;">
                                                        <input type="radio" value="1" name="hosts_ad" id="hosts_ad_1" class="input" value="1" <% nvram_match_x("", "hosts_ad", "1", "checked"); %>><#checkbox_Yes#>
                                                        <input type="radio" value="0" name="hosts_ad" id="hosts_ad_0" class="input" value="0" <% nvram_match_x("", "hosts_ad", "0", "checked"); %>><#checkbox_No#>
                                                    </div>
                                                </td>
                                            </tr>
                                            <tr>
                                                <th width="50%">加载 TVbox Hosts</th>
                                                <td>
                                                    <div class="main_itoggle">
                                                        <div id="tv_hosts_on_of">
                                                            <input type="checkbox" id="tv_hosts_fake" <% nvram_match_x("", "tv_hosts", "1", "value=1 checked"); %><% nvram_match_x("", "tv_hosts", "0", "value=0"); %>>
                                                        </div>
                                                    </div>
                                                    <div style="position: absolute; margin-left: -10000px;">
                                                        <input type="radio" value="1" name="tv_hosts" id="tv_hosts_1" class="input" value="1" <% nvram_match_x("", "tv_hosts", "1", "checked"); %>><#checkbox_Yes#>
                                                        <input type="radio" value="0" name="tv_hosts" id="tv_hosts_0" class="input" value="0" <% nvram_match_x("", "tv_hosts", "0", "checked"); %>><#checkbox_No#>
                                                    </div>
                                                </td>
                                            </tr>
                                            <tr id="adbyby_update_tr">
                                                <th>规则自动更新:</th>
                                                <td>
                                                    <select name="adbyby_update" class="input" style="width: 60px;">
                                                        <option value="0" <% nvram_match_x("","adbyby_update", "0","selected"); %>>每天</option>
                                                        <option value="1" <% nvram_match_x("","adbyby_update", "1","selected"); %>>每隔</option>
                                                        <option value="2" <% nvram_match_x("","adbyby_update", "2","selected"); %>>关闭</option>
                                                    </select>
                                                    <select name="adbyby_update_hour" id="adbyby_update_hour" class="input" style="width: 50px">
                                                    </select> 时
                                                    <select name="adbyby_update_min" id="adbyby_update_min" class="input" style="width: 50px">
                                                    </select> 分
                                                </td>
                                            </tr>
                                        </table>

                                        <table class="table">
                                            <tr>
                                                <td colspan="3" style="border-top: 0 none">
                                                    <i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('script11')"><span>域名白名单:</span></a>
                                                    <div id="script11" style="display:none">
                                                        <textarea rows="24" wrap="off" spellcheck="false" maxlength="314571" class="span12" name="scripts.ad_whitelist.sh" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("scripts.ad_whitelist.sh",""); %></textarea>
                                                    </div>
                                                </td>
                                            </tr>
                                            <tr>
                                                <td colspan="3" style="border-top: 0 none">
                                                    <i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('script12')"><span>域名黑名单:</span></a>
                                                    <div id="script12" style="display:none">
                                                        <textarea rows="24" wrap="off" spellcheck="false" maxlength="314571" class="span12" name="scripts.ad_blacklist.sh" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("scripts.ad_blacklist.sh",""); %></textarea>
                                                    </div>
                                                </td>
                                            </tr>
                                            <tr>
                                                <td colspan="3" style="border-top: 0 none">
                                                    <i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('script13')"><span>用户自定义规则:</span></a>
                                                    <div id="script13" style="display:none">
                                                        <textarea rows="8" wrap="off" spellcheck="false" maxlength="314571" class="span12" name="scripts.ad_custom.sh" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("scripts.ad_custom.sh",""); %></textarea>
                                                    </div>
                                                </td>
                                            </tr>
                                            <td colspan="2" style="border-top: 0 none">
                                                <center><input class="btn btn-primary" style="width: 219px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
                                                </td>
                                            </tr>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        </form>
    </div>
    <div id="footer"></div>
    <form method="post" name="adbyby_action" action="">
        <input type="hidden" name="connect_action" value="">
    </form>
</body>
</html>

