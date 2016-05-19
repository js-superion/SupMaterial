// ActionScript file
import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.material.list.rejectList.view.RejectListQueryCon;
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
private const MENU_NO:String="0507";
private var destination:String="rejectListImpl";
private var _queryWin:RejectListQueryCon=null;

//初始化
protected function doInit(event:FlexEvent):void
{
	if(parentDocument is WinModual){
		parentDocument.title="报损单据列表";
	}
	//初始按钮组
	disAry=[btToolBar.btPrint, btToolBar.btExp, btToolBar.imageList1, btToolBar.btQuery, btToolBar.imageList5, btToolBar.btExit];
	enAry=[btToolBar.btQuery, btToolBar.btExit];
	MainToolBar.showSpecialBtn(btToolBar, disAry, enAry, true);
	gdRejectList.grid.sumLableField="rowno";
	gdRejectList.grid.sumRowLabelText="合计";
	gdRejectList.grid.horizontalScrollPolicy="auto";
	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions={};
	gdRejectList.config(paramQuery, destination, 'findRejectDetailListByCondition', function(rev:Object):void
		{
			if (rev.data && rev.data.length > 0)
			{
				enAry=[btToolBar.btPrint, btToolBar.btExp, btToolBar.btQuery, btToolBar.btExit];
				MainToolBar.showSpecialBtn(btToolBar, disAry, enAry, true);
				PopUpManager.removePopUp(_queryWin);
			}
			else
			{
				enAry=[btToolBar.btQuery, btToolBar.btExit];
				MainToolBar.showSpecialBtn(btToolBar, disAry, enAry, true);

			}
		}, null, false);
}

//打印
protected function printClickHandler(event:Event):void
{
	printReport("1");

}

//输出
protected function expClickHandler(event:Event):void
{
	printReport("0");

}

/**
 * @param 参数说明
 * 		  lstrPurview 权限编号;
 * 		  isPrintSign 打印输出标识。直接打印：1，输出：0
 */
protected function printReport(printSign:String):void
{
	setPrintPageToDefault();
	var rejectListPrintItems:ArrayCollection=gdRejectList.grid.dataProvider as ArrayCollection;
	var dict:Dictionary=new Dictionary();
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="报损单据列表";
	dict["制单人"]=AppInfo.currentUserInfo.userName;
	for each (var item:Object in rejectListPrintItems)
	{
		item.nameSpec=item.materialName + " " + (item.materialSpec == null ? "" : item.materialSpec) + " " + (item.factoryName == null ? "" : item.factoryName);
		item.availDate=item.availDate == null ? "" : item.availDate;
		item.batch=item.batch==null?"":item.batch;
	}
	if (printSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/material/list/rejectList.xml", rejectListPrintItems, dict);
		return;
	}
	else
	{
		ReportViewer.Instance.Show("report/material/list/rejectList.xml", rejectListPrintItems, dict);
	}
}



//查找
protected function btToolBar_queryClickHandler(event:Event):void
{
	var win:RejectListQueryCon=PopUpManager.createPopUp(this, RejectListQueryCon, true) as RejectListQueryCon;
	win.iparentWin=this;
	_queryWin=win;
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

//部门名称
private function labelFun(item:Object, column:DataGridColumn):*
{

	if (column.headerText == '部门')
	{
		var deptCodeItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', item.outDeptCode);
		if (!deptCodeItem)
		{
			return '';
		}
		else
		{
			item.deptName=deptCodeItem.deptName;
			return deptCodeItem.deptName;
		}
	}

}
/**
 * 恢复默认打印机的打印页面
 * */
private function setPrintPageToDefault():void{
	ExternalInterface.call("setPrintPageToDefault")
}