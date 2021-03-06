import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.material.stat.zwDeliverStat.view.WinDeliverStatQuery;
import cn.superion.material.util.DefaultPage;
import cn.superion.material.util.MaterialDictShower;
import cn.superion.material.util.ToolBar;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.system.SysUnitInfor;

import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

import mx.collections.ArrayCollection;
import mx.controls.DateField;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

private const MENU_NO:String="0620";
//服务类
public const DESTINATION:String="deliverStatImpl";


public var dict:Dictionary=new Dictionary();
public var startStrDate:String=null;
public var endStrDate:String=null;
public var initArray:ArrayCollection = null;

/**
 * 初始化窗口
 * */
protected function doInit():void
{
	if(parentDocument is WinModual){
		parentDocument.title="总务仓库汇总表";
	}
	initPanel();
	var ro:RemoteObject = RemoteUtil.getRemoteObject("unitInforImpl",function(rev:Object):void{
		if(rev.data.length > 0 ){
			for each (var it:SysUnitInfor in rev.data){
				it.label = it.unitsSimpleName;
				it.data = it.unitsCode;
			}
			MaterialDictShower.SYS_UNITS = rev.data;
		}
	});
	ro.findByEndSign("1");
	//实现动态添加列。
	var ros:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
	{
		if(rev && rev.data[0] != null){
			initArray = rev.data[0];
			gdDeliver.sumField=['sum'];
			for each(var item:Object in rev.data[0]){
				var column1:DataGridColumn = new DataGridColumn();
				column1.headerText = ArrayCollUtils.findItemInArrayByValue(BaseDict.materialClassDict, 'materialClass', item.materialClass)?ArrayCollUtils.findItemInArrayByValue(BaseDict.materialClassDict, 'materialClass', item.materialClass).materialClassName:"";
				column1.dataField = item.materialClass;
				column1.width = '120';
				column1.setStyle('textAlign','left');
				gdDeliver.columns = gdDeliver.columns.concat(column1);
				gdDeliver.sumField.push(item.materialClass);
			}
		}
	});
	ros.findClassByZw(null);//byzcl
}

/**
 * 面板初始化
 */
private function initPanel():void
{
	initToolBar();
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1, toolBar.btQuery, toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array=[toolBar.btPrint, toolBar.btExp,toolBar.btExit, toolBar.btQuery];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}
/**
 * 查找
 * */
protected function queryClickHandler(event:Event):void
{
	var win:WinDeliverStatQuery=WinDeliverStatQuery(PopUpManager.createPopUp(this, WinDeliverStatQuery, true));
	win.parentWin=this; 
	FormUtils.centerWin(win);
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
	makeExport(gdDeliver);
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
	sheet.resize(dataGridName.dataProvider.length+2,cols.length);
	addExcelHeader(dataGridName,sheet);
	addExcelData(laryDataList,sheet,dataGridName);
	addExcelLaster(dataGridName,sheet);
	excelFile.sheets.addItem(sheet);
	var mbytes:ByteArray = excelFile.saveToByteArray();
	var  file:FileReference=new FileReference();
	var _currentDate:String=DateField.dateToString(new Date(),'YYYY-MM-DD');
	var excelTitle:String='出库部门汇总（总务）计表'+_currentDate;
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
	var sum:Number=0;
	var material1:Number=0;
	var material2:Number=0;
	var material3:Number=0;
	var material4:Number=0;
//	var initMon10:Number=0;
//	var initMon11:Number=0;
//	var initMon12:Number=0;
	var lary:ArrayCollection = dataList.dataProvider as ArrayCollection;
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).sum != null && lary.getItemAt(j).sum != ''){
			sum += lary.getItemAt(j).sum;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).material1 != null && lary.getItemAt(j).material1 != ''){
			material1 += lary.getItemAt(j).material1;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).material2 != null && lary.getItemAt(j).material2 != ''){
			material2 += lary.getItemAt(j).material2;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).material3 != null && lary.getItemAt(j).material3 != ''){
			material3 += lary.getItemAt(j).material3;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).material4 != null && lary.getItemAt(j).material4 != ''){
			material4 += lary.getItemAt(j).material4;
		}
	}
