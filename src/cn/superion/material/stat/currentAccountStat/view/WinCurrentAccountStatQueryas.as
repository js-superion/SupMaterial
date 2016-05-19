import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.stat.currentAccountStat.ModCurrentAccountStat;
import cn.superion.material.util.MaterialDictShower;

import flash.events.Event;

import flexlib.scheduling.util.DateUtil;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

private  var _condition:Object={};

public var parentWin:ModCurrentAccountStat;

private function doInit():void
{
	initComBox();
	initTextInputIcon();
	fillForm();
}

/**
 * 初始化ComboBox
 */
private function initComBox():void
{
	//授权仓库赋值
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
	
	//业务类型赋值
	var opTypeList:ArrayCollection=new ArrayCollection();
	var opTypeObj:Object=new Object();
	opTypeObj['operationType']=null;
	opTypeObj['operationTypeName']="全部";
	opTypeList.addItem(opTypeObj);
	for(var i:int=0;i<BaseDict.operationTypeDict.length;i++)
	{
		opTypeList.addItem(BaseDict.operationTypeDict[i]);
	}
	operationType.dataProvider=opTypeList;
	operationType.textInput.editable=false;
	
	
	
	//收发类别赋值	
	var laryRdType:ArrayCollection=new ArrayCollection();
	var lrtObj:Object=new Object();
	lrtObj['rdType']=null;
	lrtObj['rdTypeName']='全部';
	laryRdType.addItem(lrtObj);
	
	var laryReceviceType:ArrayCollection=BaseDict.receviceTypeDict;
	var laryDeliverType:ArrayCollection=BaseDict.deliverTypeDict;
	var len:int=laryReceviceType.length;
	laryReceviceType.addAllAt(laryDeliverType, len);
	for each (var item:Object in laryReceviceType)
	{
		var lary:Object=new Object();
		if (item.receviceType)
		{
			lary.rdType=item.receviceType;
			lary.rdTypeName=item.receviceTypeName;
		}
		if (item.deliverType)
		{
			lary.rdType=item.deliverType;
			lary.rdTypeName=item.deliverTypeName;
		}
		laryRdType.addItem(lary);
	}
	rdType.dataProvider=laryRdType;
	rdType.textInput.editable=false;
}

/**
 * 填充表单
 **/
private function fillForm():void
{
	FormUtils.fillFormByItem(this, _condition);
	fillTextInputIcon(materialClass);
	fillTextInputIcon(factoryCode);
	fillTextInputIcon(salerCode);
	fillTextInputIcon(deptCode);
	fillTextInputIcon(maker);
	fillTextInputIcon(verifier);
}

private function fillTextInputIcon(fctrl:Object):void
{
	fctrl.text=_condition[fctrl.id + "Name"];
}

/**
 * 初始化放大镜输入框
 **/
private function initTextInputIcon():void
{
	materialClass.txtContent.editable=false;
	beginMaterialCode.txtContent.editable=false;
	endMaterialCode.txtContent.editable=false;
	factoryCode.txtContent.editable=false;
	salerCode.txtContent.editable=false;
	deptCode.txtContent.editable=false;
	personId.txtContent.editable=false;
	maker.txtContent.editable=false;
	verifier.txtContent.editable=false;
}

/**
 * 处理回车键转到下一个控件
 **/
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e, fcontrolNext);
}

/**
 * 供应单位
 */
protected function salerCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict((function(rev:Object):void
		{
			salerCode.txtContent.text=rev.providerName;
			_condition['salerCodeName']=rev.providerName;
			_condition['salerCode']=rev.providerId;
		}), x, y);
}

/**
 * 部门
 */
protected function deptCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict((function(rev:Object):void
		{
			deptCode.txtContent.text=rev.deptName;
			_condition['deptCodeName']=rev.deptName;
			_condition['deptCode']=rev.deptCode;
		}), x, y);
}

/**
 * 生产厂家
 */
