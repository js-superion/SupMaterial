// ActionScript file
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.util.MainToolBar;
import cn.superion.vo.material.MaterialInvoiceDetail;

import flexlib.scheduling.util.DateUtil;

import mx.collections.ArrayCollection;
import mx.collections.ListCollectionView;
import mx.controls.Alert;
import mx.core.FlexGlobals;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

public var data:Object;
[Bindable]
private var importClassFactory:ClassFactory;
public var selectAllFlag:Boolean=false;
private var _tempSalerCode:String;
private var _tempMaterialClass:String;
private var _tempBeginMaterialCode:String;
private var _tempEndMaterialCode:String;
private var destination:String="invoiceImpl";
private var _itemSelected:Boolean = false; //是否存在被选中的数据

//初始化
protected function doInit(event:FlexEvent):void
{
	this.width=FlexGlobals.topLevelApplication.width - 15;
	salerCode.txtContent.restrict="^ ";
	materialClass.txtContent.restrict="^ ";
	beginMaterialCode.txtContent.restrict="^ ";
	endMaterialCode.txtContent.restrict="^ ";
}

//查询
protected function btQuery_clickHandler():void
{
	//供应商必选
	if(_tempSalerCode == null || _tempSalerCode == "" ){
		Alert.show('选择供应商','提示');
		return;
	}
	var params:Object=FormUtils.getFields(receiveQuery, []);
	var paramQuery:ParameterObject=new ParameterObject();
	//单据日期
	if (chkBillDate.selected)
	{
		params['beginBillDate']=beginBillDate.selectedDate;
		params['endBillDate']=MainToolBar.addOneDay(endBillDate.selectedDate);
	}
	else
	{
		params['beginBillDate']=null;
		params['endBillDate']=null;
	}
	params['salerCode']=_tempSalerCode == null ? salerCode.txtContent.text : _tempSalerCode;
	params['classCode']=_tempMaterialClass == null ? materialClass.txtContent.text : _tempMaterialClass;
	params['beginMaterialCode']=_tempBeginMaterialCode == null ? beginMaterialCode.txtContent.text : _tempBeginMaterialCode;
	params['endMaterialCode']=_tempEndMaterialCode == null ? endMaterialCode.txtContent.text : _tempEndMaterialCode;
	paramQuery.conditions=params;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
		{
			gdReceiveList.dataProvider=null
			if (rev.data && rev.data.length > 0)
			{
				gdReceiveList.dataProvider=rev.data;
				return;
			}
			data.parentWin.gdPurchaseInvoiceList.dataProvider=[];
		});
	ro.findRdsInvoice(paramQuery);
}

protected function chkBillDate_changeHandler(event:Event):void
{
	// TODO Auto-generated method stub
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
 * 过滤出选中的项目
 * */
private function createSelectedItems(faryReceive:ArrayCollection):ArrayCollection{
	var selectedItems:ArrayCollection = new ArrayCollection();
	for each (var item:Object in faryReceive)
	{
		if (item.isSelected)
		{
			_itemSelected = true; //只要存在一条被选中，则为true;
			item.sourceBillNo = item.autoId; //来源单据号为采购入库单明细的autoId
			item.sourceSerialNo = item.serialNo;//来源单据号中的序号 为采购明细钟的序号
			selectedItems.addItem(item);
		}
	}
	return selectedItems;
}
/**
 * 确定
 * */
protected function btConfirm_clickHandler(event:MouseEvent):void
{
	var laryReceive:ArrayCollection = gdReceiveList.dataProvider as ArrayCollection;
	if(laryReceive.length == 0) return;
	var selectedItemss:ArrayCollection = createSelectedItems(laryReceive);
	var selectedItems:ArrayCollection=new ArrayCollection();
	for(var i:int=0;i<selectedItemss.length;i++)
	{
		var mid:MaterialInvoiceDetail=new MaterialInvoiceDetail();
		mid.materialClass=selectedItemss[i].materialClass;
		mid.barCode=selectedItemss[i].barCode;
		mid.materialId=selectedItemss[i].materialId;
		mid.materialCode=selectedItemss[i].materialCode;
		mid.materialName=selectedItemss[i].materialName;
		mid.materialSpec=selectedItemss[i].materialSpec;
		mid.materialUnits=selectedItemss[i].materialUnits;
		mid.amount=selectedItemss[i].amount;
		mid.tradeMoney=selectedItemss[i].tradeMoney;
		mid.tradePrice=selectedItemss[i].tradePrice;
		mid.retailPrice=selectedItemss[i].retailPrice;
		mid.retailMoney=selectedItemss[i].retailMoney;
		mid.factoryCode=selectedItemss[i].factoryCode;
		mid.madeDate=selectedItemss[i].madeDate;
		mid.sourceSerialNo=selectedItemss[i].serialNo;
		
		mid.batch=selectedItemss[i].batch;
		mid.availDate=selectedItemss[i].availDate;
		mid.sourceBillNo=selectedItemss[i].autoId;
		selectedItems.addItem(mid);
	}
	if(!_itemSelected) {
		Alert.show('请选择数据','提示');
		return;
	}
	fillValueToParentWin(selectedItems);
	PopUpManager.removePopUp(this);
}

/**
 * 给父窗体赋值
 * @param selectedItems
 * */
private function fillValueToParentWin(selectedItems:ArrayCollection):void{
	var laryInvoice:ArrayCollection=data.parentWin.gdPurchaseInvoiceList.dataProvider as ArrayCollection;
	laryInvoice.addAll(selectedItems);
	data.parentWin.gdPurchaseInvoiceList.dataProvider = selectedItems;
	data.parentWin.salerCode.txtContent.text = salerCode.txtContent.text;
	data.parentWin._materialInvoiceMaster.salerCode=_tempSalerCode;
	data.parentWin._materialInvoiceMaster.salerName=salerCode.txtContent.text;
//	data.parentWin._tempSalerCode = _tempSalerCode;
//	data.parentWin.menuItemsEnableValues=['1', '1'];
}
//供应商字典
protected function salerCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict(function(rev:Object):void
		{
			salerCode.txtContent.text=rev.providerName;
			_tempSalerCode=rev.providerId;
		}, x, y);
}

