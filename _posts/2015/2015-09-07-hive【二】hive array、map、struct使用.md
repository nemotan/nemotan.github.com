---
layout: post
title: hive【二】hive array、map、struct使用
categories:
- hive
tags:
- hive
---

转自：<a href="http://www.cnblogs.com/end/archive/2013/01/17/2863884.html">hive array、map、struct使用</a>

hive提供了复合数据类型：<br>

- Structs： structs内部的数据可以通过DOT（.）来存取，例如，表中一列c的类型为STRUCT{a INT; b INT}，我们可以通过c.a来访问域a<br>

- Maps（K-V对）：访问指定域可以通过["指定域名称"]进行，例如，一个Map M包含了一个group-》gid的kv对，gid的值可以通过M['group']来获取<br>

- Arrays：array中的数据为相同类型，例如，假如array A中元素['a','b','c']，则A[1]的值为'b'

##Struct使用
建表：

	hive> create table student_test(id INT, info struct<name:STRING, age:INT>)  
	    > ROW FORMAT DELIMITED FIELDS TERMINATED BY ','                         
		> COLLECTION ITEMS TERMINATED BY ':';                                   
		 OK  
		 Time taken: 0.446 seconds 
导入数据：

	$ cat test5.txt   
	1,zhou:30  
	2,yan:30  
	3,chen:20  
	4,li:80  
	hive> LOAD DATA LOCAL INPATH '/home/work/data/test5.txt' INTO TABLE student_test;  
	Copying data from file:/home/work/data/test5.txt  
	Copying file: file:/home/work/data/test5.txt  
	Loading data to table default.student_test  
	OK  
	Time taken: 0.35 seconds  
查询：
	
	hive> select info.age from student_test;  
	Total MapReduce jobs = 1  
	......  
	Total MapReduce CPU Time Spent: 490 msec  
	OK  
	30  
	30  
	20  
	80  
	Time taken: 21.677 seconds  

##Array
建表：

	hive> create table class_test(name string, student_id_list array<INT>)  
	    > ROW FORMAT DELIMITED                                              
	    > FIELDS TERMINATED BY ','                                          
	    > COLLECTION ITEMS TERMINATED BY ':';                               
	OK  
	Time taken: 0.099 seconds  


导入数据：
	
	$ cat test6.txt   
	034,1:2:3:4  
	035,5:6  
	036,7:8:9:10  
	hive>  LOAD DATA LOCAL INPATH '/home/work/data/test6.txt' INTO TABLE class_test ;  
	Copying data from file:/home/work/data/test6.txt  
	Copying file: file:/home/work/data/test6.txt  
	Loading data to table default.class_test  
	OK  
	Time taken: 0.198 seconds  
	
	
查询：
	
	hive> select student_id_list[3] from class_test;  
	Total MapReduce jobs = 1  
	......  
	Total MapReduce CPU Time Spent: 480 msec  
	OK  
	4  
	NULL  
	10  
	Time taken: 21.574 seconds  


##Map使用
建表：

	hive> create table employee(id string, perf map<string, int>)       
        > ROW FORMAT DELIMITED                                          
   		> FIELDS TERMINATED BY '\t'                                
   	    > COLLECTION ITEMS TERMINATED BY ','                       
        > MAP KEYS TERMINATED BY ':';                                    
	    e taken: 0.144 seconds  

导入数据：
	
	$ cat test7.txt   
	1       job:80,team:60,person:70  
	2       job:60,team:80  
	3       job:90,team:70,person:100  
	hive>  LOAD DATA LOCAL INPATH '/home/work/data/test7.txt' INTO TABLE employee;

查询：
	
	hive> select perf['person'] from employee;  
	Total MapReduce jobs = 1  
	......  
	Total MapReduce CPU Time Spent: 460 msec  
	OK  
	70  
	NULL  
	100  
	Time taken: 20.902 seconds  
	hive> select perf['person'] from employee where perf['person'] is not null;     
	Total MapReduce jobs = 1  
	.......  
	Total MapReduce CPU Time Spent: 610 msec  
	OK  
	70  
	100  
	Time taken: 21.989 seconds  