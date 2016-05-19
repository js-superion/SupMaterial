/**
 *		 物资领用申请过滤模块
 *		 作者:
 *		 修改：周作建 2011.06.08
 **/

import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.util.MainToolBar;
import cn.superion.material.util.MaterialDictShower;
import cn.superion.vo.material.MaterialProvideMaster;
import cn.superion.vo.material.MaterialRdsDetail;

import flash.net.SharedObject;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

import spark.events.TextOperationEvent;

public var parentWin:Object;
private var destination:String="deliverImpl";

private var _deptCode:String="";
private var isTanchu:Boolean=false;//保存后是否弹出增加界面。
private var shareObj:SharedObject = null;
protected function doInit():void
{
	this.title="领用申请单";
	shareObj=SharedObject.getLocal("shareObj");
	gridApplyMaster.grid.dataProvider = [];
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
		if(newArray.length>0){
			storageCode.dataProvider=newArray;//AppInfo.currentUserInfo.storageList;
			if(shareObj.data.selectedIndex){
				storageCode.selectedIndex = shareObj.data.selectedIndex;
			}else{
				storageCode.selectedIndex=0;
			}
			storageCode.selectedItem = newArray[storageCode.selectedIndex];
		}
	
		
	}
	isTanchu=ExternalInterface.call("getIsTanchu");
	if(isTanchu){
		beDate.selected = false;
	}else{
		beDate.selected = true;
	}
	//阻止表单输入
	preventDefaultForm();
	if(isTanchu){
		btQuery_clickHandler();
	}
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	dept.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
}


import spark.events.IndexChangeEvent;

protected function storageCode_changeHandler(event:IndexChangeEvent):void
{
	// TODO Auto-generated method stub
	shareObj.data.selectedIndex = event.newIndex;
}

/**
 * 部门字典
 */ 
protected function dept_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(rev:Object):void
	{
		dept.txtContent.text=rev.deptName;
		_deptCode=rev.deptCode;
	}, x, y);
}

/**
 * 回车事件
 **/
private function toNextCtrl(event:KeyboardEvent, fctrlNext:Object):void
{
	if (event.keyCode != Keyboard.ENTER)
	{
		return;
	}
	//
	FormUtils.toNextControl(event, fctrlNext);
}

/**
 * 查询
 * */
protected function btQuery_clickHandler():void
{
	gridApplyMaster.grid.dataProvider=null;
	gridApplyDetail.dataProvider=null;
	var params:Object=FormUtils.getFields(queryArea, []);
	var paramQuery:ParameterObject=new ParameterObject();
	params["storageCode"]=storageCode.selectedItem?storageCode.selectedItem.storageCode:"";
	if(beDate.selected){
		params["beginBillDate"]=beginBillDate.selectedDate;
		params["endBillDate"] = MainToolBar.addOneDay(endBillDate.selectedDate);
	}else{
		params["beginBillDate"]=null;
		params["endBillDate"] = null;
	}
	
	params["deptCode"]=_deptCode;
	params["billNo"]=billNo.text;
	paramQuery.page=1;
	paramQuery.itemsPerPage=50;
	paramQuery.conditions=params;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
	{
		if (rev == null || rev.data.length < 1)
		{
			
			return;
		}
		gridApplyMaster.grid.dataProvider=rev.data;
	});
	ro.findProvide(paramQuery);
}


/**
 * 确定
 * */
