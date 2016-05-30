/**
 *		 配送处理
 *		 作者: 朱旋 2013.08.28
 *		 修改：
 **/
import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.GridColumn;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
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
import cn.superion.vo.material.CdDeptLimit;
import cn.superion.vo.material.MaterialPlanDetail;
import cn.superion.vo.material.MaterialPlanMaster;
import cn.superion.vo.material.MaterialProvideDetail;
import cn.superion.vo.material.MaterialProvideMaster;

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

private static const MENU_NO:String="0109";
public var DESTANATION:String="sendImpl";
private var winY:int=0;
private var seasonArray:ArrayCollection = new ArrayCollection([{"month":"1","season":"1"},{"month":"2","season":"1"},{"month":"3","season":"1"},
	{"month":"4","season":"2"},{"month":"5","season":"2"},{"month":"6","season":"2"},
	{"month":"7","season":"3"},{"month":"8","season":"3"},{"month":"9","season":"3"},
	{"month":"10","season":"4"},{"month":"11","season":"4"},{"month":"12","season":"4"}]);
//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;

private var _fparameter:Object={flag:"1"};
/**
 * 初始化当前窗口
 * */
public function doInit():void
{
//	if(parentDocument is WinModual){
//		parentDocument.title="采购申请处理";
//	}
//	//重新注册客户端对应的服务端类
//	registerClassAlias("cn.superion.material.entity.MaterialPlanMaster", MaterialPlanMaster);
//	registerClassAlias("cn.superion.material.entity.MaterialPlanDetail", MaterialPlanDetail);
	
	//放大镜不可手动输入
	preventDefaultForm();
	initPanel();
	initToolBar();
	if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
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
	}
}


/**
 * 面板初始化
 */
private function initPanel():void
{
	if (BaseDict.buyOperationTypeDict != null && BaseDict.buyOperationTypeDict.length > 0)
	{
//		stockType.dataProvider=BaseDict.buyOperationTypeDict;
//		stockType.selectedIndex=0;
	}
	setReadOnly(false);

//	personId.width=stockType.width;
//	requierDate.width=materialCode.width;
//	adviceBookDate.width=materialCode.width;
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp,toolBar.btExcel, toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, toolBar.btSave, toolBar.btVerify, toolBar.btAddRow, toolBar.btDelRow, toolBar.btQuery, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.btExit, toolBar.imageList1, toolBar.imageList2, toolBar.imageList3, toolBar.imageList5, toolBar.imageList6];
	var laryEnables:Array=[toolBar.btQuery,toolBar.btVerify, toolBar.btExit];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	//FormUtils.setFormItemEditable(allPanel, boolean);
//	addPanel.visible=boolean;
//	addPanel.includeInLayout=boolean;
//	stockType.enabled=boolean;
}
public var _autoId:String = null;
/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	deptCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
		{
			e.preventDefault();
		})

	materialCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
		{
			e.preventDefault();
		})
}
public function removeDataByAutoId():void{
	//获取明细表格中的所有数据
	var details:ArrayCollection = gridDetailList.dataProvider as ArrayCollection;
	for (var i:int =0;i<details.length;i++){
		if(details[i].mainAutoId == _autoId){
			details.removeItemAt(i);
			gridDetailList.dataProvider = details;
			removeDataByAutoId();
			
		}
	}
}
/**
 * 清空表单
 */
public function clearForm(masterFlag:Boolean, detailFlag:Boolean):void
{
	if (masterFlag)
	{
		//清空主记录
		clearMaster();
	}
	if (detailFlag)
	{
		//清空明细
		clearDetail();
	}
}

/**
 * 清空明细
 */
private function clearDetail():void
{
//	FormUtils.clearForm(addPanel);
//	requierDate.selectedDate=new Date;
//	adviceBookDate.selectedDate=new Date;
}

/**
 * 清空主记录
 */
public function clearMaster():void
{
//	FormUtils.clearForm(allPanel);
//	stockType.selectedIndex=0;
//	gridDetail.dataProvider=null;
//	requierDate.selectedDate=new Date;
//	adviceBookDate.selectedDate=new Date;
//	billDate.selectedDate=new Date;
//	_materialPlanMaster=new MaterialPlanMaster();
}

/**
 * 回车事件
 **/
private function toNextControl(event:KeyboardEvent, fctrlNext:Object):void
{
	FormUtils.toNextControl(event, fctrlNext);
}

