// ActionScript file
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.util.MainToolBar;
import cn.superion.vo.material.MaterialInvoiceDetail;
import cn.superion.vo.material.MaterialRdsDetail;

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
public var params:Object=[];

//初始化
protected function doInit(event:FlexEvent):void
{
	this.width=FlexGlobals.topLevelApplication.width - 15;
	materialClass.txtContent.restrict="^ ";
	//授权仓库赋值
	if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
	{
		storageDefault.dataProvider=AppInfo.currentUserInfo.storageList;
		storageDefault.selectedIndex=0;
	}
}

//查询
protected function btQuery_clickHandler():void
{
	var paramQuery:ParameterObject=new ParameterObject();
	params['storageCode']=storageDefault.selectedItem.storageCode;
	paramQuery.conditions=params;
	var ro:RemoteObject=RemoteUtil.getRemoteObject("materialDictImpl", function(rev:Object):void
		{
			gdReceiveList.dataProvider=null
			if (rev.data && rev.data.length > 0)
			{
				gdReceiveList.dataProvider=rev.data;
				return;
			}
		});
	ro.findMaterialDictListByCondition(paramQuery);
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
		params['materialClass']=rev.classCode;
	}), x, y);
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
	var selectedItems:ArrayCollection= new ArrayCollection();
	for(var i:int=0;i<selectedItemss.length;i++)
	{
		var lnewlDetail:MaterialRdsDetail=new MaterialRdsDetail();
		
		lnewlDetail.materialId=selectedItemss[i].materialId;
		lnewlDetail.materialClass=selectedItemss[i].materialClass;
		lnewlDetail.barCode=selectedItemss[i].barCode;
		lnewlDetail.materialCode=selectedItemss[i].materialCode;
		lnewlDetail.materialName=selectedItemss[i].materialName;
		lnewlDetail.materialSpec=selectedItemss[i].materialSpec;
		lnewlDetail.materialUnits=selectedItemss[i].materialUnits;
		lnewlDetail.serialNo=0;
//		lnewlDetail.availDate=new Date();
		lnewlDetail.packageAmount=0;
		lnewlDetail.packageSpec=selectedItemss[i].packageSpec;
		lnewlDetail.packageUnits=selectedItemss[i].packageUnits;
		if(selectedItemss[i].amountPerPackage == '' || selectedItemss[i].amountPerPackage == null){
			lnewlDetail.amountPerPackage = 1;
		}else{
			lnewlDetail.amountPerPackage = selectedItemss[i].amountPerPackage;
		}
//		lnewlDetail.amount = 0;
		
		lnewlDetail.amount=1;
		lnewlDetail.acctAmount=0;
		
		lnewlDetail.tradePrice=selectedItemss[i].tradePrice;
		lnewlDetail.tradeMoney=selectedItemss[i].tradePrice;
		
		lnewlDetail.factTradePrice=selectedItemss[i].tradePrice * selectedItemss[i].rebateRate;
		lnewlDetail.factTradeMoney=selectedItemss[i].tradePrice * selectedItemss[i].rebateRate;
		
		lnewlDetail.rebateRate=selectedItemss[i].rebateRate;
		lnewlDetail.rebateRate=isNaN(lnewlDetail.rebateRate) ? 1 : lnewlDetail.rebateRate;
		
		lnewlDetail.wholeSalePrice=selectedItemss[i].wholeSalePrice;
		lnewlDetail.wholeSaleMoney=selectedItemss[i].wholeSalePrice;
		
		lnewlDetail.invitePrice=selectedItemss[i].invitePrice;
		lnewlDetail.inviteMoney=selectedItemss[i].invitePrice;
		
		lnewlDetail.retailPrice=selectedItemss[i].retailPrice;
		lnewlDetail.retailMoney=selectedItemss[i].retailPrice;
		lnewlDetail.batch='0'
		
		lnewlDetail.factoryCode=selectedItemss[i].factoryCode;
		lnewlDetail.currentStockAmount=selectedItemss[i].amount;
		
		lnewlDetail.outAmount=0;
		lnewlDetail.outSign='0';
		
		lnewlDetail.invoiceAmount=0;
		lnewlDetail.invoiceSign='0';
		
		lnewlDetail.highValueSign=selectedItemss[i].highValueSign;
		lnewlDetail.agentSign=selectedItemss[i].agentSign;
		lnewlDetail.checkAmount=0;
		selectedItems.addItem(lnewlDetail);
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
	var laryInvoice:ArrayCollection=data.parentWin.gdRdsDetail.dataProvider as ArrayCollection;
	laryInvoice.addAll(selectedItems);
	data.parentWin.gdRdsDetail.dataProvider = selectedItems;
	data.parentWin.menuItemsEnableValues=['0', '0'];
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
				if (th.id == "materialClass")
				{
					materialClass_queryIconClickHandler(e);
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
private function lbfStorageDefault(item:Object, column:DataGridColumn):String
{
	var tarItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict, 'storage', item.storageDefault)
	if (tarItem)
	{
		item.storageDefaultName=tarItem.storageName
		return item.storageDefaultName
	}
	return "";
}
//取消
protected function btReturn_clickHandler(event:Event):void
{
	PopUpManager.removePopUp(this);
}