import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.material.stat.medicalReceiveDetailStat.view.WinReceiveStatQuery;
import cn.superion.material.util.DefaultPage;
import cn.superion.material.util.ToolBar;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.base.config.BaseDict;

import mx.collections.ArrayCollection;
import mx.controls.DateField;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;

import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

private const MENU_NO:String="0604";
//服务类
public const DESTINATION:String="receiveStatImpl";

public var dict:Dictionary=new Dictionary();

/**
 * 初始化当前窗口
 * */
protected function doInit():void
{
	if(parentDocument is WinModual){
		parentDocument.title="入库汇总";
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
	var laryEnables:Array=[toolBar.btExit, toolBar.btQuery];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 查找
 * */
protected function queryClickHandler(event:Event):void
{
	var win:WinReceiveStatQuery=WinReceiveStatQuery(PopUpManager.createPopUp(this, WinReceiveStatQuery, true));
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
	//printReport("0");
	makeExport(gdReceive);
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
	addExcelLaster(dataGridName,sheet);
	excelFile.sheets.addItem(sheet);
	var mbytes:ByteArray = excelFile.saveToByteArray();
	var  file:FileReference=new FileReference();
	var _currentDate:String=DateField.dateToString(new Date(),'YYYY-MM-DD');
	var excelTitle:String='入库汇总表'+_currentDate;
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
	var lary:ArrayCollection = dataList.dataProvider as ArrayCollection;
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).amount != null && lary.getItemAt(j).amount != ''){
			initMon5 += lary.getItemAt(j).amount;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).tradeMoney != null && lary.getItemAt(j).tradeMoney != ''){
			initMon6 += lary.getItemAt(j).tradeMoney;
		}
	}
	for each(var col:* in cols){
		if(i==0){
			fsheet.setCell(dataList.dataProvider.length+1,i,"合计");
		}else if(i==7){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon5);
		}else if(i==9){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon6);
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
	var rawArray:ArrayCollection=gdReceive.rawDataProvider as ArrayCollection;
	var lastItem:Object=rawArray.getItemAt(rawArray.length - 1);
	var dataList:ArrayCollection=gdReceive.dataProvider as ArrayCollection;
	preparePrintData(dataList);
	
	
	for (var i:int=0; i < dataList.length; i++)
	{
		var item:Object=dataList.getItemAt(i);
		item["groupName"]=item[gdReceive.groupField];
	}  
	
	dict["主标题"]="入库汇总表";
	
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');

	dict["合计"]="合  计 共 "+ dataList.length + " 项";

	dict["制单人"]=AppInfo.currentUserInfo.userName;
	
	if (printSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/material/stat/receiveStat.xml", dataList, dict);
	}  
	else
	{
		ReportViewer.Instance.Show("report/material/stat/receiveStat.xml", dataList, dict);
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