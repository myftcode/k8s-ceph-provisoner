# k8s v1.13.2 使用ceph的rbd作为动态存储类的后端磁盘

- 文件test.pvc.yaml：创建pvc，用storageclass自动创建pv
- 文件test.nginx.yaml：创建一个nginx应用来使用存储


# 部署时使用的命令
## 1.创建ceph的rbd存储池
```
ceph osd pool create k8s 128
```
## 2.创建使用指定存储池的用户
```
ceph auth get-or-create client.k8s mon 'allow r' osd 'allow rwx pool=k8s' -o ceph.client.k8s.keyring
```
## 3.下载rbac文件(已把默认名称空间的改为了kube-system)
```
mkdir ./ceph-rbd-provisor && cd ./ceph-rbd-provisor
for i in clusterrole.yaml clusterrolebinding.yaml deployment.yaml serviceaccount.yaml role.yaml rolebinding.yaml;
do 
   wget https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/ceph/rbd/deploy/rbac/$i
done
```
## 4.应用rbac文件
```
kubectl apply -f ./
```

## 5.创建秘钥文件
```
key_encrypt=`grep key ceph.client.k8s.keyring | awk '{printf "%s", $NF}' | base64`
cat > k8s.secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ceph-k8s-secret
  namespace: kube-system
type: "kubernetes.io/rbd"
data:
  key: $key_encrypt
EOF
```
## 6.创建存储类文件
```
cat > k8s.storageclass.yaml <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: mycephrbd
provisioner: ceph.com/rbd
reclaimPolicy: Retain
parameters:
  monitors: 192.168.59.41:6789,192.168.59.42:6789
  adminId: k8s
  adminSecretName: ceph-k8s-secret
  adminSecretNamespace: kube-system
  pool: k8s
  userId: k8s
  userSecretName: ceph-k8s-secret
  imageFormat: "2"
  imageFeatures: layering
EOF
```
## 7.应用密钥文件和存储类文件
```
kubectl apply -f k8s.secret.yaml
kubectl apply -f k8s.storageclass.yaml
```
