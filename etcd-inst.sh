git clone http://github.com/etcd-io/etcd.git etcdsrc
cd etcdsrc
apt install -y golang
./build
cp bin/* /usr/local/bin
