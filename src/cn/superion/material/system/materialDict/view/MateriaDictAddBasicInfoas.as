import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.system.materialDict.view.MaterialDictAdd;
import cn.superion.vo.center.config.CdStorageDict;
import cn.superion.vo.center.material.CdMaterialClass;
import cn.superion.vo.center.provider.CdProvider;

import flash.events.Event;

import mx.events.FlexEvent;
import mx.rpc.remoting.mxml.RemoteObject;

import spark.components.CheckBox;
import spark.events.IndexChangeEvent;
import spark.events.TextOperationEvent;
import mx.collections.ArrayCollection;

private var _isShow:Boolean=false;//显示小数位数，东方3，泰州2

private function priceFix2(con:*):void
{
	if (con.text != "" && con.text != "")
	{
		if(_isShow){
			con.text=Number(con.text).toFixed(3);
		}else{
			con.text=Number(con.text).toFixed(2);
		}
		
	}
	wholeSalePrice.text=tradePrice.text;
//	retailPrice.text=tradePrice.text;
//	invitePrice.text=tradePrice.text;
	MaterialDictAdd.currentItem.wholeSalePrice=Number(wholeSalePrice.text);
	MaterialDictAdd.currentItem.invitePrice=Number(invitePrice.text);
	MaterialDictAdd.currentItem.retailPrice=Number(retailPrice.text);
}
/**
 * 商品名称
 */ 
protected function businessName_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub
	MaterialDictAdd.currentItem.businessName=generalName.text;
	var ro:RemoteObject=RemoteUtil.getRemoteObject('baseCommonDictImpl', function(rev:Object):void
	{
		if (rev.data && rev.data.length > 0)
		{
			MaterialDictAdd.currentItem.generalFiveInputCode=rev.data[1]
			MaterialDictAdd.currentItem.generalPhoInputCode=rev.data[0]
			generalPhoInputCode.text=rev.data[0];
			generalFiveInputCode.text=rev.data[1];
		}
	})
	ro.findInputCode(generalName.text)
}
/**
 * 包装规格
 */ 
protected function minSpec_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub
	MaterialDictAdd.currentItem.packageSpec=packageSpec.text;
}
/**
 * 包装单位
 */ 
protected function minUnits_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub
	MaterialDictAdd.currentItem.packageUnits=packageUnits.text;
}
/**
 * 包装系数
 */ 
protected function minPerSpec_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub
	MaterialDictAdd.currentItem.amountPerPackage=Number(amountPerPackage.text);
}
protected function materialClass_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialClassDict(function(item:CdMaterialClass):void
		{
			materialClass.text=item.className;
			MaterialDictAdd.currentItem.materialClass=item.classCode;
		}, x, y);
}

protected function doInit(event:FlexEvent):void
{
	// TODO Auto-generated method stub
	//阻止放大镜表格输入内容 
//	countClass.dataProvider=new ArrayCollection([{data:'血费'},{data:'气体费'},{data:'（单独计价）放射材料'},{data:'（非单独计价）放射材料'},
//		{data:'（单独计价）介入材料'},{data:'（非单独计价）介入材料'},
//		{data:'（单独计价）其他卫生材料'},{data:'（非单独计价）其他卫生材料'},{data:'（单独计价）放射材料'},{data:'（非单独计价）放射材料'},
//		{data:'（单独计价）植入材料'},{data:'（非单独计价）植入材料'},{data:'（单独计价）检验材料'},{data:'（非单独计价）检验材料'}]);
	
	countClass.dataProvider=new ArrayCollection([{data:'血费'},{data:'气体费'},{data:'固定资产'},{data:'（单）放射_G'},{data:'（单）化验_G'},
		{data:'（单）植入_G'},{data:'（单）介入_G'},
		{data:'（单）其他_G'},{data:'（非单）放射_G'},{data:'（非单）化验_G'},{data:'（非单）植入_G'},
		{data:'（非单）介入_G'},{data:'（非单）其他_G'},{data:'（单）放射_D'},{data:'（单）化验_D'},
		{data:'（单）植入_D'},{data:'（单）介入_D'},{data:'（单）其他_D'},{data:'（非单）放射_D'},
		{data:'（非单）化验_D'},{data:'（非单）植入_D'},{data:'（非单）介入_D'},{data:'（非单）其他_D'}]);
	preventDefaultForm();
	packageSpec.width=factoryCode.width=generalName.width=materialName.width=materialClass.width;
	fixedSign.width=logisticSign.width=healthSign.width=agentSign.width;
	//是否显示备注，东方1是，泰州0否
	var ros:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl', function(rev:Object):void
	{
		if (rev.data && rev.data[0] == '1')
		{
			_isShow=true; 
		}
		else{
			_isShow=false; 
		}
		
	});
	ros.findSysParamByParaCode("0609");
}
/**
 * 阻止放大镜表格输入内容 
 */
