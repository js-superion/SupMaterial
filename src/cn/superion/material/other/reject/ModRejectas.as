/**
 *		 物资报损处理模块
 *		 作者：吴小娟   2010.12.17
 *		 修改：吴小娟   2011.06.14
 **/


import cn.superion.base.components.controls.TextInputIcon;
import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.ObjectUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.other.reject.view.WinRejectQuery;
import cn.superion.material.util.DefaultPage;
import cn.superion.material.util.MaterialCurrentStockShower;
import cn.superion.material.util.MaterialDictShower;
import cn.superion.material.util.ReportParameter;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialRejectDetail;
import cn.superion.vo.material.MaterialRejectMaster;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.controls.Text;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import org.alivepdf.layout.Format;

import spark.events.TextOperationEvent;


public static const MENU_NO:String="0401";
//服务类
public static const DESTINATION:String="rejectImpl";

private var _winY:int=0;

private var _materialrejectMaster:MaterialRejectMaster=new MaterialRejectMaster();
private var _materialrejectDetail:MaterialRejectDetail=new MaterialRejectDetail();

//是否批号管理
private var _bathSign:Boolean;

//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;

/**
 * 初始化当前窗口
 * */
private function doInit():void
{
//	parentDocument.title="物资报损处理";
	if(parentDocument is WinModual){
		parentDocument.title="物资报损处理";
	}
	_winY=this.parentApplication.screen.height - 345;
	rdType.width=storageCode.width;
	rejectReason.width=billNo.width + billDateText.width + billDate.width + 12;
	initPanel();
}


/**
 * 面板初始化
 */
private function initPanel():void
{
	initToolBar();
	//增加项隐藏
	bord.height=70;
	hiddenVGroup.includeInLayout=false;
	hiddenVGroup.visible=false;
	//授权仓库赋值
	if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
	{
		storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
		storageCode.selectedIndex=0;
	}
	//设置只读
	setReadOnly(true);
	//阻止表单输入
	preventDefaultForm();
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1, toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, toolBar.btSave, toolBar.btVerify, toolBar.imageList2, toolBar.btAddRow, toolBar.btDelRow, toolBar.imageList3, toolBar.btQuery, toolBar.imageList5, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array=[toolBar.btExit, toolBar.btQuery, toolBar.btAdd]
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	boolean=!boolean;
	storageCode.enabled=boolean;
	billNo.enabled=boolean;
	billDate.enabled=boolean;
	outDeptCode.enabled=boolean;
	personId.enabled=boolean;
	rdType.enabled=boolean;
	rejectReason.enabled=boolean;
	remark.enabled=boolean;
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	outDeptCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	
	personId.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	
	rdType.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	
	materialCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
		
	batch.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
}

/**
 * 清空表单
 */
private function clearForm(masterFlag:Boolean, detailFlag:Boolean):void
{
	if (masterFlag)
	{
		billNo.text="";
		billDate.selectedDate=new Date();
		outDeptCode.txtContent.text="";
		personId.txtContent.text="";
		rdType.txtContent.text="";
		rejectReason.text="";
		remark.text="";
		
		currentStockAmount.text="";
		maker.text='';
		makeDate.text='';
		verifier.text='';
		verifyDate.text='';
		
		_materialrejectMaster=new MaterialRejectMaster();
	}
	if (detailFlag)
	{
		materialCode.txtContent.text="";
		materialName.text="";
		materialSpec.text="";
		materialUnits.text="";
		
		amount.text="";
		
		batch.text="0";
		
		gdRejectDetail.dataProvider=new ArrayCollection();
	}
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
	FormUtils.toNextControl(event, fctrlNext);
}

/**
 * 部门档案
 */
protected function outDeptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(rev:Object):void
	{
		outDeptCode.txtContent.text=rev.deptName;
		
		_materialrejectMaster.outDeptCode=rev.deptCode;
	}, x, y);
}

/**
 * 人员档案
 */
protected function personId_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict(function(rev:Object):void
	{
		personId.txtContent.text=rev.name;
		
		_materialrejectMaster.personId=rev.personId;
	}, x, y);
}

