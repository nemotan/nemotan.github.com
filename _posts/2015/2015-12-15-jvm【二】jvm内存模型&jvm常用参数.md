---
layout: post
title: jvm【二】jvm内存模型&jvm常用参数
categories:
- jvm
tags:
- jvm
---
转自：([原文](http://hongweiyi.com/2012/02/jvm-structure/))
[toc]
## JVM规定
《The Java Virtual Machine Specification》中将JVM内存结构（又称运行时数据区Runtime Data Area）分为六部分（参看第三章）

1. The pc Register;
2. Java Virtual Machine Stacks；
3. Heap；
4. Method Area；
5. Runtime Constant Pool；
6. Native Method Stacks；

以上数据区的具体描述可参考规范。需要注意的是，以上只是一个规范说明，并没有规定虚拟机如何实现这些数据区。Sun JDK实现将内存空间划分为方法区、堆、本地方法栈、JVM方法栈、PC寄存器五部分。

如图：

<img src="http://www.hongweiyi.com/wp-content/uploads/2012/02/clip_image0026_thumb.jpg"></img>

## 内存空间详解
### PC寄存器和JVM方法栈
每个线程都会拥有以及创建一个属于自己的 **PC寄存器和JVM方法栈，**PC寄存器占用的有可能为CPU寄存器或者OS内存，而JVM栈占用的为OC内存。

每运行一个方法，便会将方法的信息压入JVM方法栈中，同时将当前执行方法放入PC寄存器中（需要注意的是，如果当前方法为Native方法，PC寄存器的值为空）。 **可以想到，如果方法栈太深，如递归方法，便会报StackOverflowError，同样如果占用空间太多，也会报OutOfMemoryError。** 需要修改JVM参数设置：-Xss××k，在××中填入数字。
### 本地方法栈

同JVM方法栈一样，本地方法栈存放的是native方法的调用的状态。在Sun JDK的实现中，本地方法栈和JVM方法栈是同一个。

### 方法区
方法区存放了要加载 **类的信息（名称、修饰符等）、类的静态变量、类中定义为fianl类型的常量、类中的Field信息、类中的方法信息，** 你用Class对象的方法，如getName()、getFields()等来获取信息时，这些数据都来自方法区。需要注意的是， **Runtime Constant Pool（常量池)**也存放在方法区中。

方法区是被同一个JVM所有线程所共享的，在Sun JDK中这块区域对应Permanet Generation（持久代），默认最小值为16MB，最大值为64MB，可通过-XX:PermSize及-XX:MaxPermSize来指定。当方法区无法满足分配请求时，会报OutOfMemoryError。

### 堆
堆用于存放 **对象实例以及数组值**，可以认为所有通过 ==new==来创建的 **对象的内存**均在此分配。一般所说的 ==GC==，大部分都是对堆进行的。

堆在32位操作系统上最大为2GB，在64位的则没有限制，大小通过-Xms和-Xmx来控制。-Xms为JVM启动时申请的最小堆内存，默认为物理内存的1/64但小于1GB；-Xmx为JVM可申请的最大堆内存，默认为物理内存的1/4但小于1GB，默认当空余堆内存小于40%的时候，JVM会将堆增大到-Xmx指定大小，可通过-XX:MinHeapFreeRatio=来指定比例，空余堆大于70%时，会将堆大小降到-Xms指定大小，这个参数可用-XX:MaxHeapFreeRatio=来指定。但对于运行系统来说，会避免频繁调整堆大小，会将-Xms和-Xmx的值设为一样。

为了让内存回收更加高效，Sun JDK从1.2开始对堆采取了分代管理的方法，如下图：

<img src="http://www.hongweiyi.com/wp-content/uploads/2012/02/clip_image0046.jpg"></img>
#### 新生代

大多数的新建对象都是从新生代中分配内存，新生代由Eden（伊甸园） Space和两块相同的Survivor Space（S0，S1或者From，To）构成。

>可通过-Xmn参数来指定新生代大小，-XX:SurvivorRatio来调整Eden与S Space的大小。

#### 旧生代

用于存放新生代经过多次垃圾回收仍然存活的对象，像Cache。同时新建的对象也有可能在旧生代上直接分配内存，一般来说是比较的对象，即：单一大对象以及大数组，-XX:PretenureSizeThreshold = 1024 (byte, default = 0)可用来代表单一对象超过多大即不在新生代分配。

>旧生代所占内存大小为-Xmx-（-Xmn）。

## JVM常用参数

### 参数

|配置|解释|
| :--- | :--- |
|-Xss××k|方法栈深度|
|-XX:PermSize|方法区内存最小值|
|-XX:MaxPermSize|方法区内存最大值|
|-Xms|JVM启动分配最小堆内存|
|-Xmx|JVM启动分配最大堆内存|
|-XX:MinHeapFreeRatio=|堆内存需扩展时，剩余内存最小比例，默认40%|
|-XX:MaxHeapFreeRatio=|堆内存需收缩时，剩余内存最大比例，默认70%|
|-Xmn|堆新生代内存大小|
|-XX:NewRatio=|如参数为4，则新生代与旧生代比例为1：4|
|-XX:SurvivorRatio=|S0/S1占新生代内存的比例|
|-XX:PretenureSizeThreshold=|需要内存超过参数的对象，直接在旧生代分配|
|-XX:MaxTenuringThreshold=|设置垃圾最大年龄。如果为0，新生代对象不经过S区，直接进行旧生代，值较大的话，会增加新生代对象再GC的概率。|

### 实例：根据GC日志猜测jvm参数
>Heap
 def new generation   total 6464K, used 115K [0x34e80000, 0x35580000, 0x35580000)
  eden space 5760K,   2% used [0x34e80000, 0x34e9cd38, 0x35420000)
  from space 704K,   0% used [0x354d0000, 0x354d0000, 0x35580000)
  to   space 704K,   0% used [0x35420000, 0x35420000, 0x354d0000)
 tenured generation   total 18124K, used 8277K [0x35580000, 0x36733000, 0x37680000)
   the space 18124K,  45% used [0x35580000, 0x35d95758, 0x35d95800, 0x36733000)
 compacting perm gen  total 16384K, used 16383K [0x37680000, 0x38680000, 0x38680000)
   the space 16384K,  99% used [0x37680000, 0x3867ffc0, 0x38680000, 0x38680000)
    ro space 10240K,  44% used [0x38680000, 0x38af73f0, 0x38af7400, 0x39080000)
    rw space 12288K,  52% used [0x39080000, 0x396cdd28, 0x396cde00, 0x39c80000)

**分析过程**

{% highlight java %}
-XX:PermSize = 16384K = 16M
-XX:MaxPermSize = (0x38680000-0x37680000）/1024/1024 = 16M
-Xmx = (0x37680000-0x34e80000)/1024/1024 = 40M
-Xms = 3.7+17.7 = 21.5m
新生代=(6464k+704k)/1024=7M 3.7M
老年代=33M 和 17.7M
-XX:NewRatio= 33/7 约等于 5
-XX:SurvivorRatio=8(因为：s0 大小为 704k,新生代大小为：
6464+704=7168,704/7168=1/10)
-XX:+PrintGCDetails

因此得出的结果是：
-XX:PermSize=16m -XX:MaxPermSize=16m -Xms22m -Xmx40m -XX:NewRatio=5
-XX:SurvivorRatio=8 -XX:+PrintGCDetails
{% endhighlight %}


## 小结

总的来说，所有语言的内存结构都大同小异，均分为堆、栈、区，堆放动态分配（alloc）的对象，栈存放临时变量、方法过程等，方法区则存放编译时确定的方法签名、常量池等。

学习博客：[jvm精选blog学习](http://hongweiyi.com/2012/02/jvm-structure/)
参考书籍：[深入理解Java虚拟机 JVM高级特性与最佳实践](http://www.linuxidc.com/Linux/2014-09/106869.htm)


