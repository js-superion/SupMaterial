/**
 *		 其它入库处理模块
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
import cn.superion.base.util.StringUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.receive.receiveOther.view.WinReceiveOtherQuery;
import cn.superion.material.util.DefaultPage;
import cn.superion.material.util.MaterialDictShower;
import cn.superion.material.util.ReportParameter;
import cn.superion.report.hlib.UrlLoader;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialRdsDetail;
import cn.superion.vo.material.MaterialRdsMaster;

import flash.utils.Dictionary;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.controls.Text;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.events.DataGridEvent;
import mx.events.ListEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;
import mx.utils.StringUtil;

import org.alivepdf.layout.Format;

import spark.events.TextOperationEvent;

registerClassAlias("cn.superion.material.entity.MaterialRdsMaster", cn.superion.vo.material.MaterialRdsMaster);
registerClassAlias("cn.superion.material.entity.MaterialRdsDetail", cn.superion.vo.material.MaterialRdsDetail);

public static const MENU_NO:String="0203";
//服务类
public static const DESTANATION:String="receiveImpl";

private var _winY:int=0;

private var _materialRdsMaster:MaterialRdsMaster=new MaterialRdsMaster();
private var _materialRdsDetail:MaterialRdsDetail=new MaterialRdsDetail();

//是否批号管理
[Bindable]
private var _bathSign:Boolean;

//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;

[Bindable]
private var isEditorPrice:Boolean=false;//是否允许修改进价、售价，东方医院需要 ryh 13.01.21
private var isRdsBatch:Boolean=false;//入库时是否按批号入库，参数定义


/**
 * 初始化当前窗口
 * */
