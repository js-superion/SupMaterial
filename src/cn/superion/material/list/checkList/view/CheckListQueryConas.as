import cn.superion.base.components.controls.TextInputIcon;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.list.checkList.ModCheckList;
import cn.superion.material.util.MainToolBar;
import cn.superion.material.util.MaterialDictShower;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

[Bindable]
private var currentStatusArray:ArrayCollection=new ArrayCollection([{currentStatus: null, currentStatusName: '全部'}, {currentStatus: '0', currentStatusName: '新建状态'}, {currentStatus: '1', currentStatusName: '审核状态'}]);
//上级页面
public var iparentWin:ModCheckList;
//条件对象
private var _condition:Object={};


private var _tempDeptCode:String="";
private var _tempFactoryCode:String="";
private var _tempPersonId:String="";
private var _tempBeginMaterialCode:String;
private var _tempEndMaterialCode:String;

/**
 * 初始化
 * */
protected function doInit():void
{
	initTextInputIcon();
	storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
	fillForm();
	storageCode.setFocus();	
}

/**
 * 填充表单
 * */
private function  fillForm():void{
	FormUtils.fillFormByItem(this,_condition);
	fillTextInputIcon(factoryCode);
	fillTextInputIcon(deptCode);
}
private function fillTextInputIcon(fctrl:Object):void{
	fctrl.text=_condition[fctrl.id+"Name"];
}
/**
 * 初始化放大镜输入框
 * */
private function initTextInputIcon():void{
	beginMaterialCode.txtContent.editable=false;
	endMaterialCode.txtContent.editable=false;
	personId.txtContent.editable=false;
	deptCode.txtContent.editable=false;
	factoryCode.txtContent.editable=false;
}

/**
 * 物资档案(起始物资编码)字典
 * */
protected function beginMaterialCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	var storageCode:String = storageCode.selectedItem?storageCode.selectedItem.storageCode : null;
	MaterialDictShower.showMaterialDict(storageCode,(function(rev:Object):void
	{
		beginMaterialCode.txtContent.text=rev.materialCode;
		//	_tempBeginMaterialCode=rev.materialCode;
		_condition['beginMaterialCode']=rev.materialCode;
	}), x, y);
}
/**
 * 物资(起始物资编码)键盘事件处理方法
 * */
protected function beginMaterialCode_keyUpHandler(event:KeyboardEvent):void
{
	FormUtils.textInputIconKeyUpHandler(event,_condition,endMaterialCode);
}
/**
 * 物资档案(结束物资编码)字典
 * */
protected function endMaterialCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	var storageCode:String = storageCode.selectedItem?storageCode.selectedItem.storageCode : null;
	MaterialDictShower.showMaterialDict(storageCode,(function(rev:Object):void
	{
		endMaterialCode.txtContent.text=rev.materialCode;
		//	_tempEndMaterialCode=rev.materialCode;
		_condition['endMaterialCode']=rev.materialCode;
	}), x, y);
}
/**
 * 物资(结束物资编码)键盘事件处理方法
 * */
protected function endMaterialCode_keyUpHandler(event:KeyboardEvent):void
{
	FormUtils.textInputIconKeyUpHandler(event,_condition,personId);
}

/**
 * 人员(经手人)档案字典
 * */
protected function personId_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict((function(rev:Object):void
	{
		personId.txtContent.text=rev.personIdName;
		//	_tempPersonId=rev.personId;
		_condition['personId']=rev.personId;
	}), x, y);
}
/**
 * 人员(经手人)键盘事件处理方法
 * */
protected function personId_keyUpHandler(event:KeyboardEvent):void
{
	FormUtils.textInputIconKeyUpHandler(event,_condition,deptCode);
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
		//	_tempDeptCode=rev.deptCode;
		_condition['deptCode']=rev.deptCode;
		//	_condition['outDeptCodeName']=rev.deptName;
	}), x, y);
}
/**
 * 部门键盘事件处理方法
 * */
protected function deptCode_keyUpHandler(event:KeyboardEvent):void
{
	FormUtils.textInputIconKeyUpHandler(event,_condition,factoryCode);
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
		//		_tempFactoryCode=rev.providerId;
		_condition['factoryCode']=rev.providerId;
		//		_condition['factoryCodeName']=rev.providerName;
	}), x, y);
}
/**
 * 生产厂家键盘事件处理方法
 * */
protected function factoryCode_keyUpHandler(event:KeyboardEvent):void
{
	FormUtils.textInputIconKeyUpHandler(event,_condition,currentStatus);
}
/**
 * 确认查询事件处理方法
 * */
protected function btQuery_clickHandler():void
{
	//仓库
	_condition['storageCode']=storageCode.selectedItem ? storageCode.selectedItem.storageCode : "";
	//开始盘点单号
	_condition["beginBillNo"]=beginBillNo.text;
	//结束盘点单号
	_condition["endBillNo"]=endBillNo.text;
	//盘点日期范围
	_condition['beginBillDate']=billDate.selected ? beginBillDate.selectedDate : null;
	_condition['endBillDate']=billDate.selected ? MainToolBar.addOneDay(endBillDate.selectedDate) : null;
	//生产厂家
	//	_condition['factoryCode']=_tempFactoryCode == null ? factoryCode.txtContent.text : _tempFactoryCode;
	_condition['factoryCodeName']=factoryCode.txtContent.text== null ? null : factoryCode.txtContent.text;
	//领用部门
	_condition['deptCodeName']=deptCode.txtContent.text== null ? null : deptCode.txtContent.text;
	
	//当前状态
	_condition['currentStatus']=currentStatus.selectedItem ? currentStatus.selectedItem.currentStatus : "";
	
	var params:ParameterObject=new ParameterObject();
	params.conditions=_condition;
	iparentWin.dgDrug.reQuery(params);
	
}
/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e,fcontrolNext);
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
