// ActionScript file// ActionScript file
/**
 * 基础信息部分的操作
 * */
import cn.superion.dataDict.DictWinShower;
import mx.managers.PopUpManager;
private var _providerClassCode:String = ""; //供应商分类
private var _providerCode:String = ""; //供应商分类
private var _occupationCode:String = "";//行业分类
private var _areaClassCode:String = "";//地区分类
private var _materialCode:String = ""; //物资编码
private var _occupation4:String = "";

import mx.events.FlexEvent;

protected function titlewindow1_creationCompleteHandler(event:FlexEvent):void
{
	//加载供应商分类字典
//	providerGrade.dataProvider = BaseDict.providerClassDict;
}

/**
 * 供应商所属分类
 * */
private function showProviderClass(e:Event):void
{
	DictWinShower.showProviderClassDict(function(rev:Object):void
	{
		_providerClassCode = rev.providerClassCode;
		providerClass.txtContent.text=rev.providerClassName;
	})
}

/**
 * 供应商字典
 * */
protected function showProviderDict():void{
	DictWinShower.showProviderDict(function(rev:Object):void
	{
		_providerCode = rev.providerId;
		txtProviderCode.text = rev.providerName;
	})
}

/**
 * 行业字典
 * */
private function showOccupation(e:Event):void
{
	DictWinShower.showOccupationClassDict(function(rev:Object):void
	{
		_occupationCode=rev.occupationCode;
		occupation.txtContent.text=rev.occupationName;
	})
}

/**
 * 所属地区：地区分类字典
 * */
private function showAreaClass(e:Event):void
{
	DictWinShower.showAreaClassDict(function(rev:Object):void
	{
		_areaClassCode=rev.classCode;
		area.txtContent.text=rev.className;
	})
}
