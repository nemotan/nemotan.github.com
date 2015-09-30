---
layout: post
title: hive【六】hive自定义函数--UDF,UDAF,UDTF代码实例
categories:
- hive
tags:
- hive
---
在Beeline或者在CLI中我们可以用如下命令查看函数信息

```bash	
SHOW FUNCTIONS;                       #显示所有函数	
DESCRIBE FUNCTION <function_name>;    #显示函数简单描述
DESCRIBE FUNCTION EXTENDED <function_name>; #显示函数详细描述
```
hive常用函数请参考：<a href="https://cwiki.apache.org/confluence/display/Hive/LanguageManual+UDF">hive官网UDF页</a>

##UDFS（用户自定义函数）
首先，你需要创建一个类继承UDF，必须有一个或者多个名为evaluate的方法。
{% highlight java %}

```java
/**
 * 求一個升序的数组中，N个最大值的和
 *
 */
public class ArraySizeSum extends UDF {
    /**
     * 返回升序数组的N各最大值的和
     *
     * @param arguments 第一个参数为hive的数组，对应java的list，第二个参数为size
     * @return
     */
    public long evaluate(Object[] arguments) {
        List<Object> list = (List<Object>)arguments[0];
        if(list.size()==0){
            return 0l;
        }
        int index = (int)Double.parseDouble(arguments[1].toString());
        if(list.size()<index){
            index = list.size();
        }
        long result = 0l;
        for (int i = 0; i < index; i++) {
            result += Long.parseLong(list.get(list.size() - 1 - i).toString());
        }
        return result;
    }
}
```
{% endhighlight %}

把程序打包成jar，并且创建临时函数（自定义函数class文件需要在hive的classpath下）

```bash
$ add jar /home/nemo/hive-1.2.1/lib/hive_behavior.jar; 
$ create temporary function size_sum as 'com.landray.hive.ql.ArraySizeSum';
```

##UDAF（用户自定义聚合函数）
###介绍
User-Defined Aggregation Functions(UDAFS：用户自定义聚合函数)是一个很棒的功能，使得hive继承了先进的数据处理功能，hive有两种UDAFS:简单和通用的。简单的UDFS就像名字一样，编写简单，但是由于使用了java反射从而影响了性能，并且不支持可变的参数。通用的UDFS支持前面所有的特性，但是不像simple容易编写。
###概述
当然，通用的UDAF需要两个步骤，第一步创建一个resolver 类，第二步是创建一个evaluator类。resolver负责类型检测和操作符重载（如果你想用），并且帮助hive从一系列的参数中找到evaluator。evaluator实现了UDAF的真正的逻辑。通常来说，顶层UDAF类继承了一个基本抽象类org.apache.hadoop.hive.ql.udf.GenericUDAFResolver2，并且evaluator类是一个静态内部类。
###实现resolver
resolver实现类型检测，和操作符重载，老得api必须继承org.apache.hadoop.hive.ql.udf.GenericUDAFResolver2 ，为了新版本的hive改进，建议继承AbstractGenericUDAFResolver类。
<br>代码架构如下：

```java
public class GenericUDAFHistogramNumeric extends AbstractGenericUDAFResolver {
  static final Log LOG = LogFactory.getLog(GenericUDAFHistogramNumeric.class.getName());
 
  @Override
  public GenericUDAFEvaluator getEvaluator(GenericUDAFParameterInfo info) throws SemanticException {
    // info为参数，该方法执行方法检测，用户可以自定义返回不太能够的Evaluator
 
    return new GenericUDAFHistogramNumericEvaluator();
  }
 
  public static class GenericUDAFHistogramNumericEvaluator extends GenericUDAFEvaluator {
    // UDAF的真正逻辑
  }
}
```
###实现evaluator
所有evaluators必须继承抽象类org.apache.hadoop.hive.ql.udf.generic.GenericUDAFEvaluator。子类必须实现它的一些抽象方法，实现UDAF的逻辑。GenericUDAFEvaluator有一个嵌套类Mode,这个类很重要，它表示了udaf在mapreduce的各个阶段，理解Mode的含义，就可以理解了hive的UDAF的运行流程。

