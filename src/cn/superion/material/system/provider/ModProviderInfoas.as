// ActionScript file
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictDataProvider;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.system.provider.view.ProviderInfoAdd;
import cn.superion.material.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.center.provider.CdProvider;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.controls.LinkButton;
import mx.events.CloseEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

private var _classCode:String = "";
public static var destination:String = "commProviderImpl";
public static var MENU_NO:String="0704";
private const PARA_CODE:String="0203";
public var isAuthorizationProvider:Boolean = false; //是否供应商授权
private function inita():void
{
	var o:Object=AppInfo.currentUserInfo.deptList;
	o=AppInfo.currentUserInfo.wardList;
	if (AppInfo.currentUserInfo.deptList != null && AppInfo.currentUserInfo.deptList.length > 0)
	{
		chargeDept.dataProvider=AppInfo.currentUserInfo.deptList;
		chargeDept.selectedIndex=0;
	}
	providerGrid.horizontalScrollPolicy="auto";
	initSysPara();
	this.parentApplication.mainWin.menuPanel.width = 0 ;
	//加载 科室
	var ro:RemoteObject = RemoteUtil.getRemoteObject('centerStorageImpl',function(rev1:Object):void{
		if(rev1.data){
			var newAry:ArrayCollection = new ArrayCollection();
			for each(var it:Object in rev1.data){
				var o:Object = new Object();
				o.deptCode = it[0];
				o.deptName = it[1];
//				o.deptCode = it.storageCode;
//				o.deptName = it.storageName;
				newAry.addItem(o);
			}
			chargeDept.dataProvider = newAry;
		}
	});
	ro.findStorageByProperty("3");
	
}
/**
 * 供应商是否授权商品
 * */
private function initSysPara():void{
	//查找系统参数，
	var ro:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl',function(rev:Object):void
	{
		if(rev.data[0] =='1'){
			isAuthorizationProvider = true;
		}
		if(rev.data[0] =='0'){
			isAuthorizationProvider = false;
		}
	});
	ro.findSysParamByParaCode(PARA_CODE);
}
/**
 * 冻结
 * */
protected function freeze_clickHandler(event:MouseEvent):void
{

}
protected function btUnFreeze_clickHandler(event:MouseEvent):void
{
}
protected function btQuery_clickHandler(event:MouseEvent):void
{
	var inpCode:String=txtQuery.text;
	var chargeDepts:String=null;
	if (chargeDept.selectedItem)
	{
		chargeDepts=chargeDept.selectedItem.deptCode;
	}
	var param:ParameterObject=new ParameterObject();
	if (fiveInputCode.selected==true)
	{
		param.conditions={chargeDept: chargeDepts, fiveInputCode: inpCode, phoInputCode: ""};
	}
	else
	{
		param.conditions={chargeDept: chargeDepts, fiveInputCode: "", phoInputCode: inpCode};
	}
	
	var rome:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
	{
		if (rev.data && rev.data.length > 0)
		{
			providerGrid.dataProvider=rev.data;
			providerGrid.invalidateList();
		}
		else
		{
			providerGrid.dataProvider=null;
		}
	});
	rome.findProviderDictListByInputCode(param);
	
	
//	var inpCode:String=phoCode.text;
//	var param:ParameterObject=new ParameterObject();
//	if (AppInfo.currentUserInfo.inputCode == "PHO_INPUT")
//	{
//		param.conditions={phoInputCode: inpCode};
//	}
//	else
//	{
//		param.conditions={fiveInputCode: inpCode};
//	}	
//	var ro:RemoteObject = RemoteUtil.getRemoteObject(destination,function(o:Object):void{
//		if(!o||o.data.length==0) return;
//		providerGrid.dataProvider = o.data;
//	});
//	ro.findProviderDictListByInputCode(param);
}

public function queryHandler(fstrProviderClass:String):void
{
	var ro:RemoteObject=RemoteUtil.getRemoteObject(destination,function(rev:Object):void
	{
		if(rev.data && rev.data.length>0)
		{
			providerGrid.dataProvider=rev.data;
			return;
		}
		providerGrid.dataProvider=[];
	})
	ro.findProviderByProvideClass(fstrProviderClass);
}

//按钮是否可用
private function setBtnEnable(fArray:Array,eSign:Boolean):void
{
	for each(var item:LinkButton in fArray)
	{
		item.enabled=eSign;
	}
}

/**
 * 新增
 * */
