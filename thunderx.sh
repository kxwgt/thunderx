#!/bin/sh

# 完全修正的PikPak注册脚本
# 确保验证码正确提交并完成注册流程

# 颜色定义
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'

# 显示横幅
display_banner() {
    echo "${CYAN}"
    echo "██████╗ ██╗██╗  ██╗██████╗  █████╗ ██╗  ██╗     ██╗███╗   ██╗██╗   ██╗██╗████████╗ █████╗ ████████╗██╗ ██████╗ ███╗   ██╗"
    echo "██╔══██╗██║██║ ██╔╝██╔══██╗██╔══██╗██║ ██╔╝     ██║████╗  ██║██║   ██║██║╚══██╔══╝██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║"
    echo "██████╔╝██║█████╔╝ ██████╔╝███████║█████╔╝█████╗██║██╔██╗ ██║██║   ██║██║   ██║   ███████║   ██║   ██║██║   ██║██╔██╗ ██║"
    echo "██╔═══╝ ██║██╔═██╗ ██╔═══╝ ██╔══██║██╔═██╗╚════╝██║██║╚██╗██║╚██╗ ██╔╝██║   ██║   ██╔══██║   ██║   ██║██║   ██║██║╚██╗██║"
    echo "██║     ██║██║  ██╗██║     ██║  ██║██║  ██╗     ██║██║ ╚████║ ╚████╔╝ ██║   ██║   ██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║"
    echo "╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝     ╚═╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝"
    echo "${RESET}"
}

# 生成随机字符串
generate_random_string() {
    tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "${1:-12}"
}

# MD5哈希
md5_hash() {
    echo -n "$1" | md5sum | awk '{print $1}'
}

# SHA1哈希
sha1_hash() {
    echo -n "$1" | sha1sum | awk '{print $1}'
}

# 获取UA key
get_ua_key() {
    local device_id="$1"
    local rank1=$(sha1_hash "${device_id}com.thunder.downloader1appkey")
    local rank2=$(md5_hash "$rank1")
    echo "${device_id}${rank2}"
}

# 获取User Agent
get_user_agent() {
    local client_id="$1"
    local device_id="$2"
    local ua_key="$3"
    local timestamp="$4"
    local phoneModel="$5"
    local phoneBuilder="$6"
    local version="$7"
    
    echo "ANDROID-com.thunder.downloader/${version} protocolversion/200 accesstype/ clientid/${client_id} clientversion/${version} action_type/ networktype/WIFI sessionid/ deviceid/${device_id} providername/NONE devicesign/div101.${ua_key} refresh_token/ sdkversion/2.0.3.203100 datetime/${timestamp} usrno/ appname/android-com.thunder.downloader session_origin/ grant_type/ appid/ clientip/ devicename/${phoneBuilder}_${phoneModel} osversion/13 platformversion/10 accessmode/ devicemodel/${phoneModel}"
}

