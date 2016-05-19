import cn.superion.base.components.controls.TextInputIcon;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.util.MainToolBar;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;

[Bindable]
public var currentStatusArray:ArrayCollection=new ArrayCollection([{currentStatus: null, currentStatusName: '全部'}, {currentStatus: '0', currentStatusName: '新建状态'}, {currentStatus: '1', currentStatusName: '审核状态'}, {currentStatus: '2', currentStatusName: '执行状态'}]);
//数据来源
[Bindable]
public var dataSourceArray:ArrayCollection=new ArrayCollection([{dataSource: null, dataSourceName: '全部'},{ dataSource: '1',  dataSourceName: '计划编制'}, { dataSource: '2',  dataSourceName: '采购请购'}]);

public var data:Object;
private var _tempSalerCode:String;
private var _tempDeptCode:String;
private var _tempMaterialClass:String;
private var _tempMaterialCode:String;
public var iparentWin:Object = null;
//条件对象
private var _condition:Object={};


/**
 * 初始化
 * */
protected function doInit():void
{
	fillForm();
//	initTextInputIcon();
	dataSource.setFocus();
	
}

/**
 * 填充表单
 * */
private function  fillForm():void{
	FormUtils.fillFormByItem(this,_condition);
	fillTextInputIcon(deptCode);
	fillTextInputIcon(salerCode);
}

private function fillTextInputIcon(fctrl:Object):void{
	fctrl.text=_condition[fctrl.id+"Name"];
}
/**
 * 部门档案字典
 * */
protected function deptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict((function(rev:Object):void
	{
		_tempDeptCode=rev.deptCode;
		deptCode.txtContent.text=rev.deptName;
	}), x, y);
}

/**
 * 供应商档案字典
 * */
protected function productCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict((function(rev:Object):void
	{
		salerCode.txtContent.text=rev.providerName;
		_tempSalerCode=rev.providerId;
	}), x, y);
}

/**
 *物资分类字典
 **/
protected function materialClass_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialClassDict((function(rev:Object):void
	{
		materialClass.txtContent.text=rev.className;
		_tempMaterialClass=rev.classCode;
	}), x, y);
}

/**
 *物资档案字典
 **/
protected function materialName_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict((function(rev:Object):void
	{
		materialName.txtContent.text=rev.materialName;
		_tempMaterialCode=rev.materialName;
	}), x, y);
}


/**
 * 处理回车键转到下一个控件
 * */
public static function toNextControl(e:KeyboardEvent, fcontrolNext:Object, th:Object):void
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
				if (fcontrolNext.className == "DropDownList")
				{
					fcontrolNext.openDropDown();
					fcontrolNext.setFocus();
					return;
				}
				if (fcontrolNext.className == "DateField")
				{
					fcontrolNext.open();
					fcontrolNext.setFocus();
					return;
				}
				if (fcontrolNext.className == "TextInputIcon")
				{
					fcontrolNext.txtContent.setFocus();
					return
				}
				else
				{
					fcontrolNext.setFocus();
					return
				}
			}
		}
		else
		{
			if (fcontrolNext.className == "DropDownList")
			{
				fcontrolNext.openDropDown();
				fcontrolNext.setFocus();
				return;
			}
			if (fcontrolNext.className == "DateField")
			{
				fcontrolNext.open();
				fcontrolNext.setFocus();
				return;
			}
			if (fcontrolNext.className == "TextInputIcon")
			{
				fcontrolNext.txtContent.setFocus();
			}
			else
			{
				fcontrolNext.setFocus();
			}
		}
	}
}

/**
 *确认按钮回车事件处理方法
 **/
protected function btConfirm_keyUpHandler(event:KeyboardEvent):void
{
	if (event.keyCode == Keyboard.ENTER)
	{
		btQuery_clickHandler();
	}
}

/**
 *取消按钮
 **/
protected function cancel_clickHandler(event:MouseEvent):void
{
	PopUpManager.removePopUp(this);
}

/**
 *确认查询事件处理方法
 **/
protected function btQuery_clickHandler():void
{
	var paramQuery:ParameterObject=new ParameterObject();
	_condition['beginBillNo']=billNoFrom.text;
	_condition['endBillNo']=billNoTo.text;
	if (isBillDate.selected)
	{
		_condition['beginBillDate']=billDateFrom.selectedDate;
		_condition['endBillDate']=MainToolBar.addOneDay(billDateTo.selectedDate);
	}
	else
	{
		_condition['beginBillDate']=null;
		_condition['endBillDate']=null;
	}
	_condition['dataSource']=dataSource.selectedItem.dataSource;
	_condition['materialName']=_tempMaterialCode == null ? materialName.txtContent.text : _tempMaterialCode;
	_condition['materialCode']=materialCode.text == "" ? null : materialCode.text;
	_condition['beginTradePrice']=(tradeMoneyFrom.text == "" ? null : (Number)(tradeMoneyFrom.text));
	_condition['endTradePrice']=(tradeMoneyTo.text == "" ? null : (Number)(tradeMoneyTo.text));
	_condition['currentStatus']=currentStatus.selectedItem.currentStatus;
	_condition['materialClass']=_tempMaterialClass == null ? materialClass.txtContent.text : _tempMaterialClass;
	//供应商
	_condition['salerCode']=_tempSalerCode == null ? salerCode.txtContent.text : _tempSalerCode;
	_condition['salerCodeName']=salerCode.txtContent.text == null ? null : salerCode.txtContent.text;
	//部门
	_condition['deptCode']=_tempDeptCode == null ? deptCode.txtContent.text : _tempDeptCode;
	_condition['deptCodeName']=deptCode.txtContent.text == null ? null : deptCode.txtContent.text;
	paramQuery.conditions=_condition;
	iparentWin.salerName = salerCode.txtContent.text;
	PopUpManager.removePopUp(this);
	data.parentWin.dgDrug.reQuery(paramQuery);
}