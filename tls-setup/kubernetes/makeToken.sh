head -c 16 /dev/urandom | od -An -t x | tr -d " " > ./randomToken
TOKEN=$(cat ./randomToken)
cat > /etc/kubernetes/token.csv << EOF
${TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF


