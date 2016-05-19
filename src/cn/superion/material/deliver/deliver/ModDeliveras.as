

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
import cn.superion.material.deliver.deliver.view.NumbericEditor;
import cn.superion.material.deliver.deliver.view.WinDeliverApply;
import cn.superion.material.deliver.deliver.view.WinDeliverQuery;
import cn.superion.material.util.DefaultPage;
import cn.superion.material.util.MainToolBar;
import cn.superion.material.util.MaterialCurrentStockShower;
import cn.superion.material.util.MaterialDictShower;
import cn.superion.material.util.ReportParameter;
import cn.superion.report.hlib.UrlLoader;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.center.material.CdMaterialClass;
import cn.superion.vo.material.MaterialRdsDetail;
import cn.superion.vo.material.MaterialRdsMaster;
import cn.superion.vo.system.SysUnitInfor;

import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

import flash.events.KeyboardEvent;
import flash.events.TimerEvent;
import flash.external.ExternalInterface;
import flash.utils.Timer;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.controls.Text;
import mx.core.FlexGlobals;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.events.ListEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;
import mx.utils.StringUtil;

import org.alivepdf.layout.Format;

import spark.events.TextOperationEvent;

registerClassAlias("cn.superion.material.entity.MaterialRdsMaster", cn.superion.vo.material.MaterialRdsMaster);
registerClassAlias("cn.superion.material.entity.MaterialRdsDetail", cn.superion.vo.material.MaterialRdsDetail);

public static const MENU_NO:String="0301";
//服务类
public static const DESTANATION:String="deliverImpl";

public var _materialRdsMaster:MaterialRdsMaster=new MaterialRdsMaster();
public var _materialRdsDetail:MaterialRdsDetail=new MaterialRdsDetail();

//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;
private var reportStyle:String = "";//报表样式、1为泰州的报表、2为四院的样式；
public var applyInvoiveType:String="";//科室领用单据类型，1：蓝字 2：红字

//是否批号管理
[Bindable]
private var _bathSign:Boolean;
private var isRdsBatch:Boolean=false;//入库时是否按批号入库，参数定义
private var _vis:Boolean = false;//修改按钮是否可用 
private var _isPrint:Boolean=false;//打印报表设置
public var _isDetailRemark:Boolean=false;//是否显示备注
private var _isShow:Boolean=false;//显示小数位数，东方3，泰州2

public var isTanchu:Boolean=false;//保存后是否弹出增加界面。

private var _mayGoOnOperateFlag:Boolean = true;//可以继续操作标识 防止连续

/**
 * 初始化当前窗口
 * */
public function doInit():void
{
	if(parentDocument is WinModual){
		parentDocument.title="物资领用出库";
	}
	rdType.width=storageCode.width;
	billNo.width=deptCode.width;
	initPanel();
	barCode.width=operationNo.width;
	isTanchu=ExternalInterface.call("getIsTanchu");
	//是否显示三位小数。
	var rosv:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl', function(rev:Object):void
	{
		if (rev.data && rev.data[0] == '1')
		{
			_isShow=true; 
		//	gdProviderDetail.format = [,,,,,'0.000','0.000','0.000','0.000','0.000','0.000','0.000','0.000','0.000','0.000','0.000','0.000','0.000'];
		//	gdRdsDetail.format = [,,,,,'0.000','0.000','0.000','0.000','0.000','0.000','0.000','0.000','0.000','0.000','0.000','0.000','0.000'];
		}
		else{
			_isShow=false; 
		}
		
	});
	rosv.findSysParamByParaCode("0609");
	
}


/**
 * 面板初始化
 */
