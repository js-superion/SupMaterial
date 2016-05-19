import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.stat.safetyStock.ModSafetyStock;

import flash.events.MouseEvent;

import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

public var parentWin:ModSafetyStock;
private var _condition:Object={};

/**
 *初始化方法
 * */
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
	storage.dataProvider=AppInfo.currentUserInfo.storageList;
	storage.textInput.editable=false;
}

/**
 * 填充表单
 **/
private function fillForm():void
{
	FormUtils.fillFormByItem(this, _condition);
	fillTextInputIcon(materialClass);
}

private function fillTextInputIcon(fctrl:Object):void
{
	fctrl.text=_condition[fctrl.id + "Name"];
}

/**
 * 初始化放大镜输入框
 **/
private function initTextInputIcon():void
{
	materialClass.txtContent.editable=false;
}

/**
 * 物资分类字典
 * */
protected function materialClass_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialClassDict((function(rev:Object):void
		{
			materialClass.txtContent.text=rev.className;
			_condition['materialClassName']=rev.className;
			_condition['materialClass']=rev.classCode;
		}), x, y);
}

/**
 * 处理回车跳转事件方法
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:*):void
{
	FormUtils.toNextControl(e, fcontrolNext);
}

/**
 * 放大镜键盘事件处理方法
 * */
protected function queryIcon_keyUpHandler(event:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.textInputIconKeyUpHandler(event, _condition, fcontrolNext);
}

protected function btConfirm_clickHandler(event:MouseEvent):void
{
	if (storage.selectedItem)
	{
		_condition['storageCode']=storage.selectedItem.storageCode;
	}

	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions=_condition;
	paramQuery.page=1;
	paramQuery.itemsPerPage=10000;
	PopUpManager.removePopUp(this);
	
	var ro:RemoteObject=RemoteUtil.getRemoteObject(parentWin.DESTINATION, function(rev:Object):void
	{
		setToolBarBts(rev);
		for (var i:int=0; i < rev.data.length; i++)
		{
			var item:Object=rev.data.getItemAt(i);
			item.tradeMoney=item.amount * item.tradePrice;	
		}
		parentWin.depot=storage.selectedItem.storageName;
		parentWin.gdSafetyStock.dataProvider=rev.data;
	});
	ro.findSafeStockListByCondition(paramQuery);
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
/**
 * 退出
 */
protected function btReturn_clickHandler(event:MouseEvent):void
{
	PopUpManager.removePopUp(this);
}

/**
 * 取消
 * */
protected function closeWin():void
{
	PopUpManager.removePopUp(this);
}