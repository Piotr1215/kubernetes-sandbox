sudo apt-get update \
  && sudo apt-get install -yq \
  kubelet \
  kubeadm \
  kubernetes-cni

sudo apt-mark hold kubelet kubeadm kubectl