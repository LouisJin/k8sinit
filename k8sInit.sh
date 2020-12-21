#!/bin/sh
#author: xiejin
#url: geekccc.com

CENTOS_VERSION=7

DOCKER_VERSION=19.03.13
CONTAINERD_VERSION=1.2.6
KUBE_VERSION=1.19.5
IS_MASTER=1
POD_NETWORK_CIDR=10.1.0.0/16
SERVICE_CIDR=10.2.0.0/16

# init params
function paramsInit(){
# auto read centos version
CENTOS_VERSION=$(cat /etc/redhat-release | awk '{match($0,/release ([0-9]{1})./,a)}{print a[1]}')
# get args params
}


# close selinux iptables firewalld
function closeForSetup(){
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
systemctl disabled iptables
systemctl stop iptables
systemctl disabled firewalld
systemctl stop firewalld
#swap off
sed -ri 's/.*swap.*/#&/' /etc/fstab
}


# use aliyun yum repo
function changeAliyunRepo(){
echo "start change aliyun yum..."
cd /etc/yum.repos.d
if [ -f CentOS-Base.repo ] && grep -wq "aliyun" CentOS-Base.repo; then
  echo "you has been changed aliyun yum"
  return
fi

if [ -f CentOS-Base.repo ]; then
  mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
fi

curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-${CENTOS_VERSION}.repo
yum clean all
yum makecache
echo "change aliyun yum ok!"
}


# install docker and use aliyun mirror and enable run the server
function dockerInit(){
if ! type docker >/dev/null 2>&1; then
echo "start install docker..."
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install -y https://mirrors.aliyun.com/docker-ce/linux/centos/${CENTOS_VERSION}/x86_64/stable/Packages/containerd.io-1.3.9-3.1.el${CENTOS_VERSION}.x86_64.rpm
yum install -y docker-ce-${DOCKER_VERSION} docker-ce-cli-${DOCKER_VERSION}
fi

if [ ! -f /etc/docker/daemon.json ] || ! grep -wq "aliyun" /etc/docker/daemon.json; then
mkdir -p /etc/docker
cat>/etc/docker/daemon.json<<EOF
{
  "registry-mirrors": ["https://1mpvrtkb.mirror.aliyuncs.com"]
}
EOF
fi

systemctl enable docker
systemctl daemon-reload
systemctl restart docker
}


# install kubelet kubeadm (kubectl)
function kubeInit(){
if [ ! -f /etc/yum.repos.d/kubernetes.repo ]; then
cat>/etc/yum.repos.d/kubernetes.repo<<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
fi

if ! type kubelet >/dev/null 2>&1; then
yum -y install kubelet-${KUBE_VERSION} --disableexcludes=kubernetes
fi
if ! type kubeadm >/dev/null 2>&1; then
yum -y install kubeadm-${KUBE_VERSION} --disableexcludes=kubernetes
fi
if [ ${IS_MASTER} -eq 1 ] && ! type kubectl >/dev/null 2>&1; then
yum -y install kubectl-${KUBE_VERSION} --disableexcludes=kubernetes
fi

systemctl enable kubelet && systemctl restart kubelet
echo "1" >/proc/sys/net/bridge/bridge-nf-call-iptables
kubeadm reset -f
kubeadm init --kubernetes-version=v${KUBE_VERSION} --pod-network-cidr=${POD_NETWORK_CIDR} --service-cidr=${SERVICE_CIDR}
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
} 


paramsInit
closeForSetup
changeAliyunRepo
dockerInit
kubeInit