/**
 * 调用出库类型字典
 */
protected function rdType_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	MaterialDictShower.showDeliverTypeDict(function(rev:Object):void
	{
		rdType.txtContent.text=rev.rdName;
		
		_materialrejectMaster.rdType=rev.rdCode;
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
	lstorageCode=(storageCode.selectedItem || {}).storageCode;
	
	DictWinShower.showMaterialDictNew(lstorageCode, '', '', true, function(faryItems:Array):void
	{
		fillIntoGrid(faryItems);
	}, x, y);
}


/**
 * 自动完成表格回调
 * */
private function fillIntoGrid(faryItems:Array):void
{
	var laryDetails:ArrayCollection=gdRejectDetail.dataProvider as ArrayCollection;
	
	for(var i:int;i<faryItems.length;i++)
	{
		var lnewlDetail:MaterialRejectDetail=new MaterialRejectDetail();
		
		lnewlDetail.materialId=faryItems[i].materialId;
		lnewlDetail.materialClass=faryItems[i].materialClass;
		lnewlDetail.barCode=faryItems[i].barCode;
		lnewlDetail.materialCode=faryItems[i].materialCode;
		lnewlDetail.materialName=faryItems[i].materialName;
		lnewlDetail.materialSpec=faryItems[i].materialSpec;
		lnewlDetail.materialUnits=faryItems[i].materialUnits;
		lnewlDetail.wholeSalePrice=faryItems[i].wholeSalePrice;
		lnewlDetail.amount=0;
		
		lnewlDetail.tradePrice=faryItems[i].tradePrice;
		lnewlDetail.tradeMoney=faryItems[i].tradePrice;
		
		lnewlDetail.retailPrice=faryItems[i].retailPrice;
		lnewlDetail.retailMoney=faryItems[i].retailPrice;
		//		lnewlDetail.batch='0'
		lnewlDetail.factoryCode=faryItems[i].factoryCode;
		
		//是否批号管理
		_bathSign=faryItems[i].bathSign;
		
		laryDetails.addItem(lnewlDetail);
	}
	gdRejectDetail.dataProvider=laryDetails;
	gdRejectDetail.selectedItem=lnewlDetail;
	
	fillDetailForm(lnewlDetail);
	storageCode.enabled=false;
	var timer:Timer=new Timer(100, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
	{
		gdRejectDetail.scrollToIndex(gdRejectDetail.selectedIndex);
		amount.text="";
		amount.setFocus();
	})
	timer.start();
}

/**
 * 批号字典
 */
protected function batch_queryIconClickHandler(event:Event):void
{
	var lselItem:MaterialRejectDetail=gdRejectDetail.selectedItem as MaterialRejectDetail;
	if (lselItem == null)
	{
		return;
	}
	
	var lstorageCode:String='';
	lstorageCode=(storageCode.selectedItem || {}).storageCode;
	//打开批号字典
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 338;
	
	MaterialCurrentStockShower.showCurrentStock(lstorageCode, lselItem.materialId, '', function(faryItems:Array):void
	{
		fillIntoGridByBatch(faryItems);
	}, x, y);
}
protected function detailRemark_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub
	if(gdRejectDetail.selectedItem)
	{
		gdRejectDetail.selectedItem.detailRemark=detailRemark.text;
	}
}
protected function detailRemark_keyDownHandler(event:KeyboardEvent):void
{
	// TODO Auto-generated method stub
	if (event.keyCode != Keyboard.ENTER)
	{
		return;
	}
	FormUtils.clearForm(zj);
	materialCode.txtContent.setFocus();
}
/**
 * 批号字典自动完成表格回调
 * */
