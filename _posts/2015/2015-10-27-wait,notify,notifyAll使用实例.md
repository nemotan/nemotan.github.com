---
layout: post
title: wait,notify,notifyAll使用实例
categories:
- 高并发
tags:
- 高并发
---
-------------------


[TOC]

##wait和notify、notifyAll详解
**synchronized 方法**控制对类成员变量的访问：每个类实例对应一把锁，每synchronized 方法都必须获得调用该方法的类实例的锁方能执行，否则所属线程阻塞，方法一旦执行就独占该锁，直到从该方法返回时才将锁释放，此后被阻塞的线程方能获得该锁，重新进入可执行状态。
>**注意：**wait()/notify()调用任意对象的 wait() 方法导致线程阻塞，并且该对象上的锁被释放。而调用 任意对象的notify()方法则导致因调用该对象的 wait() 方法而阻塞的线程中随机选择的一个解除阻塞（但要等到获得锁后才真正可执行）。
###synchronized和wait()、notify()的关系
1.有synchronized的地方不一定有wait,notify

2.有wait,notify的地方必有synchronized.这是因为wait和notify不是属于线程类，而是每一个对象都具有的方法，而且，这两个方法都和对象锁有关，有锁的地方，必有synchronized。
>**注意：**
>1、如果要把notify和wait方法放在一起用的话，必须先调用notify后调用wait，因为如果调用完wait，那么那个线程就会进入等待队列，该线程就已经不是current thread了。
>2、调用wait()方法前的判断最好用while，而不用if；while可以实现被wakeup后thread再次作条件判断；而if则只能判断一次；

###线程的四种状态
-  **新状态：**线程已被创建但尚未执行（start() 尚未被调用）。
-  **可执行状态：**线程可以执行，虽然不一定正在执行。CPU 时间随时可能被分配给该线程，从而使得它执行。
-  **死亡状态:**正常情况下 run() 返回使得线程死亡。调用 stop()或 destroy() 亦有同样效果，但是不被推荐，前者会产生异常，后者是强制终止，不会释放锁。
- **阻塞状态：**线程不会被分配 CPU 时间，无法执行。
###wait（）和notify方法
首先，前面叙述的所有方法都隶属于 Thread 类，但是这一对 (wait()/notify()) 却直接隶属于 Object 类，也就是说，所有对象都拥有这一对方法。初看起来这十分不可思议，但是实际上却是很自然的，因为这一对方法阻塞时要释放占用的锁，而锁是任何对象都具有的，调用任意对象的 wait() 方法导致线程阻塞，并且该对象上的锁被释放。而调用 任意对象的notify()方法则导致因调用该对象的 wait() 方法而阻塞的线程中随机选择的一个解除阻（但要等到获得锁后才真正可执行）。

其次，前面叙述的所有方法都可在任何位置调用，但是这一对方法却必须在 synchronized 方法或块中调用，理由也很简单，只有在synchronized 方法或块中当前线程才占有锁，才有锁可以释放。

同样的道理，调用这一对方法的对象上的锁必须为当前线程所拥有，这样才有锁可以释放。因此，这一对方法调用必须放置在这样的synchronized 方法或块中，该方法或块的上锁对象就是调用这一对方法的对象。若不满足这一条件，则程序虽然仍能编译，但在运行时会出现IllegalMonitorStateException 异常。

wait() 和 notify() 方法的上述特性决定了它们经常和synchronized 方法或块一起使用，将它们和操作系统的进程间通信机制作一个比较就会发现它们的相似性：synchronized方法或块提供了类似于操作系统原语的功能，它们的执行不会受到多线程机制的干扰，而这一对方法则相当于 block 和wakeup 原语（这一对方法均声明为 synchronized）。它们的结合使得我们可以实现操作系统上一系列精妙的进程间通信的算法（如信号量算法），并用于解决各种复杂的线程间通信问题。关于

wait() 和 notify() 方法最后再说明两点：

第一：调用 notify() 方法导致解除阻塞的线程是从因调用该对象的 wait() 方法而阻塞的线程中随机选取的，我们无法预料哪一个线程将会被选择，所以编程时要特别小心，避免因这种不确定性而产生问题。

