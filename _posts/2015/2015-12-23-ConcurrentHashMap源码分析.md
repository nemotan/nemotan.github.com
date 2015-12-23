---
layout: post
title: ConcurrentHashMap源码分析
categories:
- java
tags:
- java
---
[toc]

## HashTable和ConcurrentMap比较
*HashTable* 使用的是 *synchronized*是针对整张 *Hash*表的，即每次锁住整张表让线程独占， *ConcurrentHashMap*允许多个修改操作并发进行，其关键在于使用了锁分离技术。它使用了多个锁来控制对hash表的不同部分进行的修改。

*ConcurrentHashMap*内部使用段 *(Segment)*来表示这些不同的部分，每个段其实就是一个小的 *hash table，*它们有自己的锁。只要多个修改操作发生在不同的段上，它们就可以并发进行。

*size()*和 *containsValue()*等一些操作全表的方法，它们可能需要锁定整个表而而不仅仅是某个段，这需要按顺序锁定所有段，操作完毕后，又按顺序释放所有段的锁。这里“按顺序”是很重要的，否则极有可能出现死锁，在 *ConcurrentHashMap*内部，段数组是 *final*的，并且其成员变量实际上也是 *final*的，但是，仅仅是将数组声明为 *final*的并不保证数组成员也是 *final*的，这需要实现上的保证。这可以确保不会出现死锁，因为获得锁的顺序是固定的。

## 数据结构

*ConcurrentHashMap*和 *Hashtable*主要区别就是围绕着锁的粒度以及如何锁,可以简单理解成把一个大的 *HashTable*分解成多个，形成了锁分离。如图:

<img src="http://images.cnitblog.com/blog/400827/201409/011042300165927.png" />

另外附上HashMap和HashTable的数据结构图： **当然HashTable中和HashMap的区别知识增加了synchronized锁，锁定了整个表**
<img src="http://dl.iteye.com/upload/attachment/517190/b197e4de-8b25-39a0-aa03-ac933a12ff08.png"/>

## 使用场景

1、多线程共享数据场景
2、当设计数据表的事务时（事务某种意义上也是同步机制的体现），可以把一个表看成一个需要同步的数组，如果操作的表数据太多时就可以考虑事务分离了（这也是为什么要避免大表的出现），比如把数据进行字段拆分，水平分表等.

## 部分源码

### ConncurrentHashMap的segment

*ConcurrentHashMap* 中主要实体类就是三个： *ConcurrentHashMap*（整个 *Hash表）,Segment（桶），HashEntry（节点）*，对应上面的图可以看出之间的关系

{% highlight java %}
/** 
* The segments, each of which is a specialized hash table 
*/  
final Segment<K,V>[] segments; 
{% endhighlight %}
### HashEntry
*ConcurrentHashMap*完全允许多个读操作并发进行，读操作并不需要加锁。如果使用传统的技术，如 *HashMap*中的实现，如果允许可以在hash链的中间添加或删除元素，读操作不加锁将得到不一致的数据。 *ConcurrentHashMap*实现技术是保证 *HashEntry*几乎是不可变的。 *HashEntry*代表每个 *hash*链中的一个节点，其结构如下所示：

{% highlight java %}
 static final class HashEntry<K,V> {  
     final K key;  
     final int hash;  
     volatile V value;  
     final HashEntry<K,V> next;  

 }  
{% endhighlight %}
可以看到除了 *value*不是 *final*的，其它值都是 *final*的，这意味着不能从 *hash*链的中间或尾部添加或删除节点，因为这需要修改 *next* 引用值，所有的节点的修改只能从头部开始。对于 *put*操作，可以一律添加到 *Hash*链的头部。但是对于 *remove*操作，可能需要从中间删除一个节点，这就需要将要删除节点的前面所有节点整个复制一遍，最后一个节点指向要删除结点的下一个结点。这在讲解删除操作时还会详述。为了确保读操作能够看到最新的值， **将value设置成volatile，这避免了加锁。**

### 定位段

如下是定位段的方法:

{% highlight java %}
1. final Segment<K,V> segmentFor(int hash) {  
2.     return segments[(hash >>> segmentShift) & segmentMask];  
3. } 
{% endhighlight %}

### segments相关属性
关于 *Hash*表的基础数据结构，这里不想做过多的探讨。 *Hash*表的一个很重要方面就是如何解决 *hash*冲突， *ConcurrentHashMap* 和 *HashMap*使用相同的方式，都是将 *hash*值相同的节点放在一个 *hash*链中。与 *HashMap*不同的是， *ConcurrentHashMap*使用多个子 *Hash*表，也就是段( *Segment*)。下面是 *ConcurrentHashMap*的数据成员：

{% highlight java %}
1. public class ConcurrentHashMap<K, V> extends AbstractMap<K, V>  
2.         implements ConcurrentMap<K, V>, Serializable {  
3.     /** 
4.      * Mask value for indexing into segments. The upper bits of a 
5.      * key's hash code are used to choose the segment. 
6.      */  
7.     final int segmentMask;  
8.   
9.     /** 
10.      * Shift value for indexing within segments. 
11.      */  
12.     final int segmentShift;  
13.   
14.     /** 
15.      * The segments, each of which is a specialized hash table 
16.      */  
17.     final Segment<K,V>[] segments;  
18. }
{% endhighlight %}

### segment源码
所有的成员都是 *final*的，其中 *segmentMask和segmentShift*主要是为了定位段，参见上面的 *segmentFor*方法。
每个 *Segment*相当于一个子 *Hash*表，它的数据成员如下

