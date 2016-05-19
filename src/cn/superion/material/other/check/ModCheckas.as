

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
import cn.superion.material.other.check.view.CheckQueryCon;
import cn.superion.material.other.check.view.CheckStorage;
import cn.superion.material.receive.receive.view.WinReceiveQuery;
import cn.superion.material.util.DefaultPage;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialCheckDetail;
import cn.superion.vo.material.MaterialCheckMaster;
import cn.superion.vo.material.MaterialRdsDetail;
import cn.superion.vo.material.MaterialRdsMaster;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.controls.Text;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

import org.alivepdf.layout.Format;

import spark.events.TextOperationEvent;

registerClassAlias("cn.superion.material.entity.MaterialCheckDetail", cn.superion.vo.material.MaterialCheckDetail);
registerClassAlias("cn.superion.material.entity.MaterialCheckMaster", cn.superion.vo.material.MaterialCheckMaster);

public static const MENU_NO:String="0402";
//服务类
public static const DESTANATION:String="checkImpl";

private var _winY:int=0;

//当前主记录
private var _materialCheckMaster:MaterialCheckMaster=new MaterialCheckMaster();

//是否批号管理
private var _bathSign:Boolean;

//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;

/**
 * 初始化当前窗口
 * */
public function doInit():void
{
	initPanel();
	initToolBar();
	fillCombox();
}

/**
 * 面板初始化
 */
private function initPanel():void
{
	//设置只读
	setReadOnly(false);
	//阻止表单输入
	preventDefaultForm();
	inRdType.width=storageCode.width;
	deptCode.width=billNo.width;
	personId.width=billDate.width;
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1, toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, toolBar.btSave, toolBar.btVerify, toolBar.btStorage, toolBar.imageList2, toolBar.btAddRow, toolBar.btDelRow, toolBar.imageList3, toolBar.imageList5, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.btQuery, toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array=[toolBar.btAdd, toolBar.btQuery, toolBar.btExit];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	FormUtils.setFormItemEditable(allPanel, boolean);
	addPanel.includeInLayout=boolean;
	addPanel.visible=boolean;
	storageCode.enabled=boolean;
	outRdType.enabled=boolean;
	inRdType.enabled=boolean;
	masterPanel.enabled=boolean;
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
}

/**
 * 清空表单
 */
public function clearForm(masterFlag:Boolean, detailFlag:Boolean):void
{
	if (masterFlag)
	{
		//清空主记录
		clearMaster();
	}
	if (detailFlag)
	{
		//清空明细
		clearDetail();
	}
}

/**
 * 清空明细
 */
private function clearDetail():void
{
	materialCode.text="";
	materialName.text="";
	materialSpec.text="";
	materialUnits.text="";
	checkAmount.text="";
	batch.text="";
	availDate.selectedDate=new Date();
}

/**
 * 清空主记录
 */
public function clearMaster():void
{

	billNo.text="";
	deptCode.txtContent.text="";
	personId.txtContent.text="";
	remark.text="";
	storageCode.selectedIndex=0;
	inRdType.selectedIndex=0;
	outRdType.selectedIndex=0;
	gdDetails.dataProvider=null;
	accountDate.selectedDate=new Date();
	billDate.selectedDate=new Date();
	_materialCheckMaster=new MaterialCheckMaster();
}


/**
 * 回车事件
 **/
private function toNextControl(event:KeyboardEvent, fctrlNext:Object):void
{
	FormUtils.toNextControl(event, fctrlNext);
}

/**
 * 物资编码回车事件
 */
protected function materialCode_keyDownHandler(event:KeyboardEvent):void
{
	// TODO Auto-generated method stub
	if (event.keyCode == Keyboard.ENTER)
	{
		materialCode_queryIconClickHandler(event)
	}
}

/**
 * 有效期至回车事件
 */
protected function availDate_keyDownHandler(event:KeyboardEvent):void
{
	// TODO Auto-generated method stub
	if (event.keyCode == Keyboard.ENTER)
	{
		materialCode.text="";
		materialCode.txtContent.setFocus();
	}
}

/**
 * 放大镜输入框键盘处理方法
 * */
protected function textInputIcon_keyUpHandler(event:KeyboardEvent, fctrNext:Object):void
{
	FormUtils.textInputIconKeyUpHandler(event, _materialCheckMaster, fctrNext);
}

/**
 * 击事件，对该条记录进行修改
 * */