private function initPanel():void
{
	initToolBar();
	//增加行项隐藏
	bord.height=70;
	hiddenVGroup.includeInLayout=false;
	hiddenVGroup.visible=false;
	//授权仓库赋值
	if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
	{
//		storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
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
	toolBar.btAbandon.label="弃审";
	var ro:RemoteObject = RemoteUtil.getRemoteObject("unitInforImpl",function(rev:Object):void{
		if(rev.data.length > 0 ){
			for each (var it:SysUnitInfor in rev.data){
				it.label = it.unitsSimpleName;
				it.data = it.unitsCode;
			}
			MaterialDictShower.SYS_UNITS = rev.data;
		}
		
		var ro:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl', function(rev:Object):void
		{
			//若表中未加参数，默认为泰州样式
			if(!rev.data){
				reportStyle = "1";
			}
			else if(rev.data[0] == "2"){ //2为四院样式
				reportStyle = "2";
			}
			
		});
		ro.findSysParamByParaCode("0907");
	});
	ro.findByEndSign("1");
	//打印报表设置
	var rov:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl', function(rev:Object):void
	{
		if(rev.data[0] == '1'){
			_isPrint = true;
		}
	});
	rov.findSysParamByParaCode("0608");
	//是否显示备注
	var rovs:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl', function(rev:Object):void
	{
		if(rev.data && rev.data[0] == '1'){
			_isDetailRemark = true;
		}
	});
	rovs.findSysParamByParaCode("0602");
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1,toolBar.btAbandon, toolBar.btAdd,toolBar.btModify, toolBar.btCancel, toolBar.btSave, toolBar.btVerify, toolBar.imageList2, toolBar.btAddRow, toolBar.btDelRow, toolBar.imageList3, toolBar.btQuery, toolBar.imageList5, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array=[toolBar.btExit, toolBar.btQuery, toolBar.btAdd]
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
	
	var ro:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl', function(rev:Object):void
	{
		//是否显示修改按钮
		if(rev.data && rev.data.length > 0){
//			var laryDisplays:Array=null;
//			var laryEnables:Array=null;
			if(rev.data[0] == '0'){
				_vis = true;
				toolBar.btModify.enabled = false;
			}
			if(rev.data[0] == '1'){
				
			}
		}
		
	});
	ro.findSysParamByParaCode("0607");
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	boolean=!boolean;
	blueType.enabled=boolean;
	redType.enabled=boolean;

	deptCode.enabled=boolean;
	personId.enabled=boolean;
	billDate.enabled=boolean;
	rdType.enabled=boolean;
	operationNo.enabled=boolean;

	billNo.enabled=boolean;
	billMonthNo.enabled=boolean;
	remark.enabled=boolean;
	storageCode.enabled=boolean;
	barCode.enabled=boolean;
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	rdType.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
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
		FormUtils.clearForm(masterGroup);
		blueType.selected=true;
		storageCode.selectedIndex=0;
		billDate.selectedDate=new Date();
		FormUtils.clearForm(hou);
		_materialRdsMaster=new MaterialRdsMaster();
	}
	if (detailFlag)
	{
		gdProviderDetail.dataProvider=null;
		gdRdsDetail.dataProvider=null;
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

protected function barCode_enterHandler(event:KeyboardEvent):void
{
	if(event.keyCode!=13) return;
	
	var _barCode:String=barCode.text;
	if(!_barCode || _barCode.length<10) return;
	
	var timer:Timer=new Timer(1000, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
	{
		var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION,function(rev:Object):void
		{
			if(rev.data && rev.data[0])
			{
				fillIntoGrid(rev.data[0] as MaterialRdsDetail);
				tabMaterial.selectedIndex=1;
				barCode.text='';
				barCode.setFocus();
			}
		});
		if(applyInvoiveType=='1')
		{
			ro.findMaterialDetailByBarCode(barCode.text);
		}
		else
		{
			ro.findMaterialStockByBarCode(barCode.text);
		}
		
		timer.stop();
	})
	timer.start();
	
}

/**
 * 自动完成表格回调
 * */
private function fillIntoGrid(fItem:MaterialRdsDetail):void
{
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	for each(var obj:Object in laryDetails)
	{
		if(obj.barCode==fItem.barCode)
		{
			Alert.show('该条形码在发放明细中已存在','提示');
			gdRdsDetail.selectedIndex=laryDetails.getItemIndex(obj);
			return;
		}
	}
	if(applyInvoiveType=='2')
	{
		fItem.amount=-1 * fItem.amount;
		fItem.wholeSaleMoney=fItem.amount * fItem.wholeSalePrice;
		fItem.retailMoney=fItem.amount * fItem.retailPrice;
	}
	
	laryDetails.addItem(fItem);
	gdRdsDetail.dataProvider=laryDetails;
	gdRdsDetail.selectedIndex=laryDetails.length - 1;
	
}

/**
 * 实发数量
 */
private function factoryCheckAmount(item:Object, column:DataGridColumn):String
{
	if (item.checkAmount == null || item.retailPrice == null)
	{
		if (blueType.selected != true)
		{
			item.checkAmount=Number(item.checkAmount) * -1;
		}
	}
//	else if ((Number(item.checkAmount)) == 0)
//	{
//		if (blueType.selected == true)
//		{
//			item.checkAmount=(Number(item.retailMoney)) / (Number(item.retailPrice))
//		}
//		else
//		{
//			item.checkAmount=((Number(item.retailMoney)) / (Number(item.retailPrice))) * -1
//		}
//	}

	return (item.checkAmount).toFixed(2);
}

/**
 * 售价金额
 */
private function factoryRetailMoney(item:Object, column:DataGridColumn):String
{
	if(item.rowno=='合计')
	{
		if(_isShow){
			return (item.retailMoney).toFixed(3);//byzcl
		}else{
			return (item.retailMoney).toFixed(2);//byzcl
		}
		
	}
	if (item.checkAmount == null || item.retailPrice == null)
	{
		if (blueType.selected != true)
		{
			item.retailMoney=Number(item.retailMoney) * -1;
		}
	}
	else if ((Number(item.checkAmount)) != 0)
	{
		if (blueType.selected == true)
		{
			item.retailMoney=(Number(item.checkAmount)) * (Number(item.retailPrice));
		}
		else
		{
			if(applyInvoiveType=='2' && redType.selected == true)
			{
				item.retailMoney=(Number(item.checkAmount)) * (Number(item.retailPrice));
			}
			else
			{
				item.retailMoney=((Number(item.checkAmount)) * (Number(item.retailPrice))) * -1;
			}
			
		}

	}
	if(_isShow){
		return (item.retailMoney).toFixed(3);//byzcl
	}else{
		return (item.retailMoney).toFixed(2);//byzcl
	}
	
}
/**
 * 售价金额
 */
private function factoryFRetailMoney(item:Object, column:DataGridColumn):String
{
	return (item.retailPrice*item.checkAmount).toFixed(2);
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
			_materialRdsMaster.rdType=rev.rdCode;
		}, x, y);
}

/**
 * 红单蓝单
 */
