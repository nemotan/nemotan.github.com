---
layout: post
title: Java中的强引用、软引用、弱引用和虚引用以及对象的finalize方法理解
categories:
- java
tags:
- java
---
##finalize方法
###定义
Java 技术允许使用 finalize() 方法在垃圾收集器将对象从内存中清除出去之前做必要的清理工作。这个方法是由垃圾收集器在确定这个对象没有被引用时对这个对象调用的。它是在 Object 类中定义的，因此所有的类都继承了它。<font color="red">子类覆盖 finalize() 方法以整理系统资源或者执行其他清理工作。finalize() 方法是在垃圾收集器删除对象之前对这个对象调用的。</font> 
###finalize基本规则
1、java的GC只负责内存的清理，其他资源文件如db连接需要手动清理，以防系统资源不足
<br>2、System.gc()只是建议jvm执行GC，调用GC并不保证GC实际执行,是否回收由jvm决定
<br>3、finalize抛出的未捕获异常只会导致该对象的finalize执行退出。 
<br>4、用户可以自己调用对象的finalize方法，但是这种调用是正常的方法调用，和对象的销毁过程无关。 
<br>5、JVM保证在一个对象所占用的内存被回收之前，如果它实现了finalize方法，则该方法一定会被调用。Object的默认finalize什么都不做，为了效率，GC可以认为一个什么都不做的finalize不存在。 
###对象的销毁过程
当新建一个对象时，会置位该对象的一个内部标识finalizable，当某一点GC检查到该对象不可达时，就把该对象放入finalize queue(F queue)，GC会在对象销毁前执行finalize方法并且清空该对象的finalizable标识。 

简而言之，一个简单的对象生命周期为，Unfinalized Finalizable Finalized Reclaimed。 

实例：测试finaize方法的调用
	
	

	public static void main(String[] args){
        WeakReference<Grocery> ref =
                new WeakReference<Grocery>(new Grocery("虚引用A"));
        System.out.println("Just created: "+ref.get());
        System.gc();
   }
   
   
在对象的销毁过程中，按照对象的finalize的执行情况，可以分为以下几种，系统会记录对象的对应状态： <br>
unfinalized 没有执行finalize，系统也不准备执行。 <br>
finalizable 可以执行finalize了，系统会在随后的某个时间执行finalize。 <br>
finalized 该对象的finalize已经被执行了。 

GC怎么来保持对finalizable的对象的追踪呢。GC有一个Queue，叫做F-Queue，所有对象在变为finalizable的时候会加入到该Queue，然后等待GC执行它的finalize方法。 

这时我们引入了对对象的另外一种记录分类，系统可以检查到一个对象属于哪一种。 
reachable 从活动的对象引用链可以到达的对象。包括所有线程当前栈的局部变量，所有的静态变量等等。 
finalizer-reachable 除了reachable外，从F-Queue可以通过引用到达的对象。 
unreachable 其它的对象。 
<img src="http://zhang-xzhi-xjtu.iteye.com/upload/attachment/0015/4798/cde0952b-6cb4-3124-894f-dd807b2905fc.jpg"/>

1 首先，所有的对象都是从Reachable+Unfinalized走向死亡之路的。 

2 当从当前活动集到对象不可达时，对象可以从Reachable状态变到F-Reachable或者Unreachable状态。 

3 当对象为非Reachable+Unfinalized时，GC会把它移入F-Queue，状态变为F-Reachable+Finalizable。 

4 好了，关键的来了，任何时候，GC都可以从F-Queue中拿到一个Finalizable的对象，标记它为Finalized，然后执行它的finalize方法，由于该对象在这个线程中又可达了，于是该对象变成Reachable了（并且Finalized）。而finalize方法执行时，又有可能把其它的F-Reachable的对象变为一个Reachable的，这个叫做<font color="red">对象再生。 </font>

5 当一个对象在Unreachable+Unfinalized时，如果该对象使用的是默认的Object的finalize，或者虽然重写了，但是新的实现什么也不干。为了性能，GC可以把该对象之间变到Reclaimed状态直接销毁，而不用加入到F-Queue等待GC做进一步处理。 

6 从状态图看出，不管怎么折腾，任意一个对象的finalize只至多执行一次，一旦对象变为Finalized，就怎么也不会在回到F-Queue去了。当然没有机会再执行finalize了。 

7 当对象处于Unreachable+Finalized时，该对象离真正的死亡不远了。GC可以安全的回收该对象的内存了。进入Reclaimed。 

对象再生实例：
	
	public class B {  
  
    static B b;  
  
    public void finalize() {  
        System.out.println("method B.finalize");  
        b = this;  
    }  
 	}    
    B b = new B();  
    b = null;  
    System.gc();  
    B.b = null;  
    System.gc();	
 
对象b本来已经被置null，GC检查到后放入F queue，然后执行了finalize方法，但是执行finalize方法时该对象赋值给一个static变量，该对象又可达了，此之谓对象再生。 

后来该static对象也被置null,然后GC，可以从结果看到finalize方法只运行了1次。为什么呢，因为第一次finalize运行过后，该对象的finalizable置为false了，所以该对象即使以后被gc运行，也不会执行finalize方法了。 

很明显，对象再生是一个不好的编程实践，打乱了正常的对象生命周期。但是如果真的需要这么用的话，应该用当前对象为原型重新生成一个对象使用，这样以后这个新的对象还可以被GC运行finalize方法。
###
##引用
###SoftReference WeakReference 
SoftReference会尽量保持对referent的引用，直到JVM内存不够，才会回收SoftReference的referent。所以这个比较适合实现一些cache。

WeakReference不能阻止GC对referent的处理。
	
	ReferenceQueue queue = new ReferenceQueue();
    WeakReference ref = new WeakReference(new A(), queue);
    System.out.println(ref.get());

    Object obj = null;
    obj = queue.poll();
    System.out.println(ref.get());
   	System.gc();

    System.out.println(ref.get());
    obj = queue.poll();
    System.out.println(ref.get());
    class A{}
    #结果：
    com.java.reference.A@585e25f3
	com.java.reference.A@585e25f3
	null
	null

###PhantomReference
幻影引用，幽灵引用，呵呵，名字挺好听的。 

奇特的地方，任何时候调用get()都是返回null。那么它的用处呢，单独好像没有什么大的用处，所以要结合ReferenceQueue。 

	ReferenceQueue queue = new ReferenceQueue();
    PhantomReference ref = new PhantomReference(new A(), queue);
    System.out.println(ref.get());

    Object obj = null;
    obj = queue.poll();
    System.out.println(ref.get());
    System.gc();

    System.out.println(ref.get());
    obj = queue.poll();
    System.out.println(ref.get());
    #结果
    
	null
	null
	null
	null