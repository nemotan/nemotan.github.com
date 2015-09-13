---
layout: post
title: hive【四】order by,sort by, distribute by, cluster by作用以及用法
categories:
- hive
tags:
- hive
---

##一、order by
Hive中的order by跟传统的sql语言中的order by作用是一样的，会对查询的结果做一次全局排序，所以说，只有hive的sql中制定了order by所有的数据都会到同一个reducer进行处理（不管有多少map，也不管文件有多少的block只会启动一个reducer）。但是对于大量数据这将会消耗很长的时间去执行。
    这里跟传统的sql还有一点区别：如果指定了hive.mapred.mode=strict（默认值是nonstrict）,这时就必须指定limit来限制输出条数，原因是：所有的数据都会在同一个reducer端进行，数据量大的情况下可能不能出结果，那么在这样的严格模式下，必须指定输出的条数。
##二、sort by
Hive中指定了sort by，那么在每个reducer端都会做排序，也就是说保证了局部有序（每个reducer出来的数据是有序的，但是不能保证所有的数据是有序的，除非只有一个reducer），好处是：执行了局部排序之后可以为接下去的全局排序提高不少的效率（其实就是做一次归并排序就可以做到全局排序了）。
##三、distribute by和sort by一起使用
 ditribute by是控制map的输出在reducer是如何划分的，举个例子，我们有一张表，mid是指这个store所属的商户，money是这个商户的盈利，name是这个store的名字
 <table border="1" width="100%" cellspacing="1" cellpadding="1">
<tbody>
<tr>
<td>mid</td>
<td>money</td>
<td>name</td>
</tr>
<tr>
<td>AA</td>
<td>15.0</td>
<td>商店1</td>
</tr>
<tr>
<td>AA</td>
<td>20.0</td>
<td>商店2</td>
</tr>
<tr>
<td>BB</td>
<td>22.0</td>
<td>商店3</td>
</tr>
<tr>
<td>CC</td>
<td>44.0</td>
<td>商店4</td>
</tr>
</tbody>
</table>
	
	#执行hive语句
	select mid, money, name from store distribute by mid sort by mid asc, money asc
	
我们所有的mid相同的数据会被送到同一个reducer去处理，这就是因为指定了distribute by mid，这样的话就可以统计出每个商户中各个商店盈利的排序了（这个肯定是全局有序的，因为相同的商户会放到同一个reducer去处理）。这里需要注意的是distribute by必须要写在sort by之前。
	
##四、cluster by
cluster by的功能就是distribute by和sort by相结合，如下2个语句是等价的
	
	select mid, money, name from store cluster by mid
	select mid, money, name from store distribute by mid sort by mid  
	
如果需要获得与三中语句一样的效果：

	select mid, money, name from store cluster by mid sort by money
注意被cluster by指定的列只能是降序，不能指定asc和desc。  

文章转自：<a href="http://blog.csdn.net/jthink_/article/details/38903775">hive中order by,sort by, distribute by, cluster by作用以及用法</a>
