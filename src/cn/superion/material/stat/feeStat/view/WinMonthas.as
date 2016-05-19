import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.material.stat.feeStat.ModRdsStat;
import cn.superion.vo.material.MaterialMonth;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.core.UIComponent;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

public var selectAll:Boolean=false;
private var deptCode:String="";
private var personId:String="";
private var providerId:String="";
private const MENU_NO:String="0404";
public var disAry:Array=[];
public var enAry:Array=[];
[Bindable]
private var importClassFactory:ClassFactory;
private var destination:String="monthImpl";
private var materialMonth:MaterialMonth=new MaterialMonth;
//结账处理时，方法的不同，泰州的为false,东方的为true
private var isFee:Boolean = false;
public var parentWin:ModRdsStat;
protected function doInit():void
{
	fillYearCombo();
}
private function fillYearCombo():void{
	isFee = ExternalInterface.call("getIsFee");
	var laryYears:ArrayCollection=new ArrayCollection()
	var curYear:int=new Date().getFullYear()
	for(var lintYear:int=curYear-10;lintYear<curYear+2;lintYear++){
		laryYears.addItem(lintYear);
	}
	year.dataProvider=laryYears;
	year.textInput.editable=false;
	storage.textInput.editable=false;
	year.selectedItem=curYear;
}
protected function btReturn_clickHandler():void
{
	PopUpManager.removePopUp(this);
}
//仓库字典
protected function storageCode_creationCompleteHandler(event:FlexEvent):void
{
//	storage.selectedIndex=0;
	storage.labelField="storageName";
	var result:ArrayCollection =ObjectUtil.copy(AppInfo.currentUserInfo.storageList) as ArrayCollection;
	var newArray:ArrayCollection = new ArrayCollection();
	for each(var it:Object in result){
		if(it.type == '2'||it.type == '3'){
			newArray.addItem(it);
		}
	}
	storage.dataProvider=newArray;//AppInfo.currentUserInfo.storageList;
	storage.selectedIndex=0;
}

//查询
protected function btQuery_clickHandler(event:MouseEvent):void
{
	var params:Object=FormUtils.getFields(queryArea, []);
	var paramQuery:ParameterObject=new ParameterObject();
	var storageCode:String=storage.selectedItem.storageCode;
	var strYear:String=year.selectedItem.toString()
	if(strYear=="")
	{
		Alert.show("请输入年份","提示");
		return;
	}
	
	paramQuery.conditions = params;
	//查询主记录ID列表
	var ro:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
	{
		var list:ArrayCollection=rev.data as ArrayCollection;
		for (var i:int=0;i<list.length;i++)
		{
			var item:Object=list.getItemAt(i,i);
			if (item.accountSign=="0")
			{
				item.accountSign="否";
			}
			else
			{
				item.accountSign="是";
			}
		}
		gridPurchaseDetail.dataProvider=list;
	});
	ro.findMonth (storageCode,strYear);
}

//结账
protected function btCheck_clickHandler(event:MouseEvent):void
{
	var lmaterialMonth:MaterialMonth=gridPurchaseDetail.selectedItem as MaterialMonth;
	if(!lmaterialMonth){
		Alert.show("请选择结账数据","提示");
		return;
	}
	var ro:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
	{		
		Alert.show("结账成功","提示");
		btQuery_clickHandler(null);
	});
	if(isFee){//byzcl
		ro.saveMonthFee(lmaterialMonth);
	}else{
		ro.saveMonth(lmaterialMonth);
	}
	
	
}
protected function btCancel_clickHandler(event:MouseEvent):void
{
	var lmaterialMonth:MaterialMonth=gridPurchaseDetail.selectedItem as MaterialMonth;
	if(!lmaterialMonth){
		Alert.show("请选择取消结账数据","提示")
		return;
	}	
	var ro:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
	{
		if (rev.error == null)
		{
			Alert.show("取消结账成功","提示");
			btQuery_clickHandler(null);
			
		}
		
	});
	ro.cancelMonth(lmaterialMonth.storageCode,lmaterialMonth.yearMonth);
}