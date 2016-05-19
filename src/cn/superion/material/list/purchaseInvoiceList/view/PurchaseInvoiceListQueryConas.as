import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.util.MainToolBar;

import mx.collections.ArrayCollection;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

public var data:Object;
//条件对象
private static var  params:Object=new Object();

private var _tempSalerCode:String;
private var _tempDeptCode:String;
private var _tempPersonId:String;
private var _tempMaterialCode:String;
private var _tempFactoryCode:String;
private var destination:String="invoiceListImpl";
public var iparentWin:Object = null;
//初始化
protected function doInit():void
{
	operationType.dataProvider=BaseDict.buyOperationTypeDict;
	operationType.setFocus();
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

//回车跳转事件
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

//取消
protected function btReturn_clickHandler(event:MouseEvent):void
{
	PopUpManager.removePopUp(this);
}

//确定
protected function btConfirm_clickHandler():void
{
//	var params:Object=FormUtils.getFields(purchaseInvoiceListQuery, []);
	var paramQuery:ParameterObject=new ParameterObject();
	//单据编号
	params['beginBillNo']=beginBillNo.text;
	params['endBillNo']=endBillNo.text;
	//发票号
	params['beginInvoiceNo']=beginInvoiceNo.text;
	params['endInvoiceNo']=endInvoiceNo.text;	
	if (operationType.selectedItem != null && operationType.selectedIndex > -1)
	{
		params['operationType']=operationType.selectedItem.operationType;
	}
	//单据日期
	if (chkBillDate.selected)
	{
		params['beginBillDate']=dfStartDate.selectedDate;
		params['endBillDate']=MainToolBar.addOneDay(dfEndDate.selectedDate);
	}
	else
	{
		params['beginBillDate']=null;
		params['endBillDate']=null;
	}
	//发票日期
	if (chkInvoiceDate.selected)
	{
		params['beginInvoiceDate']=dfInvoiceStartDate.selectedDate;
		params['endInvoiceDate']=MainToolBar.addOneDay(dfInvoiceEndDate.selectedDate);
	}
	else
	{
		params['beginInvoiceDate']=null;
		params['endInvoiceDate']=null;
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
	
	//进价范围
	params['beginTradePrice']=beginTradePrice.text == "" ? null : parseFloat(beginTradePrice.text);
	params['endTradePrice']=endTradePrice.text == "" ? null : parseFloat(endTradePrice.text);
	//当前状态
	if (currentStatus.selectedItem != null && currentStatus.selectedIndex > -1)
	{
		params['currentStatus']=currentStatus.selectedItem.currentStatus;
	}
	paramQuery.conditions=params;
	iparentWin.salerName = salerCode.txtContent.text;
	PopUpManager.removePopUp(this);
	data.parentWin.gdPurchaseInvoiceList.reQuery(paramQuery);
}

protected function chkBillDate_changeHandler(event:Event):void
{
	if (chkBillDate.selected)
	{
		dfStartDate.enabled=true;
		dfEndDate.enabled=true;
	}
	else
	{
		dfStartDate.enabled=false;
		dfEndDate.enabled=false;
	}
	if (chkInvoiceDate.selected)
	{
		dfInvoiceStartDate.enabled=true;
		dfInvoiceEndDate.enabled=true;
	}
	else
	{
		dfInvoiceStartDate.enabled=false;
		dfInvoiceEndDate.enabled=false;
	}
}

//供应单位字典
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

//部门字典
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

//业务员字典
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

//物资编码字典
protected function materialCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict((function(rev:Object):void
	{
		materialCode.txtContent.text=rev.materialName;
		_tempMaterialCode=rev.materialCode;
	}),x,y);
}

//生产厂家字典
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

protected function btConfirm_keyUpHandler(event:KeyboardEvent):void
{
	if (event.keyCode == Keyboard.ENTER)
	{
		btConfirm_clickHandler();
	}
}
