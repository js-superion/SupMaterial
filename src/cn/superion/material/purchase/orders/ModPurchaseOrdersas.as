/**
 *		 采购订单处理
 *		 作者: 朱玉峰 2011.06.18
 *		 修改：
 **/
import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.purchase.orders.view.PurchaseApplyFilter;
import cn.superion.material.purchase.orders.view.PurchaseOrdersQuery;
import cn.superion.material.purchase.orders.view.PurchasePlanFilter;
import cn.superion.material.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialOrderDetail;
import cn.superion.vo.material.MaterialOrderMaster;

import flash.ui.ContextMenu;
import flash.utils.Dictionary;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.core.IFlexDisplayObject;
import mx.core.UIComponent;
import mx.events.CloseEvent;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.TextOperationEvent;

private static const MENU_NO:String="0103";
public var DESTANATION:String="orderImpl";
//业务类型
public var typeArc:ArrayCollection=BaseDict.buyOperationTypeDict;
//主记录
public var _materialOrderMaster:MaterialOrderMaster=new MaterialOrderMaster();
//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;
public var menuItemsName:Array=null;
public var functions:Array=null;
private var winY:int=0;
public var menuItemsEnableValues:Object=['0', '0']; //1表可用，0不可用

/**
 * 初始化方法
 */
public function doInit():void
{
	//重新注册客户端对应的服务端类
	registerClassAlias("cn.superion.material.entity.MaterialOrderMaster", MaterialOrderMaster);
	registerClassAlias("cn.superion.material.entity.MaterialOrderDetail", MaterialOrderDetail);
	//放大镜不可手动输入
	preventDefaultForm();
	initPanel();
	initToolBar();
}

/**
 * 面板初始化
 */
private function initPanel():void
{
	setReadOnly(false);
	if(parentDocument is WinModual){
		parentDocument.title="采购订单处理";
	}
	deptCode.width=operationType.width;
	personId.width=billNo.width;
	payCondition.width=billDate.width;
	remark.width=salerCode.width;
	factoryCode.width=materialCode.width;
	
	menuItemsName=['采购计划', '采购申请'];
	functions=[callbackPlan, callbackApply];
	dgOrdersDetail.contextMenu=initContextMenu(dgOrdersDetail, menuItemsName, functions);
	dgOrdersDetail.contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, menuItemEnabled);
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, toolBar.btSave, toolBar.btVerify, toolBar.btAddRow, toolBar.btDelRow, toolBar.btQuery, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.btExit, toolBar.imageList1, toolBar.imageList2, toolBar.imageList3, toolBar.imageList5, toolBar.imageList6];
	var laryEnables:Array=[toolBar.btAdd, toolBar.btQuery, toolBar.btExit];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	FormUtils.setFormItemEditable(allPanel, boolean);
	addPanel.visible=boolean;
	addPanel.includeInLayout=boolean;
	operationType.enabled=boolean;
	toolBar.btDelete.enabled=boolean;
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	deptCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	
	personId.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	
	salerCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	materialCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	factoryCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
}

/**
 * 清空表单
 */
public function clearForm():void
{
	dgOrdersDetail.dataProvider=null;
	FormUtils.clearForm(allPanel);
	billDate.selectedDate=new Date;
	operationType.selectedIndex=0;
	planArriveDate.selectedDate=new Date;
	_materialOrderMaster=new MaterialOrderMaster();
}
/**
 * 清空明细
 */
private function clearDetail():void
{
	FormUtils.clearForm(addPanel);
	planArriveDate.selectedDate=new Date;
}

/**
 * keyUp事件
 */
