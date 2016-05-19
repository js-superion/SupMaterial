/**
 *		 采购发票登记
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
import cn.superion.material.purchase.apply.view.PurchaseApplyQueryCon;
import cn.superion.material.purchase.invoice.view.PurchaseInvoiceAdd;
import cn.superion.material.purchase.invoice.view.PurchaseInvoiceQueryCon;
import cn.superion.material.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialInvoiceDetail;
import cn.superion.vo.material.MaterialInvoiceMaster;

import flash.events.ContextMenuEvent;
import flash.ui.ContextMenu;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.core.UIComponent;
import mx.events.CloseEvent;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.TextOperationEvent;
private var winY:int=0;
private static const MENU_NO:String="0104";
public var DESTANATION:String="invoiceImpl";
//业务类型
public var typeArc:ArrayCollection=BaseDict.buyOperationTypeDict;
//主记录
public var _materialInvoiceMaster:MaterialInvoiceMaster=new MaterialInvoiceMaster();
//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;
public var menuItemsName:Array=null;
public var functions:Array=null;
public var menuItemsEnableValues:Object=['0', '0']; //1表可用，0不可用

/**
 * 初始化方法
 */
public function doInit():void
{
	//重新注册客户端对应的服务端类
	registerClassAlias("cn.superion.material.entity.MaterialInvoiceMaster", MaterialInvoiceMaster);
	registerClassAlias("cn.superion.material.entity.MaterialInvoiceDetail", MaterialInvoiceDetail);
	//放大镜不可手动输入
	preventDefaultForm();
	//字典
	ddlStorageName_creationCompleteHandler();
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
		parentDocument.title="采购发票登记";
	}
	menuItemsName=['采购入库单'];
	functions=[callbackPlan];
	gdPurchaseInvoiceList.contextMenu=initContextMenu(gdPurchaseInvoiceList, menuItemsName, functions);
	gdPurchaseInvoiceList.contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, menuItemEnabled);
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, toolBar.btSave, toolBar.btVerify, toolBar.btDelRow, toolBar.btQuery, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.btExit, toolBar.imageList1, toolBar.imageList2, toolBar.imageList3, toolBar.imageList5, toolBar.imageList6];
	var laryEnables:Array=[toolBar.btAdd, toolBar.btQuery, toolBar.btExit];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	var i:String=boolean==true?"1":"0"
	//设置表头可以编辑
	FormUtils.setFormItemEditable(allPanel, boolean);
	operationType.enabled=boolean;
	invoiceType.enabled=boolean;
	menuItemsEnableValues=[i, i];//1表可用，0不可用
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
}

/**
 * 清空表单
 */
public function clearForm():void
{
	gdPurchaseInvoiceList.dataProvider=null;
	FormUtils.clearForm(allPanel);
	operationType.selectedIndex=0;
	invoiceType.selectedIndex=0;
	billDate.selectedDate=new Date;
	invoiceDate.selectedDate=new Date;
	_materialInvoiceMaster=new MaterialInvoiceMaster();
}

/**
 * 回车事件
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
		if (fcontrolNext.className == "DropDownList")
		{
			fcontrolNext.openDropDown();
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
		if (!gdPurchaseInvoiceList.selectedItem)
		{
			return;
		}
		if ((gdPurchaseInvoiceList.selectedItem.amount) <= 0)
		{
			return;
		}
		fcontrolNext.setFocus();
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
	gdPurchaseInvoiceList.contextMenu=contextMenu;
	return contextMenu;
}

/**
 * 初始化赋值
 */
private function fillmasterForm():MaterialInvoiceMaster
{
	_materialInvoiceMaster.operationType=operationType.selectedItem == false ? null : operationType.selectedItem.operationType;
	_materialInvoiceMaster.billNo=billNo.text == "" ? null : billNo.text;
	_materialInvoiceMaster.billDate=billDate.selectedDate;
	_materialInvoiceMaster.invoiceType=invoiceType.selectedItem == false ? null : invoiceType.selectedItem.invoiceType;
	_materialInvoiceMaster.remark=remark.text == "" ? null : remark.text;
	_materialInvoiceMaster.invoiceDate=invoiceDate.selectedDate;
	_materialInvoiceMaster.payCondition=payCondition.text;
	_materialInvoiceMaster.totalCosts=0;
	_materialInvoiceMaster.invoiceNo=invoiceNo.text;
	var lstBloodRdsDetail:ArrayCollection=gdPurchaseInvoiceList.dataProvider as ArrayCollection;
	for (var i:int=0; i <= lstBloodRdsDetail.length - 1; i++)
	{
		_materialInvoiceMaster.totalCosts=_materialInvoiceMaster.totalCosts + Number(lstBloodRdsDetail[i].tradeMoney);
	}
	return _materialInvoiceMaster;
}

