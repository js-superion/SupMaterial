import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.material.stat.stockAccountStat.view.WinStockAccountStatQuery;
import cn.superion.material.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;

import mx.collections.ArrayCollection;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;


private const MENU_NO:String="0603";
//服务类
public const DESTINATION:String="stockAccountImpl";
//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;
public var iObjConditon:ParameterObject=new ParameterObject();


protected function doInit():void
{
	if(parentDocument is WinModual){
		parentDocument.title="库存台帐";
	}
	initPanel();
}

/**
 * 初始化面板
 **/
private function initPanel():void
{
	initToolBar();
}
/**
 * 初始化工具栏
 * */
public function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1, toolBar.btQuery, toolBar.imageList5, toolBar.btFirstPage, toolBar.btLastPage, toolBar.btNextPage, toolBar.btPrePage, toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array=[toolBar.btExit, toolBar.btQuery];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}
/**
 * 查询
 **/
protected function queryClickHandler(event:Event):void
{
	var win:WinStockAccountStatQuery=PopUpManager.createPopUp(this, WinStockAccountStatQuery, true) as WinStockAccountStatQuery;
	win.parentWin=this;
	FormUtils.centerWin(win);
}

/**
 * 根据主记录ID查询主记录和明细记录列表
 **/
public function getDataByAutoId(fId:String):void
{
	var remoteObj:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
		{
			//主界面赋值
			if(rev.data.length<=0)
			{
				return;
			}
			FormUtils.fillFormByItem(allPanel, rev.data[0]);
			var storageItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict, 'storage', rev.data[0].storageCode);
			storageCode.text=storageItem == null ? "" : storageItem.storageName;
			fillRdAmountPrice(rev.data);
			gridStorageAccount.dataProvider=rev.data;
		});
	remoteObj.findMaterialStockAccountListByCondition(fId, iObjConditon);
}

/**
 *	清空所有
 */
public function exitAll():void
{
	FormUtils.clearForm(allPanel);
	iObjConditon=new  ParameterObject();
	gridStorageAccount.dataProvider=null;
}
private function fillRdAmountPrice(faryData:ArrayCollection):void
{
	for each (var item:Object in faryData)
	{
		item.currentStockAmount=Number(item.currentStockAmount).toFixed(2);
		item.tradePrice=Number(item.tradePrice).toFixed(2);
		var lstrPrefix:String="r";
		item["rAmount"]=item["dAmount"]="0.00";
		item["rTradePrice"]=item["dTradePrice"]="0.00";
		item["rTradeMoney"]=item["dTradeMoney"]="0.00";
		if (item.rdFlag != '1')
		{
			lstrPrefix="d"
		}
		item[lstrPrefix + "Amount"]=item.amount == null ? "0.00" : item.amount.toFixed(2);
		item[lstrPrefix + "TradePrice"]=item.tradePrice == null ? "0.00" : item.tradePrice;
		item[lstrPrefix + "TradeMoney"]=item.tradeMoney == null ? "0.00" : item.tradeMoney.toFixed(2);
	}
}

/**
 * 首页
 **/
protected function firstPageClickHandler(event:Event):void
{
	//定位到数组第一个
	if (arrayAutoId.length < 1)
	{
		return;
	}
	currentPage=0;
	var strAutoId:String=arrayAutoId[currentPage] as String;
	getDataByAutoId(strAutoId);

	toolBar.firstPageToPreState();
}

/**
 * 上一页
 **/
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
	getDataByAutoId(strAutoId);

	toolBar.prePageToPreState(currentPage);
}

/**
 * 下一页
 **/
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
	getDataByAutoId(strAutoId);

	toolBar.nextPageToPreState(currentPage, arrayAutoId.length - 1);
}

/**
 * 末页
 **/
protected function lastPageClickHandler(event:Event):void
{
	if (arrayAutoId.length < 1)
	{
		return;
	}
	currentPage=arrayAutoId.length - 1;

	var strAutoId:String=arrayAutoId[currentPage] as String;
	getDataByAutoId(strAutoId);

	toolBar.lastPageToPreState();
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
	printReport("0");
}
/**
 * 拼装打印数据，并计算页码
 * */
private function preparePrintData(faryData:ArrayCollection):void
{
	var materialCode:String=""
	var pageNo:int=0;
	for (var i:int=0; i < faryData.length; i++)
	{
		var item:Object=faryData.getItemAt(i);
		if(item.materialCode!=materialCode){
			materialCode=item.materialCode;
			pageNo++;
		}
		item.pageNo=pageNo;
	}
}

protected function printReport(printSign:String):void
{
	setPrintPageToDefault();
	var dataList:ArrayCollection=gridStorageAccount.dataProvider as ArrayCollection;
	preparePrintData(dataList);
	
	var dict:Dictionary=new Dictionary();
	
	dict["主标题"]="库存台帐表";
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	
	dict["物资分类"]=materialClass.text;
	dict["物资编码"]=materialCode.text;
	dict["物资名称"]=materialName.text;
	dict["规格型号"]=materialSpec.text;
	dict["单位"]=materialUnits.text;
	dict["库存地点"]=storageCode.text;
	
	dict["制单人"]=AppInfo.currentUserInfo.userName;
		
	if (printSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/material/stat/stockAccountStat.xml", dataList, dict);
	}
	else
	{
		ReportViewer.Instance.Show("report/material/stat/stockAccountStat.xml", dataList, dict);
	}
}

private function billDateLBF(item:Object, column:AdvancedDataGridColumn):*
{
	if (column.headerText == "单据日期")
	{
		item.bDate=item.billDate == null ? "" : DateUtil.dateToString(item.billDate, 'YYYY-MM-DD');
		return item.bDate;
	}
}

private function summaryLBF(item:Object, column:AdvancedDataGridColumn):*
{
	if (column.headerText == "摘要")
	{
		var storageCodeItem:*=ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict, 'storage', item.storageCode);
		var receviceTypeItem:*=ArrayCollUtils.findItemInArrayByValue(BaseDict.receviceTypeDict, 'receviceType', item.rdType);
		var deliverTypeItem:*=ArrayCollUtils.findItemInArrayByValue(BaseDict.deliverTypeDict, 'deliverType', item.rdType);
		if (!storageCodeItem && !receviceTypeItem && !deliverTypeItem)
		{
			return "";
		}
		else
		{
			var rdTypeName:Object=receviceTypeItem == null ? deliverTypeItem.deliverTypeName : receviceTypeItem.receviceTypeName;
			item.storageRdName=storageCodeItem.storageName + rdTypeName;
			return item.storageRdName;
		}
	}
}

private function costsLBF(item:Object, column:AdvancedDataGridColumn):*
{
	if (column.dataField == "costs")
	{
		item.costs=Number(item.currentStockAmount * item.tradePrice).toFixed(2);
		return item.costs;
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