protected function gdDetails_clickHandler(event:Event):void
{
	if (gdDetails.selectedItem)
	{
		FormUtils.fillFormByItem(addPanel, gdDetails.selectedItem);
		checkAmount.setFocus();
	}
}

/**
 * 部门档案
 */
protected function deptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showDeptDict(function(rev:Object):void
		{
			deptCode.txtContent.text=rev.deptName;
			_materialCheckMaster.deptCode=rev.deptCode;
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
			_materialCheckMaster.personId=rev.personId;
		}, x, y);
}

/**
 * 填充下拉框
 * */
private function fillCombox():void
{
	// 出库类型
	var newRdType:ArrayCollection=ObjectUtil.copy(BaseDict.deliverTypeDict) as ArrayCollection;
	if (newRdType != null)
	{
		newRdType.removeItemAt(0);
	}
	outRdType.dataProvider=newRdType;
	// 入库类型
	var newInRdType:ArrayCollection=ObjectUtil.copy(BaseDict.receviceTypeDict) as ArrayCollection;
	if (newInRdType != null)
	{
		newInRdType.removeItemAt(0);
	}
	inRdType.dataProvider=newInRdType;
	storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
	storageCode.selectedIndex=0;
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

	DictWinShower.showMaterialDictNew(lstorageCode, '', '', true, function(fItem:Array):void
		{
			fillIntoGrid(fItem);
		}, x, y);
}


/**
 * 自动完成表格回调
 * */
private function fillIntoGrid(fItem:Array):void
{
	var laryDetails:ArrayCollection=gdDetails.dataProvider as ArrayCollection;

	for(var i:int=0;i<fItem.length;i++)
	{
		var lnewlDetail:MaterialCheckDetail=new MaterialCheckDetail();
		lnewlDetail.serialNo=0;
		//物资分类
		lnewlDetail.materialClass=fItem[i].materialClass;
		//条形码
		lnewlDetail.barCode=fItem[i].barCode;
		//物资ID
		lnewlDetail.materialId=fItem[i].materialId;
		//物资编码
		lnewlDetail.materialCode=fItem[i].materialCode;
		//物资名称
		lnewlDetail.materialName=fItem[i].materialName;
		//规格型号
		lnewlDetail.materialSpec=fItem[i].materialSpec;
		//单位
		lnewlDetail.materialUnits=fItem[i].materialUnits;
		//账面数量
		lnewlDetail.amount=fItem[i].amount;
		//盘点数量
		lnewlDetail.checkAmount= lnewlDetail.amount; //默认为账面数量
		//进价
		lnewlDetail.tradePrice=fItem[i].tradePrice;
		//进价金额
		lnewlDetail.tradeMoney=0;
		//售价
		lnewlDetail.retailPrice=fItem[i].retailPrice;
		//售价金额
		lnewlDetail.retailMoney=0;
		//生产厂家
		lnewlDetail.factoryCode=fItem[i].factoryCode;
		//批号
		lnewlDetail.batch=fItem[i].batchSign;
		//盘点数量
		lnewlDetail.outAmount=0;
		//待入数量
		lnewlDetail.inAmount=0;
		//生产日期
		lnewlDetail.madeDate=fItem[i].madeDate;
		//有效日期
		lnewlDetail.availDate=availDate.selectedDate;
		laryDetails.addItem(lnewlDetail);
	}

	gdDetails.dataProvider=laryDetails;
	gdDetails.selectedItem=lnewlDetail;
	fillDetailForm(lnewlDetail);
	storageCode.enabled=false;
	var timer:Timer=new Timer(100, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
		{
			gdDetails.selectedIndex=gdDetails.dataProvider.length - 1;
			checkAmount.setFocus();
		})
	timer.start();
}

/**
 * 明细表单赋值
 */
private function fillDetailForm(fselDetailItem:Object):void
{
	if (!fselDetailItem)
	{
		return;
	}
	materialCode.txtContent.text=fselDetailItem.materialCode;
	materialName.text=fselDetailItem.materialName;
	materialSpec.text=fselDetailItem.materialSpec;
	materialUnits.text=fselDetailItem.materialUnits;
	batch.text=fselDetailItem.batch;
}

/**
 * 数量进行改变事件
 */