//物资分类字典
protected function materialClass_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialClassDict(function(rev:Object):void
		{
			materialClass.txtContent.text=rev.className;
			_tempMaterialClass=rev.classCode;
		}, x, y);
}

//物资编码字典
protected function beginMaterialCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict(function(rev:Object):void
		{
			beginMaterialCode.txtContent.text=rev.materialCode;
			_tempBeginMaterialCode=rev.materialCode;
		}, x, y);
}

protected function endMaterialCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict(function(rev:Object):void
		{
			endMaterialCode.txtContent.text=rev.materialCode;
			_tempEndMaterialCode=rev.materialCode;
		}, x, y);
}

//未开票数量
private function labelFun(item:Object, column:DataGridColumn):*
{
	if (column.dataField == "unInvoiceAmount")
	{
		if (item.notData)
		{
			return "";
		}
		else
		{
			item.unInvoiceAmount=Number(item.amount - item.invoiceAmount).toFixed(2);
			return item.unInvoiceAmount;
		}
	}
}

//回车跳转事件
private function toNextControl(e:KeyboardEvent, fcontrolNext:*, th:*):void
{
	if (e.keyCode == Keyboard.ENTER)
	{
		if (th.className == "TextInputIcon")
		{
			if (th.txtContent.text == "" || th.txtContent.text == null)
			{
				if (th.id == "salerCode")
				{
					salerCode_queryIconClickHandler();
				}
				if (th.id == "materialClass")
				{
					materialClass_queryIconClickHandler();
				}
				if (th.id == "beginMaterialCode")
				{
					beginMaterialCode_queryIconClickHandler();
				}
				if (th.id == "endMaterialCode")
				{
					endMaterialCode_queryIconClickHandler();
				}
			}
			else
			{
				if (fcontrolNext.className == "DateField")
				{
					fcontrolNext.open();
					fcontrolNext.setFocus();
					return;
				}
				if (fcontrolNext.className == "DropDownList")
				{
					fcontrolNext.openDropDown();
					fcontrolNext.setFocus();
					return;
				}
				if (fcontrolNext.className == "TextInputIcon")
				{
					fcontrolNext.txtContent.setFocus();
					return;
				}
				fcontrolNext.setFocus();
			}
		}
		else
		{
			if (fcontrolNext.className == "DateField")
			{
				fcontrolNext.open();
				fcontrolNext.setFocus();
				return;
			}
			if (fcontrolNext.className == "DropDownList")
			{
				fcontrolNext.openDropDown();
				fcontrolNext.setFocus();
				return;
			}
			if (fcontrolNext.className == "TextInputIcon")
			{
				fcontrolNext.txtContent.setFocus();
				return;
			}
			fcontrolNext.setFocus();
		}
	}
}

//全选框
protected function ckAll_changeHandler(event:Event):void
{
	for each (var obj1:Object in gdReceiveList.dataProvider)
	{
		obj1.isSelected=ckAll.selected;
	}
	gdReceiveList.invalidateList();
}

protected function btQuery_keyUpHandler(event:KeyboardEvent):void
{
	if (event.keyCode == Keyboard.ENTER)
	{
		btQuery_clickHandler();
	}
}

//取消
protected function btReturn_clickHandler(event:Event):void
{
	PopUpManager.removePopUp(this);
}