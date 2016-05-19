import cn.superion.base.config.AppInfo;
import cn.superion.base.config.TreeDictWinConfig;
import cn.superion.base.util.RemoteUtil;
import cn.superion.vo.center.deptPerson.CdDeptDict;

import flash.events.Event;

import mx.collections.ArrayCollection;
import mx.collections.Sort;
import mx.collections.SortField;
import mx.events.ListEvent;
import mx.events.TreeEvent;
import mx.rpc.remoting.RemoteObject;

public var selectedDeptCode:String =null;
[Bindable]
private var dataArray:ArrayCollection;
[Bindable]
public var selectedNode:XML;
private var destination:String="deptImpl";
[Bindable]
public var treeData:*={};
[Bindable]
public var cdDept:CdDeptDict=new CdDeptDict();
private var dictWinConfig:TreeDictWinConfig=new TreeDictWinConfig();

/**初始化操作函数*/
public function inittree():void
{
	dictWinConfig.destination=destination;
	dictWinConfig.typeName='部门档案';
	dictWinConfig.classMethod="findDeptListByParentCode"; 
	dictWinConfig.treeLabelField="deptName";
	dictWinConfig.treeRootParentCode='00';
	dictWinConfig.treeCodeField="deptCode";
	
	deptAssignTree.data=dictWinConfig;
	deptAssignTree.init();	
	deptAssignTree.validateDisplayList();
}

//点击树节点
public function changNodeHand(e:Event):void
{
	var node:Object=e.target.selectedItem;
	var deptCode:String=node.deptCode;
	selectedDeptCode = deptCode;
	if(!deptCode)
	{
		return;
	}
	var pd:*=this.parentDocument;
	//选择分类触发查询
	pd.queryProInfo(deptCode);
}	

/**
 * unitTree数据显示处理函数
 * */
private function labelShow(item:Object):String
{
	if (item is CdDeptDict)
	{
		return item.deptCode + ' ' + item.deptName;
	}
	else
	{
		return item.deptName;
	}
}