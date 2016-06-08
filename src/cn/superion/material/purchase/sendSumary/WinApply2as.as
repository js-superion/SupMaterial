import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.GridColumn;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.purchase.apply.view.PurchaseApplyQueryCon;
import cn.superion.material.purchase.plan.view.PurchaseChaseQueryCon;
import cn.superion.material.purchase.plan.view.PurchasePlanAuto;
import cn.superion.material.util.DefaultPage;
import cn.superion.material.util.MainToolBar;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialPlanDetail;
import cn.superion.vo.material.MaterialPlanMaster;
import cn.superion.vo.material.MaterialProvideDetail;
import cn.superion.vo.material.MaterialProvideMaster;
import cn.superion.vo.material.MaterialSupplierDetail;
import cn.superion.vo.material.MaterialSupplierSummary;

import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.ui.Keyboard;
import flash.ui.Mouse;

import mx.collections.ArrayCollection;
import mx.collections.ListCollectionView;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.events.FlexEvent;
import mx.events.ListEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

import spark.components.gridClasses.GridColumn;
import spark.events.TextOperationEvent;
import spark.formatters.DateTimeFormatter;

private static const MENU_NO:String="0110";
public var DESTANATION:String="sendImpl";
private var winY:int=0;

//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;
public var _this:* = null
private var _fparameter:Object={flag:"1"};
/**
 * 初始化当前窗口
 * */
public function doInit():void
{
	_this = this;
	preventDefaultForm();
	
	/*if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
	{
		var result:ArrayCollection =ObjectUtil.copy(AppInfo.currentUserInfo.storageList) as ArrayCollection;
		var newArray:ArrayCollection = new ArrayCollection();
		for each(var it:Object in result){
			if(it.type == '2'||it.type == '3'){
				newArray.addItem(it);
			}
		}
		storageCode.dataProvider=newArray;//AppInfo.currentUserInfo.storageList;
		storageCode.selectedIndex=0;
	}*/
	if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
	{
		//		storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
		//		storageCode.selectedIndex=0;
		
		var result:ArrayCollection =ObjectUtil.copy(AppInfo.currentUserInfo.storageList) as ArrayCollection;
		var newArray:ArrayCollection = new ArrayCollection();
		var ss:Array = [];
		for each(var it:Object in result){
			if(it.type == '2'||it.type == '3'){
				newArray.addItem(it);
			}
		}
		ss = newArray.toArray().reverse().sortOn("storageCode",Array.DESCENDING);
		storageCode.dataProvider=new ArrayCollection(ss);//AppInfo.currentUserInfo.storageList;
		storageCode.selectedIndex=0;		
	}
}




public var _autoId:String = null;
/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{

	salerCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
		{
			e.preventDefault();
		})
}


/**
 * 回车事件
 **/
private function toNextControl(event:KeyboardEvent, fctrlNext:Object):void
{
	FormUtils.toNextControl(event, fctrlNext);
}


/**
 * 供应商字典
 */
protected function productCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict(function(rev:Object):void
		{
			event.target.text=rev.providerName;
//			if (gridDetail.selectedItem)
//			{
//				gridDetail.selectedItem.salerCode=rev.providerId;
//				gridDetail.selectedItem.salerName=rev.providerName;
//			}
//			gridDetail.invalidateList();
		}, x, y);
}

/**
 * 部门字典
 */
protected function deptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(rev:Object):void
		{
			event.target.text=rev.deptName;
			_fparameter["deptCode"]=rev.deptCode;
		}, x, y);
}

/**
 * 物资字典
 */
protected function materialCode_queryIconClickHandler(event:Event):void
{
	//打开物资字典
	var y:int=this.parentApplication.screen.height - 338;
	var lstorageCode:String='';
	lstorageCode=null;
	DictWinShower.showMaterialDictNew(lstorageCode, '', '', true, function(faryItems:Array):void
	{
		if(faryItems){
			event.target.text = faryItems[0].materialCode;
			_fparameter["materialCode"] = faryItems[0].materialCode;
		}
	}, winY, y);
}