private function toNextControl(e:KeyboardEvent, fcontrolNext:*):void
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
				if (e.currentTarget.id == "deptCode")
				{
					deptCode_queryIconClickHandler(e);
					return;
				}
				if (e.currentTarget.id == "personId")
				{
					personId_queryIconClickHandler(e);
					return;
				}
				if (e.currentTarget.id == "salerCode")
				{
					productCode_queryIconClickHandlers(e);
					return;
				}
				if (e.currentTarget.id == "materialCode")
				{
					materialCode_queryIconClickHandler(e);
					return;
				}
				if (e.currentTarget.id == "factoryCode")
				{
					productCode_queryIconClickHandler(e);
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
 * 数量key事件
 */
protected function amountKey(e:KeyboardEvent, fcontrolNext:*):void
{
	if (e.keyCode == Keyboard.ENTER)
	{
		if (!dgOrdersDetail.selectedItem)
		{
			return;
		}
		if ((dgOrdersDetail.selectedItem.amount) <= 0)
		{
			return;
		}
		fcontrolNext.setFocus();
	}
}

/**
 *  明细表备注回车事件
 */
protected function remarkDetail_keyUpHandler(event:KeyboardEvent):void
{
	if (event.keyCode == Keyboard.ENTER)
	{
		if (!dgOrdersDetail.selectedItem)
		{
			return;
		}
		if (dgOrdersDetail.selectedItem.amount <= 0)
		{
			Alert.show("数量不能小于或等于零!", "提示", Alert.YES, null, huiCallback);
			return;
		}
		materialCode.text='';
		materialCode.txtContent.setFocus();
	}
}
/**
 * 业务类型字典
 */
protected function ddlStorageName_creationCompleteHandler(event:FlexEvent):void
{
	for each (var item:Object in typeArc)
	{
		if (item.operationTypeName == '')
		{
			typeArc.removeItemAt(typeArc.getItemIndex(item))
		}
	}
	operationType.selectedIndex=0;
	operationType.dataProvider=typeArc;
}

/**
 * 供应商字典
 */
protected function productCode_queryIconClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict(function(rev:Object):void
	{
		event.target.text=rev.providerName;
		if (dgOrdersDetail.selectedItem)
		{
			dgOrdersDetail.selectedItem.factoryCode=rev.providerId;
			
		}
		dgOrdersDetail.invalidateList();
	}, winY, y);
}

/**
 * 供应商字典
 */
protected function productCode_queryIconClickHandlers(event:Event):void
{
	// TODO Auto-generated method stub
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict(function(rev:Object):void
	{
		event.target.text=rev.providerName;
		_materialOrderMaster.salerCode=rev.providerId;
		dgOrdersDetail.invalidateList();
	}, winY, y);
}

/**
 * 供应商Code转换成名称
 */
private function labelFun(item:Object, salerCode:DataGridColumn):*
{
	var s:Object=BaseDict.providerDict;
	if (salerCode.headerText == "生产厂家")
	{
		var factoryCodeItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict, 'provider', item.factoryCode);
		if (!factoryCodeItem)
		{
			return '';
		}
		else
		{
			item.factoryName=factoryCodeItem.providerName;
			return item.factoryName
		}
	}
}

/**
 * 部门字典
 */
protected function deptCode_queryIconClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(rev:Object):void
	{
		event.target.text=rev.deptName;
		_materialOrderMaster.deptCode=rev.deptCode;
	}, winY, y);
}

/**
 * 人物档案字典
 */
protected function personId_queryIconClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict(function(rev:Object):void
	{
		event.target.text=rev.personIdName;
		_materialOrderMaster.personId=rev.personId;
	}, winY, y);
}

/**
 * 物资字典
 */
protected function materialCode_queryIconClickHandler(event:Event):void
{
	//打开物资字典
	var y:int=this.parentApplication.screen.height - 338;
	var lstorageCode:String='';
	lstorageCode=null;
	DictWinShower.showMaterialDictNew(lstorageCode, '', '', true, function(faryItems:Array):void
	{
		//先清空“增加面板addPanel”
		FormUtils.clearForm(addPanel);
		planArriveDate.selectedDate=new Date;
		detailRemark.text="";
		fillIntoGrid(faryItems);
	}, winY, y);
}

/**
 * 自动完成表格回调
 * */
