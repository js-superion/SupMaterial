/**
 *		 整进整出处理模块
 *		 ryh 2013.1.16
 *		
 **/


import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.ObjectUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.base.util.StringUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.other.rdTogether.view.WinRdTogetherQuery;
import cn.superion.material.util.DefaultPage;
import cn.superion.material.util.MainToolBar;
import cn.superion.material.util.MaterialCurrentStockShower;
import cn.superion.material.util.MaterialDictShower;
import cn.superion.material.util.ReportParameter;
import cn.superion.report.hlib.UrlLoader;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialRdsDetail;
import cn.superion.vo.material.MaterialRdsMaster;

import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.events.DataGridEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;
import mx.utils.StringUtil;

import spark.events.IndexChangeEvent;
import spark.events.TextOperationEvent;

registerClassAlias("cn.superion.material.entity.MaterialRdsMaster", cn.superion.vo.material.MaterialRdsMaster);
registerClassAlias("cn.superion.material.entity.MaterialRdsDetail", cn.superion.vo.material.MaterialRdsDetail);

public static const MENU_NO:String="0405";
//服务类
public static const DESTANATION:String="rdTogetherImpl";
public var menuItemsEnableValues:Object = ['0','0']; //1表可用，0不可用

private var _winY:int=0;

//入库主记录
private var _materialRdsMaster:MaterialRdsMaster=new MaterialRdsMaster();
//出库主记录
private var _deliverRdsMaster:MaterialRdsMaster=new MaterialRdsMaster();

private var _materialRdsDetail:MaterialRdsDetail=new MaterialRdsDetail();
private var _materialRdsDetail1:MaterialRdsDetail=new MaterialRdsDetail();

//是否批号管理
[Bindable]
private var _bathSign:Boolean;

//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;
private var isShowPurchase :Boolean = false; //报表上是否显示采购人
private var isShowLeftLine:Boolean= false;//报表左侧是否加线条
private var isRdsBatch:Boolean=false;//入库时是否按批号入库，参数定义

[Bindable]
private var isEditorPrice:Boolean=false;
private var isGray:Boolean=false;

public var ischen:Boolean=false;


/**
 * 初始化当前窗口
 * */
public function doInit():void
{
	//	parentDocument.title="整进整出处理";
	if(parentDocument is WinModual){
		parentDocument.title="整进整出处理";
	}
	
	_winY=this.parentApplication.screen.height - 345;
//	operationNo.width=storageCode.width;
//	billNo.width=salerCode.width;
	deptCode.width=invoiceDate.width;
	personId.width=invoiceNo.width;
	deliverDept.width=storageCode.width;
	deliverPerson.width=salerCode.width;
	deliverBillNo.width=deptCode.width;
	//
	initPanel();
	setPrintPageToDefault();
	//加载系统参数，
	var ro:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl', function(rev:Object):void
	{
		if (rev.data && rev.data[0] == '1')
		{
			isShowPurchase=true; //允许零出库
		}
		else{
			isShowPurchase=false; //不允许零出库
		}
		var ro:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl', function(rev:Object):void
		{
			if (rev.data && rev.data[0] == '1')
			{
				isShowLeftLine=true; 
			}
			else{
				isShowLeftLine=false; 
			}
			
		});
		ro.findSysParamByParaCode("0906");
	});
	ro.findSysParamByParaCode("0905");
	
	ro=RemoteUtil.getRemoteObject('centerSysParamImpl', function(rev:Object):void
	{
		if (rev.data && rev.data[0] == '1')
		{
			isRdsBatch=true; 
		}
		else{
			isRdsBatch=false; 
		}
		
	});
	ro.findSysParamByParaCode("0206");
	
	isEditorPrice=ExternalInterface.call("getIsEditorPrice");
	isGray=ExternalInterface.call("getIsGray");
	
}


/**
 * 面板初始化
 */
private function initPanel():void
{
	initToolBar();
	//增加项隐藏
	bord.height=105;
	hiddenVGroup.includeInLayout=false;
	hiddenVGroup.visible=false;
	//授权仓库赋值
	if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
	{
		//		storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
		//		storageCode.selectedIndex=0;
		
		var result:ArrayCollection =ObjectUtil.copy(AppInfo.currentUserInfo.storageList) as ArrayCollection;
		var newArray:ArrayCollection = new ArrayCollection();
		var ss:Array = [];
		for each(var it:Object in result){
			if(it.type == '2'||it.type == '3'){
				newArray.addItem(it);
			}
		}
		ss = newArray.toArray().reverse().sortOn("storageCode",Array.DESCENDING);
		storageCode.dataProvider=new ArrayCollection(ss);//AppInfo.currentUserInfo.storageList;
		storageCode.selectedIndex=0;		
	}
	//设置只读
	setReadOnly(true);
	//阻止表单输入
	preventDefaultForm();
	toolBar.btAbandon.label="弃审";
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1,toolBar.btAbandon, toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, toolBar.btSave, toolBar.btVerify, toolBar.imageList2, toolBar.btAddRow, toolBar.btDelRow, toolBar.imageList3, toolBar.btQuery, toolBar.imageList5, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array=[toolBar.btExit, toolBar.btQuery, toolBar.btAdd]
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}
 
/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	var i:String="";
	if(boolean){i="0"}else{i="1"}
	boolean=!boolean;
	blueType.enabled=boolean;
	redType.enabled=boolean;
	invoiceNo.enabled=boolean;
	cargoNo.enabled=boolean;
	invoiceDate.enabled=boolean;
	
	salerCode.enabled=boolean;
	
	billDate.enabled=boolean;
	invoiceDate.enabled=boolean;
	
	rdType.enabled=boolean;
	operationNo.enabled=boolean;
	if(isGray){
		billNo.enabled=!boolean;
		billMonthNo.enabled=!boolean;
	}else{
		billNo.enabled=boolean;
		billMonthNo.enabled=boolean;
	}
	
	
	deptCode.enabled=boolean;
	personId.enabled=boolean;
	remark.enabled=boolean;
	
	deliverDept.enabled=boolean;
	deliverPerson.enabled=boolean;
	deliverRemark.enabled=boolean;
	if(isGray){
		deliverBillNo.enabled=!boolean;
		deliverbillMonthNo.enabled=!boolean;
	}else{
		deliverBillNo.enabled=boolean;
		deliverbillMonthNo.enabled=boolean;
	}
	
	
	menuItemsEnableValues=[i,i];
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
		
	deliverDept.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	
	deliverPerson.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
}
/**
 * 仓库改变事件
 * */
