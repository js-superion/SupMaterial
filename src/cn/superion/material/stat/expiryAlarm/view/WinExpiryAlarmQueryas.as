import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.stat.expiryAlarm.ModExpiryAlarm;

import com.adobe.utils.StringUtil;

import flash.events.MouseEvent;
import flash.utils.Endian;

import flexlib.scheduling.util.DateUtil;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

public var parentWin:ModExpiryAlarm;
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
 */
private function initComBox():void
{
	//授权仓库赋值
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
}

/**
 * 填充表单
 * */
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
 */
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
 * 查找
 */
protected function btConfirm_clickHandler(event:MouseEvent):void
{
	_condition['storageCode']=storageCode.selectedItem ? storageCode.selectedItem.storageCode : null;
	_condition['beginAvailDate']=rdoBt.selectedValue == 'availDate' ? beginAvailDate.selectedDate : null;
	_condition['endAvailDate']=rdoBt.selectedValue == 'availDate' ? addOneDay(endAvailDate.selectedDate) : null;
	_condition['overdueNum']=rdoBt.selectedValue == 'expiryDay' ? Number(StringUtil.trim(expiryDay.text).length == 0 ? 0 : Number(expiryDay.text)) : null;
	_condition['anearNum']=rdoBt.selectedValue == 'nearDay' ? Number(StringUtil.trim(nearDay.text).length == 0 ? 0 : Number(nearDay.text)) : null;
	
	var paramQuery:ParameterObject=new ParameterObject(); 
	paramQuery.conditions=_condition;
	paramQuery.page=1;
//	paramQuery.start=1;
	paramQuery.itemsPerPage=10000;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(parentWin.DESTINATION, function(rev:Object):void
	{
		if(rev.data.length >  0){
			btReturn_clickHandler(null);
			setToolBarBts(rev);
			for (var i:int=0; i < rev.data.length; i++)
			{
				var item:Object=rev.data.getItemAt(i);
				item.tradeMoney=item.amount * item.tradePrice;	
			}
			parentWin.materialClass = materialClass.txtContent.text;
			parentWin.storageName = storageCode.selectedItem.storageName;
			if(rdoBt.selection){
				parentWin.selectedRdoName = rdoBt.selection.label;
				parentWin.selectedRdoValue = rdoBt.selection == rdoBtAvailDate ? (beginAvailDate.text +" 到 "+ endAvailDate.text)
				: rdoBtExpiryDay ? expiryDay.text
				: rdoBtNearDay ? nearDay.text
				: "";
			}
		}
		parentWin.gdExpiryAlarm.dataProvider=rev.data;
	});
	ro.findAvailDateListByCondition(paramQuery);
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
 * 回车跳转事件
 */
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
