// ActionScript file
import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.PurviewUtil;
import cn.superion.material.list.purchaseOrderList.view.PurchaseOrderListQueryCon;
import cn.superion.material.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.Button;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.core.UIComponent;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;

import spark.components.SkinnableContainer;
//		[Bindable]
//		private var autoSelectedDrug:VCdDrugDict;
//		private var copyObj:Object;
private var destination:String='orderListImpl';

//		[Bindable]
//		private var txtItems:Array;
private const MENU_NO:String="0502";
public var disAry:Array=[];
public var enAry:Array=[];
public var salerName:String = "";

/**
 * 初始化
 * */
protected function inita(event:FlexEvent):void
{
//	var strTitle:Object=this.parentDocument;
//	strTitle.title="采购订单列表";
	if(parentDocument is WinModual){
		parentDocument.title="采购订单列表";
	}
	// 显示按钮
	disAry=[tbarMain.btPrint, tbarMain.btExp, tbarMain.imageList1, tbarMain.btQuery, tbarMain.imageList5, tbarMain.btExit];
	// 可用按钮
	enAry=[tbarMain.btQuery, tbarMain.btExit];
	// 初始化组件
	showSpecialBtn(tbarMain, disAry, enAry, true);
	
	//隐藏明细查询组件
	//				packageAmount.editable = false;
	//			ary.addEventListener(CollectionEvent.COLLECTION_CHANGE, dgOrderList_dataChangeHandler);
	dgOrderList.grid.sumLableField="rowno";
	dgOrderList.grid.sumRowLabelText="合计";
	dgOrderList.grid.horizontalScrollPolicy="auto";
	
	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions={};
	dgOrderList.config(paramQuery, destination, 'findOrderDetailListByCondition', function(rev:Object):void
	{
		if (rev.data && rev.data.length)
		{
			enAry=[tbarMain.btPrint, tbarMain.btExp, tbarMain.btQuery, tbarMain.btExit];
			MainToolBar.showSpecialBtn(tbarMain, disAry, enAry, true);
			
		}
		else
		{
			Alert.show("没有查询到相关数据!");
			enAry=[tbarMain.btQuery, tbarMain.btExit];
			MainToolBar.showSpecialBtn(tbarMain, disAry, enAry, true);
			
		}
	}, null, false);
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
	var orderListPrintItems:ArrayCollection=dgOrderList.grid.dataProvider as ArrayCollection;
	var dict:Dictionary=new Dictionary();
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="采购订单列表";
	dict["制单人"]= AppInfo.currentUserInfo.userName;
	dict["供应单位"]=salerName == null ? "":salerName;
	for each( var item:Object in orderListPrintItems){
		item.nameSpec = item.materialName + " "+(item.packageSpec == null ? "" : item.packageSpec)
			+ " "+(item.factoryName == null ? "" : item.factoryName);
		item.remark = item.remark == null ? "":item.remark;
	}
	if (isPrintSign == '1')
	{
		ReportPrinter.LoadAndPrint("report/material/list/purchaseOrderList.xml", orderListPrintItems, dict);
	}
	else
	{
		ReportViewer.Instance.Show("report/material/list/purchaseOrderList.xml", orderListPrintItems, dict);
	}
}

/**
 * 查找
 * */
protected function queryClickHandler(event:Event):void
{
	var win:PurchaseOrderListQueryCon=PurchaseOrderListQueryCon(PopUpManager.createPopUp(this, PurchaseOrderListQueryCon, true));
	win.data={parentWin: this};
	PopUpManager.centerPopUp(win);
	win.iparentWin = this;
	enAry=[tbarMain.btPrint,tbarMain.btExp,tbarMain.btQuery, tbarMain.btExit];
	showSpecialBtn(tbarMain, disAry, enAry, true);
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

/**
 * 设置组件是否可用
 * rootId:指定的父组件id；b:true，为可用
 * */
private function setToolKitEnable(rootId:UIComponent, b:Boolean):void
{
	var childs:Number=rootId.numChildren;
	for (var i:int=0; i < childs; i++)
	{
		var disObj:UIComponent=rootId.getChildAt(i) as UIComponent;
		disObj.enabled=b;
	}
}

//			protected function dgOrderList_dataChangeHandler(event:CollectionEvent):void
//			{
//				if (ary.length == 0)
//					tbarMain.btDelRow.enabled=false;
//				else
//					tbarMain.btDelRow.enabled=true;
//				dgOrderList.grid.invalidateList();
//			}



protected function toNextItem(e:KeyboardEvent, txtPhoFive:UIComponent):void
{
	if (e.keyCode != 13)
		return;
	txtPhoFive.setFocus();
}


// 查询结果
public function btQuery_clickHandler():void
{
	MainToolBar.showSpecialBtn(tbarMain, disAry, [tbarMain.btPrint,tbarMain.btExp,tbarMain.btQuery,tbarMain.btExit], true);
}