
import cn.superion.base.components.controls.TextInputIcon;
import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.ObjectUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.base.util.StringUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.dataDict.MaterialDictWin;
import cn.superion.material.deliver.deliverOther.view.WinReceiveQuery;
import cn.superion.material.util.DefaultPage;
import cn.superion.material.util.MaterialCurrentStockShower;
import cn.superion.material.util.MaterialDictShower;
import cn.superion.material.util.ReportParameter;
import cn.superion.report.hlib.UrlLoader;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialRdsDetail;
import cn.superion.vo.material.MaterialRdsMaster;
import cn.superion.vo.system.SysUnitInfor;

import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.controls.Text;
import mx.core.FlexGlobals;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.events.DataGridEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;
import mx.utils.StringUtil;

import org.alivepdf.layout.Format;

import spark.events.TextOperationEvent;

registerClassAlias("cn.superion.material.entity.MaterialRdsMaster", cn.superion.vo.material.MaterialRdsMaster);
registerClassAlias("cn.superion.material.entity.MaterialRdsDetail", cn.superion.vo.material.MaterialRdsDetail);

public static const MENU_NO:String="0304";
//服务类
public static const DESTANATION:String="otherDeliverImpl";

private var _winY:int=0;

private var _materialRdsMaster:MaterialRdsMaster=new MaterialRdsMaster();
private var _materialRdsDetail:MaterialRdsDetail=new MaterialRdsDetail();
//出库主记录
private var _deliverRdsMaster:MaterialRdsMaster=new MaterialRdsMaster();
//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;

private var isCheckAmount:Boolean = false; //是否需要验证申请最大数
private var maxAmount:Number = 0; //参数表中定义的最大数量

//是否批号管理
[Bindable]
private var _bathSign:Boolean;
private var isRdsBatch:Boolean=false;//入库时是否按批号入库，参数定义
private var _isPrint:Boolean=false;//打印报表设置
private var _isDetailRemark:Boolean=false;//是否显示备注
private var _isShow:Boolean=false;//显示小数位数，东方3，泰州2


/**
 * 初始化当前窗口
 */
public function doInit():void
{
	if(parentDocument is WinModual){
		parentDocument.title="其它出库处理";
	}
	_winY=this.parentApplication.screen.height - 345;
	rdType.width=storageCode.width;
	billNo.width=deptCode.width;
	//
	initPanel();
	//加载泰州南北两院
	var ro:RemoteObject = RemoteUtil.getRemoteObject("unitInforImpl",function(rev:Object):void{
		if(rev.data.length > 0 ){
			for each (var it:SysUnitInfor in rev.data){
				it.label = it.unitsSimpleName;
				it.data = it.unitsCode;
			}
			MaterialDictShower.SYS_UNITS = rev.data;
		}
		
		var ro:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl',function(rev:Object):void{
			if(rev.data[0] != null){
				isCheckAmount = true
				maxAmount = rev.data[0];
				//
			}
		});
		ro.findSysParamByParaCode("0406");
	});
	ro.findByEndSign("1");
	
	ro=RemoteUtil.getRemoteObject('centerSysParamImpl', function(rev:Object):void
	{
		if (rev.data && rev.data[0] == '1')
		{
			isRdsBatch=true; 
		}
		else{
			isRdsBatch=false; 
		}
		
	});
	ro.findSysParamByParaCode("0206");
	
	//是否显示备注，东方1是，泰州0否
	var ros:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl', function(rev:Object):void
	{
		if (rev.data && rev.data[0] == '1')
		{
			_isDetailRemark=true; 
		}
		else{
			_isDetailRemark=false; 
		}
		
	});
	ros.findSysParamByParaCode("0602");
	//是否显示三位小数。
	var rosv:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl', function(rev:Object):void
	{
		if (rev.data && rev.data[0] == '1')
		{
			_isShow=true; 
//			gdRdsDetail.format = [,,,,,'0.000','0.000','0.000','0.000','0.000','0.000','0.000','0.000','0.000','0.000','0.000','0.000','0.000'];
		}
		else{
			_isShow=false; 
		}
		
	});
	rosv.findSysParamByParaCode("0609");
}

/**
 * 面板初始化
 */
private function initPanel():void
{
	initToolBar();
	//增加项隐藏
	bord.height=70;
	hiddenVGroup.includeInLayout=false;
	hiddenVGroup.visible=false;
	//授权仓库赋值
	if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
	{
//		storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
//		storageCode.selectedIndex=0;
		
		var result:ArrayCollection =ObjectUtil.copy(AppInfo.currentUserInfo.storageList) as ArrayCollection;
		var newArray:ArrayCollection = new ArrayCollection();
		for each(var it:Object in result){
			if(it.type == '2'||it.type == '3'){
				newArray.addItem(it);
			}
		}
		storageCode.dataProvider=newArray;//AppInfo.currentUserInfo.storageList;
		storageCode.selectedIndex=0;
		
	}
	//设置只读
	setReadOnly(true);
	//阻止表单输入
	preventDefaultForm();
	toolBar.btAbandon.label="弃审";
	//打印报表设置
	var rov:RemoteObject=RemoteUtil.getRemoteObject('centerSysParamImpl', function(rev:Object):void
	{
		if(rev.data[0] == '1'){
			_isPrint = true;
		}
	});
	rov.findSysParamByParaCode("0608");
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1,toolBar.btAbandon, toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, toolBar.btSave, toolBar.btVerify, toolBar.imageList2, toolBar.btAddRow, toolBar.btDelRow, toolBar.imageList3, toolBar.btQuery, toolBar.imageList5, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array=[toolBar.btExit, toolBar.btQuery, toolBar.btAdd]
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	boolean=!boolean;
	blueType.enabled=boolean;
	redType.enabled=boolean;

	deptCode.enabled=boolean;
	personId.enabled=boolean;
	billDate.enabled=boolean;
	rdType.enabled=boolean;
	operationNo.enabled=boolean;

	billNo.enabled=boolean;
	billMonthNo.enabled=boolean;
	remark.enabled=boolean;
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	deptCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
		{
			e.preventDefault();
		})

	personId.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
		{
			e.preventDefault();
		})

	materialCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
		{
			e.preventDefault();
		})
}

/**
 * 清空表单
 */
public function clearForm(masterFlag:Boolean, detailFlag:Boolean):void
{
	if (masterFlag)
	{
		blueType.selected=true;

		deptCode.txtContent.text="";
		personId.txtContent.text="";

		billDate.selectedDate=new Date();

		operationNo.text="";
		rdType.txtContent.text="";
		billNo.text="";
		billMonthNo.text="";

		remark.text="";

		currentStockAmount.text="";
		maker.text='';
		makeDate.text='';
		verifier.text='';
		verifyDate.text='';

		_materialRdsMaster=new MaterialRdsMaster();
		_deliverRdsMaster=new MaterialRdsMaster();
	}
	if (detailFlag)
	{
		materialCode.txtContent.text="";
		materialName.text="";
		materialSpec.text="";
		materialUnits.text="";

		amount.text="";

		batch.text="0";

		gdRdsDetail.dataProvider=new ArrayCollection();
	}
}