protected function factoryCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict((function(rev:Object):void
		{
			factoryCode.txtContent.text=rev.providerName;
			_condition['factoryCodeName']=rev.providerName;
			_condition['factoryCode']=rev.providerId;
		}), x, y);
}

/**
 * 业务员
 */
protected function personId_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict((function(rev:Object):void
		{
			personId.txtContent.text=rev.personIdName;
			_condition['personId']=rev.personId;
		}), x, y);
}

/**
 * 制单人
 */
protected function maker_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict((function(rev:Object):void
		{
			maker.txtContent.text=rev.personIdName;
			_condition['makerName']=rev.personIdName;
			_condition['maker']=rev.personId;
		}), x, y);
}

/**
 * 审核人
 */
protected function verifier_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict((function(rev:Object):void
		{
			verifier.txtContent.text=rev.personIdName;
			_condition['verifierName']=rev.personIdName;
			_condition['verifier']=rev.personId;
		}), x, y);
}

/**
 * 物资编码
 */
protected function materialCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	var storageCode:String = storageCode.selectedItem?storageCode.selectedItem.storageCode : null;
	MaterialDictShower.showMaterialDict(storageCode,(function(rev:Object):void
		{
			event.target.text=rev.materialCode;
			_condition[event.target.id]=rev.materialCode;
			endMaterialCode.txtContent.text=rev.materialCode;
			_condition["endMaterialCode"]=rev.materialCode;
			
		}), x, y);
}

/**
 * 物资分类
 */
protected function materialClass_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialClassDict((function(rev:Object):void
		{
			materialClass.text=rev.className;
			parentWin.dict["物资分类"]=_condition['materialClassName']=rev.className;
			_condition['materialClass']=rev.classCode;
		}), x, y);
}

/**
 * 放大镜键盘事件处理方法
 * */
protected function queryIcon_keyUpHandler(event:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.textInputIconKeyUpHandler(event, _condition, fcontrolNext);
}

/**
 * 查询
 */
protected function btConfirm_clickHandler(event:MouseEvent):void
{
	if (storageCode.selectedItem)
	{
		_condition['storageCode']=storageCode.selectedItem.storageCode;
		_condition['storageCodeName']=storageCode.selectedItem.storageName;
	}
	if (operationType.selectedItem)
	{
		_condition['operationType']=operationType.selectedItem.operationType;
		parentWin.dict["业务类型"]=_condition['operationTypeName']=operationType.selectedItem.operationTypeName;
	}
	if (rdType.selectedItem)
	{
		_condition['rdType']=rdType.selectedItem.rdType;
		_condition['rdTypeName']=rdType.selectedItem.rdTypeName;
	}
	_condition["beginBillNo"]=minBillNo.text;
	_condition["endBillNo"]=maxBillNo.text;
	_condition["beginBillDate"]=billDate.selected ? beginBillDate.selectedDate : null;
	_condition["endBillDate"]=billDate.selected ? addOneDay(endBillDate.selectedDate) : null;
	if (isVerifyDate.selected)
	{
		_condition["beginVerifyDate"]=beginVerifyDate.selectedDate;
		_condition["endVerifyDate"]=addOneDay(endVerifyDate.selectedDate);
	}
	else
	{
		_condition["beginVerifyDate"]=null;
		_condition["endVerifyDate"]=null;
	}

	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions=_condition;
	PopUpManager.removePopUp(this);

	var ro:RemoteObject=RemoteUtil.getRemoteObject(parentWin.DESTINATION, function(rev:Object):void
		{
		    setToolBarBts(rev);
			for each(var item:Object in rev.data)
			{
				if(item.detailRemark==null)
				{
					item.detailRemark="";
				}
				if(item.remark==null)
				{
					item.remark="";
				}
				item.detailRemark=item.detailRemark+item.remark;
			}
			parentWin.gridCurrentAccount.dataProvider=rev.data;
		});
	ro.findCurrentAccountListByCondition(paramQuery);
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