protected function storageCode_changeHandler(event:IndexChangeEvent):void
{
	var currentList:ArrayCollection = gdRdsDetail.dataProvider as ArrayCollection;
	if(currentList.length == 0 ){
		return;
	}
	Alert.show('改变当前仓库将清空表格数据','提示',Alert.YES | Alert.NO,null,function(e:*):void{
		if (e.detail == Alert.YES ){
			//清空页面数据
			FormUtils.clearForm(hg1);
			FormUtils.clearForm(hg2);
			FormUtils.clearForm(detailGroup);
			gdRdsDetail.dataProvider = [];
		}
	})
}
/**
 * 清空表单
 */
public function clearForm(masterFlag:Boolean, detailFlag:Boolean):void
{
	if (masterFlag)
	{
		blueType.selected=true;
		
		salerCode.txtContent.text="";
		
		billDate.selectedDate=new Date();
		
		rdType.txtContent.text="";
		operationNo.text="";
		billNo.text="";
		billMonthNo.text="";
		
		deptCode.txtContent.text="";
		personId.txtContent.text="";
		remark.text="";
		
		currentStockAmount.text="";
		maker.text='';
		makeDate.text='';
		verifier.text='';
		verifyDate.text='';
		
		deliverDept.text='';
		deliverPerson.text='';
		deliverRemark.text='';
		deliverBillNo.text='';
		deliverbillMonthNo.text='';
		
		_materialRdsMaster=new MaterialRdsMaster();
		_deliverRdsMaster=new MaterialRdsMaster();
	}
	if (detailFlag)
	{
		materialCode.txtContent.text="";
		materialName.text="";
		packageSpec.text="";
		packageUnits.text="";
		
		packageAmount.text="";
		
		batch.text="0";
		availDate.text="";
		//
		invoiceDate.text = '';
		invoiceDate.selectedDate = new Date();
		invoiceNo.text = '';
		cargoNo.text='';
		detailRemark.text= '';
		yldetailRemark.text='';
		ypdetailRemark.text='';
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
	if (event.currentTarget == packageAmount && !_bathSign)
	{
		var ary:ArrayCollection = gdRdsDetail.dataProvider as ArrayCollection;
		if(ary.length > 1){
			materialCode.txtContent.setFocus();
			materialCode.txtContent.text='';
		}else{
			materialCode.txtContent.setFocus();
			materialCode.txtContent.text='';
		}
		return;
	}
	if(event.currentTarget == materialCode){
		materialCode.txtContent.text = '';
		materialCode.txtContent.setFocus();
	}
	//
	FormUtils.toNextControl(event, fctrlNext);
}

/**
 * 供应商档案
 */
protected function salerCode_queryIconClickHandler(event:Event):void
{
	//考虑到登陆人员看到不同科室的的仓库，这里根据仓库编码和单位编码到仓库字典中查对应的 所属部门；
	var ro:RemoteObject = RemoteUtil.getRemoteObject('centerStorageImpl',function(rev1:Object):void{
		if(rev1.data){
			var x:int=0;
			DictWinShower.showProviderDict(function(rev:Object):void
			{
				salerCode.txtContent.text=rev.providerName;
				
				_materialRdsMaster.salerCode=rev.providerId; 
				_materialRdsMaster.salerName=rev.providerName;
				
				_deliverRdsMaster.salerCode=rev.providerId; 
				_deliverRdsMaster.salerName=rev.providerName;
				
				invoiceDate.setFocus();
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
	MaterialDictShower.showDeptDict(function(rev:Object):void
	{
		if(event.currentTarget.id=='deptCode')
		{
			deptCode.txtContent.text=rev.deptName;
			
			_materialRdsMaster.deptCode=rev.deptCode;
		}
		else if(event.currentTarget.id=='deliverDept')
		{
			deliverDept.txtContent.text=rev.deptName;
			
			_deliverRdsMaster.deptCode=rev.deptCode;
		}
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
		if(event.currentTarget.id=='personId')
		{
			personId.txtContent.text=rev.name;
			
			_materialRdsMaster.personId=rev.personId;
		}
		else if(event.currentTarget.id=='deliverPerson')
		{
			deliverPerson.txtContent.text=rev.name;
			
			_deliverRdsMaster.personId=rev.personId;
		}
	}, x, y);
}

/**
 * 调用入库类型字典
 */
protected function rdType_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	MaterialDictShower.showReceiveTypeDict(function(rev:Object):void
	{
		rdType.txtContent.text=rev.rdName;
		
		_materialRdsMaster.rdType=rev.rdCode;
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
	//	lstorageCode = lstorageCode.substr(0,2);
	DictWinShower.showMaterialDictNew(lstorageCode, '', '', true, function(fItem:Array):void
	{
		fillIntoGrid(fItem);
	}, x, y,"1");
}

protected function gdRdsDetail_itemEditBeginHandler(event:DataGridEvent):void
{
	var lastIndex:int = gdRdsDetail.dataProvider.length - 1;
	if(lastIndex == event.rowIndex - 1){
		var ss:Boolean = event.cancelable;
		event.preventDefault();
		gdRdsDetail.selectedIndex = lastIndex
	}
}
/**
 * 自动完成表格回调
 * */
private function fillIntoGrid(fItem:Array):void
{
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	
	for(var i:int=0;i<fItem.length;i++)
	{
		var lnewlDetail:MaterialRdsDetail=new MaterialRdsDetail();
		lnewlDetail.materialId=fItem[i].materialId;
		lnewlDetail.materialClass=fItem[i].materialClass;
		lnewlDetail.barCode=fItem[i].barCode;
		lnewlDetail.materialCode=fItem[i].materialCode;
		lnewlDetail.materialName=fItem[i].materialName;
		lnewlDetail.materialSpec=fItem[i].materialSpec;
		lnewlDetail.materialUnits=fItem[i].materialUnits;
		
		lnewlDetail.packageSpec=fItem[i].packageSpec;
		lnewlDetail.packageUnits=fItem[i].packageUnits;
		if(fItem[i].amountPerPackage == '' || fItem[i].amountPerPackage == null){
			lnewlDetail.amountPerPackage = 1;
		}else{
			lnewlDetail.amountPerPackage = fItem[i].amountPerPackage;
		}
		lnewlDetail.packageAmount = 0;
		
		lnewlDetail.amount = 0;
		
		lnewlDetail.tradePrice=fItem[i].tradePrice;
		lnewlDetail.tradeMoney=fItem[i].tradePrice;
		
		lnewlDetail.factTradePrice=fItem[i].tradePrice * fItem[i].rebateRate;
		lnewlDetail.factTradeMoney=fItem[i].tradePrice * fItem[i].rebateRate;
		
		lnewlDetail.rebateRate=fItem[i].rebateRate;
		lnewlDetail.rebateRate=isNaN(lnewlDetail.rebateRate) ? 1 : lnewlDetail.rebateRate;
		
		lnewlDetail.wholeSalePrice=fItem[i].wholeSalePrice;
		lnewlDetail.wholeSaleMoney=fItem[i].wholeSalePrice;
		
		lnewlDetail.invitePrice=fItem[i].invitePrice;
		lnewlDetail.inviteMoney=fItem[i].invitePrice;
		
		lnewlDetail.retailPrice=fItem[i].retailPrice;
		lnewlDetail.retailMoney=fItem[i].retailPrice;
		
		
		lnewlDetail.batch='0'  //byzcl
		lnewlDetail.factoryCode=fItem[i].factoryCode;
		lnewlDetail.currentStockAmount=fItem[i].amount;
		
		lnewlDetail.outAmount=0;
		lnewlDetail.outSign='0';
		
		lnewlDetail.countClass = fItem[i].countClass;
		lnewlDetail.registerNo = fItem[i].registerNo;
		lnewlDetail.inviteNo = fItem[i].inviteNo;
		
		lnewlDetail.invoiceAmount=0;
		lnewlDetail.invoiceSign='0';
		lnewlDetail.invoiceNo = invoiceNo.text;
		lnewlDetail.invoiceDate = invoiceDate.selectedDate;
		lnewlDetail.chargeSign = fItem[i].chargeSign;//收费标示；
		lnewlDetail.classOnAccount = fItem[i].accountClass;//会计分类；
		lnewlDetail.highValueSign=fItem[i].highValueSign;
		lnewlDetail.agentSign=fItem[i].agentSign;
		//是否批号管理
		_bathSign=isRdsBatch && fItem[i].batchSign=='1' ? true : false;
		
		//最大批号
//		var ro:RemoteObject=RemoteUtil.getRemoteObject("receiveImpl",function(rev:Object):void
//		{
//			if(_bathSign)
//			{
//				lnewlDetail.batch=rev.data[0];
//			}
//			else
//			{
//				lnewlDetail.batch=(Number(rev.data[0])-1).toString();
//			}
//			batch.text=lnewlDetail.batch;
//		});
//		ro.findMaxBatch(lnewlDetail.materialId);
		
		lnewlDetail.checkAmount=0;
		lnewlDetail.isGive='0';
		lnewlDetail.detailRemark='整进整出';
		laryDetails.addItem(lnewlDetail);
	}
	
	
	gdRdsDetail.dataProvider=laryDetails;
	gdRdsDetail.selectedIndex=laryDetails.length - 2;
	fillDetailForm(lnewlDetail);
	storageCode.enabled=false;
	var timer:Timer=new Timer(100, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
	{
		gdRdsDetail.scrollToIndex(gdRdsDetail.selectedIndex);
		packageAmount.setFocus();
	})
	timer.start();
}

/**
 * 明细表单赋值 checked by zzj 2011.06.04
 */
private function fillDetailForm(fselDetailItem:MaterialRdsDetail):void
{
	if (!fselDetailItem)
	{
		return;
	}
	//
	materialCode.txtContent.text=fselDetailItem.materialCode;
	materialName.text=fselDetailItem.materialName;
	packageSpec.text=fselDetailItem.materialSpec;
	packageUnits.text=fselDetailItem.packageUnits;
	
	packageAmount.text=fselDetailItem.packageAmount + '';
	batch.text=fselDetailItem.batch;
	availDate.text=DateField.dateToString(fselDetailItem.availDate, 'YYYY-MM-DD');
	
	currentStockAmount.text=fselDetailItem.currentStockAmount + '';
	invoiceNo.text = fselDetailItem.invoiceNo;
	invoiceDate.text = DateField.dateToString(fselDetailItem.invoiceDate, 'YYYY-MM-DD');
	detailRemark.text = fselDetailItem.detailRemark;
	yldetailRemark.text=fselDetailItem.yldetailRemark;
	ypdetailRemark.text=fselDetailItem.ypdetailRemark;
}

/**
 * 数量进行改变事件
 */
public function amount_ChangeHandler(event:Event):void
{
	var lRdsDetail:MaterialRdsDetail=gdRdsDetail.selectedItem as MaterialRdsDetail;
	if (!lRdsDetail)
	{
		return;
	}
	var isCharDuplication:Boolean = false;
	var trimedText:String = mx.utils.StringUtil.trim(packageAmount.text); 
	for(var i:int = 1; i < trimedText.length;i ++){
		if(trimedText.charAt(i) == '-'){
			isCharDuplication = true;
			break;
		}
	}
	if(isCharDuplication){
		packageAmount.text = '-';
		packageAmount.selectRange(1,packageAmount.text.length);;
		return;	
	}
	if(isNaN(Number(trimedText)) || trimedText == '' ){
		lRdsDetail.amount = 0;
	}else{
		lRdsDetail.amount=isNaN(lRdsDetail.amount) ? 1 : lRdsDetail.amount;
		lRdsDetail.amount=parseFloat(packageAmount.text) * lRdsDetail.amountPerPackage;
	}
	lRdsDetail.packageAmount = parseFloat(packageAmount.text);
	lRdsDetail.acctAmount = lRdsDetail.amount;
	//
	lRdsDetail.tradeMoney=lRdsDetail.amount * lRdsDetail.tradePrice;
	lRdsDetail.factTradeMoney=Number((lRdsDetail.amount * lRdsDetail.factTradePrice).toFixed(2));
	
	lRdsDetail.wholeSaleMoney=Number((lRdsDetail.amount * lRdsDetail.wholeSalePrice).toFixed(2));
	lRdsDetail.inviteMoney= Number((lRdsDetail.amount * lRdsDetail.invitePrice).toFixed(2));
	
	lRdsDetail.retailMoney= Number((lRdsDetail.amount * lRdsDetail.retailPrice).toFixed(2));
}
/**
 * 数量失去焦点，若是蓝字，则为正，否则为负
 * */
protected function packageAmount_focusOutHandler(event:FocusEvent):void
{
	if(redOrBlue.selection == blueType){
		if(Number(packageAmount.text)  > 0 ){
			return;	
		}
		packageAmount.text = Number(0-Number(packageAmount.text)).toString();
		
	}else{
		if(Number(packageAmount.text)  < 0 ){
			return;	
		}
		if(packageAmount.text == '-'){
			packageAmount.text = '0';
		}
		packageAmount.text = Number(0-Number(packageAmount.text)).toString();
	}
	amount_ChangeHandler(null);
}
/**
 * 批号
 */
protected function batch_changeHandler(event:Event):void
{
	var lRdsDetail:MaterialRdsDetail=gdRdsDetail.selectedItem as MaterialRdsDetail;
	if (!lRdsDetail)
	{
		return;
	}
	lRdsDetail.batch=batch.text;
}
/**
 * 批号字典
 */
protected function batch_queryIconClickHandler(event:Event):void
{
	var lselItem:MaterialRdsDetail=gdRdsDetail.selectedItem as MaterialRdsDetail;
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


/**
 * 批号字典自动完成表格回调
 * */
private function fillIntoGridByBatch(faryItems:Array):void
{
	var lRdsDetail:MaterialRdsDetail=gdRdsDetail.selectedItem as MaterialRdsDetail;
	if (!lRdsDetail)
	{
		return;
	}
	var i:int=0;
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	
	for each (var item:Object in faryItems)
	{
		var lnewlDetail:MaterialRdsDetail=new MaterialRdsDetail();
		if (i == 0)
		{
			batch.text=item.batch;
			
			lRdsDetail.tradePrice=item.tradePrice;
			lnewlDetail.tradeMoney=0;
			lRdsDetail.factoryCode=item.factoryCode;
			lRdsDetail.madeDate=item.madeDate;
			lRdsDetail.batch=item.batch;
			lRdsDetail.availDate=item.availDate;
			lnewlDetail.wholeSalePrice=lRdsDetail.wholeSalePrice;
			lnewlDetail.wholeSaleMoney=0;
			lnewlDetail.retailPrice=lRdsDetail.retailPrice;
			lnewlDetail.retailMoney=0;
			
			lnewlDetail=lRdsDetail;
			i++;
			continue;
		}
		
		lnewlDetail.materialId=lRdsDetail.materialId;
		lnewlDetail.materialClass=lRdsDetail.materialClass;
		lnewlDetail.barCode=lRdsDetail.barCode;
		lnewlDetail.materialCode=lRdsDetail.materialCode;
		lnewlDetail.materialName=lRdsDetail.materialName;
		lnewlDetail.materialSpec=lRdsDetail.materialSpec;
		lnewlDetail.materialUnits=lRdsDetail.materialUnits;
		
		lnewlDetail.amount=0;
		
		lnewlDetail.tradePrice=item.tradePrice;
		lnewlDetail.tradeMoney=0;
		
		lnewlDetail.rebateRate=lRdsDetail.rebateRate;
		lnewlDetail.rebateRate=isNaN(lRdsDetail.rebateRate) ? 1 : lRdsDetail.rebateRate;
		
		lnewlDetail.factTradePrice=lRdsDetail.tradePrice * lRdsDetail.rebateRate;
		lnewlDetail.factTradeMoney=0;
		
		lnewlDetail.wholeSalePrice=lRdsDetail.wholeSalePrice;
		lnewlDetail.wholeSaleMoney=0;
		
		lnewlDetail.invitePrice=lRdsDetail.invitePrice;
		lnewlDetail.inviteMoney=0;
		
		lnewlDetail.retailPrice=lRdsDetail.retailPrice;
		lnewlDetail.retailMoney=0;
		
		lnewlDetail.factoryCode=item.factoryCode;
		
		lnewlDetail.currentStockAmount=lRdsDetail.amount;
		
		lnewlDetail.madeDate=item.madeDate;
		lnewlDetail.batch=item.batch;
		lnewlDetail.availDate=item.availDate;
		
		
		lnewlDetail.outAmount=0;
		lnewlDetail.outSign='0';
		
		lnewlDetail.invoiceAmount=0;
		lnewlDetail.invoiceSign='0';
		
		lnewlDetail.highValueSign=lRdsDetail.highValueSign;
		lnewlDetail.agentSign=lRdsDetail.agentSign;
		
		lnewlDetail.checkAmount=0;
		lnewlDetail.isGive='0';
		
		laryDetails.addItem(lnewlDetail);
	}
	gdRdsDetail.dataProvider=laryDetails;
	gdRdsDetail.selectedItem=lnewlDetail;
	
	fillDetailForm(lnewlDetail);
	
	var timer:Timer=new Timer(100, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
	{
		gdRdsDetail.scrollToIndex(gdRdsDetail.selectedIndex);
		materialCode.txtContent.text="";
		materialCode.txtContent.setFocus();
	})
	timer.start();
}



/**
 * 有效日期
 */
protected function availDate_changeHandler(event:Event):void
{
	var lRdsDetail:MaterialRdsDetail=gdRdsDetail.selectedItem as MaterialRdsDetail;
	if (!lRdsDetail)
	{
		return;
	}
	
	lRdsDetail.availDate=availDate.selectedDate;
}
/**
 * 发票日期
 */
protected function invoiceDate_changeHandler(event:Event):void
{
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	if (laryDetails.length == 0)
	{
		return;
	}
	for each(var item:MaterialRdsDetail in laryDetails){
		item.invoiceDate = invoiceDate.selectedDate;
	}
}
/**
 * 发票号
 * */
protected function invoiceNo_changeHandler(event:TextOperationEvent):void
{
	var laryDetail:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	if (laryDetail.length == 0)
	{
		return;
	}
	for each(var item:MaterialRdsDetail in laryDetail){
		item.invoiceNo = invoiceNo.text;
	}
}
/**
 * 明细备注
 * */
protected function detailRemark_changeHandler(event:TextOperationEvent):void
{
	var lRdsDetail:MaterialRdsDetail=gdRdsDetail.selectedItem as MaterialRdsDetail;
	if (!lRdsDetail)
	{
		return;
	}
	
	lRdsDetail.detailRemark=detailRemark.text;
}
/**
 * 医疗明细备注
 * */
protected function yldetailRemark_changeHandler(event:TextOperationEvent):void
{
	var lRdsDetail:MaterialRdsDetail=gdRdsDetail.selectedItem as MaterialRdsDetail;
	if (!lRdsDetail)
	{
		return;
	}
	
	lRdsDetail.yldetailRemark=yldetailRemark.text;
}
/**
 * 去向明细备注
 * */
protected function ypdetailRemark_changeHandler(event:TextOperationEvent):void
{
	var lRdsDetail:MaterialRdsDetail=gdRdsDetail.selectedItem as MaterialRdsDetail;
	if (!lRdsDetail)
	{
		return;
	}
	
	lRdsDetail.ypdetailRemark=ypdetailRemark.text;
}
/**
 * 填充当前表单 checked by zzj 2011.04.22
 */
protected function gdRdsDetail_itemClickHandler(event:Event):void
{
	var lRdsDetail:MaterialRdsDetail=gdRdsDetail.selectedItem as MaterialRdsDetail;
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
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		
	});
	ro.updateRdsPrintSign(_materialRdsMaster.autoId);
	
}

/**
 * 输出
 * 
 */
protected function expClickHandler(event:Event):void
{
//	printReport("0");
	makeExport(gdRdsDetail);
	
}
/**
 *导出为EXCEL 
 */
private function makeExport(dataGridName:Object):void{
	
	var laryDataList:ArrayCollection=new ArrayCollection();
	var cols:Array=[];
	var excelFile:ExcelFile = new ExcelFile();
	var sheet:Sheet = new Sheet();
	laryDataList = dataGridName.dataProvider as ArrayCollection;
	cols=dataGridName.columns;
	sheet.resize(dataGridName.dataProvider.length+10,cols.length+10);
	addExcelHeader(dataGridName,sheet);
	addExcelData(laryDataList,sheet,dataGridName);
	addExcelLaster(dataGridName,sheet);
	excelFile.sheets.addItem(sheet);
	var mbytes:ByteArray = excelFile.saveToByteArray();
	var  file:FileReference=new FileReference();
	var _currentDate:String=DateField.dateToString(new Date(),'YYYY-MM-DD');
	var excelTitle:String='整进整出表'+_currentDate;
	file.save(mbytes,excelTitle+".xls");
}
private function addExcelHeader(dataList:Object,fsheet:Sheet):void{   
	var cols:Array=dataList.columns;	
	var i:int=0;
	for each(var col:* in cols){
		fsheet.setCell(0,i,col.headerText);
		i++;
	}
}
private function addExcelLaster(dataList:Object,fsheet:Sheet):void{   
	var cols:Array=dataList.columns;	
	var i:int=0;
	var initMon6:Number=0;
	var initMon7:Number=0;
	var initMon8:Number=0;
	var lary:ArrayCollection = dataList.dataProvider as ArrayCollection;
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).wholeSaleMoney != null && lary.getItemAt(j).wholeSaleMoney != ''){
			initMon6 += lary.getItemAt(j).wholeSaleMoney;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).tradeMoney != null && lary.getItemAt(j).tradeMoney != ''){
			initMon7 += lary.getItemAt(j).tradeMoney;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).retailMoney != null && lary.getItemAt(j).retailMoney != ''){
			initMon8 += lary.getItemAt(j).retailMoney;
		}
	}
	
	for each(var col:* in cols){
		if(i==0){
			fsheet.setCell(dataList.dataProvider.length+1,i,"合计");
			fsheet.setCell(dataList.dataProvider.length+2,i,"仓库：");
			fsheet.setCell(dataList.dataProvider.length+3,i,"入库单号：");
			fsheet.setCell(dataList.dataProvider.length+4,i,"入库日期：");
			fsheet.setCell(dataList.dataProvider.length+5,i,"供应单位：");
			fsheet.setCell(dataList.dataProvider.length+6,i,"领用部门：");
			fsheet.setCell(dataList.dataProvider.length+7,i,"领用人：");
			fsheet.setCell(dataList.dataProvider.length+8,i,"备注：");
		}if(i==1){
			fsheet.setCell(dataList.dataProvider.length+2,i,ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict, 'storage', _materialRdsMaster.storageCode) == null?
				"":ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict, 'storage', _materialRdsMaster.storageCode).storageName);
			fsheet.setCell(dataList.dataProvider.length+3,i,_materialRdsMaster.billNo);
			fsheet.setCell(dataList.dataProvider.length+4,i,DateUtil.dateToString(_materialRdsMaster.billDate,'YYYY-MM-DD'));
			fsheet.setCell(dataList.dataProvider.length+5,i,_materialRdsMaster.salerName == null ? "" : _materialRdsMaster.salerName);
			fsheet.setCell(dataList.dataProvider.length+6,i,deliverDept.text);
			fsheet.setCell(dataList.dataProvider.length+7,i,deliverPerson.text);
			fsheet.setCell(dataList.dataProvider.length+8,i,_materialRdsMaster.remark);
		}else if(i==8){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon6);
		}else if(i==10){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon7);
		}else if(i==13){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon8);
		}
		i++;
	}
}