/**
 * 回车事件
 **/
private function toNextCtrl(event:KeyboardEvent, fctrlNext:Object):void
{
	if (event.keyCode != Keyboard.ENTER)
	{
		return;
	}
	if (event.currentTarget == batch)
	{
		materialCode.txtContent.text='';

	}
	if(event.currentTarget == materialCode){
		materialCode.txtContent.text = '';
		materialCode.txtContent.setFocus();
	}
	//
	FormUtils.toNextControl(event, fctrlNext);
}

/**
 * 供应商档案
 */
protected function salerCode_queryIconClickHandler(event:Event):void
{
	//考虑到登陆人员看到不同科室的的仓库，这里根据仓库编码和单位编码到仓库字典中查对应的 所属部门；
	var ro:RemoteObject = RemoteUtil.getRemoteObject('centerStorageImpl',function(rev1:Object):void{
		if(rev1.data){
			var x:int=0;
			DictWinShower.showProviderDict(function(rev:Object):void
			{
				salerCode.txtContent.text=rev.providerName;
				
				_materialRdsMaster.salerCode=rev.providerId; 
				_materialRdsMaster.salerName=rev.providerName;
				
				_deliverRdsMaster.salerCode=rev.providerId; 
				_deliverRdsMaster.salerName=rev.providerName;
				
				
			}, x, _winY,rev1.data[0].deptCode);
		}
	});
	ro.findStorageById(storageCode.selectedItem.storageCode);
}

/**
 * 部门档案
 */
protected function deptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	MaterialDictShower.showDeptDict(function(rev:Object):void
		{
			deptCode.txtContent.text=rev.deptName;
			_materialRdsMaster.deptCode=rev.deptCode;
			materialCode.txtContent.setFocus();
			_deliverRdsMaster.deptCode=rev.deptCode;
		}, x, y);
}

/**
 * 人员档案
 */
protected function personId_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict(function(rev:Object):void
		{
			personId.txtContent.text=rev.name;

			_materialRdsMaster.personId=rev.personId;
			_deliverRdsMaster.personId=rev.personId;
		}, x, y);
}

/**
 * 调用出库类型字典
 */
protected function rdType_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	MaterialDictShower.showDeliverTypeDict(function(rev:Object):void
		{
			rdType.txtContent.text=rev.rdName;

			_materialRdsMaster.rdType=rev.rdCode;
		}, x, y);
}

/**
 * 物资字典
 */
protected function materialCode_queryIconClickHandler(event:Event):void
{
	//打开物资字典
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 338;

	var lstorageCode:String='';
	lstorageCode=(storageCode.selectedItem || {}).storageCode;
	
	//考虑到二级库，二级库定义为四位，截取lstorageCode前2位
//	lstorageCode = lstorageCode.substr(0,2);
	DictWinShower.showMaterialDictNew(lstorageCode, '', '', true, function(fItem:Array):void
		{
			fillIntoGrid(fItem);
		}, x, y,"1");
}

/**
 * 药品字典自动完成表格回调
 * */
private function fillIntoGrid(fItem:Array):void
{
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
//

	for(var i:int=0;i<fItem.length;i++)
	{
		var lnewlDetail:MaterialRdsDetail=new MaterialRdsDetail();
		
		lnewlDetail.materialId=fItem[i].materialId;
		lnewlDetail.materialClass=fItem[i].materialClass;
		lnewlDetail.barCode=fItem[i].barCode;
		lnewlDetail.materialCode=fItem[i].materialCode;
		lnewlDetail.materialName=fItem[i].materialName;
		lnewlDetail.materialSpec=fItem[i].materialSpec;
		lnewlDetail.materialUnits=fItem[i].materialUnits;
		
		lnewlDetail.packageSpec=fItem[i].packageSpec;
		lnewlDetail.packageUnits=fItem[i].packageUnits;
		if (fItem[i].amountPerPackage == '' || fItem[i].amountPerPackage == null)
		{
			lnewlDetail.amountPerPackage=1;
		}
		else
		{
			lnewlDetail.amountPerPackage=fItem[i].amountPerPackage;
		}
		lnewlDetail.packageAmount=0;
		
		lnewlDetail.amount=1;
		lnewlDetail.acctAmount=0;
		
		lnewlDetail.tradePrice=fItem[i].tradePrice;
		lnewlDetail.tradeMoney=fItem[i].tradePrice;
		
		lnewlDetail.rebateRate=fItem[i].rebateRate;
		lnewlDetail.rebateRate=isNaN(lnewlDetail.rebateRate) ? 1 : lnewlDetail.rebateRate;
		
		lnewlDetail.factTradePrice=fItem[i].tradePrice * fItem[i].rebateRate;
		lnewlDetail.factTradeMoney=fItem[i].tradePrice * fItem[i].rebateRate;
		
		//是否批号管理
		_bathSign=isRdsBatch && fItem[i].batchSign=='1' ? true : false;
		
//		//最大批号
//		var ro:RemoteObject=RemoteUtil.getRemoteObject("receiveImpl",function(rev:Object):void
//		{
//			if(_bathSign)
//			{
//				lnewlDetail.batch=rev.data[0];
//			}
//			else
//			{
//				lnewlDetail.batch=(Number(rev.data[0])-1).toString();
//			}
//			batch.text=lnewlDetail.batch;
//		});
//		ro.findMaxBatch(lnewlDetail.materialId);
		batch.text = '0';
		lnewlDetail.batch='0'
		
		lnewlDetail.wholeSalePrice=fItem[i].wholeSalePrice;
		lnewlDetail.wholeSaleMoney=fItem[i].wholeSalePrice;
		
		lnewlDetail.invitePrice=fItem[i].invitePrice;
		lnewlDetail.inviteMoney=fItem[i].invitePrice;
		
		lnewlDetail.retailPrice=fItem[i].retailPrice;
		lnewlDetail.retailMoney=fItem[i].retailPrice;
		
		lnewlDetail.factoryCode=fItem[i].factoryCode;
		lnewlDetail.chargeSign = fItem[i].chargeSign;//收费标示；
		lnewlDetail.classOnAccount = fItem[i].accountClass;//会计分类；
		lnewlDetail.currentStockAmount=fItem[i].amount;
		
		lnewlDetail.outAmount=0;
		lnewlDetail.outSign='0';
		
		lnewlDetail.countClass = fItem[i].countClass;
		lnewlDetail.registerNo = fItem[i].registerNo;
		lnewlDetail.inviteNo = fItem[i].inviteNo;
		
		
		lnewlDetail.invoiceAmount=0;
		lnewlDetail.invoiceSign='0';
		
		lnewlDetail.highValueSign=fItem[i].highValueSign;
		lnewlDetail.agentSign=fItem[i].agentSign;
		
		lnewlDetail.checkAmount=0;
		
		laryDetails.addItem(lnewlDetail);
	}
	

	gdRdsDetail.dataProvider=laryDetails;
	gdRdsDetail.selectedItem=lnewlDetail;

	fillDetailForm(lnewlDetail);
	storageCode.enabled=false;
	
	batch_queryIconClickHandler(null);
	
	var timer:Timer=new Timer(100, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
		{
			gdRdsDetail.scrollToIndex(gdRdsDetail.selectedIndex);
			amount.setFocus();
		})
	timer.start();
}

