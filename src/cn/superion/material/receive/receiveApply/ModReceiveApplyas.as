/**
 *		 特殊入库申请模块
 *		 作者:
 *		 修改：周作建 2011.06.02
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
import cn.superion.material.receive.receiveApply.view.WinReceiveApplyQuery;
import cn.superion.material.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialApplyDetail;
import cn.superion.vo.material.MaterialApplyMaster;

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

//注册服务类，否则多模块加载会丢失类型
registerClassAlias("cn.superion.material.entity.MaterialApplyMaster", cn.superion.vo.material.MaterialApplyMaster);
registerClassAlias("cn.superion.material.entity.MaterialApplyDetail", cn.superion.vo.material.MaterialApplyDetail);

public static const MENU_NO:String="0202";
//服务类
public static const DESTANATION:String="applyImpl";

private var _winY:int=0;

private var _materialApplyMaster:MaterialApplyMaster=new MaterialApplyMaster();
private var _materialApplyDetail:MaterialApplyDetail=new MaterialApplyDetail();

//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;

/**
 * 初始化当前窗口
 * */
public function doInit():void
{
//	parentDocument.title="特殊入库申请";
	if(parentDocument is WinModual){
		parentDocument.title="特殊入库申请";
	}
	_winY=this.parentApplication.screen.height - 345;
	deptCode.width=storageCode.width;
	personId.width=billNo.width;
	//
	initPanel();
	toolBar.btAbandon.label="弃审";
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
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1, toolBar.btAbandon,toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, toolBar.btSave, toolBar.btVerify, toolBar.imageList2, toolBar.btAddRow, toolBar.btDelRow, toolBar.imageList3, toolBar.btQuery, toolBar.imageList5, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array=[toolBar.btExit, toolBar.btQuery, toolBar.btAdd]
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	boolean=!boolean;

	salerCode.enabled=boolean;

	billDate.enabled=boolean;

	billNo.enabled=boolean;

	deptCode.enabled=boolean;
	personId.enabled=boolean;
	remark.enabled=boolean;
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	salerCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})

	deptCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})

	personId.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
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
		salerCode.txtContent.text="";

		billDate.selectedDate=new Date();

		billNo.text="";

		deptCode.txtContent.text="";
		personId.txtContent.text="";
		remark.text="";

		maker.text='';
		makeDate.text='';
		verifier.text='';
		verifyDate.text='';

		_materialApplyMaster=new MaterialApplyMaster();
	}
	if (detailFlag)
	{
		materialCode.txtContent.text="";
		materialName.text="";
		materialSpec.text="";
		materialUnits.text="";

		amount.text="";

		batch.text="";
		availDate.text="";

		gdRdsDetail.dataProvider=new ArrayCollection();
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
	if (event.currentTarget == availDate)
	{
		materialCode.txtContent.text='';
	}

	//
	FormUtils.toNextControl(event, fctrlNext);
}

/**
 * 供应商档案
 */
protected function salerCode_queryIconClickHandler(event:Event):void
{
	//根据仓库编码和单位编码到仓库字典中查对应的 所属部门；
	var ro:RemoteObject = RemoteUtil.getRemoteObject('centerStorageImpl',function(rev1:Object):void{
		if(rev1.data){
			var x:int=0;
			DictWinShower.showProviderDict(function(rev:Object):void
			{
				salerCode.txtContent.text=rev.providerName;
				
				_materialApplyMaster.salerCode=rev.providerId;
				_materialApplyMaster.salerName=rev.providerName;
				
				materialCode.txtContent.setFocus();
			}, x, _winY,rev1.data[0].deptCode);
		}
	});
	ro.findStorageById(storageCode.selectedItem.storageCode);
}

/**
 * 部门档案
 */
protected function deptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(rev:Object):void
	{
		deptCode.txtContent.text=rev.deptName;

		_materialApplyMaster.deptCode=rev.deptCode;
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

		_materialApplyMaster.personId=rev.personId;
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

	DictWinShower.showMaterialDictNew(lstorageCode, '', '', true, function(fItem:Object):void
	{
		fillIntoGrid(fItem);
	}, x, y,"1");
}


/**
 * 自动完成表格回调
 * */