private function addExcelData(laryDataList:ArrayCollection,fsheet:Sheet,gridName:Object):void{
	var lintRow:int=1;
	var cols:Array=gridName.columns;
	for each(var litem:Object in laryDataList){
		var lintColumn:int = 0;
		var index:int =0;
		for each(var col:DataGridColumn in cols){
			fsheet.setCell(lintRow,0,lintRow ||'');
			if(litem[cols[index].dataField] is Date)
				fsheet.setCell(lintRow,lintColumn,DateField.dateToString(litem[cols[index].dataField],'YYYY-MM-DD'));
			else
				fsheet.setCell(lintRow,lintColumn,litem[cols[index].dataField]|| '');
			index++;
			lintColumn ++;
		}
		lintRow ++;
	}
	
}
/**
 * 拼装打印数据，并计算页码
 * */
private function preparePrintData(faryData:ArrayCollection):void
{
	var rdBillNo:String=""
	var pageNo:int=0;
	for (var i:int=0; i < faryData.length; i++)
	{
		var item:Object=faryData.getItemAt(i);
		if(item.rdBillNo!=rdBillNo){
			rdBillNo=item.rdBillNo
			pageNo++;
		}
		item.wholeSalePrice = item.amountPerPackage * item.wholeSalePrice; //
		item.invitePrice = item.amountPerPackage * item.invitePrice; //
		item.retailPrice = item.amountPerPackage * item.retailPrice; //
		item.tradePrice = item.amountPerPackage * item.tradePrice; //
		
		item.factoryName=!item.factoryName ? '' : item.factoryName
		item.pageNo=pageNo;
		item.factoryName = item.factoryName.substr(0,6);
		item.packageSpec = item.packageSpec == null ? "" : item.packageSpec;
		item.materialSpec = item.materialSpec == null ? "" : item.materialSpec;
		item.packageUnits = item.packageUnits == null ? item.materialUnits:item.packageUnits
		item.materialSpec = item.materialSpec == null ? "" : item.materialSpec;
//		item.nameSpec = item.materialName + " "+(item.packageSpec == null ? "" : item.packageSpec);
		item.nameSpec = item.materialName;
		item.invoiceNo = item.invoiceNo?item.invoiceNo:"";
		item.countClass = item.countClass?item.countClass:"";
		item.detailRemark = item.detailRemark?item.detailRemark:"";
		item.ypdetailRemark = item.ypdetailRemark?item.ypdetailRemark:"";
		item.yldetailRemark = item.yldetailRemark?item.yldetailRemark:"";
	}
}
/**
 * 生成表格尾第二行
 * */
