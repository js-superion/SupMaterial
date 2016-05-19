package cn.superion.material.util
{
	import cn.superion.base.util.ObjectUtils;
	
	import mx.collections.ArrayCollection;

	public class ObjectInitUtil
	{
		
		public static var unitsList:ArrayCollection = new ArrayCollection();
		/**
		 * 重置对象中的所以NaN为0
		 * */
		public static function initObject(fobj:Object):void
		{
			var lobjShadow:Object=ObjectUtils.reCreateASimpleObject(fobj);
			for (var field:String in lobjShadow)
			{
				if ((fobj[field] is Number||fobj[field] is int) &&isNaN(fobj[field]))
				{
					fobj[field]=0;
				}
			}
		}
	}
}