protected function rdType_clickHandler(event:MouseEvent):void
{
	var aryyList:ArrayCollection=gdProviderDetail.dataProvider as ArrayCollection;
	var minuseFlag:int=-1;
	if (blueType.selected)
	{
		minuseFlag=1;
	}
	for each (var item:Object in aryyList)
	{
		item.retailMoney=minuseFlag * Math.abs((item.retailMoney ? item.retailMoney : 0))
		item.checkAmount=minuseFlag * Math.abs((item.checkAmount ? item.checkAmount : 0));
		trace(item.retailMoney)
	}
	trace(aryyList.getItemAt(0).retailMoney + "------")
	gdProviderDetail.dataProvider=aryyList;
	trace(gdProviderDetail.dataProvider.getItemAt(0).retailMoney + "----0000000-")
}
/**
 * 点击红蓝单
 * */
protected function redOrBlue_changeHandler(event:Event):void
{
	var laryDetails:ArrayCollection=gdProviderDetail.dataProvider as ArrayCollection;
	if(laryDetails.length ==0){
		return	
	}
	Alert.yesLabel = "是";
	Alert.noLabel = "否"
	Alert.show('切换单据类型将清空页面数据','提示',Alert.YES | Alert.NO,null,function(e:*):void{
		if (e.detail == Alert.YES ){
			//清空页面数据
			FormUtils.clearForm(hg1);
			FormUtils.clearForm(hg2);
			gdProviderDetail.dataProvider = [];
		}else{
			redOrBlue.selection = event.target.selection == redType?blueType:redType;
		}
	}) 
}
/**
 * 打印
 */
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
	var excelTitle:String='物资领用出库表'+_currentDate;
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
	var initMon5:Number=0;
	var initMon6:Number=0;
	var initMon7:Number=0;
	var lary:ArrayCollection = dataList.dataProvider as ArrayCollection;
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).amount != null && lary.getItemAt(j).amount != ''){
			initMon5 += lary.getItemAt(j).amount;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).wholeSaleMoney != null && lary.getItemAt(j).wholeSaleMoney != ''){
			initMon6 += lary.getItemAt(j).wholeSaleMoney;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).retailMoney != null && lary.getItemAt(j).retailMoney != ''){
			initMon7 += lary.getItemAt(j).retailMoney;
		}
	}
	
	for each(var col:* in cols){
		if(i==0){
			fsheet.setCell(dataList.dataProvider.length+1,i,"合计");
			fsheet.setCell(dataList.dataProvider.length+2,i,"仓库：");
			fsheet.setCell(dataList.dataProvider.length+3,i,"出库单号:");
			fsheet.setCell(dataList.dataProvider.length+4,i,"出库日期:");
			fsheet.setCell(dataList.dataProvider.length+5,i,"请领部门:");
		}if(i==1){
			fsheet.setCell(dataList.dataProvider.length+2,i,storageCode.selectedItem.storageName);
			fsheet.setCell(dataList.dataProvider.length+3,i,_materialRdsMaster.billNo == null ? "" : _materialRdsMaster.billNo);
			fsheet.setCell(dataList.dataProvider.length+4,i,DateUtil.dateToString(_materialRdsMaster.billDate,'YYYY-MM-DD'));
			fsheet.setCell(dataList.dataProvider.length+5,i,ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', _materialRdsMaster.deptCode) == null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', _materialRdsMaster.deptCode).deptName);
		}else if(i==7){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon5);
		}else if(i==9){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon6);
		}else if(i==11){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon7);
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
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	if(_isPrint){
		setPrintPageSize()
		var dataList:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
		var rawData:ArrayCollection=gdRdsDetail.getRawDataProvider() as ArrayCollection;
		var lastItem:Object=rawData.getItemAt(rawData.length - 1);
		var stCode:String = storageCode.selectedItem?storageCode.selectedItem.storageCode:"";
		if(stCode == '101'){
			preparePrintData(dataList);
		}else{
			preparePrintData1(dataList);
		}
			
		var dict:Dictionary=new Dictionary();
		dict["主标题"]="物资领用出库";
		dict["批发总额"]=lastItem.wholeSaleMoney.toFixed(2);
//		dict["零售总额"]=lastItem.retailMoney.toFixed(2);
		dict["零售总额"]=lastItem.wholeSaleMoney.toFixed(2);
		dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
		dict["仓库"]=storageCode.selectedItem.storageName;
		dict["请领部门"]=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', _materialRdsMaster.deptCode) == null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', _materialRdsMaster.deptCode).deptName;
		dict["出库日期"]=_materialRdsMaster.billDate;
		dict["备注"] = _materialRdsMaster.remark?_materialRdsMaster.remark:"";
		dict["出库单号"]=_materialRdsMaster.billNo == null ? "" : _materialRdsMaster.billNo;
		dict["月单号"]=_materialRdsMaster.billMonthNo;
		var makerv:String=shiftTo(_materialRdsMaster.maker);
		dict["表尾第一行"]=createPrintFirstBottomLine1(verifier.text,personId.text,makerv);
		//dict["审核人"]=verifier.text;
		//dict["接收人"]=personId.text;
		var strXml:String = ""
		if(stCode != '102'){//==101 -> !='102'
			if(reportStyle == "" || reportStyle == '1') {
				strXml = "report/material/deliver/deliverOther.xml";	
			}
			else if(reportStyle == '2')//2：东方医院
			{
				strXml = "report/material/deliver/deliverOther_siyuan_1.xml";
			} 
		}else{
			if(reportStyle == "" || reportStyle == '1') {
				strXml = "report/material/deliver/deliverOther.xml";	
			}
			else if(reportStyle == '2')//2：东方医院 102 医疗器械仓库
			{
				strXml = "report/material/deliver/yl_deliverOther_siyuan_1.xml";
			} 
		}
		loadReportXml(strXml, dataList, dict,printSign)
	}else{
		setPrintPageSize()
		var dataList:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
		var rawData:ArrayCollection=gdRdsDetail.getRawDataProvider() as ArrayCollection;
		var lastItem:Object=rawData.getItemAt(rawData.length - 1);
		preparePrintData(dataList);
		
		var dict:Dictionary=new Dictionary();
		dict["主标题"]="物资领用出库";
		dict["批发总额"]=lastItem.wholeSaleMoney.toFixed(2);
		dict["零售总额"]=lastItem.retailMoney.toFixed(2);
		dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
		dict["仓库"]=storageCode.selectedItem.storageName;
		dict["请领部门"]=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', _materialRdsMaster.deptCode) == null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', _materialRdsMaster.deptCode).deptName;
		dict["出库日期"]=_materialRdsMaster.billDate;
		dict["出库单号"]=_materialRdsMaster.billNo == null ? "" : _materialRdsMaster.billNo;
		dict["表尾第一行"]=createPrintFirstBottomLine(lastItem);
		var strXml:String = ""
		if(reportStyle == "" || reportStyle == '1') {
			strXml = "report/material/deliver/deliverOther.xml";	
		}
		else if(reportStyle == '2')
		{
			strXml = "report/material/deliver/deliverOther_siyuan.xml";
		} 
		loadReportXml(strXml, dataList, dict,printSign)
	}
	
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
		if(ReportParameter.reportPrintHeight_out&&ReportParameter.reportPrintHeight_out!='0'){
			var lreportHeight:String=parseFloat(ReportParameter.reportPrintHeight_out)/10+''
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
 * 计算当前页
 * */
private function preparePrintData(faryData:ArrayCollection):void
{
	var rdBillNo:String=""
	var pageNo:int=0;
	var dataProDateils:ArrayCollection=gdProviderDetail.dataProvider as ArrayCollection;
	for (var i:int=0; i < faryData.length; i++)
	{
		var item:Object=faryData.getItemAt(i);
		if (item.rdBillNo != rdBillNo)
		{
			rdBillNo=item.rdBillNo
			pageNo++;
		}
		for(var j:int=0;j<dataProDateils.length;j++){
			var itemPro:Object = dataProDateils.getItemAt(j);
			
			if(item.materialId == itemPro.materialId){
				item.shamount = itemPro.amount;
				item.materialClass = itemPro.materialClass;
			}
		}
		item.factoryName=!item.factoryName ? '' : item.factoryName
		item.pageNo=pageNo;
		item.materialSpec = item.materialSpec == null ? "" : item.materialSpec
		item.factoryName=item.factoryName.substr(0, 6);
		item.nameSpec=item.materialName + "  " + (item.materialSpec == null ? "" : item.materialSpec);
		item.detailRemark=item.detailRemark?item.detailRemark:"";
		item.registerNo=item.registerNo?item.registerNo:"";
		item.countClass=item.countClass?item.countClass:"";
		
		item.materialClass = ArrayCollUtils.findItemInArrayByValue(BaseDict.materialClassDict, 'materialClass', item.materialClass)?ArrayCollUtils.findItemInArrayByValue(BaseDict.materialClassDict, 'materialClass', item.materialClass).materialClassName:"";
	}
}

private function preparePrintData1(faryData:ArrayCollection):void
{
	var rdBillNo:String=""
	var pageNo:int=0;
	var dataProDateils:ArrayCollection=gdProviderDetail.dataProvider as ArrayCollection;
	for (var i:int=0; i < faryData.length; i++)
	{
		var item:Object=faryData.getItemAt(i);
//		if(item.amount == '0'){
//			faryData.removeItemAt(i);
//			i--;
//			continue;
//		}
		if (item.rdBillNo != rdBillNo)
		{
			rdBillNo=item.rdBillNo
			pageNo++;
		}
		for(var j:int=0;j<dataProDateils.length;j++){
			var itemPro:Object = dataProDateils.getItemAt(j);
			
			if(item.materialId == itemPro.materialId){
				item.shamount = itemPro.amount;
				item.materialClass = itemPro.materialClass;
			}
		}
		item.factoryName=!item.factoryName ? '' : item.factoryName
		item.pageNo=pageNo;
		item.materialSpec = item.materialSpec == null ? "" : item.materialSpec
		item.factoryName=item.factoryName.substr(0, 6);
		item.nameSpec=item.materialName + "  " + (item.materialSpec == null ? "" : item.materialSpec);
		item.detailRemark=item.detailRemark?item.detailRemark:"";
		item.registerNo=item.registerNo?item.registerNo:"";
		item.countClass=item.countClass?item.countClass:"";
		
		item.materialClass = ArrayCollUtils.findItemInArrayByValue(BaseDict.materialClassDict, 'materialClass', item.materialClass)?ArrayCollUtils.findItemInArrayByValue(BaseDict.materialClassDict, 'materialClass', item.materialClass).materialClassName:"";
	}
}

/**
 * 生成表格尾部首行
 * */
private function createPrintFirstBottomLine(fLastItem:Object):String
{
	var lstrLine:String="领用人:{0}        会计:{1}        审核:{2}        制单:{3}"        ;
	var makerv:String=shiftTo(_materialRdsMaster.maker);
	var verifierv:String=shiftTo(_materialRdsMaster.verifier)
	lstrLine=StringUtils.format(lstrLine, "    ","    ","    ", makerv);
	return lstrLine;
}

/**
 * 生成表格尾部首行三个参数，byzcl
 * */
private function createPrintFirstBottomLine1(verifierName:String,personIdName:String,makerv:String):String
{
	var lstrLine:String="审核人:{0}                                      请领人:{1}               接收人:{2}         制单:{3}";
	var makerv:String=shiftTo(_materialRdsMaster.maker);
	var verifierv:String=shiftTo(_materialRdsMaster.verifier)
	lstrLine=StringUtils.format(lstrLine,verifierName,personIdName,"    ",makerv);
	return lstrLine;
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
	rdType.txtContent.text="领用出库";
	_materialRdsMaster.rdFlag='2';
	_materialRdsMaster.rdType='201';
	_materialRdsMaster.operationType='201';
	_materialRdsMaster.currentStatus='0';
	//表尾赋值
	maker.text=AppInfo.currentUserInfo.userName;
	makeDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");
	gdProviderDetail.editable=true;
	//弹出选择的窗口
	var win:WinDeliverApply=PopUpManager.createPopUp(this, WinDeliverApply, true) as WinDeliverApply;
	win.data={win: this};
	FormUtils.centerWin(win);
	storageCode.enabled=true;
}

/**
 * 增行
 * */
protected function addRowClickHandler(event:Event):void
{
	barCode.text='';
//	//显示输入明细区域
//	bord.height=111;
//	hiddenVGroup.includeInLayout=true;
//	hiddenVGroup.visible=true;
//	
//	materialName.text="";
//	materialSpec.text="";
//	materialUnits.text="";
//	
//	amount.text="";
//	
//	batch.text="0";
//	
//	materialCode_queryIconClickHandler(null);
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
	
	//考虑到二级库，二级库定义为四位，截取lstorageCode前2位
	//	lstorageCode = lstorageCode.substr(0,2);
	DictWinShower.showMaterialDictNew(lstorageCode, '', '', true, function(fItem:Array):void
	{
		fillIntoGrid1(fItem);
	}, x, y,"1");
}
/**
 * 药品字典自动完成表格回调
 * */
private function fillIntoGrid1(fItem:Array):void
{
	var laryDetails:ArrayCollection=gdProviderDetail.dataProvider as ArrayCollection;
	//
	
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
		if (fItem[i].amountPerPackage == '' || fItem[i].amountPerPackage == null)
		{
			lnewlDetail.amountPerPackage=1;
		}
		else
		{
			lnewlDetail.amountPerPackage=fItem[i].amountPerPackage;
		}
		lnewlDetail.packageAmount=0;
		
		lnewlDetail.amount=0;
		lnewlDetail.acctAmount=0;
		
		lnewlDetail.tradePrice=fItem[i].tradePrice;
		lnewlDetail.tradeMoney=fItem[i].tradePrice;
		
		lnewlDetail.rebateRate=fItem[i].rebateRate;
		lnewlDetail.rebateRate=isNaN(lnewlDetail.rebateRate) ? 1 : lnewlDetail.rebateRate;
		
		lnewlDetail.factTradePrice=fItem[i].tradePrice * fItem[i].rebateRate;
		lnewlDetail.factTradeMoney=fItem[i].tradePrice * fItem[i].rebateRate;
		
		//是否批号管理
		_bathSign=isRdsBatch && fItem[i].batchSign=='1' ? true : false;
		
		//		//最大批号
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
		batch.text = '0';
		lnewlDetail.batch='0'
		
		lnewlDetail.wholeSalePrice=fItem[i].wholeSalePrice;
		lnewlDetail.wholeSaleMoney=fItem[i].wholeSalePrice;
		
		lnewlDetail.invitePrice=fItem[i].invitePrice;
		lnewlDetail.inviteMoney=fItem[i].invitePrice;
		
		lnewlDetail.retailPrice=fItem[i].retailPrice;
		lnewlDetail.retailMoney=fItem[i].retailPrice;
		
		lnewlDetail.factoryCode=fItem[i].factoryCode;
		lnewlDetail.chargeSign = fItem[i].chargeSign;//收费标示；
		lnewlDetail.classOnAccount = fItem[i].accountClass;//会计分类；
		lnewlDetail.currentStockAmount=fItem[i].amount;
		
		lnewlDetail.outAmount=0;
		lnewlDetail.outSign='0';
		
		lnewlDetail.invoiceAmount=0;
		lnewlDetail.invoiceSign='0';
		
		lnewlDetail.highValueSign=fItem[i].highValueSign;
		lnewlDetail.agentSign=fItem[i].agentSign;
		
		lnewlDetail.checkAmount=0;
		
		laryDetails.addItem(lnewlDetail);
	}
	
	
	gdProviderDetail.dataProvider=laryDetails;
	gdProviderDetail.selectedItem=lnewlDetail;
	
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
private function fillDetailForm(fselDetailItem:MaterialRdsDetail):void
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
	detailRemark.text = fselDetailItem.detailRemark;
	
	amount.text=fselDetailItem.amount + '';
	batch.text=fselDetailItem.batch;
	
	currentStockAmount.text=fselDetailItem.currentStockAmount + '';
}

