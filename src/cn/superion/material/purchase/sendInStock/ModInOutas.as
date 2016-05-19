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
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.purchase.apply.view.PurchaseApplyQueryCon;
import cn.superion.material.purchase.plan.view.PurchaseChaseQueryCon;
import cn.superion.material.purchase.plan.view.PurchasePlanAuto;
import cn.superion.material.purchase.sendSumary.WinApply;
import cn.superion.material.purchase.sendSumary.WinApply2;
import cn.superion.material.util.DefaultPage;
import cn.superion.material.util.MainToolBar;
import cn.superion.material.util.ToolBar;
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
import flash.external.ExternalInterface;
import flash.sampler.startSampling;
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
import mx.events.IndexChangedEvent;
import mx.events.ListEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

import spark.components.gridClasses.GridColumn;
import spark.events.IndexChangeEvent;
import spark.events.TextOperationEvent;
import spark.formatters.DateTimeFormatter;

private static const MENU_NO:String="0106";
public var DESTANATION:String="sendImpl";
private var winY:int=0;

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



protected function status_changeHandler(event:IndexChangeEvent):void
{
	// TODO Auto-generated method stub
	queryClickHandler(null);
}

protected function tabnavigator1_changeHandler(event:IndexChangedEvent):void
{
	// TODO Auto-generated method stub
//	if(){
//		
//	}
	
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

}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btSum,toolBar.btExp,toolBar.btExcel, toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, toolBar.btSave, toolBar.btVerify, toolBar.btAddRow, toolBar.btDelRow, toolBar.btQuery, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.btExit, toolBar.imageList1, toolBar.imageList2, toolBar.imageList3, toolBar.imageList5, toolBar.imageList6];
	var laryEnables:Array=[toolBar.btQuery,toolBar.btPrint,toolBar.btExcel,toolBar.btVerify, toolBar.btExit];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
}
public var _autoId:String = null;
/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
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
}

/**
 * 清空主记录
 */
public function clearMaster():void
{
//	FormUtils.clearForm(allPanel);
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
//	}
}

/**
 *  明细表备注回车事件
 */
protected function remarkDetail_keyUpHandler(event:KeyboardEvent):void
{
//	if (event.keyCode == Keyboard.ENTER)
//	}
}

/**
 * 数量不符合时回调
 */
public function huiCallback(rev:CloseEvent):void
{
//	}
}

/**
 * 物资编码KeyUp事件
 */
protected function materialCode_keyUpHandler(event:KeyboardEvent):void
{
//	// TODO Auto-generated method stub
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
 * 自动完成表格回调
 * */
private function fillIntoGrid(fItem:Array):void
{
//	amount.setFocus();
}


/**
 * 给主记录赋值
 */
private function fillRdsMaster():void
{
//	_materialPlanMaster.operationType=stockType.selectedItem == false ? null : stockType.selectedItem.operationType;
//	}
}

/**
 * 所有Change事件
 */
protected function evaluate_changeHandler(event:Event):void
{
//	if (!gridDetail.selectedItem)
}

protected function gridDetail_clickHandler(event:MouseEvent):void
{
//	// TODO Auto-generated method stub
}

/**
 * 填充当前表单
 */
protected function gdItems_itemClickHandler(event:ListEvent):void
{
}

//打印
protected function printClickHandler(flag:String):void
{
//	printReport("1");
	var selectedItem:MaterialSupplierSummary = gridMasterList.selectedItem as MaterialSupplierSummary;
	if(!selectedItem){
		Alert.show("请点击一条记录！", "提示");
		return;
	}
	var map:Object={};
	map.intOrient = 1;
	map.pageWidth = 0;
	map.pageHeight = 0;
	map.pageName = "A4" ;
	map.hidePreviewPb = "0"; //隐藏预览窗口的打印按钮 
	//内容大小、方向
	map.top = "8mm";
	map.left = "10mm";
	map.width = "200mm";
	map.height = "297mm";
	
	map.printFlag = flag;
	map.jspName = "GroupSupply.jsp";
	
	map.createPerson = AppInfo.currentUserInfo.userName;
	map.deptName = AppInfo.currentUserInfo.deptName;
	map.dataProvider2 = gridGroupByDept.dataProvider;
	
	var date:Date = new Date();
	map.printDate = cn.superion.base.util.DateUtil.dateToString(date,'YYYY-MM-DD hh:mm:ss');
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION,function(rev:Object):void{
		ExternalInterface.call("PreviewOrExp",map);
		map.jspName = "GroupDept.jsp";
		ExternalInterface.call("PreviewOrExp",map);
		
	})
	ro.findPrintData(map);

}

private function groupList(lst:ArrayCollection):ArrayCollection{
	var temp:Object = {};
	temp.deptCode = null;
	for each(var it:Object in lst){
		it.isSelected = false;
		if(temp.deptCode==it.deptCode)
		{
			it.isGroupFirst = false;
		}else{
			it.isGroupFirst = true;
		}
		temp.deptCode = it.deptCode;
	}
	return lst;
}