private function fillIntoGridByBatch(faryItems:Array):void
{
	var lRejectDetail:MaterialRejectDetail=gdRejectDetail.selectedItem as MaterialRejectDetail;
	if (!lRejectDetail)
	{
		return;
	}
	var i:int=0;
	var laryDetails:ArrayCollection=gdRejectDetail.dataProvider as ArrayCollection;
	
	for each (var item:Object in faryItems)
	{
		var lnewlDetail:MaterialRejectDetail=new MaterialRejectDetail();
		if (i == 0)
		{
			batch.text=item.batch;
			
			lRejectDetail.tradePrice=item.tradePrice;
			lRejectDetail.factoryCode=item.factoryCode;
			lRejectDetail.madeDate=item.madeDate;
			lRejectDetail.batch=item.batch;
			lRejectDetail.availDate=item.availDate;
			
			lnewlDetail=lRejectDetail;
			i++;
			continue;
		}
		
		lnewlDetail.materialId=lRejectDetail.materialId;
		lnewlDetail.materialClass=lRejectDetail.materialClass;
		lnewlDetail.barCode=lRejectDetail.barCode;
		lnewlDetail.materialCode=lRejectDetail.materialCode;
		lnewlDetail.materialName=lRejectDetail.materialName;
		lnewlDetail.materialSpec=lRejectDetail.materialSpec;
		lnewlDetail.materialUnits=lRejectDetail.materialUnits;
		
		lnewlDetail.amount=0;
		
		lnewlDetail.tradePrice=item.tradePrice;
		lnewlDetail.tradeMoney=0;
		
		lnewlDetail.retailPrice=lRejectDetail.retailPrice;
		lnewlDetail.retailMoney=0;
		
		lnewlDetail.factoryCode=item.factoryCode;
		
		lnewlDetail.currentStockAmount=lRejectDetail.amount;
		
		lnewlDetail.madeDate=item.madeDate;
		lnewlDetail.batch=item.batch;
		lnewlDetail.availDate=item.availDate;
			
		laryDetails.addItem(lnewlDetail);
	}
	gdRejectDetail.dataProvider=laryDetails;
	gdRejectDetail.selectedItem=lnewlDetail;
	
	fillDetailForm(lnewlDetail);
	
	var timer:Timer=new Timer(100, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
	{
		gdRejectDetail.scrollToIndex(gdRejectDetail.selectedIndex);
		materialCode.txtContent.text="";
		materialCode.txtContent.setFocus();
	})
	timer.start();
}

/**
 * 明细表单赋值
 */
private function fillDetailForm(fselDetailItem:MaterialRejectDetail):void
{
	if (!fselDetailItem)
	{
		return;
	}
	materialCode.txtContent.text=fselDetailItem.materialCode;
	materialName.text=fselDetailItem.materialName;
	materialSpec.text=fselDetailItem.materialSpec;
	materialUnits.text=fselDetailItem.materialUnits;
	
	amount.text=fselDetailItem.amount + '';
	batch.text=fselDetailItem.batch;
	detailRemark.text=fselDetailItem.detailRemark;
	var ro:RemoteObject=RemoteUtil.getRemoteObject("commMaterialServiceImpl", function(rev:Object):void
	{
		currentStockAmount.text=rev.data[0].totalCurrentStockAmount;
	});
	ro.findCurrentStockByIdStorage(gdRejectDetail.selectedItem.materialId, 0);
}

/**
 * 数量进行改变事件
 */
private function amount_ChangeHandler(event:Event):void
{
	var lRejectDetail:MaterialRejectDetail=gdRejectDetail.selectedItem as MaterialRejectDetail;
	if (!lRejectDetail)
	{
		return;
	}
	
	lRejectDetail.amount=parseFloat(amount.text);
	lRejectDetail.amount=isNaN(lRejectDetail.amount) ? 0 : lRejectDetail.amount;

	lRejectDetail.tradeMoney=lRejectDetail.amount * lRejectDetail.tradePrice;
	
	lRejectDetail.retailMoney=lRejectDetail.amount * lRejectDetail.retailPrice;
	lRejectDetail.wholeSaleMoney=lRejectDetail.amount*lRejectDetail.wholeSalePrice;
}

/**
 * 批号
 */
protected function batch_changeHandler(event:Event):void
{
	var lRejectDetail:MaterialRejectDetail=gdRejectDetail.selectedItem as MaterialRejectDetail;
	if (!lRejectDetail)
	{
		return;
	}
	lRejectDetail.batch=batch.text;
}