/**
 * 批号字典
 */
protected function batch_queryIconClickHandler(event:Event):void
{
	var lselItem:MaterialRdsDetail=gdRdsDetail.selectedItem as MaterialRdsDetail;
	if (lselItem == null)
	{
		return;
	}

	var lstorageCode:String='';
	lstorageCode=(storageCode.selectedItem || {}).storageCode;
	//打开批号字典
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 338;

	MaterialCurrentStockShower.showCurrentStock(lstorageCode, lselItem.materialId, '', function(faryItems:Array):void
		{
			fillIntoGridByBatch(faryItems);
		}, x, y);
}

/**
 * 批号字典自动完成表格回调
 * */
private function fillIntoGridByBatch(faryItems:Array):void
{
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	var lRdsDetail:MaterialRdsDetail=gdRdsDetail.selectedItem as MaterialRdsDetail;
	//byzcl
//	for(var j:int=0;j<laryDetails.length;j++){
//		if(faryItems[0].materialId == laryDetails.getItemAt(j).materialId && faryItems[0].batch == laryDetails.getItemAt(j).batch){
//			Alert.show('明细中已存在相同的'+faryItems[0].materialName+'物资');
//			laryDetails.removeItemAt(laryDetails.length-1);
//			gdRdsDetail.dataProvider = laryDetails;
//			return;
//		}
//	}
	//byzcl
	if (!lRdsDetail)
	{
		return;
	}
	var i:int=0;
	

	for each (var item:Object in faryItems)
	{
		var lnewlDetail:MaterialRdsDetail=new MaterialRdsDetail();
		if (i == 0)
		{
			batch.text=item.batch;

			lRdsDetail.tradePrice=item.tradePrice;
			lRdsDetail.factoryCode=item.factoryCode;
			lRdsDetail.madeDate=item.madeDate;
			lRdsDetail.batch=item.batch;
			lRdsDetail.availDate=item.availDate;
			lRdsDetail.wholeSalePrice=item.wholeSalePrice;
			lRdsDetail.retailPrice=item.retailPrice;
			lRdsDetail.wholeSaleMoney=item.wholeSalePrice;// item.amount  byzcl
			lRdsDetail.retailMoney=item.retailPrice;
			lRdsDetail.tradeMoney = item.tradePrice; 
			lRdsDetail.currentStockAmount=item.amount;//byzcl

			lnewlDetail=lRdsDetail;
			i++;
			continue;
		}

		lnewlDetail.materialId=lRdsDetail.materialId;
		lnewlDetail.materialClass=lRdsDetail.materialClass;
		lnewlDetail.barCode=lRdsDetail.barCode;
		lnewlDetail.materialCode=lRdsDetail.materialCode;
		lnewlDetail.materialName=lRdsDetail.materialName;
		lnewlDetail.materialSpec=lRdsDetail.materialSpec;
		lnewlDetail.materialUnits=lRdsDetail.materialUnits;

		lnewlDetail.amount=1;

		lnewlDetail.tradePrice=item.tradePrice;
		lnewlDetail.tradeMoney=item.tradePrice;

		lnewlDetail.rebateRate=item.rebateRate;
		lnewlDetail.rebateRate=isNaN(item.rebateRate) ? 1 : lRdsDetail.rebateRate;

		lnewlDetail.factTradePrice=item.tradePrice * item.rebateRate;
		lnewlDetail.factTradeMoney=0;

		lnewlDetail.wholeSalePrice=item.wholeSalePrice;
		lnewlDetail.wholeSaleMoney=Number((item.wholeSalePrice).toFixed(2))

		lnewlDetail.invitePrice=item.invitePrice;
		lnewlDetail.inviteMoney=0;

		lnewlDetail.retailPrice=item.retailPrice;
		lnewlDetail.retailMoney=Number((item.retailPrice).toFixed(2));

		lnewlDetail.factoryCode=item.factoryCode;

		lnewlDetail.currentStockAmount=item.amount;

		lnewlDetail.madeDate=item.madeDate;
		lnewlDetail.batch=item.batch;
		lnewlDetail.availDate=item.availDate;


		lnewlDetail.outAmount=0;
		lnewlDetail.outSign='0';

		lnewlDetail.invoiceAmount=0;
		lnewlDetail.invoiceSign='0';

		lnewlDetail.highValueSign=lRdsDetail.highValueSign;
		lnewlDetail.agentSign=lRdsDetail.agentSign;

		lnewlDetail.checkAmount=0;
		
		lnewlDetail.packageAmount = lRdsDetail.packageAmount
		lnewlDetail.amountPerPackage = lRdsDetail.amountPerPackage
		lnewlDetail.factTradePrice = lRdsDetail.factTradePrice
		lnewlDetail.factTradeMoney = lRdsDetail.factTradeMoney
		lnewlDetail.serialNo = lRdsDetail.serialNo
		lnewlDetail.acctAmount = lRdsDetail.acctAmount

		laryDetails.addItem(lnewlDetail);
	}
	gdRdsDetail.dataProvider=laryDetails;
	gdRdsDetail.selectedItem=lnewlDetail;

	fillDetailForm(lnewlDetail);

	var timer:Timer=new Timer(100, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
		{
			gdRdsDetail.scrollToIndex(gdRdsDetail.selectedIndex);
			materialCode.txtContent.text="";
		//	materialCode.txtContent.setFocus();
			amount.setFocus();
		})
	timer.start();
}


/**
 * 明细表单赋值 checked by zzj 2011.06.04
 */
