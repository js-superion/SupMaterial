import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.util.MaterialDictShower;

import com.adobe.utils.StringUtil;

import flexlib.scheduling.util.DateUtil;

import mx.collections.ArrayCollection;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

private var _condition:Object={};
public var parentWin:Object;

/**
 * 初始化
 **/ 
protected function doInit():void
{	
	initComBox();
	initTextInputIcon();
	fillForm();	
	
	if(MaterialDictShower.isAllUnitsDict)
	{
		unitsCode.dataProvider = MaterialDictShower.SYS_UNITS;//加载泰州南北院的信息
	}
	else
	{
		unitsCode.dataProvider = new ArrayCollection([{unitsCode:AppInfo.currentUserInfo.unitsCode,unitsSimpleName:AppInfo.currentUserInfo.unitsName}]);
		unitsCode.textInput.editable=false;
		unitsCode.requireSelection=true;
	}
//	unitsCode.requireSelection = true;
}

/**
 * 初始化ComboBox
 **/
private function initComBox():void
{
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
	//业务类型
	operationType.dataProvider = new ArrayCollection([{operationType:null,operationTypeName:'全部'},
		{operationType:'201',operationTypeName:'领用出库'},
		{operationType:'202',operationTypeName:'销售出库'},
		{operationType:'203',operationTypeName:'调拨出库'},
		{operationType:'204',operationTypeName:'盘亏出库'},
		{operationType:'205',operationTypeName:'报损出库'},
		{operationType:'209',operationTypeName:'其他出库'}]);
	operationType.textInput.editable=false;
}

/**
 * 填充表单
 **/
private function fillForm():void
{
	FormUtils.fillFormByItem(this,_condition);
	fillTextInputIcon(materialCode);
//	fillTextInputIcon(materialClass);
	fillTextInputIcon(deptCode);
//	fillTextInputIcon(rdType);
}

private function fillTextInputIcon(fctrl:Object):void{
	fctrl.text=_condition[fctrl.id+"Name"];
}

/**
 * 初始化放大镜输入框
 **/
private function initTextInputIcon():void
{
	deptCode.txtContent.editable=false;
//	materialClass.txtContent.editable=false;
	materialCode.txtContent.editable=false;
}
/**
 * 部门档案字典
 **/
protected function deptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	MaterialDictShower.showDeptDict((function(rev:Object):void
	{
		event.target.text=rev.deptName;
		_condition['deptCodeName']=rev.deptName;
		_condition['deptCode']=rev.deptCode;
	}),x,y);
}

/**
 * 出库类别
 * */
protected function rdType_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeliverTypeDict((function(rev:Object):void
	{
//		rdType.txtContent.text=_condition['rdTypeName']=rev.rdName;
		parentWin.dict["出库类别"]=rev.rdName;
		_condition['rdType']=rev.rdCode;
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
		event.target.text=rev.className;
		_condition['materialClassName']=rev.className;
		_condition['materialClass']=rev.classCode;
	}),x,y);
}

/**
 * 物资档案字典
 **/
protected function materialName_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	var storageCode:String = storageCode.selectedItem?storageCode.selectedItem.storageCode : null;
	MaterialDictShower.showMaterialDict(storageCode,(function(rev:Object):void
	{
		event.target.text=rev.materialName;
		_condition['materialCodeName']=rev.materialName;
		_condition['materialCode']=rev.materialCode;
	}),x,y);
}
/**
 * 回车事件处理方法
 **/
private function toNextControl(event:KeyboardEvent, fcontrolNext:*):void
{
	FormUtils.toNextControl(event,fcontrolNext);
}

/**
 * 放大镜键盘事件处理方法
 * */
protected function queryIcon_keyUpHandler(event:KeyboardEvent,fcontrolNext:Object):void
{
	FormUtils.textInputIconKeyUpHandler(event,_condition,fcontrolNext);
}

/**
 * 查询处理方法
 **/