/**
 * 填充当前表单
 */
protected function gdRejectDetail_itemClickHandler(event:Event):void
{
	var lRejectDetail:MaterialRejectDetail=gdRejectDetail.selectedItem as MaterialRejectDetail;
	if (!lRejectDetail)
	{
		return;
	}
	fillDetailForm(lRejectDetail);
}

/**
 * 打印
 * */
protected function printClickHandler(event:Event):void
{
	printReport("1");
	
}

/**
 * 输出
 * */
protected function expClickHandler(event:Event):void
{
//	printReport("0");
	DefaultPage.exportExcel(gdRejectDetail,"报损单");
	
}

/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	setPrintPageSize();
	var dataList:ArrayCollection=gdRejectDetail.dataProvider as ArrayCollection;
	
	var dict:Dictionary=new Dictionary();
	
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	
	dict["主标题"]="物资报损单";
	dict["制表人"]="制表人:" + AppInfo.currentUserInfo.userName;
	dict["仓库"]=storageCode.selectedItem.storageName;
	dict["报损部门"]=outDeptCode.text==null?"":outDeptCode.text;
	dict["报损单号"]=billNo.text==null?"":billNo.text;
	dict["经手人"]=personId.text;

	dict["制单人"]=maker.text;
	dict["审核人"]=verifier.text;
	for (var i:int=0; i < dataList.length; i++)
	{
		var item:Object=dataList.getItemAt(i);
		item.materialName=item.materialName==null?"":item.materialName;
		item.materialSpec=item.materialSpec==null?"":item.materialSpec;
		item.materialUnits=item.materialSpec==null?"":item.materialSpec;
		item.batch=item.batch==null?"":item.batch;
		item.detailRemark = item.detailRemark  == null ? "" : item.detailRemark ; 
//		item.wholeSalePrice = item.tradePrice;
	}
	if (printSign == "1")
	{
		ReportPrinter.LoadAndPrint("report/material/other/reject.xml", dataList, dict);
	}
	else
	{
		ReportViewer.Instance.Show("report/material/other/reject.xml", dataList, dict);
	}
}

/**
 * 增加
 * */
protected function addClickHandler(event:Event):void
{
	//新增权限
	if (!checkUserRole('01'))
	{
		return;
	}
	
	//增加按钮
	toolBar.addToPreState()
	
	//显示输入明细区域
	bord.height=111;
	hiddenVGroup.includeInLayout=true;
	hiddenVGroup.visible=true;
	
	//设置可写
	setReadOnly(false);
	//清空当前表单
	clearForm(true, true);
	//表头赋值
	//授权仓库赋值
	if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
	{
		storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
		storageCode.selectedIndex=0;
	}
	rdType.txtContent.text="报损出库";
	_materialrejectMaster.rdType='203';
	_materialrejectMaster.currentStatus='0';
	
	//表尾赋值
	maker.text=AppInfo.currentUserInfo.userName;
	makeDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");
	//得到区域
	billNo.setFocus();
}

/**
 * 修改
 * */
protected function modifyClickHandler(event:Event):void
{
	//判断当前表格是否具有明细数据
	var laryDetails:ArrayCollection=gdRejectDetail.dataProvider as ArrayCollection;
	if (!laryDetails)
	{
		return;
	}
	
	//当前状态显示的值
	if (_materialrejectMaster.currentStatus == "2")
	{
		Alert.show("该物资报损单已经审核，不能再修改");
		return;
	}
	if (_materialrejectMaster.currentStatus == "0")
	{
		toolBar.setEnabled(toolBar.btVerify, true);
	}
	else
	{
		toolBar.setEnabled(toolBar.btSave, false);
		toolBar.setEnabled(toolBar.btVerify, false);
	}
	
	//修改按钮初始化
	toolBar.modifyToPreState();
	//显示输入明细区域
	bord.height=111;
	hiddenVGroup.includeInLayout=true;
	hiddenVGroup.visible=true;
	
	//设置可写
	setReadOnly(false);
	//显示所选择的明细记录
	gdRejectDetail_itemClickHandler(null);
	storageCode.enabled=false;
}

