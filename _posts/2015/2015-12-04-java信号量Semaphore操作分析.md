---
layout: post
title: java信号量Semaphore操作分析
categories:
- 高并发
tags:
- 高并发
---
[toc]


转自：[http://my.oschina.net/cloudcoder/blog/362974](http://my.oschina.net/cloudcoder/blog/362974)
### 简介

**信号量(Semaphore)，**有时被称为信号灯，是在多线程环境下使用的一种设施, 它负责协调各个线程, 以保证它们能够正确、合理的使用公共资源。

**概念上**，信号量维护了一个许可集。如有必要， **在许可可用前会阻塞每一个 acquire()，**然后再获取该许可。每个  **release() 添加一个许可，从而可能释放一个正在阻塞的获取者。**但是，不使用实际的许可对象，Semaphore 只对可用许可的号码进行计数，并采取相应的行动。拿到信号量的线程可以进入代码，否则就等待。 **通过acquire()和release()获取和释放访问许可。**


### 概念

 Semaphore分为 **单值和多值两种**，前者只能被 **一个线程**获得，后者可以被 **若干个线程**获得。以一个停车场运作为例。为了简单起见，假设停车场只有三个车位，一开始三个车位都是空的。这时如果同时来了五辆车，看门人允许其中三辆不受阻碍的进入，然后放下车拦，剩下的车则必须在入口等待，此后来的车也都不得不在入口处等待。这时，有一辆车离开停车场，看门人得知后，打开车拦，放入一辆，如果又离开两辆，则又可以放入两辆，如此往复。 **在这个停车场系统中，车位是公共资源，每辆车好比一个线程，看门人起的就是信号量的作用。**

更进一步，信号量的特性如下： **信号量是一个非负整数（车位数）**，所有通过它的线程（车辆）都会将该整数减一（通过它当然是为了使用资源），当该整数值为零时，所有试图通过它的线程都将处于等待状态。在信号量上我们定义两种操作： **Wait（等待） 和 Release（释放）。**当一个线程调用Wait（等待）操作时，它要么通过然后将信号量减一，要么一直等下去，直到信号量大于一或超时。Release（释放）实际上是在信号量上执行加操作，对应于车辆离开停车场，该操作之所以叫做“释放”是因为加操作实际上是释放了由信号量守护的资源。

在java中，还可以设置该信号量是否采用公平模式，如果以 **公平方式执行，**则线程将会按到达的顺序 **（FIFO）执行，**如果是非公平，则可以后请求的 **有可能排在队列的头部。**
JDK中定义如下：
 
{% highlight java %} 
    Semaphore(int permits, boolean fair)
　　//创建具有给定的许可数和给定的公平设置的Semaphore。
{% endhighlight %}
Semaphore当前在多线程环境下被扩放使用，操作系统的信号量是个很重要的概念，在进程控制方面都有应用。Java并发库Semaphore 可以很轻松完成信号量控制， **Semaphore可以控制某个资源可被同时访问的个数，通过 acquire() 获取一个许可，如果没有就等待，而 release() 释放一个许可。比如在Windows下可以设置共享文件的最大客户端访问个数。**

Semaphore实现的功能就类似厕所有5个坑，假如有10个人要上厕所，那么同时只能有多少个人去上厕所呢？同时只能有5个人能够占用，当5个人中 的任何一个人让开后，其中等待的另外5个人中又有一个人可以占用了。另外等待的5个人中可以是随机获得优先机会，也可以是按照先来后到的顺序获得机会，这取决于构造 **Semaphore对象**时传入的参数选项。单个信号量的Semaphore对象可以实现互斥锁的功能，并且可以是由一个线程获得了“锁”，再由另一个线程释放“锁”，这可应用于死锁恢复的一些场合。


### 实例一：简单应用

{% highlight java %}
public class SemaPhore {
    public static void main(String[] args) {
        // 线程池
        ExecutorService exec = Executors.newCachedThreadPool();
        // 只能5个线程同时访问
        final Semaphore semp = new Semaphore(5);
        // 模拟20个客户端访问
        for (int index = 0; index < 50; index++) {
            final int NO = index;
            Runnable run = new Runnable() {
                public void run() {
                    try {
                        // 获取许可
                        semp.acquire();
                        System.out.println("Accessing: " + NO);
                        Thread.sleep((long) (Math.random() * 6000));
                        // 访问完后，释放
                        semp.release();
                        //availablePermits()指的是当前信号灯库中有多少个可以被使用
                        System.out.println("-----------------" + semp.availablePermits());
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
            };
            exec.execute(run);
        }
        // 退出线程池
        exec.shutdown();
    }
}
{% endhighlight %}

### 实例二：信号量实现生产者消费者模式

{% highlight java %}
package com.nemo.thread.semaphore;

import java.util.concurrent.Semaphore;

/**
 * Created by nemo on 15/12/4.
 */
public class SemaPhoreProduce {
    static Buffer buffer = new Buffer();

    static class Produce implements Runnable{
        static int num = 1;
        @Override
        public void run() {
            int n = num++;
            while (true) {
                try {
                    buffer.put(n);
                    System.out.println(Thread.currentThread().getName() + "  入库" + n);
                    // 速度较快。休息10毫秒
                    Thread.sleep(10);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    static class Consume implements Runnable{
        @Override
        public void run() {
            while (true) {
                try {
                    System.out.println(Thread.currentThread().getName() +"  出库"+ buffer.take());
                    // 速度较慢，休息1000毫秒
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    static class Buffer{
        // 非满锁
        final Semaphore notFull = new Semaphore(10);
        // 非空锁
        final Semaphore notEmpty = new Semaphore(0);
        // 核心锁
        final Semaphore mutex = new Semaphore(1);
        // 库存容量
        final Object[] items = new Object[10];
        int putptr, takeptr, count;
        /**
         * 把商品放入仓库.<br>
         *
         * @param x
         * @throws InterruptedException
         */
        public void put(Object x) throws InterruptedException {
            // 保证非满
            notFull.acquire();
            // 保证不冲突
            mutex.acquire();
            try {
                // 增加库存
                items[putptr] = x;
                if (++putptr == items.length)
                    putptr = 0;
                ++count;
            } finally {
                // 退出核心区
                mutex.release();
                // 增加非空信号量，允许获取商品
                notEmpty.release();
            }
        }
        /**
         * 从仓库获取商品
         *
         * @return
         * @throws InterruptedException
         */
        public Object take() throws InterruptedException {
            // 保证非空
            notEmpty.acquire();
            // 核心区
            mutex.acquire();
            try {
                // 减少库存
                Object x = items[takeptr];
                if (++takeptr == items.length)
                    takeptr = 0;
                --count;
                return x;
            } finally {
                // 退出核心区
                mutex.release();
                // 增加非满的信号量，允许加入商品
                notFull.release();
            }
        }
    }

    public static void main(String args[]){
        // 启动线程
        for (int i = 0; i <= 3; i++) {
            // 生产者
            new Thread(new Produce(),"produce"+i+1).start();
            // 消费者
            new Thread(new Consume(),"consume"+i+1).start();
        }
    }
}



{% endhighlight %}
