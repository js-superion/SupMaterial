import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.vo.center.provider.CdProviderClass;

import flash.events.Event;
import flash.external.ExternalInterface;

import mx.collections.ArrayCollection;
import mx.events.ListEvent;
import mx.rpc.remoting.mxml.RemoteObject;

[Bindable]
private var dataArray:ArrayCollection;
private var destination:String="providerClassImpl";
[Bindable]
public var treeData:*={};
[Bindable]
public var proClassVo:CdProviderClass=new CdProviderClass();

/**初始化操作函数*/
private function initia():void
{
	buildProClassTree();
}

private function buildProClassTree():void
{
	var ro:RemoteObject=RemoteUtil.getRemoteObject(destination,function(rev:Object):void
	{
		var config:*={dataList:rev.data};
		config.labelField='className';
		config.rootParentCode='00';
		config.codeField='classCode';
		config.parentCodeField='parentCode';
		treeData= ArrayCollUtils.buildTreeData(config);
		treeData.className=ExternalInterface.call("getProviderClassName");
		itemClassTree.dataProvider=treeData;
		itemClassTree.openItems=[treeData];
		itemClassTree.invalidateList();
	})
	ro.findProviderClassList();
}

private function douClickHandler(e:ListEvent):void
{
	var flag:Boolean=e.target.isItemOpen(itemClassTree.selectedItem);
	e.target.expandItem(itemClassTree.selectedItem,!flag);	
}

//点击树节点
public function changNodeHand(e:Event):void
{
	var node:*=e.target.selectedItem;
	var classCode:String=node.classCode;
	if(!classCode)
	{
		return;
	}
	var pd:*=this.parentDocument;
	//选择分类触发查询
	pd.queryHandler(classCode);
}

//数据显示code+name
private function labelShow(item:Object):String
{
	if(item && item.endSign && item.endSign=='0' && !item.children)
	{
		item.children=new ArrayCollection();
	}	
	if(item.classCode=='00')
	{
		return item.className;
	}	
	return item.classCode + ' ' + item.className;
}