{% highlight java %}
1.     static final class Segment<K,V> extends ReentrantLock implements Serializable {  
2. private static final long serialVersionUID = 2249069246763182397L;  
3.         /** 
4.          * The number of elements in this segment's region. 
5.          */  
6.         transient volatile int count;  
7.   
8.         /** 
9.          * Number of updates that alter the size of the table. This is 
10.          * used during bulk-read methods to make sure they see a 
11.          * consistent snapshot: If modCounts change during a traversal 
12.          * of segments computing size or checking containsValue, then 
13.          * we might have an inconsistent view of state so (usually) 
14.          * must retry. 
15.          */  
16.         transient int modCount;  
17.   
18.         /** 
19.          * The table is rehashed when its size exceeds this threshold. 
20.          * (The value of this field is always <tt>(int)(capacity * 
21.          * loadFactor)</tt>.) 
22.          */  
23.         transient int threshold;  
24.   
25.         /** 
26.          * The per-segment table. 
27.          */  
28.         transient volatile HashEntry<K,V>[] table;  
29.   
30.         /** 
31.          * The load factor for the hash table.  Even though this value 
32.          * is same for all segments, it is replicated to avoid needing 
33.          * links to outer object. 
34.          * @serial 
35.          */  
36.         final float loadFactor;  
37. }
{% endhighlight %}

### remove(key)源码

{% highlight java %}
1. public V remove(Object key) {  
2.  hash = hash(key.hashCode());  
3.     return segmentFor(hash).remove(key, hash, null);  
4. }  
整个操作是先定位到段，然后委托给段的remove操作。当多个删除操作并发进行时，只要它们所在的段不相同，它们就可以同时进行。下面是Segment的remove方法实现：
1. V remove(Object key, int hash, Object value) {  
2.     lock();  
3.     try {  
4.         int c = count - 1;  
5.         HashEntry<K,V>[] tab = table;  
6.         int index = hash & (tab.length - 1);  
7.         HashEntry<K,V> first = tab[index];  
8.         HashEntry<K,V> e = first;  
9.         while (e != null && (e.hash != hash || !key.equals(e.key)))  
10.             e = e.next;  
11.   
12.         V oldValue = null;  
13.         if (e != null) {  
14.             V v = e.value;  
15.             if (value == null || value.equals(v)) {  
16.                 oldValue = v;  
17.                 // All entries following removed node can stay  
18.                 // in list, but all preceding ones need to be  
19.                 // cloned.  
20.                 ++modCount;  
21.                 HashEntry<K,V> newFirst = e.next;  
22.                 *for (HashEntry<K,V> p = first; p != e; p = p.next)  
23.                     *newFirst = new HashEntry<K,V>(p.key, p.hash,  
24.                                                   newFirst, p.value);  
25.                 tab[index] = newFirst;  
26.                 count = c; // write-volatile  
27.             }  
28.         }  
29.         return oldValue;  
30.     } finally {  
31.         unlock();  
32.     }  
33. }
{% endhighlight %}
**注意：移除一个节点不是简单的链表进行移除，因为在HashEntry中，next属性是final不可变的，因此删除操作实际上是克隆一条链。**
如图，删除元素之前：

<img src="http://images.cnitblog.com/blog/400827/201409/011046327975389.png"/>

删除元素之后：

<img src="http://images.cnitblog.com/blog/400827/201409/011046510631976.png">

>1、当要删除的结点存在时，删除的最后一步操作要将count的值减一。这必须是最后一步操作，否则读取操作可能看不到之前对段所做的结构性修改
2、remove执行的开始就将table赋给一个局部变量tab，这是因为table是 volatile变量，读写volatile变量的开销很大。编译器也不能对volatile变量的读写做任何优化，直接多次访问非volatile实例变量没有多大影响，编译器会做相应优化。


### put操作源码

{% highlight java %}
1. V put(K key, int hash, V value, boolean onlyIfAbsent) {  
2.     lock();  
3.     try {  
4.         int c = count;  
5.         if (c++ > threshold) // ensure capacity  
6.             rehash();  
7.         HashEntry<K,V>[] tab = table;  
8.         int index = hash & (tab.length - 1);  
9.         HashEntry<K,V> first = tab[index];  
10.         HashEntry<K,V> e = first;  
11.         while (e != null && (e.hash != hash || !key.equals(e.key)))  
12.             e = e.next;  
13.   
14.         V oldValue;  
15.         if (e != null) {  
16.             oldValue = e.value;  
17.             if (!onlyIfAbsent)  
18.                 e.value = value;  
19.         }  
20.         else {  
21.             oldValue = null;  
22.             ++modCount;  
23.             tab[index] = new HashEntry<K,V>(key, hash, first, value);  
24.             count = c; // write-volatile  
25.         }  
26.         return oldValue;  
27.     } finally {  
28.         unlock();  
29.     }  
30. }
{% endhighlight %}

### get源码
{% highlight java %}

1. V get(Object key, int hash) {  
2.     if (count != 0) { // read-volatile 当前桶的数据个数是否为0 
3.         HashEntry<K,V> e = getFirst(hash);  得到头节点
4.         while (e != null) {  
5.             if (e.hash == hash && key.equals(e.key)) {  
6.                 V v = e.value;  
7.                 if (v != null)  
8.                     return v;  
9.                 return readValueUnderLock(e); // recheck  
10.             }  
11.             e = e.next;  
12.         }  
13.     }  
14.     return null;  
15. }
{% endhighlight %}

另外这篇博文详细讲解了每个方法的原理：
[http://www.ibm.com/developerworks/cn/java/java-lo-concurrenthashmap/](http://www.ibm.com/developerworks/cn/java/java-lo-concurrenthashmap/)


 