/**
 * 删除
 * */
protected function deleteClickHandler(event:Event):void
{
	//删除权限
	if (!checkUserRole('03'))
	{
		return;
	}
	
	if (_materialrejectMaster.autoId == "" || (_materialrejectMaster.autoId==null))
	{
		Alert.show("请先查询要删除的物资报损单！", "提示信息");
		return;
	}
	
	if (_materialrejectMaster.currentStatus == '1')
	{
		Alert.show("该物资报损单已审核！", "提示信息");
		return;
	}
	else if (_materialrejectMaster.currentStatus == '2')
	{
		Alert.show("该物资报损单已记账！", "提示信息");
		return;
	}
	
	Alert.show("您确定要删除当前记录？", "提示信息", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
	{
		if (e.detail == Alert.YES)
		{
			var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
			{
				Alert.show("删除物资报损单成功！", "提示信息");
			});
			ro.deleteReject(_materialrejectMaster.autoId);
		}
	});
}

/**
 * 保存
 * */
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
	var laryDetails:ArrayCollection=gdRejectDetail.dataProvider as ArrayCollection;
	if (!laryDetails)
	{
		Alert.show("报损单明细记录不能为空", "提示");
		return;
	}
	//填充主记录
	fillRejectMaster();
	//保存当前数据
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
	{
		if (rev && rev.data[0])
		{
			toolBar.saveToPreState();
			//
			copyFieldsToCurrentMaster(rev.data[0], _materialrejectMaster);
			//
			billNo.text=_materialrejectMaster.billNo;
			
			Alert.show("物资报损单保存成功！", "提示信息");
			return;
		}
	});
	ro.saveReject(_materialrejectMaster, laryDetails);
}

/**
 * 保存前验证主记录
 */
private function validateMaster():Boolean
{
	if (outDeptCode.txtContent.text == "")
	{
		outDeptCode.txtContent.setFocus();
		Alert.show("报损部门必填", "提示");
		return false;
	}
	
	if (personId.txtContent.text == "")
	{
		personId.txtContent.setFocus();
		Alert.show("经手人必填", "提示");
		return false;
	}
	return true;
}

/**
 * 填充主记录,作为参数
 * */
private function fillRejectMaster():void
{
	_materialrejectMaster.storageCode=storageCode.selectedItem.storageCode;
	_materialrejectMaster.billNo=billNo.text;
	_materialrejectMaster.billDate=billDate.selectedDate;
	
	_materialrejectMaster.remark=remark.text;
}

/**
 * 复制当前数据记录
 */
private function copyFieldsToCurrentMaster(fsource:Object, ftarget:Object):void
{
	ObjectUtils.mergeObject(fsource, ftarget)
}

/**
 * 放弃
 * */
protected function cancelClickHandler(event:Event):void
{
	Alert.show("您是否放弃当前操作吗？", "提示", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
	{
		if (e.detail == Alert.NO)
		{
			return;
		}
		//增加项隐藏
		bord.height=70;
		hiddenVGroup.includeInLayout=false;
		hiddenVGroup.visible=false;
		
		toolBar.cancelToPreState();
		//清空当前表单
		clearForm(true, true);
		//设置只读
		setReadOnly(true);
	})
}

/**
 * 审核
 * */
protected function verifyClickHandler(event:Event):void
{
	//审核权限
	if (!checkUserRole('06'))
	{
		return;
	}
	
	//应为后台提供
	_materialrejectMaster.verifier=AppInfo.currentUserInfo.personId;
	_materialrejectMaster.verifyDate=new Date();
	
	if (_materialrejectMaster.currentStatus == "1")
	{
		Alert.show('该物资报损单已经审核', '提示信息');
		return;
	}
	
	Alert.show('您是否审核当前报损单？', '提示信息', Alert.YES | Alert.NO, null, function(e:*):void
	{
		if (e.detail == Alert.YES)
		{
			var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
			{
				//显示输入明细区域
				bord.height=70;
				hiddenVGroup.includeInLayout=false;
				hiddenVGroup.visible=false;
				//设置只读
				setReadOnly(true);
				//赋当前审核状态
				_materialrejectMaster.currentStatus='1';
				//表尾赋值
				verifier.text=AppInfo.currentUserInfo.userName;
				verifyDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");
				
				Alert.show("物资报损单审核成功！", "提示信息");
			});
			ro.verifyReject(_materialrejectMaster.autoId);
		}
	})
}