private function fillIntoGrid(fItem:Object):void
{
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;

		var lnewlDetail:MaterialApplyDetail=new MaterialApplyDetail();

		lnewlDetail.materialId=fItem.materialId;
		lnewlDetail.materialClass=fItem.materialClass;
		lnewlDetail.barCode=fItem.barCode;
		lnewlDetail.materialCode=fItem.materialCode;
		lnewlDetail.materialName=fItem.materialName;
		lnewlDetail.materialSpec=fItem.materialSpec;
		lnewlDetail.materialUnits=fItem.materialUnits;
		
		lnewlDetail.packageSpec=fItem.packageSpec;
		lnewlDetail.packageUnits=fItem.packageUnits;
		if(fItem.amountPerPackage == '' || fItem.amountPerPackage == null){
			lnewlDetail.amountPerPackage = 1;
		}else{
			lnewlDetail.amountPerPackage = fItem.amountPerPackage;
		}
		lnewlDetail.packageAmount = 0;
		lnewlDetail.amount=1;

		lnewlDetail.tradePrice=fItem.tradePrice;
		lnewlDetail.tradeMoney=fItem.tradePrice;
		
		lnewlDetail.rebateRate=fItem.rebateRate;
		lnewlDetail.rebateRate=isNaN(fItem.rebateRate) ? 1 : fItem.rebateRate;
		
		lnewlDetail.factTradePrice=fItem.tradePrice * fItem.rebateRate;
		lnewlDetail.factTradeMoney=0;
		
		lnewlDetail.wholeSalePrice=fItem.wholeSalePrice;
		lnewlDetail.wholeSaleMoney=0;
		
		lnewlDetail.invitePrice=fItem.invitePrice;
		lnewlDetail.inviteMoney=0;
		
		lnewlDetail.retailPrice=fItem.retailPrice;
		lnewlDetail.retailMoney=fItem.retailPrice;
		lnewlDetail.chargeSign = fItem.chargeSign;//收费标示；
		lnewlDetail.classOnAccount = fItem.accountClass;//收费标示；
		lnewlDetail.factoryCode=fItem.factoryCode;

		laryDetails.addItem(lnewlDetail);
	gdRdsDetail.dataProvider=laryDetails;
	gdRdsDetail.selectedItem=lnewlDetail;

	fillDetailForm(lnewlDetail);
	storageCode.enabled=false;
	var timer:Timer=new Timer(100, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
	{
		gdRdsDetail.scrollToIndex(gdRdsDetail.selectedIndex);
		amount.setFocus();
	})
	timer.start();
}

/**
 * 明细表单赋值 checked by zzj 2011.06.04
 */
private function fillDetailForm(fselDetailItem:MaterialApplyDetail):void
{
	if (!fselDetailItem)
	{
		return;
	}
	//
	materialCode.txtContent.text=fselDetailItem.materialCode;
	materialName.text=fselDetailItem.materialName;
	materialSpec.text=fselDetailItem.materialSpec;
	materialUnits.text=fselDetailItem.materialUnits;

	amount.text=fselDetailItem.amount + '';
	batch.text=fselDetailItem.batch;
	availDate.text=DateField.dateToString(fselDetailItem.availDate, 'YYYY-MM-DD');
}

/**
 * 数量进行改变事件
 */
private function amount_ChangeHandler(event:Event):void
{
	var lRdsDetail:MaterialApplyDetail=gdRdsDetail.selectedItem as MaterialApplyDetail;
	if (!lRdsDetail)
	{
		return;
	}

	lRdsDetail.amount=parseFloat(amount.text);
	lRdsDetail.amount=isNaN(lRdsDetail.amount) ? 1 : lRdsDetail.amount;
	//
	lRdsDetail.tradeMoney=lRdsDetail.amount * lRdsDetail.tradePrice;

	lRdsDetail.retailMoney=lRdsDetail.amount * lRdsDetail.retailPrice;
}

/**
 * 批号
 */
protected function batch_changeHandler(event:Event):void
{
	var lRdsDetail:MaterialApplyDetail=gdRdsDetail.selectedItem as MaterialApplyDetail;
	if (!lRdsDetail)
	{
		return;
	}
	lRdsDetail.batch=batch.text;
}

/**
 * 有效日期
 */
protected function availDate_changeHandler(event:Event):void
{
	var lRdsDetail:MaterialApplyDetail=gdRdsDetail.selectedItem as MaterialApplyDetail;
	if (!lRdsDetail)
	{
		return;
	}

	lRdsDetail.availDate=availDate.selectedDate;
}

/**
 * 填充当前表单 checked by zzj 2011.04.22
 */
