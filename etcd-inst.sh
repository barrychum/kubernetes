apt install -y golang

cd /tmp
rm -rf etcd
git clone -b v3.4.0 https://github.com/etcd-io/etcd.git 
cd etcd
./build
cp bin/* /usr/local/bin