private function createPrintSecondBottomLine(fLastItem:Object):String
{
	var lstrLine:String = "";
//	if(isShowPurchase){
//		var purchaser:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',_materialRdsMaster.personId);
//		lstrLine = "采购:{0}          审核:{1}         制单:{2}  ";
//		lstrLine=StringUtils.format(lstrLine, 
//			purchaser?purchaser.personIdName:"",
//			"",
//			maker.text)
//	}
//	else{
//		lstrLine = "审核:{0}         制单:{1}        ";
//		lstrLine=StringUtils.format(lstrLine, 
//			"",
//			maker.text)
//	}
	lstrLine = "采购:{0}                 会计:                 接收人:{1}                 制单人:{2}                 ";
	lstrLine=StringUtils.format(lstrLine,"","",maker.text)
	
	return lstrLine;
}

/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	setPrintPageSize()
	var dataList1:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	var dataList:ArrayCollection = ObjectUtil.copy(dataList1) as ArrayCollection;
	var rawList:ArrayCollection = gdRdsDetail.getRawDataProvider() as ArrayCollection;
	var lastItem:Object=rawList.getItemAt(rawList.length - 1);
	preparePrintData(dataList);
	var dict:Dictionary=new Dictionary();
	
	dict["主标题"]="整进整出单";
	dict["单位"] = AppInfo.currentUserInfo.unitsName;
	dict["仓库"] = ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict, 'storage', _materialRdsMaster.storageCode) == null?
		"":ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict, 'storage', _materialRdsMaster.storageCode).storageName;
	
	dict["供应单位"]=_materialRdsMaster.salerName == null ? "" : _materialRdsMaster.salerName;
	dict["入库单号"]=_materialRdsMaster.billNo;
	dict["入库类别"]=rdType.text;
	dict["进货单号"]=_materialRdsMaster.cargoNo?_materialRdsMaster.cargoNo:"";
	dict["入库日期"]=DateUtil.dateToString(_materialRdsMaster.billDate,'YYYY-MM-DD');
	dict["领用部门"]=deliverDept.text;
	dict["领用人"]=deliverPerson.text;
	dict["出库单号"]=deliverBillNo.text;
	dict["备注"]=_materialRdsMaster.remark;
	dict["月单号"]=_materialRdsMaster.billMonthNo;
	var dept:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', _materialRdsMaster.deptCode);
	dict["合计进价"]=lastItem.wholeSaleMoney.toFixed(2);//批发价
	dict["表尾第二行"]=createPrintSecondBottomLine(lastItem)
	var reportUrl:String="";
	var stCode:String = storageCode.selectedItem?storageCode.selectedItem.storageCode:"";
	if(stCode != '102'){
		if(isShowLeftLine){
			reportUrl = "report/material/other/rdTogether21.xml"
		}else{
			reportUrl = "report/material/other/rdTogether.xml"
		}
	}else{
		if(isShowLeftLine){
			reportUrl = "report/material/other/YLrdTogether21.xml"
		}else{
			reportUrl = "report/material/other/rdTogether.xml"
		}
	}
	loadReportXml(reportUrl, dataList, dict,printSign)
}
private function loadReportXml(reportUrl:String,faryDetails:ArrayCollection, fdict:Dictionary,fprintSign:String):void{
	var loader:UrlLoader=new UrlLoader();
	loader.addEventListener(Event.COMPLETE, function(event:Event):void{
		var xml:XML=XML(event.currentTarget.Data)
		if(ReportParameter.reportPrintHeight_in&&ReportParameter.reportPrintHeight_in!='0'){
			var lreportHeight:String=parseFloat(ReportParameter.reportPrintHeight_in)/10+''
			xml.PageHeight=lreportHeight	
		}		
		if (fprintSign == "1")
		{
			ReportPrinter.Print(xml, faryDetails, fdict);
		}
		else
		{
			ReportViewer.Instance.Show(xml, faryDetails, fdict);
		}
	});
	loader.Load(reportUrl);
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
	bord.height=212;
	hiddenVGroup.includeInLayout=true;
	hiddenVGroup.visible=true;
	
	//设置可写
	setReadOnly(false);
	//清空当前表单
	clearForm(true, true);
	storageCode.enabled = true;
	//表头赋值
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
		storageCode.selectedIndex=0;
	}
	rdType.txtContent.text="整进整出";
	_materialRdsMaster.rdFlag='1';
	_materialRdsMaster.rdType='110';
	_materialRdsMaster.operationType='110';
	_materialRdsMaster.currentStatus='0';
	
	_deliverRdsMaster.rdFlag='2';
	_deliverRdsMaster.rdType='210';
	_deliverRdsMaster.operationType='210';
	_deliverRdsMaster.currentStatus='0'
		
	//表尾赋值
	maker.text=AppInfo.currentUserInfo.userName;
	makeDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");
	//得到区域
	salerCode.txtContent.setFocus();
}
/**
 * 弃审按钮
 */ 