private function fillIntoGrid(faryItems:Array):void
{
	amount.setFocus();
	var laryDetails:ArrayCollection=dgOrdersDetail.dataProvider as ArrayCollection;
	//放大镜取出的值、赋值
	for(var i:int=0;i<faryItems.length;i++)
	{
		var materialOrderDetail:MaterialOrderDetail=new MaterialOrderDetail();
		materialOrderDetail=fillDetailForm(faryItems[i]);
		materialOrderDetail.arrivalAmount=0;
		laryDetails.addItem(materialOrderDetail);
	}
	dgOrdersDetail.dataProvider=laryDetails;
	dgOrdersDetail.selectedIndex=laryDetails.length - 1;
	materialCode.text=faryItems[faryItems.length-1].materialCode;
}


/**
 * 给明细赋值
 */
private function fillDetailForm(faryItems:Object):MaterialOrderDetail
{
	var materialOrderDetail:MaterialOrderDetail=new MaterialOrderDetail();
	materialOrderDetail.sourceSerialNo=0;
	materialOrderDetail.serialNo=0;
	materialOrderDetail.inputAmount=0;
	//物资编码
	materialOrderDetail.materialCode=faryItems.materialCode;
	//物资Id
	materialOrderDetail.materialId=faryItems.materialId;
	//物资类型
	materialOrderDetail.materialClass=faryItems.materialClass;
	//物资名称
	materialOrderDetail.materialName=faryItems.materialName;
	//规格型号
	materialOrderDetail.materialSpec=faryItems.materialSpec;
	//单位
	materialOrderDetail.materialUnits=faryItems.materialUnits;
	//进价
	materialOrderDetail.tradePrice=faryItems.tradePrice;
	
	//售价
	materialOrderDetail.retailPrice=faryItems.retailPrice;
	//初始数量
	materialOrderDetail.amount=1;
	materialOrderDetail.chargeSign = faryItems.chargeSign;//收费标示；
	materialOrderDetail.classOnAccount = faryItems.accountClass;//会计分类；
	//金额
	materialOrderDetail.tradeMoney=faryItems.amount * faryItems.tradePrice;
	//售价金额
	materialOrderDetail.retailMoney=faryItems.amount * faryItems.retailPrice;
	//到货日期
	materialOrderDetail.planArriveDate=planArriveDate.selectedDate;
	materialName.text=materialOrderDetail.materialName;
	materialSpec.text=materialOrderDetail.materialSpec;
	materialUnits.text=materialOrderDetail.materialUnits;
	tradePrice.text = materialOrderDetail.tradePrice.toString();
	var timer:Timer=new Timer(100, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
	{
		amount.setFocus();
	})
	timer.start();
	return materialOrderDetail;
}

/**
 * 明细表格赋值
 */
private function EvaluateList(mcpd:MaterialOrderDetail):void
{
	FormUtils.fillFormByItem(addPanel, mcpd);
}

/**
 * 给主记录赋值
 */
private function fillRdsMaster():MaterialOrderMaster
{
	_materialOrderMaster.operationType=operationType.selectedItem == false ? null : operationType.selectedItem.operationType;
	_materialOrderMaster.billNo=billNo.text == "" ? null : billNo.text;
	_materialOrderMaster.billDate=billDate.selectedDate;
	_materialOrderMaster.remark=remark.text == "" ? null : remark.text;
	_materialOrderMaster.totalCosts=0;
	_materialOrderMaster.payCondition=payCondition.text;
	var lstBloodRdsDetail:ArrayCollection=dgOrdersDetail.dataProvider as ArrayCollection;
	for (var i:int=0; i <= lstBloodRdsDetail.length - 1; i++)
	{
		_materialOrderMaster.totalCosts=_materialOrderMaster.totalCosts + Number(lstBloodRdsDetail[i].tradeMoney);
	}
	return _materialOrderMaster;
}
/**
 * 给主记录赋值
 */
