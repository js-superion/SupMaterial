/**
 *		 
 **/

import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.base.util.StringUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.util.MainToolBar;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

public var parentWin:*;

private var _destination:String="rdTogetherImpl";
private var paramsObj:Object={};


protected function doInit():void
{
	//授权仓库赋值 
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
	//业务类型
	operationType.dataProvider=new ArrayCollection([{operationType: null, operationTypeName: '全部'}, {operationType: '101', operationTypeName: '普通采购'}, {operationType: '102', operationTypeName: '受托代销'}, {operationType: '103', operationTypeName: '直运'},{operationType: '210', operationTypeName: '整进整出'}]);
	operationType.selectedIndex=0;

	//入库类别
	rdType.txtContent.editable=false;

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

protected function rdType_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showReceiveTypeDict(function(item:Object):void
	{
		rdType.txtContent.text=item.rdName;
		paramsObj['rdType']=item.rdCode;
	}, x, y);
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
 * 物资字典
 */
protected function materialCode_queryIconClickHandler(event:Event):void
{
	//打开物资字典
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 338;
	
	var lstorageCode:String='';
	lstorageCode=(storageCode.selectedItem || {}).storageCode;
	//	lstorageCode = lstorageCode.substr(0,2);
	DictWinShower.showMaterialDictNew(lstorageCode, '', '', true, function(fItem:Array):void
	{
		materialCode.txtContent.text=fItem[0].materialName;
		paramsObj['materialCode']=fItem[0].materialCode;
	}, x, y,"1");
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

	if (operationType.selectedItem)
	{
		params['operationType']=operationType.selectedItem.operationTypeCode;
	}
	if (paramsObj['rdType'])
	{
		params['rdType']=paramsObj['rdType'];
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
	if(paramsObj['materialCode']){
		params['materialCode']=paramsObj['materialCode'];
	}


	if (currentStatus.selectedItem)
	{
		params['currentStatus']=currentStatus.selectedItem.currentStatus;
	}
	if (printStatus.selectedItem)
	{
		params['printStatus']=printStatus.selectedItem.currentStatus;
	}
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
	if(beginBillNo.text != null && StringUtils.Trim(beginBillNo.text) != ''){
		if(endBillNo.text != null && StringUtils.Trim(endBillNo.text) != ''){
			params['beginBillNo'] = beginBillNo.text;
			params['endBillNo'] = endBillNo.text;
		}else{
			params['billNo'] = beginBillNo.text;
		}
	}
	
	if(cargoNo.text != null && StringUtils.Trim(cargoNo.text) != ''){
		params['cargoNo']=cargoNo.text;
	}
	if(rd1.selected){
		params['rdFlag']='1';
	}else{
		parentWin.ischen=true;
		params['rdFlag']='2';
	}
	params['remark']='整进整出';

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
	ro.findRdsMasterListByCondition(paramsQuery);
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