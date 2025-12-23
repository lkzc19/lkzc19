#!/bin/bash
set -e

source "$(dirname "$0")/crypt.sh"
source "$(dirname "$0")/bark.sh"

device_token=$(decrypt "g2JztZW29NKsxY22nrXfSZ" "$LKZC19_SECRET")
content="测试通知"
title="测试标题"

bark_notify_1 "${device_token}" "${content}"
bark_notify_2 "${device_token}" "${title}" "${content}"