protected function fillRdsText(mpm:MaterialOrderMaster):void
{
	FormUtils.fillFormByItem(this, mpm);
	FormUtils.selectComboItem(operationType, "operationType", mpm.operationType);
	var salerCodeObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict, 'provider', mpm.salerCode);
	salerCode.text=salerCodeObj==null?null:salerCodeObj.providerName;
	var bm:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', mpm.deptCode);
	deptCode.txtContent.text=bm == null ? null : bm.deptName;
	var yw:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', mpm.personId);
	personId.txtContent.text=yw == null ? null : yw.personIdName;
	maker.text=shiftTo(mpm.maker);
	verifier.text=shiftTo(mpm.verifier);
}

/**
 * 所有Change事件
 */
protected function evaluate_changeHandler(event:Event):void
{
	if (!dgOrdersDetail.selectedItem)
	{
		return;
	}
	dgOrdersDetail.selectedItem.amount=Number(amount.text);
	dgOrdersDetail.selectedItem.tradePrice=Number(tradePrice.text);
	dgOrdersDetail.selectedItem.tradeMoney=(Number(amount.text)) * (Number(tradePrice.text));
	dgOrdersDetail.selectedItem.retailMoney= dgOrdersDetail.selectedItem.amount * dgOrdersDetail.selectedItem.retailPrice;
	dgOrdersDetail.selectedItem.planArriveDate=planArriveDate.selectedDate;
	dgOrdersDetail.selectedItem.detailRemark=detailRemark.text;
	dgOrdersDetail.invalidateList();
}

/**
 * SuperDataGrid单击事件
 */
protected function gridDetail_doubleClickHandler(event:MouseEvent):void
{
	// TODO Auto-generated method stub
	if (!dgOrdersDetail.selectedItem)
	{
		return;
	}
	FormUtils.fillFormByItem(addPanel, dgOrdersDetail.selectedItem);
	if (dgOrdersDetail.selectedItem.factoryCode != null)
	{
		var factoryCodeItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict, 'provider', dgOrdersDetail.selectedItem.factoryCode);
		
	}
	factoryCode.text=factoryCodeItem == null ? null : factoryCodeItem.providerName;
	var ro:RemoteObject=RemoteUtil.getRemoteObject("commMaterialServiceImpl", function(rev:Object):void
	{
		currentStockAmount.text=rev.data[0].totalCurrentStockAmount;
	});
	ro.findCurrentStockByIdStorage(dgOrdersDetail.selectedItem.materialId, 0);
}

/**
 * 打印
 */
protected function printClickHandler(event:Event):void
{
	printReport("1");
	
}

/**
 * 输出
 */
protected function expClickHandler(event:Event):void
{
	printReport("0");
	
}
/**
 * 计算当前页
 * */
private function preparePrintData(faryData:ArrayCollection):void
{
	var rdBillNo:String=""
	var pageNo:int=0;
	for (var i:int=0; i < faryData.length; i++)
	{
		var item:Object=faryData.getItemAt(i);
		if (item.rdBillNo != rdBillNo)
		{
			rdBillNo=item.rdBillNo
			pageNo++;
		}
		item.factoryName=!item.factoryName ? '' : item.factoryName
		item.pageNo=pageNo;
		item.factoryName=item.factoryName.substr(0, 6);
		item.nameSpec=item.materialName + " " + (item.materialSpec == null ? "" : item.materialSpec)+" "+(item.factoryName==null?"":item.factoryName);
	}
}

/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	var _dataList:ArrayCollection=dgOrdersDetail.dataProvider as ArrayCollection;
preparePrintData(_dataList);	
var dict:Dictionary=new Dictionary();
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="采购订单处理";
	dict["制表人"]=AppInfo.currentUserInfo.userName;
	dict["业务类型"]=operationType.selectedItem.operationTypeName;
	dict["订单编号"]=billNo.text;
	dict["订单日期"]=DateField.dateToString(DateField.stringToDate(billDate.text, "YYYY-MM-DD"), "YYYY-MM-DD");
	dict["供应单位"]=salerCode.txtContent.text;
	dict["部门"]=deptCode.txtContent.text;
	dict["业务员"]=personId.txtContent.text;
	dict["付款条件"]=payCondition.text;
	dict["备注"]=remark.text;
	dict["制单人"]=maker.text;
	dict["制单日期"]=makeDate.text;
	dict["审核人"]=verifier.text;
	dict["审核日期"]=verifyDate.text;
	if (printSign == '1')
		ReportPrinter.LoadAndPrint("report/material/purchase/purchaseOrders.xml", _dataList, dict);
	if (printSign == '0')
		ReportViewer.Instance.Show("report/material/purchase/purchaseOrders.xml", _dataList, dict);
}

