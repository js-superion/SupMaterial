// ActionScript file
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.purchase.plan.ModPurchasePlan;
import cn.superion.material.purchase.plan.view.PurchasePlanAuto;
import cn.superion.material.util.MainToolBar;

import com.adobe.utils.StringUtil;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.events.CloseEvent;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.validators.NumberValidator;
import mx.validators.Validator;

import spark.events.TextOperationEvent;

public var parentWin:ModPurchasePlan;
private var materialCode:String="";
public var materialClass1:String="";
public var materialCode1:String="";
private var destination:String='planImpl';
[Bindable]
public var data:Object;
public var _vAll:Array=[];

private function doInit():void
{
	initValidate();
	storage.dataProvider=AppInfo.currentUserInfo.storageList;
	storage.selectedIndex=0;
}
public var typeArc:ArrayCollection=AppInfo.currentUserInfo.storageLis;
public var modMaterialPurchasePlan:ModPurchasePlan;

/**
 * 回车跳转事件
 */
protected function keyUpCtrl(e:KeyboardEvent, fcontrolNext:*):void
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
				if (e.currentTarget.id == "materialType")
				{
					materialClass_queryIconClickHandler(e);
					return;
				}
				if (e.currentTarget.id == "materialName")
				{
					materialName_queryIconClickHandler(e);
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

private function initValidate():void
{
	//String类验证
	var lcontrols:Array=[rate];
	for each (var control:* in lcontrols)
	{
		var vRequired:NumberValidator=new NumberValidator();
		vRequired.source=control.className == "TextInputIcon" ? control.txtContent : control;
		vRequired.property="text";
		vRequired.required=true;
		vRequired.minValue="0.01";
		vRequired.maxValue="1";
		vRequired.requiredFieldError="必填"
		_vAll.push(vRequired);
	}
}

/**
 * 去除框
 */
protected function returnHandler():void
{
	// TODO Auto-generated method stub
	PopUpManager.removePopUp(this);
}

protected function titlewindow1_closeHandler(event:Event):void
{
	PopUpManager.removePopUp(this)
}


/**
 * 确定按钮功能
 */
protected function btQuery_clickHandler(event:Event):void
{
	// TODO Auto-generated method stub

	var vResults:Array=Validator.validateAll(_vAll)
	if (vResults.length > 0)
	{
		return
	}

	var fparameter:Object={};
	var o:Object=storage.selectedItem;
	var para:ParameterObject=new ParameterObject();
	if(storage.selectedItem)
	{
		fparameter["storageCode"]=storage.selectedItem.storageCode;
	}
	fparameter["beginMonth"]=dfStart.selectedDate;
	fparameter["endMonth"]=MainToolBar.addOneDay(dfEnd.selectedDate);
	if (rate.text == "")
	{
		Alert.show("比例系数不能为空!", "提示");
		return;
	}
	fparameter["rate"]=rate.text;
	if (materialClass1 != null)
	{
		fparameter["classCode"]=materialClass1;
	}
	if (materialCode1 != null)
	{
		fparameter["materialCode"]=materialCode1;
	}
	para.conditions=fparameter;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
	{
		var _ary:ArrayCollection=new ArrayCollection();
		_ary=rev;
		var _dgPro:ArrayCollection=data.parentWin.gridDetail.dataProvider as ArrayCollection;
		for (var i:int=0; i < _ary.length; i++)
		{
			_dgPro.addItem(_ary[i])
		}
		returnHandler();
	});

	ro.autoBuildMaterialPlan(para);
}

/**
 * 物资分类字典
 */
protected function materialClass_queryIconClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialClassDict(function(rev:Object):void
	{
		event.target.text=rev.className;
		materialClass1=rev.classCode;
	}, x, y);
}

/**
 * 物资档案字典
 */
protected function materialName_queryIconClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDict(function(rev:Object):void
	{
		event.target.text=rev.materialName;
		materialCode1=rev.materialCode;
	}, x, y);
}

