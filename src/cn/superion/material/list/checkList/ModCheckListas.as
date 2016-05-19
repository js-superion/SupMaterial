import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.material.list.checkList.view.CheckListQueryCon;
import cn.superion.material.other.check.view.CheckQueryCon;
import cn.superion.material.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.Button;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.core.UIComponent;
import mx.managers.PopUpManager;

import spark.components.SkinnableContainer;

private var destination:String='checkListImpl';
private const MENU_NO:String="0508";
private var _queryWin:CheckListQueryCon = null;

//初始化
protected function doInit():void
{
//	var strTitle:Object=this.parentDocument;
//	strTitle.title="盘点单据列表";
	if(parentDocument is WinModual){
		parentDocument.title="盘点单据列表";
	}
	//初始按钮组
	showSpecialBtn(tbarMain, [tbarMain.btExit, tbarMain.btQuery, tbarMain.btPrint, tbarMain.btExp, tbarMain.imageList1, tbarMain.imageList6], [tbarMain.btExit, tbarMain.btQuery], true);
	dgDrug.grid.sumLableField="rowno";
	dgDrug.grid.sumRowLabelText="合计";
	dgDrug.grid.horizontalScrollPolicy="auto";
	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions={};
	dgDrug.config(paramQuery, destination, 'findCheckDetailListByCondition', function(rev:Object):void
	{
		if (rev.data && rev.data.length > 0)
		{
			showSpecialBtn(tbarMain, [tbarMain.btExit, tbarMain.btQuery, tbarMain.btPrint, tbarMain.btExp, tbarMain.imageList1, tbarMain.imageList6], [tbarMain.btPrint, tbarMain.btExp, tbarMain.btQuery, tbarMain.btExit], true);
			PopUpManager.removePopUp(_queryWin);
		}
		else
		{
			showSpecialBtn(tbarMain, [tbarMain.btExit, tbarMain.btQuery, tbarMain.btPrint, tbarMain.btExp, tbarMain.imageList1, tbarMain.imageList6], [tbarMain.btQuery, tbarMain.btExit], true);
		}
	}, null, false);
}

private function rhSignLabel(item:Object, column:DataGridColumn):String
{
	if (column.headerText == "账面金额")
	{
		var ite:*=(Number)(item.amount * item.retailPrice).toFixed(2);
		item.counterMoney=ite;
		return ite;
		
	}
	if (column.headerText == "盘点金额")
	{
		var pdItem:*=(Number)(item.retailPrice * item.checkAmount).toFixed(2);
		item.pdMoney=pdItem;
		return pdItem;
	}
	if (column.headerText == "盈亏数量")
	{
		var amount:*=(Number)(item.amount - item.checkAmount).toFixed(2);
		item.profitAmount=amount;
		return amount;
		
	}
	if (column.headerText == "盈亏金额")
	{
		var cost:*=(Number)(item.retailPrice * (item.amount - item.checkAmount)).toFixed(2);
		item.profitCost=cost;
		return cost;
	}
	return "0";
}

/**
 *查询按钮处理方法
 **/
protected function queryClickHandler(event:Event):void
{
	
	var queryWin:CheckListQueryCon=PopUpManager.createPopUp(this, CheckListQueryCon, true) as CheckListQueryCon;
	queryWin.iparentWin=this;
	_queryWin = queryWin;
	PopUpManager.centerPopUp(queryWin);
}

/**
 *退出按钮处理方法
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
 * 指定按钮的状态
 * toolbar：父容器的id；
 * displayedBtns:要显示的组件
 * enabledBtns：初始状态为可用的组件；
 * status:状态参数，”true“：表示组件可用；”false“表示不可用
 *
 * */
protected function showSpecialBtn(toolbar:SkinnableContainer, displayedBtns:Array, enabledBtns:Array, status:Boolean):void
{
	if (!toolbar is SkinnableContainer)
		return;
	var childs:int=toolbar.numElements;
	if (childs == 0)
		return;
	if (displayedBtns != null && displayedBtns.length > 0)
	{
		for (var c:int=0; c < childs; c++)
		{
			var its:UIComponent=toolbar.getElementAt(c) as UIComponent;
			if (!its is Button)
				continue;
			its.includeInLayout=false;
			its.visible=false;
		}
		for (var k:int=0; k < displayedBtns.length; k++)
		{
			displayedBtns[k].includeInLayout=true;
			displayedBtns[k].visible=true;
		}
	}
	for (var i:int=0; i < childs; i++)
	{
		var it:UIComponent=toolbar.getElementAt(i) as UIComponent;
		if (!it is Button)
			continue;
		//所有置灰
		it.enabled=!status;
		for (var j:int=0; j < enabledBtns.length; j++)
		{
			if (it.id == enabledBtns[j].id)
			{
				it.enabled=status;
				break;
			}
		}
	}
}

//设置组件是否可用    rootId:指定的父组件id；b:true，为可用
private function setToolKitEnable(rootId:UIComponent, b:Boolean):void
{
	var childs:Number=rootId.numChildren;
	for (var i:int=0; i < childs; i++)
	{
		var disObj:UIComponent=rootId.getChildAt(i) as UIComponent;
		disObj.enabled=b;
	}
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
 * lstrPurview 权限编号;
 * isPrintSign 打印输出标识。直接打印：1，输出：0
 */
protected function printReport(printSign:String):void
{
	setPrintPageToDefault();
	var checkListPrintItems:ArrayCollection=dgDrug.grid.dataProvider as ArrayCollection;
	var dict:Dictionary=new Dictionary();
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="盘点单据列表";
	dict["制表人"]=AppInfo.currentUserInfo.userName;
	for each( var item:Object in checkListPrintItems){
		item.nameSpec = item.materialName + " "+(item.materialSpec == null ? "" : item.materialSpec)
			+ " "+(item.factoryName == null ? "" : item.factoryName);
		item.availDate=item.availDate==null?"":item.availDate;
	}
	
		if (printSign == '1')
		{
			ReportPrinter.LoadAndPrint("report/material/list/checkList.xml", checkListPrintItems, dict);

		}
		else
		{
			ReportViewer.Instance.Show("report/material/list/checkList.xml", checkListPrintItems, dict);

		}
}
/**
 * 恢复默认打印机的打印页面
 * */
private function setPrintPageToDefault():void{
	ExternalInterface.call("setPrintPageToDefault")
}