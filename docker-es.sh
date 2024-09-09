#!/bin/bash

# 定义 Elasticsearch 镜像
ELASTICSEARCH_IMAGE="elasticsearch:7.17.14"

# 定义数据目录路径
ES_DATADIR="/esdatadir"
CONFIG_DIR="${ES_DATADIR}/config"
DATA_DIR="${ES_DATADIR}/data"
LOGS_DIR="${ES_DATADIR}/logs"

# 复制当前目录下的 config 文件夹到目标目录
echo "将当前目录下的配置文件移动到 $CONFIG_DIR..."
if [ -d "./config" ]; then
    mv ./config "$ES_DATADIR"
else
    echo "当前目录下没有找到 config 目录。"
    exit 1
fi

# 检查是否已安装 Docker
if ! command -v docker &> /dev/null; then
    echo "Docker 未安装，请先安装 Docker。"
    exit 1
fi

# 复制配置文件到目标目录
echo "将配置文件移动到 $CONFIG_DIR..."
mv config "$ES_DATADIR"

# 创建目标目录
echo "检查并创建目录..."
if [ ! -d "$ES_DATADIR" ]; then
    echo "创建数据目录: $ES_DATADIR"
    mkdir -p "$ES_DATADIR"
fi

if [ ! -d "$CONFIG_DIR" ]; then
    echo "创建配置目录: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
fi

if [ ! -d "$DATA_DIR" ]; then
    echo "创建数据目录: $DATA_DIR"
    mkdir -p "$DATA_DIR"
fi

if [ ! -d "$LOGS_DIR" ]; then
    echo "创建日志目录: $LOGS_DIR"
    mkdir -p "$LOGS_DIR"
fi

# 拉取 Elasticsearch 镜像
echo "拉取 Elasticsearch 镜像 ${ELASTICSEARCH_IMAGE}..."
docker pull ${ELASTICSEARCH_IMAGE}

# 运行 Elasticsearch 容器
echo "运行 Elasticsearch 容器..."
docker run --restart=always \
    -p 9200:9200 \
    -e "discovery.type=single-node" \
    -e "ELASTIC_PASSWORD=123456" \
    -e ES_JAVA_OPTS="-Xms1g -Xmx1g" \
    --name docker-es \
    -d \
    -v "$CONFIG_DIR:/usr/share/elasticsearch/config" \
    -v "$DATA_DIR:/usr/share/elasticsearch/data" \
    -v "$LOGS_DIR:/usr/share/elasticsearch/logs" \
    ${ELASTICSEARCH_IMAGE}

echo "Elasticsearch 容器已启动。"

