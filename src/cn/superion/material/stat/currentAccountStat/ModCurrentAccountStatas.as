import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.material.stat.currentAccountStat.view.WinCurrentAccountStatQuery;
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

private const MENU_NO:String="0602";
//服务类
public const DESTINATION:String="currentAccountStatImpl";

public var dict:Dictionary=new Dictionary();

/**
 * 初始化当前窗口
 * */
protected function doInit():void
{
	if(parentDocument is WinModual){
		parentDocument.title="流水账查询";
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
	makeExport(gridCurrentAccount);
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
	var excelTitle:String='流水帐查询表'+_currentDate;
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
	var lary:ArrayCollection = dataList.dataProvider as ArrayCollection;
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).impAmount != null && lary.getItemAt(j).impAmount != ''){
			initMon5 += lary.getItemAt(j).impAmount;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).impMoney != null && lary.getItemAt(j).impMoney != ''){
			initMon6 += lary.getItemAt(j).impMoney;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).expAmount != null && lary.getItemAt(j).expAmount != ''){
			initMon7 += lary.getItemAt(j).expAmount;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).expMoney != null && lary.getItemAt(j).expMoney != ''){
			initMon8 += lary.getItemAt(j).expMoney;
		}
	}
	for each(var col:* in cols){
		if(i==0){
			fsheet.setCell(dataList.dataProvider.length+1,i,"合计");
		}else if(i==7){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon5);
		}else if(i==8){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon6);
		}else if(i==9){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon7);
		}else if(i==10){
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
 * 拼装打印数据
 * */
private function preparePrintData(faryData:ArrayCollection):void
{
	for (var i:int=0; i < faryData.length; i++)
	{
		var item:Object=faryData.getItemAt(i);

		item.nameSpecFactory = item.materialName + " "+(item.materialSpec == null ? "" : item.materialSpec)+" "+(item.factoryName == null ? "" : item.factoryName.substr(0,6));
	}
}

protected function printReport(printSign:String):void
{
	setPrintPageToDefault();
	var dataList:ArrayCollection=gridCurrentAccount.dataProvider as ArrayCollection;

	preparePrintData(dataList);

	dict["主标题"]="流水账表";
	dict["单位"]=AppInfo.currentUserInfo.unitsName;
	
	dict["仓库"]=ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict,'storage',dataList.getItemAt(0).storageCode).storageName;
	
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	
	dict["制单人"]=AppInfo.currentUserInfo.userName;
	
	if (printSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/material/stat/currentAccountStat.xml", dataList, dict);
	}
	else
	{
		ReportViewer.Instance.Show("report/material/stat/currentAccountStat.xml", dataList, dict);
	}
}

/**
 * 查询
 */
protected function queryClickHandler(event:Event):void
{
	var win:WinCurrentAccountStatQuery=PopUpManager.createPopUp(this, WinCurrentAccountStatQuery, true) as WinCurrentAccountStatQuery;
	win.parentWin=this;
	FormUtils.centerWin(win);
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
 * 恢复默认打印机的打印页面
 * */
private function setPrintPageToDefault():void{
	ExternalInterface.call("setPrintPageToDefault")
}