```java
public static enum Mode {
    /**
     * PARTIAL1: 这个是mapreduce的map阶段:从原始数据到部分数据聚合
     * 将会调用iterate()和terminatePartial()
     */
    PARTIAL1,
        /**
     * PARTIAL2: 这个是mapreduce的map端的Combiner阶段，负责在map端合并map的数据::从部分数据聚合到部分数据聚合:
     * 将会调用merge() 和 terminatePartial() 
     */
    PARTIAL2,
        /**
     * FINAL: mapreduce的reduce阶段:从部分数据的聚合到完全聚合 
     * 将会调用merge()和terminate()
     */
    FINAL,
        /**
     * COMPLETE: 如果出现了这个阶段，表示mapreduce只有map，没有reduce，所以map端就直接出结果了:从原始数据直接到完全聚合
      * 将会调用 iterate()和terminate()
     */
    COMPLETE
  };
```
evaluator代码架构：

```java
#!Java
  public static class GenericUDAFHistogramNumericEvaluator extends GenericUDAFEvaluator {
 
    // For PARTIAL1 and COMPLETE: ObjectInspectors for original data
    private PrimitiveObjectInspector inputOI;
    private PrimitiveObjectInspector nbinsOI;
 
    // For PARTIAL2 and FINAL: ObjectInspectors for partial aggregations (list of doubles)
    private StandardListObjectInspector loi;
 
 
    @Override
    public ObjectInspector init(Mode m, ObjectInspector[] parameters) throws HiveException {
      super.init(m, parameters);
      // return type goes here
    }
 	//以持久化的方式返回agg表示部分聚合结果，这里的持久化意味着返回值只能Java基础类型、数组、基础类型包装器、Hadoop的Writables、Lists和Maps。即使实现了java.io.Serializable，也不要使用自定义的类。
    @Override
    public Object terminatePartial(AggregationBuffer agg) throws HiveException {
      // return value goes here
    } 
 	//返回由agg表示的最终结果。
    @Override
    public Object terminate(AggregationBuffer agg) throws HiveException {
      // final return value goes here
    }
 	//合并由partial表示的部分聚合结果到agg中。
    @Override
    public void merge(AggregationBuffer agg, Object partial) throws HiveException {
    }
 
 	//迭代parameters表示的原始数据并保存到agg中。
    @Override
    public void iterate(AggregationBuffer agg, Object[] parameters) throws HiveException {
    }
 
    // Aggregation buffer definition and manipulation methods
    static class StdAgg implements AggregationBuffer {
    };
 
    //用于返回存储临时聚合结果的
    @Override
    public AggregationBuffer getNewAggregationBuffer() throws HiveException {
    }
 	//重置聚合，该方法在重用相同的聚合时很有用。
    @Override
    public void reset(AggregationBuffer agg) throws HiveException {
    }   
  }
```

**源码分析一：GenericUDAFSumLong**
<br>这是一个sum求和的UDAF：<br>

```java
public static class GenericUDAFSumLong extends GenericUDAFEvaluator {

    private PrimitiveObjectInspector inputOI;#参数的类型
    private LongWritable result;   #最终的结果，在terminate方法中调用

　　　//这个方法返回了UDAF的返回类型，这里确定了sum自定义函数的返回类型是Long类型
    @Override
    public ObjectInspector init(Mode m, ObjectInspector[] parameters) throws HiveException {
      assert (parameters.length == 1);
      super.init(m, parameters);
      result = new LongWritable(0);
      inputOI = (PrimitiveObjectInspector) parameters[0];#参数类型
      return PrimitiveObjectInspectorFactory.writableLongObjectInspector;
    }

    /** 存储sum的值的类 */
    static class SumLongAgg implements AggregationBuffer {
      boolean empty;
      long sum;
    }

    //创建新的聚合计算的需要的内存，用来存储mapper,combiner,reducer运算过程中的相加总和。

    @Override
    public AggregationBuffer getNewAggregationBuffer() throws HiveException {
      SumLongAgg result = new SumLongAgg();
      reset(result);
      return result;
    }
　　　　
    //mapreduce支持mapper和reducer的重用，所以为了兼容，也需要做内存的重用。

    @Override
    public void reset(AggregationBuffer agg) throws HiveException {
      SumLongAgg myagg = (SumLongAgg) agg;
      myagg.empty = true;
      myagg.sum = 0;
    }

    private boolean warned = false;
    　　
    //map阶段调用，只要把保存当前和的对象agg，再加上输入的参数，就可以了。
    @Override
    public void iterate(AggregationBuffer agg, Object[] parameters) throws HiveException {
      assert (parameters.length == 1);
      try {
        merge(agg, parameters[0]);
      } catch (NumberFormatException e) {
        if (!warned) {
          warned = true;
          LOG.warn(getClass().getSimpleName() + " "
              + StringUtils.stringifyException(e));
        }
      }
    }
　　  //mapper结束要返回的结果，还有combiner结束返回的结果
    @Override
    public Object terminatePartial(AggregationBuffer agg) throws HiveException {
      return terminate(agg);
    }
       
    //combiner合并map返回的结果，还有reducer合并mapper或combiner返回的结果。
    @Override
    public void merge(AggregationBuffer agg, Object partial) throws HiveException {
      if (partial != null) {
        SumLongAgg myagg = (SumLongAgg) agg;
        myagg.sum += PrimitiveObjectInspectorUtils.getLong(partial, inputOI);
        myagg.empty = false;
      }
    }
     
    //reducer返回结果，或者是只有mapper，没有reducer时，在mapper端返回结果。
    @Override
    public Object terminate(AggregationBuffer agg) throws HiveException {
      SumLongAgg myagg = (SumLongAgg) agg;
      if (myagg.empty) {
        return null;
      }
      result.set(myagg.sum);
      return result;
    }

  }
```