protected function btConfirmHandler(event:MouseEvent):void
{
	if(gridApplyDetail.dataProvider.length<=0)
	{
		return;
	}
	//取过滤窗口的明细，赋给页面
	var aryyList:ArrayCollection=gridApplyDetail.dataProvider as ArrayCollection;
	var laryRawData:ArrayCollection=MainToolBar.aryColTransfer(aryyList, MaterialRdsDetail);
	for each(var item:Object in laryRawData){
		item.checkAmount = item.amount; //实发数量默认 = 申请数量
	}
	data.win.gdProviderDetail.dataProvider=laryRawData;
	if(data.win._isDetailRemark){//byzcl
		data.win.gdProviderDetail.selectedIndex = 0;
		data.win.fillDetailForm1(data.win.gdProviderDetail.selectedItem);
	}
	
	//申领单位
	data.win._materialRdsMaster.unitsCode=gridApplyMaster.grid.selectedItem.unitsCode;//deptUnitsCode  //byzcl
	data.win._materialRdsMaster.deptCode=gridApplyMaster.grid.selectedItem.deptCode;
	data.win._materialRdsMaster.personId=gridApplyMaster.grid.selectedItem.personId;
	data.win._materialRdsMaster.operationNo=gridApplyMaster.grid.selectedItem.billNo; //
	data.win._materialRdsMaster.sourceAutoId=gridApplyMaster.grid.selectedItem.autoId; 
	
	
	data.win.applyInvoiveType=gridApplyMaster.grid.selectedItem.invoiceType;
	data.win.blueType.selected=gridApplyMaster.grid.selectedItem.invoiceType == '1'
	data.win.redType.selected=gridApplyMaster.grid.selectedItem.invoiceType == '2'
	
	FormUtils.selectComboItem(data.win.storageCode, "storageCode", storageCode.selectedItem.storageCode);
	data.win.storageCode.enabled="false";
	var dept:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, "dept", gridApplyMaster.grid.selectedItem.deptCode);
	var person:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, "personId", gridApplyMaster.grid.selectedItem.personId);
	data.win.deptCode.text=dept?dept.deptName:"";
	data.win.personId.text=person?person.personIdName:"";
	data.win.storageCode.enabled=false;
	data.win.barCode.setFocus();
	//显示输入明细区域
	if(data.win._isDetailRemark){
		data.win.bord.height=140;   //byzcl 111
		data.win.hiddenVGroup.includeInLayout=true;
		data.win.hiddenVGroup.visible=true;
	}
	
	PopUpManager.removePopUp(this);
}

/**
 * 生产厂家
 */
private function factoryLBF(item:Object, column:DataGridColumn):String
{
	if (item.factoryCode == '')
	{
		item.factoryName='';
	}
	else
	{
		var provider:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict, 'provider', item.factoryCode);

		item.factoryName=provider == null ? "" : provider.providerName;
	}
	return item.factoryName;
}
/**
 * 请领单位
 */ 
private function labelFunDeptUnitsCode(item:Object, column:DataGridColumn):*
{
	return displayName("deptUnitsCode", item.unitsCode); //当前 登陆人员所在的单位，如，南北院
}
/**
 * 请领部门
 */ 
private function labelFunDeptCode(item:Object, column:DataGridColumn):*
{
	return displayName("deptCode", item.deptCode);
}
/**
 * 请领人员
 */ 
private function labelFunPersonId(item:Object, column:DataGridColumn):*
{
	return displayName("personId", item.personId);
}

/**
 * 由编码显示名称
 */ 
private function displayName(item:*, txt:String):*
{
	var fItem:Object;
	//所属单位
	if (item == "deptUnitsCode")
	{
		var deptUnitsName:String = "";
		for each (var it:Object in MaterialDictShower.SYS_UNITS){
			if(it.unitsCode == txt){
				deptUnitsName = it.unitsSimpleName;
			}
		}
		return deptUnitsName;
	}
	//部门
	if (item == "deptCode")
	{
		fItem=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, "dept", txt);
		if (fItem)
		{
			return fItem.deptName;
		}
		return txt;
	}
	//业务员
	if (item == "personId")
	{
		fItem=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, "personId", txt);
		if (fItem)
		{
			return fItem.personIdName;
		}
		return txt;
	}
}
public var data:Object={};
private var tempAry:ArrayCollection=new ArrayCollection;
protected function btReturn_clickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	data.win.doInit();
	PopUpManager.removePopUp(this);
}

protected function gridApplyMaster_itemClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	// TODO Auto-generated method stub
	gridApplyMaster.grid.selectedItem;
	var obj:Object=gridApplyMaster.grid.selectedItem;
	if (obj == null)
		return;
	if (obj.autoId == null)
		return;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
	{
		if (rev == null || rev.data.length < 1)
		{
			
			return;
		}
		else
		{
			gridApplyDetail.dataProvider=rev.data;
			tempAry=rev.data;
		}
	});
	ro.findProvideDetailByMainAutoId(obj.autoId);
}
