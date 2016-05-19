import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.util.MainToolBar;

import mx.collections.ArrayCollection;
import mx.events.CloseEvent;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

public var data:Object;
private var _tempDeptCode:String;
private var _tempPersonId:String;

//初始化
protected function titlewindow1_creationCompleteHandler(event:FlexEvent):void
{
	deptCode.txtContent.restrict="^ ";
	personId.txtContent.restrict="^ ";
}

//回车跳转事件
private function toNextControl(e:KeyboardEvent, fcontrolNext:*, th:*):void
{
	if (e.keyCode == Keyboard.ENTER)
	{
		if (th.className == "TextInputIcon")
		{
			if (th.txtContent.text == "" || th.txtContent.text == null)
			{
				if (th.id == "deptCode")
				{
					deptCode_queryIconClickHandler();
				}
				if (th.id == "personId")
				{
					personId_queryIconClickHandler();
				}
			}
			else
			{
				if (fcontrolNext.className == "DateField")
				{
					fcontrolNext.open();
					fcontrolNext.setFocus();
					return;
				}
				if (fcontrolNext.className == "DropDownList")
				{
					fcontrolNext.openDropDown();
					fcontrolNext.setFocus();
					return;
				}
				if (fcontrolNext.className == "TextInputIcon")
				{
					fcontrolNext.txtContent.setFocus();
					return;
				}
				fcontrolNext.setFocus();
			}
		}
		else
		{
			if (fcontrolNext.className == "DateField")
			{
				fcontrolNext.open();
				fcontrolNext.setFocus();
				return;
			}
			if (fcontrolNext.className == "DropDownList")
			{
				fcontrolNext.openDropDown();
				fcontrolNext.setFocus();
				return;
			}
			if (fcontrolNext.className == "TextInputIcon")
			{
				fcontrolNext.txtContent.setFocus();
				return;
			}
			fcontrolNext.setFocus();
		}
	}
}

//取消
protected function btReturn_clickHandler(event:MouseEvent):void
{
	PopUpManager.removePopUp(this);
}

//确定
protected function btConfirm_clickHandler():void
{
	var params:Object=FormUtils.getFields(materialCardQuery, []);
	var paramQuery:ParameterObject=new ParameterObject();
	//启用日期
	if (chkStartDate.selected)
	{
		params['beginStartDate']=dfStartDate.selectedDate;
		//					var endDate:Date=new Date();
		//					endDate.setTime(dfEndDate.selectedDate.getTime() + 24 * 60 * 60 * 1000);
		params['endStartDate'] = MainToolBar.addOneDay(dfEndDate.selectedDate);
	}
	else
	{
		params['beginStartDate']=null;
		params['endStartDate']=null;
	}
	//停用日期
	if (chkStopDate.selected)
	{
		params['beginStopDate']=dfStopStartDate.selectedDate;
		params['endStopDate'] = MainToolBar.addOneDay(dfStopEndDate.selectedDate);
	}
	else
	{
		params['beginStopDate']=null;
		params['endStopDate']=null;
	}
	params['deptCode']=_tempDeptCode == null ? deptCode.txtContent.text : _tempDeptCode;
	params['personId']=_tempPersonId == null ? personId.txtContent.text : _tempPersonId;
	params['maxLimited']=maxLimited.text == "" ? null : parseFloat(maxLimited.text);
	paramQuery.conditions=params;
	PopUpManager.removePopUp(this);
	data.parentWin.gdMaterialCardList.reQuery(paramQuery);
}

protected function chkStartDate_changeHandler(event:Event):void
{
	if (chkStartDate.selected)
	{
		dfStartDate.enabled=true;
		dfEndDate.enabled=true;
	}
	else
	{
		dfStartDate.enabled=false;
		dfEndDate.enabled=false;
	}
	if (chkStopDate.selected)
	{
		dfStopStartDate.enabled=true;
		dfStopEndDate.enabled=true;
	}
	else
	{
		dfStopStartDate.enabled=false;
		dfStopEndDate.enabled=false;
	}
}

//部门字典
protected function deptCode_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(rev:Object):void
	{
		deptCode.txtContent.text=rev.deptName;
		_tempDeptCode=rev.dept;
	});
}

//人员字典
protected function personId_queryIconClickHandler():void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict(function(rev:Object):void
	{
		personId.txtContent.text=rev.personIdName;
		_tempPersonId=rev.personId;
	});
}

protected function btConfirm_keyUpHandler(event:KeyboardEvent):void
{
	if (event.keyCode == Keyboard.ENTER)
	{
		btConfirm_clickHandler();
	}
}