private function changeHandler(event:Event):void
{
//	Alert.show("字符串长度"+ checkAmount.text.length ,"提示");
	var strn:String=checkAmount.text;
	var strm1:String="";
	for(var i:int=0;i<strn.length;i++)
	{
		if(i==0)
		{
			strm1=strm1.concat(strn.charAt(i));
		}
		else
		{
			if(strn.charAt(i)!="-")
			{
				strm1=strm1.concat(strn.charAt(i));
			}
		}
	}
	if (gdDetails.selectedItem)
	{
		var amount:Number=Number(checkAmount.text);
		gdDetails.selectedItem.tradeMoney=amount * gdDetails.selectedItem.tradePrice;
		gdDetails.selectedItem.retailMoney=amount * gdDetails.selectedItem.retailPrice;
		gdDetails.selectedItem.availDate=availDate.selectedDate;
		gdDetails.selectedItem.checkAmount=Number(strm1=="-"?0:strm1);
		gdDetails.selectedItem.batch=batch.text;
//		FormUtils.changHandler(event, gdDetails.selectedItem)
		gdDetails.invalidateList();
		return;
	}
}

/**
 * 打印
 */
protected function printClickHandler(event:Event):void
{
	printReport("1");

}

/**
 * 输出
 */
protected function expClickHandler(event:Event):void
{
	printReport("0");

}

/**
 * 拼装打印数据，并计算页码
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
		item.packageSpec=item.packageSpec == null ? "" : item.packageSpec;
		item.packageUnits=item.packageUnits == null ? "" : item.packageUnits;
		item.materialSpec=item.materialSpec == null ? "" : item.materialSpec;
		item.nameSpec=item.materialName + " " + (item.materialSpec == null ? "" : item.materialSpec)+" "+(item.factoryName==null?"":item.factoryName);
	}
}

/**
 * 生成表格尾第二行
 * */
private function createPrintSecondBottomLine(fLastItem:Object):String
{
	var lstrLine:String="                                                                 审核：{0}                 制单：{1}";
	lstrLine=StringUtils.format(lstrLine, verifier.text, maker.text)
	return lstrLine;
}

/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	var checkListPrintItems:ArrayCollection=gdDetails.dataProvider as ArrayCollection;
	var dict:Dictionary=new Dictionary();
	preparePrintData(checkListPrintItems);
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="库存盘点单";
	dict["制表人"]=AppInfo.currentUserInfo.userName;
	dict["仓库"]=storageCode.selectedItem.storageName
	dict["单号"]=billNo.text
	dict["盘点日期"]=billDate.text
	dict["部门"]=deptCode.text
	dict["经手人"]=personId.text
	dict["入库类别"]=inRdType.selectedItem.receviceTypeName
	dict["出库类别"]=outRdType.selectedItem.receviceTypeName
	dict["备注"]=remark.text
	dict["制单人"]=maker.text;
	dict["审核人"]=verifier.text;

	var lstrReportFile:String="report/material/other/checkList.xml";
	if (printSign == '1')
	{
		ReportPrinter.LoadAndPrint(lstrReportFile, checkListPrintItems, dict);
	}
	else
	{
		ReportViewer.Instance.Show(lstrReportFile, checkListPrintItems, dict);
	}
}

/**
 * 增加
 */
protected function addClickHandler(event:Event):void
{
	//新增权限
	if (!checkUserRole('01'))
	{
		return;
	}
	allPanel.enabled=true;
	//增加按钮
	toolBar.addToPreState()
	toolBar.btStorage.enabled=true;
	//设置可写
	setReadOnly(true);
	//清空当前表单
	clearForm(true, true);
	materialCode.txtContent.setFocus();
}


/**
 * 修改
 */
protected function modifyClickHandler(event:Event):void
{
	//判断当前表格是否具有明细数据
	var laryDetails:ArrayCollection=gdDetails.dataProvider as ArrayCollection;
	if (!laryDetails)
	{
		return;
	}

	//当前状态显示的值
	if (_materialCheckMaster.currentStatus == "2")
	{
		Alert.show("该库存盘点单已经审核，不能再修改");
		return;
	}

	//修改按钮初始化
	toolBar.modifyToPreState();
	//设置可写
	setReadOnly(true);
	storageCode.enabled=false;
}


/**
 * 删除
 */
