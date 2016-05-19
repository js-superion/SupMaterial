import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.StringUtils;
import cn.superion.material.stat.currentStockStat.view.WinCurrentStockStatQuery;
import cn.superion.material.util.DefaultPage;
import cn.superion.material.util.ToolBar;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;

import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;

private const MENU_NO:String="0601";
//服务类
public const DESTINATION:String="currentStockStatImpl";
public var dict:Dictionary=new Dictionary();

protected function doInit():void
{
	if(parentDocument is WinModual){
		parentDocument.title="现存量查询";
	}
	initPanel();
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
	var laryEnables:Array=[toolBar.btExit, toolBar.btQuery];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 打印
 **/ 
protected function printClickHandler(event:Event):void
{
	printReport("1");	
}

/**
 * 输出
 **/ 
protected function expClickHandler(event:Event):void
{
//	printReport("0");	
	expExcel();//ryh 13.2.25
}

private function expExcel():void
{
	var details:ArrayCollection=gridCurrentStock.dataProvider as ArrayCollection;
	var cols:Array=gridCurrentStock.columns;
	var excelFile:ExcelFile = new ExcelFile();
	var sheet:Sheet = new Sheet();
	if(details.length==0){
		Alert.show('没有库存数据不可以导出','提示');
		return; 
	}
	
	sheet.resize(gridCurrentStock.dataProvider.length+details.length+1,cols.length)
	addExcelHeader(gridCurrentStock,sheet);
	addExcelData(details,sheet);
	addExcelLaster(details,sheet);
	excelFile.sheets.addItem(sheet);
	var mbytes:ByteArray = excelFile.saveToByteArray();
	var  file:FileReference=new FileReference()
	var currentDate:String=DateUtil.dateToString(new Date,'YYYY-MM-DD');
	var excelTitle:String='现存量查询表' + currentDate;
	
	file.save(mbytes,excelTitle+".xls");
}

private function addExcelHeader(gridList:Object,fsheet:Sheet):void{
	var cols:Array=gridCurrentStock.columns
	var i:int=0; 
	for (var col:int=0;col<cols.length;col++){
		fsheet.setCell(0,i,cols[col].headerText);
		i++;
	} 
}

private function addExcelLaster(dataList:Object,fsheet:Sheet):void{   
	var cols:Array=gridCurrentStock.columns;	
	var i:int=0;
	var initMon5:Number=0;
	var initMon6:Number=0;
	var initMon7:Number=0;
	var lary:ArrayCollection = gridCurrentStock.dataProvider as ArrayCollection;
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
			fsheet.setCell(gridCurrentStock.dataProvider.length+1,i,"合计");
		}else if(i==6){
			fsheet.setCell(gridCurrentStock.dataProvider.length+1,i,initMon5);
		}else if(i==8){
			fsheet.setCell(gridCurrentStock.dataProvider.length+1,i,initMon6);
		}else if(i==10){
			fsheet.setCell(gridCurrentStock.dataProvider.length+1,i,initMon7);
		}
		i++;
	}
}

private function addExcelData(laryGroupData:ArrayCollection,fsheet:Sheet):void{
	var lintRow:int=1;
	var cols:Array=gridCurrentStock.columns
	for each(var lgroup:Object in laryGroupData)
	{
		for(var i:int=0;i<cols.length;i++)
		{
			if(i==0)
			{
				fsheet.setCell(lintRow,i,lintRow);
			}
			else if ((cols[i].dataField == 'barCode' || cols[i].dataField == 'materialCode') && lgroup[cols[i].dataField].length>6)
			{
				fsheet.setCell(lintRow,i,'_'+lgroup[cols[i].dataField] || '');
			}
			else if(cols[i].dataField == 'availDate' && lgroup[cols[i].dataField])
			{
				fsheet.setCell(lintRow,i,DateUtil.dateToString(lgroup[cols[i].dataField],'YYYY-MM-DD') || '');
			}
			else
			{
				fsheet.setCell(lintRow,i,lgroup[cols[i].dataField] || '');
			}
			
		}
		lintRow++;
	}
}


protected function printReport(printSign:String):void
{
	setPrintPageToDefault();
	var dataList:ArrayCollection=gridCurrentStock.dataProvider as ArrayCollection;
	var max:Number=0;
	var min:Number=0;
	preparePrintData(dataList);
	
	dict["主标题"]="现存量表";
	dict["单位"]=AppInfo.currentUserInfo.unitsName;
	
	dict["仓库"]=ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict,'storage',dataList.getItemAt(0).storageCode).storageName;
	
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	
	dict["制单人"]=AppInfo.currentUserInfo.userName;
	
	if (printSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/material/stat/currentStockStat.xml", dataList, dict);
	}
	else
	{   
		ReportViewer.Instance.Show("report/material/stat/currentStockStat.xml", dataList, dict);
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
		item.tradePrice=!item.tradePrice ? '' :item.tradePrice;
		if(item.amount==0 || item.tradePrice==0)
		{
			item.tradePrice=0.00;
		}
		else
		{		
			item.tradeMoney=Number(item.amount *　item.tradePrice).toFixed(2);
		}
		item.nameSpecFactory = item.materialName + " "+(item.materialSpec == null ? "" : item.materialSpec)+" "+(item.factoryName == null ? "" : item.factoryName.substr(0,6));
	}
}
/**
 * 查询
 **/ 
protected function queryClickHandler(event:Event):void
{
	var win:WinCurrentStockStatQuery=PopUpManager.createPopUp(this, WinCurrentStockStatQuery, true) as WinCurrentStockStatQuery;
	win.parentWin=this;
	FormUtils.centerWin(win);	
}
  
private function wholeSaleMoneyLBF(item:Object, column:DataGridColumn):String
{
	if (column.headerText == "批发金额")
	{
		var money:*=(Number)(item.amount * item.wholeSalePrice).toFixed(2);
		item.wholeSaleMoney=money;
		return money;
		
	}
	return "0.00";
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