/**
 * 增加按钮
 */
protected function toolBar_addClickHandler(event:Event):void
{
	if (!checkUserRole('01'))
	{
		return;
	}
	//设置表可用
	menuItemsEnableValues=['1', '1'];
	//设置可以编辑
	setReadOnly(true);
	//清空数据
	clearForm();
	billNo.setFocus();
	//增加按钮
	toolBar.addToPreState()
}
/**
 * 修改按钮
 */
protected function toolBar_modifyClickHandler(event:Event):void
{
	if (!checkUserRole('02'))
	{
		return;
	}
	//设置表可用
	menuItemsEnableValues=['1', '1'];
	//设置可以编辑
	setReadOnly(true);
	operationType.setFocus();
	//修改按钮初始化
	toolBar.modifyToPreState();
}

/**
 * 删除
 */
protected function toolBar_deleteClickHandler(event:Event):void
{
	if (!checkUserRole('03'))
	{
		return;
	}
	Alert.show("确定删除？", "提示信息", Alert.YES | Alert.NO, null, deleteCallback1);
}

/**
 * 删除回调
 */
private function deleteCallback1(rev:CloseEvent):void
{
	if (rev.detail == Alert.YES)
	{
		var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			Alert.show("删除成功", "提示");
			//清理所有数据
			clearDetail();
			//文本不可编辑
			initPanel();
			//按钮状态
			initToolBar();
			clearForm();
		});
		ro.delOrder(_materialOrderMaster.autoId);
	}
}

/**
 * 保存
 */
protected function toolBar_saveClickHandler(event:Event):void
{
	if (!checkUserRole('04'))
	{
		return;
	}
	if (checkout())
	{
		var materialOrderMaster:MaterialOrderMaster=new MaterialOrderMaster();
		materialOrderMaster=fillRdsMaster();
		var arr:ArrayCollection=new  ArrayCollection();
		arr=dgOrdersDetail.dataProvider as ArrayCollection;
		var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			//设置表可用
			menuItemsEnableValues=['0', '0'];
			initToolBar();
			findRdsById(rev.data[0].autoId);
			setReadOnly(false);
			Alert.show("保存成功", "提示");
		});
		ro.saveOrder(materialOrderMaster, dgOrdersDetail.dataProvider);
		toolBar.btSave.enabled = false;
	}
}
/**
 * 保存时校验
 */
protected function checkout():Boolean
{
	var state:Boolean=true;
	;
	if (operationType.selectedItem == null)
	{
		operationType.setFocus();
		Alert.show("请选择业务类型", "提示");
		return state=false;
	}
	if (_materialOrderMaster.salerCode == null)
	{
		salerCode.txtContent.setFocus();
		Alert.show("请输入供应单位", "提示");
		return state=false;
	}
	if (_materialOrderMaster.deptCode == null)
	{
		deptCode.txtContent.setFocus();
		Alert.show("请输入部门", "提示");
		return state=false;
	}
	if (_materialOrderMaster.personId == null)
	{
		personId.txtContent.setFocus();
		Alert.show("请输入业务员", "提示");
		return state=false;
	}
	if (dgOrdersDetail.dataProvider.length <= 0)
	{
		materialCode.txtContent.setFocus();
		Alert.show("明细不能为空,请以拼音简码创建第一条明细.", "提示");
		return state=false;
	}
	var lstBloodRdsDetail:ArrayCollection=dgOrdersDetail.dataProvider as ArrayCollection;
	for (var i:int=0; i <= lstBloodRdsDetail.length - 1; i++)
	{
		if ((Number)(lstBloodRdsDetail[i].amount) <= 0)
		{
			amount.setFocus();
			Alert.show("第" + (i + 1) + "条物品数量不能<=0,请重新输入", "提示");
			dgOrdersDetail.selectedIndex=i;
			return state=false;
		}
		if ((Number)(lstBloodRdsDetail[i].tradeMoney) > 1650000)
		{
			tradePrice.setFocus();
			Alert.show("第" + (i + 1) + "条物品金额不能>=165万,请重新输入", "提示");
			dgOrdersDetail.selectedIndex=i;
			return state=false;
		}
	}
	return state;
}



