
import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.GridColumn;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.material.receive.specialValue.view.WinReceiveQuery;
import cn.superion.material.util.DefaultPage;
import cn.superion.material.util.MainToolBar;
import cn.superion.material.util.MaterialDictShower;
import cn.superion.material.util.ReportParameter;
import cn.superion.report.hlib.UrlLoader;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialPatsDetail;
import cn.superion.vo.material.MaterialRdsDetail;
import cn.superion.vo.material.MaterialRdsMaster;
import cn.superion.vo.material.VMaterialPats;
import cn.superion.vo.system.SysUnitInfor;

import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

import spark.events.TextOperationEvent;

registerClassAlias("cn.superion.material.entity.MaterialRdsMaster", cn.superion.vo.material.MaterialRdsMaster);
registerClassAlias("cn.superion.material.entity.MaterialRdsDetail", cn.superion.vo.material.MaterialRdsDetail);

public static const MENU_NO:String="0204";
//服务类
public static const DESTANATION:String="specialValueImpl";


private var _materialRdsMaster:MaterialRdsMaster=new MaterialRdsMaster();
private var _materialRdsDetail:MaterialRdsDetail=new MaterialRdsDetail();

[Bindable]
public var _tempSalerCode:String="";
[Bindable]
public var _tempSalerName:String="";
public var _tempMaterialCode:String="";

public var _beginAccountDate:Date;
public var _endAccountDate:Date;
public var _materialCode:String='';
//是否赠送耗材
public var _isGiveSign:Boolean=false;


/**
 * 初始化当前窗口
 * */
public function doInit():void
{
	if(parentDocument is WinModual){
		parentDocument.title="特殊高值入库";
	}
	
	initPanel();
	setPrintPageToDefault();
	
	var ro:RemoteObject = RemoteUtil.getRemoteObject("unitInforImpl",function(rev:Object):void{
		if(rev.data.length > 0 ){
			for each (var it:SysUnitInfor in rev.data){
				it.label = it.unitsSimpleName;
				it.data = it.unitsCode;
			}
			MaterialDictShower.SYS_UNITS = rev.data;
		}
	});
	ro.findByEndSign("1");
	
	if(MaterialDictShower.isAllUnitsDict)
	{
		MaterialDictShower.getAdvanceDictList();
	}
	
}


/**
 * 面板初始化
 */
private function initPanel():void
{
	initToolBar();
	
	//授权仓库赋值
	if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
	{
		storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
		storageCode.selectedIndex=0;
	}
	
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1, toolBar.btVerify, toolBar.imageList2, toolBar.btQuery, toolBar.imageList5, toolBar.btExit];
	var laryEnables:Array=[toolBar.btExit, toolBar.btQuery, toolBar.btAdd]
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}


/**
 * 回车事件
 **/
private function toNextCtrl(event:KeyboardEvent, fctrlNext:Object):void
{
	if (event.keyCode == Keyboard.ENTER)
	{
		FormUtils.toNextControl(event, fctrlNext);
	}
}
 
//打印
protected function printClickHandler(event:Event):void
{
	printReport("1");
	
}


/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	setPrintPageSize()
	var dataList:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;

	for each(var item:Object in dataList)
	{
		item.materialSpec=item.materialSpec==null ? "" : item.materialSpec;
		item.nameSpec=item.materialName + " " + item.materialSpec;
		item.batch=item.batch==null ? "" : item.batch;
		item.availDateName=item.availDate==null ? "" : DateField.dateToString(item.availDate,'YYYY-MM-DD');
		item.factoryName=item.factoryName==null ? "" : item.factoryName.length > 12 ? (item.factoryName).substr(0,12) : item.factoryName;
	}
	
	var dict:Dictionary=new Dictionary();
	
	dict["主标题"]="特殊高值入库单";
	dict["单位"] = AppInfo.currentUserInfo.unitsName;
	dict["日期"] = new Date();
	
	dict["开始日期"]=DateField.dateToString(_beginAccountDate,'YYYY-MM-DD');
	dict["结束日期"]=DateField.dateToString(_endAccountDate,'YYYY-MM-DD');
	dict["供应商"]=_tempSalerName;
	dict["发票日期"]=invoiceDate.text;
	dict['发票号']=invoiceNo.text;
	dict['制单人']="制单人:"+AppInfo.currentUserInfo.userName;

	var reportUrl:String="report/material/receive/specialValue.xml";
	loadReportXml(reportUrl, dataList, dict,printSign)
}