**源码分析二：GenericUDAFMkCollectionEvaluator**
<br>
简介：这是collect_set的源码，在group by之后，返回分组列元素组成的一个数组.主要代码如下：

```java
public ObjectInspector init(Mode m, ObjectInspector[] parameters)
      throws HiveException {
    super.init(m, parameters);
    // init output object inspectors
    // The output of a partial aggregation is a list
    if (m == Mode.PARTIAL1) {
      inputOI = (PrimitiveObjectInspector) parameters[0];
      return ObjectInspectorFactory
          .getStandardListObjectInspector((PrimitiveObjectInspector) ObjectInspectorUtils
              .getStandardObjectInspector(inputOI));
    } else {
      if (!(parameters[0] instanceof ListObjectInspector)) {
        //no map aggregation.
        inputOI = (PrimitiveObjectInspector)  ObjectInspectorUtils
        .getStandardObjectInspector(parameters[0]);
        return (StandardListObjectInspector) ObjectInspectorFactory
            .getStandardListObjectInspector(inputOI);
      } else {
        internalMergeOI = (ListObjectInspector) parameters[0];
        inputOI = (PrimitiveObjectInspector) internalMergeOI.getListElementObjectInspector();
        loi = (StandardListObjectInspector) ObjectInspectorUtils.getStandardObjectInspector(internalMergeOI);
        return loi;
      }
    }
  }


  class MkArrayAggregationBuffer extends AbstractAggregationBuffer {

    private Collection<Object> container;

    public MkArrayAggregationBuffer() {
      if (bufferType == BufferType.LIST){
        container = new ArrayList<Object>();
      } else if(bufferType == BufferType.SET){
        container = new LinkedHashSet<Object>();
      } else {
        throw new RuntimeException("Buffer type unknown");
      }
    }
  }

  @Override
  public void reset(AggregationBuffer agg) throws HiveException {
    ((MkArrayAggregationBuffer) agg).container.clear();
  }

  @Override
  public AggregationBuffer getNewAggregationBuffer() throws HiveException {
    MkArrayAggregationBuffer ret = new MkArrayAggregationBuffer();
    return ret;
  }

  //mapside,遍历值，并把值放到集合中
  @Override
  public void iterate(AggregationBuffer agg, Object[] parameters)
      throws HiveException {
    assert (parameters.length == 1);
    Object p = parameters[0];

    if (p != null) {
      MkArrayAggregationBuffer myagg = (MkArrayAggregationBuffer) agg;
      putIntoCollection(p, myagg);
    }
  }

  //mapside，部分数据聚合，返回一个list
  @Override
  public Object terminatePartial(AggregationBuffer agg) throws HiveException {
    MkArrayAggregationBuffer myagg = (MkArrayAggregationBuffer) agg;
    List<Object> ret = new ArrayList<Object>(myagg.container.size());
    ret.addAll(myagg.container);
    return ret;
  }

 //combiner和reduce调用的时候，partial是一个部分聚合的list集合
  @Override
  public void merge(AggregationBuffer agg, Object partial)
      throws HiveException {
    MkArrayAggregationBuffer myagg = (MkArrayAggregationBuffer) agg;
    List<Object> partialResult = (ArrayList<Object>) internalMergeOI.getList(partial);
    if (partialResult != null) {
      for(Object i : partialResult) {
        putIntoCollection(i, myagg);
      }
    }
  }
//完全聚合
  @Override
  public Object terminate(AggregationBuffer agg) throws HiveException {
    MkArrayAggregationBuffer myagg = (MkArrayAggregationBuffer) agg;
    List<Object> ret = new ArrayList<Object>(myagg.container.size());
    ret.addAll(myagg.container);
    return ret;
  }

  private void putIntoCollection(Object p, MkArrayAggregationBuffer myagg) {
    Object pCopy = ObjectInspectorUtils.copyToStandardObject(p,  this.inputOI);
    myagg.container.add(pCopy);
  }
```
##UDTF(User-Defined Table-Generating Functions)
 用来解决 输入一行输出多行(On-to-many maping) 的需求。UDTF需要继承GenericUDTF抽象类，实现initialize, process, and，和close方法。initalize方法返回UDTF所预期的参数的类型。UDTF必须返回行信息。初始化完成后，UDTF会调用process方法。在process中，每一次forward()调用产生一行；如果产生多列可以将多个列的值放在一个数组中，然后将该数组传入到forward()函数。<br>
