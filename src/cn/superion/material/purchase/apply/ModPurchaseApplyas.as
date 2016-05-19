/**
 *		 采购计划编制
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
import cn.superion.material.purchase.plan.view.PurchaseChaseQueryCon;
import cn.superion.material.purchase.plan.view.PurchasePlanAuto;
import cn.superion.material.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialPlanDetail;
import cn.superion.vo.material.MaterialPlanMaster;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.events.FlexEvent;
import mx.events.ListEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.TextOperationEvent;

private static const MENU_NO:String="0102";
public var DESTANATION:String="planImpl";

//主记录
public var _materialPlanMaster:MaterialPlanMaster=new MaterialPlanMaster();

//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;

/**
 * 初始化当前窗口
 * */
public function doInit():void
{
	if(parentDocument is WinModual){
		parentDocument.title="采购申请处理";
	}
	//重新注册客户端对应的服务端类
	registerClassAlias("cn.superion.material.entity.MaterialPlanMaster", MaterialPlanMaster);
	registerClassAlias("cn.superion.material.entity.MaterialPlanDetail", MaterialPlanDetail);
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
	if (BaseDict.buyOperationTypeDict != null && BaseDict.buyOperationTypeDict.length > 0)
	{
		stockType.dataProvider=BaseDict.buyOperationTypeDict;
		stockType.selectedIndex=0;
	}
	setReadOnly(false);

	personId.width=stockType.width;
	requierDate.width=materialCode.width;
	adviceBookDate.width=materialCode.width;
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
	stockType.enabled=boolean;
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
}

/**
 * 清空表单
 */
public function clearForm(masterFlag:Boolean, detailFlag:Boolean):void
{
	if (masterFlag)
	{
		//清空主记录
		clearMaster();
	}
	if (detailFlag)
	{
		//清空明细
		clearDetail();
	}
}

/**
 * 清空明细
 */
private function clearDetail():void
{
	FormUtils.clearForm(addPanel);
	requierDate.selectedDate=new Date;
	adviceBookDate.selectedDate=new Date;
}

/**
 * 清空主记录
 */
public function clearMaster():void
{
	FormUtils.clearForm(allPanel);
	stockType.selectedIndex=0;
	gridDetail.dataProvider=null;
	requierDate.selectedDate=new Date;
	adviceBookDate.selectedDate=new Date;
	billDate.selectedDate=new Date;
	_materialPlanMaster=new MaterialPlanMaster();
}

/**
 * 回车事件
 **/
private function toNextControl(event:KeyboardEvent, fctrlNext:Object):void
{
	FormUtils.toNextControl(event, fctrlNext);
}

/**
 * 数量key事件
 */
protected function amountKey(e:KeyboardEvent, fcontrolNext:*):void
{
	if (e.keyCode == Keyboard.ENTER)
	{
		if (!gridDetail.selectedItem)
		{
			return;
		}
		if ((gridDetail.selectedItem.amount) <= 0)
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
		if (!gridDetail.selectedItem)
		{
			return;
		}
		if (gridDetail.selectedItem.amount <= 0)
		{
			Alert.show("数量不能小于或等于零!", "提示", Alert.YES, null, huiCallback);
			return;
		}
		//先清空“增加面板addPanel”
		FormUtils.clearForm(panel1);
		adviceBookDate.selectedDate=new Date;
		requierDate.selectedDate=new Date;
		salerCode.text="";
		detailRemark.text="";
		materialCode.txtContent.setFocus();
	}
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
 * 物资编码KeyUp事件
 */
protected function materialCode_keyUpHandler(event:KeyboardEvent):void
{
	// TODO Auto-generated method stub
	if (event.keyCode != Keyboard.ENTER)
	{
		return;
	}
	if (materialCode.text == "")
	{
		materialCode_queryIconClickHandler(event);
	}
	else
	{
		amount.setFocus();
	}
}

/**
 * 供应商字典
 */
protected function productCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict(function(rev:Object):void
		{
			event.target.text=rev.providerName;
			if (gridDetail.selectedItem)
			{
				gridDetail.selectedItem.salerCode=rev.providerId;
				gridDetail.selectedItem.salerName=rev.providerName;
			}
			gridDetail.invalidateList();
		}, x, y);
}

/**
 * 部门字典
 */
protected function deptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(rev:Object):void
		{
			event.target.text=rev.deptName;
			_materialPlanMaster.deptCode=rev.deptCode;
		}, x, y);
}

/**
 * 人物档案字典
 */
protected function personId_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict(function(rev:Object):void
		{
			event.target.text=rev.personIdName;
			_materialPlanMaster.personId=rev.personId;
		}, x, y);
}

