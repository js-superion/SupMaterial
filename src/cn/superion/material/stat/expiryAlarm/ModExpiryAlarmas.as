import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.material.stat.expiryAlarm.view.WinExpiryAlarmQuery;
import cn.superion.material.util.DefaultPage;
import cn.superion.material.util.ToolBar;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;

import flashx.textLayout.formats.Float;

import mx.collections.ArrayCollection;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;

private const MENU_NO:String="0607";
//服务类
public const DESTINATION:String='availDateImpl';

private var _winY:int=0;
//以下变量用于报表
public var materialClass:String = null;//对应查询框中的物资类别
public var storageName:String = null;//仓库
public var selectedRdoName:String = null;//选中按钮对应的label
public var selectedRdoValue:String = null;//选中按钮对应的值

/**
 * 初始化当前窗口
 * */
protected function doInit():void
{
	if(parentDocument is WinModual){
		parentDocument.title="保质期预警";
	}
	initPanel();
}

/**
 * 初始化面板
 */
private function initPanel():void
{
	initToolBar();
//	initQuery();
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
	var win:WinExpiryAlarmQuery=WinExpiryAlarmQuery(PopUpManager.createPopUp(this, WinExpiryAlarmQuery, true));
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
	printReport("0");
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
		item.madeDate=item.madeDate == null ? "" :item.madeDate;
		item.availDate=item.availDate == null ? "" : item.availDate;
		item.nameSpecFactory = item.materialName + " "+(item.materialSpec == null ? "" : item.materialSpec)+" "+(item.factoryName == null ? "" : item.factoryName.substr(0,6));
	}
}

protected function printReport(printSign:String):void
{
	setPrintPageToDefault();
	var dataList:ArrayCollection=gdExpiryAlarm.dataProvider as ArrayCollection;
	var lastItem:Object=dataList.getItemAt(dataList.length - 1);
	preparePrintData(dataList);
	var dict:Dictionary=new Dictionary();
	
	dict["主标题"]="保质期预警表";
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	
	dict["仓库"] = storageName == null ? "" : storageName;
	
	dict["合计数量"]=lastItem.amount.toFixed(2);
	
	dict["制单人"]=AppInfo.currentUserInfo.userName;
	dict["物资类型"] = materialClass == null ? "" : materialClass;
	dict["selectedRadioName"]= selectedRdoName == null ? "" : selectedRdoName + ":";
	dict["selectedRdoValue"] = selectedRdoValue == null ? "" : selectedRdoValue;
	if (printSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/material/stat/expiryAlarm.xml", dataList, dict);

	}
	else
	{
		ReportViewer.Instance.Show("report/material/stat/expiryAlarm.xml", dataList, dict);

	}
}

private function tradeMoneyLBF(item:Object, column:DataGridColumn):*
{
	if (column.headerText == "进价金额")
	{
		var ite:*=(Number)(item.amount * item.tradePrice).toFixed(2);
		item.tradeMoney=ite;
		return ite;
	}
	return "0";
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

private function qulityDaysLBF(item:Object, column:DataGridColumn):*
{
	if (column.headerText == "保质期(天)")
	{
		if (item.notData)
		{
			return "";
		}
		else
		{
			item.qulityDays=DateUtil.getTimeSpans(item.madeDate, item.availDate);
			return item.qulityDays;
		}
	}

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