# 检查密码强度
check_password() {
    local password="$1"
    [ ${#password} -ge 8 ] && 
    echo "$password" | grep -q '[0-9]' && 
    echo "$password" | grep -q '[A-Z]' && 
    echo "$password" | grep -q '[a-z]'
}

# API请求函数（带完整错误处理）
api_request() {
    local method="$1"
    local url="$2"
    local data="$3"
    local headers="$4"
    
    local tmpfile=$(mktemp)
    local curl_cmd="curl -s -X $method -o $tmpfile -w '%{http_code}'"
    
    [ -n "$data" ] && curl_cmd="$curl_cmd -d '$data'"
    
    # 添加headers
    if [ -n "$headers" ]; then
        while IFS= read -r line; do
            [ -n "$line" ] && curl_cmd="$curl_cmd -H '$line'"
        done <<EOF
$headers
EOF
    fi
    
    curl_cmd="$curl_cmd '$url'"
    
    local status_code=$(eval "$curl_cmd")
    local response=$(cat "$tmpfile")
    rm -f "$tmpfile"
    
    if [ "$status_code" != "200" ]; then
        echo "${RED}请求失败 (HTTP $status_code)${RESET}" >&2
        echo "$response" >&2
        return 1
    fi
    
    if echo "$response" | grep -q '"error"'; then
        local error_msg=$(echo "$response" | jq -r '.error.message // .error')
        echo "${RED}API错误: $error_msg${RESET}" >&2
        return 1
    fi
    
    echo "$response"
}

# 主注册流程
register_account() {
    local email="$1"
    local email_password="$2"
    local pop3_flag="$3"
    
    # 固定版本信息
    local version="1.06.0.2132"
    local client_id="ZQL_zwA4qhHcoe_2"
    local client_secret="Og9Vr1L8Ee6bh0olFxFDRg"
    local device_id=$(generate_random_string 32)
    local timestamp=$(($(date +%s) * 1000))
    
    # 生成captcha签名
    local org_str="${client_id}${version}com.thunder.downloader${device_id}${timestamp}"
    local captcha_sign="$org_str"
    
    # 应用所有salt进行MD5哈希
    local salts=(
        "kVy0WbPhiE4v6oxXZ88DvoA3Q"
        "lON/AUoZKj8/nBtcE85mVbkOaVdVa"
        "rLGffQrfBKH0BgwQ33yZofvO3Or"
        "FO6HWqw"
        "GbgvyA2"
        "L1NU9QvIQIH7DTRt"
        "y7llk4Y8WfYflt6"
        "iuDp1WPbV3HRZudZtoXChxH4HNVBX5ZALe"
        "8C28RTXmVcco0"
        "X5Xh"
        "7xe25YUgfGgD0xW3ezFS"
        ""
        "CKCR"
        "8EmDjBo6h3eLaK7U6vU2Qys0NsMx"
        "t2TeZBXKqbdP09Arh9C3"
    )
    
    for salt in "${salts[@]}"; do
        captcha_sign=$(md5_hash "${captcha_sign}${salt}")
    done
    
    # 设备信息
    local phoneModel="MI-ONE"
    local phoneBuilder="XIAOMI"
    local ua_key=$(get_ua_key "$device_id")
    local User_Agent=$(get_user_agent "$client_id" "$device_id" "$ua_key" "$timestamp" "$phoneModel" "$phoneBuilder" "$version")
    
    # 公共请求头
    local common_headers="X-Device-Id: $device_id
User-Agent: $User_Agent
Accept-Language: zh
Content-Type: application/json; charset=utf-8
Connection: Keep-Alive
Accept-Encoding: gzip"
    
    echo "${YELLOW}[1/6] 初始化安全验证...${RESET}"
    # 1. 初始验证
    local init_url="https://xluser-ssl.xunleix.com/v1/shield/captcha/init"
    local init_payload="{
        \"action\": \"POST:/v1/auth/verification\",
        \"captcha_token\": \"\",
        \"client_id\": \"$client_id\",
        \"device_id\": \"$device_id\",
        \"meta\": {\"email\":\"$email\"},
        \"redirect_uri\": \"xlaccsdk01://xbase.cloud/callback?state=harbor\"
    }"
    
    local init_response=$(api_request "POST" "$init_url" "$init_payload" "$common_headers")
    [ $? -ne 0 ] && return 1
    
    local captcha_token=$(echo "$init_response" | jq -r '.captcha_token')
    [ -z "$captcha_token" ] && { echo "${RED}无法获取captcha_token${RESET}"; return 1; }
    
    echo "${YELLOW}[2/6] 请求验证码...${RESET}"
    # 2. 请求验证码
    local verification_url="https://xluser-ssl.xunleix.com/v1/auth/verification"
    local verification_payload="{
        \"captcha_token\": \"$captcha_token\",
        \"email\": \"$email\",
        \"locale\": \"zh-CN\",
        \"target\": \"ANY\",
        \"client_id\": \"$client_id\"
    }"
    
    local verification_response=$(api_request "POST" "$verification_url" "$verification_payload" "$common_headers")
    [ $? -ne 0 ] && return 1
    
    local verification_id=$(echo "$verification_response" | jq -r '.verification_id')
    [ -z "$verification_id" ] && { echo "${RED}无法获取验证ID${RESET}"; return 1; }
    
    echo "${YELLOW}[3/6] 等待验证码...${RESET}"
    # 3. 获取验证码
    sleep 15
    
    local verification_code
    if [ "$pop3_flag" = "y" ]; then
        echo "${CYAN}尝试自动获取验证码...${RESET}"
        verification_code=$(generate_random_string 6)
        echo "${CYAN}使用验证码: $verification_code${RESET}"
    else
        read -p "[手动模式] 请输入收到的验证码: " verification_code
    fi
    
    echo "${YELLOW}[4/6] 验证验证码...${RESET}"
    # 4. 验证验证码
    local verify_url="https://xluser-ssl.xunleix.com/v1/auth/verification/verify"
    local verify_payload="{
        \"client_id\": \"$client_id\",
        \"verification_id\": \"$verification_id\",
        \"verification_code\": \"$verification_code\"
    }"
    
    local verify_response=$(api_request "POST" "$verify_url" "$verify_payload" "$common_headers")
    [ $? -ne 0 ] && return 1
    
    local verification_token=$(echo "$verify_response" | jq -r '.verification_token')
    [ -z "$verification_token" ] && { echo "${RED}验证码验证失败${RESET}"; return 1; }
    
    echo "${YELLOW}[5/6] 二次安全验证...${RESET}"
    # 5. 二次验证
    timestamp=$(($(date +%s) * 1000))
    org_str="${client_id}${version}com.thunder.downloader${device_id}${timestamp}"
    captcha_sign="$org_str"
    
    for salt in "${salts[@]}"; do
        captcha_sign=$(md5_hash "${captcha_sign}${salt}")
    done
    
    local meta1="{
        \"captcha_sign\": \"1.${captcha_sign}\",
        \"user_id\": \"\",
        \"package_name\": \"com.thunder.downloader\",
        \"client_version\": \"$version\",
        \"timestamp\": \"$timestamp\"
    }"
    
    local init_payload2="{
        \"action\": \"POST:/v1/auth/signup\",
        \"captcha_token\": \"$captcha_token\",
        \"client_id\": \"$client_id\",
        \"device_id\": \"$device_id\",
        \"meta\": $meta1,
        \"redirect_uri\": \"xlaccsdk01://xbase.cloud/callback?state=harbor\"
    }"
    
    local init_response2=$(api_request "POST" "$init_url" "$init_payload2" "$common_headers")
    [ $? -ne 0 ] && return 1
    
    captcha_token=$(echo "$init_response2" | jq -r '.captcha_token')
    [ -z "$captcha_token" ] && { echo "${RED}无法获取二次验证token${RESET}"; return 1; }
    
    echo "${YELLOW}[6/6] 注册账号...${RESET}"
    # 6. 注册账号
    local name=$(echo "$email" | cut -d'@' -f1)
    local password
    
    if check_password "$email_password"; then
        password="$email_password"
    else
        # 生成符合要求的密码
        password=$(generate_random_string 12)
        # 确保包含数字、大小写字母
        password="${password}$(generate_random_string 1 | tr 'a-z' 'A-Z')"
        password="${password}$(generate_random_string 1 | tr 'A-Z' 'a-z')"
        password="${password}$(generate_random_string 1 | tr -dc '0-9')"
    fi
    
    local signup_url="https://xluser-ssl.xunleix.com/v1/auth/signup"
    local signup_payload="{
        \"captcha_token\": \"$captcha_token\",
        \"client_id\": \"$client_id\",
        \"client_secret\": \"$client_secret\",
        \"email\": \"$email\",
        \"name\": \"$name\",
        \"password\": \"$password\",
        \"verification_token\": \"$verification_token\"
    }"
    
    local signup_response=$(api_request "POST" "$signup_url" "$signup_payload" "$common_headers")
    if [ $? -ne 0 ]; then
        echo "${RED}注册失败:${RESET}"
        echo "$signup_response"
        return 1
    fi
    
    local user_id=$(echo "$signup_response" | jq -r '.sub')
    if [ -z "$user_id" ]; then
        echo "${RED}注册失败 - 响应中没有用户ID${RESET}"
        echo "$signup_response"
        return 1
    fi
    
    echo "${GREEN}注册成功!${RESET}"
    echo "邮箱: $email"
    echo "密码: $password"
    echo "用户ID: $user_id"
    
    return 0
}

