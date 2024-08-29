#!/bin/bash

# 定义变量
es_host="http://localhost:9200"
es_user="elastic"
es_pass="123456"
snapshot_repo_name="my_backup"
snapshot_name="snapshot_$(date +%Y%m%d%H%M%S)"
snapshot_dir="/wget/es/elasticsearch-7.17.14/backup"

# 检查快照仓库是否存在
# 输出200是成功访问，输出404是没有找到网页信息，输出500是服务器出现错误
repository_exists() {
    echo "检查快照仓库是否存在..."

    response=$(curl -u "$es_user:$es_pass" -s -o /dev/null -w "%{http_code}" "$es_host/_snapshot/$snapshot_repo_name")

    if [ "$response" -eq 200 ]; then
        echo "快照仓库已存在"
        return 0
    elif [ "$response" -eq 404 ]; then
        echo "快照仓库不存在"
        return 1
    else
        echo "无法检查快照仓库状态"
        exit 1
    fi
}

# 创建快照仓库
create_repository() {
    echo "创建快照仓库..."

    curl -u "$es_user:$es_pass" -X PUT "$es_host/_snapshot/$snapshot_repo_name" -H 'Content-Type: application/json' -d'
    {
      "type": "fs",                                         // 确定文件类型 
      "settings": {
        "location": "'"$snapshot_dir"'",     // 路径
        "compress": true                             // 是否压缩
      }
    }
    '

    if [ $? -eq 0 ]; then
        echo "快照仓库创建成功"
    else
        echo "快照仓库创建失败"
        exit 1
    fi
}

# 执行快照
create_snapshot() {
    echo "创建快照..."

    curl -u "$es_user:$es_pass" -X PUT "$es_host/_snapshot/$snapshot_repo_name/$snapshot_name?wait_for_completion=true" -H 'Content-Type: application/json' -d'
    {
      "indices": "*",                                 // 指定要包含在快照中的索引
      "ignore_unavailable": true,          // 设置是否忽略不可用的索引
      "include_global_state": true        // 指定是否包括全局集群状态
    }
    '

    if [ $? -eq 0 ]; then
        echo "快照创建成功"
    else
        echo "快照创建失败"
        exit 1
    fi
}

# 检查快照状态
check_snapshot_status() {
    echo "检查快照状态..."

    curl -u "$es_user:$es_pass" -X GET "$es_host/_snapshot/$snapshot_repo_name/$snapshot_name/_status" -H 'Content-Type: application/json'

    if [ $? -eq 0 ]; then
        echo "快照状态检查完成"
    else
        echo "快照状态检查失败"
        exit 1
    fi
}

# 确保快照目录存在
if [ ! -d "$snapshot_dir" ]; then
    echo "快照目录不存在，正在创建..."
    mkdir -p "$snapshot_dir"
    chown -R es:es "$snapshot_dir"
fi

# 执行步骤
if ! repository_exists; then
    create_repository
fi
create_snapshot
check_snapshot_status