/**
 * 放弃按钮
 */
protected function toolBar_cancelClickHandler(event:Event):void
{
	Alert.show("您是否放弃当前操作吗？", "提示", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
	{
		if (e.detail == Alert.NO)
		{
			return;
		}
		//设置表不可用
		menuItemsEnableValues=['0', '0'];
		//清空数据
		clearForm();
		//按钮状态
		initToolBar();
		//设置文本不可编辑
		setReadOnly(false);
	})
}


/**
 * 审核按钮
 */
protected function toolBar_verifyClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	if (!checkUserRole('06'))
	{
		return;
	}
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		Alert.show("审核成功", "提示");
		findRdsById(_materialOrderMaster.autoId);
	});
	ro.verifyOrder(_materialOrderMaster.autoId);
}

/**
 * 增行
 */
protected function toolBar_addRowClickHandler(event:Event):void
{
	FormUtils.clearForm(panel1);
	materialCode.text='';
	//光标定位到drugClass
	materialCode.txtContent.setFocus();
	dgOrdersDetail.selectedIndex=-2;
	salerCode.text="";
	detailRemark.text="";
	planArriveDate.selectedDate=new Date;
	preventDefaultForm();
}

/**
 * 删行
 */
protected function toolBar_delRowClickHandler(event:Event):void
{
	if (!dgOrdersDetail.selectedItem)
	{
		return;
	}
	 deleteCallback();
}

/**
 *  删行回调方法
 */
private function deleteCallback():void
{
		//光标所在位置
		var laryDetails:ArrayCollection=dgOrdersDetail.dataProvider as ArrayCollection;
		var i:int=laryDetails.getItemIndex(dgOrdersDetail.selectedItem);
		if (i < 0)
		{
			return
		}
		clearDetail();
		laryDetails.removeItemAt(i);
		dgOrdersDetail.dataProvider=laryDetails;
		dgOrdersDetail.invalidateList();
		dgOrdersDetail.selectedIndex=dgOrdersDetail.dataProvider.length - 1;
		dgOrdersDetail.selectedIndex=i == 0 ? 0 : (i - 1);
		EvaluateList(dgOrdersDetail.selectedItem as MaterialOrderDetail);
}
/**
 * 查询采购订单界面
 */
private function callbackPlan(e:Event):void
{
	var win:PurchasePlanFilter=PopUpManager.createPopUp(this, PurchasePlanFilter, true) as PurchasePlanFilter;
	win.data={parentWin: this};
	PopUpManager.centerPopUp(win);
}

/**
 * 查询采购申请界面
 */
private function callbackApply(e:Event):void
{
	var win:PurchaseApplyFilter=PopUpManager.createPopUp(this, PurchaseApplyFilter, true) as PurchaseApplyFilter;
	win.data={parentWin: this};
	PopUpManager.centerPopUp(win);
}

/**
 * 查询按钮
 */
protected function toolBar_queryClickHandler(event:Event):void
{
	var queryWin:PurchaseOrdersQuery=PopUpManager.createPopUp(this, PurchaseOrdersQuery, true) as PurchaseOrdersQuery;
	queryWin.data={parentWin: this};
	PopUpManager.centerPopUp(queryWin);
}

/**
 * 首页
 */
protected function firstPageClickHandler(event:Event):void
{
	//定位到数组第一个
	if (arrayAutoId.length < 1)
	{
		return;
	}
	currentPage=0;
	var strAutoId:String=arrayAutoId[currentPage] as String;
	findRdsById(strAutoId);
	toolBar.firstPageToPreState()
}

