#!/bin/bash
set -e

source "$(dirname "$0")/crypt.sh"

# 测试新的AES加密解密功能
plaintext="zxc"
secret="zxc"

echo "=== 测试AES加密解密 ==="
echo "原始文本: $plaintext"

# 先加密生成新的密文
encrypted=$(encrypt "$plaintext" "$secret")
echo "加密后: $encrypted"

# 再解密验证
decrypted=$(decrypt "$encrypted" "$secret")
echo "解密后: $decrypted"

# 验证结果
if [ "$plaintext" = "$decrypted" ]; then
    echo "✓ 测试通过：解密后的文本与原始文本一致"
else
    echo "✗ 测试失败：解密后的文本与原始文本不一致"
    exit 1
fi
