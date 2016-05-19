// ActionScript file
import cn.superion.base.components.controls.TextInputIcon;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictDataProvider;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.system.provider.ModProviderInfo;
import cn.superion.vo.center.material.CdMaterialDict;
import cn.superion.vo.center.provider.CdProvider;
import cn.superion.vo.center.provider.CdProviderMaterial;

import com.adobe.utils.StringUtil;

import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.ui.Keyboard;
import flash.utils.Timer;

import mx.collections.ArrayCollection;
import mx.containers.Form;
import mx.controls.Alert;
import mx.controls.LinkButton;
import mx.core.Application;
import mx.events.ValidationResultEvent;
import mx.managers.PopUpManager;
import mx.modules.ModuleLoader;
import mx.rpc.remoting.RemoteObject;

import spark.components.PopUpAnchor;
import spark.components.TextInput;
import spark.events.IndexChangeEvent;
import spark.events.TextOperationEvent;

public var destination:String='commProviderImpl';
private var _this:*=this;
[Bindable]
public var data:Object;
[Bindable]
public var proInfoVo:CdProvider;
[Bindable]
private var simpleObj:Object;
public var  gCode:String=null;
public var gName:String=null;

private function initia():void
{
	proInfoVo=this.data.proInfo
	if(this.data.type=='add')
	{
		providerCode.editable=true;
		providerCode.enabled=true;
		providerCode.setFocus();
		this.setBtnEnable([btFirst,btPrevious,btNext,btLast],false);
	}
	else
	{
		providerCode.editable=false;
		providerCode.enabled=false;	
	}
	preventDefaultForm();
	simpleObj=FormUtils.reCreateASimpleObject(proInfoVo);
	fillDictHandler();	
	providerClass.txtContent.text=gName;	
	proInfoVo.providerClassName=gName;
	proInfoVo.providerClass=gCode;
	//所属分类--选中树节点，显示所属分类名称	
	if(this.data.proClassItem)
	{
		proInfoVo.providerClass=this.data.proClassItem.classCode;
		proInfoVo.providerClassName=this.data.proClassItem.className;	
		providerClass.txtContent.text=this.data.proClassItem.className;	
	}
	providerCode.setFocus();
	fillGridFile();
	fillGridProduct();
//	if(!this.data.parentWin.isAuthorizationProvider){
//		tabDrugInfo.removeChild(nav_quality);
//		tabDrugInfo.removeChild(nav_product);
//	}
	
	var ro:RemoteObject = RemoteUtil.getRemoteObject('centerStorageImpl',function(rev1:Object):void{
		if(rev1.data){
			var newAry:ArrayCollection = new ArrayCollection();
			for each(var it:Object in rev1.data){
				var o:Object = new Object();
				o.deptCode = it[0];
				o.deptName = it[1];
				newAry.addItem(o);
			}
			chargeDept.dataProvider = newAry;
			if(data.type=='add')
			{
				chargeDept.selectedIndex=-1;
			}
			else
			{
				FormUtils.selectComboItem(chargeDept,"deptCode",proInfoVo.chargeDept);
			}
		}
	});
	ro.findStorageByProperty("3");
}
/**
 * 阻止放大镜表格输入内容 
 */
private function preventDefaultForm():void
{
	providerClass.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	
	area.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	
	occupation.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	charge.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
}
private function fillGridFile():void{
	var ro:RemoteObject=RemoteUtil.getRemoteObject(ModProviderInfo.destination, function(rev:Object):void
	{	
		gridFile.dataProvider=rev.data;
	})
	ro.findProviderFilesById(proInfoVo.providerId);	
}
private function fillGridProduct():void{
	var ro:RemoteObject=RemoteUtil.getRemoteObject(ModProviderInfo.destination, function(rev:Object):void
	{	
		gridProduct.dataProvider=rev.data;
	})
	ro.findProviderMaterialById(proInfoVo.providerId);		
}
//字典name赋值
private function fillDictHandler():void
{
	if(proInfoVo==null){
		return;
	}
	var dictArry:Array=['providerClass','area','occupation','charge'];
	for each(var field:* in dictArry)
	{
		//有数据赋值，否则清空
		if(proInfoVo[field])
		{
			this[field].txtContent.text=proInfoVo[field+'Name'];
		}
		else
		{
			this[field].txtContent.text='';
		}
	}
}

private function turnToSimpleObj():void
{
	var selItem:Object=FormUtils.getFields(this, []);
	for (var field:*in selItem)
	{
		proInfoVo[field]=selItem[field];
	}
}

//按钮是否可用
private function setBtnEnable(fArray:Array,eSign:Boolean):void
{
	for each(var item:LinkButton in fArray)
	{
		item.enabled=eSign;
	}
}

//清空text
private function clearTxt(fArray:Array):void
{
	for each(var it:TextInput in fArray)
	{
		it.text='';
	}
}

