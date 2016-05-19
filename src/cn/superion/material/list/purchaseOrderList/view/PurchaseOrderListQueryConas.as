import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.StringUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.list.purchaseOrderList.ModPurchaseOrderList;
import cn.superion.material.util.MainToolBar;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;

public var disAry:Array=[];

public var parentWin:ModPurchaseOrderList;

private var destination:String="orderListImpl";

[Bindable]
private var currentStatusArray:ArrayCollection=new ArrayCollection([{currentStatus: null, currentStatusName: '全部'}, {currentStatus: '0', currentStatusName: '新建状态'}, {currentStatus: '1', currentStatusName: '审核状态'}, {currentStatus: '2', currentStatusName: '执行状态'}]);
private var paramsObj:Object={};
public var data:Object;
private var  params:Object=new Object();

private var _tempDeptCode:String;
private var _tempSalerCode:String;
private var _tempFactoryCode:String;
private var _tempMaterialCode:String;
private var _tempMaterialClass:String;
public var iparentWin:Object = null;

private function doInit():void
{
//	operationType.dataProvider=BaseDict.operationTypeDict;
	beginBillNo.setFocus();
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
 * 供应商字典
 * */
protected function salerCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict((function(item:Object):void
	{
		salerCode.txtContent.text=item.providerName;
		_tempSalerCode=item.providerId;
	}), x, y);
}

/**
 * 部门字典
 * */
protected function deptCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict((function(item:Object):void
	{
		deptCode.txtContent.text=item.deptName;
		_tempDeptCode=item.deptCode;
	}), x, y);
}

/**
 * 物资分类字典
 * */
protected function materialClass_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialClassDict((function(item:Object):void
	{
		materialClass.txtContent.text=item.className;
		_tempMaterialClass=item.classCode;
	}), x, y);
}

/**
 * 物资档案字典
 * */
protected function materialName_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict((function(item:Object):void
	{
		materialName.txtContent.text=item.materialName;
		_tempMaterialCode=item.materialName;
	}), x, y);
}

/**
 * 生产厂家字典
 * */
protected function factoryCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict((function(rev:Object):void
	{
		factoryCode.txtContent.text=rev.providerName;
		_tempFactoryCode=rev.providerId;
	}), x, y);
}

/**
 * 取消按钮
 * */
protected function cancel_clickHandler(event:MouseEvent):void
{
	PopUpManager.removePopUp(this);
}

/**
 * 查询按钮
 * */
protected function btQuery_clickHandler():void
{
	
	var paramQuery:ParameterObject=new ParameterObject();
	//单据日期
	if (chkBillDate.selected)
	{
		params['beginBillDate']=beginBillDate.selectedDate;
		// 结束单据日期
		params['endBillDate']=MainToolBar.addOneDay(endBillDate.selectedDate);;
	}
	else
	{
		params['beginBillDate']=null;
		params['endBillDate']=null;
	}
	
	// 单据编号
	params["beginBillNo"]=StringUtils.Trim(beginBillNo.text);
	params["endBillNo"]=StringUtils.Trim(endBillNo.text);
	// 部门
	params['deptCode']=_tempDeptCode == null ? deptCode.txtContent.text : _tempDeptCode;
	params['deptCodeName']=deptCode.txtContent.text == null ? null : deptCode.txtContent.text;
	// 物资分类
	params["materialClass"]=_tempMaterialClass == null ? materialClass.txtContent.text : _tempMaterialClass;
	params['materialCode']=materialCode.text == "" ? null : materialCode.text;
	
	// 物资名称
	params['materialName']=_tempMaterialCode == null ? materialName.txtContent.text : _tempMaterialCode;
	
	// 进价
	params["beginTradePrice"]=beginTradePrice.text == "" ? null : parseFloat(beginTradePrice.text);
	params["endTradePrice"]=endTradePrice.text == "" ? null : parseFloat(endTradePrice.text);
	// 供应单位
	params['salerCode']=_tempSalerCode == null ? salerCode.text : _tempSalerCode;
	params['salerCodeName']=salerCode.txtContent.text == null ? null : salerCode.txtContent.text;
	// 计划到货日期
	if (chkArriveDate.selected)
	{
		params['beginPlanArriveDate']=beginArriveDate.selectedDate;
		params['endPlanArriveDate']=MainToolBar.addOneDay(endArriveDate.selectedDate);
	}
	else
	{
		params['beginPlanArriveDate']=null;
		params['endPlanArriveDate']=null;
	}
	
	// 生产厂家
	params['factoryCode']=_tempFactoryCode == null ? factoryCode.txtContent.text : _tempFactoryCode;
	params['factoryCodeName']=factoryCode.txtContent.text == null ? null : factoryCode.txtContent.text;
	// 当前状态
	if (currentStatus.selectedItem != null && currentStatus.selectedIndex > -1)
	{
		params['currentStatus']=currentStatus.selectedItem.currentStatus;
	}
	paramQuery.conditions=params;
	iparentWin.salerName = salerCode.txtContent.text;
	PopUpManager.removePopUp(this);
	data.parentWin.dgOrderList.reQuery(paramQuery);
}

/**
 * 日期
 * */
protected function chkBillDate_changeHandler(event:Event):void
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
	if (chkArriveDate.selected)
	{
		beginArriveDate.enabled=true;
		endArriveDate.enabled=true;
	}
	else
	{
		beginArriveDate.enabled=false;
		endArriveDate.enabled=false;
	}
}

/**
 * 处理键的keyUp事件
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

protected function btConfirm_keyUpHandler(event:KeyboardEvent):void
{
	if (event.keyCode == Keyboard.ENTER)
	{
		btQuery_clickHandler();
	}
}