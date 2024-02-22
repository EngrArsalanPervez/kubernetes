## How to Deploy k8s Cluster

## Build k8s Cluster

### Pre-Requisites

1. Blog: https://www.learnlinux.tv/how-to-build-an-awesome-kubernetes-cluster-using-proxmox-virtual-environment/
2. Youtube: https://www.youtube.com/watch?v=U1VzcjCB_sY
3. One VM for **k8s-ctrlr [192.168.0.5]**
4. Minimum one VM for **k8s-node [192.168.0.6]**

### k8s-ctrl

1. Change hostname in **/etc/hosts**

    ```bash
    nano /etc/hosts
      127.0.0.1       localhost
      127.0.1.1       k8s-ctrlr              
      
      # The following lines are desirable for IPv6 capable hosts
      ::1     ip6-localhost ip6-loopback
      fe00::0 ip6-localnet
      ff00::0 ip6-mcastprefix
      ff02::1 ip6-allnodes
      ff02::2 ip6-allrouters
    ```

2. Change hostname in /etc/hostname

   ```bash
   nano /etc/hostname
    k8s-ctrlr
   ```
3. Reboot
   ```bash
   reboot
   ```

### k8s-node

1. Change hostname in **/etc/hosts**

    ```bash
    nano /etc/hosts
      127.0.0.1       localhost
      127.0.1.1       k8s-node              
      
      # The following lines are desirable for IPv6 capable hosts
      ::1     ip6-localhost ip6-loopback
      fe00::0 ip6-localnet
      ff00::0 ip6-mcastprefix
      ff02::1 ip6-allnodes
      ff02::2 ip6-allrouters
    ```

2. Change hostname in /etc/hostname

   ```bash
   nano /etc/hostname
    k8s-node
   ```
3. Reboot
   ```bash
   reboot
   ```

### Installation on both k8s-ctrlr and k8s-node

#### Installing containerd

```bash
sudo apt update
sudo apt install containerd
sudo systemctl status containerd
sudo mkdir /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo nano /etc/containerd/config.toml
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
  SystemdCgroup = true
```

#### Disable swap

```bash
free -m
sudo swapoff -a
sudo nano /etc/fstab
  #comment out the line that corresponds to swap
  # /swapfile                                 none            swap    sw              0       0
```

#### Enable bridging

```bash
sudo nano /etc/sysctl.conf
  net.ipv4.ip_forward=1
```

#### Enable br_netfilter

```bash
sudo nano /etc/modules-load.d/k8s.conf
  br_netfilter
```

#### Reboot your servers

```bash
sudo reboot
```

#### Installing Kubernetes

```bash
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/kubernetes.gpg] http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list
sudo apt update
sudo apt install kubeadm kubectl kubelet
```

### k8s-node

#### Basics

```bash
sudo clout-init clean
sudo rm -rf /var/lib/cloud/instances
sudo truncate -s 0 /etc/machine-id
sudo rm /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id
ls -l /var/lib/dbus/machine-id
sudo reboot
```

### k8s-ctrlr

#### Initialize our Kubernetes cluster

```bash
sudo kubeadm init --control-plane-endpoint=192.168.0.5 --node-name k8s-ctrlr --pod-network-cidr=10.244.0.0/16
# Use the join command to run on k8s-node(s)
# kubeadm join 192.168.0.5:6443 --token 9v2xv7.5s4yy7eidanwx6yp --discovery-token-ca-cert-hash sha256:c4e201d505a370093641e6a0fd6bc724a011a00b47a2b637ab941eba0156ae78

# If for some reason the join command has expired, the following command will provide you with a new one:
# kubeadm token create --print-join-command

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl get pods --all-namespaces

kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Wait for a few seconds
kubectl get pods --all-namespaces

kubectl get nodes
```

### k8s-node

#### Join k8s-ctrlr

```bash
sudo kubeadm reset 
sudo kubeadm join 192.168.0.5:6443 --token 9v2xv7.5s4yy7eidanwx6yp --discovery-token-ca-cert-hash sha256:c4e201d505a370093641e6a0fd6bc724a011a00b47a2b637ab941eba0156ae78
```

### k8s-ctrlr

#### Check nodes

```bash
kubectl get nodes
# Wait until the STATUS = READY
# If STATUS is not READY for quit a long time, delete node and join again
```

#### Delete nodes

```bash
kubectl drain k8s-node --ignore-daemonsets --delete-emptydir-data
kubectl delete node k8s-node
```

## Deploying a container within our cluster

### k8s-ctrlr

Create the file pod.yml with the following contents:

```bash
cd Desktop
mkdir k8s
cd k8s
nano pod.yml
```

```bash
apiVersion: v1
kind: Pod
metadata:
  name: nginx-example
  labels:
    app: nginx
spec:
  containers:
    - name: nginx
      image: linuxserver/nginx
      ports:
        - containerPort: 80
          name: "nginx-http"
```

```bash
kubectl apply -f pod.yml
kubectl get pods
kubectl get pods -o wide
curl 10.244.1.2
```

### Creating a NodePort Service

```bash
nano service-nodeport.yml
```

```bash
apiVersion: v1
kind: Service
metadata:
  name: nginx-example
spec:
  type: NodePort
  ports:
    - name: http
      port: 80
      nodePort: 30080
      targetPort: nginx-http
  selector:
    app: nginx
```

```bash
kubectl apply -f service-nodeport.yml
kubectl get service
```

### Access NGINX from LAN

NGINX can be accessed either through k8s-ctrlr or k8s-node

Go to browser:

1. http://192.168.0.5:30080/
2. http://192.168.0.6:30080/