//	for(var j:int=0;j<lary.length;j++){
//		if(lary.getItemAt(j).retailMoney != null && lary.getItemAt(j).retailMoney != ''){
//			initMon10 += lary.getItemAt(j).retailMoney;
//		}
//	}
//	for(var j:int=0;j<lary.length;j++){
//		if(lary.getItemAt(j).currentStockAmount != null && lary.getItemAt(j).currentStockAmount != ''){
//			initMon11 += lary.getItemAt(j).currentStockAmount;
//		}
//	}
//	for(var j:int=0;j<lary.length;j++){
//		if(lary.getItemAt(j).currentStockMoney != null && lary.getItemAt(j).currentStockMoney != ''){
//			initMon12 += lary.getItemAt(j).currentStockMoney;
//		}
//	}
	for each(var col:* in cols){
		if(i==0){
			fsheet.setCell(dataList.dataProvider.length+1,i,"合计");
		}else if(i==3){
			fsheet.setCell(dataList.dataProvider.length+1,i,sum);
		}else if(i==4){
			fsheet.setCell(dataList.dataProvider.length+1,i,material1);
		}else if(i==5){
			fsheet.setCell(dataList.dataProvider.length+1,i,material2);
		}else if(i==6){
			fsheet.setCell(dataList.dataProvider.length+1,i,material3);
		}else if(i==7){
			fsheet.setCell(dataList.dataProvider.length+1,i,material4);
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
 * 拼装打印数据
 * */
private function preparePrintData(faryData:ArrayCollection):void
{
	for (var i:int=0; i < faryData.length; i++)
	{
		var item:Object=faryData.getItemAt(i);
		item.nameSpec = item.materialName + " "+(item.materialSpec == null ? "" : item.materialSpec);
		item.salerName=item.salerName == null ? "" : item.salerName.substr(0,6);
		
	}
}

protected function printReport(printSign:String):void
{
	setPrintPageToDefault();
//	var rawArray:ArrayCollection=gdDeliver.rawDataProvider as ArrayCollection;
//	var lastItem:Object=rawArray.getItemAt(rawArray.length - 1);
	var dataList:ArrayCollection=gdDeliver.dataProvider as ArrayCollection;
//	preparePrintData(dataList);
	
//	for (var i:int=0; i < dataList.length; i++)
//	{
//		var item:Object=dataList.getItemAt(i);
//		item["groupName"]=item[gdDeliver.groupField];
//	}  
	
	dict["主标题"]="出库汇总表";
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["统计日期"]=startStrDate+"--"+endStrDate;
		
	dict["合计"]="合  计 共 "+ dataList.length + " 项";
	
	dict["制单人"]=AppInfo.currentUserInfo.userName;
	
	if (printSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/material/stat/deliverDeptStatComputer.xml", dataList, dict);
	}
	else
	{
		ReportViewer.Instance.Show("report/material/stat/deliverDeptStatComputer.xml", dataList, dict);
	}
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
 * 恢复默认打印机的打印页面
 * */
private function setPrintPageToDefault():void{
	ExternalInterface.call("setPrintPageToDefault")
}

/**
 * LabFunction，针对表格扩充的字段进行处理
 * */
private function labFun(item:Object,column:DataGridColumn):String{
	 if(column.headerText=="所属单位"){ //零售 - 批发
		 var ss:String = "";
		//根据页面获得的单位列表，循环处理；
		 for each (var unitInfo:Object in MaterialDictShower.SYS_UNITS){
			 if(unitInfo.unitsCode == item.deptUnitsCode){
				 ss = item.unitsSimpleName = unitInfo.unitsSimpleName;
				 break;
			 }
		 }
		 return ss;
	 }
	 else{
		 return "";
	 } 
}