/**
 * 给主记录text赋值
 */
protected function fillmasterText(mpm:MaterialInvoiceMaster):void
{
	FormUtils.fillFormByItem(this, mpm);

	var salerCodeObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict, 'provider', mpm.salerCode);
	salerCode.text=mpm.salerName;

	FormUtils.selectComboItem(operationType, "operationType", mpm.operationType);
	FormUtils.selectComboItem(invoiceType, "invoiceType", mpm.invoiceType);
	var bm:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', mpm.deptCode);
	deptCode.txtContent.text=bm == null ? null : bm.deptName;
	var yw:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', mpm.personId);
	personId.txtContent.text=yw == null ? null : yw.personIdName;
	maker.text=shiftTo(mpm.maker);
	verifier.text=shiftTo(mpm.verifier);
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
		item.nameSpec=item.materialName + " " + (item.materialSpec == null ? "" : item.materialSpec) + " " + (item.factoryName == null ? "" : item.factoryName);
	}
}

/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	var _dataList:ArrayCollection=gdPurchaseInvoiceList.dataProvider as ArrayCollection;
	preparePrintData(_dataList);
	var dict:Dictionary=new Dictionary();
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="采购发票登记";
	dict["制表人"]=AppInfo.currentUserInfo.userName;
	dict["业务类型"]=operationType.selectedItem.operationTypeName;
	dict["单据编号"]=billNo.text;
	dict["单据日期"]=DateField.dateToString(DateField.stringToDate(billDate.text, "YYYY-MM-DD"), "YYYY-MM-DD");
	dict["供应单位"]=salerCode.txtContent.text;
	dict["发票类型"]=invoiceType.selectedItem.invoiceTypeName;
	dict["发票号"]=invoiceNo.text;
	dict["发票日期"]=DateField.dateToString(DateField.stringToDate(invoiceDate.text, "YYYY-MM-DD"), "YYYY-MM-DD");
	dict["部门"]=deptCode.txtContent.text;
	dict["业务员"]=personId.txtContent.text;
	dict["付款条件"]=payCondition.text;
	dict["备注"]=remark.text;
	dict["制单人"]=maker.text;
	dict["审核人"]=verifier.text;
	dict["记账人"]=_materialInvoiceMaster.accounter == null ? "" : _materialInvoiceMaster.accounter;
	dict["审核日期"]=verifyDate.text;
	if (printSign == '1')
		ReportPrinter.LoadAndPrint("report/material/purchase/purchaseInvoice.xml", _dataList, dict);
	if (printSign == '0')
		ReportViewer.Instance.Show("report/material/purchase/purchaseInvoice.xml", _dataList, dict);
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
	setReadOnly(true);
	clearForm();
	//增加按钮
	toolBar.addToPreState()
	billNo.setFocus();
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
	//设置可以编辑
	setReadOnly(true);
	//修改按钮初始化
	toolBar.modifyToPreState();
	menuItemsEnableValues=['1', '1']; //1表可用，0不可用
	billNo.setFocus();
}


/**
 * 删除按钮
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
				//清空数据
				clearForm();
				//按钮状态
				initToolBar();
				//设置文本不可编辑
				setReadOnly(false);
				menuItemsEnableValues=['0', '0'];
			});
		ro.delMaterialInvoice(_materialInvoiceMaster.autoId);
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
	var lstBloodRdsDetail:ArrayCollection=gdPurchaseInvoiceList.dataProvider as ArrayCollection;
	if (validateMaster())
	{
		var materialInvoiceMaster:MaterialInvoiceMaster=new MaterialInvoiceMaster();
		materialInvoiceMaster=fillmasterForm();
		toolBar.btSave.enabled = false;
		var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
			{
				initToolBar();
				findRdsById(rev.data[0].autoId);
				setReadOnly(false);
				Alert.show("保存成功", "提示");
			});
		ro.saveMaterialInvoice(materialInvoiceMaster, gdPurchaseInvoiceList.dataProvider);
	}
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
			//清空数据
			clearForm();
			//按钮状态
			initToolBar();
			//设置文本不可编辑
			setReadOnly(false);
			menuItemsEnableValues=['0', '0'];
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
			findRdsById(_materialInvoiceMaster.autoId);
		});
	ro.verifyMaterialInvoice(_materialInvoiceMaster.autoId);
}


/**
 * 删行按钮
 */