protected function toolBar_abandonClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	Alert.show('您是否弃审该张单据？', '提示信息', Alert.YES | Alert.NO, null, function(e:*):void
	{
		if (e.detail == Alert.YES)
		{
			var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
			{
				findRdsById(_materialRdsMaster.autoId);
				Alert.show("整进整出弃审成功！", "提示信息");
			});
			ro.cancelVerifyRds(_materialRdsMaster.autoId);
		}
	})
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
	if (_materialRdsMaster.currentStatus == "2")
	{
		Alert.show("该入库单已经审核，不能再修改");
		return;
	}
	if (_materialRdsMaster.currentStatus == "0")
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
	bord.height=230;
	hiddenVGroup.includeInLayout=true;
	hiddenVGroup.visible=true;
	
	//设置可写
	setReadOnly(false);
	//显示所选择的明细记录
	gdRdsDetail_itemClickHandler(null);
}


//删除
protected function deleteClickHandler(event:Event):void
{
	//删除权限
	if (!checkUserRole('03'))
	{
		return;
	}
	
	if (_materialRdsMaster.autoId == "" || (_materialRdsMaster.autoId == null))
	{
		Alert.show("请先查询要删除的整进整出单！", "提示信息");
		return;
	}
	
	if (_materialRdsMaster.currentStatus == '1')
	{
		Alert.show("该整进整出单已审核！", "提示信息");
		return;
	}
	else if (_materialRdsMaster.currentStatus == '2')
	{
		Alert.show("该整进整出单已记账！", "提示信息");
		return;
	}
	
	Alert.show("您确定要删除当前记录？", "提示信息", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
	{
		if (e.detail == Alert.YES)
		{
			var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
			{
				Alert.show("删除整进整出单成功！", "提示信息");
				doInit();
				//清空当前表单
				clearForm(true, true);
			});
			ro.deleteRds(_materialRdsMaster.autoId);
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
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	if (laryDetails.length == 0 )
	{
		Alert.show("入库单明细记录不能为空", "提示");
		return;
	}
	if(!MainToolBar.validateItem(gdRdsDetail,['packageAmount'],['0']))
		return;
	
	//默认进价和批发价相等 ryh 13.2.23
	if(isEditorPrice)
	{
		for each(var item:Object in laryDetails)
		{
			if(item.tradePrice==null || isNaN(item.tradePrice) || item.tradePrice==0)
			{
				item.tradePrice=item.wholeSalePrice;
				item.tradeMoney=item.wholeSaleMoney;
			}
		}
		
	}
	//填充主记录
	fillRdsMaster();
//	toolBar.btSave.enabled = false;
	//保存当前数据
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		if (rev && rev.data[0])
		{
			toolBar.saveToPreState();
			//
			copyFieldsToCurrentMaster(rev.data[0], _materialRdsMaster);
			//
			billNo.text=_materialRdsMaster.billNo;
			doInit();
			billNo.enabled=false;
			billMonthNo.enabled=false;
			deliverBillNo.enabled=false;
			deliverbillMonthNo.enabled=false;
			findRdsById(rev.data[0].autoId);
			Alert.show("整进整出保存成功！", "提示信息");
			return;
		}
	});
	ro.saveRdTogether(_materialRdsMaster,_deliverRdsMaster,laryDetails);
}
/**
 * 点击红蓝单
 * */
