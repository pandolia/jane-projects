---
title: SSH 公钥登录及端口转发
image: 143.jpg
category: Devops
---

#### 一、 配置公钥登录

（1） 检查一下服务器的 ssh 配置文件 /etc/ssh/sshd_config （ Windows OpenSSH 下，配置文件在 C:\ProgramData\ssh\sshd_config ）。

```
# 允许 root 用户登录
PermitRootLogin yes

# 启用 RSA 公钥登录
RSAAuthentication yes
PubkeyAuthentication yes

# 已授权的公钥文件路径
AuthorizedKeysFile .ssh/authorized_keys

# 允许其他主机连接本服务器的转发端口（-R 命令中的监听端口）
# 设置为 no 则不允许，为 clientspecified 则可在 -R 命令中指定
GatewayPorts yes

# 30秒发一次心跳，失败3次断开与客户端的连接
ClientAliveInterval 30
ClientAliveCountMax 3
```

Windows OpenSSH 下，需要注意要把配置文件中的下面两行注释掉：

```
# Match Group administrators
#       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
```

Linux 系统下，需要修改相应的文件及目录的权限：

```
chmod 700 /home/username
chmod 700 ~/.ssh/
chmod 600 ~/.ssh/authorized_keys
```

修改配置后重启 sshd 服务。

（2） 在客户端生成公钥和私钥：

```
mkdir ~/.ssh
cd ~/.ssh
ssh-keygen -t rsa
```

生成过程中会要求输入一个文件名，建议这里输一个名字（比如 my_id），之后会在 ~/.ssh 下生成公钥文件 my_id 和私钥文件 my_id.rsa 。注意一定要保护好你的私钥。之后在 ~/.ssh 下新建一个名为 config 的文件，输入以下内容，给公网服务器建立一个别名 myhost 。

```config
Host myhost
    HostName www.xxx.com
    User user
    IdentityFile ~/.ssh/my_id

Host *
    # 30 秒发一次心跳，失败 3 次断开与服务端的连接
    ServerAliveInterval 30
    ServerAliveCountMax 3
```

最后，将公钥 my_id 中内容加入到服务器上 ~/.ssh/authorized_keys 文件的最后一行（如果该文件不存在，则新建一个），并设置好该文件的权限，确保该文件只能被管理员和本用户看到和编辑。

在客户端执行 ssh myhost 就可以成功登录了。还可以通过 ftp 客户端 WinSCP 登录 myhost ，浏览 myhost 上的文件。

文件传输 scp 命令：

```sh
# download: remote -> local
scp user@remote_host:remote_file local_file 

# upload: local -> remote
scp local_file user@remote_host:remote_file

# 拷贝整个目录时，需加上 -r 参数。
```

#### 二、 端口转发

内网主机 A （192.168.1.125），在 80 端口运行 http 服务。有 ssh 客户端。

公网服务器 B （45.32.127.32），已开启 sshd 服务。

首先在内网主机 A 上运行：

```sh
ssh -fNR 8000:192.168.1.125:80 administrator@45.32.127.32
```

这样就把内网 192.168.1.125:80 端口暴露到公网  45.32.127.32:8000 端口了，之后访问公网地址 [http://45.32.127.32:8000](http://45.32.127.32:8000) 就可以访问到内网主机 A 上的 http 服务了。

这条命令在本地（A）和 远程服务器（B）之间建立了一条反向隧道，具体过程为：

* （1） 本地启动 ssh 进程；

* （2） ssh 进程登录远程服务器，命令远程服务器 sshd 进程开始监听 8000 端口；

* （3） sshd 在 8000 端口上接收到的任何连接请求和数据都会转发到本地的 ssh 进程，ssh 进程再将连接请求和数据转发到 192.168.1.125:80 端口，并将响应数据原路返回。

参数 R 表示建立反向隧道， N 表示不在远程服务器上执行命令， f 表示在后台运行 ssh （即便关闭终端，ssh 进程也不会被关闭）。-R 参数格式：

```sh
-R 远程监听网卡地址:端口:本地转发地址:端口
```

其中的远程监听网卡地址可以省略，使用默认网卡。这里需要注意的是，即便写成 -R 127.0.0.1:8000:192.168.1.125:80 ，8000 端口仍然被其他主机访问。只有在 GatewayPorts 设置为 clientspecified 时才能通过命令设置监听网卡。

这里还可以把 192.168.1.125:80 改成 A 所在局域网的其他服务器 ip:port ，将 A 能访问到的其他服务器的端口暴露到公网。

如果不想让所有人都访问这个服务，可以在公网服务器的防火墙上关闭 8000 端口，这样这个端口就只能被公网服务自身访问了。

然后在另一个局域网的内网主机 C （可以访问到公网服务器 B ，但访问不到内网主机 A ）运行：

```sh
ssh -fNL 80:45.32.127.32:8000 administrator@45.32.127.32
```

这样就把公网 45.32.127.32:8000 端口暴露到内网主机 C 的 80 端口了，之后在 C 访问 [http://127.0.0.1:80](http://127.0.0.1:80) 就相当于访问 [http://45.32.127.32:8000](http://45.32.127.32:8000) 。

这条命令在本地（C）和 远程服务器（B）之间建立了一条正向隧道，具体过程为：

* （1） 本地启动 ssh 进程，登录远程服务器，

* （2） 本地 ssh 进程开始监听 80 端口，任何发向此端口的连接请求都由 ssh 进程会转发到远程服务器的 sshd 进程，sshd 进程再将连接请求转发到 45.32.127.32:8000 端口。

这里同样可以将 45.32.127.32:8000 改成其他地址和端口（只要 B 可以访问到）。

-L 参数格式：

```sh
-L 本地监听网卡地址:端口:远程转发地址:端口
```

另外还有一个动态端口转发：

```sh
ssh -D 0.0.0.0:8888 user@host
```

在本地 0.0.0.0:8888 端口运行了一个 socks5 代理服务器，之后可以在 FireFox 浏览器中配置 socks5 代理服务器地址和端口为 127.0.0.1:8888 ，浏览器任何请求都先发到本地 8888 端口（本地 ssh 进程）， ssh 进程转发到远程服务器 sshd 进程，最后由远程 sshd 进程发起实际的连接，并将请求数据原路返回给本地的浏览器。

#### 三、 用端口转发实现 Windows 远程桌面控制

Windows 的远程桌面协议监听的是 3389 号端口，因此只要可以连接上某台主机的 3389 号端口，就可以实现远程桌面控制。例如：按以上的方法，把 A 主机的 3389 号端口，通过公网上的 B 主机，暴露到 C 主机本地 13389 号端口，然后在 C 主机打开远程桌面控制，连接 127.0.0.1:13389 ，输入 A 主机的域、用户名及密码，就可以在 C 主机上远程控制 A 主机了。