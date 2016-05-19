// ActionScript file
import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.material.list.deliverList.view.DeliverListQueryCon;
import cn.superion.material.util.DefaultPage;
import cn.superion.material.util.MaterialDictShower;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.system.SysUnitInfor;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

public static var DESTANATION:String='deliverListImpl';
private const MENU_NO:String="0505";
public var disAry:Array=[];
public var enAry:Array=[];
private var _queryWin:DeliverListQueryCon = null;

/**
 * 初始化
 * */
protected function inita(event:FlexEvent):void
{
//	var strTitle:Object=this.parentDocument;
	if(parentDocument is WinModual){
		parentDocument.title="出库单据列表";
	}
//	strTitle.title="出库单据列表";
	//   显示的组件
	disAry=[tbarMain.btPrint, tbarMain.btExp, tbarMain.imageList1, tbarMain.btQuery, tbarMain.imageList5, tbarMain.btExit];
	//  可用的组件
	enAry=[tbarMain.btQuery, tbarMain.btExit];
	//  初始化组件
	MainToolBar.showSpecialBtn(tbarMain, disAry, enAry, true);
	
	dgDeliverBillList.grid.sumLableField="rowno";
	dgDeliverBillList.grid.sumRowLabelText="合计";
	dgDeliverBillList.grid.horizontalScrollPolicy="auto";
	
	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions={};
	dgDeliverBillList.config(paramQuery, DESTANATION, 'findDeliverDetailListByCondition', function(rev:Object):void
	{
		if (rev.data && rev.data.length > 0 )
		{
			enAry=[tbarMain.btPrint, tbarMain.btExp, tbarMain.btQuery, tbarMain.btExit];
			MainToolBar.showSpecialBtn(tbarMain, disAry, enAry, true);
			PopUpManager.removePopUp(_queryWin);
		}
		else
		{
			enAry=[tbarMain.btQuery, tbarMain.btExit];
			MainToolBar.showSpecialBtn(tbarMain, disAry, enAry, true);
			
		}
	}, null, false);
	//加载南北两院单位
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
}

//打印输出
/**
 * @param 参数说明
 * 		  lstrPurview 权限编号;
 * 		  isPrintSign 打印输出标识。直接打印：1，输出：0
 */
protected function printExpClickHandler(lstrPurview:String, isPrintSign:String):void
{
	// TODO Auto-generated method stub
	//判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, lstrPurview))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	setPrintPageToDefault();
	var deliverListPrintItems:ArrayCollection=dgDeliverBillList.grid.dataProvider as ArrayCollection;
	var dict:Dictionary=new Dictionary();
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="出库单据列表";
	dict["制单人"]= AppInfo.currentUserInfo.userName;
	for each( var item:Object in deliverListPrintItems){
		item.nameSpec = item.materialName + " "+(item.packageSpec == null ? "" : item.packageSpec)
			+ " "+(item.factoryName == null ? "" : item.factoryName);
		item.availDate = item.availDate == null ? "" : item.availDate;
		item.deptName = item.deptName ==null ? "" : item.deptName;
	}
	if (isPrintSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/material/list/deliverList.xml", deliverListPrintItems, dict);
	}
	else
	{
		ReportViewer.Instance.Show("report/material/list/deliverList.xml", deliverListPrintItems, dict);
	}
}

/**
 * 查找
 * */
protected function queryClickHandler(event:Event):void
{
	var win:DeliverListQueryCon=DeliverListQueryCon(PopUpManager.createPopUp(this, DeliverListQueryCon, true));
	win.data={parentWin: this};
	_queryWin = win;
	PopUpManager.centerPopUp(win);
	
}

/**
 * 退出
 * */
protected function exitClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
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
			return " ";
		}
		else
		{
			item.agentSignName='否';
			return '否';
		}					
	}
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
}
/**
 * 恢复默认打印机的打印页面
 * */
private function setPrintPageToDefault():void{
	ExternalInterface.call("setPrintPageToDefault")
}