//新增
private function addHandler():void
{
	//判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, ModProviderInfo.MENU_NO, "01"))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	
	providerCode.editable=true;
	providerCode.enabled=true;		
	proInfoVo=new CdProvider();
	clearTxt([providerCode,providerName,shortName,phoInputCode,fiveInputCode]);
	simpleObj=FormUtils.reCreateASimpleObject(proInfoVo);
	fillDictHandler();
	if(this.data.proClassItem)
	{
		proInfoVo.providerClass=this.data.proClassItem.classCode;
		proInfoVo.providerClassName=this.data.proClassItem.className;	
		providerClass.txtContent.text=this.data.proClassItem.className;	
	}
	providerCode.setFocus();		
	//上一条，下一条
	var pd:*=this.data.parentWin;
	pd.preNextHandler(this);	
	gridProduct.dataProvider=[];
	gridFile.dataProvider=[];
	chargeDept.selectedIndex=-1;
}

private function validEmail():Boolean
{
	var myValidators:Array=[emailValid];
	var re:ValidationResultEvent;
	for (var i:int=0; i < myValidators.length; i++)
	{
		re=myValidators[i].validate();
		if (re.results != null)
		{
			myValidators[i].source.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
			myValidators[i].source.setFocus();
			return false;
		}
	}
	return true;
}

private function saveHandler():void
{
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, "0704", "04"))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	if (!providerCode.text)
	{
		Alert.show('编码不能为空,请输入!', '提示');
		return;
	}
	if (!providerName.text)
	{
		Alert.show('名称不能为空,请输入!', '提示');
		return;
	}
	if (!providerClass.txtContent.text || !proInfoVo.providerClass)
	{
		providerClass.txtContent.text='';
		Alert.show('所属分类不能为空,请输入!', '提示');
		return;
	}
	if(chargeDept.selectedIndex == -1 || chargeDept.selectedItem == null)
	{
		Alert.show('分管部门不能为空,请输入!', '提示');
		return;	
	}
	if(!validEmail())
	{
		return;
	}	
	var type:String='';
	var o:Object=proInfoVo
	if(proInfoVo.providerId)
	{
		type='update';
	}
	else
	{
		type='add';
	}
	turnToSimpleObj();	
	var _dp:ArrayCollection=data.parentWin.providerGrid.dataProvider as ArrayCollection;
	if (!_dp)
	{
		_dp=new ArrayCollection;
	}
		
	var ro:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
	{
//			btSave.enabled=false;
			proInfoVo.chargeDeptName=simpleObj.chargeDeptName;
			proInfoVo.chargeName=simpleObj.chargeName;
			proInfoVo.providerClassName=simpleObj.providerClassName;
			proInfoVo.areaName=simpleObj.areaName;
			proInfoVo.occupationName=simpleObj.occupationName;
			data.parentWin.btAdd.enabled=true
			if (type == 'add')
			{
				Alert.show('保存' + proInfoVo.providerName + '供应商信息成功!', '提示信息');
				_dp.addItem(proInfoVo);
				data.parentWin.providerGrid.dataProvider=_dp;
				proInfoVo.providerId=rev.data[0].providerId;
				proInfoVo.unitsCode=rev.data[0].unitsCode;
				data.parentWin.btAdd.enabled=true
				return;
			}
			Alert.show('修改' + proInfoVo.providerName + '供应商信息成功!', '提示信息');
			data.parentWin.providerGrid.invalidateList();
			data.parentWin.providerGrid.selectedItem=proInfoVo;
			data.parentWin.providerGrid.scrollToIndex(data.parentWin.providerGrid.selectedIndex);
			data.parentWin.preNextHandler(_this);
			
	})
	var laryProducts:ArrayCollection = gridProduct.dataProvider as ArrayCollection;
	laryProducts = rebuildData(laryProducts);
	setClearFlagInProvider(proInfoVo,gridFile.dataProvider,laryProducts)
	ro.save( proInfoVo,	gridFile.dataProvider,laryProducts);
	
}
private function setClearFlagInProvider(fproInfo:CdProvider,faryFiles:Object,faryProducts:ArrayCollection):void{
	if(faryFiles==null||faryFiles.length==0){
		fproInfo.clearFileSign="1"
	}else{
		fproInfo.clearFileSign="0"
	}
	if(faryProducts==null||faryProducts.length==0){
		fproInfo.clearMaterialSign="1"
	}else{
		fproInfo.clearMaterialSign="0"
	}
}
private function rebuildData(ary:ArrayCollection):ArrayCollection{
	var lst:ArrayCollection = new ArrayCollection();
	for each(var item:Object in ary){
		var o:CdProviderMaterial = new CdProviderMaterial();
		o.materialId=item.materialId;
		o.accreditDescri = accreditDescri.text;
		o.accreditFileName1 = item.accreditFileName1;
		o.accreditFileName2 = item.accreditFileName2;
		o.accreditFileName3 = item.accreditFileName3;
		o.accreditStartDate = item.accreditStartDate;
		o.accreditStopDate = item.accreditEndDate||item.accreditStopDate;
		o.authorizeNo = item.authorizeNo;
		o.data1 = item.data1;
		o.data2 = item.data2;
		o.data3 = item.data3;
		o.retailPrice = item.retailPrice;
		o.invitedPrice = item.invitedPrice;
		o.factoryCode = item.factoryCode;
		lst.addItem(o);
	}
	return lst;
}
//显示前后数据
private function turnLine(flag:String):void
{
	var seleIndex:Number=data.parentWin.providerGrid.selectedIndex;
	var rowcount:Number=data.parentWin.providerGrid.rowCount;
	var allLine:Number=ArrayCollection(data.parentWin.providerGrid.dataProvider).length;
	if (flag == "first")
	{
		data.parentWin.providerGrid.selectedIndex=0;
		setBtnEnable([btFirst,btPrevious],false);
		setBtnEnable([btAdd,btNext,btLast],true);
	}
	if (flag == "pre")
	{
		if (seleIndex == 1)
		{
			data.parentWin.providerGrid.selectedIndex=0;
			setBtnEnable([btFirst,btPrevious],false);
			setBtnEnable([btAdd,btNext,btLast],true);	
		}
		else
		{
			data.parentWin.providerGrid.selectedIndex=seleIndex - 1;
			setBtnEnable([btAdd,btFirst,btPrevious,btNext,btLast],true);
		}
		
	}
	if (flag == "next")
	{
		if(seleIndex + 2 == allLine)
		{
			data.parentWin.providerGrid.selectedIndex=allLine - 1;
			setBtnEnable([btNext,btLast],false);
			setBtnEnable([btAdd,btFirst,btPrevious],true);	
		}
		else
		{   
			data.parentWin.providerGrid.selectedIndex=seleIndex + 1;
			setBtnEnable([btAdd,btFirst,btPrevious,btNext,btLast],true);	
		}	
	}
	if (flag == "last")
	{
		data.parentWin.providerGrid.selectedIndex=allLine - 1;
		setBtnEnable([btNext,btLast],false);
		setBtnEnable([btAdd,btFirst,btPrevious],true);
	}

	proInfoVo=data.parentWin.providerGrid.selectedItem;
	if(proInfoVo==null){
		return;
	}
	simpleObj=FormUtils.reCreateASimpleObject(proInfoVo);	
	fillDictHandler();	
	this.fillGridFile();
	this.fillGridProduct();
}


