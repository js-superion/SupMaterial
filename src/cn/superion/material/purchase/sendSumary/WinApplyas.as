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

private var _fparameter:Object={flag:"1"};
/**
 * 初始化当前窗口
 * */
public function doInit():void
{
	preventDefaultForm();
	
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

	salerCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
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
	}, winY, y);
}




/**
 * 保存
 */
protected function saveClickHandler(event:Event):void
{
	
	
	if(!gridDetailList.dataProvider)
	{
		return
	}
	//控制供货单位必选
	if(salerCode.txtContent.text == ''){
		Alert.show("供货商必须选择", "提示");
		return;
	}
	
	var master:MaterialSupplierSummary = new MaterialSupplierSummary();
	master.storageCode = storageCode.selectedItem.storageCode;
	master.providerCode = _fparameter["mainProvider"];
	master.providerName = salerCode.txtContent.text;
	var tempAry:ArrayCollection = gridListCount.dataProvider as ArrayCollection;
	var newAry:ArrayCollection = new ArrayCollection();
	
	for each(var item:Object in tempAry){
		var detail:MaterialSupplierDetail = new MaterialSupplierDetail();
		detail.materialClass = item.materialClass;
		detail.materialCode = item.materialCode;
		detail.materialName = item.materialName;
		detail.materialSpec = item.materialSpec;
		detail.materialUnits = item.materialUnits;
		detail.serialNo = item.rowNo;
		detail.tradeMoney = item.tradeMoney;
		detail.tradePrice = item.tradePrice;
		newAry.addItem(detail);
	}	
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			Alert.show("保存成功", "提示");
		});
	ro.saveSumary(master,newAry);
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
	
	_fparameter.currentStatus ='1'//过滤病区审核过的申请单
	_fparameter.checkAmountSign ='1';
	_fparameter.checkSupplySign = '1';
	_fparameter.storageCode = storageCode.selectedItem?storageCode.selectedItem.storageCode:null;
	param.conditions = _fparameter
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		gridMasterList.dataProvider = rev.data;
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
				if(!it.sendAmount)
				{
					it.sendAmount = it.amount;
				}
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