/**
 * 供应商字典
 */
protected function productCode_queryIconClickHandlers(event:Event):void
{
	// TODO Auto-generated method stub
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict(function(rev:Object):void
	{
		event.target.text=rev.providerName;
		_fparameter["mainProvider"] =rev.providerId;
		_fparameter["providerName"] =rev.providerName;
	}, winY, y);
}




/**
 * 保存
 */
protected function saveClickHandler(event:Event):void
{
	
	
	//控制供货单位必选
//	if(salerCode.txtContent.text == ''){
//		Alert.show("供货商必须选择", "提示");
//		return;
//	}
	
	var master:MaterialSupplierSummary = new MaterialSupplierSummary();
	master.storageCode = storageCode.selectedItem?storageCode.selectedItem.storageCode:null;
	master.providerCode = _fparameter["mainProvider"];
	master.providerName = salerCode.txtContent.text;
	var tempAry:ArrayCollection = gridListCount.dataProvider as ArrayCollection;
	var newAry:ArrayCollection = groupList2(tempAry);
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			Alert.show("保存成功", "提示");
			PopUpManager.removePopUp(_this);
		});
	ro.saveSumary(newAry);
}



import spark.events.IndexChangeEvent;

protected function status_changeHandler(event:IndexChangeEvent):void
{
	// TODO Auto-generated method stub
	queryClickHandler(null);
}

/**
 * 审核
 */
protected function verifyClickHandler(event:Event):void
{
	//审核权限
	if (!checkUserRole('06'))
	{
		return;
	}
	if(!gridListCount.dataProvider)
	{
		return;
	}
	var tempAry:ArrayCollection = gridListCount.dataProvider as ArrayCollection;
	var newAry:ArrayCollection = new ArrayCollection();
	for each(var item:Object in tempAry){
		if(item.isSelected){
			var materialProvideMaster:MaterialProvideMaster = new MaterialProvideMaster();
			materialProvideMaster = MainToolBar.classTransfer(item,materialProvideMaster);
			materialProvideMaster.sendStatus='2';
			newAry.addItem(materialProvideMaster);
		}
	}
	if(newAry.length == 0){
		Alert.show("请选择审核主记录", "提示");
		return
	}
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		Alert.show("审核成功", "提示");
	});
	ro.updateSendMaterialMaster(newAry);
}


private function groupList2(lst:ArrayCollection):ArrayCollection{
	var map:Object = {};
	var groupArray:ArrayCollection = new ArrayCollection();
	var detailArray:ArrayCollection = new ArrayCollection();
	map.mainProvider = null;
	
	for each(var it:Object in lst){
		if(it.isSelected){
			if(map.mainProvider==it.mainProvider)
			{
				it.isGroupFirst = false;
				detailArray.addItem(it);
			}else{
				it.isGroupFirst = true;
				var groupItem:Object = {};
				detailArray = new ArrayCollection();
				detailArray.addItem(it);
				groupItem.mainProvider = it.mainProvider;
				groupItem.providerName =it.providerName;
				groupItem.storageCode = storageCode.selectedItem?storageCode.selectedItem.storageCode:null;
				groupItem.fromDate = fromDate.text;
				groupItem.toDate = toDate.text; //保存时，后台需要根据开始，结束日期，查找并更新申请明细
				groupItem.detail = detailArray;
				groupArray.addItem(groupItem);
				
			}
			map.mainProvider = it.mainProvider;
		}
		
	}
	return groupArray;
}



private function groupList(lst:ArrayCollection):ArrayCollection{
	var temp:Object = {};
	temp.mainProvider = null;
	for each(var it:Object in lst){
		it.isSelected = false;
		if(temp.mainProvider==it.mainProvider)
		{
			it.isGroupFirst = false;
		}else{
			it.isGroupFirst = true;
		}
		temp.mainProvider = it.mainProvider;
	}
	return lst;
}

