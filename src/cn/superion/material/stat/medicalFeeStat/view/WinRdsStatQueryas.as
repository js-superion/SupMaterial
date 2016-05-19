import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.stat.medicalFeeStat.ModRdsStat;

import flash.events.MouseEvent;

import mx.collections.ArrayCollection;
import mx.events.CalendarLayoutChangeEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

public var parentWin:ModRdsStat;
private var _condition:Object={};
//结账处理时，方法的不同，泰州的为false,东方的为true
private var isFee:Boolean = false;

protected function doInit():void
{
	isFee = ExternalInterface.call("getIsFee");
	initComBox();
	fillForm();	
	initTextInputIcon();
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
	countClass.dataProvider = new ArrayCollection([{countName:"单独计价",countCode:"1"},{countName:"非单独计价",countCode:"2"}]);
	countClass.textInput.editable=false;
}
/**
 * 填充表单
 **/
private function fillForm():void
{
	FormUtils.fillFormByItem(this,_condition);
//	fillTextInputIcon(materialClass);
}

private function fillTextInputIcon(fctrl:Object):void{
	fctrl.text=_condition[fctrl.id+"Name"];
}
/**
 * 初始化放大镜输入框
 **/ 
private function initTextInputIcon():void
{
//	materialClass.txtContent.editable=false;
}

/**
 * 物资分类字典
 **/ 
protected function materialClass_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialClassDict((function(rev:Object):void
	{
		event.target.text=rev.className;
		parentWin.dict["物资分类"]=_condition['materialClassName']=rev.className;
		_condition['materialClass']=rev.classCode;
	}),x,y);
}
/**
 * 按回车跳转
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

protected function btConfirm_clickHandler(event:MouseEvent):void
{
	if (storageCode.selectedItem != null && storageCode.selectedIndex > -1)
	{
		_condition['storageCode']=storageCode.selectedItem.storageCode;
		parentWin.storageName = storageCode.selectedItem.storageName;
	}
	if (countClass.selectedItem != null && countClass.selectedIndex > -1)
	{
		_condition['countClass']=countClass.selectedItem.countCode;
	}
	if (isBillDate.selected == true)
	{
		_condition['beginYearMonth']=DateField.dateToString(billDateFrom.selectedDate, "YYYY-MM");
		_condition['endYearMonth']=DateField.dateToString(billDateTo.selectedDate, "YYYY-MM");
	}
	else
	{
		_condition['beginYearMonth']=null;
		_condition['endYearMonth']=null;
	}
//	_condition['beginCurrentStockAmount']=currentStockAmountFrom.text == "" ? null : (Number)(currentStockAmountFrom.text);
//	_condition['endCurrentStockAmount']=currentStockAmountTo.text == "" ? null : (Number)(currentStockAmountTo.text);
	_condition['isFee'] = isFee;
	_condition['materialName'] = materialName.text;

	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions=_condition;
	PopUpManager.removePopUp(this);
	
	var ro:RemoteObject=RemoteUtil.getRemoteObject(parentWin.DESTINATION, function(rev:Object):void
	{
		setToolBarBts(rev);
		for each(var item:Object in rev.data){
			item.initMoney = item.initMoney?Number(item.initMoney):0;
			item.tradeMoney = item.tradeMoney?Number(item.tradeMoney):0;
			item.retailMoney = item.retailMoney?Number(item.retailMoney):0;
			item.currentStockMoney = item.currentStockMoney?Number(item.currentStockMoney):0;
		}
		parentWin.gdRdsDetailList.dataProvider=rev.data;	
	});
	ro.findRdsStatListByConditionMonth(paramQuery);
}

/**
 * 设置当前按钮是否显示
 */
private function setToolBarBts(rev:Object):void
{
	if (rev.data && rev.data.length)
	{
		parentWin.toolBar.btPrint.enabled=true;
		parentWin.toolBar.btExp.enabled=true;
	}
	else
	{
		parentWin.toolBar.btPrint.enabled=false;
		parentWin.toolBar.btExp.enabled=false;
	}
}

protected function billDateFrom_changeHandler(event:CalendarLayoutChangeEvent):void
{
	if (billDateFrom.selectedDate)
	{
		billDateTo.selectedDate=billDateFrom.selectedDate
		billDateTo.selectableRange={rangeStart: billDateFrom.selectedDate, rangeEnd: new Date()}
	}
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

/**
 * 物资字典
 */
protected function materialCode_queryIconClickHandler(event:Event):void
{
	//打开物资字典
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 338;
	
	var lstorageCode:String='';
//	lstorageCode=(storageCode.selectedItem || {}).storageCode;
	//	lstorageCode = lstorageCode.substr(0,2);
	DictWinShower.showMaterialDictNew(lstorageCode, '', '', true, function(fItem:Array):void
	{
		//fillIntoGrid(fItem);
		materialName.text = fItem[0].materialName;
	}, x, y,"1");
}