import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.material.stat.medicalMonthFee.view.WinDeliverStatQuery;
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

private const MENU_NO:String="0605";
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
		parentDocument.title="医用耗材出库月报表";
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
//	var ros:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
//	{
//		if(rev && rev.data[0] != null){
//			initArray = rev.data[0];
//			gdDeliver.sumField=['sum'];
//			for each(var item:Object in rev.data[0]){
//				var column1:DataGridColumn = new DataGridColumn();
//				column1.headerText = ArrayCollUtils.findItemInArrayByValue(BaseDict.materialClassDict, 'materialClass', item.materialClass)?ArrayCollUtils.findItemInArrayByValue(BaseDict.materialClassDict, 'materialClass', item.materialClass).materialClassName:"";
//				column1.dataField = item.materialClass;
//				column1.width = '120';
//				column1.setStyle('textAlign','left');
//				gdDeliver.columns = gdDeliver.columns.concat(column1);
//				gdDeliver.sumField.push(item.materialClass);
//			}
//		}
//	});
//	ros.findDeliverStatListByDeptMedical(null);//byzcl
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
	sheet.resize(dataGridName.dataProvider.length+4,cols.length);
	addExcelHeader(dataGridName,sheet);
	addExcelData(laryDataList,sheet,dataGridName);
	addExcelLaster(dataGridName,sheet);
	excelFile.sheets.addItem(sheet);
	var mbytes:ByteArray = excelFile.saveToByteArray();
	var  file:FileReference=new FileReference();
	var _currentDate:String=DateField.dateToString(new Date(),'YYYY-MM-DD');
	var excelTitle:String='医用耗材出库月报表'+_currentDate;
	file.save(mbytes,excelTitle+".xls");
}
private function addExcelHeader(dataList:Object,fsheet:Sheet):void{   
	var cols:Array=dataList.columns;	
	var i:int=0;
	for each(var col:* in cols){
		if(i == 0){
			fsheet.setCell(0,i,"序号");
		}
		if(i == 1){
			fsheet.setCell(0,i,"编码");
		}
		if(i == 2){
			fsheet.setCell(0,i,"科室");
		}
		if(i == 3){
			fsheet.setCell(0,i,"总费用");
		}
		if(i == 4){
			fsheet.setCell(0,i,"血费");
		}
		if(i == 5){
			fsheet.setCell(0,i,"气体费");
		}
		if(i == 6){
			fsheet.setCell(0,i,"固定资产");
		}
		if(i == 7){
			fsheet.setCell(2,i,"（单）放射_G");
		}
		if(i == 8){
			fsheet.setCell(2,i,"（单）化验_G");
		}
		if(i == 9){
			fsheet.setCell(1,i,"单独计价");
			fsheet.setCell(2,i,"（单）植入_G");
		}
		if(i == 10){
			fsheet.setCell(2,i,"（单）介入_G");
		}
		if(i == 11){
			fsheet.setCell(0,i,"高值材料");
			fsheet.setCell(2,i,"（单）其他_G");
		}
		if(i == 12){
			fsheet.setCell(2,i,"（非单）放射_G");
		}
		if(i == 13){
			fsheet.setCell(2,i,"（非单）化验_G");
		}
		if(i == 14){
			fsheet.setCell(1,i,"非单独计价");
			fsheet.setCell(2,i,"（非单）植入_G");
		}
		if(i == 15){
			fsheet.setCell(2,i,"（非单）介入_G");
		}
		if(i == 16){
			fsheet.setCell(2,i,"（非单）其他_G");
		}
		if(i == 17){
			fsheet.setCell(2,i,"（单）放射_D");
		}
		if(i == 18){
			fsheet.setCell(2,i,"（单）化验_D");
		}
		if(i == 19){
			fsheet.setCell(1,i,"单独计价");
			fsheet.setCell(2,i,"（单）植入_D");
		}
		if(i == 20){
			fsheet.setCell(2,i,"（单）介入_D");
		}
		if(i == 21){
			fsheet.setCell(2,i,"（单）其他_D");
		}
		if(i == 22){
			fsheet.setCell(0,i,"低值材料");
			fsheet.setCell(2,i,"（非单）放射_D");
		}
		if(i == 23){
			fsheet.setCell(2,i,"（非单）化验_D");
		}
		if(i == 24){
			fsheet.setCell(1,i,"非单独计价");
			fsheet.setCell(2,i,"（非单）植入_D");
		}
		if(i == 25){
			fsheet.setCell(2,i,"（非单）介入_D");
		}
		if(i == 26){
			fsheet.setCell(2,i,"（非单）其他_D");
		}
//		fsheet.setCell(0,i,col.headerText);
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
	var material5:Number=0;
	var material6:Number=0;
	var material7:Number=0;
	var material8:Number=0;
	var material9:Number=0;
	var material10:Number=0;
	var material11:Number=0;
	var material12:Number=0;
	var material13:Number=0;
	var material14:Number=0;
	var material15:Number=0;
	var material16:Number=0;
	var material17:Number=0;
	var material18:Number=0;
	var material19:Number=0;
	var material20:Number=0;
	var material21:Number=0;
	var material22:Number=0;
	var material23:Number=0;
	
	var lary:ArrayCollection = dataList.dataProvider as ArrayCollection;
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).sum != null && lary.getItemAt(j).sum != ''){
			sum += lary.getItemAt(j).sum;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['血费'] != null && lary.getItemAt(j)['血费'] != ''){
			material1 += lary.getItemAt(j)['血费'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['气体费'] != null && lary.getItemAt(j)['气体费'] != ''){
			material2 += lary.getItemAt(j)['气体费'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['固定资产'] != null && lary.getItemAt(j)['固定资产'] != ''){
			material23 += lary.getItemAt(j)['固定资产'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（单）放射_G'] != null && lary.getItemAt(j)['（单）放射_G'] != ''){
			material3 += lary.getItemAt(j)['（单）放射_G'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（单）化验_G'] != null && lary.getItemAt(j)['（单）化验_G'] != ''){
			material4 += lary.getItemAt(j)['（单）化验_G'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（单）植入_G'] != null && lary.getItemAt(j)['（单）植入_G'] != ''){
			material5 += lary.getItemAt(j)['（单）植入_G'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（单）介入_G'] != null && lary.getItemAt(j)['（单）介入_G'] != ''){
			material6 += lary.getItemAt(j)['（单）介入_G'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（单）其他_G'] != null && lary.getItemAt(j)['（单）其他_G'] != ''){
			material7 += lary.getItemAt(j)['（单）其他_G'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（非单）放射_G'] != null && lary.getItemAt(j)['（非单）放射_G'] != ''){
			material8 += lary.getItemAt(j)['（非单）放射_G'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（非单）化验_G'] != null && lary.getItemAt(j)['（非单）化验_G'] != ''){
			material9 += lary.getItemAt(j)['（非单）化验_G'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（非单）植入_G'] != null && lary.getItemAt(j)['（非单）植入_G'] != ''){
			material10 += lary.getItemAt(j)['（非单）植入_G'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（非单）介入_G'] != null && lary.getItemAt(j)['（非单）介入_G'] != ''){
			material11 += lary.getItemAt(j)['（非单）介入_G'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（非单）其他_G'] != null && lary.getItemAt(j)['（非单）其他_G'] != ''){
			material12 += lary.getItemAt(j)['（非单）其他_G'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（单）放射_D'] != null && lary.getItemAt(j)['（单）放射_D'] != ''){
			material13 += lary.getItemAt(j)['（单）放射_D'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（单）化验_D'] != null && lary.getItemAt(j)['（单）化验_D'] != ''){
			material14 += lary.getItemAt(j)['（单）化验_D'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（单）植入_D'] != null && lary.getItemAt(j)['（单）植入_D'] != ''){
			material15 += lary.getItemAt(j)['（单）植入_D'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（单）介入_D'] != null && lary.getItemAt(j)['（单）介入_D'] != ''){
			material16 += lary.getItemAt(j)['（单）介入_D'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（单）其他_D'] != null && lary.getItemAt(j)['（单）其他_D'] != ''){
			material17 += lary.getItemAt(j)['（单）其他_D'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（非单）放射_D'] != null && lary.getItemAt(j)['（非单）放射_D'] != ''){
			material18 += lary.getItemAt(j)['（非单）放射_D'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（非单）化验_D'] != null && lary.getItemAt(j)['（非单）化验_D'] != ''){
			material19 += lary.getItemAt(j)['（非单）化验_D'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（非单）植入_D'] != null && lary.getItemAt(j)['（非单）植入_D'] != ''){
			material20 += lary.getItemAt(j)['（非单）植入_D'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（非单）介入_D'] != null && lary.getItemAt(j)['（非单）介入_D'] != ''){
			material21 += lary.getItemAt(j)['（非单）介入_D'];
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j)['（非单）其他_D'] != null && lary.getItemAt(j)['（非单）其他_D'] != ''){
			material22 += lary.getItemAt(j)['（非单）其他_D'];
		}
	}

	for each(var col:* in cols){
		if(i==0){
			fsheet.setCell(dataList.dataProvider.length+3,i,"合计");
		}else if(i==3){
			fsheet.setCell(dataList.dataProvider.length+3,i,sum);
		}else if(i==4){
			fsheet.setCell(dataList.dataProvider.length+3,i,material1);
		}else if(i==5){
			fsheet.setCell(dataList.dataProvider.length+3,i,material2);
		}else if(i==6){
			fsheet.setCell(dataList.dataProvider.length+3,i,material23);
		}else if(i==7){
			fsheet.setCell(dataList.dataProvider.length+3,i,material3);
		}else if(i==8){
			fsheet.setCell(dataList.dataProvider.length+3,i,material4);
		}else if(i==9){
			fsheet.setCell(dataList.dataProvider.length+3,i,material5);
		}else if(i==10){
			fsheet.setCell(dataList.dataProvider.length+3,i,material6);
		}else if(i==11){
			fsheet.setCell(dataList.dataProvider.length+3,i,material7);
		}else if(i==12){
			fsheet.setCell(dataList.dataProvider.length+3,i,material8);
		}else if(i==13){
			fsheet.setCell(dataList.dataProvider.length+3,i,material9);
		}else if(i==14){
			fsheet.setCell(dataList.dataProvider.length+3,i,material10);
		}else if(i==15){
			fsheet.setCell(dataList.dataProvider.length+3,i,material11);
		}else if(i==16){
			fsheet.setCell(dataList.dataProvider.length+3,i,material12);
		}else if(i==17){
			fsheet.setCell(dataList.dataProvider.length+3,i,material13);
		}else if(i==18){
			fsheet.setCell(dataList.dataProvider.length+3,i,material14);
		}else if(i==19){
			fsheet.setCell(dataList.dataProvider.length+3,i,material15);
		}else if(i==20){
			fsheet.setCell(dataList.dataProvider.length+3,i,material16);
		}else if(i==21){
			fsheet.setCell(dataList.dataProvider.length+3,i,material17);
		}else if(i==22){
			fsheet.setCell(dataList.dataProvider.length+3,i,material18);
		}else if(i==23){
			fsheet.setCell(dataList.dataProvider.length+3,i,material19);
		}else if(i==24){
			fsheet.setCell(dataList.dataProvider.length+3,i,material20);
		}else if(i==25){
			fsheet.setCell(dataList.dataProvider.length+3,i,material21);
		}else if(i==26){
			fsheet.setCell(dataList.dataProvider.length+3,i,material22);
		}
		
		i++;
	}
}
private function addExcelData(laryDataList:ArrayCollection,fsheet:Sheet,gridName:Object):void{
	var lintRow:int=3;
	var cols:Array=gridName.columns;
	for each(var litem:Object in laryDataList){
		var lintColumn:int = 0;
		var index:int =0;
		for each(var col:AdvancedDataGridColumn in cols){
//			fsheet.setCell(lintRow,0,lintRow ||'');
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
		ReportPrinter.LoadAndPrint("report/material/stat/deliverDeptStatMedical.xml", dataList, dict);
	}
	else
	{
		ReportViewer.Instance.Show("report/material/stat/deliverDeptStatMedical.xml", dataList, dict);
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