public function doInit():void
{
	if(parentDocument is WinModual){
		parentDocument.title="其它入库处理";
	}
	_winY=this.parentApplication.screen.height - 345;
	billNo.width=storageCode.width;
	deptCode.width=billDate.width;
	personId.width=rdType.width;
	//
	invoiceNo.width = materialCode.width;
	invoiceDate.width = materialName.width;
	initPanel();
	toolBar.btAbandon.label="弃审";
	
	var ro:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl', function(rev:Object):void
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
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1,toolBar.btAbandon, toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, toolBar.btSave, toolBar.btVerify, toolBar.imageList2, toolBar.btAddRow, toolBar.btDelRow, toolBar.imageList3, toolBar.btQuery, toolBar.imageList5, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array=[toolBar.btExit, toolBar.btQuery, toolBar.btAdd]
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	boolean=!boolean;
	blueType.enabled=boolean;
	redType.enabled=boolean;


	billDate.enabled=boolean;

	rdType.enabled=boolean;
	operationNo.enabled=boolean;
	operationType.enabled=boolean;
	billNo.enabled=boolean;
	billMonthNo.enabled=boolean;

	deptCode.enabled=boolean;
	personId.enabled=boolean;
	remark.enabled=boolean;
	
	invoiceNo.enabled = boolean;
	invoiceDate.enabled = boolean;
	detailRemark.enabled = boolean;
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
		blueType.selected=true;

		billDate.selectedDate=new Date();

		rdType.txtContent.text="";
		operationNo.text="";
		operationType.text='';
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

		_materialRdsMaster=new MaterialRdsMaster();
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
		invoiceNo.text = '';
		detailRemark.text= '';
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
	if (event.currentTarget == invoiceNo)
	{
		invoiceDate.setFocus();
		invoiceDate.selectRange(0,0);
		return;
	}
	if (event.currentTarget == packageAmount && !_bathSign)
	{
		var ary:ArrayCollection = gdRdsDetail.dataProvider as ArrayCollection;
		if(ary.length > 1){
			materialCode.txtContent.text = '';
			materialCode.txtContent.setFocus();
		}else{
			invoiceNo.setFocus();			
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
 * 部门档案
 */
protected function deptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(rev:Object):void
	{
		deptCode.txtContent.text=rev.deptName;

		_materialRdsMaster.deptCode=rev.deptCode;
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

		_materialRdsMaster.personId=rev.personId;
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

	DictWinShower.showMaterialDictNew(lstorageCode, '', '', true, function(fItem:Array):void
	{
		fillIntoGrid(fItem);
	}, x, y,"1");
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
		
		lnewlDetail.amount=1;
		lnewlDetail.acctAmount=0;
		
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
		lnewlDetail.batch='0'
		
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
		
		lnewlDetail.highValueSign=fItem[i].highValueSign;
		lnewlDetail.agentSign=fItem[i].agentSign;
		lnewlDetail.chargeSign = fItem[i].chargeSign;//收费标示；
		lnewlDetail.classOnAccount = fItem[i].accountClass;//收费标示；
		lnewlDetail.checkAmount=0;
	
		//是否批号管理
		_bathSign=isRdsBatch && fItem[i].batchSign=='1' ? true : false;
		
		
		//最大批号
		var ro:RemoteObject=RemoteUtil.getRemoteObject("receiveImpl",function(rev:Object):void
		{ 
			if(_bathSign)
			{
				lnewlDetail.batch=rev.data[0];
			}
			else
			{
				lnewlDetail.batch=(Number(rev.data[0])-1).toString();
			}
			batch.text=lnewlDetail.batch;
		});
		ro.findMaxBatch(lnewlDetail.materialId);
		
		lnewlDetail.checkAmount=0;
		laryDetails.addItem(lnewlDetail);
	}
	
	gdRdsDetail.dataProvider=laryDetails;
	gdRdsDetail.selectedItem=lnewlDetail;
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
	packageSpec.text=fselDetailItem.packageSpec;
	packageUnits.text=fselDetailItem.packageUnits;

	packageAmount.text=fselDetailItem.packageAmount + '';
	batch.text=fselDetailItem.batch;
	availDate.text=DateField.dateToString(fselDetailItem.availDate, 'YYYY-MM-DD');

	currentStockAmount.text=fselDetailItem.currentStockAmount + '';
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
	//
	lRdsDetail.packageAmount = parseFloat(packageAmount.text);
	//
	lRdsDetail.tradeMoney=lRdsDetail.amount * lRdsDetail.tradePrice;
	lRdsDetail.factTradeMoney=Number((lRdsDetail.amount * lRdsDetail.factTradePrice).toFixed(2));
	
	lRdsDetail.wholeSaleMoney=Number((lRdsDetail.amount * lRdsDetail.wholeSalePrice).toFixed(2));
	lRdsDetail.inviteMoney= Number((lRdsDetail.amount * lRdsDetail.invitePrice).toFixed(2));
	
	lRdsDetail.retailMoney= Number((lRdsDetail.amount * lRdsDetail.retailPrice).toFixed(2));
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

//输出
protected function expClickHandler(event:Event):void
{
	printReport("0");

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
		item.tradePrice = item.amountPerPackage * item.tradePrice; 
		//
		item.factoryName=!item.factoryName ? '' : item.factoryName
		item.pageNo=pageNo;
		item.factoryName = item.factoryName.substr(0,6);
		item.packageSpec = item.packageSpec == null ? "" : item.packageSpec;
		item.packageUnits = item.packageUnits == null ? item.materialUnits:item.packageUnits
		item.materialSpec = item.materialSpec == null ? "" : item.materialSpec;
		item.nameSpec = item.materialName + " "+(item.packageSpec == null ? "" : item.packageSpec);
	}
}
/**
 * 生成表格尾第二行
 * */
private function createPrintSecondBottomLine(fLastItem:Object):String
{
	var lstrLine:String="审核:{0}         制单:{1}        ";
	lstrLine=StringUtils.format(lstrLine, 
		"",
		maker.text)
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
	var dict:Dictionary=new Dictionary();
	//
	var rawList:ArrayCollection = gdRdsDetail.getRawDataProvider() as ArrayCollection;
	var lastItem:Object=rawList.getItemAt(rawList.length - 1);
	preparePrintData(dataList);
	
	dict["主标题"]="其他入库单";
	dict["单位"] = AppInfo.currentUserInfo.unitsName;
	dict["仓库"] = ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict, 'storage', _materialRdsMaster.storageCode) == null?
		"":ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict, 'storage', _materialRdsMaster.storageCode).storageName;
	dict["月单号"]=_materialRdsMaster.billMonthNo;
	dict["供应单位"]=_materialRdsMaster.salerName == null ? "":_materialRdsMaster.salerName.substr(0,10);
	dict["入库单号"]=_materialRdsMaster.billNo;
	dict["入库类别"]=rdType.text;
	dict["入库日期"]=DateUtil.dateToString(_materialRdsMaster.billDate,'YYYY-MM-DD');
	var dept:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', _materialRdsMaster.deptCode);
	dict["合计进价"]=lastItem.wholeSaleMoney.toFixed(2);//批发价
	dict["表尾第二行"]=createPrintSecondBottomLine(lastItem)
	loadReportXml("report/material/receive/receiveOther.xml", dataList, dict,printSign)
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
/**
 * 弃审按钮
 */ 
protected function toolBar_abandonClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	Alert.show('您是否弃审当前其它出库单？', '提示信息', Alert.YES | Alert.NO, null, function(e:*):void
	{
		if (e.detail == Alert.YES)
		{
			var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
			{
				findRdsById(_materialRdsMaster.autoId);
				Alert.show("其它入库弃审成功！", "提示信息");
			});
			ro.cancelVerifyRds(_materialRdsMaster.autoId);
		}
	})
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
	bord.height=140;
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
	rdType.txtContent.text="其它入库";

	_materialRdsMaster.rdFlag='1';
	_materialRdsMaster.rdType='109';
	_materialRdsMaster.operationType='109';
	_materialRdsMaster.currentStatus='0';

	//表尾赋值
	maker.text=AppInfo.currentUserInfo.userName;
	makeDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");
	//得到区域
	billNo.setFocus();
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
	bord.height=140;
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

	if (_materialRdsMaster.autoId == "" || (_materialRdsMaster.autoId == null))
	{
		Alert.show("请先查询要删除的其它入库单！", "提示信息");
		return;
	}

	if (_materialRdsMaster.currentStatus == '1')
	{
		Alert.show("该其它入库单已审核！", "提示信息");
		return;
	}
	else if (_materialRdsMaster.currentStatus == '2')
	{
		Alert.show("该其它入库单已记账！", "提示信息");
		return;
	}

	Alert.show("您确定要删除当前记录？", "提示信息", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
	{
		if (e.detail == Alert.YES)
		{
			var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
			{
				Alert.show("删除其它入库单成功！", "提示信息");
				doInit();
				//清空当前表单
				clearForm(true, true);
			});
			ro.deleteRds(_materialRdsMaster.autoId);
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
		Alert.show("入库单明细记录不能为空", "提示");
		return;
	}
	//默认进价和批发价相等 ryh 13.2.23
	if(isEditorPrice)
	{
		for each(var item:Object in laryDetails)
		{
//			item.tradePrice=item.wholeSalePrice;
//			item.tradeMoney=item.wholeSaleMoney;
			item.factTradePrice=item.wholeSalePrice;
//			item.invitePrice=item.wholeSalePrice;
		}
		
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
			copyFieldsToCurrentMaster(rev.data[0], _materialRdsMaster);
			//
			billNo.text=_materialRdsMaster.billNo;
			doInit();
			findRdsById(rev.data[0].autoId);
			Alert.show("其它入库保存成功！", "提示信息");
			return;
		}
	});
	ro.saveOtherRds(_materialRdsMaster, laryDetails);
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
	if (rdType.txtContent.text == "")
	{
		rdType.txtContent.setFocus();
		Alert.show("入库类型必填", "提示");
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
	_materialRdsMaster.billDate=billDate.selectedDate;
	_materialRdsMaster.operationNo=operationNo.text;
	_materialRdsMaster.billMonthNo=billMonthNo.text;

	_materialRdsMaster.operationType='109';

	_materialRdsMaster.remark=remark.text;
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
	_materialRdsMaster.verifier=AppInfo.currentUserInfo.personId;
	_materialRdsMaster.verifyDate=new Date();

	if (_materialRdsMaster.currentStatus == "1")
	{
		Alert.show('该其它入库单已经审核', '提示信息');
		return;
	}

	Alert.show('您是否审核当前其它入库单？', '提示信息', Alert.YES | Alert.NO, null, function(e:*):void
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
				_materialRdsMaster.currentStatus='1';
				//表尾赋值
				verifier.text=AppInfo.currentUserInfo.userName;
				verifyDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");
				findRdsById(rev.data[0].autoId);
				Alert.show("其它入库单审核成功！", "提示信息");
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
		return;
	}

	var lRdsDetail:MaterialRdsDetail=gdRdsDetail.selectedItem as MaterialRdsDetail;
	if (!lRdsDetail)
	{
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
	var win:WinReceiveOtherQuery=PopUpManager.createPopUp(this, WinReceiveOtherQuery, true) as WinReceiveOtherQuery;
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

		if (rev.data && rev.data.length > 0 && rev.data[0] != null && rev.data[1] != null)
		{
			_materialRdsMaster=rev.data[0] as MaterialRdsMaster;
			var details:ArrayCollection=rev.data[1] as ArrayCollection;
			storageCode.enabled=false;
			//主记录赋值
			fillMaster(_materialRdsMaster);
			//明细赋值
			gdRdsDetail.dataProvider=details;
			stateButton(rev.data[0].currentStatus);
		}

	});
	ro.findRdsDetailById(fstrAutoId);
}