private function fillDetailForm(fselDetailItem:MaterialRdsDetail):void
{
	if (!fselDetailItem)
	{
		return;
	}
	//
	materialCode.txtContent.text=fselDetailItem.materialCode;
	materialName.text=fselDetailItem.materialName;
	materialSpec.text=fselDetailItem.materialSpec;
	materialUnits.text=fselDetailItem.materialUnits;
	detailRemark.text = fselDetailItem.detailRemark; //byzcl

	amount.text=fselDetailItem.amount + '';
	batch.text=fselDetailItem.batch;

	currentStockAmount.text=fselDetailItem.currentStockAmount + '';
}

/**
 * 数量进行改变事件
 */
public function amount_ChangeHandler(event:Event):void
{
	var lRdsDetail:MaterialRdsDetail=gdRdsDetail.selectedItem as MaterialRdsDetail;
	if (!lRdsDetail)
	{
		return;
	}
	var isCharDuplication:Boolean = false;
	var trimedText:String = mx.utils.StringUtil.trim(amount.text); 
	for(var i:int = 1; i < trimedText.length;i ++){
		if(trimedText.charAt(i) == '-'){
			isCharDuplication = true;
			break;
		}
	}
	if(isCharDuplication){
		amount.text = '-';
		amount.selectRange(1,amount.text.length);;
		return;	
	}
	if(isNaN(Number(trimedText)) || trimedText == '' ){
		lRdsDetail.amount = 0;
	}else{
		lRdsDetail.amount=isNaN(lRdsDetail.amount) ? 1 : lRdsDetail.amount;
		lRdsDetail.amount=parseFloat(amount.text) //* lRdsDetail.amountPerPackage;
	}
//	lRdsDetail.packageAmount = parseFloat(packageAmount.text);
	lRdsDetail.acctAmount = lRdsDetail.amount;
	if(_isShow){
		lRdsDetail.tradeMoney=lRdsDetail.amount * lRdsDetail.tradePrice;
		lRdsDetail.factTradeMoney=Number((lRdsDetail.amount * lRdsDetail.factTradePrice).toFixed(3));
		
		lRdsDetail.wholeSaleMoney=Number((lRdsDetail.amount * lRdsDetail.wholeSalePrice).toFixed(3));
		lRdsDetail.inviteMoney= Number((lRdsDetail.amount * lRdsDetail.invitePrice).toFixed(3));
		
		lRdsDetail.retailMoney= Number((lRdsDetail.amount * lRdsDetail.retailPrice).toFixed(3));
	}else{
		lRdsDetail.tradeMoney=lRdsDetail.amount * lRdsDetail.tradePrice;
		lRdsDetail.factTradeMoney=Number((lRdsDetail.amount * lRdsDetail.factTradePrice).toFixed(2));
		
		lRdsDetail.wholeSaleMoney=Number((lRdsDetail.amount * lRdsDetail.wholeSalePrice).toFixed(2));
		lRdsDetail.inviteMoney= Number((lRdsDetail.amount * lRdsDetail.invitePrice).toFixed(2));
		
		lRdsDetail.retailMoney= Number((lRdsDetail.amount * lRdsDetail.retailPrice).toFixed(2));
	}
	
}

/**
 * 数量失去焦点，若是蓝字，则为正，否则为负
 * */
protected function amount_focusOutHandler(event:FocusEvent):void
{
	if(redOrBlue.selection == blueType){
		if(Number(amount.text)  > 0 ){
			return;	
		}
		amount.text = Number(0-Number(amount.text)).toString();
		
	}else{
		if(Number(amount.text)  < 0 ){
			return;	
		}
		if(amount.text == '-'){
			amount.text = '0';
		}
		amount.text = Number(0-Number(amount.text)).toString();
	}
	amount_ChangeHandler(null);
}
/**
 * 批号
 */
protected function batch_changeHandler(event:Event):void
{
	var lRdsDetail:MaterialRdsDetail=gdRdsDetail.selectedItem as MaterialRdsDetail;
	if (!lRdsDetail)
	{
		return;
	}
	lRdsDetail.batch=batch.text;
}

/**
 * 填充当前表单 checked by zzj 2011.04.22
 */
protected function gdRdsDetail_itemClickHandler(event:Event):void
{
	var lRdsDetail:MaterialRdsDetail=gdRdsDetail.selectedItem as MaterialRdsDetail;
	if (!lRdsDetail)
	{
		return;
	}
	fillDetailForm(lRdsDetail);
}

//打印
protected function printClickHandler(event:Event):void
{
	printReport("1");
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		
	});
	ro.updateRdsPrintSign(_materialRdsMaster.autoId);

}

//输出
protected function expClickHandler(event:Event):void
{
//	printReport("0");
	makeExport(gdRdsDetail);

}

/**
 *导出为EXCEL 
 */
private function makeExport(dataGridName:Object):void{
	
	var laryDataList:ArrayCollection=new ArrayCollection();
	var cols:Array=[];
	var excelFile:ExcelFile = new ExcelFile();
	var sheet:Sheet = new Sheet();
	laryDataList = dataGridName.dataProvider as ArrayCollection;
	cols=dataGridName.columns;
	sheet.resize(dataGridName.dataProvider.length+10,cols.length+10);
	addExcelHeader(dataGridName,sheet);
	addExcelData(laryDataList,sheet,dataGridName);
	addExcelLaster(dataGridName,sheet);
	excelFile.sheets.addItem(sheet);
	var mbytes:ByteArray = excelFile.saveToByteArray();
	var  file:FileReference=new FileReference();
	var _currentDate:String=DateField.dateToString(new Date(),'YYYY-MM-DD');
	var excelTitle:String='其他出库表'+_currentDate;
	file.save(mbytes,excelTitle+".xls");
}
private function addExcelHeader(dataList:Object,fsheet:Sheet):void{   
	var cols:Array=dataList.columns;	
	var i:int=0;
	for each(var col:* in cols){
		fsheet.setCell(0,i,col.headerText);
		i++;
	}
}
private function addExcelLaster(dataList:Object,fsheet:Sheet):void{   
	var cols:Array=dataList.columns;	
	var i:int=0;
	var initMon5:Number=0;
	var initMon6:Number=0;
	var initMon7:Number=0;
	var lary:ArrayCollection = dataList.dataProvider as ArrayCollection;
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).amount != null && lary.getItemAt(j).amount != ''){
			initMon5 += lary.getItemAt(j).amount;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).wholeSaleMoney != null && lary.getItemAt(j).wholeSaleMoney != ''){
			initMon6 += lary.getItemAt(j).wholeSaleMoney;
		}
	}
	for(var j:int=0;j<lary.length;j++){
		if(lary.getItemAt(j).retailMoney != null && lary.getItemAt(j).retailMoney != ''){
			initMon7 += lary.getItemAt(j).retailMoney;
		}
	}
	
	for each(var col:* in cols){
		if(i==0){
			fsheet.setCell(dataList.dataProvider.length+1,i,"合计");
			fsheet.setCell(dataList.dataProvider.length+2,i,"仓库：");
			fsheet.setCell(dataList.dataProvider.length+3,i,"出库单号：");
			fsheet.setCell(dataList.dataProvider.length+4,i,"出库日期：");
			fsheet.setCell(dataList.dataProvider.length+5,i,"请领部门：");
		}if(i==1){
			fsheet.setCell(dataList.dataProvider.length+2,i,storageCode.selectedItem.storageName);
			fsheet.setCell(dataList.dataProvider.length+3,i,_materialRdsMaster.billNo == null ? "" : _materialRdsMaster.billNo);
			fsheet.setCell(dataList.dataProvider.length+4,i,DateUtil.dateToString(_materialRdsMaster.billDate,'YYYY-MM-DD'));
			fsheet.setCell(dataList.dataProvider.length+5,i,ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', _materialRdsMaster.deptCode) == null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', _materialRdsMaster.deptCode).deptName);
		}else if(i==6){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon5);
		}else if(i==8){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon6);
		}else if(i==10){
			fsheet.setCell(dataList.dataProvider.length+1,i,initMon7);
		}
		i++;
	}
}

