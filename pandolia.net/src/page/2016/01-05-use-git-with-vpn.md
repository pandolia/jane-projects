---
title: 用 VPN 上网时如何使用 Git
image: 649.jpg
category: Devops
---

使用 VPN 上网时，如果使用 git 向远程仓库 push 代码，可能会出现下面的错误：

    $ git push
    ssh: connect to host github.com port 22: Connection timed out
    fatal: Could not read from remote repository.

google 到 stackoverflow 有人问了同样的问题： [git push pull times out](http://stackoverflow.com/questions/757432/git-push-pull-times-out/757462#757462) ，上面给出的原因和解决办法是：“This sort of effect is usually due to the VPN setup routing all your traffic over the VPN. You can work around that by updating your routing tables to route traffic to github back over your Ethernet (I assume) interface rather than over the VPN. For example **route add 65.74.177.129 eth0** will route traffic to github over eth0. ” 意思是 VPN 开启后会将所有数据都通过 VPN 传递，解决方法是更新路由表使所有发送到（或接收） github 的数据都通过原来的网卡来传递。

但按上面给出的命令 **route add 65.74.177.129 eth0** 设置后问题却仍然没有解决。google到一篇博文 [how to do git push under vpn](http://matrix207.github.io/2014/04/25/how-to-do-git-push-under-vpn) ，提出了需要设置网关，但按此文的方法设置后还是不行。

再 google 了一下 route 的使用，搜到这样一篇博文： [route 详解](http://www.cnblogs.com/longzhongren/p/4220599.html)，上面有一条这样的命令及解释：

    # route add -net 192.168.0.0 netmask 255.255.255.0 gw 192.168.30.1 dev eth1
    # 新增路由规则：所有以 192.168.*.* 开头的 IP 的数据的网关是 192.168.30.1 ，并通过 eth1 进出

按此命令重新设置了一下，问题得以解决。详细步骤如下：

首先用 **ping** 命令获取 github 的 IP 地址：

    $ ping github.com
    PING github.com (192.30.252.130) 56(84) bytes of data.

然后用 **route** 命令查看一下路由表：

    # su
    # route
    Kernel IP routing table
    Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
    default         *               0.0.0.0         U     1024   0        0 ppp0
    10.0.0.4        *               255.255.255.255 UH    0      0        0 ppp0
    192.168.31.0    *               255.255.255.0   U     0      0        0 eth0
    203.79.187.188  192.168.31.1    255.255.255.255 UGH   0      0        0 eth0

可以看到本机有两个连接，一个是 VPN 连接（也就是 ppp0 ），另一个是以太网卡连接（eth0），若使用无线网卡上网，这里可能是 wlan0 。另外可以看到一个网关地址 **192.168.31.1** 。现在把通向 **github** 的数据指定到 **eth0** 进出就可以了，命令为：

    # route add -net 192.30.252.0 netmask 255.255.255.0 gw 192.168.31.1 dev eth0

设置后，可以正常运行 **git push** 命令了。

为了开机自动添加此路由规则，打开 **/etc/rc.local** ，将此命令添加至此文件。