/**
 * 填充表头部分
 */
private function fillMaster(materialRdsMaster:MaterialRdsMaster):void
{
	if (!materialRdsMaster)
	{
		return;
	}
	redOrBlue.selection = materialRdsMaster.invoiceType == '1'?blueType:redType;
	FormUtils.fillFormByItem(this, materialRdsMaster);
	FormUtils.fillTextByDict(rdType, materialRdsMaster.rdType, 'receviceType');
	FormUtils.fillTextByDict(deptCode, materialRdsMaster.deptCode, 'dept');
	FormUtils.fillTextByDict(personId, materialRdsMaster.personId, 'personId');
	FormUtils.fillTextByDict(maker, materialRdsMaster.maker, 'personId');
	FormUtils.fillTextByDict(verifier, materialRdsMaster.verifier, 'personId');
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
 * 品名规格，用以扩展打印需要的字段
 */
private function nameSpecLBF(item:Object, column:DataGridColumn):String
{
	var nameSpec:String=item.materialName + (item.materialSpec == null ? "" : item.materialSpec);
	item.nameSpec=nameSpec;
	return "";
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
 * 更具数据状态显示不同的按钮
 */
protected function stateButton(currentStatus:String):void
{
	var state:Boolean=(currentStatus == "1" ? false : true);
	toolBar.btModify.enabled=state;
	toolBar.btDelete.enabled=state;
	toolBar.btVerify.enabled=state;
	toolBar.btPrint.enabled=!state;
	toolBar.btExp.enabled=!state;
	toolBar.btAbandon.enabled=(currentStatus == "1" ? true : false);
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