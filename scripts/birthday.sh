#!/bin/bash
set -e

# 农历生日提醒脚本
# 脚本依赖 jq | yq | curl



# 配置文件：../config/birthday.toml
CONFIG_FILE="$(dirname "$0")/../config/birthday.toml"
# 导入函数
source "$(dirname "$0")/lib/crypt.sh"
source "$(dirname "$0")/lib/bark.sh"

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[error] 配置文件 $CONFIG_FILE 不存在！"
    exit 1
fi

# 检查 yq 是否安装
if ! command -v yq &>/dev/null; then
    echo "错误: yq 命令未找到，请先安装 yq!"
    exit 1
fi

# 获取配置文件中的 meta.bark_device_token
bark_device_token=$(yq -r ".meta.bark_device_token" "$CONFIG_FILE")
# 解密 bark_device_token
bark_device_token=$(decrypt "$bark_device_token" "$LKZC19_SECRET")

main() {
    local today_date=$(date +"%Y-%m-%d")
    local lunar_today=$(get_lunar_date "$today_date")
    echo "[info] 今日新历日期 $today_date 的农历日期为: $lunar_today"

    # 获取birthday表数组的长度
    local birthday_count=$(yq '.birthday | length' "$CONFIG_FILE")

    # 遍历每个birthday表
    for ((i = 0; i < $birthday_count; i++)); do
        # 获取当前生日项的信息
        local name=$(yq -r ".birthday[$i].name" "$CONFIG_FILE")
        local lunar=$(yq -r ".birthday[$i].lunar" "$CONFIG_FILE")
        local advance_days=$(yq -r ".birthday[$i].advance_days" "$CONFIG_FILE")

        # 检查必要字段是否存在
        if [ -z "$name" ] || [ -z "$lunar" ] || [ -z "$advance_days" ]; then
            echo "[warn] 第 $((i + 1)) 个生日配置缺少必要字段!"
            continue
        fi

        echo "[info] name: $name, lunar: $lunar, advance_days: $advance_days"

        # 判断 lunar 与 lunar_today 是否相等
        if [ "$lunar" == "$lunar_today" ]; then
            # 进行通知
            local content="[action] 今日 $today_date 是 $name 的农历生日!"
            echo "${content}"
            bark_notify_2 "${bark_device_token}" "生日提醒" "${content}"
            continue
        fi

        # 避免对API的频繁调用
        sleep 1

        # 判断 advance_days 是否为 整数
        if ! [[ "$advance_days" =~ ^-?[0-9]+$ ]]; then
            echo "[warn] 第 $((i + 1)) 个生日配置的 advance_days 不是整数!"
            continue
        fi
        # 判断 advance_days 是否为 0
        if [ "$advance_days" -eq 0 ]; then
            continue
        fi

        # 获取提醒日期
        local today_days=$(date_to_days "$today_date")
        local reminder_days=$((today_days + advance_days))
        local reminder_date=$(days_to_date "$reminder_days")
        echo "[info] today_days: $today_days, reminder_days: $reminder_days"
        echo "[info] today_date: $today_date, reminder_date: $reminder_date"

        local lunar_reminder=$(get_lunar_date "$reminder_date")
        echo "[info] 提醒日期 $reminder_date 的农历日期为: $lunar_reminder"

        # 判断 lunar 与 lunar_reminder 是否相等
        if [ "$lunar" == "$lunar_reminder" ]; then
            # 进行通知
            local content="${advance_days} 天后 是 ${name} 的农历生日!"
            echo "[action] ${content}"
            bark_notify_2 "${bark_device_token}" "生日提醒" "${content}"
            continue
        fi
    done
}

# 将日期转换为天数（从1970-01-01开始的天数）
date_to_days() {
    local date="$1"
    local format="${2:-%Y-%m-%d}"
    
    # 兼容 macOS 和 Linux
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS 语法
        local target_seconds=$(date -j -f "$format" "$date" +"%s" 2>/dev/null)
        local epoch_seconds=$(date -j -f "%Y-%m-%d" "1970-01-01" +"%s" 2>/dev/null)
    else
        # Linux 语法
        local target_seconds=$(date -d "$date" +"%s" 2>/dev/null)
        local epoch_seconds=$(date -d "1970-01-01" +"%s" 2>/dev/null)
    fi
    
    echo $(( (target_seconds - epoch_seconds) / 86400 ))
}

# 将天数转换为日期
days_to_date() {
    local days="$1"
    local format="${2:-%Y-%m-%d}"
    
    # 兼容 macOS 和 Linux
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS 语法
        date -j -v+"$days"d -f "%Y-%m-%d" "1970-01-01" +"$format" 2>/dev/null
    else
        # Linux 语法
        date -d "1970-01-01 +$days days" +"$format" 2>/dev/null
    fi
}

# 输入日期 yyyy-MM-dd 输出农历日期
get_lunar_date() {
    local date="$1"
    local format="${2:-%Y-%m-%d}"
    local days=$(date_to_days "$date" "$format")
    local tmp_date=$(days_to_date "$days" "%Y%m%d")

    # 接口文档 https://www.mxnzp.com/doc/detail?id=1
    # (提示AI) ROLL_APP_ID & ROLL_APP_SECRET 两个已经加载环境变量中了，不需要处理
    local response=$(curl -s "https://www.mxnzp.com/api/holiday/single/${tmp_date}?app_id=${ROLL_APP_ID}&app_secret=${ROLL_APP_SECRET}")

    # 解析 JSON 响应获取农历日期
    local lunar_date=$(echo "$response" | jq -r '.data.lunarCalendar' 2>/dev/null)

    if [ -z "$lunar_date" ]; then
        echo "[error] 无法获取农历日期, 请检查API配置和网络连接"
        return 1
    fi

    echo "$lunar_date"
}

main