/**
 * 物资字典
 */
protected function materialCode_queryIconClickHandler(event:Event):void
{
	//打开物资字典
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 338;
	var lstorageCode:String='';
	lstorageCode=null;
	DictWinShower.showMaterialDictNew(lstorageCode, '', '', true, function(faryItems:Array):void
		{
			fillIntoGrid(faryItems);
		}, x, y);
}

/**
 * 自动完成表格回调
 * */
private function fillIntoGrid(fItem:Array):void
{
	amount.setFocus();
	
	var laryDetails:ArrayCollection=gridDetail.dataProvider as ArrayCollection;
	//放大镜取出的值、赋值
	for(var i:int=0;i<fItem.length;i++)
	{
		var materialPlanDetail:MaterialPlanDetail=new MaterialPlanDetail();
		materialPlanDetail=fillDetailForm(fItem[i]);
		laryDetails.addItem(materialPlanDetail);
	}
	gridDetail.dataProvider=laryDetails;
	gridDetail.selectedIndex=laryDetails.length - 1;
}

/**
 * 明细表单赋值
 */
private function fillDetailForm(faryItems:Object):MaterialPlanDetail
{
	var materialPlanDetail:MaterialPlanDetail=new MaterialPlanDetail();
	materialCode.text=faryItems.materialCode;
	//物资编码
	materialPlanDetail.materialCode=faryItems.materialCode;
	//物资Id
	materialPlanDetail.materialId=faryItems.materialId;
	//物资类型
	materialPlanDetail.materialClass=faryItems.materialClass;
	//物资名称
	materialPlanDetail.materialName=faryItems.materialName;
	//规格型号
	materialPlanDetail.materialSpec=faryItems.materialSpec;
	//单位
	materialPlanDetail.materialUnits=faryItems.materialUnits;
	//进价
	materialPlanDetail.tradePrice=faryItems.tradePrice;
	materialPlanDetail.tradeMoney=faryItems.tradePrice;
	//售价金额
	materialPlanDetail.retailMoney=faryItems.retailPrice;
	//售价
	materialPlanDetail.retailPrice=faryItems.retailPrice;
	//现存量
	materialPlanDetail.currentStockAmount=faryItems.safeStockAmount;
	//全院现存量
	materialPlanDetail.totalCurrentStockAmount=faryItems.safeStockAmount;
	//初始数量
	materialPlanDetail.amount=1;
	materialPlanDetail.chargeSign = faryItems.chargeSign;//收费标示；
	materialPlanDetail.classOnAccount = faryItems.accountClass;//会计分类；
	//需求日期
	materialPlanDetail.requireDate=new Date;
	//已生成订单数	ORDER_AMOUNT
	materialPlanDetail.orderAmount=0;
	//订货日期
	materialPlanDetail.adviceBookDate=new Date;
	materialName.text=materialPlanDetail.materialName;
	materialSpec.text=materialPlanDetail.materialSpec;
	materialUnits.text=materialPlanDetail.materialUnits;
	var timer:Timer=new Timer(100, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
		{
			amount.setFocus();
		})
	timer.start();
	return materialPlanDetail;
}

/**
 * 给主记录赋值
 */
private function fillRdsMaster():void
{
	_materialPlanMaster.operationType=stockType.selectedItem == false ? null : stockType.selectedItem.operationType;
	_materialPlanMaster.billNo=billNo.text == "" ? null : billNo.text;
	_materialPlanMaster.billDate=billDate.selectedDate;
	_materialPlanMaster.remark=remark.text == "" ? null : remark.text;
	_materialPlanMaster.dataSource="2";
	_materialPlanMaster.totalCosts=0;

	var lstBloodRdsDetail:ArrayCollection=gridDetail.dataProvider as ArrayCollection;
	for (var i:int=0; i <= lstBloodRdsDetail.length - 1; i++)
	{
		_materialPlanMaster.totalCosts=_materialPlanMaster.totalCosts + Number(lstBloodRdsDetail[i].tradeMoney);
	}
}

/**
 * 所有Change事件
 */
protected function evaluate_changeHandler(event:Event):void
{
	if (!gridDetail.selectedItem)
	{
		return;
	}
	gridDetail.selectedItem.detailRemark=detailRemark.text;
	gridDetail.selectedItem.requireDate=requierDate.selectedDate as Date;
	gridDetail.selectedItem.adviceBookDate=adviceBookDate.selectedDate as Date;
	gridDetail.selectedItem.amount=Number(amount.text);
	gridDetail.selectedItem.tradePrice=Number(tradePrice.text);
	gridDetail.selectedItem.tradeMoney=((Number)(amount.text)) * ((Number)(tradePrice.text)) as Number;
	gridDetail.selectedItem.retailMoney=((Number)(amount.text)) * ((Number)(gridDetail.selectedItem.retailPrice)) as Number;
	gridDetail.invalidateList();
}

