import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.base.util.StringUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.list.deliverList.ModDeliverList;
import cn.superion.material.util.MainToolBar;
import cn.superion.material.util.MaterialDictShower;

import com.adobe.utils.StringUtil;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

[Bindable]
private var currentStatusArray:ArrayCollection=new ArrayCollection([{currentStatus: null, currentStatusName: '全部'}, {currentStatus: '0', currentStatusName: '新建状态'}, {currentStatus: '1', currentStatusName: '审核状态'},{currentStatus: '2', currentStatusName: '记账状态'}]);
private var params:Object=new Object();
public var enAry:Array=[];
public var data:Object;
public var parentWin:ModDeliverList;

private var _tempDeptCode:String;
private var _tempFactoryCode:String;
private var _tempPersonId:String;
private var _tempBeginMaterialCode:String;
private var _tempEndMaterialCode:String;

/**
 * 初始化
 * */
protected function doInit():void
{
	storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
	//业务类型
	operationType.dataProvider = new ArrayCollection([{operationType:null,operationTypeName:'全部'},
		{operationType:'201',operationTypeName:'领用出库'},
		{operationType:'202',operationTypeName:'销售出库'},
		{operationType:'203',operationTypeName:'调拨出库'},
		{operationType:'204',operationTypeName:'盘亏出库'},
		{operationType:'205',operationTypeName:'报损出库'},
		{operationType:'209',operationTypeName:'其他出库'}]);
	fillForm();
	unitsCode.dataProvider = MaterialDictShower.SYS_UNITS;//加载泰州南北院的信息
//	unitsCode.requireSelection = true;
}

/**
 * 填充表单
 * */
private function  fillForm():void{
	FormUtils.fillFormByItem(this,params);
	fillTextInputIcon(factoryCode);
	fillTextInputIcon(deptCode);
}

private function fillTextInputIcon(fctrl:Object):void{
	fctrl.text=params[fctrl.id+"Name"];
}
protected function date_changeHandler(event:Event):void
{
	if (chkBillDate.selected)
	{
		beginBillDate.enabled=true;
		endBillDate.enabled=true;
	}
	else
	{
		beginBillDate.enabled=false;
		endBillDate.enabled=false;
	}
}

/**
 * 生产厂家档案字典
 * */
protected function factoryCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict((function(rev:Object):void
	{
		factoryCode.txtContent.text=rev.providerName;
		params['factoryCode']=rev.providerId;
	}), x, y);
}

/**
 * 部门档案字典
 * */
protected function deptCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	MaterialDictShower.showDeptDict((function(rev:Object):void
	{
		deptCode.txtContent.text=rev.deptName;
		params['deptCode']=rev.deptCode;
	}), x, y);
}

/**
 * 物资档案字典
 * */
protected function beginMaterialCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	var storageCode:String = storageCode.selectedItem?storageCode.selectedItem.storageCode : null;
	MaterialDictShower.showMaterialDict(storageCode,(function(rev:Object):void
	{
		beginMaterialCode.txtContent.text=rev.materialCode;
		params['beginMaterialCode']=rev.materialCode;
	}), x, y);
}

protected function endMaterialCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	var storageCode:String = storageCode.selectedItem?storageCode.selectedItem.storageCode : null;
	MaterialDictShower.showMaterialDict(storageCode,(function(rev:Object):void
	{
		endMaterialCode.txtContent.text=rev.materialCode;
		params['endMaterialCode']=rev.materialCode;
	}), x, y);
}

/**
 * 业务员字典/人员档案字典
 * */
protected function personId_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict((function(rev:Object):void
	{
		personId.txtContent.text=rev.personIdName;
		params['personId']=rev.personId;
	}), x, y);
}


/**
 * 查询按钮
 * */
protected function btQuery_clickHandler():void
{
//	var params:Object=new Object();
	var paramQuery:ParameterObject=new ParameterObject();
	// 仓库编码
	if (storageCode.selectedItem != null && storageCode.selectedIndex > -1)
	{
		params["storageCode"]=storageCode.selectedItem.storageCode;
	}
	// 业务类型
	if (operationType.selectedItem != null && operationType.selectedIndex > -1)
	{
		params['operationType']=operationType.selectedItem.operationType;
	}
	// 出库单号
	params["beginBillNo"]=beginBillNo.text;
	params["endBillNo"]=endBillNo.text;
	// 领用部门
	params['deptCodeName']=deptCode.txtContent.text;
	// 生产厂家
	params['factoryCodeName']=factoryCode.txtContent.text;
	// 物资编码
//	params['beginMaterialCode']=_tempBeginMaterialCode == null ? beginMaterialCode.txtContent.text : _tempBeginMaterialCode;
//	params['endMaterialCode']=_tempEndMaterialCode == null ? endMaterialCode.txtContent.text : _tempEndMaterialCode;
	// 当前状态
	if (currentStatus.selectedItem != null && currentStatus.selectedIndex > -1)
	{
		params['currentStatus']=currentStatus.selectedItem.currentStatus;
	}
	// 出库日期
	if (chkBillDate.selected)
	{
		// 开始出库日期
		params['beginBillDate']=beginBillDate.selectedDate;
		// 结束出库日期
		params['endBillDate']=MainToolBar.addOneDay(endBillDate.selectedDate);
	}
	else
	{
		params['beginBillDate']=null;
		params['endBillDate']=null;
	}
	params['deptUnitsCode']=StringUtil.trim(unitsCode.textInput.text).length == 0 ? null:unitsCode.selectedItem.unitsCode,
	//物资编码
	params['beginMaterialCode'] = StringUtil.trim(beginMaterialCode.txtContent.text).length == 0 ? null:beginMaterialCode.txtContent.text;
	params['endMaterialCode'] = StringUtil.trim(endMaterialCode.txtContent.text).length == 0 ? null:endMaterialCode.txtContent.text;
	paramQuery.conditions=params;
	data.parentWin.dgDeliverBillList.reQuery(paramQuery);
}


/**
 * 取消按钮
 * */
protected function cancel_clickHandler(event:MouseEvent):void
{
	PopUpManager.removePopUp(this);
}


/**
 * 处理回车事件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:*, th:*):void
{
	if (e.keyCode == Keyboard.ENTER)
	{
		if (th.className == "TextInputIcon")
		{
			if (th.txtContent.text == "" || th.txtContent.text == null)
			{
				th.dispatchEvent(new Event("queryIconClick"));
				return
			}
			else
			{
				if (fcontrolNext.className == "DateField")
				{
					fcontrolNext.open();
					fcontrolNext.setFocus();
					return;
				}
				if (fcontrolNext.className == "DropDownList")
				{
					fcontrolNext.openDropDown();
					fcontrolNext.setFocus();
					return;
				}
				if (fcontrolNext.className == "TextInputIcon")
				{
					fcontrolNext.txtContent.setFocus();
					return;
				}
				fcontrolNext.setFocus();
			}
		}
		else
		{
			if (fcontrolNext.className == "DateField")
			{
				fcontrolNext.open();
				fcontrolNext.setFocus();
				return;
			}
			if (fcontrolNext.className == "DropDownList")
			{
				fcontrolNext.openDropDown();
				fcontrolNext.setFocus();
				return;
			}
			if (fcontrolNext.className == "TextInputIcon")
			{
				fcontrolNext.txtContent.setFocus();
				return;
			}
			fcontrolNext.setFocus();
		}
	}
}

/**
 * 处理确定按钮的回车事件
 * */
protected function btConfirm_keyUpHandler(event:KeyboardEvent):void
{
	if (event.keyCode == Keyboard.ENTER)
	{
		btQuery_clickHandler();
	}
}