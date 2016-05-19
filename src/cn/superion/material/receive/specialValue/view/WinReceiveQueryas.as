

import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.util.MainToolBar;
import cn.superion.material.util.MaterialDictShower;

import flash.events.Event;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.TextOperationEvent;



public var parentWin:*;

private var _destination:String="specialValueImpl";
private var paramsObj:Object={};
private var _tempMaterialCode:String='';
private var _tempSalerCode:String='';
private var salerClass:String="";


protected function doInit():void
{
	
	supplyDeptCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	
	materialCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
		
	salerClass=ExternalInterface.call("getSalerClass");
}


/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e, fcontrolNext);
}


/**
 * 取消按钮事件响应方法
 * */
protected function closeWin():void
{
	PopUpManager.removePopUp(this);
}

/**
 * 供应商字典：点击
 * */
protected function salerCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	MaterialDictShower.showProviderDict((function(item:Object):void
	{
		supplyDeptCode.txtContent.text=item.providerName;
		_tempSalerCode=item.providerId;
	}), x, y,null,salerClass); 
}


/**
 * 物资字典：点击
 * */
protected function materialCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	
	DictWinShower.showMaterialDict((function(item:Object):void
	{
		materialCode.txtContent.text=item.materialName;
		_tempMaterialCode=item.materialCode;
		
	}), x, y);
}

protected function btConfirm_clickHandler(event:MouseEvent):void
{
	if(_tempSalerCode=="")
	{
		Alert.show('请选择供应商','提示');
		return
	}
	var _condition:Object={};
	_condition["supplyDeptCode"]=parentWin._tempSalerCode=_tempSalerCode;
	parentWin._tempSalerName=supplyDeptCode.text;
	parentWin.invoiceNo.text='';
	
	parentWin.invoiceDate.text='';
	
	if(isGive.selected)
	{
		parentWin._isGiveSign=true;
		parentWin.invoiceNo.enabled=false;
		parentWin.invoiceDate.enabled=false;
	}
	else
	{
		parentWin._isGiveSign=false;
		parentWin.invoiceNo.enabled=false;
		parentWin.invoiceDate.enabled=true;
	}
	
	_condition["isGive"]=isGive.selected ? "1" : "0";
	_condition["materialCode"]=parentWin._materialCode=materialCode.text ? _tempMaterialCode : '';
	_condition["beginAccountDate"]=parentWin._beginAccountDate=beginAccountDate.selectedDate;
	_condition["endAccountDate"]=parentWin._endAccountDate=MainToolBar.addOneDay(endAccountDate.selectedDate);

	_condition["isGive"]=isGive.selected ? '1' : '0';
	
	var param:ParameterObject=new ParameterObject();
	param.conditions=_condition;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(_destination,function(rev:Object):void
	{
		closeWin(); 
		
		if(rev.data && rev.data.length>0 && rev.data[0])
		{
			for each(var item:Object in rev.data){
				var factoryObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict,'provider',item.factoryCode);
				item.factoryName=factoryObj==null ? "" : factoryObj.providerName;
				
				var deptObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict,'dept',item.wardCode);
				item.wardName=deptObj && item.wardCode? deptObj.deptName : '';
				item.isSelected=true;
				
				item.wholeSaleMoney=(Number(item.amount) * Number(item.wholeSalePrice)).toFixed(2);
			}
			parentWin.gdRdsDetail.dataProvider=rev.data;
			parentWin.toolBar.btPrint.enabled=true;
			parentWin.toolBar.btExp.enabled=true;
			parentWin.toolBar.btVerify.enabled=true;
		} 
		else 
		{
			parentWin.toolBar.btVerify.enabled=false;
			parentWin.toolBar.btPrint.enabled=false;
			parentWin.toolBar.btExp.enabled=false;
			parentWin.gdRdsDetail.dataProvider=null;
			Alert.show('没有查询到相关的数据','提示');
		}
		parentWin.gdRdsDetail.invalidateList();
	});
	ro.findMaterialValueDetailByCondition(param);
}


/**
 * 取消
 */
protected function btReturn_clickHandler(event:MouseEvent):void
{
	PopUpManager.removePopUp(this);
}