protected function toolBar_delRowClickHandler(event:Event):void
{
	if (!gdPurchaseInvoiceList.selectedItem)
	{
		return;
	}
	var laryDetails:ArrayCollection=gdPurchaseInvoiceList.dataProvider as ArrayCollection;
	var i:int=laryDetails.getItemIndex(gdPurchaseInvoiceList.selectedItem);
	if (i < 0)
	{
		return
	}
	laryDetails.removeItemAt(i);
	gdPurchaseInvoiceList.dataProvider=laryDetails;
	gdPurchaseInvoiceList.invalidateList();
	gdPurchaseInvoiceList.selectedIndex=gdPurchaseInvoiceList.dataProvider.length - 1;
	gdPurchaseInvoiceList.selectedIndex=i == 0 ? 0 : (i - 1);
}

/**
 *  删行回调方法
 */
private function deleteCallback(rev:CloseEvent):void
{
	if (rev.detail == Alert.YES)
	{
		//光标所在位置
		
	}
}

/**
 * 查询采购订单界面
 */
private function callbackPlan(e:Event):void
{
	var win:PurchaseInvoiceAdd=PopUpManager.createPopUp(this, PurchaseInvoiceAdd, true) as PurchaseInvoiceAdd;
	win.data={parentWin: this};
	PopUpManager.centerPopUp(win);
}

/**
 * 查询按钮
 */
protected function toolBar_queryClickHandler(event:Event):void
{
	//清空表头输入项
	var winQuery:PurchaseInvoiceQueryCon=PurchaseInvoiceQueryCon(PopUpManager.createPopUp(this, PurchaseInvoiceQueryCon, true));
	winQuery.data={parentWin: this};
	PopUpManager.centerPopUp(winQuery);
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
			clearForm();
			_materialInvoiceMaster=rev.data[0];
			fillmasterText(_materialInvoiceMaster)
			gdPurchaseInvoiceList.dataProvider=rev.data[1];
			stateButton(rev.data[0].currentStatus);
		});
	ro.findMaterialInvoiceDetail(autId);
}



/**
 * 更具数据状态显示不同的按钮
 */
protected function stateButton(currentStatus:String):void
{
//	if(currentStatus==null){currentStatus="0"}
	var state:Boolean=(currentStatus != "0" ? false : true);
	toolBar.btModify.enabled=state;
	toolBar.btAdd.enabled=true;
	toolBar.btDelete.enabled=state;
	toolBar.btVerify.enabled=state;
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
 * 供应商字典
 */
protected function productCode_queryIconClickHandler(event:Event):void
{
	// TODO Auto-generated method stub

	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict(function(rev:Object):void
		{
			event.target.text=rev.providerName;
			if (gdPurchaseInvoiceList.selectedItem)
			{
				event.target.text=rev.providerName;
				_materialInvoiceMaster.salerCode=rev.providerId;
				_materialInvoiceMaster.salerName=rev.providerName;
			}
			gdPurchaseInvoiceList.invalidateList();
		}, winY, y);
}

/**
 * 部门字典
 */
protected function deptCode_queryIconClickHandler(event:Event):void
{
	// TODO Auto-generated method stub=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(rev:Object):void
		{
			event.target.text=rev.deptName;
			_materialInvoiceMaster.deptCode=rev.deptCode;
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
			_materialInvoiceMaster.personId=rev.personId;
		}, winY, y);
}

/**
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
 * 业务类型、发票类型字典
 */
protected function ddlStorageName_creationCompleteHandler():void
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
	invoiceType.dataProvider=BaseDict.invoiceTypeDict;
	invoiceType.selectedIndex=0;
}

/**
 * Code转Name;
 */
private function labelFun(item:Object, salerCode:DataGridColumn):*
{
	if (salerCode.headerText == "建议供应商")
	{
		var factoryCodeItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict, 'provider', item.salerCode);
		if (!factoryCodeItem)
		{
			return '';
		}
		else
		{
			return factoryCodeItem.providerName;
		}
	}
}

/**
 * 保存时校验
 */
protected function validateMaster():Boolean
{
	var state:Boolean=true;
	;
	if (operationType.selectedItem == null)
	{
		operationType.setFocus();
		Alert.show("请选择业务类型", "提示");
		return state=false;
	}
	if (_materialInvoiceMaster.deptCode == null)
	{
		deptCode.txtContent.setFocus();
		Alert.show("请输入部门", "提示");
		return state=false;
	}
	if (_materialInvoiceMaster.personId == null)
	{
		personId.txtContent.setFocus();
		Alert.show("请输入业务员", "提示");
		return state=false;
	}
	if (gdPurchaseInvoiceList.dataProvider.length <= 0)
	{
		Alert.show("明细不能为空.", "提示");
		return state=false;
	}
	var lstBloodRdsDetail:ArrayCollection=gdPurchaseInvoiceList.dataProvider as ArrayCollection;
	return state;
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