<h1 align="center"> Kunernetes 1.8.2 Installation in CentOS 7 </h1> 

---

<h2 id="archi">Architecture</h2>

The landscape we're going to build: 

| Machine | IP Address | Service Running | 
|:----------------|:----------------|:----------|
| M134 | 192.168.94.134 | etcd, flanneld, kube-apiserver, kube-controller-manager, kube-scheduler, kubelet, kube-proxy |
| M136 | 192.168.94.136 | etcd, flanneld,  kubelet, kube-proxy |


<h2 id="etcd"> ETCD Configuration </h2>

Before start, make sure that the firewall of CentOS has been closed:

~~~bash 
systemctl disable firewalld
systemctl stop firewalld
~~~

### The Certificates: 

There exists several ways doing the same thing, personally I respect the way proposed by CoreOS at: <a href="https://coreos.com/etcd/docs/3.2.7/op-guide/clustering.html">Clustering etcd TLS Configuration</a>. 

1. Firstly, download from cfssl( <a href="https://pkg.cfssl.org">Downloadpage</a> ) these two bins: 

~~~bash
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64

mv ./cfssl_linux-amd64 /usr/bin/cfssl && chmod +x /usr/bin/cfssl
mv ./cfssljson_linux-amd64 /usr/bin/cfssljson && chmod +x /usr/bin/cfssljson
~~~

2. clone the git repo of edcd :

> git clone https://github.com/coreos/etcd.git 

3. Copy the  etcd/hack/tls-setup repository to /root/tls-setup

4. Configure the /root/req-csr.json file put your personal ip address after the localhost

~~~json

[root@localhost tls-setup]# cat config/req-csr.json
{
  "CN": "etcd",
  "hosts": [
    "localhost",
    "192.168.94.136",
    "192.168.94.134",
    "192.168.94.131",
    "192.168.94.132",
    "192.168.94.133",
    "192.168.94.135",
    "192.168.94.137",
    "192.168.94.138"
  ],
  "key": {
    "algo": "ecdsa",
    "size": 384
  },
  "names": [
    {
      "O": "autogenerated",
      "OU": "etcd cluster",
      "L": "the internet"
    }
  ]
}
~~~

5. Install "make" and make run **make**


~~~bash
[root@localhost tls-setup]# cat Makefile
.PHONY: cfssl ca req clean

CFSSL	= @env PATH=$(GOPATH)/bin:$(PATH) cfssl
JSON	= env PATH=$(GOPATH)/bin:$(PATH) cfssljson

all: ca req

#cfssl:
#	go get -u -tags nopkcs11 github.com/cloudflare/cfssl/cmd/cfssl
#	go get -u github.com/cloudflare/cfssl/cmd/cfssljson
#	go get -u github.com/mattn/goreman

ca:
	mkdir -p certs
	$(CFSSL) gencert -initca config/ca-csr.json | $(JSON) -bare certs/ca

req:
	$(CFSSL) gencert \
	  -ca certs/ca.pem \
	  -ca-key certs/ca-key.pem \
	  -config config/ca-config.json \
	  config/req-csr.json | $(JSON) -bare certs/etcd1
	$(CFSSL) gencert \
	  -ca certs/ca.pem \
	  -ca-key certs/ca-key.pem \
	  -config config/ca-config.json \
	  config/req-csr.json | $(JSON) -bare certs/etcd2
	$(CFSSL) gencert \
	  -ca certs/ca.pem \
	  -ca-key certs/ca-key.pem \
	  -config config/ca-config.json \
	  config/req-csr.json | $(JSON) -bare certs/etcd3
	$(CFSSL) gencert \
	  -ca certs/ca.pem \
	  -ca-key certs/ca-key.pem \
	  -config config/ca-config.json \
	  config/req-csr.json | $(JSON) -bare certs/proxy1

clean:
	rm -rf certs
[root@localhost tls-setup]# cat Makefile
.PHONY: cfssl ca req clean

CFSSL	= @env PATH=$(GOPATH)/bin:$(PATH) cfssl
JSON	= env PATH=$(GOPATH)/bin:$(PATH) cfssljson

all: ca req

#cfssl:
#	go get -u -tags nopkcs11 github.com/cloudflare/cfssl/cmd/cfssl
#	go get -u github.com/cloudflare/cfssl/cmd/cfssljson
#	go get -u github.com/mattn/goreman

