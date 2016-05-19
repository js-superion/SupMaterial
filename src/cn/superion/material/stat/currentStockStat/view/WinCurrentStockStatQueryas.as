import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.stat.currentStockStat.ModCurrentStockStat;
import cn.superion.material.util.MaterialDictShower;

import flexlib.scheduling.util.DateUtil;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

private var _condition:Object={};
public var parentWin:ModCurrentStockStat;

private function doInit():void
{
	initComBox();
	initTextInputIcon();
	fillForm();
	_stockAmountFlag=null;
}

/**
 * 初始化ComboBox
 **/
private function initComBox():void
{
	//仓库赋值
//	storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
//	storageCode.textInput.editable=false;
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

private function fillForm():void
{
	FormUtils.fillFormByItem(this, _condition);
	fillTextInputIcon(materialCode);
	fillTextInputIcon(materialClass);
}

private function fillTextInputIcon(fctrl:Object):void
{
	fctrl.text=_condition[fctrl.id + "Name"];
}

/**
 * 初始化放大镜
 **/
private function initTextInputIcon():void
{
	materialClass.txtContent.editable=false;
	materialCode.txtContent.editable=false;
}

/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
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
 * 物资档案字典
 **/
protected function materialCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	var storageCode:String = storageCode.selectedItem?storageCode.selectedItem.storageCode : null;
	MaterialDictShower.showMaterialDict(storageCode,(function(rev:Object):void
		{
			event.target.text=rev.materialName;
			_condition['materialCode']=rev.materialCode;
		}), x, y);
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
			materialClass.txtContent.text=rev.className;
			parentWin.dict["物资分类"]=_condition['materialClassName']=rev.className;
			_condition['materialClass']=rev.classCode;
		}), x, y);
}

public function btConfirm_clickHandler(event:MouseEvent):void
{
	if (storageCode.selectedItem)
	{
		_condition['storageCode']=storageCode.selectedItem.storageCode;
	}
	if (isAvailDate.selected)
	{
		_condition['beginAvailDate']=beginAvailDate.selectedDate;
		_condition['endAvailDate']=addOneDay(endAvailDate.selectedDate);
	}
	else
	{
		_condition['beginAvailDate']=null;
		_condition['endAvailDate']=null;
	}
	if(StockAmount.selected==true)
	{
		_condition["minStockAmount"]=minStockAmount.text == "" ? null : Number(minStockAmount.text);
		_condition["maxStockAmount"]=maxStockAmount.text == "" ? null : Number(maxStockAmount.text);
	}
	else
	{
		_condition["stockAmountFlag"]=_stockAmountFlag;
	}
		
	parentWin.dict["现存量范围"]="现存量范围: "+minStockAmount.text+"  -  "+maxStockAmount.text;
	
	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions=_condition;
	PopUpManager.removePopUp(this);

	var ro:RemoteObject=RemoteUtil.getRemoteObject(parentWin.DESTINATION, function(rev:Object):void
		{
		    setToolBarBts(rev);
			for (var i:int=0; i < rev.data.length; i++)
			{
				var item:Object=rev.data.getItemAt(i);
				item.retailMoney=item.amount * item.retailPrice;	
				item.wholeSaleMoney=item.amount * item.wholeSalePrice;
				
				if(item.factoryCode)
				{
					var provider:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict, 'provider', item.factoryCode);		
					item.factoryName=provider == null ? "" : provider.providerName;
				}
				else
				{
					item.factoryName='';
				}
			}
			parentWin.gridCurrentStock.dataProvider=rev.data;
		});
	ro.findCurrentStockListByCondition(paramQuery);
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
 * 给指定日期+(24*3600*1000-1000);
 * */
private function addOneDay(date:Date):Date
{
	return DateUtil.addTime(new Date(date), DateUtil.DAY_IN_MILLISECONDS - 1000);
}

/**
 * 取消按钮事件响应方法
 * */
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
