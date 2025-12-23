#!/bin/bash
set -e

_bark_url="https://api.day.app"

bark_notify_1() {
    local device_token="$1"
    local content="$2"

    local encoded_content=$(echo -n "$content" | jq -s -R -r @uri)
    local url="${_bark_url}/${device_token}/${encoded_content}"
    # 获取完整的JSON响应
    local response=$(curl -s "${url}")
    
    # 使用jq提取code字段
    local code=$(echo "$response" | jq -r '.code')
    
    # 判断code是否为200
    if [ "$code" != "200" ]; then
        # 使用jq提取message字段
        local message=$(echo "$response" | jq -r '.message')
        echo "[error] 通知失败: ${message}"
        return 1
    fi

    echo "[info] 通知成功"
    return 0
}

bark_notify_2() {
    local device_token="$1"
    local title="$2"
    local content="$3"

    local encoded_title=$(echo -n "$title" | jq -s -R -r @uri)
    local encoded_content=$(echo -n "$content" | jq -s -R -r @uri)
    local url="${_bark_url}/${device_token}/${encoded_title}/${encoded_content}"
    # 获取完整的JSON响应
    local response=$(curl -s "${url}")
    
    # 使用jq提取code字段
    local code=$(echo "$response" | jq -r '.code')
    
    # 判断code是否为200
    if [ "$code" != "200" ]; then
        # 使用jq提取message字段
        local message=$(echo "$response" | jq -r '.message')
        echo "[error] 通知失败: ${message}"
        return 1
    fi

    echo "[info] 通知成功"
    return 0
}