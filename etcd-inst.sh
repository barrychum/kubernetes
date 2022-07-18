apt install -y golang

git clone -b v3.4.0 http://github.com/etcd-io/etcd.git 
cd etcd/
./build.sh
cp bin/* /usr/local/bin