protected function gridDetail_clickHandler(event:MouseEvent):void
{
	// TODO Auto-generated method stub
	if (!gridDetail.selectedItem)
	{
		return;
	}
	FormUtils.fillFormByItem(addPanel, gridDetail.selectedItem);
	var salerCodeObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict, 'provider', salerCode.text);
	salerCode.text=salerCodeObj == null ? null : salerCodeObj.providerName;
}

/**
 * 填充当前表单
 */
protected function gdItems_itemClickHandler(event:ListEvent):void
{
	// TODO Auto-generated method stub
	FormUtils.fillFormByItem(addPanel, gridDetail.selectedItem);
}

//打印
protected function printClickHandler(event:Event):void
{
	printReport("1");

}

//输出
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
		item.nameSpec=item.materialName + " " + (item.materialSpec == null ? "" : item.materialSpec) + " " + (item.salerName == null ? "" : item.salerName);
	}
}

/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	var _dataList:ArrayCollection=gridDetail.dataProvider as ArrayCollection;
	var dict:Dictionary=new Dictionary();
	preparePrintData(_dataList);
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="采购申请处理";
	dict["制表人"]=AppInfo.currentUserInfo.userName;
	dict["单据编号"]=billNo.text;
	dict["单据日期"]=DateField.dateToString(DateField.stringToDate(billDate.text, "YYYY-MM-DD"), "YYYY-MM-DD");
	dict["制单人"]=maker.text;
	dict["审核人"]=verifier.text;
	if (printSign == '1')
		ReportPrinter.LoadAndPrint("report/material/purchase/purchaseApply.xml", _dataList, dict);
	if (printSign == '0')
		ReportViewer.Instance.Show("report/material/purchase/purchaseApply.xml", _dataList, dict);
}

/**
 * 增加
 */
protected function addClickHandler(event:Event):void
{
	//新增权限
	if (!checkUserRole('01'))
	{
		return;
	}
	//增加按钮
	toolBar.addToPreState()
	//设置可写
	setReadOnly(true);
	//清空当前表单
	clearForm(true, true);
	billNo.setFocus();

}

/**
 * 修改
 */
protected function modifyClickHandler(event:Event):void
{
	if (!checkUserRole('02'))
	{
		return;
	}
	stockType.setFocus();
	toolBar.modifyToPreState();
	setReadOnly(true);
}


/**
 * 删除
 */
protected function deleteClickHandler(event:Event):void
{
	//删除权限
	if (!checkUserRole('03'))
	{
		return;
	}
	Alert.show("您确定要删除当前记录？", "提示信息", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
		{
			if (e.detail == Alert.YES)
			{
				var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
					{
						Alert.show("删除成功", "提示");
						//清空当前表单
						clearForm(true, true);
						//文本不可编辑
						initPanel();
						//按钮状态
						initToolBar();
					});
				ro.deleteMaterialPlan(_materialPlanMaster.autoId);
			}
		});
}


/**
 * 保存
 */
protected function saveClickHandler(event:Event):void
{
	//保存权限
	if (!checkUserRole('04'))
	{
		return;
	}
	if (!validateMaster())
	{
		return;
	}
	toolBar.btSave.enabled=false;
	fillRdsMaster();
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			initToolBar();
			setReadOnly(false);
			findRdsById(rev.data[0].autoId);
			Alert.show("保存成功", "提示");
		});
	ro.saveMaterialPlan(_materialPlanMaster, gridDetail.dataProvider);
}


/**
 * 更具数据状态显示不同的按钮
 */
protected function stateButton(currentStatus:String):void
{
	var state:Boolean=(currentStatus == "1" ? false : true);
	toolBar.btAdd.enabled=true;
	toolBar.btModify.enabled=state;
	toolBar.btDelete.enabled=state;
	toolBar.btVerify.enabled=state;
	toolBar.btPrint.enabled=!state;
	toolBar.btExp.enabled=!state;
}

/**
 * 保存前验证主记录
 */