private function addExcelData(laryDataList:ArrayCollection,fsheet:Sheet,gridName:Object):void{
	var lintRow:int=1;
	var cols:Array=gridName.columns;
	for each(var litem:Object in laryDataList){
		var lintColumn:int = 0;
		var index:int =0;
		for each(var col:DataGridColumn in cols){
			fsheet.setCell(lintRow,0,lintRow ||'');
			if(litem[cols[index].dataField] is Date)
				fsheet.setCell(lintRow,lintColumn,DateField.dateToString(litem[cols[index].dataField],'YYYY-MM-DD'));
			else
				fsheet.setCell(lintRow,lintColumn,litem[cols[index].dataField]|| '');
			index++;
			lintColumn ++;
		}
		lintRow ++;
	}
	
}


/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	if(_isPrint){
		//setPrintPageSize()
		var dataList:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
		var rawData:ArrayCollection=gdRdsDetail.getRawDataProvider() as ArrayCollection;
		var lastItem:Object=rawData.getItemAt(rawData.length - 1);
		preparePrintData(dataList);
		var dict:Dictionary=new Dictionary();
		dict["主标题"]="其他出库单";
		dict["批发总额"]=lastItem.wholeSaleMoney.toFixed(2);
		dict["零售总额"]=lastItem.retailMoney.toFixed(2);
		dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
		dict["仓库"]=storageCode.selectedItem.storageName;
		dict["供货单位"]=_materialRdsMaster.salerName;
		dict["请领部门"]=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', _materialRdsMaster.deptCode) == null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', _materialRdsMaster.deptCode).deptName;
		dict["出库日期"]=_materialRdsMaster.billDate;
		dict["出库单号"]=_materialRdsMaster.billNo == null ? "" : _materialRdsMaster.billNo;
		dict["月单号"]=_materialRdsMaster.billMonthNo;
		//dict["表尾第一行"]=createPrintFirstBottomLine(lastItem);
		var makerv:String=shiftTo(_materialRdsMaster.maker);
		dict["表尾第一行"]=createPrintFirstBottomLine1(verifier.text,personId.text,makerv);
		loadReportXml("report/material/deliver/deliverOther_1.xml", dataList, dict,printSign)
	}else{
		setPrintPageSize()
		var dataList:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
		var rawData:ArrayCollection=gdRdsDetail.getRawDataProvider() as ArrayCollection;
		var lastItem:Object=rawData.getItemAt(rawData.length - 1);
		preparePrintData(dataList);
		var dict:Dictionary=new Dictionary();
		dict["主标题"]="其他出库单";
		dict["批发总额"]=lastItem.wholeSaleMoney.toFixed(2);
		dict["零售总额"]=lastItem.retailMoney.toFixed(2);
		dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
		dict["供货单位"]=_materialRdsMaster.salerName;
		dict["仓库"]=storageCode.selectedItem.storageName;
		dict["请领部门"]=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', _materialRdsMaster.deptCode) == null ? "" : ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', _materialRdsMaster.deptCode).deptName;
		dict["出库日期"]=_materialRdsMaster.billDate;
		dict["出库单号"]=_materialRdsMaster.billNo == null ? "" : _materialRdsMaster.billNo;
		dict["表尾第一行"]=createPrintFirstBottomLine(lastItem);
		loadReportXml("report/material/deliver/deliverOther.xml", dataList, dict,printSign)
	}
	
}
/**
 * 设置默认打印机的打印页面
 * */
private function setPrintPageSize():void{
	var lnumWidth:Number=210*1000
	var lnumHeight:Number=parseFloat(ReportParameter.reportPrintHeight_in)
	lnumHeight=isNaN(lnumHeight)?288*1000:lnumHeight*1000 
	ExternalInterface.call("setPrintPageSize",lnumWidth,lnumHeight)
}
private function loadReportXml(reportUrl:String,faryDetails:ArrayCollection, fdict:Dictionary,fprintSign:String):void{
	var loader:UrlLoader=new UrlLoader();
	loader.addEventListener(Event.COMPLETE, function(event:Event):void{
		var xml:XML=XML(event.currentTarget.Data)
		if(ReportParameter.reportPrintHeight_out&&ReportParameter.reportPrintHeight_out!='0'){
			var lreportHeight:String=parseFloat(ReportParameter.reportPrintHeight_out)/10+''
			xml.PageHeight=lreportHeight	
		}		
		if (fprintSign == "1")
		{
			ReportPrinter.Print(xml, faryDetails, fdict);
		}
		else
		{
			ReportViewer.Instance.Show(xml, faryDetails, fdict);
		}
	});
	loader.Load(reportUrl);
}
/**
 * 计算当前页
 * */
private function preparePrintData(faryData:ArrayCollection):void
{
	var rdBillNo:String=""
	var pageNo:int=0;
	for (var i:int=0; i < faryData.length; i++)
	{
		var item:Object=faryData.getItemAt(i);
		if (item.rdBillNo != rdBillNo)
		{
			rdBillNo=item.rdBillNo
			pageNo++;
		}
		item.factoryName=!item.factoryName ? '' : item.factoryName
		item.pageNo=pageNo;
		item.factoryName=item.factoryName.substr(0, 6);
		//item.nameSpec=item.materialName + "  " + (item.materialSpec == null ? "" : item.materialSpec);
	}
}

/**
 * 生成表格尾部首行
 * */
private function createPrintFirstBottomLine(fLastItem:Object):String
{
	var lstrLine:String="领用人:{0}        会计:{1}        审核:{2}        制单:{3}"        ;
	var makerv:String=shiftTo(_materialRdsMaster.maker);
	var verifierv:String=shiftTo(_materialRdsMaster.verifier)
	lstrLine=StringUtils.format(lstrLine, "    ","    ","    ", makerv);
	return lstrLine;
}

