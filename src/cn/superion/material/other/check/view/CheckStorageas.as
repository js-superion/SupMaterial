/** 
 *		 库存盘点模块 盘库条件窗体  
 *		 author:宋盐兵   2011.01.19
 *		 modified by 邢树斌  2011.02.19
 *		 checked by 
 **/
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.base.util.StringUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.other.check.ModCheck;
import cn.superion.material.util.MainToolBar;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

//上级页面
public var iparentWin:ModCheck;
//条件对象
private static var _condition:Object={}
public var data:Object={};
/**
 * 初始化
 * */
private function doInit():void
{
	_condition={};
	fillCombox();
	fillForm();
	storageCode.setFocus();
	materialClass.txtContent.editable=false		
}
/**
 * 填充表单
 * */
private function  fillForm():void{
	FormUtils.fillFormByItem(this,_condition);
}

/**
 * 物资类别字典
 * */
protected function materialClass_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialClassDict(function(item:Object):void
	{
		_condition.materialClass=item.classCode;
		materialClass.text=item.className;
	});
}

/**
 * 物资档案字典
 * */
protected function materialName_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict(function(rev:Object):void
	{
		materialName.txtContent.text=rev.materialName;
	});
}

/**
 * 确认查询事件处理方法
 * */
protected function btConfirm_clickHandler(event:MouseEvent):void
{
	var paramQuery:ParameterObject=new ParameterObject();
	// 仓库编码
	if (storageCode.selectedItem != null && storageCode.selectedIndex > -1)
	{
		_condition["storageCode"]=storageCode.selectedItem.storageCode;
	}
	else
	{
		Alert.show('仓库不可为空，请选择仓库', '提示');
		return;
	}
	// 物资名称
	_condition["materialName"]=StringUtils.Trim(materialName.txtContent.text);
	// 有效期限
	if (isAvailDate.selected)
	{
		_condition["beginAvailDate"]=beginAvailDate.selectedDate
		// 结束有效日期
		var endOfAvailDate:Date=new Date();
		endOfAvailDate.setTime(endAvailDate.selectedDate.getTime() + 24 * 60 * 60 * 1000);
		_condition["endAvailDate"]=endOfAvailDate;
	}
	else
	{
		_condition["beginAvailDate"]=null;
		_condition["endAvailDate"]=null;
	}
	// 临近天数
	_condition["anearNum"]=anearNum.text == "" ? null : parseInt(anearNum.text);
	paramQuery.conditions=_condition;
	PopUpManager.removePopUp(this);
	var ro:RemoteObject=RemoteUtil.getRemoteObject(ModCheck.DESTANATION, function(rev:Object):void
	{
		var arryList:ArrayCollection=new ArrayCollection();
		for(var i:int=0;i<rev.data.length;i++)
		{
			rev.data[i].checkAmount = rev.data[i].amount
			arryList.addItem(rev.data[i]);
		}
		data.parentWin.gdDetails.dataProvider=arryList;
	});
	ro.findCheckMaterial(paramQuery);
}
/**
 * 物资类别键盘事件处理方法
 * */
protected function materialClass_keyUpHandler(event:KeyboardEvent):void
{
	FormUtils.textInputIconKeyUpHandler(event,_condition,materialName);
}
/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e,fcontrolNext);
}

/**
 * 有效期限复选框事件处理方法
 * */
protected function isAvailDate_changeHandler(event:Event):void
{
	if (isAvailDate.selected)
	{
		beginAvailDate.enabled=true;
		endAvailDate.enabled=true;
		anearNum.enabled=false;
	}
	else
	{
		beginAvailDate.enabled=false;
		endAvailDate.enabled=false;
		anearNum.enabled=true;
	}
}

/**
 * 账面为零是否盘点复选框回车事件处理方法
 * */
protected function checkSign_keyUpHandler(e:KeyboardEvent):void
{
	if (e.keyCode == Keyboard.ENTER)
	{
		checkSign.selected=!checkSign.selected;
	}
}

/**
 * 账面为零是否盘点复选框事件处理方法
 * */
protected function checkSign_changeHandler(event:Event):void
{
	_condition.checkZeroSign=checkSign.selected?"1":"0"
}
protected function lessZero_changeHandler(event:Event):void
{
	_condition.lessZero=lessZero.selected?"1":"0"
}
protected function bigZero_changeHandler(event:Event):void
{
	_condition.bigZero=bigZero.selected?"1":"0"
}
/**
 * 是否受托代销物资复选框事件处理方法
 * */
protected function agentSign_changeHandler(event:Event):void
{
	_condition.agentSign =agentSign.selected?"1":"0"
}
/**
 * 仓库档案字典
 * */
protected function fillCombox():void
{
	storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
	storageCode.selectedIndex=0
}
//返回主页面
protected function btReturn_clickHandler():void
{
	PopUpManager.removePopUp(this);
}
