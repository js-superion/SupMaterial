// ActionScript file
import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.material.list.purchaseList.view.PurchaseListQueryCon;
import cn.superion.material.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;
public static const DESTANATION:String='applyListImpl';
private const MENU_NO:String="0501";
//	private  var _condition:Object={};
//工具栏中要显示组件数组
public var iaryDisplays:Array=[];
//工具栏中使能组件数组
private var _aryEnableds:Array=[];
public var salerName:String = "";

/**
 * 初始化
 * */
protected function doInit():void
{
	initToolBar(); 
	initPanel();
	
}
/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
//	parentDocument.title="采购请购列表";
	if(parentDocument is WinModual){
		parentDocument.title="采购请购列表";
	}
	//  显示组件：打印，输出，查询，退出	
	iaryDisplays=[tbarMain.btExit, tbarMain.btQuery, tbarMain.btPrint, tbarMain.btExp, tbarMain.imageList1, tbarMain.imageList6];
	//  可用组件：查询，退出
	_aryEnableds=[tbarMain.btExit, tbarMain.btQuery];
	//  组件初始化
	MainToolBar.showSpecialBtn(tbarMain, iaryDisplays, _aryEnableds, true);
}
/**
 * 初始化面板
 * */
private function initPanel():void
{
	//初始化不可编辑,增加项隐藏
	dgDrug.grid.sumLableField="rowno";
	dgDrug.grid.sumRowLabelText="合计";
	dgDrug.grid.horizontalScrollPolicy="auto";
	var _condition:Object={};
	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions=_condition;
	dgDrug.config(paramQuery, DESTANATION, 'findPlanDetailListByCondition', function(rev:Object):void
	{
		if (rev.data && rev.data.length)
		{
			_aryEnableds=[tbarMain.btExit, tbarMain.btQuery, tbarMain.btPrint, tbarMain.btExp];
			MainToolBar.showSpecialBtn(tbarMain, iaryDisplays, _aryEnableds, true);					
		}
		else
		{
			Alert.show("没有查询到相关数据!");
			_aryEnableds=[tbarMain.btExit, tbarMain.btQuery];
			MainToolBar.showSpecialBtn(tbarMain, iaryDisplays, _aryEnableds, true);					
		}
	}, null, false);
}

/**
 * 查找
 * */
protected function queryClickHandler(event:Event):void
{
	
	var win:PurchaseListQueryCon=PurchaseListQueryCon(PopUpManager.createPopUp(this, PurchaseListQueryCon, true));
	win.data={parentWin: this};
	win.iparentWin = this;
	PopUpManager.centerPopUp(win);
	
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

private function labelFun(item:Object, column:DataGridColumn):*
{
	if (column.headerText == "建议供应商")
	{
		var factoryCodeItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict, 'provider', item.salerCode);
		
		if (!factoryCodeItem)
		{
			return '';
		}
		else
		{
			item.salerName=factoryCodeItem.providerName;
			return factoryCodeItem.providerName;
		}
	}
}

/**
 * @param 参数说明
 * 		  lstrPurview 权限编号;
 * 		  isPrintSign 打印输出标识。直接打印：1，输出：0
 */
protected function btToolBar_printExpClickHandler(lstrPurview:String, isPrintSign:String):void
{
	//  判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, lstrPurview))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	
	var purchaseListPrintItems:ArrayCollection=dgDrug.grid.dataProvider as ArrayCollection;
	var dict:Dictionary=new Dictionary();
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="采购请购列表";
	dict["制单人"]= AppInfo.currentUserInfo.userName;
	dict["建议供应商"]=salerName == null ? "":salerName;
	for each( var item:Object in purchaseListPrintItems){
		item.nameSpec = item.materialName + " "+(item.packageSpec == null ? "" : item.packageSpec);
	}
	if (isPrintSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/material/list/purchaseList.xml", purchaseListPrintItems, dict);
		
	}
	else
	{
		ReportViewer.Instance.Show("report/material/list/purchaseList.xml", purchaseListPrintItems, dict);
	}
}