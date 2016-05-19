package cn.superion.material.util
{
	import cn.superion.base.util.LoadModuleUtil;
	
	import mx.collections.ArrayCollection;
	import mx.controls.DateField;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.core.FlexGlobals;
	import mx.modules.ModuleLoader;
	import com.as3xls.xls.ExcelFile;
	import flash.utils.ByteArray;
	import flash.net.FileReference;
	import com.as3xls.xls.Sheet;

	public class DefaultPage
	{
		public function DefaultPage()
		{
		}

		//回到缺省主页面，供各分模块中的返回调用
		public static function gotoDefaultPage():void
		{
			var url:String='cn/superion/material/main/view/ModMainRight.swf';
			LoadModuleUtil.loadCurrentModule(ModuleLoader(FlexGlobals.topLevelApplication.mainWin.mainFrame), url, FlexGlobals.topLevelApplication.mainWin.modPanel);
		}
		
		public static function exportExcel(dataGridName:Object,rptHeaderName:String):void{
			
			var laryDataList:ArrayCollection=new ArrayCollection();
			var cols:Array=[];
			var excelFile:ExcelFile = new ExcelFile();
			var sheet:Sheet = new Sheet();
			laryDataList = dataGridName.dataProvider as ArrayCollection;
			cols=dataGridName.columns;
			sheet.resize(dataGridName.dataProvider.length+1,cols.length);
			addExcelHeader(dataGridName,sheet);
			addExcelData(laryDataList,sheet,dataGridName);
			excelFile.sheets.addItem(sheet);
			var mbytes:ByteArray = excelFile.saveToByteArray();
			var  file:FileReference=new FileReference();
			var _currentDate:String=DateField.dateToString(new Date(),'YYYY-MM-DD');
			var excelTitle:String=rptHeaderName+_currentDate;
			file.save(mbytes,excelTitle+".xls");
		}
		public static function addExcelHeader(dataList:Object,fsheet:Sheet):void{   
			var cols:Array=dataList.columns;	
			var i:int=0;
			for each(var col:* in cols){
				if(col.dataField){
					fsheet.setCell(0,i,col.headerText);
					i++;
				}
			}
		}
		
		public static function addExcelData(laryDataList:ArrayCollection,fsheet:Sheet,gridName:Object):void{
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
	}
}