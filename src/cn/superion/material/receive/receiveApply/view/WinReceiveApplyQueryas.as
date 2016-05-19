/**
 *		 特殊入库申请查询查询条件窗体
 *		 author:周作建   2011.06.05
 *		 checked by：
 **/

import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.util.MainToolBar;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

public var parentWin:*;

private var _destination:String="applyImpl";
private var paramsObj:Object={};


protected function doInit():void
{
	//授权仓库赋值
	if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
	{
		storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
		storageCode.selectedIndex=0;
	}
	salerCode.txtContent.editable=false;
	deptCode.txtContent.editable=false;
	personId.txtContent.editable=false;
}

/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e, fcontrolNext);
}


protected function salerCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict(function(item:Object):void
	{
		salerCode.txtContent.text=item.providerName;
		paramsObj['salerCode']=item.providerId;
	}, x, y);
}

protected function deptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(item:Object):void
	{
		deptCode.txtContent.text=item.deptName;
		paramsObj['deptCode']=item.deptCode;
	}, x, y);
}

protected function personId_queryIconClickHandler(event:Event):void
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
 * 取消按钮事件响应方法
 * */
protected function closeWin():void
{
	PopUpManager.removePopUp(this);
}



protected function btConfirm_clickHandler(event:MouseEvent):void
{
	var params:Object={};

	if (storageCode.selectedItem)
	{
		params['storageCode']=storageCode.selectedItem.storageCode;
	}


	if (paramsObj['salerCode'])
	{
		params['salerCode']=paramsObj['salerCode'];
	}
	if (paramsObj['deptCode'])
	{
		params['deptCode']=paramsObj['deptCode'];
	}
	if (paramsObj['personId'])
	{
		params['personId']=paramsObj['personId'];
	}


	if (currentStatus.selectedItem)
	{
		params['currentStatus']=currentStatus.selectedItem.currentStatus;
	}
	if (billDate.selected)
	{
		params['beginBillDate']=beginBillDate.selectedDate;
		params['endBillDate'] = MainToolBar.addOneDay(endBillDate.selectedDate);
	}
	else
	{
		params['beginBillDate']=null;
		params['endBillDate']=null;
	}

	var paramsQuery:ParameterObject=new ParameterObject();
	paramsQuery.conditions=params;

	var ro:RemoteObject=RemoteUtil.getRemoteObject(_destination, function(rev:Object):void
	{
		if (rev.data && rev.data.length > 0)
		{
			parentWin.arrayAutoId=ArrayCollection(rev.data).toArray();

			parentWin.findRdsById(rev.data[0]);

			setToolBarPageBts(rev.data.length);
		}
		else
		{
			parentWin.doInit();
			//清空当前表单
			parentWin.clearForm(true, true);
		}
	});
	ro.findApplyListByCondition(paramsQuery);
	PopUpManager.removePopUp(this);
}

/**
 * 设置当前按钮是否显示
 */
private function setToolBarPageBts(flenth:int):void
{
	parentWin.toolBar.queryToPreState()

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
 * 取消
 */
protected function btReturn_clickHandler(event:MouseEvent):void
{
	PopUpManager.removePopUp(this);
}