private function loadReportXml(reportUrl:String,faryDetails:ArrayCollection, fdict:Dictionary,fprintSign:String):void{
	var loader:UrlLoader=new UrlLoader();
	loader.addEventListener(Event.COMPLETE, function(event:Event):void{
		var xml:XML=XML(event.currentTarget.Data)
		if(ReportParameter.reportPrintHeight_in&&ReportParameter.reportPrintHeight_in!='0'){
			var lreportHeight:String=parseFloat(ReportParameter.reportPrintHeight_in)/10+''
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
 * 输出
 */
protected function expClickHandler(event:Event):void
{
	expExcel();
}

private function expExcel():void
{
	var dataList:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
	var newData:ArrayCollection=new ArrayCollection();
	for each(var item:Object in dataList)
	{
		if(item.isSelected)
		{
			newData.addItem(item);
		}
	}
	
	gdRdsDetailVisible.dataProvider=newData;
	
	var details:ArrayCollection=gdRdsDetailVisible.dataProvider as ArrayCollection;
	var cols:Array=gdRdsDetailVisible.columns;
	var excelFile:ExcelFile = new ExcelFile();
	var sheet:Sheet = new Sheet();
	if(details.length==0){
		Alert.show('请选择需要输出的高值耗材','提示');
		return; 
	}
	
	sheet.resize(gdRdsDetailVisible.dataProvider.length+details.length+1,cols.length)
	addExcelHeader(gdRdsDetailVisible,sheet);
	addExcelData(details,sheet);
	excelFile.sheets.addItem(sheet);
	var mbytes:ByteArray = excelFile.saveToByteArray();
	var  file:FileReference=new FileReference()
	var currentDate:String=DateUtil.dateToString(new Date,'YYYY-MM-DD');
	var excelTitle:String=currentDate+'【'+salerName.text+'】特殊高值耗材';
	 
	file.save(mbytes,excelTitle+".xls");
	
	
}

private function addExcelHeader(gridList:Object,fsheet:Sheet):void{
	var cols:Array=gdRdsDetailVisible.columns
	var i:int=0; 
	for (var col:int=0;col<cols.length;col++){
		fsheet.setCell(0,i,cols[col].headerText);
		i++;
	} 
}

private function addExcelData(laryGroupData:ArrayCollection,fsheet:Sheet):void{
	var lintRow:int=1;
	var cols:Array=gdRdsDetailVisible.columns
	for each(var lgroup:Object in laryGroupData)
	{
		for(var i:int=0;i<cols.length;i++)
		{
			if(!lgroup.isTitle && (i==0 || i==1 || i==14) && lgroup[cols[i].dataField])
			{
				fsheet.setCell(lintRow,i,lgroup[cols[i].dataField]+"_" || '');
			}
			else if(cols[i].dataField=='availDate' && lgroup[cols[i].dataField])
			{
				fsheet.setCell(lintRow,i,DateUtil.dateToString(lgroup[cols[i].dataField],'YYYY-MM-DD') || '');
			}
			else
			{
				fsheet.setCell(lintRow,i,lgroup[cols[i].dataField] || '');
			}
		}
		lintRow++;
	}
}


//审核
protected function verifyClickHandler(event:Event):void
{
	//审核权限
	if (!checkUserRole('06'))
	{
		return;
	}

	Alert.show('您确定审核当前特殊高值入库单？', '提示信息', Alert.OK | Alert.CANCEL, null, function(e:*):void
	{
		if (e.detail == Alert.OK)
		{
			var detailList:ArrayCollection=gdRdsDetail.dataProvider as ArrayCollection;
			var larryAutoId:Array=[];
			var larryDetail:ArrayCollection=new ArrayCollection();
			
			if(storageCode.selectedItem == null)
			{
				Alert.show('请选择需要入库的仓库','提示');
				return;
			}
			if(!_isGiveSign && !invoiceDate.text)
			{
				Alert.show('请填写发票日期','提示');
				return;
			}
			var _storageCode:String=storageCode.selectedItem.storageCode;
			for each(var obj:Object in detailList)
			{
				if(obj.isSelected && obj.autoId)
				{
					var patsDetail:VMaterialPats=new VMaterialPats();
					patsDetail=obj as VMaterialPats;
					if(larryAutoId.length==0){
						larryAutoId.push(obj.autoId);
					}
					else
					{
						var flag:Boolean=true;
						for(var i:int=0;i<larryAutoId.length;i++){
							if(obj.autoId ==larryAutoId[i])
							{
								flag=false;
							}
						}
						if(flag){
							larryAutoId.push(obj.autoId);
						}
					}
					obj.invoiceNo=invoiceNo.text;
					if(invoiceDate.text)
					{
						obj.invoiceDate=invoiceDate.selectedDate;
					}
					
					larryDetail.addItem(obj);
					
				}
			}
			
			if(larryDetail.length==0)
			{
				Alert.show('请选择需要审核的耗材明细','提示');
				return
			}
			_materialRdsMaster.storageCode=storageCode.selectedItem.storageCode;
			_materialRdsMaster.salerCode=salerCode.text;
			_materialRdsMaster.salerName=salerName.text;
			
			var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
			{
				if(rev.success)
				{
					Alert.show("特殊高值入库单审核成功！", "提示信息");
					gdRdsDetail.dataProvider=larryDetail;
					toolBar.btVerify.enabled=false;
					toolBar.btPrint.enabled=true;
					toolBar.btExp.enabled=true;
				}
				
			});
			ro.saveMaterialRds(_materialRdsMaster,larryAutoId,larryDetail);
		}
	})
}



//查询
protected function queryClickHandler(event:Event,isAlert:Boolean=true):void
{
	var win:WinReceiveQuery=PopUpManager.createPopUp(this, WinReceiveQuery, true) as WinReceiveQuery;
	win.parentWin=this;
	FormUtils.centerWin(win);
}

/**
 * LabFunction 处理售价显示
 */
private function retailPriceLBF(item:Object, column:DataGridColumn):String
{
	//若存在包装系数，则返回 包装系数 * 包装数量
	if(item.amountPerPackage && item.amountPerPackage!='0'){
		return (item.amountPerPackage * item.retailPrice).toFixed(2);
	}else{
		return item.retailPrice == null ? "":(item.retailPrice).toFixed(2);
	}
}

/**
 * LabFunction 处理批发价显示
 */
private function wholeSalePriceLBF(item:Object, column:DataGridColumn):*
{
	//若存在包装系数，则返回 包装系数 * 包装数量
//	if(item.amountPerPackage && item.amountPerPackage!='0'){
//		return (item.amountPerPackage * item.wholeSalePrice).toFixed(2);
//	}else{
//		return item.wholeSalePrice == null ? "": (item.wholeSalePrice).toFixed(2);;
//	}
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
 * 更具数据状态显示不同的按钮
 */
protected function stateButton(currentStatus:String):void
{
	var state:Boolean=(currentStatus == "0" ? true : false);
	toolBar.btModify.enabled=state;
	toolBar.btDelete.enabled=state;
	toolBar.btVerify.enabled=state;
	toolBar.btPrint.enabled=!state;
	toolBar.btExp.enabled=!state;
	toolBar.btAbandon.enabled=(currentStatus == "1" ? true : false);
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
 * 设置默认打印机的打印页面
 * */
private function setPrintPageSize():void{
	var lnumWidth:Number=210*1000
	var lnumHeight:Number=parseFloat(ReportParameter.reportPrintHeight_in)
	lnumHeight=isNaN(lnumHeight)?288*1000:lnumHeight*1000 
	ExternalInterface.call("setPrintPageSize",lnumWidth,lnumHeight)
}


/**
 * 恢复默认打印机的打印页面
 * */
private function setPrintPageToDefault():void{
	ExternalInterface.call("setPrintPageToDefault")
}