protected function redOrBlue_changeHandler(event:Event):void
{
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	if(laryDetails.length ==0){
		return	
	}
	Alert.show('切换单据类型将清空页面数据','提示',Alert.YES | Alert.NO,null,function(e:*):void{
		if (e.detail == Alert.YES ){
			//清空页面数据
			FormUtils.clearForm(hg1);
			FormUtils.clearForm(hg2);
			FormUtils.clearForm(detailGroup);
			gdRdsDetail.dataProvider = [];
		}else{
			redOrBlue.selection = event.target.selection == redType?blueType:redType;
		}
	}) 
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
	
	if (rdType.txtContent.text == "")
	{
		rdType.txtContent.setFocus();
		Alert.show("采购类型必填", "提示");
		return false;
	}
	if (deliverDept.txtContent.text == "")
	{
		deliverDept.txtContent.setFocus();
		Alert.show("领用部门必填", "提示");
		return false;
	}
	if (deliverPerson.txtContent.text == "")
	{
		deliverPerson.txtContent.setFocus();
		Alert.show("领用人必填", "提示");
		return false;
	}
	return true;
}

/**
 * 填充主记录,作为参数
 * */
private function fillRdsMaster():void
{
	_materialRdsMaster.invoiceType=blueType.selected ? '1' : '2';
	_materialRdsMaster.storageCode=storageCode.selectedItem.storageCode;
	_materialRdsMaster.billNo=billNo.text;
	_materialRdsMaster.billMonthNo=billMonthNo.text;
	_materialRdsMaster.billDate=billDate.selectedDate;
	_materialRdsMaster.invoiceDate = invoiceDate.selectedDate;
	_materialRdsMaster.operationNo=operationNo.text;
	_materialRdsMaster.cargoNo=cargoNo.text;
	
	var _space:String="";
	if(remark.text){
		_space=',';
	}
	_materialRdsMaster.remark="整进整出"+_space+remark.text;
	
	//出库记录
	_deliverRdsMaster.invoiceType=blueType.selected ? '1' : '2';
	_deliverRdsMaster.storageCode=storageCode.selectedItem.storageCode;
	_deliverRdsMaster.billNo=deliverBillNo.text;
	_deliverRdsMaster.billMonthNo=deliverbillMonthNo.text;
	_deliverRdsMaster.billDate=billDate.selectedDate;
	_deliverRdsMaster.invoiceDate=invoiceDate.selectedDate;
	_deliverRdsMaster.operationNo=operationNo.text;
	
	_space='';
	if(deliverRemark.text){
		_space=',';
	}
	_deliverRdsMaster.remark="整进整出"+_space+deliverRemark.text;
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
		bord.height=105;
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
	_materialRdsMaster.verifier=AppInfo.currentUserInfo.personId;
	_materialRdsMaster.verifyDate=new Date();
	
	if (_materialRdsMaster.currentStatus == "1")
	{
		Alert.show('该整进整出单已经审核', '提示信息');
		return;
	}
	
	Alert.show('您是否审核当前整进整出单？', '提示信息', Alert.YES | Alert.NO, null, function(e:*):void
	{
		if (e.detail == Alert.YES)
		{
			var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
			{
				//显示输入明细区域
				bord.height=105;
				hiddenVGroup.includeInLayout=false;
				hiddenVGroup.visible=false;
				//设置只读
				setReadOnly(true);
				//赋当前审核状态 
				_materialRdsMaster.currentStatus='1';
				//表尾赋值
				verifier.text=AppInfo.currentUserInfo.userName;
				verifyDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");
				billNo.enabled=false;
				billMonthNo.enabled=false;
				deliverBillNo.enabled=false;
				deliverbillMonthNo.enabled=false;
				findRdsById(rev.data[0].autoId);
				Alert.show("整进整出单审核成功！", "提示信息");
			});
			ro.verifyRds(_materialRdsMaster.autoId);
		}
	})
}