/**
 * 明细表单赋值 checked by zzj 2011.06.04
 */
public function fillDetailForm1(fselDetailItem:MaterialRdsDetail):void
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
	
	currentStockAmount.text=fselDetailItem.currentStockAmount + '';
}

/**
 * 删行
 * */
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
		Alert.show("请您选择要删除的记录！", "提示");
		return;
	}
	
	Alert.yesLabel = "是";
	Alert.noLabel = "否"
	var lselIndex:int=gdRdsDetail.selectedIndex;
	Alert.show("您是否删除" + lRdsDetail.materialName + "吗？", "提示", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
	{
		if (e.detail == Alert.NO)
		{
			return;
		}
		if (lselIndex < 0)
		{
			storageCode.enabled = true;
			return;
		}
		
		laryDetails.removeItemAt(lintSelIndex);
		if (lintSelIndex == 0)
		{
			lintSelIndex=1;
		}
		gdRdsDetail.selectedIndex=lintSelIndex - 1;
		
		return;
		
	})
}

/**
 * 保存
 */
protected function saveClickHandler(event:Event):void
{
	if(_mayGoOnOperateFlag == true){
		_mayGoOnOperateFlag = false;
	}else{
		return;
	}
	var timer:Timer = new Timer(2000)
	timer.addEventListener(TimerEvent.TIMER,function():void{
		_mayGoOnOperateFlag = true;
		timer.stop();
	});
	timer.start();
	
	//保存权限
	if (!checkUserRole('04'))
	{
		return;
	}
	var laryDetails:ArrayCollection=gdProviderDetail.dataProvider as ArrayCollection;
	if (!laryDetails)
	{
		Alert.show("出库单明细记录不能为空", "提示");
		return;
	}
	if (!validateMaster())
	{ 
		return;
	}
	var larryDeliver:ArrayCollection=new ArrayCollection();
	//处理票面数量,应该放保存时处理
	for each (var item:MaterialRdsDetail in laryDetails){
		item.acctAmount = item.amount;
		item.sourceAutoId=item.autoId;
		if(item.highValueSign=='1')
		{
			var barFlag:Boolean=false;
			for each(var detail:MaterialRdsDetail in gdRdsDetail.dataProvider)
			{
				if(item.materialId==detail.materialId && detail.barCode)
				{
					if(redType.selected)
					{
						detail.acctAmount = detail.amount=-1;
						detail.checkAmount=-1;
					}
					else
					{
						detail.acctAmount = detail.amount=detail.checkAmount=1;
					}
					detail.autoId=item.autoId;
					detail.sourceAutoId=item.autoId;
					detail.mainAutoId=item.mainAutoId;
					detail.retailMoney = detail.checkAmount * detail.retailPrice;
					larryDeliver.addItem(detail);
					barFlag=true;
				}
			}
			if(barFlag==false)
			{
				Alert.show("第"+item.serialNo+"行申请的物资没有填写条形码",'提示');
				tabMaterial.selectedIndex=0;
				gdProviderDetail.setFocus();
				gdProviderDetail.selectedIndex=Number(item.serialNo)-1;
				return;
			}
		}
		else
		{
			larryDeliver.addItem(item);
		}
	}
	//填充主记录
	fillRdsMaster();
	//toolBar.btSave.enabled = false;
	//保存当前数据
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			if (rev && rev.data[0])
			{
				findRdsById1(rev.data[0].autoId);
				bord.height=70;
				hiddenVGroup.visible=false;
				
				if(isTanchu){
					Alert.yesLabel = "调用新申请单";
					Alert.noLabel = "继续操作";
					Alert.show(" 保存成功！","提示信息",Alert.YES|Alert.NO,null,function(e:CloseEvent){
						if(e.detail == Alert.OK){
							addClickHandler(null);
						}
					});
					
				}else{
					Alert.show("保存成功！", "提示信息");
				}
				
				return;
			}
		});
	ro.saveRds(_materialRdsMaster, larryDeliver);
}



