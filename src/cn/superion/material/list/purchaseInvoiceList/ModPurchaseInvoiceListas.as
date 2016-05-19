// ActionScript file
import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.PurviewUtil;
import cn.superion.material.list.purchaseInvoiceList.view.PurchaseInvoiceListQueryCon;
import cn.superion.material.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;

public var disAry:Array=[];
public var enAry:Array=[];
private const MENU_NO:String="0503";
private var destination:String="invoiceListImpl";
public var salerName:String = "";
//初始化
protected function doInit(event:FlexEvent):void
{
//	var strTitle:Object=this.parentDocument;
//	strTitle.title="采购发票列表";
	if(parentDocument is WinModual){
		parentDocument.title="采购发票列表";
	}
	//初始按钮组
	disAry=[btToolBar.btPrint, btToolBar.btExp, btToolBar.imageList1, btToolBar.btQuery, btToolBar.imageList5, btToolBar.btExit];
	enAry=[btToolBar.btQuery, btToolBar.btExit];
	MainToolBar.showSpecialBtn(btToolBar, disAry, enAry, true);
	gdPurchaseInvoiceList.grid.sumLableField="rowno";
	gdPurchaseInvoiceList.grid.sumRowLabelText="合计";
	gdPurchaseInvoiceList.grid.horizontalScrollPolicy="auto";
	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions={};
	gdPurchaseInvoiceList.config(paramQuery, destination, 'findInvoiceDetailListByCondition', function(rev:Object):void
	{
		if (rev.data && rev.data.length)
		{
			enAry=[btToolBar.btPrint, btToolBar.btExp, btToolBar.btQuery, btToolBar.btExit];
			MainToolBar.showSpecialBtn(btToolBar, disAry, enAry, true);
		}
		else
		{
			Alert.show("没有查询到相关数据!");
			enAry=[ btToolBar.btQuery, btToolBar.btExit];
			MainToolBar.showSpecialBtn(btToolBar, disAry, enAry, true);
			
		}
		
	}, null, false);
	//				gdPurchaseInvoiceList.grid.dataProvider=[{'amount': '100', 'tradePrice': '2.36'}, {'amount': '100', 'tradePrice': '2.36'}];
}

/**
 * @param 参数说明
 * 		  lstrPurview 权限编号;
 * 		  isPrintSign 打印输出标识。直接打印：1，输出：0
 */
protected function btToolBar_printExpClickHandler(lstrPurview:String, isPrintSign:String):void
{
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, lstrPurview))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	var invoiceListPrintItems:ArrayCollection=gdPurchaseInvoiceList.grid.dataProvider as ArrayCollection;
	var dict:Dictionary=new Dictionary();
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="采购发票列表";
	dict["制单人"]= AppInfo.currentUserInfo.userName;
	dict["供应单位"]=salerName == null ? "":salerName;
	for each( var item:Object in invoiceListPrintItems){
		item.nameSpec = item.materialName + " "+(item.packageSpec == null ? "" : item.packageSpec)
			+ " "+(item.factoryName == null ? "" : item.factoryName);
		item.detailRemark = item.detailRemark == null ? "" : item.detailRemark;
	}
	if (isPrintSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/material/list/purchaseInvoiceList.xml", invoiceListPrintItems, dict);
	}
	else
	{
		ReportViewer.Instance.Show("report/material/list/purchaseInvoiceList.xml", invoiceListPrintItems, dict);
	}
}

//查找
protected function btToolBar_queryClickHandler(event:Event):void
{
	var win:PurchaseInvoiceListQueryCon=PurchaseInvoiceListQueryCon(PopUpManager.createPopUp(this, PurchaseInvoiceListQueryCon, true));
	win.data={parentWin: this};
	win.iparentWin = this;
	PopUpManager.centerPopUp(win);
}



//退出
protected function btToolBar_exitClickHandler(event:Event):void
{
	if (this.parentDocument is WinModual)
	{
		PopUpManager.removePopUp(this.parentDocument as IFlexDisplayObject);
		return;
	}
	DefaultPage.gotoDefaultPage();
}