第二：除了 notify()，还有一个方法 notifyAll() 也可起到类似作用，唯一的区别在于，调用 notifyAll() 方法将把因调用该对象的wait() 方法而阻塞的所有线程一次性全部解除阻塞。当然，只有获得锁的那一个线程才能进入可执行状态。

谈到阻塞，就不能不谈一谈死锁，略一分析就能发现，suspend() 方法和不指定超时期限的 wait() 方法的调用都可能产生死锁。遗憾的是，Java 并不在语言级别上支持死锁的避免，我们在编程中必须小心地避免死锁。

以上我们对 Java 中实现线程阻塞的各种方法作了一番分析，我们重点分析了 wait() 和 notify()方法，因为它们的功能最强大，使用也最灵活，但是这也导致了它们的效率较低，较容易出错。实际使用中我们应该灵活使用各种方法，以便更好地达到我们的目的。
###守护线程
守护线程是一类特殊的线程，它和普通线程的区别在于它并不是应用程序的核心部分，当一个应用程序的所有非守护线程终止运行时，即使仍然有守护线程在运行，应用程序也将终止，反之，只要有一个非守护线程在运行，应用程序就不会终止。守护线程一般被用于在后台为其它线程提供服务。

可以通过调用方法 isDaemon() 来判断一个线程是否是守护线程，也可以调用方法 setDaemon() 来将一个线程设为守护线程。
###实例
####实例一：生产者消费者
{% highlight java %}
public class Ticket1 {
    int MAX = 10;
    int count = 0;
    public synchronized  void produce(){
        if(count == MAX){
            try {
                Thread.sleep(1000);
                wait();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        count++;
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println(Thread.currentThread().getName()+"生产了:"+count);
        this.notify();
    }

    public synchronized  void consume(){
        if(count == 0){
            try {
                this.wait();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println(Thread.currentThread().getName()+"消费了:"+ count--);
        this.notify();
    }

}
public class ConsumerProducer1 {
    public static void main(String args[]){
            Ticket1 t = new Ticket1();
            new Thread(new Producer(t),"生产者1").start();
            new Thread(new Consumer(t),"消费者1").start();
            new Thread(new Producer(t),"生产者2").start();
            new Thread(new Consumer(t),"消费者2").start();
            new Thread(new Producer(t),"生产者3").start();
            new Thread(new Consumer(t),"消费者3").start();
    }

}

class Consumer implements  Runnable{
    Ticket1 t;
    public Consumer(Ticket1 t){
        this.t = t;
    }
    public void run() {
        while(true){
            t.consume();
        }
    }
}

class Producer implements Runnable{
    Ticket1 t;
    public Producer(Ticket1 t){
        this.t = t;
    }
    public void run() {
       while(true){
            t.produce();
        }
    }
}

{% endhighlight %}
**结果输出：**
>生产者1生产了:9
生产者1生产了:10
消费者3消费了:10
消费者3消费了:9
...
...

####实例二：线程交替打印问题

**打印类**

{% highlight java %}
public class Print {
    public void print(){
           System.out.println(Thread.currentThread().getName());

    }
}
{% endhighlight %}
**线程类**

{% highlight java %}
public class PrintThread {
    public static void main(String args[]) {
        Print printA = new Print();
        Print printB = new Print();
        Print printC = new Print();
        new Thread(new PrintTh(printC, printA), "线程A").start();
        try {
            Thread.sleep(10);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        new Thread(new PrintTh(printA, printB), "线程B").start();

        try {
            Thread.sleep(10);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        new Thread(new PrintTh(printB, printC), "线程C").start();
    }
}

class PrintTh implements Runnable {
    public Print pre;
    public Print curr;

    public PrintTh(Print pre, Print curr) {
        this.pre = pre;
        this.curr = curr;
    }

    public void run() {
        int count = 10;
        while (count > 0) {
            synchronized (pre) {
                    curr.print();
                    curr.notify();
                }
                try {
                    pre.wait();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
            count--;
    }
}
{% endhighlight %}