/**
 * 生成表格尾部首行三个参数，byzcl
 * */
private function createPrintFirstBottomLine1(verifierName:String,personIdName:String,makerv:String):String
{
	var lstrLine:String="审核人:{0}               请领人:{1}               接收人:{2}               制单:{3}";
	var makerv:String=shiftTo(_materialRdsMaster.maker);
	var verifierv:String=shiftTo(_materialRdsMaster.verifier)
	lstrLine=StringUtils.format(lstrLine,verifierName,personIdName,"    ",makerv);
	return lstrLine;
}

//增加
protected function addClickHandler(event:Event):void
{
	//新增权限
	if (!checkUserRole('01'))
	{
		return;
	}

	//增加按钮
	toolBar.addToPreState()

	//显示输入明细区域
	if(_isDetailRemark){
		bord.height=140;
	}else{
		bord.height=110;   //byzcl 111
	}
	
	hiddenVGroup.includeInLayout=true;
	hiddenVGroup.visible=true;

	//设置可写
	setReadOnly(false);
	//清空当前表单
	clearForm(true, true);
	//表头赋值
	//授权仓库赋值
	if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
	{
//		storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
//		storageCode.selectedIndex=0;
		var result:ArrayCollection =ObjectUtil.copy(AppInfo.currentUserInfo.storageList) as ArrayCollection;
		var newArray:ArrayCollection = new ArrayCollection();
		for each(var it:Object in result){
			if(it.type == '2'||it.type == '3'){
				newArray.addItem(it);
			}
		}
		storageCode.dataProvider=newArray;//AppInfo.currentUserInfo.storageList;
		storageCode.selectedIndex=0;
	}
	rdType.txtContent.text="其它出库";
	_materialRdsMaster.rdFlag='2';
	_materialRdsMaster.rdType='109';
	_materialRdsMaster.operationType='109';
	_materialRdsMaster.currentStatus='0';

	
	_deliverRdsMaster.rdFlag='2';
	_deliverRdsMaster.rdType='209';
	_deliverRdsMaster.invoiceType = blueType.selected ? '1':'2';
	_deliverRdsMaster.operationType='209';
	_deliverRdsMaster.currentStatus='0';
		
		
	//表尾赋值
	maker.text=AppInfo.currentUserInfo.userName;
	makeDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");
	//得到区域
	deptCode.txtContent.setFocus();
	storageCode.enabled=true;
}


//修改
protected function modifyClickHandler(event:Event):void
{
	//判断当前表格是否具有明细数据
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	if (!laryDetails)
	{
		return;
	}

	//当前状态显示的值
	if (_materialRdsMaster.currentStatus == "2")
	{
		Alert.show("该出库单已经审核，不能再修改");
		return;
	}
	if (_materialRdsMaster.currentStatus == "0")
	{
		toolBar.setEnabled(toolBar.btVerify, true);
	}
	else
	{
		toolBar.setEnabled(toolBar.btSave, false);
		toolBar.setEnabled(toolBar.btVerify, false);
	}

	//修改按钮初始化
	toolBar.modifyToPreState();
	//显示输入明细区域
	if(_isDetailRemark){
		bord.height=140;
	}else{
		bord.height=111;   //byzcl 111
	}
	hiddenVGroup.includeInLayout=true;
	hiddenVGroup.visible=true;

	//设置可写
	setReadOnly(false);
	//显示所选择的明细记录
	gdRdsDetail_itemClickHandler(null);
	storageCode.enabled=false;
}


//删除
protected function deleteClickHandler(event:Event):void
{
	//删除权限
	if (!checkUserRole('03'))
	{
		return;
	}

	if (_materialRdsMaster.autoId == "" || (_materialRdsMaster.autoId == null))
	{
		Alert.show("请先查询要删除的出库单！", "提示信息");
		return;
	}

	if (_materialRdsMaster.currentStatus == '1')
	{
		Alert.show("该其它出库单已审核！", "提示信息");
		return;
	}
	else if (_materialRdsMaster.currentStatus == '2')
	{
		Alert.show("该其它出库单已记账！", "提示信息");
		return;
	}

	Alert.show("您确定要删除当前记录？", "提示信息", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
		{
			if (e.detail == Alert.YES)
			{
				var ro:RemoteObject=RemoteUtil.getRemoteObject("rdTogetherImpl", function(rev:Object):void
					{
						Alert.show("删除其它出库单成功！", "提示信息");
						doInit();
						clearForm(true, true);
					});
				ro.deleteRds(_materialRdsMaster.autoId);
			}
		});
}

/**
 * 校验表格中的数量是否大于参数定义的最大数；
 * @param itemsAmount,表格中的数量；
 * @param paramAmount,系统参数表中定义的最大数；
 * */
private function compareAmount(itemsAmount:Number,paramAmount:Number):Number{
	return itemsAmount - paramAmount;
}
//保存
protected function saveClickHandler(event:Event):void
{
	//保存权限
	if (!checkUserRole('04'))
	{
		return;
	}
	if (!validateMaster())
	{
		return;
	}
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	var laryPares:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	if (!laryDetails)
	{
		Alert.show("出库单明细记录不能为空", "提示");
		return;
	}
	//根据系统参数判断是否限制单据数量
	if(isCheckAmount){
		//验证每张单据的最大数
		var itemsAmount:Number = laryDetails.length;
		if(compareAmount(itemsAmount,maxAmount)>0){
			Alert.show("每张单据最大数量不能超过【"+maxAmount+"】条","提示");
			return;
		}
	}
	//处理票面数量,应该放保存时处理
	for each (var item:MaterialRdsDetail in laryDetails){
		item.acctAmount = item.amount;
	}
	//填充主记录
	fillRdsMaster();
	toolBar.btSave.enabled = false;
	//保存当前数据
	var ro:RemoteObject=RemoteUtil.getRemoteObject("rdTogetherImpl", function(rev:Object):void
		{
			if (rev && rev.data[0])
			{
				toolBar.saveToPreState();
				//
				copyFieldsToCurrentMaster(rev.data[0], _materialRdsMaster);
				//
				billNo.text=_materialRdsMaster.billNo;
//				doInit();
				findRdsById(rev.data[1].autoId);
				Alert.show("其它出库单保存成功！", "提示信息");
				return;
			}
		});
	ro.saveRdTogether(_materialRdsMaster, _deliverRdsMaster,laryDetails);
}

/**
 * 点击红蓝单
 * */