/**
 * 数量key事件
 */
protected function amountKey(e:KeyboardEvent, fcontrolNext:*):void
{
//	if (e.keyCode == Keyboard.ENTER)
//	{
//		if (!gridDetail.selectedItem)
//		{
//			return;
//		}
//		if ((gridDetail.selectedItem.amount) <= 0)
//		{
//			return;
//		}
//		fcontrolNext.setFocus();
//	}
}

/**
 *  明细表备注回车事件
 */
protected function remarkDetail_keyUpHandler(event:KeyboardEvent):void
{
//	if (event.keyCode == Keyboard.ENTER)
//	{
//		if (!gridDetail.selectedItem)
//		{
//			return;
//		}
//		if (gridDetail.selectedItem.amount <= 0)
//		{
//			Alert.show("数量不能小于或等于零!", "提示", Alert.YES, null, huiCallback);
//			return;
//		}
//		//先清空“增加面板addPanel”
//		FormUtils.clearForm(panel1);
//		adviceBookDate.selectedDate=new Date;
//		requierDate.selectedDate=new Date;
//		salerCode.text="";
//		detailRemark.text="";
//		materialCode.txtContent.setFocus();
//	}
}

/**
 * 数量不符合时回调
 */
public function huiCallback(rev:CloseEvent):void
{
//	if (rev.detail == Alert.YES)
//	{
//		amount.setFocus();
//		return;
//	}
}

/**
 * 物资编码KeyUp事件
 */
protected function materialCode_keyUpHandler(event:KeyboardEvent):void
{
//	// TODO Auto-generated method stub
//	if (event.keyCode != Keyboard.ENTER)
//	{
//		return;
//	}
//	if (materialCode.text == "")
//	{
//		materialCode_queryIconClickHandler(event);
//	}
//	else
//	{
//		amount.setFocus();
//	}
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
			materialCode.text = faryItems[0].materialName;
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
	}, winY, y);
}

/**
 * 自动完成表格回调
 * */
private function fillIntoGrid(fItem:Array):void
{
//	amount.setFocus();
//	
//	var laryDetails:ArrayCollection=gridDetail.dataProvider as ArrayCollection;
//	//放大镜取出的值、赋值
//	for(var i:int=0;i<fItem.length;i++)
//	{
//		var materialPlanDetail:MaterialPlanDetail=new MaterialPlanDetail();
//		materialPlanDetail=fillDetailForm(fItem[i]);
//		laryDetails.addItem(materialPlanDetail);
//	}
//	gridDetail.dataProvider=laryDetails;
//	gridDetail.selectedIndex=laryDetails.length - 1;
}


/**
 * 给主记录赋值
 */
private function fillRdsMaster():void
{
//	_materialPlanMaster.operationType=stockType.selectedItem == false ? null : stockType.selectedItem.operationType;
//	_materialPlanMaster.billNo=billNo.text == "" ? null : billNo.text;
//	_materialPlanMaster.billDate=billDate.selectedDate;
//	_materialPlanMaster.remark=remark.text == "" ? null : remark.text;
//	_materialPlanMaster.dataSource="2";
//	_materialPlanMaster.totalCosts=0;
//
//	var lstBloodRdsDetail:ArrayCollection=gridDetail.dataProvider as ArrayCollection;
//	for (var i:int=0; i <= lstBloodRdsDetail.length - 1; i++)
//	{
//		_materialPlanMaster.totalCosts=_materialPlanMaster.totalCosts + Number(lstBloodRdsDetail[i].tradeMoney);
//	}
}

/**
 * 所有Change事件
 */
protected function evaluate_changeHandler(event:Event):void
{
//	if (!gridDetail.selectedItem)
//	{
//		return;
//	}
//	gridDetail.selectedItem.detailRemark=detailRemark.text;
//	gridDetail.selectedItem.requireDate=requierDate.selectedDate as Date;
//	gridDetail.selectedItem.adviceBookDate=adviceBookDate.selectedDate as Date;
//	gridDetail.selectedItem.amount=Number(amount.text);
//	gridDetail.selectedItem.tradePrice=Number(tradePrice.text);
//	gridDetail.selectedItem.tradeMoney=((Number)(amount.text)) * ((Number)(tradePrice.text)) as Number;
//	gridDetail.selectedItem.retailMoney=((Number)(amount.text)) * ((Number)(gridDetail.selectedItem.retailPrice)) as Number;
//	gridDetail.invalidateList();
}

