// ActionScript file
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.LoadModuleUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.util.MainToolBar;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.modules.ModuleLoader;
import mx.rpc.remoting.RemoteObject;

public var typeArc:ArrayCollection=BaseDict.buyOperationTypeDict;
[Bindable]
private var currentStatusArray:ArrayCollection=new ArrayCollection([{currentStatus: '0', currentStatusName: '新建状态'}, {currentStatus: '1', currentStatusName: '审核状态'}, {currentStatus: '2', currentStatusName: '执行状态'}, {currentStatus: '3', currentStatusName: '关闭状态'}]);

private var paramsObj:Object={};

public var data:Object;
private var destination:String="orderImpl";

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
}

protected function doInit(event:FlexEvent):void
{
	salerCode.txtContent.editable=false;
	deptCode.txtContent.editable=false;
	personId.txtContent.editable=false;
}

/**
 * 按回车跳转
 */ 
private function keyUpCtrl(e:KeyboardEvent, fcontrolNext:*):void
{
	if (e.keyCode == Keyboard.ENTER)
	{
		if (fcontrolNext is TextInputIcon && !(e.currentTarget is TextInputIcon))
		{
			fcontrolNext.txtContent.setFocus()
			return;
		}
		if (e.currentTarget is TextInputIcon)
		{
			if (e.currentTarget.text == "")
			{
				if (e.currentTarget.id == "salerCode")
				{
					salerCode_queryIconClickHandler();
					return;
				}
				if (e.currentTarget.id == "deptCode")
				{
					deptCode_queryIconClickHandler();
					return;
				}
				if (e.currentTarget.id == "personId")
				{
					personId_queryIconClickHandler();
					return;
				}
			}
			if (fcontrolNext is TextInputIcon)
			{
				fcontrolNext.txtContent.setFocus()
				return;
			}
		}
		if (fcontrolNext.className == "DateField")
		{
			fcontrolNext.open();
			fcontrolNext.setFocus()
			return;
		}
		fcontrolNext.setFocus()
	}
}

/**
 * 供应商字典
 * */
protected function salerCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict(function(item:Object):void
		{
			salerCode.txtContent.text=item.providerName;
			paramsObj['salerCode']=item.providerId;
		}, x, y);
}

/**
 * 部门字典
 * */
protected function deptCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(item:Object):void
		{
			deptCode.txtContent.text=item.deptName;
			paramsObj['deptCode']=item.deptCode;
		}, x, y);
}

/**
 * 业务员字典
 * */
protected function personId_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict(function(item:Object):void
		{
			personId.txtContent.text=item.personIdName;
			paramsObj['personId']=item.personId;
		}, x, y);
}

/**
 * 取消
 */ 
protected function cancel_clickHandler():void
{
	PopUpManager.removePopUp(this);
}

/**
 * 查询
 */ 
protected function btQuery_clickHandler(event:Event):void
{
	var params:Object=FormUtils.getFields(queryPanel, []);
	params['operationType']=operationType.selectedItem.operationType;
	if (!billDate.selected)
	{
		params['beginBillDate']=null;
		params['endBillDate']=null;
	}else{
		params['beginBillDate'] = beginBillDate.selectedDate;
		params['endBillDate'] = MainToolBar.addOneDay(endBillDate.selectedDate);
	}
	if (paramsObj['deptCode'])
	{
		params['deptCode']=paramsObj['deptCode'];
	}
	if (paramsObj['personId'])
	{
		params['personId']=paramsObj['personId'];
	}
	if (paramsObj['salerCode'])
	{
		params['salerCode']=paramsObj['salerCode'];
	}
	var paramsQuery:ParameterObject=new ParameterObject();
	paramsQuery.conditions=params;
	cancel_clickHandler();
	var ro:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
		{
			if(rev.data.length<=0)
			{
				Alert.show("没有相关数据","提示");
				data.parentWin.clearForm();
				data.parentWin.doInit();
				return;
			}		
			data.parentWin.arrayAutoId=	ArrayCollection(rev.data).toArray();;
			data.parentWin.findRdsById(rev.data[0]);
			setToolBarPageBts(rev.data.length);
		});
	ro.findOrderByCondition(paramsQuery);
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
/**
 * 业务类型，调用字典
 */ 
protected function ddlStorageName_creationCompleteHandler(event:FlexEvent):void
{
	for each (var item:Object in typeArc)
	{
		if (item.operationTypeName == '')
		{
			typeArc.removeItemAt(typeArc.getItemIndex(item))
		}
	}
	operationType.selectedIndex=0;
	operationType.dataProvider=typeArc;
}