//增行
protected function addRowClickHandler(event:Event):void
{
	materialName.text="";
	packageSpec.text="";
	packageUnits.text="";
	
	packageAmount.text="";
	
	batch.text="0";
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
		clearForm(false,true);
		return;
	}
	
	var lRdsDetail:MaterialRdsDetail=gdRdsDetail.selectedItem as MaterialRdsDetail;
	if (!lRdsDetail)
	{
		Alert.show("请您选择要删除的记录！", "提示");
		return;
	}
	
	//已保存
	var lselIndex:int=gdRdsDetail.selectedIndex;
	//	Alert.show("您是否删除" + lRdsDetail.materialName + "吗？", "提示", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
	//	{
	//		if (e.detail == Alert.NO)
	//		{
	//			return;
	//		}
	if (lselIndex < 0)
	{
		return;
	}
	
	laryDetails.removeItemAt(lintSelIndex);
	if (lintSelIndex == 0)
	{
		//			clearForm(false,true);
		lintSelIndex=1;
	}
	gdRdsDetail.selectedIndex=lintSelIndex - 1;
	gdRdsDetail_itemClickHandler(null);
	if((gdRdsDetail.dataProvider.length)<=0)
	{
		storageCode.enabled=true;
	}
	
	//	})
}

/**
 * 
 *查询 
 */