private function preventDefaultForm():void
{
	materialClass.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	
	factoryCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	
	mainProvider.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
}
/**
 * 物资名拼音简码Change
 */ 
protected function phoInputCode_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub
	
	MaterialDictAdd.currentItem.generalPhoInputCode=phoInputCode.text;
}
/**
 * 物资名五笔简码Change
 */ 
protected function fiveInputCode_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub
	MaterialDictAdd.currentItem.generalFiveInputCode=fiveInputCode.text;
}
/**
 * 通用名拼音简码Change
 */ 
protected function generalPhoInputCode_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub
	MaterialDictAdd.currentItem.generalPhoInputCode=generalPhoInputCode.text;
}
/**
 * 通用名五笔码Change
 */ 
protected function generalFiveInputCode_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub
	MaterialDictAdd.currentItem.generalFiveInputCode=generalFiveInputCode.text;
}

/**
 * 给物资名、拼音五笔简码文本赋值
 */ 
protected function generalName_focusOutHandler(event:FocusEvent):void
{
	// TODO Auto-generated method stub
	fpinput();
	MaterialDictAdd.currentItem.storageDefault=storageDefault.selectedItem?storageDefault.selectedItem.storageCode:null;
}
protected function mainProvider_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict(function(item:CdProvider):void
		{
			mainProvider.text=item.providerName;
			MaterialDictAdd.currentItem.mainProvider=item.providerId;
		}, x, y);
}

protected function factoryCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict(function(item:CdProvider):void
		{
			factoryCode.text=item.providerName;
			MaterialDictAdd.currentItem.factoryCode=item.providerId;
		}, x, y);
}
/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
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
				if (e.currentTarget.id == "factoryCode")
				{
					factoryCode_queryIconClickHandler(e);
					return;
				}
				if (e.currentTarget.id == "materialClass")
				{
					materialClass_queryIconClickHandler(e);
					return;
				}
				if (e.currentTarget.id == "mainProvider")
				{
					mainProvider_queryIconClickHandler(e);
					return;
				}
			}
			if (fcontrolNext is TextInputIcon)
			{
				fcontrolNext.txtContent.setFocus()
				return;
			}
		}
		fcontrolNext.setFocus()
	}
}

public static function changeHandler(event:Event):void
{
	FormUtils.changHandler(event, MaterialDictAdd.currentItem);
	fillInputCodeToData(event); 
}

protected function storageDefault_changeHandler(event:IndexChangeEvent):void
{
	MaterialDictAdd.currentItem.storageDefault=storageDefault.selectedItem?storageDefault.selectedItem.storageCode:null;
}


public static function fillInputCodeToData(e:Event):void
{
	if (e.currentTarget.id == 'materialName')
	{
		var ro:RemoteObject=RemoteUtil.getRemoteObject('baseCommonDictImpl', function(rev:Object):void
			{
				if (rev.data && rev.data.length > 0)
				{
					MaterialDictAdd.currentItem.fiveInputCode=rev.data[1]
					MaterialDictAdd.currentItem.phoInputCode=rev.data[0]
					
				}
			})
		ro.findInputCode(e.currentTarget.text)
	}
}
/**
 * 给物资名称文本赋值
 */ 
public function fpinput():void
{
	fiveInputCode.text=MaterialDictAdd.currentItem.fiveInputCode;
	phoInputCode.text=MaterialDictAdd.currentItem.phoInputCode;
}
public static function chkChangeHandler(event:Event):void
{
	var chkItem:CheckBox=event.target as CheckBox;
	MaterialDictAdd.currentItem[chkItem.id]=chkItem.selected ? "1" : "0"
}