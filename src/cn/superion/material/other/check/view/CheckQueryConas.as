/** 
 *		 库存盘点模块 设定查询条件窗体  
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

import flash.events.Event;
import flash.ui.Keyboard;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.core.UIComponent;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.components.TextInput;

public var iparentWin:ModCheck;
//条件对象
private static var _condition:Object={}
public var data:Object={};
/**
 * 初始化
 * */
private function doInit():void
{
	initTextInputIcon();
	fillCombo();
	fillForm();
	storageCode.setFocus();	
}

/**
 * 初始化放大镜输入框
 * */
private function initTextInputIcon():void{
	materialClass.txtContent.editable=false;
}

/**
 * 部门档案字典
 * */
protected function deptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(rev:Object):void
	{
		event.target.text=rev.deptName;
	});
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
	DictWinShower.showMaterialDict(function(item:Object):void
	{		
		materialName.text=item.materialName;
	});
}

/**
 * 确认查询事件处理方法
 * */
protected function btConfirm_clickHandler(event:MouseEvent):void
{
	var paramQuery:ParameterObject=new ParameterObject();
	if (storageCode.selectedItem != null)
	{
		_condition["storageCode"]=storageCode.selectedItem.storageCode;
	}
	// 盘点单号
	_condition["beginBillNo"]=StringUtils.Trim(beginBillNo.text);
	_condition["endBillNo"]=StringUtils.Trim(endBillNo.text);
	// 盘点日期
	if (chkBillDate.selected)
	{
		// 开始出库日期
		_condition["beginBillDate"]=beginBillDate.selectedDate;
		// 结束出库日期
		_condition["endBillDate"]= MainToolBar.addOneDay(endBillDate.selectedDate);
	}
	else
	{
		_condition["beginBillDate"]=null;
		_condition["endBillDate"]=null;
	}
	// 物资名称
	_condition["materialName"]=StringUtils.Trim(materialName.txtContent.text);
	paramQuery.conditions=_condition;
	PopUpManager.removePopUp(this);
	var ro:RemoteObject=RemoteUtil.getRemoteObject(ModCheck.DESTANATION, function(rev:Object):void
	{
		if (rev.data && rev.data.length > 0)
		{
			data.parentWin.arrayAutoId=ArrayCollection(rev.data).toArray();
			
			data.parentWin.findRdsById(rev.data[0]);
			
			setToolBarPageBts(rev.data.length);
			return;
		}
		data.parentWin.doInit();
		data.parentWin.clearForm(true, true);
	});
	ro.findCheckMasterListByCondition(paramQuery);
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
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e,fcontrolNext);
}
/**
 * 物资类别键盘事件处理方法
 * */
protected function materialClass_keyUpHandler(event:KeyboardEvent):void
{
	FormUtils.textInputIconKeyUpHandler(event,_condition,materialName);
}

/**
 * 盘点日期选择
 * */
protected function chkBillDate_changeHandler(event:Event):void
{
	if (chkBillDate.selected)
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
/**
 * 填充表单
 * */
private function  fillForm():void{
	FormUtils.fillFormByItem(this,_condition);
}
/**
 * 仓库档案字典
 * */
protected function fillCombo():void
{
	storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
	storageCode.selectedIndex=0;
}

//返回主页面
protected function btReturn_clickHandler():void
{
	PopUpManager.removePopUp(this);
}