protected function btConfirm_clickHandler(event:MouseEvent):void
{	
	if (storageCode.selectedItem != null && storageCode.selectedIndex > -1)
	{
		_condition['storageCode']=storageCode.selectedItem.storageCode;
		parentWin.dict["仓库"]=storageCode.selectedItem.storageName;
	}
	if (operationType.selectedItem != null && operationType.selectedIndex > -1)
	{
		_condition['operationType']=operationType.selectedItem.operationType;
	}
	if (isBillDate.selected == true)
	{
		_condition['beginBillDate']=billDateFrom.selectedDate;
		_condition['endBillDate'] = addOneDay(billDateTo.selectedDate);
		parentWin.startStrDate=DateField.dateToString(billDateFrom.selectedDate, 'YYYY-MM-DD');
		parentWin.endStrDate=DateField.dateToString(addOneDay(billDateTo.selectedDate), 'YYYY-MM-DD');
	}
	_condition['deptUnitsCode']=AppInfo.currentUserInfo.unitsCode;//StringUtil.trim(unitsCode.textInput.text).length == 0 ? null:unitsCode.selectedItem.unitsCode;
//	_condition['detailRemark']=detailRemark.text;
	//行政物资需求，按照行政物资的出库类别分组，以后扩展
	
    var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions=_condition;		
	PopUpManager.removePopUp(this);

	var laryDisplays:Array=[parentWin.toolBar.btPrint, parentWin.toolBar.btExp, parentWin.toolBar.imageList1, parentWin.toolBar.btQuery, parentWin.toolBar.imageList6, parentWin.toolBar.btExit];
	var laryEnables:Array;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(parentWin.DESTINATION, function(rev:Object):void
	{
		//setToolBarBts(rev);
		 if(rev && rev.data[0] != null){
			 var i:int = 1;
			 for each(var item:Object in rev.data[0]){
				 			if(item.deptCode){
				 				 item.deptName =  ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict,'dept',item.deptCode)?ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict,'dept',item.deptCode).deptName:"";
				 			 }else{
				 				 item.deptName = "";
				 			 }
							 item['sum'] = Number(item['sum']?item['sum']:0);
							 item['remark'] = item['remark']?item['remark']:"";
							 item['血费'] = Number(item['血费']?item['血费']:0);
							 item['气体费'] = Number(item['气体费']?item['气体费']:0);
							 item['固定资产'] = Number(item['固定资产']?item['固定资产']:0);
							 item['（单）放射_G'] = Number(item['（单）放射_G']?item['（单）放射_G']:0);
							 item['（单）化验_G'] = Number(item['（单）化验_G']?item['（单）化验_G']:0);
							 item['（单）植入_G'] = Number(item['（单）植入_G']?item['（单）植入_G']:0);
							 item['（单）介入_G'] = Number(item['（单）介入_G']?item['（单）介入_G']:0);
							 item['（单）其他_G'] = Number(item['（单）其他_G']?item['（单）其他_G']:0);
							 item['（非单）放射_G'] = Number(item['（非单）放射_G']?item['（非单）放射_G']:0);
							 item['（非单）化验_G'] = Number(item['（非单）化验_G']?item['（非单）化验_G']:0);
							 item['（非单）植入_G'] = Number(item['（非单）植入_G']?item['（非单）植入_G']:0);
							 item['（非单）介入_G'] = Number(item['（非单）介入_G']?item['（非单）介入_G']:0);
							 item['（非单）其他_G'] = Number(item['（非单）其他_G']?item['（非单）其他_G']:0);
							 item['（单）放射_D'] = Number(item['（单）放射_D']?item['（单）放射_D']:0);
							 item['（单）化验_D'] = Number(item['（单）化验_D']?item['（单）化验_D']:0);
							 item['（单）植入_D'] = Number(item['（单）植入_D']?item['（单）植入_D']:0);
							 item['（单）介入_D'] = Number(item['（单）介入_D']?item['（单）介入_D']:0);
							 item['（单）其他_D'] = Number(item['（单）其他_D']?item['（单）其他_D']:0);
							 item['（非单）放射_D'] = Number(item['（非单）放射_D']?item['（非单）放射_D']:0);
							 item['（非单）化验_D'] = Number(item['（非单）化验_D']?item['（非单）化验_D']:0);
							 item['（非单）植入_D'] = Number(item['（非单）植入_D']?item['（非单）植入_D']:0);
							 item['（非单）介入_D'] = Number(item['（非单）介入_D']?item['（非单）介入_D']:0);
							 item['（非单）其他_D'] = Number(item['（非单）其他_D']?item['（非单）其他_D']:0);
							 item['rowno']=i;
							 i++;
//							 for(var property:String in item){
//							 	if(property != 'sum' && property != 'remark' && property != 'deptCode'){
//									item[property] = item[property]?item[property]:0;
//								}
//							 }
//							 for each(var item1:Object in parentWin.initArray){
//									if(!item.hasOwnProperty(item1.materialClass)){
//										item[item1.materialClass] = 0;
//									}
//							 }
			 			 }
			 parentWin.gdDeliver.dataProvider=rev.data[0];
		 }
	});
	ro.findDeliverCountClassListByDeptMedicalReceiveFee(paramQuery);//byzcl
}

/**
 * 设置当前按钮是否显示
 */
private function setToolBarBts(rev:Object):void
{
	if (rev.data && rev.data.length)
	{
		parentWin.gdDeliver.sumRowLabelText="合计";
		parentWin.toolBar.btPrint.enabled=true;
		parentWin.toolBar.btExp.enabled=true;
	}
	else
	{
		parentWin.gdDeliver.sumRowLabelText="";
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