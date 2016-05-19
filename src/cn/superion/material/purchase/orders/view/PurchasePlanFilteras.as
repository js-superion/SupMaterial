// ActionScript file
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.util.MainToolBar;
import cn.superion.vo.material.MaterialOrderDetail;

import com.adobe.utils.StringUtil;

import mx.collections.ArrayCollection;
import mx.collections.ListCollectionView;
import mx.controls.Alert;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

private var _tempClass:String="";
private var _tempSalerCode:String="";
[Bindable]
public var data:Object;
public var selectAll:Boolean=false;
[Bindable]
private var importClassFactory:ClassFactory;
private var destination:String="orderImpl";

protected function doInit(event:FlexEvent):void
{
	importClassFactory=new ClassFactory(CheckBoxHeaderRenderer);
	importClassFactory.properties={stateHost: this, stateProperty: 'selectAll'};
}

/**
 * 供应商字典：回车
 * */
protected function salerCode_KeyDownHandler(e:KeyboardEvent):void
{
	if (e.keyCode != 13)
		return;
	if (salerCode.txtContent.text.length > 0)
	{
		beginBillDate.setFocus();
		return;
	}
	salerCode_queryIconClickHandler();
}

//按回车跳转
private function keyUpCtrl(e:KeyboardEvent, fcontrolNext:*):void
{
	if (e.keyCode == Keyboard.ENTER)
	{
		if (fcontrolNext is TextInputIcon && !(e.currentTarget is TextInputIcon))
		{
			fcontrolNext.txtContent.setFocus()
			return;
		}
		if (e.currentTarget is TextInputIcon)
		{
			if (e.currentTarget.text == "")
			{
				if (e.currentTarget.id == "materialClass")
				{
					materialClass_queryIconClickHandler();
					return;
				}
				if (e.currentTarget.id == "salerCode")
				{
					salerCode_queryIconClickHandler();
					return;
				}
			}
			if (fcontrolNext is TextInputIcon)
			{
				fcontrolNext.txtContent.setFocus()
				return;
			}
		}
		if (fcontrolNext.className == "DateField")
		{
			fcontrolNext.open();
			fcontrolNext.setFocus()
			return;
		}
		fcontrolNext.setFocus()
	}
}

/**
 * 查询
 * */
protected function btQuery_clickHandler(event:Event):void
{
	var fparameter:Object={};
	var para:ParameterObject=new ParameterObject();
	fparameter["dataSource"]="1"
	fparameter["materialClass"]=materialClass.txtContent.text == "" ? null : _tempClass;
	fparameter["beginMaterialCode"]=beginMaterialCode.text;
	fparameter["endMaterialCode"]=endMaterialCode.text;
	fparameter["salerCode"]=salerCode.txtContent.text == "" ? null : _tempSalerCode;
	if (isBillDate.selected == true)
	{
		fparameter["beginBillDate"]=beginBillDate.selectedDate;
		fparameter["endBillDate"] = MainToolBar.addOneDay(endBillDate.selectedDate);
	}
	if (isBookDate.selected == true)
	{
		fparameter["beginRequireDate"]=beginRequireDate.selectedDate;
		fparameter["endRequireDate"]= MainToolBar.addOneDay(endRequireDate.selectedDate);
	}
	para.conditions=fparameter;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
		{
			if (rev.data && rev.data.length > 0)
			{
				dgPlanList.dataProvider=rev.data;
				return;
			}
			dgPlanList.dataProvider=null;
			Alert.show("没有检索到相关数据！", "提示信息");
		});

	ro.findPlanDetailListByCondition(para);
}


/**
 * 确定
 * */
private function btConfirmHandler():void
{
	var _ary:ArrayCollection=new ArrayCollection();
	var _dataList:ArrayCollection=dgPlanList.dataProvider as ArrayCollection;
	for each (var item:Object in _dataList)
	{
		if (item.isSelected)
		{
			_ary.addItem(item);
		}
	}
	if (_ary.length == 0)
	{
		Alert.show("请选择要处理的数据！", "提示信息");
		return;
	}
	data.parentWin.toolBar.btDelRow.enabled=true;
	var _dgPro:ArrayCollection=data.parentWin.dgOrdersDetail.dataProvider as ArrayCollection;
	//验证重复的数据
	for (var i:int=0; i < _ary.length; i++)
	{
		var materialOrderDetail:MaterialOrderDetail=new MaterialOrderDetail();
		materialOrderDetail.materialCode=_ary[i].materialCode;
		materialOrderDetail.materialClass=_ary[i].materialClass;
		materialOrderDetail.materialId=_ary[i].materialId;
		materialOrderDetail.materialName=_ary[i].materialName;
		materialOrderDetail.materialSpec=_ary[i].materialSpec;
		materialOrderDetail.materialUnits=_ary[i].materialUnits;
		materialOrderDetail.amount=_ary[i].amount;
		materialOrderDetail.serialNo=0;
		materialOrderDetail.tradePrice=_ary[i].tradePrice;
		materialOrderDetail.tradeMoney=_ary[i].tradeMoney;
		materialOrderDetail.retailPrice=_ary[i].retailPrice;
		materialOrderDetail.retailMoney=_ary[i].retailMoney
		materialOrderDetail.factoryCode = _ary[i].salerCode;
		materialOrderDetail.detailRemark=_ary[i].detailRemark;
		materialOrderDetail.sourceBillNo=_ary[i].autoId;
		materialOrderDetail.detailAutoId=_ary[i].detailAutoId; //增加一个明细的id，为了校验重复使用 4-11，jzx
		materialOrderDetail.sourceSerialNo=_ary[i].serialNo;
		materialOrderDetail.inputAmount=0;
		materialOrderDetail.arrivalAmount=0;
		materialOrderDetail.planArriveDate=new Date();
		if(MainToolBar.findDuplicateItem(_ary[i],'detailAutoId',_dgPro)) continue;
		_dgPro.addItem(materialOrderDetail);
	}
	data.parentWin.dgOrdersDetail.dataProvider=_dgPro;
	btReturn_clickHandler();
}

/**
 * 物资分类字典：点击
 * */
protected function materialClass_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialClassDict((function(item:Object):void
		{
			materialClass.txtContent.text=item.className;
			_tempClass=item.classCode;
		}), x, y);
}

/**
 * 物资分类字典：回车
 * */
protected function materialClass_keyDownHandler(event:KeyboardEvent):void
{
	if (event.keyCode != 13)
		return;
	if (materialClass.txtContent.text.length > 0)
	{
		beginMaterialCode.setFocus();
		return;
	}
	materialClass_queryIconClickHandler();
}

/**
 * 供应商字典：点击
 * */
protected function salerCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict((function(item:Object):void
		{
			salerCode.txtContent.text=item.providerName;
			_tempSalerCode=item.providerId;
		}), x, y);
}

/**
 * 取消
 * */
protected function btReturn_clickHandler():void
{
	PopUpManager.removePopUp(this);
}

/**
 * 点击全选
 * */
protected function selectAll_clickHandler():void
{
	for each (var item:Object in dgPlanList.dataProvider)
	{
		item.isSelected=this.selAll.selected;
		ListCollectionView(dgPlanList.dataProvider).itemUpdated(item, "isSelected");
	}
}