/**
 * 增行
 * */
protected function addRowClickHandler(event:Event):void
{
	materialName.text="";
	materialSpec.text="";
	materialUnits.text="";
	
	amount.text="";
	
	batch.text="0";
	
	materialCode_queryIconClickHandler(null);
}

/**
 * 删行
 * */
protected function delRowClickHandler(event:Event):void
{
	var laryDetails:ArrayCollection=gdRejectDetail.getRawDataProvider() as ArrayCollection;
	
	var lintMaxIndex:int=laryDetails.length;
	var lintSelIndex:int=gdRejectDetail.selectedIndex;
	if (lintSelIndex < 0 || lintSelIndex > lintMaxIndex - 1)
	{
		return;
	}
	
	var lRejectDetail:MaterialRejectDetail=gdRejectDetail.selectedItem as MaterialRejectDetail;
	if (!lRejectDetail)
	{
		return;
	}
	
	//已保存
	var lselIndex:int=gdRejectDetail.selectedIndex;
	if (lselIndex < 0)
	{
		return;
	}
	
	laryDetails.removeItemAt(lintSelIndex);
	if (lintSelIndex == 0)
	{
		lintSelIndex=1;
	}
	gdRejectDetail.selectedIndex=lintSelIndex - 1;
	if((gdRejectDetail.dataProvider.length)<=0)
	{
		storageCode.enabled=true;
	}
	return;
}

/**
 * 查询
 * */
protected function queryClickHandler(event:Event):void
{
	var win:WinRejectQuery=PopUpManager.createPopUp(this, WinRejectQuery, true) as WinRejectQuery;
	win.parentWin=this;
	FormUtils.centerWin(win);
}

/**
 * 首页
 * */
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
 * */
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
	
	toolBar.nextPageToPreState(currentPage,arrayAutoId.length - 1);
}

/**
 * 上一页
 * */
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
 * */
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
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
	{
		
		if (rev.data && rev.data.length > 0 && rev.data[0] != null && rev.data[1] != null)
		{
			_materialrejectMaster=rev.data[0] as MaterialRejectMaster;
			var details:ArrayCollection=rev.data[1] as ArrayCollection;
			
			//主记录赋值
			fillMaster(_materialrejectMaster);
			//明细赋值
			gdRejectDetail.dataProvider=details;
		}
		
	});
	ro.findRejectDetailById(fstrAutoId);
}


/**
 * 填充表头部分
 */
private function fillMaster(materialRdsMaster:MaterialRejectMaster):void
{
	if (!materialRdsMaster)
	{
		return;
	}
	FormUtils.fillFormByItem(this, materialRdsMaster);
	
	FormUtils.fillTextByDict(rdType, materialRdsMaster.rdType, 'deliverType');
	FormUtils.fillTextByDict(outDeptCode, materialRdsMaster.outDeptCode, 'dept');
	FormUtils.fillTextByDict(personId, materialRdsMaster.personId, 'personId');
	FormUtils.fillTextByDict(maker, materialRdsMaster.maker, 'personId');
	FormUtils.fillTextByDict(verifier, materialRdsMaster.verifier, 'personId');
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
 * 退出
 * */
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
 * 设置默认打印机的打印页面
 * */
private function setPrintPageSize():void{
	var lnumWidth:Number=210*1000
	var lnumHeight:Number=parseFloat(ReportParameter.reportPrintHeight_in)
	lnumHeight=isNaN(lnumHeight)?288*1000:lnumHeight*1000 
	ExternalInterface.call("setPrintPageSize",lnumWidth,lnumHeight)
}