protected function deleteClickHandler(event:Event):void
{
	//删除权限
	if (!checkUserRole('03'))
	{
		return;
	}

	if (_materialCheckMaster.autoId == "" || (_materialCheckMaster.autoId == null))
	{
		Alert.show("请先查询要删除的库存盘点！", "提示信息");
		return;
	}

	if (_materialCheckMaster.currentStatus == '1')
	{
		Alert.show("库存盘点单已审核！", "提示信息");
		return;
	}
	else if (_materialCheckMaster.currentStatus == '2')
	{
		Alert.show("库存盘点单已记账！", "提示信息");
		return;
	}

	Alert.show("您确定要删除当前记录？", "提示信息", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
		{
			if (e.detail == Alert.YES)
			{
				var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
					{
						Alert.show("删除库存盘点单成功！", "提示信息");
						doInit();
						//清空当前表单
						clearForm(true, true);
					});
				ro.delCheck(_materialCheckMaster.autoId);
			}
		});
}


/**
 * 保存
 */
protected function saveClickHandler(event:Event):void
{
	//保存权限
	if (!checkUserRole('04'))
	{
		return;
	}
	var laryDetails:ArrayCollection=gdDetails.dataProvider as ArrayCollection;
	if (!laryDetails)
	{
		Alert.show("库存盘点明细记录不能为空", "提示");
		return;
	}
	//填充主记录
	fillRdsMaster();
	//保存当前数据
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{
			if (rev && rev.data[0])
			{
				doInit();
				findRdsById(rev.data[0].autoId);
				Alert.show("库存盘点保存成功！", "提示信息");
				return;
			}
		});
	ro.saveCheck(_materialCheckMaster, laryDetails);
}

/**
 * 保存前验证
 */
private function validateMaster():Boolean
{
	var stat:Boolean=true;
	var arryList:ArrayCollection=new ArrayCollection();
	arryList=gdDetails.dataProvider as ArrayCollection;
	for (var i:int; i < arryList.length; i++)
	{
		if (arryList[i].checkAmount <= 0)
		{
			Alert.show("盘点数量小于一！", "提示", Alert.YES, null, function(e:CloseEvent):void
				{
					if (e.detail == Alert.YES)
					{
						gdDetails.selectedIndex=i;
						checkAmount.setFocus();
					}
				})
			stat=false;
			return false;
		}
	}
	return stat;
}

/**
 * 填充主记录,作为参数
 * */
private function fillRdsMaster():void
{
	// 仓库
	_materialCheckMaster.storageCode=storageCode.selectedItem.storageCode;
	// 盘点单号
	_materialCheckMaster.billNo=billNo.text;
	// 盘点日期
	_materialCheckMaster.billDate=billDate.selectedDate;
	// 账面日期
	_materialCheckMaster.accountDate=accountDate.selectedDate;
	// 入库类别
	_materialCheckMaster.inRdType=inRdType.selectedItem.receviceType
	// 出库类别
	_materialCheckMaster.outRdType=outRdType.selectedItem.deliverType
	// 备注
	_materialCheckMaster.remark=remark.text;
}

/**
 * 复制当前数据记录
 */
private function copyFieldsToCurrentMaster(fsource:Object, ftarget:Object):void
{
	ObjectUtils.mergeObject(fsource, ftarget)
}

/**
 * 放弃
 */
protected function cancelClickHandler(event:Event):void
{
	Alert.show("您是否放弃当前操作吗？", "提示", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
		{
			if (e.detail == Alert.NO)
			{
				return;
			}
			toolBar.btStorage.enabled=false;
			doInit();
			//清空当前表单
			clearForm(true, true);
		})
}

/**
 * 审核
 */
protected function verifyClickHandler(event:Event):void
{
	//审核权限
	if (!checkUserRole('06'))
	{
		return;
	}

	//应为后台提供
	_materialCheckMaster.verifier=AppInfo.currentUserInfo.personId;
	_materialCheckMaster.verifyDate=new Date();

	if (_materialCheckMaster.currentStatus == "1")
	{
		Alert.show('库存盘点单已经审核', '提示信息');
		return;
	}

	Alert.show('您是否审核当前库存盘点？', '提示信息', Alert.YES | Alert.NO, null, function(e:*):void
		{
			if (e.detail == Alert.YES)
			{
				var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
					{
						setReadOnly(false);
						findRdsById(rev.data[0].autoId);
						Alert.show("库存盘点审核成功！", "提示信息");
					});
				ro.verifyCheck(_materialCheckMaster.autoId);
			}
		})
}

/**
 * 增行
 */
protected function addRowClickHandler(event:Event):void
{
	materialCode_queryIconClickHandler(event)
}

