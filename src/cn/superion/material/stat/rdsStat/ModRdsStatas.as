import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.material.stat.rdsStat.view.WinRdsStatQuery;
import cn.superion.material.util.DefaultPage;
import cn.superion.material.util.ToolBar;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;

import mx.collections.ArrayCollection;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;

import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

private const MENU_NO:String="0606";
//服务类
public const DESTINATION:String="rdsStatImpl";

public var dict:Dictionary = new Dictionary();

/**
 * 初始化当前窗口
 * */
protected function doInit():void
{
	if(parentDocument is WinModual){
		parentDocument.title="收发存汇总表";
	}
	initPanel();
}

/**
 * 面板初始化
 **/
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
	var laryEnables:Array=[toolBar.btExit, toolBar.btQuery, toolBar.btAdd]
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 查找
 * */
protected function queryClickHandler(event:Event):void
{
	var win:WinRdsStatQuery=WinRdsStatQuery(PopUpManager.createPopUp(this, WinRdsStatQuery, true));
	win.parentWin=this;
	FormUtils.centerWin(win);
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
	//printReport("0");
	makeExport(gdRdsDetailList);
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
	sheet.resize(dataGridName.dataProvider.length+2,cols.length+2);
	addExcelHeader(dataGridName,sheet);
	addExcelData(laryDataList,sheet,dataGridName);
//	addExcelLaster(dataGridName,sheet);
	excelFile.sheets.addItem(sheet);
	var mbytes:ByteArray = excelFile.saveToByteArray();
	var  file:FileReference=new FileReference();
	var _currentDate:String=DateField.dateToString(new Date(),'YYYY-MM-DD');
	var excelTitle:String='收发存汇总表'+_currentDate;
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
	var initMon8:Number=0;
	var initMon9:Number=0;
	var initMon10:Number=0;
	var lary:ArrayCollection = dataList.dataProvider as ArrayCollection;
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).initAmount != null && lary.getItemAt(j).initAmount != ''){
			initMon5 += lary.getItemAt(j).initAmount;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).receiveAmount != null && lary.getItemAt(j).receiveAmount != ''){
			initMon6 += lary.getItemAt(j).receiveAmount;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).otherReceiveAmount != null && lary.getItemAt(j).otherReceiveAmount != ''){
			initMon7 += lary.getItemAt(j).otherReceiveAmount;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).deliveryAmount != null && lary.getItemAt(j).deliveryAmount != ''){
			initMon8 += lary.getItemAt(j).deliveryAmount;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).deliveryOtherAmount != null && lary.getItemAt(j).deliveryOtherAmount != ''){
			initMon9 += lary.getItemAt(j).deliveryOtherAmount;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).currentStockAmount != null && lary.getItemAt(j).currentStockAmount != ''){
			initMon10 += lary.getItemAt(j).currentStockAmount;
		}
	}
	for each(var col:* in cols){
		if(i==0){
			fsheet.setCell(dataList.dataProvider.length+1,i,"合计");
		}else if(i==5){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon5);
		}else if(i==6){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon6);
		}else if(i==7){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon7);
		}else if(i==8){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon8);
		}else if(i==9){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon9);
		}else if(i==11){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon10);
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
		for each(var col:AdvancedDataGridColumn in cols){
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

protected function printReport(printSign:String):void
{
	setPrintPageToDefault();
	var dataList:ArrayCollection= gdRdsDetailList.dataProvider as ArrayCollection;
	dataList = preparePrintData(dataList);
	
	dict["主标题"]="收发存汇总表";
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	
	dict["仓库"]=ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict,'storage',dataList.getItemAt(0).storageCode).storageName;

	dict["制单人"]=AppInfo.currentUserInfo.userName;
	
	if (printSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/material/stat/rdsStat.xml", dataList, dict);
	}
	else
	{
		ReportViewer.Instance.Show("report/material/stat/rdsStat.xml", dataList, dict);
	}
}
/**
 * 拼装打印数据
 * */
private function preparePrintData(faryData:ArrayCollection):ArrayCollection
{
	for (var i:int=0; i < faryData.length; i++)
	{
		var item:Object=faryData.getItemAt(i);
		item.nameSpecFactory = item.materialName + " "+(item.materialSpec == null ? "" : item.materialSpec)+" "+(item.factoryName == null ? "" : item.factoryName.substr(0,6));
	}
	return faryData;
}


private function storageCodeLBF(item:Object, column:AdvancedDataGridColumn):*
{
	if (column.headerText == "仓库")
	{
		var storage:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict,'storage',item.storageCode);
		if(storage)
		{
			item.storageName=storage.storageName;
		}
		else
		{
			item.storageName='';
		}
		return item.storageName
	}
}

private function materialUnitsLBF(item:Object, column:AdvancedDataGridColumn):*
{
	if (column.headerText == "单位")
	{
		item.initAmount=(Number)(item.initAmount).toFixed(2);
		item.receiveAmount=(Number)(item.receiveAmount).toFixed(2);
		item.otherReceiveAmount=(Number)(item.otherReceiveAmount).toFixed(2);
		item.deliveryAmount=(Number)(item.deliveryAmount).toFixed(2);
		item.deliveryOtherAmount=(Number)(item.deliveryOtherAmount).toFixed(2);
		item.currentStockAmount=(Number)(item.currentStockAmount).toFixed(2);
		return item.materialUnits;					
	}
}

private function receiveAllAmountLBF(item:Object, column:AdvancedDataGridColumn):*
{
	if (column.headerText == "入库小计")
	{
		item.receiveAllAmount=(Number(item.receiveAmount) + Number(item.otherReceiveAmount)).toFixed(2);
		return item.receiveAllAmount;
		
	}
}

private function deliveryAllAmountLBF(item:Object, column:AdvancedDataGridColumn):*
{
	if (column.headerText == "出库小计")
	{
		item.deliveryAllAmount=(Number(item.deliveryAmount) + Number(item.deliveryOtherAmount)).toFixed(2);
		return item.deliveryAllAmount;
	}
}

/**
 * 退出
 **/ 
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