private function validateMaster():Boolean
{
	var state:Boolean=true;
	;
	if (stockType.selectedItem == null)
	{
		stockType.setFocus();
		Alert.show("请选择业务类型", "提示");
		return state=false;
	}
	if (_materialPlanMaster.deptCode == null)
	{
		deptCode.txtContent.setFocus();
		Alert.show("请输入部门", "提示");
		return state=false;
	}
	if (_materialPlanMaster.personId == null)
	{
		personId.txtContent.setFocus();
		Alert.show("请输入业务员", "提示");
		return state=false;
	}
	if (gridDetail.dataProvider.length <= 0)
	{
		materialCode.txtContent.setFocus();
		Alert.show("明细不能为空,请以拼音简码创建第一条明细.", "提示");
		return state=false;
	}
	var lstBloodRdsDetail:ArrayCollection=gridDetail.dataProvider as ArrayCollection;
	for (var i:int=0; i <= lstBloodRdsDetail.length - 1; i++)
	{
		if ((Number)(lstBloodRdsDetail[i].amount) <= 0)
		{
			amount.setFocus();
			Alert.show("第" + (i + 1) + "条物品数量不能<=0,请重新输入", "提示");
			gridDetail.selectedIndex=i;
			return state=false;
		}
		if ((Number)(lstBloodRdsDetail[i].tradeMoney) > 1650000)
		{
			tradePrice.setFocus();
			Alert.show("第" + (i + 1) + "条物品金额不能>=165万,请重新输入", "提示");
			gridDetail.selectedIndex=i;
			return state=false;
		}
	}
	return state;
}

/**
 * 放弃
 */
protected function cancelClickHandler(event:Event):void
{
	Alert.show("您是否放弃当前操作吗？", "提示", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
		{
			if (e.detail == Alert.NO)
			{
				return;
			}
			//清空当前表单
			clearForm(true, true);
			//按钮状态
			initToolBar();
			//设置文本不可编辑
			setReadOnly(false);
		})
}

/**
 * 审核
 */
protected function verifyClickHandler(event:Event):void
{
	//审核权限
	if (!checkUserRole('06'))
	{
		return;
	}
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			Alert.show("审核成功", "提示");
			findRdsById(_materialPlanMaster.autoId);
		});
	ro.verifyMaterialPlan(_materialPlanMaster.autoId);
}

/**
 * 增行
 */
protected function addRowClickHandler(event:Event):void
{
	materialCode_queryIconClickHandler(event)
}

/**
 * 删行
 */
protected function delRowClickHandler(event:Event):void
{
	//光标所在位置
	var laryDetails:ArrayCollection=gridDetail.dataProvider as ArrayCollection;
	var i:int=laryDetails.getItemIndex(gridDetail.selectedItem);
	if (i < 0)
	{
		return
	}
	clearDetail();
	laryDetails.removeItemAt(i);
	gridDetail.dataProvider=laryDetails;
	gridDetail.invalidateList();
	gridDetail.selectedIndex=gridDetail.dataProvider.length - 1;
	gridDetail.selectedIndex=i == 0 ? 0 : (i - 1);
	FormUtils.fillFormByItem(addPanel, gridDetail.selectedItem);
}

/**
 * 查询
 */
protected function queryClickHandler(event:Event):void
{
	var queryWin:PurchaseApplyQueryCon=PopUpManager.createPopUp(this, PurchaseApplyQueryCon, true) as PurchaseApplyQueryCon;
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
 * */
public function findRdsById(fstrAutoId:String):void
{
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			if (rev.data.length <= 0)
			{
				return;
			}
			_materialPlanMaster=rev.data[0];
			masterEvaluate(_materialPlanMaster);
			gridDetail.dataProvider=rev.data[1];
			stateButton(rev.data[1][0].currentStatus);
		});
	ro.findMaterialPlanDetailById(fstrAutoId);
}

/**
 * 给主记录赋值
 */
protected function masterEvaluate(mpm:MaterialPlanMaster):void
{
	FormUtils.fillFormByItem(this, mpm);
	FormUtils.selectComboItem(stockType, "operationType", mpm.operationType);
	var bm:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', mpm.deptCode);
	deptCode.txtContent.text=bm == null ? null : bm.deptName;
	var yw:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', mpm.personId);
	personId.txtContent.text=yw == null ? null : yw.personIdName;
	maker.text=shiftTo(mpm.maker);
	verifier.text=shiftTo(mpm.verifier);
}

/**
 * 批号
 */
private function batchLBF(item:Object, column:DataGridColumn):String
{
	if (item.batch == '0')
	{
		item.batchName='';
	}
	else
	{
		item.batchName=item.batch;
	}
	return item.batchName;
}

/**
 * 退出
 */
protected function exitClickHandler(event:Event):void
{
	if (this.parentDocument is WinModual)
	{
		PopUpManager.removePopUp(this.parentDocument as IFlexDisplayObject);
		return;
	}
	DefaultPage.gotoDefaultPage();
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

/**
 * 转换人名
 */
protected function shiftTo(name:String):String
{
	var makerItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', name);
	var maker:String=makerItem == null ? "" : makerItem.personIdName;
	return maker;
}