protected function redOrBlue_changeHandler(event:Event):void
{
	var laryDetails:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	if(laryDetails.length ==0){
		return	
	}
	Alert.show('切换单据类型将清空页面数据','提示',Alert.YES | Alert.NO,null,function(e:*):void{
		if (e.detail == Alert.YES ){
			//清空页面数据
			FormUtils.clearForm(hg1);
			FormUtils.clearForm(hg2);
			FormUtils.clearForm(detailGroup);
			gdRdsDetail.dataProvider = [];
		}else{
			redOrBlue.selection = event.target.selection == redType?blueType:redType;
		}
	}) 
}
/**
 * 保存前验证主记录
 */
private function validateMaster():Boolean
{
	if (deptCode.txtContent.text == "")
	{
		deptCode.txtContent.setFocus();
		Alert.show("请领部门必填", "提示");
		return false;
	}

	if (salerCode.txtContent.text == "")
	{
		salerCode.txtContent.setFocus();
		Alert.show("供货单位必填", "提示");
		return false;
	}
	
	if (salerCode.txtContent.text == "仓库直供")
	{
		salerCode.txtContent.setFocus();
		Alert.show("其他出库（0库存）不允许选择仓库直供", "提示");
		return false;
	}
	
	if (rdType.txtContent.text == "")
	{
		rdType.txtContent.setFocus();
		Alert.show("出库类型必填", "提示");
		return false;
	}
	return true;
}

/**
 * 填充主记录,作为参数
 * */
private function fillRdsMaster():void
{
	_materialRdsMaster.invoiceType=blueType.selected ? '1' : '2';
	_materialRdsMaster.storageCode=storageCode.selectedItem.storageCode;
	_materialRdsMaster.billNo=billNo.text;
	_materialRdsMaster.billDate=billDate.selectedDate;
	_materialRdsMaster.operationNo=operationNo.text;

	_materialRdsMaster.rdFlag='1';
	_materialRdsMaster.operationType='109';
	_materialRdsMaster.rdType='109';

	_materialRdsMaster.remark=remark.text;
	
	
	//出库记录
	_deliverRdsMaster.invoiceType=blueType.selected ? '1' : '2';
	_deliverRdsMaster.storageCode=storageCode.selectedItem.storageCode;
	_deliverRdsMaster.billNo=billNo.text;
	_deliverRdsMaster.billDate=billDate.selectedDate;
	_deliverRdsMaster.rdFlag="2";
	_deliverRdsMaster.operationType='209';
	_deliverRdsMaster.rdType='209';
	_deliverRdsMaster.remark = remark.text;
//	_deliverRdsMaster.
	
//	_deliverRdsMaster.invoiceDate=billDate.selectedDate;
//	_deliverRdsMaster.operationNo=operationNo.text;
	
}

/**
 * 复制当前数据记录
 */
private function copyFieldsToCurrentMaster(fsource:Object, ftarget:Object):void
{
	ObjectUtils.mergeObject(fsource, ftarget)
}

//放弃
protected function cancelClickHandler(event:Event):void
{
	Alert.show("您是否放弃当前操作吗？", "提示", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
		{
			if (e.detail == Alert.NO)
			{
				return;
			}
			//增加项隐藏
			bord.height=70;
			hiddenVGroup.includeInLayout=false;
			hiddenVGroup.visible=false;

			toolBar.cancelToPreState();
			//清空当前表单
			clearForm(true, true);
			//设置只读
			setReadOnly(true);
		})
}

//审核
protected function verifyClickHandler(event:Event):void
{
	//审核权限
	if (!checkUserRole('06'))
	{
		return;
	}

	//应为后台提供
	_materialRdsMaster.verifier=AppInfo.currentUserInfo.personId;
	_materialRdsMaster.verifyDate=new Date();

	if (_materialRdsMaster.currentStatus == "1")
	{
		Alert.show('该其它出库单已经审核', '提示信息');
		return;
	}

	Alert.show('您是否审核当前其它出库单？', '提示信息', Alert.YES | Alert.NO, null, function(e:*):void
		{
			if (e.detail == Alert.YES)
			{
				var ro:RemoteObject=RemoteUtil.getRemoteObject("rdTogetherImpl", function(rev:Object):void
					{
						//显示输入明细区域
						bord.height=70;
						hiddenVGroup.includeInLayout=false;
						hiddenVGroup.visible=false;
						//设置只读
						setReadOnly(true);
						//赋当前审核状态
						_materialRdsMaster.currentStatus='1';
						//表尾赋值
						verifier.text=AppInfo.currentUserInfo.userName;
						verifyDate.text=DateUtil.dateToString(new Date(), "YYYY-MM-DD");
						findRdsById(rev.data[0].autoId);
						Alert.show("其它出库单审核成功！", "提示信息");
					});
				ro.verifyRds(_materialRdsMaster.autoId);
			}
		})
}

//增行
protected function addRowClickHandler(event:Event):void
{
	materialName.text="";
	materialSpec.text="";
	materialUnits.text="";

	amount.text="";

	batch.text="0";
	detailRemark.text = "";

	materialCode_queryIconClickHandler(null);
}

//删行
protected function delRowClickHandler(event:Event):void
{
	var laryDetails:ArrayCollection=gdRdsDetail.getRawDataProvider() as ArrayCollection;

	var lintMaxIndex:int=laryDetails.length;
	var lintSelIndex:int=gdRdsDetail.selectedIndex;
	if (lintSelIndex < 0 || lintSelIndex > lintMaxIndex - 1)
	{
		return;
	}

	var lRdsDetail:MaterialRdsDetail=gdRdsDetail.selectedItem as MaterialRdsDetail;
	if (!lRdsDetail)
	{
		return;
	}

	//已保存
	var lselIndex:int=gdRdsDetail.selectedIndex;
	if (lselIndex < 0)
	{
		return;
	}
	
	laryDetails.removeItemAt(lintSelIndex);
	if (lintSelIndex == 0)
	{
		lintSelIndex=1;
	}
	gdRdsDetail.selectedIndex=lintSelIndex - 1;
	if((gdRdsDetail.dataProvider.length)<=0)
	{
		storageCode.enabled=true;
	}
	return;
}

//查询
protected function queryClickHandler(event:Event):void
{
	var win:WinReceiveQuery=PopUpManager.createPopUp(this, WinReceiveQuery, true) as WinReceiveQuery;
	win.parentWin=this;
	FormUtils.centerWin(win);
}

//首页
protected function firstPageClickHandler(event:Event):void
{
	//定位到数组第一个
	if (arrayAutoId.length < 1)
	{
		return;
	}
	currentPage=0;
	var strAutoId:String=arrayAutoId[currentPage] as String;
	findRdsById(strAutoId);

	toolBar.firstPageToPreState()
}

