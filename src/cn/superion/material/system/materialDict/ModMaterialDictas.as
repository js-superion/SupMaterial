import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.material.system.materialDict.view.MaterialDictAdd;
import cn.superion.material.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.center.material.CdMaterialDict;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.mxml.RemoteObject;

private var _queryStates:Object={}
public static var destination:String="commMaterialDictImpl";
[Bindable]
public var fstrType:String="add";
private var fparameter:ParameterObject;
[Bindable]
public var selectedNode:XML;
private var win:MaterialDictAdd; //添加窗口
public static var flag:Boolean=true; //判断弹出框显示状态
public static const  MENU_NO:String="0702";
private var _isShow:Boolean=false;//显示小数位数，东方3，泰州2

public function initModMaterial():void
{
	this.pg_material_master.horizontalScrollPolicy="auto"
//	pg_material_master.colorWhereField="freezeSign"
//	pg_material_master.colorWhereValue="1";
	
	pg_material_master.colorWhereField="registerAvlDays";
	pg_material_master.colorWhereValues=["1","2","3","4","-1"];
	pg_material_master.colorWhereColors=[0xF72D55,0xdc7c00,0x01b919,0x000000,0x312CF3];
	
	
	if (AppInfo.currentUserInfo.inputCode == "PHO_INPUT")
	{
		queryType.selectedValue='phoInputCode'
	}
	else
	{
		queryType.selectedValue='fiveInputCode'
	}
	//快速查询监听事件
//	this.addEventListener(KeyboardEvent.KEY_DOWN, focusF2);
	//授权仓库赋值
	if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
	{
		storageDefault.dataProvider=AppInfo.currentUserInfo.storageList;
		storageDefault.selectedIndex=0;
	}
	storageDefault.textInput.editable=false;
	this.parentApplication.mainWin.menuPanel.width=0;
	
	//是否显示备注，东方1是，泰州0否
	var ros:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl', function(rev:Object):void
	{
		if (rev.data && rev.data[0] == '1')
		{
			_isShow=true; 
		//	pg_material_master.format = [,,,,'0.000','0.000','0.000','0.000','0.000'];
		}
		else{
			_isShow=false; 
		}
		
	});
	ros.findSysParamByParaCode("0609");
}

public function queryGridByClassCode():void
{
	var selItem:Object=materialClassLeftTree.itemClassTree.selectedItem
	if (!selItem)
	{
		return
	}
	var storageCode:String=null;
	if (storageDefault.selectedItem)
	{
		storageCode=storageDefault.selectedItem.storageCode;
	}
	var parame:ParameterObject=new ParameterObject();
	parame.conditions={materialClass: selItem.classCode, storageCode: storageCode};
	var remoteObj:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:*):void
	{
		if(rev.data && rev.data.length>0)
		{
			reCreateData(rev.data);
		}
		
		pg_material_master.dataProvider=rev.data;
	});
	remoteObj.findMaterialDictListByCondition(parame);
	_queryStates.method="findMaterialDictListByCondition";
	_queryStates.param=parame;
}

private function reCreateData(larry:ArrayCollection):void
{
	for each(var item:Object in larry)
	{
		var daysRange:String='4';
		if (item.registerAvlDate)
		{
			var days:int=DateUtil.getTimeSpans(new Date(),item.registerAvlDate);
			
			if(days<=30)
			{
				daysRange='1'
			}
			else if(days>30 && days<=60)
			{
				daysRange='2';
			}
			else if(days>60 && days<=90)
			{
				daysRange='3';
			}
			else
			{
				daysRange='4';
			}
		}
		if(item.freezeSign=='1')
		{
			daysRange='-1';
		}
		item.registerAvlDays=daysRange;
	}
}

/**
 * 用户按下回车查询
 * */
protected function txtQuery_enterHandler(event:FlexEvent):void
{
	// TODO Auto-generated method stub
	btQuery_clickHandler(null);
}


//查询
private function btQuery_clickHandler(event:Event):void
{
	var inpCode:String=txtQuery.text;
	var storageCode:String=null;
	if (storageDefault.selectedItem)
	{
		storageCode=storageDefault.selectedItem.storageCode;
	}
	var param:ParameterObject=new ParameterObject();
	if (queryType.selectedValue == 'fiveInputCode')
	{
		param.conditions={storageCode: storageCode, fiveInputCode: inpCode, phoInputCode: null};
	}
	else
	{
		param.conditions={storageCode: storageCode, fiveInputCode: null, phoInputCode: inpCode};
	}
	var rome:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
	{
		if (rev.data && rev.data.length > 0)
		{
			reCreateData(rev.data);
			pg_material_master.dataProvider=rev.data;
			pg_material_master.invalidateList();
		}
		else
		{
			pg_material_master.dataProvider=null;
		}
	});
	rome.findMaterialDictListByCondition(param);
}