/**
 * 删行
 */
protected function delRowClickHandler(event:Event):void
{
	if (!gdDetails.selectedItem)
	{
		return;
	}

	//光标所在位置
	var laryDetails:ArrayCollection=gdDetails.dataProvider as ArrayCollection;
	var i:int=laryDetails.getItemIndex(gdDetails.selectedItem);
	laryDetails.removeItemAt(i);
	gdDetails.dataProvider=laryDetails;
	gdDetails.invalidateList();
	gdDetails.selectedIndex=gdDetails.dataProvider.length - 1;
	gdDetails.selectedIndex=i == 0 ? 0 : (i - 1);
	FormUtils.fillFormByItem(addPanel, gdDetails.selectedItem);
	if((gdDetails.dataProvider.length)<=0)
	{
		storageCode.enabled=true;
	}
}

/**
 * 查询
 */
protected function queryClickHandler(event:Event):void
{
	var queryWin:CheckQueryCon=PopUpManager.createPopUp(this, CheckQueryCon, true) as CheckQueryCon;
	queryWin.data={parentWin: this};
	PopUpManager.centerPopUp(queryWin);
}

/**
 * 盘库事件响应方法
 * */
protected function btToolBar_storageClickHandler(event:Event):void
{
	var storageWin:CheckStorage=PopUpManager.createPopUp(this, CheckStorage, true) as CheckStorage;
	storageWin.data={parentWin: this};
	PopUpManager.centerPopUp(storageWin);
}

/**
 * 首页
 */
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

/**
 * 下一页
 */
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

/**
 * 上一页
 */
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

/**
 * 末页
 */
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
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
		{

			if (rev.data && rev.data.length > 0 && rev.data[0] != null && rev.data[1] != null)
			{
				_materialCheckMaster=rev.data[0] as MaterialCheckMaster;
				;
				var details:ArrayCollection=rev.data[1] as ArrayCollection;

				//主记录赋值
				fillMaster(_materialCheckMaster);
				//明细赋值
				gdDetails.dataProvider=details;
				stateButton(rev.data[0].currentStatus);
			}

		});
	ro.findCheckDetailList(fstrAutoId);
}


/**
 * 填充表头部分
 */
private function fillMaster(fmaterialCheckMaster:MaterialCheckMaster):void
{
	FormUtils.fillFormByItem(allPanel, fmaterialCheckMaster);
	// 仓库
	if (fmaterialCheckMaster.storageCode != null)
	{
		FormUtils.selectComboItem(storageCode, 'storageCode', fmaterialCheckMaster.storageCode);
	}
	if (fmaterialCheckMaster.outRdType != null)
	{
		// 出库类别
		FormUtils.selectComboItem(outRdType, 'outRdType', fmaterialCheckMaster.outRdType);
	}
	if (fmaterialCheckMaster.inRdType != null)
	{
		// 入库类别
		FormUtils.selectComboItem(inRdType, 'inRdType', fmaterialCheckMaster.inRdType);
	}
	if (fmaterialCheckMaster.deptCode != null)
	{
		// 部门
		var deptItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict, 'dept', fmaterialCheckMaster.deptCode);
		deptCode.text=deptItem == null ? "" : deptItem.deptName;
	}
	if (fmaterialCheckMaster.personId != null)
	{
		// 经手人
		var personItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', fmaterialCheckMaster.personId);
		personId.text=personItem == null ? "" : personItem.personIdName;
	}
	if (fmaterialCheckMaster.maker != null)
	{
		// 制单人
		var makerItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', fmaterialCheckMaster.maker);
		maker.text=makerItem == null ? "" : makerItem.personIdName;
	}
	if (fmaterialCheckMaster.verifier != null)
	{
		// 审核人
		var verifierItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', fmaterialCheckMaster.verifier);
		verifier.text=verifierItem == null ? "" : verifierItem.personIdName
	}
	if (fmaterialCheckMaster.storageCode != null)
	{
		FormUtils.selectComboItem(storageCode, 'storageCode', fmaterialCheckMaster.storageCode);
	}
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
	var state:Boolean=(currentStatus == "1" ? false : true);
	toolBar.btModify.enabled=state;
	toolBar.btDelete.enabled=state;
	toolBar.btVerify.enabled=state;
	toolBar.btPrint.enabled=!state;
	toolBar.btExp.enabled=!state;
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

/**
 * 退出
 */
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