private function addHandler():void
{
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, "01"))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	var proInfoWin:ProviderInfoAdd=PopUpManager.createPopUp(this,ProviderInfoAdd,true) as ProviderInfoAdd;
//	var proInfo:CdProvider=new CdProvider()
//	proInfo.providerClass=leftTree.itemClassTree.selectedItem.classCode;
	proInfoWin.data={parentWin:this,proInfo:new CdProvider(),type:'add'};
	proInfoWin.gCode=leftTree.itemClassTree.selectedItem?leftTree.itemClassTree.selectedItem.classCode:null;
	FormUtils.centerWin(proInfoWin);
	proInfoWin.gName=leftTree.itemClassTree.selectedItem?leftTree.itemClassTree.selectedItem.className:null;
}

//修改
private function changeHandler():void
{
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, "02"))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	
	var selItem:CdProvider=providerGrid.selectedItem as CdProvider;
	if(!selItem)
	{ 
		Alert.show('请选择要修改的记录','提示');
		return;
	}
	
	var treeNode:*=leftTree.itemClassTree.selectedItem;
	if(treeNode)
	{
		//如果是根节点
		if(treeNode.classCode=='00')
		{
			treeNode=null;
		}	
	}
	var proInfoWin:ProviderInfoAdd=PopUpManager.createPopUp(this,ProviderInfoAdd,true) as ProviderInfoAdd;
	proInfoWin.data={parentWin:this,proInfo:selItem,type:'update',proClassItem:treeNode};
	preNextHandler(proInfoWin);
	PopUpManager.centerPopUp(proInfoWin);  
}

public function preNextHandler(proInfoWin:ProviderInfoAdd):void
{
	var seleIndex:Number=providerGrid.selectedIndex;
	//没有数据
	if(providerGrid.dataProvider.length==0)
	{
		setBtnEnable([proInfoWin.btAdd],false);
		setBtnEnable([proInfoWin.btFirst,proInfoWin.btPrevious,proInfoWin.btNext,proInfoWin.btLast],false);
	}
	//选择第一条 && 最后一条  ==只有一条
	if(providerGrid.dataProvider.length==1)
	{
		setBtnEnable([proInfoWin.btFirst,proInfoWin.btPrevious,
			proInfoWin.btNext,proInfoWin.btLast],false);
		setBtnEnable([proInfoWin.btAdd],true);
		return;	
	}
	//选择第一条
	if(seleIndex==0)
	{
		setBtnEnable([proInfoWin.btFirst,proInfoWin.btPrevious],false);
		setBtnEnable([proInfoWin.btAdd,proInfoWin.btNext,proInfoWin.btLast],true);
		return;	
	}
	//选择最后一条
	if(seleIndex==providerGrid.dataProvider.length-1)
	{
		setBtnEnable([proInfoWin.btNext,proInfoWin.btLast],false);
		setBtnEnable([proInfoWin.btAdd,proInfoWin.btFirst,proInfoWin.btPrevious],true);
		return;
	}
	//其他
	setBtnEnable([proInfoWin.btAdd],false);
	setBtnEnable([proInfoWin.btFirst,proInfoWin.btPrevious,proInfoWin.btNext,proInfoWin.btLast],true);
}

//删除
private function deleteHandler():void
{
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, "03"))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	var selItem:*=providerGrid.selectedItem;
	if(!selItem)
	{
		Alert.show('请选择要删除的记录','提示');
		return;
	}
	var _dp:ArrayCollection=providerGrid.dataProvider as ArrayCollection;
	
	Alert.show('您是否要删除：'+selItem.providerName+'供应商信息？','提示',Alert.YES|Alert.NO,null,function(e:CloseEvent):void
	{
		if(e.detail == Alert.YES)
		{
			//删除操作
			var ro:RemoteObject=RemoteUtil.getRemoteObject(destination,function(rev:Object):void
			{
					_dp.removeItemAt(_dp.getItemIndex(selItem));
					providerGrid.dataProvider=_dp;
			})
			ro.deleteProviderById(selItem.providerId);
		}
	})
}

//打印输出
/**
 * @param 参数说明
 * 		  lstrPurview 权限编号;
 * 		  isPrintSign 打印输出标示,预览：2，直接打印：1，输出：0	
 */ 
private function printExpHandler(lstrPurview:String,isPrintSign:String):void
{
	//判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, lstrPurview))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	var lstrReportFileName:String="report/material/list/providerList.xml";
	var receiveListPrintItems:ArrayCollection=providerGrid.dataProvider as ArrayCollection;
	var dict:Dictionary=new Dictionary();
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="供应单位列表";
	dict["制表人"]=AppInfo.currentUserInfo.userName;
	if (isPrintSign == '1')
	{
		ReportPrinter.LoadAndPrint(lstrReportFileName, receiveListPrintItems, dict);
		
	}
	else
	{
		ReportViewer.Instance.Show(lstrReportFileName, receiveListPrintItems, dict);
		
	}
}

private function returnHandler():void{
	DefaultPage.gotoDefaultPage();
	this.parentApplication.mainWin.menuPanel.width = 197 ;
	
}
