/**
 *		 物资领用申请过滤模块
 *		 作者:
 *		 修改：周作建 2011.06.08
 **/

import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.util.MainToolBar;
import cn.superion.material.util.MaterialDictShower;
import cn.superion.vo.material.MaterialProvideMaster;
import cn.superion.vo.material.MaterialRdsDetail;

import flash.net.SharedObject;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

import spark.events.TextOperationEvent;

public var parentWin:Object;
private var destination:String="deliverImpl";

private var _deptCode:String="";
private var isTanchu:Boolean=false;//保存后是否弹出增加界面。
private var shareObj:SharedObject = null;
protected function doInit():void
{
	shareObj=SharedObject.getLocal("shareObj");
	//授权仓库赋值
	if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
	{
		var result:ArrayCollection =ObjectUtil.copy(AppInfo.currentUserInfo.storageList) as ArrayCollection;
		var newArray:ArrayCollection = new ArrayCollection();
		for each(var it:Object in result){
			if(it.type == '2'||it.type == '3'){
				newArray.addItem(it);
			}
		}
		storageCode.dataProvider=newArray;//AppInfo.currentUserInfo.storageList;
		if(shareObj.data.selectedIndex){
			storageCode.selectedIndex = shareObj.data.selectedIndex;
		}else{
			storageCode.selectedIndex=0;
		}
		storageCode.selectedItem = newArray[storageCode.selectedIndex];
		
	}
	//阻止表单输入
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	dept.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
}


import spark.events.IndexChangeEvent;
import cn.superion.material.util.ToolBar;
import cn.superion.material.util.DefaultPage;
import flash.events.KeyboardEvent;

protected function storageCode_changeHandler(event:IndexChangeEvent):void
{
	// TODO Auto-generated method stub
	shareObj.data.selectedIndex = event.newIndex;
}

/**
 * 部门字典
 */ 
protected function dept_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(rev:Object):void
	{
		dept.txtContent.text=rev.deptName;
		_deptCode=rev.deptCode;
	}, x, y);
}

/**
 * 回车事件
 **/
private function toNextCtrl(event:KeyboardEvent, fctrlNext:Object):void
{
	if (event.keyCode != Keyboard.ENTER)
	{
		return;
	}
	//
	FormUtils.toNextControl(event, fctrlNext);
}

/**
 * 查询
 * */
protected function btQuery_clickHandler():void
{
	gridApplyDetail.dataProvider=null;
	var params:Object={};
	var paramQuery:ParameterObject=new ParameterObject();
	params["storageCode"]=storageCode.selectedItem?storageCode.selectedItem.storageCode:"";
	if(beDate.selected){
		params["beginBillDate"]=beginBillDate.selectedDate;
		params["endBillDate"] = MainToolBar.addOneDay(endBillDate.selectedDate);
	}else{
		params["beginBillDate"]=null;
		params["endBillDate"] = null;
	}
	params["materialName"]=materialCode.txtContent.text;
	params["deptCode"]=_deptCode;
	params["billNo"]=billNo.text;
	paramQuery.conditions=params;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
	{
		if(rev && rev.data.length >=0){
			gridApplyDetail.dataProvider=rev.data;
		}
	});
	ro.findProvideByCondition(paramQuery);
}


/**
 * 确定
 * */
protected function btConfirmHandler(event:MouseEvent):void
{
	if(gridApplyDetail.dataProvider.length<=0)
	{
		return;
	}
	DefaultPage.exportExcel(gridApplyDetail,"计划采购明细");
	
}

/**
 * 生产厂家
 */
private function factoryLBF(item:Object, column:DataGridColumn):String
{
	if (item.factoryCode == '')
	{
		item.factoryName='';
	}
	else
	{
		var provider:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict, 'provider', item.factoryCode);
		
		item.factoryName=provider == null ? "" : provider.providerName;
	}
	return item.factoryName;
}
/**
 * 请领单位
 */ 
private function labelFunDeptUnitsCode(item:Object, column:DataGridColumn):*
{
	return displayName("deptUnitsCode", item.unitsCode); //当前 登陆人员所在的单位，如，南北院
}
/**
 * 请领部门
 */ 
private function labelFunDeptCode(item:Object, column:DataGridColumn):*
{
	return displayName("deptCode", item.deptCode);
}
/**
 * 请领人员
 */ 
private function labelFunPersonId(item:Object, column:DataGridColumn):*
{
	return displayName("personId", item.personId);
}

/**
 *物资档案字典
 **/
protected function materialName_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	var code:String = storageCode.selectedItem?storageCode.selectedItem.storageCode : null;
	MaterialDictShower.showMaterialDict(code,(function(rev:Object):void
	{
		materialCode.txtContent.text=rev.materialName;
	}), x, y);
}

/**
 * 由编码显示名称
 */ 
private function displayName(item:*, txt:String):*
{
	var fItem:Object;
	//所属单位
	if (item == "deptUnitsCode")
	{
		var deptUnitsName:String = "";
		for each (var it:Object in MaterialDictShower.SYS_UNITS){
			if(it.unitsCode == txt){
				deptUnitsName = it.unitsSimpleName;
			}
		}
		return deptUnitsName;
	}
	//部门
	if (item == "deptCode")
	{
		fItem=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, "dept", txt);
		if (fItem)
		{
			return fItem.deptName;
		}
		return txt;
	}
	//业务员
	if (item == "personId")
	{
		fItem=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, "personId", txt);
		if (fItem)
		{
			return fItem.personIdName;
		}
		return txt;
	}
}
private var tempAry:ArrayCollection=new ArrayCollection;
protected function btReturn_clickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	DefaultPage.gotoDefaultPage();
}