protected function gridMasterList_itemClickHandler(event:ListEvent):void
{
	// TODO Auto-generated method stub
//	var item:MaterialSupplierSummary = gridMasterList.selectedItem as MaterialSupplierSummary;
//	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
//	{
//		
//		gridGroupByDept.dataProvider = groupList(rev.data[1]);
//	});
//	ro.findSupplierDetail(item.billNo);
	
	var item:MaterialSupplierSummary = gridMasterList.selectedItem as MaterialSupplierSummary;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		gridListCount.dataProvider = rev.data[0];
		
		gridGroupByDept.dataProvider = groupList(rev.data[1]);
	});
	ro.findSupplierDetail(item.billNo);
}

//输出
protected function expClickHandler(event:Event):void
{
	printReport("0");

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

/**
 * 生单
 */
protected function toolBar_sumClickHandler(event:Event):void
{
	//弹出过滤窗口
//	var win:WinApply = PopUpManager.createPopUp(this,WinApply,true) as WinApply;
	var win:WinApply2 = PopUpManager.createPopUp(this,WinApply2,true) as WinApply2;
	PopUpManager.centerPopUp(win);
}




private function groupList2(master:MaterialSupplierSummary,lst:ArrayCollection):ArrayCollection{
	var map:Object = {};
	var groupArray:ArrayCollection = new ArrayCollection();
	var detailArray:ArrayCollection = new ArrayCollection();
	map.deptCode = null;
	var storageCode1:String = storageCode.selectedItem.storageCode;
	for each(var it:Object in lst){
//		if(it.isSelected){
			if(map.deptCode==it.deptCode)
			{
				it.isGroupFirst = false;
				detailArray.addItem(it);
			}else{
				it.isGroupFirst = true;
				var groupItem:Object = {};
				detailArray = new ArrayCollection();
				detailArray.addItem(it);
				groupItem.billNo = master.billNo;
				groupItem.providerName =master.providerName;
				groupItem.providerCode =master.providerCode;
				groupItem.deptCode = it.deptCode;
				groupItem.storageCode = storageCode1;
				groupItem.detail = detailArray;
				groupArray.addItem(groupItem);
				
			}
			map.deptCode = it.deptCode;
//		}
		
	}
	return groupArray;
}


/**
 * 审核
 */
protected function verifyClickHandler(event:Event):void
{
	//审核权限
	if(!gridMasterList.dataProvider)
	{
		return;
	}
	if(gridGroupByDept.dataProvider.length ==0)
	{
		return;
	}
	var master:MaterialSupplierSummary =gridMasterList.selectedItem as MaterialSupplierSummary;
	if(!master){
		return;
	}
	if(master.checkSign=='1'){
		Alert.show("单据已审核", "提示");
		return;
	}
	var groupedDetails:ArrayCollection = gridGroupByDept.dataProvider as ArrayCollection;
	
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		initToolBar();
		Alert.show("审核成功", "提示");
		queryClickHandler(null);
	});
	ro.verifySupplyDetails(master.autoId,groupList2(master,groupedDetails));
}

/**
 * 查询
 */
protected function queryClickHandler(event:Event):void
{
//	selAll.selected = false;
	gridMasterList.dataProvider = null;
	gridGroupByDept.dataProvider =null;
	var param:ParameterObject=new ParameterObject();
	_fparameter.fromDate = fromDate.text;
	_fparameter.toDate = toDate.text;
	_fparameter.checkSign = status.selectedItem?status.selectedItem.k:null;
	_fparameter.storageCode = storageCode.selectedItem?storageCode.selectedItem.storageCode:null;
	param.conditions = _fparameter
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		if(rev.data){
			if(_fparameter.checkSign == '1'){
				toolBar.btVerify.enabled = false;
			}else{
				toolBar.btVerify.enabled = true;
			}
			gridMasterList.dataProvider = rev.data;
		}
		
	});
	ro.findSumary(param);
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
	if (column.dataField == 'rowNo')
	{
		reVal  = (gridGroupByDept.dataProvider.getItemIndex(item)+1).toString();
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
		
		if(item.isGroupFirst){
			return reVal;
		}else{
			return "";
		}
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



/**
 * 根据autoId集合，汇总明细数据
 * */
public function findSendMaterialTotal(autoIds:Array):void{
	
	if(!autoIds|| autoIds.length == 0 )
	{
		return;
	}
	var ro:RemoteObject = RemoteUtil.getRemoteObject(DESTANATION,function(rev:Object):void{
		if(rev.data && rev.data.length>0) 
		{
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
			return;
		}
	});
	ro.findSendDetailByAutoIdAndOtherCons(gridMasterList.selectedItem.autoId,'0');
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





