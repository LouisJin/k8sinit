# k8sinit
## k8s学习环境一键安装脚本

### 适用环境

* CentOS 7 及以上

### 默认配置

**配置可通过下载sh文件自行更改** 

* `Docker` 版本 19.03.13
* `CONTAINERD` 版本1.2.6
* `KUBE` 版本1.19.5
* `POD_NETWORK_CIDR` 地址10.1.0.0/16
* `SERVICE_CIDR` 地址10.2.0.0/16
* `IS_MASTER` 默认为master节点 为0则为node

### 脚本功能

* 关闭`selinux`  `iptables`  `firewalld`  `swap` 
* 切换yum源为阿里云的源
* `docker`初始化安装， 使用阿里云镜像加速，启动docker服务
* `kubelet`  `kubeadm`  `kubectl`  工具安装，使用阿里云仓库加速，如果是`Node` 则不安装 `kubectl` ，启动`kubelet` 服务，`kubeadm` 初始化

### 执行方法

```shell
curl https://raw.githubusercontent.com/LouisJin/k8sinit/main/k8sInit.sh -o k8sInit.sh && chmod +x k8sInit.sh && ./k8sInit.sh
```