最后调用close（）方法。
<br>
下面是我写的一个用来切分”key:value;key:value;”这种字符串，返回结果为key, value两个字段。供参考：

```java
import java.util.ArrayList;

 import org.apache.hadoop.hive.ql.udf.generic.GenericUDTF;
 import org.apache.hadoop.hive.ql.exec.UDFArgumentException;
 import org.apache.hadoop.hive.ql.exec.UDFArgumentLengthException;
 import org.apache.hadoop.hive.ql.metadata.HiveException;
 import org.apache.hadoop.hive.serde2.objectinspector.ObjectInspector;
 import org.apache.hadoop.hive.serde2.objectinspector.ObjectInspectorFactory;
 import org.apache.hadoop.hive.serde2.objectinspector.StructObjectInspector;
 import org.apache.hadoop.hive.serde2.objectinspector.primitive.PrimitiveObjectInspectorFactory;

 public class ExplodeMap extends GenericUDTF{

     @Override
     public void close() throws HiveException {
         // TODO Auto-generated method stub    
     }

     @Override
     public StructObjectInspector initialize(ObjectInspector[] args)
             throws UDFArgumentException {
         if (args.length != 1) {
             throw new UDFArgumentLengthException("ExplodeMap takes only one argument");
         }
         if (args[0].getCategory() != ObjectInspector.Category.PRIMITIVE) {
             throw new UDFArgumentException("ExplodeMap takes string as a parameter");
         }

         ArrayList<String> fieldNames = new ArrayList<String>();
         ArrayList<ObjectInspector> fieldOIs = new ArrayList<ObjectInspector>();
         fieldNames.add("col1");
         fieldOIs.add(PrimitiveObjectInspectorFactory.javaStringObjectInspector);
         fieldNames.add("col2");
         fieldOIs.add(PrimitiveObjectInspectorFactory.javaStringObjectInspector);

         return ObjectInspectorFactory.getStandardStructObjectInspector(fieldNames,fieldOIs);
     }

     @Override
     public void process(Object[] args) throws HiveException {
         String input = args[0].toString();
         String[] test = input.split(";");
         for(int i=0; i<test.length; i++) {
             try {
                 String[] result = test[i].split(":");
                 forward(result);
             } catch (Exception e) {
                 continue;
             }
         }
     }
 }
```
使用方法：

```sql
select explode_map(properties) as (col1,col2) from src;  #正确
select a, explode_map(properties) as (col1,col2) from src #错误，不能和其他参数一起使用
select explode_map(explode_map(properties)) from src #错误，不可以嵌套使用
select explode_map(properties) as (col1,col2) from src group by col1, col2 #错误，不可以和group by/cluster by/distribute by/sort by一起使用
select src.id, mytable.col1, mytable.col2 from src lateral view explode_map(properties) mytable as col1, col2; #经常使用

```




<br><br><br>
参考：<br>
http://www.cnblogs.com/ggjucheng/archive/2013/02/01/2888819.html
https://cwiki.apache.org/confluence/display/Hive/DeveloperGuide+UDTF

