# Ansible FRP 自动化部署

> 使用Ansible自动化部署和管理FRP内网穿透服务，支持TOML配置格式

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ansible](https://img.shields.io/badge/Ansible-2.15%2B-blue.svg)](https://www.ansible.com/)
[![FRP Version](https://img.shields.io/badge/FRP-0.68.0%2B-orange.svg)](https://github.com/fatedier/frp)

## 📋 目录

- [特性](#特性)
- [系统要求](#系统要求)
- [快速开始](#快速开始)
- [配置说明](#配置说明)
- [使用示例](#使用示例)
- [故障排除](#故障排除)
- [安全最佳实践](#安全最佳实践)
- [项目结构](#项目结构)
- [贡献指南](#贡献指南)

## ✨ 特性

- 🚀 **自动化部署** - 一键部署FRP服务器端和客户端
- 🔐 **安全管理** - 使用Ansible Vault加密敏感信息（token、密码）
- 📝 **TOML配置** - 支持FRP 0.68.0+的TOML配置格式
- 🌍 **跨平台支持** - 支持Linux（systemd）和macOS（launchd）
- 🔄 **服务管理** - 自动配置系统服务，支持开机自启
- 📊 **Dashboard** - 内置Web管理面板，实时监控连接状态
- 🎯 **灵活代理** - 支持TCP、HTTP、HTTPS等多种代理类型
- 🛡️ **配置验证** - 自动验证配置文件正确性
- 📦 **批量部署** - 支持同时部署多台服务器和客户端

## 💻 系统要求

### 控制节点（运行Ansible的机器）

- Ansible 2.15+
- Python 3.8+
- SSH客户端

### 目标节点

**服务器端（Linux）**:
- Ubuntu 20.04+ / Debian 11+ / CentOS 8+
- systemd支持
- Python 3

**客户端（Linux/macOS）**:
- Linux: 同服务器端要求
- macOS: 10.15+ (Catalina)
  - launchd服务支持
  - Homebrew (可选，用于依赖管理)

## 🚀 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/zero-click/ansible-frp.git
cd ansible-frp
```

### 2. 配置主机清单

编辑 `inventory/hosts.ini`：

```ini
[frp_servers]
vps ansible_host=YOUR_SERVER_IP

[frp_clients]
localhost ansible_connection=local

[frp_servers:vars]
ansible_user=root
ansible_python_interpreter=/usr/bin/python3

[frp_clients:vars]
ansible_user=your-username
```

### 3. 配置变量

编辑服务器配置 `inventory/group_vars/frp_servers.yml`：

```yaml
---
# 服务器认证配置（已加密）
frp_server_token: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          ...加密的token...

# Dashboard配置
frp_server_dashboard_user: admin
frp_server_dashboard_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          ...加密的密码...

# 端口配置
frp_server_bind_port: 7000
frp_server_dashboard_port: 7500
```

编辑客户端配置 `inventory/group_vars/frp_clients.yml`：

```yaml
---
# 服务器连接配置
frp_client_server_addr: "YOUR_SERVER_IP"
frp_client_server_port: 7000
frp_client_token: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          ...加密的token...

# 代理配置列表
frp_client_proxies:
  - name: ssh
    type: tcp
    local_ip: "127.0.0.1"
    local_port: 22
    remote_port: 6000
```

### 4. 加密敏感信息

生成并加密token：

```bash
# 生成随机token
TOKEN=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
echo $TOKEN

# 加密token
echo "your-vault-password" > /tmp/vault_pass
echo "$TOKEN" | ansible-vault encrypt_string --vault-password-file /tmp/vault_pass \
  --name 'frp_server_token' >> inventory/group_vars/frp_servers.yml
```

### 5. 部署

```bash
# 创建vault密码文件
echo "your-vault-password" > .vault_pass
chmod 600 .vault_pass

# 部署服务器端
ansible-playbook -i inventory/hosts.ini playbooks/deploy-server.yml \
  --vault-password-file .vault_pass

# 部署客户端
ansible-playbook -i inventory/hosts.ini playbooks/deploy-client.yml \
  --vault-password-file .vault_pass
```

### 6. 验证

```bash
# 检查服务器状态
ssh root@YOUR_SERVER_IP "systemctl status frps"

# 检查客户端状态（macOS）
launchctl list | grep frp

# 访问Dashboard
http://YOUR_SERVER_IP:7500
```

## ⚙️ 配置说明

### FRP版本和配置格式

本项目使用 **FRP 0.68.0+** 和 **TOML配置格式**。

### 支持的代理类型

#### TCP代理（SSH、数据库等）

```yaml
frp_client_proxies:
  - name: ssh
    type: tcp
    local_ip: "127.0.0.1"
    local_port: 22
    remote_port: 6000
```

使用：`ssh -p 6000 your_username@YOUR_SERVER_IP`

#### HTTP代理（Web服务）

```yaml
frp_client_proxies:
  - name: webapp
    type: http
    local_ip: "127.0.0.1"
    local_port: 8080
    custom_domains:
      - app.yourdomain.com
```

#### HTTPS代理

```yaml
frp_client_proxies:
  - name: secure_app
    type: https
    local_ip: "127.0.0.1"
    local_port: 8443
    custom_domains:
      - secure.yourdomain.com
```

### 平台特定配置

#### Linux客户端

```yaml
# 创建frp用户
frp_client_user: frp

# 安装路径
frp_install_dir: /opt/frp
frp_binary_dir: /usr/local/bin
frp_log_dir: /var/log/frp
```

#### macOS客户端

```yaml
# 使用当前用户
# ansible_user: your-username

# 安装路径
frp_install_dir: ~/.frp
frp_binary_dir: ~/.local/bin
frp_log_dir: ~/.frp/logs
```

## 📚 使用示例

### 场景1：远程SSH访问内网Mac

**目标**：从外网SSH连接到家里的Mac

**客户端配置**：
```yaml
frp_client_proxies:
  - name: home_mac_ssh
    type: tcp
    local_ip: "127.0.0.1"
    local_port: 22
    remote_port: 6001
```

**连接方式**：
```bash
ssh -p 6001 your-username@YOUR_SERVER_IP
```

### 场景2：内网Web服务暴露

**目标**：访问内网开发的Web应用

**客户端配置**：
```yaml
frp_client_proxies:
  - name: dev_web
    type: http
    local_ip: "127.0.0.1"
    local_port: 3000
    custom_domains:
      - dev.yourdomain.com
```

**访问方式**：
```
http://dev.yourdomain.com
```

**DNS配置**：
```
A记录: dev.yourdomain.com -> YOUR_SERVER_IP
```

### 场景3：多客户端管理

**服务器配置**：保持默认即可

**客户端A配置**（办公室Mac）：
```yaml
frp_client_proxies:
  - name: office_ssh
    type: tcp
    local_port: 22
    remote_port: 6010
```

**客户端B配置**（家里Mac）：
```yaml
frp_client_proxies:
  - name: home_ssh
    type: tcp
    local_port: 22
    remote_port: 6020
```

**连接方式**：
```bash
# 连接办公室Mac
ssh -p 6010 your-username@YOUR_SERVER_IP

# 连接家里Mac
ssh -p 6020 your-username@YOUR_SERVER_IP
```

## 🔧 故障排除

### 常见问题

#### 1. 客户端无法连接到服务器

**症状**：客户端日志显示连接失败

**检查步骤**：
```bash
# 1. 检查服务器端口是否开放
nc -zv YOUR_SERVER_IP 7000

# 2. 检查服务器防火墙
ssh root@YOUR_SERVER_IP "ufw status"
ssh root@YOUR_SERVER_IP "iptables -L -n"

# 3. 检查服务器服务状态
ssh root@YOUR_SERVER_IP "systemctl status frps"

# 4. 检查token是否匹配
# 服务器端
ssh root@YOUR_SERVER_IP "cat /opt/frp/frps.toml | grep auth.token"
# 客户端
cat ~/.frp/frpc.toml | grep auth.token
```

**解决方案**：
- 开放服务器防火墙端口7000
- 确保客户端和服务器token一致
- 检查网络连接

#### 2. macOS服务无法启动

**症状**：launchd服务加载失败

**检查步骤**：
```bash
# 检查plist文件
launchctl list | grep frp

# 查看服务日志
log show --predicate 'process == "frpc"' --last 10m

# 手动测试
~/.local/bin/frpc -c ~/.frp/frpc.toml
```

**解决方案**：
```bash
# 重新加载服务
launchctl unload -w ~/Library/LaunchAgents/com.frp.client.plist
launchctl load -w ~/Library/LaunchAgents/com.frp.client.plist

# 检查plist文件路径
cat ~/Library/LaunchAgents/com.frp.client.plist
```

#### 3. 配置文件语法错误

**症状**：ansible任务失败，配置验证错误

**检查步骤**：
```bash
# 验证服务器配置
ssh root@YOUR_SERVER_IP "/usr/local/bin/frps verify -c /opt/frp/frps.toml"

# 验证客户端配置
~/.local/bin/frpc verify -c ~/.frp/frpc.toml
```

**解决方案**：
- 检查TOML语法是否正确
- 确保缩进和引号使用正确
- 查看配置文件日志

#### 4. Dashboard无法访问

**症状**：无法打开Web管理面板

**检查步骤**：
```bash
# 检查端口监听
ssh root@YOUR_SERVER_IP "ss -tlnp | grep 7500"

# 浏览器测试
curl -I http://YOUR_SERVER_IP:7500
```

**解决方案**：
- 开放防火墙端口7500
- 检查Dashboard配置
- 验证用户名密码

### 日志位置

#### 服务器端

```bash
# 服务日志
ssh root@YOUR_SERVER_IP "journalctl -u frps -f"

# 配置文件
ssh root@YOUR_SERVER_IP "cat /opt/frp/frps.toml"

# 应用日志
ssh root@YOUR_SERVER_IP "tail -f /var/log/frp/frps.log"
```

#### 客户端

```bash
# Linux
journalctl -u frpc -f
tail -f /var/log/frp/frpc.log

# macOS
tail -f ~/.frp/logs/frpc.log
```

## 🔐 安全最佳实践

### 1. 使用强密码

```bash
# 生成32字符随机token
openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
```

### 2. 加密敏感信息

```bash
# 加密单个变量
echo "敏感信息" | ansible-vault encrypt_string \
  --vault-password-file .vault_pass --name '变量名'

# 编辑加密文件
ansible-vault edit inventory/group_vars/frp_servers.yml \
  --vault-password-file .vault_pass
```

### 3. 最小权限原则

```bash
# 服务器端：使用专用frp用户
frp_server_user: frp

# 客户端Linux：同样使用专用用户
frp_client_user: frp

# 客户端macOS：使用当前用户（通过launchd限制权限）
```

### 4. 防火墙配置

```bash
# 服务器防火墙（仅开放必要端口）
ufw allow 7000/tcp  # FRP绑定端口
ufw allow 7500/tcp  # Dashboard端口
ufw allow 22/tcp    # SSH
ufw enable
```

### 5. 定期更新

```bash
# 检查FRP更新
https://github.com/fatedier/frp/releases

# 修改playbook中的版本号
vim inventory/group_vars/all.yml
# frp_version: "0.68.0" -> "0.69.0"

# 重新部署
ansible-playbook playbooks/site.yml --vault-password-file .vault_pass
```

### 6. 网络安全

- ✅ 使用VPN保护Dashboard访问
- ✅ 限制Dashboard IP访问范围
- ✅ 定期更换token和密码
- ✅ 监控连接日志，发现异常及时处理

## 📁 项目结构

```
ansible-frp/
├── inventory/                    # 主机清单和变量
│   ├── hosts.ini                # 主机定义
│   └── group_vars/
│       ├── all.yml              # 全局变量
│       ├── frp_servers.yml      # 服务器端变量（部分加密）
│       └── frp_clients.yml      # 客户端变量（部分加密）
├── roles/                       # Ansible角色
│   ├── frp_server/             # 服务器端角色
│   │   ├── defaults/           # 默认变量
│   │   ├── handlers/           # 处理器
│   │   ├── tasks/              # 任务定义
│   │   ├── templates/          # 配置模板
│   │   └── files/              # 静态文件
│   └── frp_client/            # 客户端角色
│       ├── defaults/
│       ├── handlers/
│       ├── tasks/
│       └── templates/
├── playbooks/                  # 部署playbooks
│   ├── deploy-server.yml      # 部署服务器端
│   ├── deploy-client.yml      # 部署客户端
│   ├── cleanup-server.yml     # 清理服务器端
│   └── site.yml               # 完整部署
├── docs/                       # 项目文档
│   ├── ARCHITECTURE.md         # 架构设计
│   ├── CONFIGURATION.md       # 配置详解
│   ├── GETTING_STARTED.md     # 快速入门
│   └── MIGRATION_GUIDE.md     # 迁移指南
├── tests/                      # 测试配置
│   ├── test/                   # 测试用例
│   └── integration/           # 集成测试
├── .ansible.cfg               # Ansible配置
├── .gitignore                 # Git忽略文件
├── .vault_pass                # Vault密码（不提交）
├── README.md                  # 本文件
└── LICENSE                    # MIT许可证
```

## 🤝 贡献指南

我们欢迎所有形式的贡献！

### 贡献方式

1. **报告Bug** - 在Issues中报告问题
2. **建议新功能** - 在Issues中提出想法
3. **提交代码** - Fork项目并提交Pull Request
4. **改进文档** - 完善文档和示例

### 开发流程

```bash
# 1. Fork项目
# 2. 创建特性分支
git checkout -b feature/your-feature

# 3. 提交更改
git commit -m "Add your feature"

# 4. 推送分支
git push origin feature/your-feature

# 5. 提交Pull Request
```

### 代码规范

- 遵循Ansible最佳实践
- 使用YAML格式化（2空格缩进）
- 添加适当的注释
- 更新相关文档

## 📄 许可证

本项目采用 [MIT License](LICENSE) 开源许可证。

```
Copyright (c) 2026 zero-click

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 🙏 致谢

- [FRP项目](https://github.com/fatedier/frp) - 强大的内网穿透工具
- [Ansible项目](https://www.ansible.com/) - 优秀的自动化平台
- 所有贡献者 - 感谢你们的贡献

## 📞 联系方式

- Author: zero-click
- 项目主页: [https://github.com/zero-click/ansible-frp](https://github.com/zero-click/ansible-frp)
- 问题反馈: [GitHub Issues](https://github.com/zero-click/ansible-frp/issues)

---

**注意**: 请确保在使用FRP时遵守当地法律法规，不要用于非法用途。
