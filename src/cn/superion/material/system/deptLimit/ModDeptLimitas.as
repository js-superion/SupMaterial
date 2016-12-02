import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.material.util.DefaultPage;
import cn.superion.vo.center.deptPerson.CdDeptDict;
import cn.superion.vo.material.CdDeptLimit;

import flash.events.Event;
import flash.events.MouseEvent;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.core.Application;
import mx.events.CloseEvent;
import mx.managers.PopUpManager;
import mx.modules.ModuleLoader;
import mx.rpc.remoting.mxml.RemoteObject;

private const MENU_NO:String="0707";
private var destination:String="sendImpl";
private var paramter:ParameterObject=new ParameterObject();
private var seasonArray:ArrayCollection = new ArrayCollection([{"month":"1","season":"1"},{"month":"2","season":"1"},{"month":"3","season":"1"},
																 {"month":"4","season":"2"},{"month":"5","season":"2"},{"month":"6","season":"2"},
																 {"month":"7","season":"3"},{"month":"8","season":"3"},{"month":"9","season":"3"},
																 {"month":"10","season":"4"},{"month":"11","season":"4"},{"month":"12","season":"4"}]);
private function inita():void
{
}

public function queryProInfo(deptcode:String):void
{
	paramter.conditions = {"deptCode":deptcode};
	var remoteObj:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
		{
			deptPerInfo.dataProvider=rev.data;
		});
	remoteObj.findDeptLimitByCon(paramter);
}


/**新建**/
private function addClickHandler(evt:MouseEvent):void
{
	//判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, "01"))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}

	var item:*=leftTree.deptAssignTree.selectedItem;
	if(!item)  return;
	addRow(item);
}


/**
 * 增行
 */
protected function addRow(item:CdDeptDict):void
{
	var _details:ArrayCollection = deptPerInfo.dataProvider as ArrayCollection;
	var materialPlanDetail:CdDeptLimit=new CdDeptLimit();
	var currentYear:String = DateUtil.dateToString(new Date(),"YYYY");
	var currentMonth:String = DateUtil.dateToString(new Date(),"MM");
	var index:int = Number(currentMonth) - 1;
	materialPlanDetail.years =  currentYear;
	materialPlanDetail.limits = 0;
	materialPlanDetail.season = seasonArray[index].season;
	materialPlanDetail.deptName = item.deptName;
	materialPlanDetail.deptCode = item.deptCode;
	_details.addItem(materialPlanDetail);
	deptPerInfo.dataProvider = _details;
	deptPerInfo.selectedIndex =_details.length-1;
	deptPerInfo.verticalScrollPosition = _details.length + 1;
	deptPerInfo.editedItemPosition={columnIndex:1,rowIndex:_details.length - 1}
}



/**删除确认*/
private function delUnitConfirm(evt:CloseEvent):void
{
	if (evt.detail == Alert.YES)
	{
		var lselItem:*=deptPerInfo.selectedItem;
		var remoteObj:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
			{
				var arc:ArrayCollection=ArrayCollection(deptPerInfo.dataProvider);
				if (arc && arc.length > 0)
				{
					arc.removeItemAt(arc.getItemIndex(lselItem));
					arc.refresh();
				}
			});
		remoteObj.delDeptVsUserById(lselItem.deptCode, lselItem.userCode);
	}
}
/**返回*/
private function exp():void
{
	DefaultPage.exportExcel(deptPerInfo,'科室限额报表')
}

/**返回*/
private function returnClickHandler(evt:MouseEvent):void
{
}