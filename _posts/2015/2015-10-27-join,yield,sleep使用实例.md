---
layout: post
title: join,yield,sleep使用实例
categories:
- 高并发
tags:
- 高并发
---
##sleep（）
使当前线程（即调用该方法的线程）暂停执行一段时间，让其他线程有机会继续执行，**但它并不释放对象锁。**也就是说如果有synchronized同步快，其他线程仍然不能访问共享数据。注意该方法要捕捉异常。
 
例如有两个线程同时执行(没有synchronized)一个线程优先级为MAX_PRIORITY，另一个为MIN_PRIORITY，如果没有Sleep()方法，只有高优先级的线程执行完毕后，低优先级的线程才能够执行；但是高优先级的线程sleep(500)后，低优先级就有机会执行了。

总之，sleep()可以使低优先级的线程得到执行的机会，当然也可以让同优先级、高优先级的线程有执行的机会。

**实例一：sleep方法的用法**

##join（）

join()方法使调用该方法的线程在此之前执行完毕，也就是等待该方法的线程执行完毕后再往下继续执行。注意该方法也需要捕捉异常。

hread.Join把指定的线程加入到当前线程，可以将两个交替执行的线程合并为顺序执行的线程。比如在线程B中调用了线程A的Join()方法，直到线程A执行完毕后，才会继续执行线程B。

t.join();      //使调用线程 t 在此之前执行完毕。
t.join(1000);  //等待 t 线程，等待时间是1000毫秒

**实例一:join方法的使用**

{% highlight java %}
public class JoinTest implements  Runnable{
    public static int a = 0;

    public void run() {
        for (int k = 0; k < 5; k++) {
            a = a + 1;
        }
    }

    public static void main(String[] args) throws Exception {
        Runnable r = (Runnable) new JoinTest();
        Thread t = new Thread(r);
        t.start();
       // t.join();
        System.out.println(a);
    }
}
{% endhighlight %}

结果：当t.join()未加之前，打印出a得值一般不会是5，因为主线程打印的时候，线程t还没有运行完成。当加上t.join之后，主线程会阻塞，直到t线程运行完成之后在往下执行，最终结果一定是5.

**实例二：join（long seconds）的使用**

{% highlight java %}
public class JoinTest2 implements Runnable{
    public void run() {
        try {
            System.out.println("Begin sleep");
            Thread.sleep(5000);
            System.out.println("End sleep");
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

    }
    public static void main(String[] args) {
        Thread t = new Thread(new JoinTest2());
        t.start();
        try {
            t.join(1000);
            System.out.println("joinFinish");
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}
/*
结果输出：
Begin sleep
joinFinish
End sleep
*/
{% endhighlight %}
很明显，t线程join（1000）的时候，主线程只阻塞了1000毫秒，1000毫秒之后继续往下执行，而t线程执行过程中暂停了5000毫秒。说明join（long seconeds）使得主线程阻塞seconeds毫秒，之后不管t是否在执行，都会往下执行。


##yield（）
该方法与sleep()类似，只是不能由用户指定暂停多长时间，并且yield（）方法只能让**同优先级**的线程有执行的机会。

###join方法和yield方法区别
- sleep(long)使当前线程进入停滞状态，所以执行sleep()的线程在指定的时间内肯定不会被执行；
- sleep(long)可使优先级低的线程得到执行的机会，当然也可以让同优先级的线程有执行的机会；
- sleep(long)是不会释放锁标志的。

sleep 方法使当前运行中的线程睡眠一段时间，进入不可以运行状态，这段时间的长短是由程序设定的，yield方法使当前线程让出CPU占有权，但让出的时间是不可设定的。
 yield()也不会释放锁标志。
 实际上，yield()方法对应了如下操作；先检测当前是否有相同优先级的线程处于同可运行状态，如有，则把CPU的占有权交给次线程，否则继续运行原来的线程，所以yield()方法称为“退让”，它把运行机会让给了同等级的其他线程。

 sleep 方法允许较低优先级的线程获得运行机会，但yield（）方法执行时，当前线程仍处在可运行状态，所以不可能让出较低优先级的线程此时获取CPU占有权。在一个运行系统中，如果较高优先级的线程没有调用sleep方法，也没有受到I/O阻塞，那么较低优先级线程只能等待所有较高优先级的线程运行结束，方可有机会运行。

 yield()只是使当前线程重新回到可执行状态，所有执行yield()的线程有可能在进入到可执行状态后马上又被执行，所以yield()方法只能使同优先级的线程有执行的机会。
 
 
 ##线程的优先级
 **实例：测试优先级**
 
 {% highlight java %}
 public class YieldTest extends Thread {
    private String sTname = "";

    YieldTest(String s) {
        sTname = s;
    }

    public void run() {
        for (int i = 0; i < 2; i++) {
                System.out.println(sTname);
        }
    }

    public static void main(String argv[]) {
        YieldTest pm1 = new YieldTest("one");
        YieldTest pm2 = new YieldTest("two");
        pm1.setPriority(Thread.MIN_PRIORITY);
        pm2.setPriority(Thread.MAX_PRIORITY);
        pm1.start();
        pm2.start();
    }

}
/*
输出结果：
one
one
two
two
*/
 {% endhighlight %}
 从输出的结果看，pm2设置了较高优先级，pm1设置了较低优先级，为什么会线程1先执行完呢？难道线程优先级没有生效？

其实：<font color="red">高优先级</font>
书上说的的情况大多是在单核处理器上，但不完全对，那个线程会执行，完全取决于操作系统，操作系统有自己的处理机制，Java会跟操作系统商量，优先级高的线程比优先级低的线程先执行的概率相对高一些，但不是绝对的，有时候优先级低的会先执行，完全取决于操作系统；

对于双核处理器，优先级高的线程比优先级低的线程先执行的概率逐渐减小，优先级高的线程和优先级低的线程都有可以先执行；

对于多核处理器，优先级高的线程和优先级低的线程哪个会先执行，真心不好说；另外多核处理器设置线程优先级没太多意义。

**实例二：测试yield**

{% highlight java %}
public class YieldTest extends Thread {
    private String sTname = "";

    YieldTest(String s) {
        sTname = s;
    }

    public void run() {
        for (int i = 0; i < 2; i++) {
            yield();
                System.out.println(sTname);
        }
    }

    public static void main(String argv[]) {
        YieldTest pm1 = new YieldTest("one");
        YieldTest pm2 = new YieldTest("two");
        pm1.start();
        pm2.start();
    }

}
/*
结果输出：
one
two
one
two
*/
{% endhighlight %}
