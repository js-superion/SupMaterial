import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.stat.receiveStat.ModReceiveStat;
import cn.superion.material.util.MaterialDictShower;

import flash.events.MouseEvent;

import flexlib.scheduling.util.DateUtil;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

private  var _condition:Object={};
public var parentWin:ModReceiveStat;


protected function doInit():void
{
	initComBox();
	initTextInputIcon();
	fillForm();		
}

/**
 * 初始化ComboBox
 **/ 
private function initComBox():void
{
//	storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
	var result:ArrayCollection =ObjectUtil.copy(AppInfo.currentUserInfo.storageList) as ArrayCollection;
	var newArray:ArrayCollection = new ArrayCollection();
	for each(var it:Object in result){
		if(it.type == '2'||it.type == '3'){
			newArray.addItem(it);
		}
	}
	storageCode.dataProvider=newArray;//AppInfo.currentUserInfo.storageList;
	storageCode.selectedIndex=0;
	storageCode.textInput.editable=false;
	//业务类型
	operationType.dataProvider = new ArrayCollection([{operationType:null,operationTypeName:'全部'},
		{operationType:'101',operationTypeName:'普通采购'},
		{operationType:'102',operationTypeName:'受托代销'},
		{operationType:'103',operationTypeName:'直运'},
		{operationType:'104',operationTypeName:'盘盈入库'},
		{operationType:'105',operationTypeName:'期初入库'},
		{operationType:'106',operationTypeName:'特殊入库'},
		{operationType:'109',operationTypeName:'其他入库'}]);
	operationType.textInput.editable=false;
	
	cbxIsGive.textInput.editable=false;
}
/**
 * 填充表单
 **/
private function fillForm():void
{
	FormUtils.fillFormByItem(this,_condition);
	fillTextInputIcon(materialClass);
	fillTextInputIcon(salerCode);
	fillTextInputIcon(rdType);
	fillTextInputIcon(materialCode);
}

private function fillTextInputIcon(fctrl:Object):void{
	fctrl.text=_condition[fctrl.id+"Name"];
}

/**
 * 初始化放大镜输入框
 **/ 
private function initTextInputIcon():void
{
	materialClass.txtContent.editable=false;
	materialCode.txtContent.editable=false;
	salerCode.txtContent.editable=false;
	rdType.txtContent.editable=false;
}
/**
 * 回车事件处理方法
 **/
private function toNextControl(e:KeyboardEvent, fcontrolNext:*):void
{
	FormUtils.toNextControl(e,fcontrolNext);
}
/**
 * 放大镜键盘事件处理方法
 * */
protected function queryIcon_keyUpHandler(event:KeyboardEvent,fcontrolNext:Object):void
{
	FormUtils.textInputIconKeyUpHandler(event,_condition,fcontrolNext);
}

/**
 *供应商档案
 **/
protected function productCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict((function(rev:Object):void
	{
		event.target.text=rev.providerName;
		_condition['salerCodeName']=rev.providerName;
		_condition['salerCode']=rev.providerId;
	}), x, y);
}

/**
 *物资分类
 **/
protected function materialClass_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialClassDict((function(rev:Object):void
	{
		event.target.text=rev.className;
		_condition['materialClassName']=rev.className;
		_condition['materialClass']=rev.classCode;
	}), x, y);
}

/**
 *物资档案字典
 **/
protected function materialName_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	var storageCode:String = storageCode.selectedItem?storageCode.selectedItem.storageCode : null;
	MaterialDictShower.showMaterialDict(storageCode,(function(rev:Object):void
	{
		materialCode.txtContent.text=rev.materialName;
		_condition['materialCodeName']=rev.materialName;
		_condition['materialCode']=rev.materialCode;
	}), x, y);
}

/**
 * 入库类别
 **/ 
protected function rdType_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showReceiveTypeDict(function(item:Object):void
	{
		rdType.txtContent.text=item.rdName;
		parentWin.dict["入库类别"]=_condition['rdTypeName']=item.rdName;
		_condition['rdType']=item.rdCode;
	}, x, y);
}

/**
 *查询
 **/
protected function btConfirm_clickHandler(event:MouseEvent):void
{	
	if (storageCode.selectedItem)
	{
		_condition['storageCode']=storageCode.selectedItem.storageCode;
		parentWin.dict["仓库"]=storageCode.selectedItem.storageName;
	}
	if (operationType.selectedItem)
	{
		_condition['operationType']=operationType.selectedItem.operationType;
	}
	if (isBillDate.selected)
	{
		_condition['beginBillDate']=billDateFrom.selectedDate;
		_condition['endBillDate'] = addOneDay(billDateTo.selectedDate);
	}
	_condition["isGive"]=cbxIsGive.selectedItem.giveCode;
	_condition['detailRemark']=detailRemark.text;
	_condition['remark']=remark.text;
	if(fixedSign.selected){
		_condition['fixedSign'] = '1';
	}else{
		_condition['fixedSign'] = '0';
	}
	
	var params:ParameterObject=new ParameterObject();
	params.conditions=_condition;
	PopUpManager.removePopUp(this);
	
	var ro:RemoteObject=RemoteUtil.getRemoteObject(parentWin.DESTINATION, function(rev:Object):void
	{
		setToolBarBts(rev);
		for each(var item:Object in rev.data){
			if(item.currentStatus == '0'){
				item.currentStatus = '未审核';
			}else if(item.currentStatus == '1'){
				item.currentStatus = '已审核';
			}else if(item.currentStatus == '2'){
				item.currentStatus = '已记账';
			}
			if(item.materialClass){
				var mtc:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.materialClassDict,'materialClass',item.materialClass);
				item.materialClassName =  mtc?mtc.materialClassName:"";
			}else{
				item.materialClassName = "";
			}
			
			if(item.rdType){
				var rd:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.storageRdDict,'rdType',item.rdType);
				item.deliverTypeName =  rd?rd.rdTypeName:"";
			}else{
				item.deliverTypeName = "";
			}
			
		}
		var lstrFz:Object=fzGroup.selectedValue;
		parentWin.gdReceive.groupField=lstrFz;
		parentWin.gdReceive.dataProvider=rev.data;
	});
	ro.findReceiveStatListByCondition(params);
}

/**
 * 设置当前按钮是否显示
 */
private function setToolBarBts(rev:Object):void
{
	if (rev.data && rev.data.length)
	{
		parentWin.gdReceive.sumRowLabelText="合计";
		parentWin.toolBar.btPrint.enabled=true;
		parentWin.toolBar.btExp.enabled=true;
	}
	else
	{
		parentWin.gdReceive.sumRowLabelText="";
		parentWin.toolBar.btPrint.enabled=false;
		parentWin.toolBar.btExp.enabled=false;
	}
}

/**
 * 给指定日期+(24*3600*1000-1000);
 * */
private function addOneDay(date:Date):Date
{
	return DateUtil.addTime(new Date(date), DateUtil.DAY_IN_MILLISECONDS - 1000);
}

/**
 * 取消按钮事件响应方法
 **/
protected function closeWin():void
{
	PopUpManager.removePopUp(this);
}

/**
 * 退出
 */
protected function btReturn_clickHandler(event:MouseEvent):void
{
	PopUpManager.removePopUp(this);
}