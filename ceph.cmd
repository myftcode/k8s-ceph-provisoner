ceph osd pool create k8s 128
ceph auth get-or-create client.k8s mon 'allow r' osd 'allow rwx pool=k8s' -o ceph.client.k8s.keyring

key_encrypt=`grep key ceph.client.k8s.keyring | awk '{printf "%s", $NF}' | base64`
cat > k8s.secret.yml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ceph-k8s-secret
type: "kubernetes.io/rbd"
data:
  key: $key_encrypt

EOF

mkdir ./ceph-rbd-provisor && cd ./ceph-rbd-provisor
for i in clusterrole.yaml clusterrolebinding.yaml deployment.yaml serviceaccount.yaml role.yaml rolebinding.yaml;
do 
   wget https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/ceph/rbd/deploy/rbac/$i
done