protected function gdRdsDetail_itemClickHandler(event:Event):void
{
	var lRdsDetail:MaterialApplyDetail=gdRdsDetail.selectedItem as MaterialApplyDetail;
	if (!lRdsDetail)
	{
		return;
	}
	fillDetailForm(lRdsDetail);
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
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	var _dataList:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;

	var dict:Dictionary=new Dictionary();

	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="特殊入库申请";
	dict["制表人"]="制表人:" + AppInfo.currentUserInfo.userName;
	dict["仓库"]=storageCode.selectedItem.storageName;
	dict["申请单号"]=billNo.text;
	dict["供应单位"]=salerCode.txtContent.text;
	dict["申请日期"]=billDate.text;
//	dict["月单号"]=_materialApplyMaster.billMonthNo;
	dict["审核日期"]=DateField.dateToString(_materialApplyMaster.verifyDate, "YYYY-MM-DD");
	dict["部门"]=deptCode.txtContent.text;
	dict["业务员"]=personId.txtContent.text;
	dict["备注"]=remark.text;
	dict["制单人"]="        ";
	dict["审核人"]=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', _materialApplyMaster.verifier)==null?null:ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', _materialApplyMaster.verifier).personIdName;
	if (printSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/material/receive/receiveApply.xml", _dataList, dict);
	}
	if (printSign == '0')
	{
		ReportViewer.Instance.Show("report/material/receive/receiveApply.xml", _dataList, dict);
	}
}

//增加
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

	_materialApplyMaster.currentStatus='0';

	//表尾赋值
	maker.text=AppInfo.currentUserInfo.userName;
	makeDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");
	//得到区域
	salerCode.txtContent.setFocus();
	storageCode.enabled=true;
}


//修改
protected function modifyClickHandler(event:Event):void
{
	//判断当前表格是否具有明细数据
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	if (!laryDetails)
	{
		return;
	}

	//当前状态显示的值 
	if (_materialApplyMaster.currentStatus == "2")
	{
		Alert.show("该申请单已经入库，不能再修改");
		return;
	}
	if (_materialApplyMaster.currentStatus == "1")
	{
		Alert.show("该申请单已经审核，不能再修改");
		return;
	}
	if (_materialApplyMaster.currentStatus == "0")
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
	gdRdsDetail_itemClickHandler(null);
	storageCode.enabled=false;
}


//删除
protected function deleteClickHandler(event:Event):void
{
	//删除权限
	if (!checkUserRole('03'))
	{
		return;
	}

	if (_materialApplyMaster.autoId == "" || (_materialApplyMaster.autoId==null))
	{
		Alert.show("请先查询要删除的特殊入库申请单！", "提示信息");
		return;
	}

	if (_materialApplyMaster.currentStatus == '1')
	{
		Alert.show("该特殊入库申请单已审核！", "提示信息");
		return;
	}
	else if (_materialApplyMaster.currentStatus == '2')
	{
		Alert.show("该特殊入库申请单已入库！", "提示信息");
		return;
	}

	Alert.show("您确定要删除当前记录？", "提示信息", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
	{
		if (e.detail == Alert.YES)
		{
			var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
			{
				Alert.show("删除特殊入库申请单成功！", "提示信息");
				doInit();
				//清空当前表单
				clearForm(true, true);
			});
			ro.deleteApply(_materialApplyMaster.autoId);
		}
	});
}


//保存
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
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	if (!laryDetails)
	{
		Alert.show("特殊申请单明细记录不能为空", "提示");
		return;
	}
	//填充主记录
	fillRdsMaster();
	toolBar.btSave.enabled = false;
	//保存当前数据
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		if (rev && rev.data[0])
		{
			toolBar.saveToPreState();
			//
			copyFieldsToCurrentMaster(rev.data[0], _materialApplyMaster);
			//
			billNo.text=_materialApplyMaster.billNo;
			storageCode.enabled=false;
			Alert.show("特殊申请入库保存成功！", "提示信息");
			return;
		}
	});
	ro.saveApply(_materialApplyMaster, laryDetails);
}

/**
 * 保存前验证主记录
 */
private function validateMaster():Boolean
{
	if (salerCode.txtContent.text == "")
	{
		salerCode.txtContent.setFocus();
		Alert.show("供应单位必填", "提示");
		return false;
	}

	return true;
}

/**
 * 填充主记录,作为参数
 * */
private function fillRdsMaster():void
{
	_materialApplyMaster.storageCode=storageCode.selectedItem.storageCode;
	_materialApplyMaster.billNo=billNo.text;
	_materialApplyMaster.billDate=billDate.selectedDate;

	_materialApplyMaster.remark=remark.text;
}

