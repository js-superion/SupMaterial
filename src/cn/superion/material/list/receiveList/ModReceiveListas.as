// ActionScript file
import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.PurviewUtil;
import cn.superion.material.list.receiveList.view.ReceiveListQueryCon;
import cn.superion.material.util.*;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;

private var copyObj:Object;
private var destination:String='receiveListImpl';
private const MENU_NO:String="0504";

[Bindable]
private var txtItems:Array;
private var disBt:Array;
private var enBt:Array;
private var _queryWin:ReceiveListQueryCon = null;
/**
 * 初始化
 * */
protected function doInit(event:FlexEvent):void
{
	if(parentDocument is WinModual){
		parentDocument.title="入库单据列表";
	}
	//初始按钮组
	disBt=[tbarMain.btPrint, tbarMain.btExp, tbarMain.btQuery, tbarMain.btExit];
	enBt=[tbarMain.btQuery, tbarMain.btExit];
	MainToolBar.showSpecialBtn(tbarMain, disBt, enBt, true);
	dgReceiveList.grid.sumLableField="rowno";
	dgReceiveList.grid.sumRowLabelText="合计";
	dgReceiveList.grid.horizontalScrollPolicy="auto";
	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions={};
	dgReceiveList.config(paramQuery, destination, 'findReceiveDetailListByCondition', function(rev:Object):void
	{
		if (rev.data && rev.data.length)
		{
			enBt=[tbarMain.btPrint, tbarMain.btExp, tbarMain.btQuery, tbarMain.btExit];
			MainToolBar.showSpecialBtn(tbarMain,disBt, enBt, true);
			PopUpManager.removePopUp(_queryWin);
		}
		else
		{
			enBt=[tbarMain.btQuery, tbarMain.btExit];
			MainToolBar.showSpecialBtn(tbarMain,disBt, enBt, true);
			
		}
	}, null, false);
}

/**
 * @param 参数说明
 * 		  lstrPurview 权限编号;
 * 		  isPrintSign 打印输出标识。直接打印：1，输出：0
 */
protected function btToolBar_printExpClickHandler(lstrPurview:String, isPrintSign:String):void
{
	// TODO Auto-generated method stub
	//  判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, lstrPurview))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}			
	setPrintPageToDefault();
	var receiveListPrintItems:ArrayCollection=dgReceiveList.grid.dataProvider as ArrayCollection;
	//				for each (var it :Object in receiveListPrintItems){		
	//					it.agentSign == "1" ? "是" : "否";
	//				}
	//	var condition:String = "";
	var dict:Dictionary=new Dictionary();
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="入库单据列表";
	dict["制单人"]= AppInfo.currentUserInfo.userName;
	for each( var item:Object in receiveListPrintItems){
		item.nameSpec = item.materialName + " "+(item.packageSpec == null ? "" : item.packageSpec)
			+ " "+(item.factoryName == null ? "" : item.factoryName);
		item.availDate = item.availDate == null ? "" : item.availDate;
		item.deptName = item.deptName ==null ? "" : item.deptName;
	}
	if (isPrintSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/material/list/reveiveList.xml", receiveListPrintItems, dict);
		
	}
	else
	{
		ReportViewer.Instance.Show("report/material/list/reveiveList.xml", receiveListPrintItems, dict);
		
	}
}

/**
 * 查找
 * */
protected function queryClickHandler(event:Event):void
{
	var win:ReceiveListQueryCon=PopUpManager.createPopUp(this, ReceiveListQueryCon, true) as ReceiveListQueryCon;
	win.data={parentWin: this};
	_queryWin = win;
	PopUpManager.centerPopUp(win);
}

/**
 *退出
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

private function labFun(item:Object, column:DataGridColumn):*
{	
	if(column.headerText=="是否代销")
	{
		if (item.agentSign=='1')
		{
			item.agentSignName='是';
			return '是';
		}
		else if(item.agentSign==null||item.agentSign=="")
		{
			item.agentSignName = "";
			return " ";
		}
		else
		{
			item.agentSignName='否';
			return '否';
		}					
	}				
}

/**
 * 恢复默认打印机的打印页面
 * */
private function setPrintPageToDefault():void{
	ExternalInterface.call("setPrintPageToDefault")
}