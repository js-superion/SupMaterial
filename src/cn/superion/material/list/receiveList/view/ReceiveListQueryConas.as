import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.util.MainToolBar;
import cn.superion.material.util.MaterialDictShower;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;
import mx.validators.NumberValidator;

[Bindable]
private var currentStatusArray:ArrayCollection=new ArrayCollection([{currentStatus:null,currentStatusName:'全部'},{currentStatus: '0', currentStatusName: '新建状态'}, {currentStatus: '1', currentStatusName: '审核状态'},{currentStatus: '2', currentStatusName: '记账状态'}]);
private var _tempSalerCode:String;
private var _tempDeptCode:String;
private var _tempPersonId:String;
private var _tempMaterialCode:String;
private var _tempFactoryCode:String;
private var destination:String='receiveListImpl';	
public var data:Object;
//条件对象
private var  params:Object=new Object();

/**
 * 初始化
 * */
protected function doInit():void
{
	storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
	storageCode.setFocus();
	//业务类型
	operationType.dataProvider = new ArrayCollection([{operationType:null,operationTypeName:'全部'},
		{operationType:'101',operationTypeName:'普通采购'},
		{operationType:'102',operationTypeName:'受托代销'},
		{operationType:'103',operationTypeName:'直运'},
		{operationType:'104',operationTypeName:'盘盈入库'},
		{operationType:'105',operationTypeName:'期初入库'},
		{operationType:'106',operationTypeName:'特殊入库'},
		{operationType:'109',operationTypeName:'其他入库'}]);
	fillForm();
}

/**
 * 填充表单
 * */
private function  fillForm():void{
	FormUtils.fillFormByItem(this,params);
	fillTextInputIcon(deptCode);
	fillTextInputIcon(salerCode);
	fillTextInputIcon(factoryCode);
}

private function fillTextInputIcon(fctrl:Object):void{
	fctrl.text=params[fctrl.id+"Name"];
}
/**
 * 日期
 * */
protected function date_changeHandler(event:Event):void
{
	if (billDate.selected)
	{
		beginBillDate.enabled=true;
		endBillDate.enabled=true;
	}
	else
	{
		beginBillDate.enabled=false;
		endBillDate.enabled=false;
	}
	
	if (availDate.selected)
	{
		beginAvailDate.enabled=true;
		endAvailDate.enabled=true;
	}
	else
	{
		beginAvailDate.enabled=false;
		endAvailDate.enabled=false;
	}
}

/**
 * 查找
 * */
protected function btQuery_clickHandler():void
{
	
//	var params:Object=FormUtils.getFields(queryPanel, []);
	var paramQuery:ParameterObject=new ParameterObject();
	if (storageCode.selectedItem != null && storageCode.selectedIndex > -1)
	{
		params['storageCode']=storageCode.selectedItem.storageCode;
	}
	if (operationType.selectedItem != null && operationType.selectedIndex > -1)
	{
		params['operationType']=operationType.selectedItem.operationType;
	}
	if (currentStatus.selectedItem != null && currentStatus.selectedIndex > -1)
	{
		params['currentStatus']=currentStatus.selectedItem.currentStatus;
	}
	
	params['beginTradePrice']=beginTradePrice.text == "" ? null : Number(beginTradePrice.text);
	params['endTradePrice']=endTradePrice.text == "" ? null : Number(endTradePrice.text);
	
	if (billDate.selected)
	{
		params['beginBillDate']=beginBillDate.selectedDate;
		params['endBillDate']=MainToolBar.addOneDay(endBillDate.selectedDate);
	}
	else
	{
		params['beginBillDate']=null;
		params['endBillDate']=null;
	}
	if (availDate.selected)
	{
		params['endAvailDate']=MainToolBar.addOneDay(endAvailDate.selectedDate);
	}
	else
	{
		params['beginAvailDate']=null;
		params['endAvailDate']=null;
	}
	// 供应单位
	params['salerCode']=_tempSalerCode == null ? salerCode.text : _tempSalerCode;
	params['salerCodeName']=salerCode.txtContent.text == null ? null : salerCode.txtContent.text;
	// 部门
	params['deptCode']=_tempDeptCode == null ? deptCode.txtContent.text : _tempDeptCode;
	params['deptCodeName']=deptCode.txtContent.text == null ? null : deptCode.txtContent.text;
	// 生产厂家
	params['factoryCode']=_tempFactoryCode == null ? factoryCode.txtContent.text : _tempFactoryCode;
	params['factoryCodeName']=factoryCode.txtContent.text == null ? null : factoryCode.txtContent.text;
	
	params['personId']=_tempPersonId == null ? personId.txtContent.text : _tempPersonId;
	params['materialCode']=_tempMaterialCode == null ? materialCode.txtContent.text : _tempMaterialCode;
//	params['factoryCode']=_tempFactoryCode == null ? factoryCode.txtContent.text : _tempFactoryCode;
	paramQuery.conditions=params;
	data.parentWin.dgReceiveList.reQuery(paramQuery);
	
}

/**
 *供应单位档案字典
 */
protected function salerCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict((function(rev:Object):void
	{
		salerCode.txtContent.text=rev.providerName;
		_tempSalerCode=rev.providerId;
	}),x,y);
}

/**
 *部门档案字典
 */
protected function deptCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict((function(rev:Object):void
	{
		deptCode.txtContent.text=rev.deptName;
		_tempDeptCode=rev.deptCode;
	}),x,y);
}

/**
 *人员档案字典
 */
protected function personId_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict((function(rev:Object):void
	{
		personId.txtContent.text=rev.personIdName;
		_tempPersonId=rev.personId;
	}),x,y);
}

/**
 *物资档案字典
 */
protected function materialCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	var storageCode:String = storageCode.selectedItem?storageCode.selectedItem.storageCode : null;
	MaterialDictShower.showMaterialDict(storageCode,(function(rev:Object):void
	{
		materialCode.txtContent.text=rev.materialName;
		_tempMaterialCode=rev.materialCode;
	}),x,y);
}

/**
 *生产厂家字典
 */
protected function factoryCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict((function(rev:Object):void
	{
		factoryCode.txtContent.text=rev.providerName;
		_tempFactoryCode=rev.providerId;
	}),x,y);
}

/**
 * 取消按钮
 * */
protected function btCancel_clickHandler(event:Event):void
{
	PopUpManager.removePopUp(this);
}


/**
 * 处理回车事件
 * */
private function toNextControl(event:KeyboardEvent, fcontrolNext:*, th:*):void
{
	if (event.keyCode == Keyboard.ENTER)
	{
		if (th is TextInputIcon)
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
 * 确定按钮的回车事件
 * */
protected function btConfirm_keyUpHandler(event:KeyboardEvent):void
{
	if (event.keyCode == Keyboard.ENTER)
	{
		btQuery_clickHandler();
	}
}