protected function gridDetail_clickHandler(event:MouseEvent):void
{
//	// TODO Auto-generated method stub
//	if (!gridDetail.selectedItem)
//	{
//		return;
//	}
//	FormUtils.fillFormByItem(addPanel, gridDetail.selectedItem);
//	var salerCodeObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict, 'provider', salerCode.text);
//	salerCode.text=salerCodeObj == null ? null : salerCodeObj.providerName;
}

/**
 * 填充当前表单
 */
protected function gdItems_itemClickHandler(event:ListEvent):void
{
	// TODO Auto-generated method stub
	//FormUtils.fillFormByItem(addPanel, gridDetail.selectedItem);
}

//打印
protected function printClickHandler(event:Event):void
{
	printReport("1");

}

//输出
protected function expClickHandler(event:Event):void
{
	printReport("0");

}


private function initDeptLimit(year:String,season:String,deptCode:String):void{
	
	
	var param:ParameterObject=new ParameterObject();
	var _fparameter:Object = {};
	_fparameter.deptCode =deptCode;// deptCode.selectedItem?deptCode.selectedItem.deptCode:""
	_fparameter.years = year;
	_fparameter.season =season;
	param.conditions = _fparameter
	//是否显示三位小数。
	var rod:RemoteObject=RemoteUtil.getRemoteObject('sendImpl', function(rev:Object):void
	{
		seasonLimit.text = usedLimit.text = remainLimit.text = '';
		if(rev.data && rev.data.length>0){
			var limit:CdDeptLimit = rev.data[0]
			seasonLimit.text = limit.limits;
			usedLimit.text = limit.addUp;
			remainLimit.text = (limit.limits - limit.addUp).toString();
		}
		
	});
	rod.findDeptLimitInfo(year,season,deptCode);
	
}


public function deptCode_changeHandler(item:MaterialProvideMaster):void
{
	// TODO Auto-generated method stub
	var currentYear:String = DateUtil.dateToString(new Date(),"YYYY");
	var currentMonth:String = DateUtil.dateToString(new Date(),"MM");
	var index:int = Number(currentMonth) - 1;
	var season:String = seasonArray[index].season;
	var code:String = item.deptCode;;
	initDeptLimit(currentYear,season,code);
}


//导出
protected function excelClickHandler(event:Event):void
{
	//DefaultPage.makeExport(gridDetail,"采购申请统计表");
}

/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
//	var _dataList:ArrayCollection=gridDetail.dataProvider as ArrayCollection;
//	var dict:Dictionary=new Dictionary();
//	preparePrintData(_dataList);
//	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
//	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
//	dict["主标题"]="采购申请处理";
//	dict["制表人"]=AppInfo.currentUserInfo.userName;
//	dict["单据编号"]=billNo.text;
//	dict["单据日期"]=DateField.dateToString(DateField.stringToDate(billDate.text, "YYYY-MM-DD"), "YYYY-MM-DD");
//	dict["制单人"]=maker.text;
//	dict["审核人"]=verifier.text;
//	if (printSign == '1')
//		ReportPrinter.LoadAndPrint("report/material/purchase/purchaseApply.xml", _dataList, dict);
//	if (printSign == '0')
//		ReportViewer.Instance.Show("report/material/purchase/purchaseApply.xml", _dataList, dict);
}

/**
 * 保存
 */
protected function saveClickHandler(event:Event):void
{
	//保存权限
//	if (!checkUserRole('04'))
//	{
//		return;
//	}
	
//	toolBar.btSave.enabled=false;
	
	if(!gridDetailList.dataProvider)
	{
		return
	}
	
	var tempAry:ArrayCollection = gridDetailList.dataProvider as ArrayCollection;
	var newAry:ArrayCollection = new ArrayCollection();
	for each(var item:Object in tempAry){
		var materialProvideDetail:MaterialProvideDetail = new MaterialProvideDetail();
		materialProvideDetail = MainToolBar.classTransfer(item,materialProvideDetail);
		newAry.addItem(materialProvideDetail);
	}	
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			initToolBar();
			Alert.show("保存成功", "提示");
		});
	ro.updateSendMaterial(null,newAry);
}