/**
 * 翻页调用此函数
 * */
public function findRdsById1(fstrAutoId:String):void
{
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		gdProviderDetail.editable=false;
		
		if (rev.data && rev.data.length > 0 && rev.data[0] != null && rev.data[1] != null)
		{
			ObjectUtils.mergeObject(rev.data[0], _materialRdsMaster)
			var details:ArrayCollection=rev.data[2] as ArrayCollection;
			//主记录赋值
			fillMaster(_materialRdsMaster);
			//明细赋值
			var laryRawData:ArrayCollection=MainToolBar.aryColTransfer(details, MaterialRdsDetail);
//			for each(var item:Object in laryRawData){
//				item.checkAmount = item.amount; //实发数量默认 = 申请数量
//			}
			for each(var item:Object in laryRawData){
				for each(var itemc:Object in rev.data[1]){
					if(item.materialId == itemc.materialId){
						item.detailRemark = itemc.detailRemark;
					}
				}
			}
			gdProviderDetail.dataProvider=laryRawData;
//			if (_materialRdsMaster.currentStatus == '1')
//			{
				gdRdsDetail.dataProvider=rev.data[1];
//			}
			stateButton(_materialRdsMaster.currentStatus);
			storageCode.enabled=false;
			toolBar.btAdd.enabled=true;
			if(_vis){
				toolBar.btModify.enabled = false;
			}
		}
		
	});
	ro.findRdsDetailById(fstrAutoId);
}