public function initNewMaterialDict():CdMaterialDict
{
	var cdMaterialDict:CdMaterialDict=new CdMaterialDict();
	cdMaterialDict.stopDate=new Date();
	var curTreeItem:Object=materialClassLeftTree.itemClassTree.selectedItem
	if (curTreeItem)
	{
		cdMaterialDict.materialClass=curTreeItem.classCode
		if (cdMaterialDict.materialClass == "00")
		{
			cdMaterialDict.materialClass=""
		}
	}
	return cdMaterialDict
}

//新增
private function showMaterialDictAddWin(fstrType:String):void
{
	//判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, "01"))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	var lstrWinTitle:String="新建物资信息";
	var selItem:CdMaterialDict=initNewMaterialDict();
	if(fstrType == 'add'){
		var seleTreeItem:Object=materialClassLeftTree.itemClassTree.selectedItem;
		if(!seleTreeItem){
			return;
		}
		if(seleTreeItem.endSign == null || seleTreeItem.endSign == "0" ){
			Alert.show("只能在末级分类下增加", "提示");
			return;
		}
	}
	if (fstrType == 'modi')
	{
		lstrWinTitle="修改物资信息"
		selItem=pg_material_master.selectedItem as CdMaterialDict
		if (selItem == null)
		{
			return;
		}
		selItem=pg_material_master.selectedItem as CdMaterialDict;
	}
	var win:MaterialDictAdd=MaterialDictAdd(PopUpManager.createPopUp(this, MaterialDictAdd, true));
	win.data={parentWin: this, isAdd: fstrType == 'add', selectedItem: selItem};
	FormUtils.centerWin(win);
	win.title=lstrWinTitle;
}

//修改
private function itemDictDoub():void
{
	//判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, "02"))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
}

//删除
private function delClick(e:Event):void
{
	//判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, "03"))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	var selectedItem:Object=pg_material_master.selectedItem;
	if (selectedItem == null)
	{
		Alert.show("请选择您要删除的数据！", "提示")
	}
	else
	{
		var lmaterialId:String=selectedItem.materialId;
		Alert.show("确定要删除该记录吗?", "警告", Alert.YES | Alert.NO, null, function(evt:CloseEvent):void
		{
			if (evt.detail == Alert.YES)
			{
				var remoteObj:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:*):void
				{
					requery();
					Alert.show("删除" + selectedItem.materialName + "物资信息成功!", "提示信息");
				});
				remoteObj.deleteMaterialDict(lmaterialId);
			}
		});
	}
}

public function requery():void
{
	if (!_queryStates.method)
	{
		return;
	}
	var remoteObj:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:*):void
	{
		if(rev.data && rev.data.length>0)
		{
			reCreateData(rev.data);
		}
		
		pg_material_master.dataProvider=rev.data;
	});
	remoteObj.getOperation(_queryStates.method).send(_queryStates.param);
}

//返回
private function returnBack():void
{
	this.parentApplication.mainWin.menuPanel.width=197;
	PopUpManager.removePopUp(this.parentDocument as IFlexDisplayObject);
	DefaultPage.gotoDefaultPage();
}

/**
 * @param 参数说明
 * 		  lstrPurview 权限编号;
 * 		  isPrintSign 打印输出标识。直接打印：1，输出：0
 */
private function printExpHandler(lstrPurview:String, isPrintSign:String):void
{
	//判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, lstrPurview))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	var receiveListPrintItems:ArrayCollection=pg_material_master.dataProvider as ArrayCollection;
	var dict:Dictionary=new Dictionary();
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="物资列表";
	dict["制表人"]=AppInfo.currentUserInfo.userName;
	if (isPrintSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/material/list/materialDictList.xml", receiveListPrintItems, dict);

	}
	else
	{
		ReportViewer.Instance.Show("report/material/list/materialDictList.xml", receiveListPrintItems, dict);

	}
}

private function lbfMainProvider(item:Object, column:DataGridColumn):String
{
	var tarItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict, 'provider', item.mainProvider)
	if (tarItem)
	{
		item.mainProviderName=tarItem.providerName
		return item.mainProviderName
	}
	return "";
}

private function lbfStorageDefault(item:Object, column:DataGridColumn):String
{
	var tarItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict, 'storage', item.storageDefault)
	if (tarItem)
	{
		item.storageDefaultName=tarItem.storageName
		return item.storageDefaultName
	}
	return "";
}