/**
 * 更具数据状态显示不同的按钮
 */
protected function stateButton(currentStatus:String):void
{
	var state:Boolean=(currentStatus == "1" ? false : true);
	toolBar.btAdd.enabled=true;
	toolBar.btModify.enabled=state;
	toolBar.btDelete.enabled=state;
	toolBar.btVerify.enabled=state;
	toolBar.btPrint.enabled=true;
	toolBar.btExp.enabled=true;
	toolBar.btExcel.enabled=true;
}


import spark.events.IndexChangeEvent;
import mx.events.IndexChangedEvent;

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
//	if (!checkUserRole('06'))
//	{
//		return;
//	}
	if(!gridMasterList.dataProvider)
	{
		return;
	}
	var tempAry:ArrayCollection = gridMasterList.dataProvider as ArrayCollection;
	var newAry:ArrayCollection = new ArrayCollection();
	for each(var item:Object in tempAry){
		if(item.isSelected){
			var materialProvideMaster:MaterialProvideMaster = new MaterialProvideMaster();
			materialProvideMaster = MainToolBar.classTransfer(item,materialProvideMaster);
//			materialProvideMaster.sendStatus='2';
//			if(materialProvideMaster.currentStatus=='2'){
//				Alert.show("请选择审核主记录", "提示");
//				return
//			}else{
				
				materialProvideMaster.currentStatus='2';
				
//			}
			
			newAry.addItem(materialProvideMaster);
		}
	}
	if(newAry.length == 0){
		Alert.show("请选择审核主记录", "提示");
		return
	}
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		initToolBar();
		Alert.show("审核成功", "提示");
		queryClickHandler(null);
	});
	ro.updateSendMaterialMaster(newAry);
}




protected function cancelClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	if(!gridMasterList.dataProvider)
	{
		return;
	}
	var tempAry:ArrayCollection = gridMasterList.dataProvider as ArrayCollection;
	var newAry:ArrayCollection = new ArrayCollection();
	for each(var item:Object in tempAry){
		if(item.isSelected){
			var materialProvideMaster:MaterialProvideMaster = new MaterialProvideMaster();
			materialProvideMaster = MainToolBar.classTransfer(item,materialProvideMaster);
			newAry.addItem(materialProvideMaster);
		}
	}
	if(newAry.length == 0){
		Alert.show("请选择主记录", "提示");
		return
	}
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		initToolBar();
		queryClickHandler(null);
		Alert.show("弃审成功", "提示");
	});
	ro.updateSendMaterialMaster3(newAry,"1");
}


import spark.events.GridItemEditorEvent;

protected function gridDetailList_gridItemEditorSessionStartingHandler(event:GridItemEditorEvent):void
{
	// TODO Auto-generated method stub
	//if(status.selectedItem.k =='2'){
	//未审核（处理）的可以修改，其它状态不让改
	if(status.selectedItem.k !='1'){
		event.preventDefault();
	}
}

protected function storageCode_changeHandler(event:IndexChangeEvent):void
{
	// TODO Auto-generated method stub
	queryClickHandler(null);
}

/**
 * 查询
 */
protected function queryClickHandler(event:Event):void
{
	selAll.selected = false;
	gridListCount.dataProvider = null;
	gridDetailList.dataProvider = null
	var param:ParameterObject=new ParameterObject();
	_fparameter.deptCode = deptCode.txtContent.text == ''?null:_fparameter.deptCode;
	_fparameter.materialCode = materialCode.txtContent.text == ''?null:_fparameter.materialCode;
	//_fparameter.mainProvider = salerCode.txtContent.text == ''?null:_fparameter.mainProvider;
	_fparameter.manualSign ='0'//过滤病区审核过的申请单
	_fparameter.fromDate = fromDate.text;
	_fparameter.toDate = toDate.text;
	_fparameter.detailRemark = detailRemark.text;
	_fparameter.storageCode = storageCode.selectedItem?storageCode.selectedItem.storageCode:null;
	_fparameter.currentStatus = status.selectedItem?status.selectedItem.k:"1,2,3,4,5";
	param.conditions = _fparameter
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		gridMasterList.dataProvider = rev.data;
		if(_fparameter.currentStatus == '1'){
			toolBar.btCancel.enabled = false;
			toolBar.btVerify.enabled = true;
		}else if(_fparameter.currentStatus=='2'){
			toolBar.btCancel.enabled = true;
			toolBar.btVerify.enabled = false;
		}else{
			toolBar.btCancel.enabled = false;
			toolBar.btVerify.enabled = false;
		}
	});
	ro.findSendMaterialEntityListByCondition(param);
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
		reVal  = (gridMasterList.dataProvider.getItemIndex(item)+1).toString();
	}
	if (column.headerText == '日期')
	{
		var fmt:DateTimeFormatter = new DateTimeFormatter();
		fmt.dateTimePattern = "yyyy-MM-dd";
		reVal = fmt.format(item.billDate);
	}
	if (column.dataField == 'personId')
	{
		var person:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', item.personId);
		if (!person)
		{
			item.personName = "";
		}
		else
		{
			item.personName=person.personIdName;
		}
		reVal = item.personName
	}
	if (column.dataField == 'deptCode')
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
	}
	if (column.headerText == '供应单位')
	{
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
	}
	return reVal;
}