/**
 * 保存前验证主记录
 */
private function validateMaster():Boolean
{
	if (deptCode.text == "")
	{
		deptCode.setFocus();
		Alert.show("请领部门为空，您不能进行保存", "提示");
		return false;
	}

	if (rdType.txtContent.text == "")
	{
		rdType.txtContent.setFocus();
		Alert.show("出库类型必填", "提示");
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
	_materialRdsMaster.operationType='201';
	_materialRdsMaster.remark=remark.text;
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
 */
protected function cancelClickHandler(event:Event):void
{
	Alert.yesLabel = "是";
	Alert.noLabel = "否";
	
	Alert.show("您是否放弃当前操作吗？", "提示", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
		{
			if (e.detail == Alert.NO)
			{
				return;
			}

			toolBar.cancelToPreState();
			//清空当前表单
			clearForm(true, true);
			//设置只读
			setReadOnly(true);
			
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

	//应为后台提供
	_materialRdsMaster.verifier=AppInfo.currentUserInfo.personId;
	_materialRdsMaster.verifyDate=new Date();

	if (_materialRdsMaster.currentStatus == "1")
	{
		Alert.show('该领用出库单已经审核', '提示信息');
		return;
	}
	Alert.yesLabel = "是";
	Alert.noLabel = "否"
	Alert.show('您是否审核当前领用出库单？', '提示信息', Alert.YES | Alert.NO, null, function(e:*):void
		{
			if (e.detail == Alert.YES)
			{
				var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
					{
						//设置只读
						setReadOnly(true);
						//表尾赋值
						verifier.text=AppInfo.currentUserInfo.userName;
						verifyDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");
						findRdsById1(_materialRdsMaster.autoId);
						Alert.show("领用出库单审核成功！", "提示信息");
					});
				ro.verifyRds(_materialRdsMaster.autoId);
			}
		})
}

/**
 * 响应表格单击事件
 * 根据物资编码和仓库、查找对应的现存量
 * */
protected function gdProviderDetail_itemClickHandler(event:ListEvent):void
{
	var selectedItem : MaterialRdsDetail = gdProviderDetail.selectedItem as MaterialRdsDetail;
	if(!selectedItem){
		return;
	}
	fillDetailForm(selectedItem);
	var _storageCode:String=storageCode.selectedItem.storageCode;
	var ro:RemoteObject=RemoteUtil.getRemoteObject("commMaterialServiceImpl", function(rev:Object):void
	{
		currentStockAmount.text=rev.data[0].currentStockAmount;
//		gdProviderDetail.selectedItem.currentStockAmount=Number(currentStockAmount.text);
	});
	ro.findCurrentStockByIdStorage(selectedItem.materialId, _storageCode);
	
}
/**
 * 弃审按钮
 */ 
protected function toolBar_abandonClickHandler(event:Event):void
{
	
	Alert.yesLabel = "是";
	Alert.noLabel = "否"
	// TODO Auto-generated method stub
	Alert.show('您是否弃审当前其它出库单？', '提示信息', Alert.YES | Alert.NO, null, function(e:*):void
	{
		if (e.detail == Alert.YES)
		{
			var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
			{
				findRdsById1(_materialRdsMaster.autoId);
				Alert.show("物资领用出库弃审成功！", "提示信息");
			});
			ro.cancelVerifyRds(_materialRdsMaster.autoId);
		}
	})
}
/**
 * 查询
 */
protected function queryClickHandler(event:Event):void
{
	var win:WinDeliverQuery=PopUpManager.createPopUp(this, WinDeliverQuery, true) as WinDeliverQuery;
	win.parentWin=this;
	FormUtils.centerWin(win);
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
	findRdsById1(strAutoId);

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
	findRdsById1(strAutoId);

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
	findRdsById1(strAutoId);

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
	findRdsById1(strAutoId);

	toolBar.lastPageToPreState();
}

/**
 * 翻页调用此函数
 * */
public function findRdsById(fstrAutoId:String):void
{
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			gdProviderDetail.editable=false;

			if (rev.data && rev.data.length > 0 && rev.data[0] != null && rev.data[1] != null)
			{
				ObjectUtils.mergeObject(rev.data[0], _materialRdsMaster)
				var details:ArrayCollection=rev.data[2] as ArrayCollection;
				//主记录赋值
				fillMaster(_materialRdsMaster);
				//明细赋值
				gdProviderDetail.dataProvider=details;
				if (_materialRdsMaster.currentStatus == '1')
				{
					gdRdsDetail.dataProvider=rev.data[1];
				}
				stateButton(_materialRdsMaster.currentStatus);
				storageCode.enabled=false;
			}

		});
	ro.findRdsDetailById(fstrAutoId);
}