//下一页
protected function nextPageClickHandler(event:Event):void
{
	if (arrayAutoId.length < 1)
	{
		return;
	}
	currentPage++;
	if (currentPage >= arrayAutoId.length)
	{
		currentPage=arrayAutoId.length - 1;
	}

	var strAutoId:String=arrayAutoId[currentPage] as String;
	findRdsById(strAutoId);

	toolBar.nextPageToPreState(currentPage, arrayAutoId.length - 1);
}

//上一页
protected function prePageClickHandler(event:Event):void
{
	if (arrayAutoId.length < 1)
	{
		return;
	}
	currentPage--;
	if (currentPage <= 0)
	{
		currentPage=0;
	}

	var strAutoId:String=arrayAutoId[currentPage] as String;
	findRdsById(strAutoId);

	toolBar.prePageToPreState(currentPage);
}

//末页
protected function lastPageClickHandler(event:Event):void
{
	if (arrayAutoId.length < 1)
	{
		return;
	}
	currentPage=arrayAutoId.length - 1;

	var strAutoId:String=arrayAutoId[currentPage] as String;
	findRdsById(strAutoId);

	toolBar.lastPageToPreState();
}

/**
 * 翻页调用此函数
 * */
public function findRdsById(fstrAutoId:String):void
{
	var ro:RemoteObject=RemoteUtil.getRemoteObject("rdTogetherImpl", function(rev:Object):void
		{

			if (rev.data && rev.data.length > 0 && rev.data[0] != null && rev.data[1] != null)
			{
				ObjectUtils.mergeObject(rev.data[0], _deliverRdsMaster)
				var details:ArrayCollection=rev.data[1] as ArrayCollection;
				storageCode.enabled=false;
				if(rev.data.length>2){
					if(rev.data[2]){
						_deliverRdsMaster=rev.data[0] as MaterialRdsMaster;
					}
				}
				
				//主记录赋值
				fillMaster(_materialRdsMaster,_deliverRdsMaster);
				//明细赋值
				gdRdsDetail.dataProvider=details;
				stateButton(rev.data[0].currentStatus);
			}

		});
	ro.findRdTogetherByAutoId(fstrAutoId);
}
/**
 * 弃审按钮
 */ 
protected function toolBar_abandonClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	Alert.show('您是否弃审该张单据？', '提示信息', Alert.YES | Alert.NO, null, function(e:*):void
	{
		if (e.detail == Alert.YES)
		{
			var ro:RemoteObject=RemoteUtil.getRemoteObject("rdTogetherImpl", function(rev:Object):void
			{
				findRdsById(_materialRdsMaster.autoId);
				Alert.show("其它出库单弃审成功！", "提示信息");
			});
			ro.cancelVerifyRds(_materialRdsMaster.autoId);
		}
	})
}

/**
 * 填充表头部分
 */
private function fillMaster(materialRdsMaster:MaterialRdsMaster,deliverMaster:Object):void
{
	FormUtils.fillFormByItem(this, deliverMaster);
	rdType.text=ArrayCollUtils.findItemInArrayByValue(BaseDict.deliverTypeDict, 'deliverType', deliverMaster.rdType) == null ? null : ArrayCollUtils.findItemInArrayByValue(BaseDict.deliverTypeDict, 'deliverType', deliverMaster.rdType).deliverTypeName;
	redOrBlue.selection = deliverMaster.invoiceType == '1'?blueType:redType;
	FormUtils.fillTextByDict(deptCode, deliverMaster.deptCode, 'dept');
	FormUtils.fillTextByDict(personId, deliverMaster.personId, 'personId');
	FormUtils.fillTextByDict(maker, deliverMaster.maker, 'personId');
	FormUtils.fillTextByDict(verifier, deliverMaster.verifier, 'personId');
	
	salerCode.txtContent.text = deliverMaster.salerName;
	//领用科室
	var obj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict,'dept',deliverMaster.deptCode);
//	deliverDept.text=obj==null ? "" : obj.deptName;
	//领用人
	obj=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',deliverMaster.personId);
//	deliverPerson.text=obj==null ? "" : obj.personIdName;
//	
//	deliverRemark.text=deliverMaster.remark;
//	
//	//出库单号
//	deliverBillNo.text=deliverMaster.billNo;
//	deliverbillMonthNo.text=deliverMaster.billMonthNo;
}


/**
 * 批号
 */
private function batchLBF(item:Object, column:DataGridColumn):String
{
	if (item.batch == '0')
	{
		item.batchName='';
	}
	else
	{
		item.batchName=item.batch;
	}
	return item.batchName;
}

/**
 * 品名规格，用以扩展打印需要的字段
 */
private function nameSpecLBF(item:Object, column:DataGridColumn):String
{
	var nameSpec:String=item.materialName/* + (item.materialSpec == null ? "" : item.materialSpec)*/;
	item.nameSpec=nameSpec;
	return "";
}

/**
 * 生产厂家
 */
private function factoryLBF(item:Object, column:DataGridColumn):String
{
	if (item.factoryCode == '')
	{
		item.factoryName='';
	}
	else
	{
		var provider:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict, 'provider', item.factoryCode);

		item.factoryName=provider == null ? "" : provider.providerName;
	}
	return item.factoryName;
}

//退出
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
 * 当前角色权限认证
 */
public static function checkUserRole(role:String):Boolean
{
	//判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, role))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return false;
	}
	return true;
}

/**
 * 更具数据状态显示不同的按钮
 */
protected function stateButton(currentStatus:String):void
{
	var state:Boolean=(currentStatus == "1" ? false : true);
	toolBar.btModify.enabled=state;
	toolBar.btDelete.enabled=state;
	toolBar.btVerify.enabled=state;
	toolBar.btPrint.enabled=!state;
	toolBar.btExp.enabled=!state;
	toolBar.btAbandon.enabled=(currentStatus == "1" ? true : false);
}

// 制单人
protected function shiftTo(name:String):String
{
	var makerItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', name);
	var maker:String=makerItem == null ? "" : makerItem.personIdName;
	return maker;
}

/**
 * 明细备注
 * */
protected function detailRemark_changeHandler(event:TextOperationEvent):void
{
	var lRdsDetail:MaterialRdsDetail=gdRdsDetail.selectedItem as MaterialRdsDetail;
	if (!lRdsDetail)
	{
		return;
	}
	
	lRdsDetail.detailRemark=detailRemark.text;
}

protected function gdRdsDetail_itemEditBeginHandler(event:DataGridEvent):void
{
	var lastIndex:int = gdRdsDetail.dataProvider.length - 1;
	if(lastIndex == event.rowIndex - 1){
		var ss:Boolean = event.cancelable;
		event.preventDefault();
		gdRdsDetail.selectedIndex = lastIndex
	}
}