git clone -b v3.5.0 http://github.com/etcd-io/etcd.git 
cd etcd/
apt install -y golang
./build.sh
cp bin/* /usr/local/bin