/**
 * 下一页
 */
protected function nextPageClickHandler(event:Event):void
{
	if (arrayAutoId.length < 1)
	{
		return;
	}
	currentPage++;
	if (currentPage >= arrayAutoId.length)
	{
		currentPage=arrayAutoId.length - 1;
	}

	var strAutoId:String=arrayAutoId[currentPage] as String;
	findRdsById(strAutoId);

	toolBar.nextPageToPreState(currentPage, arrayAutoId.length - 1);
}

/**
 * 上一页
 */
protected function prePageClickHandler(event:Event):void
{
	if (arrayAutoId.length < 1)
	{
		return;
	}
	currentPage--;
	if (currentPage <= 0)
	{
		currentPage=0;
	}

	var strAutoId:String=arrayAutoId[currentPage] as String;
	findRdsById(strAutoId);

	toolBar.prePageToPreState(currentPage);
}

/**
 * 末页
 */
protected function lastPageClickHandler(event:Event):void
{
	if (arrayAutoId.length < 1)
	{
		return;
	}
	currentPage=arrayAutoId.length - 1;

	var strAutoId:String=arrayAutoId[currentPage] as String;
	findRdsById(strAutoId);

	toolBar.lastPageToPreState();
}

/**
 * 翻页调用此函数
 */
public function findRdsById(autId:String):void
{
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			if (rev.data.length <= 0)
			{
				return;
			}
			_materialOrderMaster=rev.data[0];
			fillRdsText(_materialOrderMaster);
			dgOrdersDetail.dataProvider=rev.data[1];
			stateButton(rev.data[1][0].currentStatus);
		});
	ro.findOrderDetail(autId);
}



/**
 * 更具数据状态显示不同的按钮
 */
protected function stateButton(currentStatus:String):void
{
	var state:Boolean=(currentStatus != "0" ? false : true);
	toolBar.btModify.enabled=state;
	toolBar.btDelete.enabled=state;
	toolBar.btVerify.enabled=state;
	toolBar.btAdd.enabled=true;
	toolBar.btPrint.enabled=!state;
	toolBar.btExp.enabled=!state;
}

/**
 * 转换人名
 */
protected function shiftTo(name:String):String
{
	var makerItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', name);
	var maker:String=makerItem == null ? "" : makerItem.personIdName;
	return maker;
}


/**
 *
 */ /**
 * 退出按钮
 */
protected function toolBar_exitClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	if (this.parentDocument is WinModual)
	{
		PopUpManager.removePopUp(this.parentDocument as IFlexDisplayObject);
		return;
	}
	DefaultPage.gotoDefaultPage();
}



/**
 * 数量不符合时回调
 */
public function huiCallback(rev:CloseEvent):void
{
	if (rev.detail == Alert.YES)
	{
		amount.setFocus();
		return;
	}
}



/**
 * 响应右键弹出事件
 * 根据menuItemsEnableValues中的值，分别对应右键菜单项是否可用
 * */
private function menuItemEnabled(e:ContextMenuEvent):void
{
	var aryMenuItems:Array=e.target.customItems;
	for (var i:int=0; i < aryMenuItems.length; i++)
	{
		aryMenuItems[i].enabled=menuItemsEnableValues[i] == "1" ? true : false;
	}
}

private function initContextMenu(comp:UIComponent, menuItemsName:Array, functions:Array):ContextMenu
{
	var contextMenu:ContextMenu=new ContextMenu();
	contextMenu.hideBuiltInItems();
	var menuItems:Array=[];
	for (var i:int=0; i < menuItemsName.length; i++)
	{
		var menuItem:ContextMenuItem=new ContextMenuItem(menuItemsName[i]);
		menuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, functions[i]);
		menuItems.push(menuItem);
	}
	contextMenu.customItems=menuItems;
	dgOrdersDetail.contextMenu=contextMenu;
	return contextMenu;
}

/**
 * 当前角色权限认证
 */
public static function checkUserRole(role:String):Boolean
{
	//判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, role))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return false;
	}
	return true;
}