/**
 * 复制当前数据记录
 */
private function copyFieldsToCurrentMaster(fsource:Object, ftarget:Object):void
{
	ObjectUtils.mergeObject(fsource, ftarget)
}

//放弃
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

//审核
protected function verifyClickHandler(event:Event):void
{
	//审核权限
	if (!checkUserRole('06'))
	{
		return;
	}

	//应为后台提供
	_materialApplyMaster.verifier=AppInfo.currentUserInfo.personId;
	_materialApplyMaster.verifyDate=new Date();

	if (_materialApplyMaster.currentStatus == "1")
	{
		Alert.show('该特殊入库申请单已经审核', '提示信息');
		return;
	}

	Alert.show('您是否审核当前特殊入库申请单？', '提示信息', Alert.YES | Alert.NO, null, function(e:*):void
	{
		if (e.detail == Alert.YES)
		{
			var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
			{
				//显示输入明细区域
				bord.height=70;
				hiddenVGroup.includeInLayout=false;
				hiddenVGroup.visible=false;
				//设置只读
				setReadOnly(true);
				//赋当前审核状态
				_materialApplyMaster.currentStatus='1';
				//表尾赋值
				verifier.text=AppInfo.currentUserInfo.userName;
				verifyDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");

				Alert.show("特殊入库申请单审核成功！", "提示信息");
			});
			ro.verifyApply(_materialApplyMaster.autoId);
		}
	})
}

//增行
protected function addRowClickHandler(event:Event):void
{
	materialName.text="";
	materialSpec.text="";
	materialUnits.text="";

	amount.text="";

	batch.text="";
	availDate.text="";

	materialCode_queryIconClickHandler(null);
}

//删行
protected function delRowClickHandler(event:Event):void
{
	var laryDetails:ArrayCollection=gdRdsDetail.getRawDataProvider() as ArrayCollection;

	var lintMaxIndex:int=laryDetails.length;
	var lintSelIndex:int=gdRdsDetail.selectedIndex;
	if (lintSelIndex < 0 || lintSelIndex > lintMaxIndex - 1)
	{
		return;
	}

	var lRdsDetail:MaterialApplyDetail=gdRdsDetail.selectedItem as MaterialApplyDetail;
	if (!lRdsDetail)
	{
		Alert.show("请您选择要删除的记录！", "提示");
		return;
	}

	//已保存
	var lselIndex:int=gdRdsDetail.selectedIndex;
	if (lselIndex < 0)
	{
		return;
	}
	
	laryDetails.removeItemAt(lintSelIndex);
	if (lintSelIndex == 0)
	{
		lintSelIndex=1;
	}
	gdRdsDetail.selectedIndex=lintSelIndex - 1;
	if((gdRdsDetail.dataProvider.length)<=0)
	{
		storageCode.enabled=true;
	}
}

//查询
protected function queryClickHandler(event:Event):void
{
	var win:WinReceiveApplyQuery=PopUpManager.createPopUp(this, WinReceiveApplyQuery, true) as WinReceiveApplyQuery;
	win.parentWin=this;
	FormUtils.centerWin(win);
}

//首页
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

//下一页
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

//上一页
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

//末页
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

		if (rev.data && rev.data.length > 0 && rev.data[0] != null && rev.data[1] != null)
		{
			_materialApplyMaster=rev.data[0];
			var details:ArrayCollection=rev.data[1] as ArrayCollection;

			storageCode.enabled=false;
			//主记录赋值
			fillMaster(_materialApplyMaster);
			//明细赋值
			gdRdsDetail.dataProvider=details;
		}

	});
	ro.findApplyDetailById(fstrAutoId);
}


/**
 * 填充表头部分
 */
private function fillMaster(materialApplyMaster:MaterialApplyMaster):void
{
	if (!materialApplyMaster)
	{
		return;
	}
	FormUtils.fillFormByItem(this, materialApplyMaster);
	salerCode.text=materialApplyMaster.salerName;

	FormUtils.fillTextByDict(deptCode, materialApplyMaster.deptCode, 'dept');
	FormUtils.fillTextByDict(personId, materialApplyMaster.personId, 'personId');
	FormUtils.fillTextByDict(maker, materialApplyMaster.maker, 'personId');
	FormUtils.fillTextByDict(verifier, materialApplyMaster.verifier, 'personId');
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

//退出
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