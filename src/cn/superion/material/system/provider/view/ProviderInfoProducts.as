import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.UploadRo;
import cn.superion.material.util.MainToolBar;
import cn.superion.vo.center.material.CdMaterialDict;
import cn.superion.vo.center.provider.CdProviderMaterial;
import cn.superion.vo.notice.CdNoticeFiles;
import mx.collections.ArrayCollection;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.managers.PopUpManager;

[Bindable]
private var productUpLoadSize:Number=0; //当前已上传的文件个数
[Bindable]
public var _date:Date = new Date();
[Bindable]
private var _productUpLoadRo:UploadRo=new UploadRo();
[Bindable]
private var productDestination:String="noticeImpl";
[Bindable]
private var productSaveMethod:String="saveCdNotice"; //服务端保存的方法
[Bindable]
private var txtItems:Array;
private var i:int = 0;
private var fileNo:String = null;

/**
 * 授权产品部分的操作
 * */


/**
 * 产品列表tab页面初始化加载
 * */
protected function nav_product_init():void
{
	//当前已定义的文本
	_productUpLoadRo.isMultiUpload=true;
	_productUpLoadRo.fileCompleteCallback=productUpLoadCompleteHandler;
	_productUpLoadRo.maxSize=50 * 1024 * 1024;
	_productUpLoadRo.maxFilesNum=10;
//	this.addEventListener("downloadRow", downloadRowHandler);
}

/**
 * 自动完成表格回调,同时验证重复数据
 * */
private function showItemDict(rev:Object):void
{
	//若用双向绑定,则必须给对象的类加Bindable关键字，才可以让IEventDispatcher监听到。
	var item:CdMaterialDict = rev as CdMaterialDict;
	MainToolBar.convertItem(gridProduct,item,['materialClass','materialCode']);
	retailPrice.text = rev.tradePrice==0?'':rev.tradePrice;
	invitedPrice.text = "";
	materialName.text = rev.materialName;
	materialSpec.text = rev.materialSpec;
	materialUnits.text = rev.materialUnits;
	//
	invitedPrice.setFocus();
}
/**
 * LabFunction 物资分类
 * */
private function labFunMaterialClass(o:Object,column:DataGridColumn):String{
	var it:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.materialClassDict,'materialClass',o.materialClass);
	if(it) return it.materialClassName;
	return "";
}

/**
 * LabFunction 生产厂家
 * */
private function labFunFactoryCode(o:Object,column:DataGridColumn):String{
	var it:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.factoryDict,'factory',o.factoryName);
	if(it) return it.factoryName;
	return "";
}
/**
 *上传事件
 * */
protected function productBtUpload_clickHandler(event:MouseEvent,s:String):void
{
	if(!gridProduct.selectedItem){
		return;
	}
	fileNo = s;
	_productUpLoadRo.pickfile(productDestination, productSaveMethod, this, null, "*");
}

/**
 *上传完成回调
 * */
private function productUpLoadCompleteHandler(item:Object):void
{
	productUpLoadSize += item.filesize / 1024 / 1024;
	this.productTxtUploadInfo.text=productUpLoadSize.toFixed(2) + "M";
	if(fileNo=='0'){
		txUpload1.text=item.filename;
		gridProduct.selectedItem["data1"] = item.data;
		gridProduct.selectedItem.accreditFileName1 = item.filename;
			
	}
	if(fileNo=='1'){
		txUpload2.text=item.filename;
		gridProduct.selectedItem["data2"] = item.data;
		gridProduct.selectedItem.accreditFileName2 = item.filename;
	}
	if(fileNo=='2'){
		txUpload3.text=item.filename;
		gridProduct.selectedItem["data3"] = item.data;
		gridProduct.selectedItem.accreditFileName3 = item.filename;
	}
}
/**
 * 保存回调
 * */
private function productUploadSaveCallback(rev:Object):void
{
	noticeInfo=rev.data[0];
	Alert.show("通知信息保存成功！", "提示信息");
	for each (var item:Object in _productUpLoadRo._fileDataArray)
	{
		item.hasSaved="1";
	}
}

protected function productBtDownload1_clickHandler():void
{
	if (arrNoticeFiles == null || arrNoticeFiles.length <= 0)
	{
		return;
	}
	var cdNoticeFile:CdNoticeFiles=arrNoticeFiles[0];
	var remoteObj:RemoteObject=RemoteUtil.getRemoteObject(uploadDestination, function(rev:Object):void
	{
		//
		var fileData:Object=rev.data[0];
		var _fileName:String=gridFile.selectedItem.fileName;
		
		Alert.show("下载完成，要保存到您的计算机中吗？", "提示", Alert.YES | Alert.NO, null, function(e:*):void
		{
			if (e.detail == Alert.YES)
			{
				var fileReference:FileReference=new FileReference();
				fileReference.save(fileData, _fileName);
			}
		});
		
	});
	remoteObj.downLoadFile(cdNoticeFile);
}

