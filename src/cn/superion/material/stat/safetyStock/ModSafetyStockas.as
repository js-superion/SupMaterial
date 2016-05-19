import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.material.stat.safetyStock.view.WinSafetyStockQuery;
import cn.superion.material.util.DefaultPage;
import cn.superion.material.util.ToolBar;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;

import mx.collections.ArrayCollection;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;

private const MENU_NO:String="0608";
//服务类
public const DESTINATION:String="safeStockImpl";
//出库
public var depot:String="";
private var _winY:int=0;


/**
 * 初始化当前窗口
 * */
protected function doInit():void
{
	if(parentDocument is WinModual){
		parentDocument.title="安全库存预警";
	}
	_winY=this.parentApplication.screen.height - 345;
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
	var win:WinSafetyStockQuery=WinSafetyStockQuery(PopUpManager.createPopUp(this, WinSafetyStockQuery, true));
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
		item.nameSpecFactory = item.materialName + " "+(item.materialSpec == null ? "" : item.materialSpec)+" "+(item.factoryName == null ? "" : item.factoryName.substr(0,6));
	}
}
protected function printReport(printSign:String):void
{
	setPrintPageToDefault();
	var dataList:ArrayCollection=gdSafetyStock.dataProvider as ArrayCollection;
	var lastItem:Object=dataList.getItemAt(dataList.length - 1);
	preparePrintData(dataList);
	var dict:Dictionary=new Dictionary();
	
	dict["主标题"]="安全库存预警";
	
	dict["单位"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["仓库"]=depot; 
	dict["制单人"]=AppInfo.currentUserInfo.userName;
	
	if (printSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/material/stat/safetyStock.xml", dataList, dict);
	}
	else
	{
		ReportViewer.Instance.Show("report/material/stat/safetyStock.xml", dataList, dict);
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