protected function queryClickHandler(event:Event):void
{
	var win:WinRdTogetherQuery=PopUpManager.createPopUp(this, WinRdTogetherQuery, true) as WinRdTogetherQuery;
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
	
	toolBar.nextPageToPreState(currentPage, arrayAutoId.length - 1);
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
		if (rev.data && rev.data.length > 0 && rev.data[0] != null && rev.data[1] != null && rev.data.length>2)
		{
			if(ischen){
				
				_deliverRdsMaster=rev.data[0] as MaterialRdsMaster;
				var details:ArrayCollection=rev.data[1] as ArrayCollection;
				
				if(rev.data[2]){
					_materialRdsMaster=rev.data[2] as MaterialRdsMaster;
				}
				
				//主记录赋值
				fillMaster(_materialRdsMaster,_deliverRdsMaster);
				//明细赋值
				gdRdsDetail.dataProvider=details;
				stateButton(rev.data[0].currentStatus);
			}else{
				_materialRdsMaster=rev.data[0] as MaterialRdsMaster;
				var details:ArrayCollection=rev.data[1] as ArrayCollection;
				
				if(rev.data[2]){
					_deliverRdsMaster=rev.data[2] as MaterialRdsMaster;
				}
				
				//主记录赋值
				fillMaster(_materialRdsMaster,_deliverRdsMaster);
				//明细赋值
				_materialRdsDetail1 = details.getItemAt(0) as MaterialRdsDetail;
				invoiceNo.text=_materialRdsDetail1.invoiceNo;
				gdRdsDetail.dataProvider=details;
				stateButton(rev.data[0].currentStatus);
			}
			
		}
		
	});
	ro.findRdTogetherByAutoId(fstrAutoId);
}

/**
 * 填充表头部分
 */
private function fillMaster(materialRdsMaster:MaterialRdsMaster,deliverMaster:Object):void
{
	if (!materialRdsMaster)
	{
		return;
	}
	FormUtils.fillFormByItem(this, materialRdsMaster);
	//业务号
	salerCode.text=materialRdsMaster.salerName;
	blueType.selected = materialRdsMaster.invoiceType == "1" ? true:false;
	redType.selected = materialRdsMaster.invoiceType == "2" ? true:false;

	FormUtils.fillTextByDict(rdType, materialRdsMaster.rdType, 'receviceType');
	FormUtils.fillTextByDict(deptCode, materialRdsMaster.deptCode, 'dept');
	FormUtils.fillTextByDict(personId, materialRdsMaster.personId, 'personId');
	FormUtils.fillTextByDict(maker, materialRdsMaster.maker, 'personId');
	FormUtils.fillTextByDict(verifier, materialRdsMaster.verifier, 'personId');
	
	//领用科室
	var obj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict,'dept',deliverMaster.deptCode);
	deliverDept.text=obj==null ? "" : obj.deptName;
	//领用人
	obj=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',deliverMaster.personId);
	deliverPerson.text=obj==null ? "" : obj.personIdName;
	deliverRemark.text=deliverMaster.remark;
	
	//出库单号
	deliverBillNo.text=deliverMaster.billNo;
	deliverbillMonthNo.text=deliverMaster.billMonthNo;
}

/**
 * LabFunction 处理售价显示
 */
private function retailPriceLBF(item:Object, column:DataGridColumn):String
{
	//若存在包装系数，则返回 包装系数 * 包装数量
	if(item.amountPerPackage && item.amountPerPackage!='0'){
		return (item.amountPerPackage * item.retailPrice).toFixed(2);
	}else{
		return item.retailPrice == null ? "":(item.retailPrice).toFixed(2);
	}
}

/**
 * LabFunction 处理批发价显示
 */
private function wholeSalePriceLBF(item:Object, column:DataGridColumn):String
{
	//若存在包装系数，则返回 包装系数 * 包装数量
	if(item.amountPerPackage && item.amountPerPackage!='0'){
		return (item.amountPerPackage * item.wholeSalePrice).toFixed(2);
	}else{
		return item.wholeSalePrice == null ? "": (item.wholeSalePrice).toFixed(2);;
	}
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
 * 更具数据状态显示不同的按钮
 */
protected function stateButton(currentStatus:String):void
{
	var state:Boolean=(currentStatus == "0" ? true : false);
	toolBar.btModify.enabled=state;
	toolBar.btDelete.enabled=state;
	toolBar.btVerify.enabled=state;
	toolBar.btPrint.enabled=!state;
	toolBar.btExp.enabled=!state;
	toolBar.btAbandon.enabled=(currentStatus == "1" ? true : false);
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
/**
 * 设置默认打印机的打印页面
 * */
private function setPrintPageSize():void{
	var lnumWidth:Number=210*1000
	var lnumHeight:Number=parseFloat(ReportParameter.reportPrintHeight_in)
	lnumHeight=isNaN(lnumHeight)?288*1000:lnumHeight*1000 
	ExternalInterface.call("setPrintPageSize",lnumWidth,lnumHeight)
}


/**
 * 恢复默认打印机的打印页面
 * */
private function setPrintPageToDefault():void{
	ExternalInterface.call("setPrintPageToDefault")
}