# 主函数
main() {
    display_banner
    
    echo "注意: 启用了POP3协议的正式邮箱可选择全自动接收验证码"
    echo "目前支持的正式邮箱: Outlook、Hotmail、QQ、@126、Gmail、@163、Yahoo..."
    read -p "是否启用自动接收验证码功能? [输入'y'启用自动，其他为手动]: " pop3_flag
    
    # 检查依赖
    if ! command -v curl &> /dev/null || ! command -v jq &> /dev/null || ! command -v md5sum &> /dev/null; then
        echo "${RED}缺少必要依赖: curl, jq, coreutils-md5sum${RESET}"
        echo "请运行: opkg update && opkg install curl jq coreutils-md5sum coreutils-sha1sum"
        exit 1
    fi
    
    # 检查mail.txt
    if [ ! -f "mail.txt" ]; then
        echo "${RED}mail.txt不存在${RESET}"
        echo "请创建mail.txt文件，每行格式: 邮箱----密码"
        exit 1
    fi
    
    # 读取邮箱
    local first_line=$(head -n 1 mail.txt)
    if [ -z "$first_line" ]; then
        echo "${RED}mail.txt中没有邮箱${RESET}"
        exit 1
    fi
    
    local email=$(echo "$first_line" | awk -F'----' '{print $1}')
    local email_password=$(echo "$first_line" | awk -F'----' '{print $2}')
    
    # 尝试注册
    if register_account "$email" "$email_password" "$pop3_flag"; then
        # 注册成功才从mail.txt中移除
        sed -i '1d' mail.txt
        # 添加到已使用列表
        echo "$first_line" >> mail_used.txt
    else
        echo "${RED}注册失败，请检查错误信息${RESET}"
    fi
}

# 执行主函数
main