#!/bin/bash
set -e

# 简单的字符映射加密解密算法，纯shell实现，不依赖第三方工具

# 字符集：包含可打印ASCII字符（使用单引号定义，避免转义问题）
CHAR_SET='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
CHAR_COUNT=${#CHAR_SET}

# 获取字符在字符集中的索引
_char_index() {
    local char="$1"
    local index=0
    local i=0
    
    while [ $i -lt $CHAR_COUNT ]; do
        if [ "${CHAR_SET:$i:1}" = "$char" ]; then
            echo $i
            return
        fi
        i=$((i+1))
    done
    
    # 如果字符不在字符集中，返回0
    echo 0
}

# 获取字符集中指定索引的字符
_index_char() {
    local index="$1"
    # 确保索引在有效范围内
    local normalized_index=$((index % CHAR_COUNT))
    if [ $normalized_index -lt 0 ]; then
        normalized_index=$((normalized_index + CHAR_COUNT))
    fi
    
    echo -n "${CHAR_SET:$normalized_index:1}"
}

# 生成密钥流：基于密码生成重复的密钥索引流
key_stream() {
    local secret="$1"
    local length="$2"
    local stream=""
    local i=0
    
    while [ $i -lt $length ]; do
        local char=${secret:$((i % ${#secret})):1}
        local index=$(_char_index "$char")
        stream+="$index "
        i=$((i+1))
    done
    
    echo -n "$stream"
}

# 加密函数：纯shell实现，不依赖第三方工具
encrypt() {
    local plaintext="$1"
    local secret="$2"
    local ciphertext=""
    local i=0
    
    # 生成密钥流
    local stream=$(key_stream "$secret" "${#plaintext}")
    local key_indices=($stream)
    
    # 逐字符加密
    while [ $i -lt ${#plaintext} ]; do
        local plain_char=${plaintext:$i:1}
        local plain_index=$(_char_index "$plain_char")
        local key_index=${key_indices[$i]}
        
        # 加密变换：字符索引 + 密钥索引
        local cipher_index=$((plain_index + key_index))
        local cipher_char=$(_index_char "$cipher_index")
        
        ciphertext+="$cipher_char"
        i=$((i+1))
    done
    
    echo -n "$ciphertext"
}

# 解密函数：纯shell实现，不依赖第三方工具
decrypt() {
    local ciphertext="$1"
    local secret="$2"
    local plaintext=""
    local i=0
    
    # 生成密钥流
    local stream=$(key_stream "$secret" "${#ciphertext}")
    local key_indices=($stream)
    
    # 逐字符解密
    while [ $i -lt ${#ciphertext} ]; do
        local cipher_char=${ciphertext:$i:1}
        local cipher_index=$(_char_index "$cipher_char")
        local key_index=${key_indices[$i]}
        
        # 解密变换：字符索引 - 密钥索引
        local plain_index=$((cipher_index - key_index))
        local plain_char=$(_index_char "$plain_index")
        
        plaintext+="$plain_char"
        i=$((i+1))
    done
    
    echo -n "$plaintext"
}
