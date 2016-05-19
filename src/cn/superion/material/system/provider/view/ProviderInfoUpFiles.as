/**
 * 附件操作
 * */
import cn.superion.base.config.AppInfo;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.base.util.UploadRo;
import cn.superion.vo.center.provider.CdProviderFiles;
import cn.superion.vo.notice.CdNotice;
import flash.events.MouseEvent;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.events.CloseEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

[Bindable]
private var upLoadSize:Number=0; //当前已上传的文件个数
[Bindable]
private var _upLoadRo:UploadRo=new UploadRo();
[Bindable]
private var uploadDestination:String="noticeImpl";
[Bindable]
private var saveMethod:String="saveCdNotice"; //服务端保存的方法
[Bindable]
public var noticeInfo:CdNotice;
[Bindable]
private var arrNoticeFiles:ArrayCollection;

/**
 * 附件tab页面初始化加载
 * */
protected function nav_upfile_init():void
{
	_upLoadRo.isMultiUpload=true;
	_upLoadRo.fileCompleteCallback = upLoadCompleteHandler;
	_upLoadRo.maxSize=50 * 1024 * 1024;
	_upLoadRo.maxFilesNum=10;
	this.addEventListener("downloadRow", downloadRowHandler);
	this.addEventListener("delRow", delRowHandler);
}

/**
 *上传事件
 * */
protected function btUpload_clickHandler(event:MouseEvent):void
{
	if(!fileType.selectedItem){
		Alert.show("请选择文件类型！","提示")
		return;
	}
	_upLoadRo.pickfile(uploadDestination, saveMethod, this, null, "*");
}

/**
 *上传完成回调
 * */
private function upLoadCompleteHandler(item:Object):void
{
	upLoadSize+=item.filesize / 1024 / 1024;
	fileName.text = item.filename;
	this.txUploadInfo.text=upLoadSize.toFixed(2) + "M";
	var obj :CdProviderFiles = new CdProviderFiles();
	obj.fileType = fileType.selectedItem.fileType;
	obj.fileName = item.filename;
	obj.data = item.data
	var laryFiles:ArrayCollection=gridFile.getRawDataProvider() as ArrayCollection;
	laryFiles.addItem(obj);
}
private function labFunFileType(item:Object,column:DataGridColumn):String{
	if(item.fileType == '1'){
		return "营业执行附件";
	}
	else if(item.fileType == '2'){
		return "组织代码证附件";
	}
	else return "";
	
}

/**
 * 保存
 * */
private function uploadSaveHandler():void{
	// 01：增加  02：修改  03：删除 04：保存  05：打印  06：审核
	// 07：弃审                08：输出            09：输入
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE,"0301", "04"))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return;
	}
	//提交数据库
	var remoteObj:RemoteObject=RemoteUtil.getRemoteObject(uploadDestination, uploadSaveCallback);
	remoteObj.saveCdNotice(noticeInfo, _upLoadRo._fileDataArray, "add");
}
/**
 * 保存回调
 * */
private function uploadSaveCallback(rev:Object):void
{
	noticeInfo=rev.data[0];
	Alert.show("通知信息保存成功！", "提示信息");
	for each (var item:Object in _upLoadRo._fileDataArray)
	{
		item.hasSaved="1";
	}
}

private function delRowHandler(event:Event):void{
	Alert.show("确认删除吗？","提示",Alert.YES|Alert.NO,this,function(event:CloseEvent):void{
		if(event.detail==Alert.NO){
			return;
		}
		var laryFiles:ArrayCollection=gridFile.getRawDataProvider() as ArrayCollection;
		var lintSelIndex:int=gridFile.selectedIndex
		if(lintSelIndex>=laryFiles.length){
			return;
		}	
		laryFiles.removeItemAt(gridFile.selectedIndex);	
	})
}
protected function downloadRowHandler(event:Event):void
{
	var lproviderFile:CdProviderFiles=gridFile.selectedItem as CdProviderFiles;
	var lstrFilePath:String=lproviderFile.filePath	
	var lstrFileName:String=lproviderFile.fileName
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
	remoteObj.downLoadFile("1",lstrFilePath);	
}

/**
 * 返回
 * */
private function returnHandler():void{
	PopUpManager.removePopUp(this);
}