/**
 * 查询
 */
protected function queryClickHandler(event:Event):void
{
	selAll.selected = false;
	gridListCount.dataProvider = null;
	var param:ParameterObject=new ParameterObject();
	
	_fparameter.mainProvider = salerCode.text?_fparameter["mainProvider"]:null;
	_fparameter.currentStatus ='4'//过滤病区审核过的申请单
	_fparameter.checkAmountSign ='1';
	_fparameter.fromDate =fromDate.text;
	_fparameter.toDate =toDate.text;
	_fparameter.checkSupplySign = '1';
	_fparameter.manualSign = '0';
	_fparameter.storageCode = storageCode.selectedItem?storageCode.selectedItem.storageCode:null;
	param.conditions = _fparameter
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		groupList(rev.data);
		gridListCount.dataProvider = rev.data;
	});
	ro.findGroupByProvider(param);
}

/**
 * 退出
 */
protected function exitClickHandler(event:Event):void
{
	if (this.parentDocument is WinModual)
	{
		PopUpManager.removePopUp(this.parentDocument as IFlexDisplayObject);
		return;
	}
	DefaultPage.gotoDefaultPage();
}

/**
 * 当前角色权限认证
 */
public static function checkUserRole(role:String):Boolean
{
	//判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, role))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return false;
	}
	return true;
}

private function labFun(item:Object,column:DataGridColumn):String
{
	var reVal:String = "";
	if (column.headerText == '序号')
	{
		reVal  = (gridListCount.dataProvider.getItemIndex(item)+1).toString();
	}
	if (column.headerText == '日期')
	{
		var fmt:DateTimeFormatter = new DateTimeFormatter();
		fmt.dateTimePattern = "yyyy-MM-dd";
		reVal = fmt.format(item.billDate);
	}
	if (column.headerText == '病区')
	{
		var deptItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', item.deptCode);
		if (!deptItem)
		{
			item.deptName='';
		}
		else
		{
			item.deptName=deptItem.deptName;
		}
		reVal = item.deptName;
	}
	return reVal;
}

private function labFunTotal(item:Object,column:spark.components.gridClasses.GridColumn):String
{
	var reVal:String = "";
	if (column.headerText == '序号')
	{
		reVal  = (gridListCount.dataProvider.getItemIndex(item)+1).toString();
		item.serialNo = reVal;
		return reVal;
	}
	if (column.headerText == '供应单位')
	{
//		if(item.isGroupFirst){
			var provider:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict, 'provider', item.mainProvider);
			if (!provider)
			{
				item.providerName='';
			}
			else
			{
				item.providerName = provider.providerName;
			}
			reVal = item.providerName;
//		}
			
			if(item.isGroupFirst){
				return reVal;
			}else{
				return "";
			}
	}
	return reVal;
}


/**
 * 全选
 * */
protected function selAll_changeHandler(event:Event):void
{
	for each (var item:Object in gridListCount.dataProvider)
	{
		item.isSelected = this.selAll.selected;
		ListCollectionView(gridListCount.dataProvider).itemUpdated(item, "isSelected");
	}
}


/**
 * 根据autoId集合，汇总明细数据
 * */
public function findSendMaterialTotal(autoIds:Array):void{
	
	if(!autoIds|| autoIds.length == 0 )
	{
		gridListCount.dataProvider = null;
		return;
	}
	var ro:RemoteObject = RemoteUtil.getRemoteObject(DESTANATION,function(rev:Object):void{
		if(rev.data && rev.data.length>0) 
		{
			gridListCount.dataProvider = rev.data;
		}
	});
	ro.findSendMaterialTotal(autoIds,'0');
}



public function getSelectedAutoIds():Array{
	var faryIds:Array = [];
	var faryGridMaster:ArrayCollection = gridListCount.dataProvider as ArrayCollection;
	for each(var item:Object in faryGridMaster){
		if(item.isSelected){
			faryIds.push(item.autoId);
		}
	}
	return faryIds;
}