protected function btDelFile_clickHandler(event:MouseEvent,s:String):void
{
	fileNo = s;
	if(fileNo=='0'){
		if(txUpload1.text.length ==0)return;
		txUpload1.text="";
		_productUpLoadRo._fileDataArray.splice(0, 1);
		_productUpLoadRo.currentFilesNum--;
		if (_productUpLoadRo.currentFilesNum < 0)
		{
			_productUpLoadRo.currentFilesNum=0;
		}
	}
	if(fileNo=='1'){
		if(txUpload2.text.length ==0)return;
		txUpload2.text="";
		_productUpLoadRo._fileDataArray.splice(0, 1);
		
		_productUpLoadRo.currentFilesNum--;
		if (_productUpLoadRo.currentFilesNum < 0)
		{
			_productUpLoadRo.currentFilesNum=0;
		}
	}
	if(fileNo=='2'){
		if(txUpload3.text.length ==0)return;
		txUpload3.text="";
		_productUpLoadRo._fileDataArray.splice(0, 1);
		
		_productUpLoadRo.currentFilesNum--;
		if (_productUpLoadRo.currentFilesNum < 0)
		{
			_productUpLoadRo.currentFilesNum=0;
		}
	}
	if(!_productUpLoadRo.fileData){
		return
	}
	var ss:Number = _productUpLoadRo.fileData.filesize;
	productUpLoadSize -= ss/1024/1024;
	productUpLoadSize.toFixed(2);
	this.productTxtUploadInfo.text=productUpLoadSize.toFixed(2) + "M";//		}
}

protected function btDelFile2_clickHandler(event:MouseEvent):void
{
	// TODO Auto-generated method stub
	//判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	/*if (!PurviewUtil.getPurview(AppInfo.APP_CODE, "0902", "03"))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}*/
	
	//新增
	if (arrNoticeFiles == null || arrNoticeFiles.length <= 0)
	{
		if (txUpload2.text != "")
		{
			txUpload2.text="";
			_productUpLoadRo._fileDataArray.splice(1, 1);
			
			_productUpLoadRo.currentFilesNum--;
			if (_productUpLoadRo.currentFilesNum < 0)
			{
				_productUpLoadRo.currentFilesNum=0;
			}
		}
	}
	else
	{
		//修改
		if (txUpload2.text == "" || txUpload2.text == null)
		{
			return;
		}
		if (arrNoticeFiles.length <= 1)
		{
			return;
		}
		_productUpLoadRo.currentFilesNum--;
		if (_productUpLoadRo.currentFilesNum < 0)
		{
			_productUpLoadRo.currentFilesNum=0;
		}
		
		var cdNoticeFile:CdNoticeFiles=arrNoticeFiles[1];
		
		var remoteObj:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
		{
			txUpload2.text="";
			Alert.show("删除文件成功!", "提示");
		});
		remoteObj.delNoticeFile(cdNoticeFile);
	}
}


protected function btDelFile3_clickHandler(event:MouseEvent):void
{
	// TODO Auto-generated method stub
	//判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	/*if (!PurviewUtil.getPurview(AppInfo.APP_CODE, "0902", "03"))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	*/
	//新增
	if (arrNoticeFiles == null || arrNoticeFiles.length <= 0)
	{
		if (txUpload3.text != "")
		{
			txUpload3.text="";
			_productUpLoadRo._fileDataArray.splice(2, 1);
			
			_productUpLoadRo.currentFilesNum--;
			if (_productUpLoadRo.currentFilesNum < 0)
			{
				_productUpLoadRo.currentFilesNum=0;
			}
		}
	}
	else
	{
		//修改
		if (txUpload3.text == "" || txUpload3.text == null)
		{
			return;
		}
		if (arrNoticeFiles.length <= 2)
		{
			return;
		}
		_productUpLoadRo.currentFilesNum--;
		if (_productUpLoadRo.currentFilesNum < 0)
		{
			_productUpLoadRo.currentFilesNum=0;
		}
		
		var cdNoticeFile:CdNoticeFiles=arrNoticeFiles[2];
		var remoteObj:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
		{
			txUpload3.text="";
			Alert.show("删除文件成功!", "提示");
		});
		remoteObj.delNoticeFile(cdNoticeFile);
	}
}

protected function btDownload_clickHandler(event:MouseEvent):void
{
	var btId:String=event.target.id
	var lstrBtIndex:String=btId.substr(btId.length-1,1)
	var lproviderMaterial:CdProviderMaterial=gridProduct.selectedItem as CdProviderMaterial;
	if(lproviderMaterial==null){
		return;
	}
	var lstrFilePath:String=lproviderMaterial["accreditFilePath"+lstrBtIndex]	
	var lstrFileName:String=lproviderMaterial["accreditFileName"+lstrBtIndex]
	if(!lstrFilePath){
		return
	}
	var remoteObj:RemoteObject=RemoteUtil.getRemoteObject(destination, function(rev:Object):void
	{
		var fileData:Object=rev.data[0];
		Alert.show("下载完成，要保存到您的计算机中吗？", "提示", Alert.YES | Alert.NO, null, function(e:*):void
		{
			if (e.detail == Alert.YES)
			{
				var fileReference:FileReference=new FileReference();
				fileReference.save(fileData, lstrFileName);
			}
		});
		
	});
	remoteObj.downLoadFile("2",lstrFilePath);
}

/**
 * 删除
 * */
protected function author_btDelete_clickHandler():void
{
	var ss:ArrayCollection = gridProduct.dataProvider as ArrayCollection;
}
protected function btDelProductRow_clickHandler(event:MouseEvent):void
{
	var lintSelIndex:int=gridProduct.selectedIndex;
	if(lintSelIndex<0){
		return
	}	
	Alert.show("确认删除吗？","提示",Alert.YES|Alert.NO,this,function(event:CloseEvent):void{
		if(event.detail==Alert.NO){
			return;
		}
		var laryProducts:ArrayCollection=gridProduct.getRawDataProvider() as ArrayCollection
		if(lintSelIndex>=laryProducts.length){
			return;
		}
		laryProducts.removeItemAt(lintSelIndex);
		if(laryProducts.length==1){
			lintSelIndex=0;
		}
		gridProduct.selectedIndex=lintSelIndex
	})	
}

/**
 * 返回
 * */
protected function author_btReturn_clickHandler():void
{
	PopUpManager.removePopUp(this);
}



