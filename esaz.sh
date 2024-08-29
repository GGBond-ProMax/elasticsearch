#!/bin/bash
# Elasticsearch Installation Script

# 定义变量
path="/wget/es"
es_version="7.17.14"
es_tar="elasticsearch-${es_version}-linux-x86_64.tar.gz"
es_dir="elasticsearch-${es_version}"
data_path="${path}/${es_dir}/data"
logs_path="${path}/${es_dir}/logs"

# 检查目录是否存在
if [ -d "$path" ]; then
    echo "目录已存在"
else
    echo "目录不存在，正在创建..."
    mkdir -p "$path"
fi

# 进入目录
cd "$path" || { echo "无法进入目录 $path"; exit 1; }

# 下载Elasticsearch
wget "https://artifacts.elastic.co/downloads/elasticsearch/${es_tar}"

# 解压Elasticsearch
tar -zxvf "${es_tar}" -C "$path"

# 进入Elasticsearch目录
cd "$es_dir" || { echo "无法进入目录 $es_dir"; exit 1; }

# 检查并创建数据目录
if [ ! -d "$data_path" ]; then
    echo "数据目录不存在，正在创建..."
    mkdir -p "$data_path"
fi

# 检查并创建日志目录
if [ ! -d "$logs_path" ]; then
    echo "日志目录不存在，正在创建..."
    mkdir -p "$logs_path"
fi

# 编辑配置文件
cat <<EOL > config/elasticsearch.yml
cluster.name: test-elasticsearch
node.name: es-node1
path.data: /wget/es/elasticsearch-7.17.14/data
path.logs: /wget/es/elasticsearch-7.17.14/logs
network.host: 0.0.0.0
http.port: 9200
cluster.initial_master_nodes: ["es-node1"]
# xpack.security.enabled: true
# xpack.security.transport.ssl.enabled: true
EOL

# 创建es用户（如果不存在）
if ! id -u es &>/dev/null; then
    useradd es
fi

# 重启es，初始化密码
./bin/elasticsearch -d
./bin/elasticsearch-setup-passwords interactive

# 赋予es用户权限
chown -R es:es "$path"

# 创建systemd服务文件
sudo bash -c 'cat <<EOL > /etc/systemd/system/elasticsearch.service
[Unit]
Description=Elasticsearch
Documentation=https://www.elastic.co
Requires=network-online.target
After=network-online.target

[Service]
User=es
Group=es
Environment="ES_HOME=/wget/es/elasticsearch-7.17.14"
ExecStart=/wget/es/elasticsearch-7.17.14/bin/elasticsearch
Restart=always
LimitNOFILE=65535
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOL'

# 重新加载systemd配置，启动Elasticsearch并设置为开机自启
sudo systemctl daemon-reload
sudo systemctl start elasticsearch
sudo systemctl enable elasticsearch

# 检查Elasticsearch状态
sudo systemctl status elasticsearch
