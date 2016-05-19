import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.stat.stockAccountStat.ModStockAccountStat;
import cn.superion.material.util.MaterialDictShower;

import flash.events.MouseEvent;

import flexlib.scheduling.util.DateUtil;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

public var parentWin:ModStockAccountStat;
private  var _condition:Object={};



private function doInit():void
{
	initComBox();
	initTextInputIcon();
	fillForm();		
}

/**
 * 初始化ComboBox
 */ 
private function initComBox():void
{
//	storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
	var result:ArrayCollection =ObjectUtil.copy(AppInfo.currentUserInfo.storageList) as ArrayCollection;
	var newArray:ArrayCollection = new ArrayCollection();
	for each(var it:Object in result){
		if(it.type == '2'||it.type == '3'){
			newArray.addItem(it);
		}
	}
	storageCode.dataProvider=newArray;//AppInfo.currentUserInfo.storageList;
	storageCode.selectedIndex=0;
	storageCode.textInput.editable=false;
}

/**
 * 填充表单
 **/
private function  fillForm():void{
	FormUtils.fillFormByItem(this,_condition);
	fillTextInputIcon(deptCode);
	fillTextInputIcon(factoryCode);
}

private function fillTextInputIcon(fctrl:Object):void{
	fctrl.text=_condition[fctrl.id+"Name"];
}

/**
 * 初始化放大镜输入框
 **/
private function initTextInputIcon():void{
	deptCode.txtContent.editable=false;
	personId.txtContent.editable=false;
	factoryCode.txtContent.editable=false;
	beginMaterialCode.txtContent.editable=false;
	endMaterialCode.txtContent.editable=false;
}

/**
 * 部门字典
 **/ 
protected function deptCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict((function(rev:Object):void
	{
		if(rev.data)
		{
			deptCode.txtContent.text=rev.deptName;
			_condition['deptCodeName']=rev.deptName;
			_condition['deptCode']=rev.deptCode;
		}

	}), x, y);
}

/**
 * 业务员字典
 **/ 
protected function personId_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict((function(rev:Object):void
	{
		personId.txtContent.text=rev.personIdName;
		_condition['personId']=rev.personId;
	}), x, y);
}

/**
 * 生产厂家字典
 **/ 
protected function factoryCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict((function(rev:Object):void
	{
		factoryCode.txtContent.text=rev.providerName;
		_condition['factoryCodeName']=rev.providerName;
		_condition['factoryCode']=rev.providerId;
	}), x, y);
}

/**
 * 物资编码
 */ 
protected function materialCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	var storageCode:String = storageCode.selectedItem?storageCode.selectedItem.storageCode : null;
	MaterialDictShower.showMaterialDict(storageCode,(function(rev:Object):void
	{
		event.target.text=rev.materialCode;
		_condition[event.target.id]=rev.materialCode;
		endMaterialCode.txtContent.text=rev.materialCode;
		_condition["endMaterialCode"]=rev.materialCode;
	}), x, y);
}

/**
 * 处理回车键转到下一个控件
 **/ 
private function toNextControl(e:KeyboardEvent, fcontrolNext:*):void
{
	FormUtils.toNextControl(e,fcontrolNext);
}

/**
 * 放大镜键盘事件处理方法
 * */
protected function queryIcon_keyUpHandler(event:KeyboardEvent,fcontrolNext:Object):void
{
	FormUtils.textInputIconKeyUpHandler(event,_condition,fcontrolNext);
}

protected function btConfirm_clickHandler(event:MouseEvent):void
{
	//仓库
	if (storageCode.selectedItem != null && storageCode.selectedIndex > -1)
	{
		_condition['storageCode']=storageCode.selectedItem.storageCode;
	}
	_condition['billNo']=billNo.text==""?null:billNo.text;
	//单据日期
	if (isBillDate.selected)
	{	
		_condition['beginBillDate']=beginBillDate.selectedDate;
		_condition['endBillDate'] = addOneDay(endBillDate.selectedDate);
	}
	else
	{
		_condition['beginBillDate']=null;
		_condition['endBillDate']=null;
	}
	
	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions=_condition;
	PopUpManager.removePopUp(this);
	
	var ro:RemoteObject=RemoteUtil.getRemoteObject(parentWin.DESTINATION, function(rev:Object):void
	{
		if (rev.data && rev.data.length > 0)
		{
			var fIdArray:ArrayCollection=new ArrayCollection();
			fIdArray=rev.data;
			parentWin.arrayAutoId=ArrayCollection(rev.data).toArray();
			setToolBarPageBts(rev.data.length);
			parentWin.iObjConditon=paramQuery;
			parentWin.getDataByAutoId(fIdArray[0]);
			return;
		}
		else
		{
			parentWin.initToolBar();
			parentWin.exitAll();
		}
	});
	ro.findStockAccountListByCondition(paramQuery);
}

/**
 * 设置当前按钮是否显示
 */
private function setToolBarPageBts(flenth:int):void
{
	parentWin.toolBar.queryToPreState();
	
	if (flenth < 2)
	{
		parentWin.toolBar.btFirstPage.enabled=false
		parentWin.toolBar.btPrePage.enabled=false
		parentWin.toolBar.btNextPage.enabled=false
		parentWin.toolBar.btLastPage.enabled=false
		return;
	}
	parentWin.toolBar.btFirstPage.enabled=false
	parentWin.toolBar.btPrePage.enabled=false
	parentWin.toolBar.btNextPage.enabled=true
	parentWin.toolBar.btLastPage.enabled=true
}

/**
 * 给指定日期+(24*3600*1000-1000);
 * */
private function addOneDay(date:Date):Date
{
	return DateUtil.addTime(new Date(date), DateUtil.DAY_IN_MILLISECONDS - 1000);
}

/**
 * 取消按钮事件响应方法
 **/
protected function closeWin():void
{
	PopUpManager.removePopUp(this);
}

/**
 * 退出
 */
protected function btReturn_clickHandler(event:MouseEvent):void
{
	PopUpManager.removePopUp(this);
}