/**
 * 填充表头部分
 */
private function fillMaster(materialRdsMaster:MaterialRdsMaster):void
{
	FormUtils.fillFormByItem(this, materialRdsMaster);
	rdType.text=ArrayCollUtils.findItemInArrayByValue(BaseDict.deliverTypeDict, 'deliverType', materialRdsMaster.rdType) == null ? null : ArrayCollUtils.findItemInArrayByValue(BaseDict.deliverTypeDict, 'deliverType', materialRdsMaster.rdType).deliverTypeName;
	redOrBlue.selection = materialRdsMaster.invoiceType == '1'?blueType:redType;
	FormUtils.fillTextByDict(deptCode, materialRdsMaster.deptCode, 'dept');
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
 * 品名规格，用以扩展打印需要的字段
 */
private function nameSpecLBF(item:Object, column:DataGridColumn):String
{
	var nameSpec:String=item.materialName + (item.materialSpec == null ? "" : item.materialSpec);
	item.nameSpec=nameSpec;
	return '';
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
	toolBar.btSave.enabled = false;
	
	//整进整出的领用出库单不能弃审 ryh 2013.01.24
	var _remark:String=_materialRdsMaster.remark;
	var _rdTogether:int=-1;
	if(_remark!=null && _remark!='')
	{
		_rdTogether=_remark.search("整进整出");
	}
	toolBar.btAbandon.enabled=(currentStatus == "1" && _rdTogether<0 ? true : false);
}

/**
 * 数量失去焦点，若是蓝字，则为正，否则为负
 * */
protected function amount_focusOutHandler(event:FocusEvent):void
{
	if(redOrBlue.selection == blueType){
		if(Number(amount.text)  > 0 ){
			return;	
		}
		amount.text = Number(0-Number(amount.text)).toString();
		
	}else{
		if(Number(amount.text)  < 0 ){
			return;	
		}
		if(amount.text == '-'){
			amount.text = '0';
		}
		amount.text = Number(0-Number(amount.text)).toString();
	}
	amount_ChangeHandler(null);
}

/**
 * 数量进行改变事件
 */
private function amount_ChangeHandler(event:Event):void
{
	var lRdsDetail:MaterialRdsDetail=gdProviderDetail.selectedItem as MaterialRdsDetail;
	if (!lRdsDetail)
	{
		return;
	}
	var isCharDuplication:Boolean = false;
	var trimedText:String = mx.utils.StringUtil.trim(amount.text); 
	for(var i:int = 1; i < trimedText.length;i ++){
		if(trimedText.charAt(i) == '-'){
			isCharDuplication = true;
			break;
		}
	}
	if(isCharDuplication){
		amount.text = '-';
		amount.selectRange(1,amount.text.length);;
		return;	
	}
	if(isNaN(Number(trimedText)) || trimedText == '' ){
		lRdsDetail.checkAmount = 0;
	}else{
		lRdsDetail.checkAmount=isNaN(lRdsDetail.amount) ? 1 : lRdsDetail.amount;
		lRdsDetail.checkAmount=parseFloat(amount.text) //* lRdsDetail.amountPerPackage;
	}
	//	lRdsDetail.packageAmount = parseFloat(packageAmount.text);
	lRdsDetail.acctAmount = lRdsDetail.amount;
	//
	lRdsDetail.tradeMoney=lRdsDetail.amount * lRdsDetail.tradePrice;
	lRdsDetail.factTradeMoney=Number((lRdsDetail.amount * lRdsDetail.factTradePrice).toFixed(2));
	
	lRdsDetail.wholeSaleMoney=Number((lRdsDetail.amount * lRdsDetail.wholeSalePrice).toFixed(2));
	lRdsDetail.inviteMoney= Number((lRdsDetail.amount * lRdsDetail.invitePrice).toFixed(2));
	
	lRdsDetail.retailMoney= Number((lRdsDetail.amount * lRdsDetail.retailPrice).toFixed(2));
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
			lRdsDetail.factoryCode=item.factoryCode;
			lRdsDetail.madeDate=item.madeDate;
			lRdsDetail.batch=item.batch;
			lRdsDetail.availDate=item.availDate;
			lRdsDetail.wholeSalePrice=item.wholeSalePrice;
			lRdsDetail.retailPrice=item.retailPrice;
			//			lRdsDetail.wholeSaleMoney=item.wholeSaleMoney;
			//			lRdsDetail.retailMoney=item.retailMoney;
			
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
		lnewlDetail.wholeSaleMoney=Number((lRdsDetail.amount * lRdsDetail.wholeSalePrice).toFixed(2))
		
		lnewlDetail.invitePrice=lRdsDetail.invitePrice;
		lnewlDetail.inviteMoney=0;
		
		lnewlDetail.retailPrice=lRdsDetail.retailPrice;
		lnewlDetail.retailMoney=Number((lRdsDetail.amount * lRdsDetail.retailPrice).toFixed(2));
		
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
 * 修改
 * */
protected function modifyClickHandler(event:Event):void{
	
	gdProviderDetail.editable=true;
	toolBar.btSave.enabled = true;
	if(_isDetailRemark){
		//显示输入明细区域
		bord.height=140;   //byzcl 111
		hiddenVGroup.includeInLayout=true;
		hiddenVGroup.visible=true;
	}
	
//	gdProviderDetail_itemClickHandler(null);
}

/**
 * 明细备注
 * */
protected function detailRemark_changeHandler(event:TextOperationEvent):void
{
	var lRdsDetail:MaterialRdsDetail=gdProviderDetail.selectedItem as MaterialRdsDetail;
	if (!lRdsDetail)
	{
		return;
	}
	
	lRdsDetail.detailRemark=detailRemark.text;
}