/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e, fcontrolNext);
}


private function keUpHandler(e:KeyboardEvent):void
{
	if(!btSaveProvider.enabled)
		return;
	if (e.keyCode == Keyboard.ENTER)
	{
		saveHandler();
	}
}

//地区分类字典
private function showAreaDict(e:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	setBtnEnable([btFirst,btPrevious,btNext,btLast],false);
	
	DictWinShower.showAreaClassDict(function(rev:Object):void
		{
			proInfoVo.area=rev.classCode;
			simpleObj.areaName=rev.className;
			area.txtContent.text=rev.className;
		},x,y)
}

//部门字典
private function showDeptDict(e:IndexChangeEvent):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	setBtnEnable([btFirst,btPrevious,btNext,btLast],false);
			proInfoVo.chargeDept=e.target.selectedItem.deptCode;
			simpleObj.chargeDeptName=e.target.selectedItem.deptName;
}

//人员字典
private function showPersonDict(e:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	setBtnEnable([btFirst,btPrevious,btNext,btLast],false);
	DictWinShower.showPersonDict(function(rev:Object):void
		{
			proInfoVo.charge=rev.personId;
			simpleObj.chargeName=rev.name;
			charge.txtContent.text=rev.name;
		},x,y)
}

//所属分类字典
private function showProviderClassDict(e:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	setBtnEnable([btFirst,btPrevious,btNext,btLast],false);
	DictWinShower.showProviderClassDict(function(rev:Object):void
		{
			proInfoVo.providerClass=rev.classCode;
			simpleObj.providerClassName=rev.className;
			providerClass.txtContent.text=rev.className;
		},x,y)
}

//行业字典
private function showOccupDict(e:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	setBtnEnable([btFirst,btPrevious,btNext,btLast],false);
	DictWinShower.showOccupationClassDict(function(rev:Object):void
		{
			proInfoVo.occupation=rev.occupationCode;
			simpleObj.occupationName=rev.occupationName;
			occupation.txtContent.text=rev.occupationName;
		},x,y)
}

private function changHandler(e:Event):void
{
	setBtnEnable([btFirst,btPrevious,btNext,btLast],false);
	if(e.target.id=='providerName')
	{
		changeProNameHandler();
	}
}

private function changeProNameHandler():void
{
	if(!providerName.text)
	{
		phoInputCode.text='';
		fiveInputCode.text='';
		return;
	}
		
	var ro:RemoteObject=RemoteUtil.getRemoteObject('baseCommonDictImpl',function(rev:Object):void
	{
		if (rev.data && rev.data.length > 0)
		{
			phoInputCode.text=rev.data[0];
			fiveInputCode.text=rev.data[1];
		}	
	})
	ro.findInputCode(providerName.text);
}

//返回
private function returnHadler():void
{
	PopUpManager.removePopUp(this);
	
	//加载高级字典数据
	DictDataProvider.initAdvance();
	DictDataProvider.init();
	
}