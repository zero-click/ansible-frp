#!/bin/bash
# 敏感信息检查脚本
# 用于在开源前检查是否还有敏感信息

echo "🔍 检查敏感信息..."
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 错误计数
errors=0

# 检查函数
check_sensitive() {
    local pattern=$1
    local description=$2
    local results

    results=$(grep -r "$pattern" . --exclude-dir=.git --exclude-dir=myconfig --exclude-dir=docs \
              --exclude="*.md" --exclude="*.example" --exclude="check-sensitive-info.sh" 2>/dev/null || true)

    if [ ! -z "$results" ]; then
        echo "${RED}❌ 发现敏感信息: $description${NC}"
        echo "$results"
        echo ""
        ((errors++))
    else
        echo "${GREEN}✅ 通过检查: $description${NC}"
    fi
}

# 检查密码文件
echo "检查密码文件..."
if [ -f ".vault_pass" ] || [ -f ".vaultpass" ]; then
    echo "${RED}❌ 发现密码文件，请删除 .vault_pass 和 .vaultpass${NC}"
    ((errors++))
else
    echo "${GREEN}✅ 密码文件已清除${NC}"
fi
echo ""

# 检查敏感信息
check_sensitive "154\.21\.80\.114" "IP地址"
check_sensitive "MA36eedwLdZ2Tn2cEBUNAYklTlzdGMli" "示例Token"
check_sensitive "xhh6xuh6aOoZUkw6Xygz6VYR" "示例密码"
check_sensitive "woosley" "用户名"
check_sensitive "wsl19880104" "可能的密码"

# 检查是否有真实的配置文件（非示例文件）
echo "检查配置文件..."
if [ -f "inventory/hosts.ini" ] && [ ! -f "inventory/hosts.ini.example" ]; then
    echo "${YELLOW}⚠️  警告: hosts.ini 存在但没有对应的 .example 文件${NC}"
    ((errors++))
fi

if [ -f "inventory/group_vars/frp_servers.yml" ] && [ ! -f "inventory/group_vars/frp_servers.yml.example" ]; then
    echo "${YELLOW}⚠️  警告: frp_servers.yml 存在但没有对应的 .example 文件${NC}"
    ((errors++))
fi

if [ -f "inventory/group_vars/frp_clients.yml" ] && [ ! -f "inventory/group_vars/frp_clients.yml.example" ]; then
    echo "${YELLOW}⚠️  警告: frp_clients.yml 存在但没有对应的 .example 文件${NC}"
    ((errors++))
fi

echo ""
echo "===================="
if [ $errors -eq 0 ]; then
    echo "${GREEN}✅ 所有检查通过！项目可以安全开源。${NC}"
    exit 0
else
    echo "${RED}❌ 发现 $errors 个问题，请修复后再开源。${NC}"
    echo ""
    echo "建议操作："
    echo "1. 删除所有 .vault_pass 和 .vaultpass 文件"
    echo "2. 确保所有敏感文件都有对应的 .example 文件"
    echo "3. 运行: grep -r '敏感信息' . --exclude-dir=.git --exclude-dir=.git"
    exit 1
fi
