// ActionScript file
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.base.util.StringUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.util.MainToolBar;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.events.CloseEvent;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.mxml.RemoteObject;

public var data:Object;
public var enAry:Array=[];
private var _tempDeptCode:String;
private var _tempMaterialCode:String;
[Bindable]
public var fIdArray:ArrayCollection=new ArrayCollection();
private var destination:String='invoiceImpl';

//初始化
protected function doInit(event:FlexEvent):void
{
	deptCode.txtContent.restrict="^ ";
	materialCode.txtContent.restrict="^ ";
	operationType.dataProvider=BaseDict.operationTypeDict;
	invoiceType.dataProvider=BaseDict.invoiceTypeDict;
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
				if (th.id == "deptCode")
				{
					deptCode_queryIconClickHandler();
				}
				if (th.id == "materialCode")
				{
					materialCode_queryIconClickHandler();
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
	// TODO Auto-generated method stub
	PopUpManager.removePopUp(this);
}

//查询
protected function btConfirm_clickHandler():void
{
	var params:Object=FormUtils.getFields(purchaseInvoiceQuery, []);
	if (operationType.selectedItem != null && operationType.selectedIndex > -1)
	{
		params['operationType']=operationType.selectedItem.operationType;
	}
	if (invoiceType.selectedItem != null && invoiceType.selectedIndex > -1)
	{
		params['invoiceType']=invoiceType.selectedItem.invoiceType;
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
	params['deptCode']=_tempDeptCode == null ? deptCode.txtContent.text : _tempDeptCode;
	params['materialCode']=_tempMaterialCode == null ? materialCode.txtContent.text : _tempMaterialCode;
	params['beginTradePrice']=beginTradePrice.text == "" ? null : parseFloat(beginTradePrice.text);
	params['endTradePrice']=endTradePrice.text == "" ? null : parseFloat(endTradePrice.text);
	params['billType']=billType.selectedItem?billType.selectedItem.billType:null;
	if (currentStatus.selectedItem != null && currentStatus.selectedIndex > -1)
	{
		params['currentStatus']=currentStatus.selectedItem.currentStatus;
	}
	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions=params;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
		{
		if(rev.data.length<=0)
		{
			Alert.show("没有相关数据","提示");
			data.parentWin.doInit();
			data.parentWin.clearForm();
			return;
		}		
		data.parentWin.arrayAutoId=	ArrayCollection(rev.data).toArray();;
		data.parentWin.findRdsById(rev.data[0]);
		setToolBarPageBts(rev.data.length);
		});
	ro.findMaterialInvoiceByCondition(paramQuery);
	//关闭查询框
	PopUpManager.removePopUp(this);
}
/**
 * 设置当前按钮是否显示
 */
private function setToolBarPageBts(flenth:int):void
{
	data.parentWin.toolBar.queryToPreState()
	
	if (flenth < 2)
	{
		data.parentWin.toolBar.btFirstPage.enabled=false
		data.parentWin.toolBar.btPrePage.enabled=false
		data.parentWin.toolBar.btNextPage.enabled=false
		data.parentWin.toolBar.btLastPage.enabled=false
		return;
	}
	data.parentWin.toolBar.btFirstPage.enabled=false
	data.parentWin.toolBar.btPrePage.enabled=false
	data.parentWin.toolBar.btNextPage.enabled=true
	data.parentWin.toolBar.btLastPage.enabled=true
}
protected function changeHandler(event:Event):void
{
	// TODO Auto-generated method stub
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

//部门字典
protected function deptCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(rev:Object):void
		{
			deptCode.txtContent.text=rev.deptName;
			_tempDeptCode=rev.deptCode;
		}, x, y);
}

//物资编码字典
protected function materialCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict(function(rev:Object):void
		{
			materialCode.txtContent.text=rev.materialCode;
			_tempMaterialCode=rev.materialCode;
		}, x, y);
}

protected function btConfirm_keyUpHandler(event:KeyboardEvent):void
{
	if (event.keyCode == Keyboard.ENTER)
	{
		btConfirm_clickHandler();
	}
}