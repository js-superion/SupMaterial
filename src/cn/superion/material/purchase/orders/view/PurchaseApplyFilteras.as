// ActionScript file
import cn.superion.base.config.ParameterObject;
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

public var parentWin:Object;
private var _tempSalerCode:String="";
private var _tempDeptCode:String="";
private var _tempPersonId:String="";
private var _materialClass:String="";
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
 * 供应商字典：点击
 * */
protected function salerCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict((function(item:Object):void
		{
			salerCode.txtContent.text=item.providerName;
			_tempSalerCode=item.providerCode;
		}), x, y);
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
		deptCode.setFocus();
		return;
	}
	salerCode_queryIconClickHandler();
}

/**
 * 部门字典：点击
 * */
protected function deptCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict((function(item:Object):void
		{
			deptCode.txtContent.text=item.deptName;
			_tempDeptCode=item.deptCode;
		}), x, y);
}

/**
 * 部门字典：弹出
 * */
protected function deptCode_KeyDownHandler(e:KeyboardEvent):void
{
	if (e.keyCode != 13)
		return;
	if (deptCode.txtContent.text.length > 0)
	{
		personId.txtContent.setFocus();
		return
	}
	deptCode_queryIconClickHandler();
}

/**
 * 业务员字典：点击
 * */
protected function personId_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict((function(item:Object):void
		{
			personId.txtContent.text=item.name;
			_tempPersonId=item.personId;
		}), x, y);
}

/**
 * 业务员字典：回车
 * */
protected function personId_KeyDownHandler(e:KeyboardEvent):void
{
	if (e.keyCode != 13)
		return;
	if (personId.txtContent.text.length > 0)
	{
		beginBillDate.setFocus();
		return
	}
	personId_queryIconClickHandler();
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
					MaterialClass_queryIconClickHandler(e);
					return;
				}
				if (e.currentTarget.id == "salerCode")
				{
					salerCode_queryIconClickHandler();
					return;
				}
				if (e.currentTarget.id == "personId")
				{
					personId_KeyDownHandler(e);
					return;
				}
				if (e.currentTarget.id == "deptCode")
				{
					deptCode_queryIconClickHandler();
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

	fparameter["materialClass"]=materialClass.txtContent.text == "" ? null : _materialClass;
	fparameter["beginMaterialCode"]=beginMaterialCode.text;
	fparameter["dataSource"]="2";
	fparameter["endMaterialCode"]=endMaterialCode.text;
	fparameter["salerCode"]=salerCode.txtContent.text == "" ? null : _tempSalerCode;
	fparameter["deptCode"]=deptCode.txtContent.text == "" ? null : _tempDeptCode;
	fparameter["personId"]=personId.txtContent.text == "" ? null : _tempPersonId;
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
				dgApplyList.dataProvider=rev.data;
				return;
			}
			dgApplyList.dataProvider=null;
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
	var _dataList:ArrayCollection=dgApplyList.dataProvider as ArrayCollection;
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
	for (var i:int=0; i < _ary.length; i++)
	{
		var materialOrderDetail:MaterialOrderDetail=new MaterialOrderDetail();
		materialOrderDetail.materialCode=_ary[i].materialCode;
		materialOrderDetail.materialClass=_ary[i].materialClass;
		materialOrderDetail.materialId=_ary[i].materialId;
		materialOrderDetail.serialNo=0;
		materialOrderDetail.materialName=_ary[i].materialName;
		materialOrderDetail.materialSpec=_ary[i].materialSpec;
		materialOrderDetail.materialUnits=_ary[i].materialUnits;
		materialOrderDetail.amount=_ary[i].amount;
		materialOrderDetail.tradePrice=_ary[i].tradePrice;
		materialOrderDetail.tradeMoney=_ary[i].tradeMoney;
		materialOrderDetail.detailRemark=_ary[i].detailRemark;
		materialOrderDetail.retailPrice=_ary[i].retailPrice;
		materialOrderDetail.retailMoney=_ary[i].retailMoney;
		materialOrderDetail.factoryCode = _ary[i].salerCode;
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

//物资分类字典
protected function MaterialClass_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialClassDict(function(rev:Object):void
		{
			materialClass.txtContent.text=rev.className;
			_materialClass=rev.materialClass;
		}, x, y);
}

//取消
protected function btReturn_clickHandler():void
{
	PopUpManager.removePopUp(this);
}

/**
 * 点击全选
 * */
protected function selectAll_clickHandler():void
{
	for each (var item:Object in dgApplyList.dataProvider)
	{
		item.isSelected=this.selAll.selected;
		ListCollectionView(dgApplyList.dataProvider).itemUpdated(item, "isSelected");
	}
}