ca:
	mkdir -p certs
	$(CFSSL) gencert -initca config/ca-csr.json | $(JSON) -bare certs/ca

req:
	$(CFSSL) gencert \
	  -ca certs/ca.pem \
	  -ca-key certs/ca-key.pem \
	  -config config/ca-config.json \
	  config/req-csr.json | $(JSON) -bare certs/etcd1
	$(CFSSL) gencert \
	  -ca certs/ca.pem \
	  -ca-key certs/ca-key.pem \
	  -config config/ca-config.json \
	  config/req-csr.json | $(JSON) -bare certs/etcd2
	$(CFSSL) gencert \
	  -ca certs/ca.pem \
	  -ca-key certs/ca-key.pem \
	  -config config/ca-config.json \
	  config/req-csr.json | $(JSON) -bare certs/etcd3
	$(CFSSL) gencert \
	  -ca certs/ca.pem \
	  -ca-key certs/ca-key.pem \
	  -config config/ca-config.json \
	  config/req-csr.json | $(JSON) -bare certs/proxy1

clean:
	rm -rf certs
~~~

6. Distribute them to machines

For each machine: 

~~~bash
ssh root@$M134_IP yum install -y etcd
ssh root@$M134_IP mkdir -p /etc/etcd/ssl
scp /root/tls-setup/certs/ca.pem root@$M134:/etc/etcd/ssl/
scp /root/tls-setup/certs/etcd1.* root@$M134:/etc/etcd/ssl/
ssh root@$M134 chown -R etcd:etcd /etc/etcd/ssl
ssh root@$M134 "chmod -R 644 /etc/etcd/ssl/*"
ssh root@$M134 chmod 755 /etc/etcd/ssl
~~~

7. Edit /usr/lib/systemd/system/etcd.service 

In fact we can personalize the variable in /etc/etcd/etcd.conf. But for the purpose of easy maintenance, I choose to edit directly the service:

~~~
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=-/etc/etcd/etcd.conf
User=etcd
# set GOMAXPROCS to number of processors
ExecStart=/bin/bash -c "GOMAXPROCS=$(nproc) /usr/bin/etcd \
  --name "M136" \
  --initial-advertise-peer-urls https://192.168.94.136:2380 \
  --listen-peer-urls https://192.168.94.136:2380 \
  --listen-client-urls https://192.168.94.136:2379,https://127.0.0.1:2379 \
  --advertise-client-urls https://192.168.94.136:2379 \
  --initial-cluster-token etcd-cluster-1 \
  --initial-cluster M134=https://192.168.94.134:2380,M136=https://192.168.94.136:2380 \
  --initial-cluster-state new \
  --client-cert-auth \
  --trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --cert-file=/etc/etcd/ssl/etcd2.pem \
  --key-file=/etc/etcd/ssl/etcd2-key.pem \
  --peer-client-cert-auth \
  --peer-trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --peer-cert-file=/etc/etcd/ssl/etcd2.pem \
  --peer-key-file=/etc/etcd/ssl/etcd2-key.pem

Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
~~~

8. Restart Service:

> systemctl daemon-reload
> systemctl restart etcd

9. Verify the etcd nodes

**Attention** we have done the tls way, thus ancient way of verify will not work, we should indicate the pem certificate in our command: 

~~~bash
[root@localhost kubernetes1.8Install]# etcdctl --cacert=/etc/etcd/ssl/ca.pem --cert=/etc/etcd/ssl/etcd1.pem --key=/etc/etcd/ssl/etcd1-key.pem --endpoints=https://192.168.94.134:2379,https://192.168.94.136:2379 endpoint health
https://192.168.94.134:2379 is healthy: successfully committed proposal: took = 28.7663ms
https://192.168.94.136:2379 is healthy: successfully committed proposal: took = 22.780332ms
[root@localhost kubernetes1.8Install]# etcdctl --cacert=/etc/etcd/ssl/ca.pem --cert=/etc/etcd/ssl/etcd1.pem --key=/etc/etcd/ssl/etcd1-key.pem --endpoints=https://192.168.94.134:2379,https://192.168.94.136:2379 member list
157821c7d00252a2, started, M136, https://192.168.94.136:2380, https://192.168.94.136:2379
6d28ea3bc3b20778, started, M134, https://192.168.94.134:2380, https://192.168.94.134:2379
~~~

