#!/bin/bash

echo "[INSTALLATION START] For Ubuntu 16.04+ \n installation is designed to work with Packet bare metal servers"

hostip=$(hostname  -I | cut -f1 -d' ')

# Install docker usinga apt-get
echo "[STEP 1] Installing Docker"
sudo apt-get update \
  && sudo apt-get install -qy docker.io

# Add repos for kubeadm and kubectl
echo "[STEP 2] Adding kubeadm and kubectl repos"
sudo apt-get update \
  && sudo apt-get install -y apt-transport-https \
  && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# Update kubernetes package
echo "[STEP 3] Updating Kubernetes package"
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" \
  | sudo tee -a /etc/apt/sources.list.d/kubernetes.list \
  && sudo apt-get update

# Install Kubernetes components
echo "[STEP 4] Installing Kubernetes (kubeadm, kubelet, kubectl and kubernetes-cni)"
sudo apt-get update \
  && sudo apt-get install -yq \
  kubelet \
  kubeadm \
  kubernetes-cni

# Start and Enable kubelet service
echo "[STEP 5] Putting kubelet kubeadm kubectl on hold to avoid unexpected upgrades"
sudo apt-mark hold kubelet kubeadm kubectl

# Install Openssh server
echo "[STEP 6] Disabling swap and making change in fstab file for permament disable"
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Set Root password
echo "[STEP 7] Install additional packages"
sudo apt-get update \
  && sudo apt-get install -yq \
  wget \

# Install additional required packages
echo "[STEP 8] Installing k9s"
(
  set -x &&
  wget -c https://github.com/derailed/k9s/releases/download/v0.13.4/k9s_0.13.4_Linux_x86_64.tar.gz -O - | tar -xz &&
  chmod +x k9s &&
  mv k9s /usr/local/bin/
)

#######################################
# To be executed only on master nodes #
#######################################

if [[ $(hostname) =~ *master* ]]
then

  # Initialize Kubernetes
  echo "[STEP 9] Initialize Kubernetes Cluster"
  sudo kubeadm init --apiserver-advertise-address="$hostip" --kubernetes-version stable-1.17

  # Copy Kube admin config
  echo "[STEP 10] Copy kube admin config to root user .kube directory"
  cd $HOME
  sudo cp /etc/kubernetes/admin.conf $HOME/
  sudo chown $(id -u):$(id -g) $HOME/admin.conf
  echo "export KUBECONFIG=$HOME/admin.conf" | tee -a ~/.bashrc
  source ~/.bashrc

  # Deploy flannel network
  echo "[STEP 11] Deploy Weave network"
  sudo mkdir -p /var/lib/weave
  head -c 16 /dev/urandom | shasum -a 256 | cut -d" " -f1 | sudo tee /var/lib/weave/weave-passwd

  kubectl create secret -n kube-system generic weave-passwd --from-file=/var/lib/weave/weave-passwd

  kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&password-secret=weave-passwd&env.IPALLOC_RANGE=192.168.0.0/24"

  # Generate Cluster join command
  echo "[STEP 12] Generate and save cluster join command to /joincluster.sh"
  joinCommand=$(kubeadm token create --print-join-command 2>/dev/null)
  echo "$joinCommand --ignore-preflight-errors=all" > /root/joincluster.sh

fi

#################################################
# TODO: Figure out how to transfer joincommand  #
# file to worker node and execute joing command #
# To be executed only on worker nodes           #
#################################################