private function labFunDetail(item:Object,column:spark.components.gridClasses.GridColumn):String
{
	var reVal:String = "";
	if (column.headerText == '序号')
	{
		reVal  = (gridDetailList.dataProvider.getItemIndex(item)+1).toString();
	}
	if (column.headerText == '供应商')
	{
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
	}
	return reVal;
}


protected function tabnavigator1_changeHandler(event:IndexChangedEvent):void
{
	// TODO Auto-generated method stub
	if(event.newIndex ==1){
		var selectedAutoIds:Array =getSelectedAutoIds();
		findSendMaterialTotal(selectedAutoIds);
	}
	
}


/**
 * 全选
 * */
protected function selAll_changeHandler(event:Event):void
{
	for each (var item:Object in gridMasterList.dataProvider)
	{
		item.isSelected = this.selAll.selected;
		ListCollectionView(gridMasterList.dataProvider).itemUpdated(item, "isSelected");
	}
	findDetailByMainAutoIds(getSelectedAutoIds());
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
/**
 * 单击事件
 * */
public function findDetailByMainAutoId(selectItem:Object):void
{
	var ro:RemoteObject = RemoteUtil.getRemoteObject(DESTANATION,function(rev:Object):void{
		if(rev.data && rev.data.length>0) 
		{
			var revData:ArrayCollection = rev.data[0];
			for each(var it:Object in revData){
				it.wardName = selectItem.deptName;
//				if(it.sendAmount=='' || it.sendAmount ==null)
//				{
//					it.sendAmount = it.amount;
//				}
			}
			var ary:ArrayCollection = null;
			if(gridDetailList.dataProvider){
				ary = gridDetailList.dataProvider;
			}else{
				ary = new ArrayCollection();
			}
			
			gridDetailList.dataProvider = ary;
			ary.addAll(revData);
			return;
		}
	});
	ro.findSendDetailByAutoIdAndOtherCons(gridMasterList.selectedItem.autoId,'0');
}

public function findDetailByMainAutoIds(autoIds:Array):void
{
	if(!autoIds|| autoIds.length == 0 )
	{
		gridListCount.dataProvider = null;
		gridDetailList.dataProvider = null
		return;
	}
	var ro:RemoteObject = RemoteUtil.getRemoteObject(DESTANATION,function(rev:Object):void{
		
		if(rev.data && rev.data.length>0) 
		{
			for each(var item:Object in rev.data)
			{
				if(!item.sendAmount)
				{
					item.sendAmount = item.amount;
				}
				for each(var item1:Object in gridMasterList.dataProvider)
				{
					if(item.mainAutoId == item1.autoId)
					{
						var deptItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', item1.deptCode);
						if (!deptItem)
						{
							item.wardName = '';
						}
						else
						{
							item.wardName=deptItem.deptName;
						}
						
						break;
					}
				}
			}
			gridDetailList.dataProvider = rev.data;
		}else{
			gridDetailList.dataProvider = null
		}
	});
	ro.findDetailByMainAutoIds(autoIds,'0');
	findSendMaterialTotal(autoIds);
}

public function getSelectedAutoIds():Array{
	var faryIds:Array = [];
	var faryGridMaster:ArrayCollection = gridMasterList.dataProvider as ArrayCollection;
	for each(var item:Object in faryGridMaster){
		if(item.isSelected){
			faryIds.push(item.autoId);
		}
	}
	return faryIds;
}





