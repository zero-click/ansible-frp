# FRP测试指南

本文档说明如何测试FRP部署。

## 测试场景

### 1. SSH隧道测试

测试通过FRP建立的SSH隧道：

```bash
# 运行SSH隧道测试
ansible-playbook tests/test_deployment.yml \
  -i tests/inventory/test_hosts.ini \
  --tags ssh_tunnel \
  --vault-password-file .vault_pass
```

**验证步骤**:

1. 检查测试输出，确认配置正确
2. 手动测试SSH连接：
   ```bash
   ssh -p 6000 your_username@<server_ip>
   ```
3. 验证能进入客户端shell

### 2. HTTP代理测试

测试HTTP代理功能：

```bash
# 运行HTTP代理测试
ansible-playbook tests/test_deployment.yml \
  -i tests/inventory/test_hosts.ini \
  --tags http_proxy \
  --vault-password-file .vault_pass
```

**前提条件**:
- 客户端本地有HTTP服务运行
- 配置了HTTP类型的代理

**验证步骤**:
```bash
# 测试HTTP连接
curl -I http://<server_ip>:<http_port>

# 测试自定义域名
curl -I http://<custom_domain>
```

### 3. 多代理测试

测试多个代理同时工作：

```bash
# 运行多代理测试
ansible-playbook tests/test_deployment.yml \
  -i tests/inventory/test_hosts.ini \
  --tags multiple_proxies \
  --vault-password-file .vault_pass
```

## 测试配置

### 测试变量

编辑 `tests/test_vars.yml` 配置测试参数：

```yaml
# SSH测试配置
ssh_test_user: your_username
ssh_test_key_path: ~/.ssh/id_rsa

# 连接测试配置
connection_test_timeout: 10

# 服务测试配置
service_test_retries: 3
service_test_delay: 5
```

### 启用/禁用测试场景

```yaml
test_scenarios:
  - name: ssh_tunnel
    enabled: true    # 启用SSH隧道测试

  - name: http_proxy
    enabled: false   # 禁用HTTP代理测试
```

## 使用测试Inventory

### 本地测试

使用本地测试环境：

```bash
ansible-playbook tests/test_deployment.yml \
  -i tests/inventory/test_hosts.ini \
  --vault-password-file .vault_pass
```

### 生产环境测试

使用生产inventory（谨慎！）：

```bash
ansible-playbook tests/test_deployment.yml \
  -i inventory/hosts.ini \
  --vault-password-file .vault_pass \
  --check  # 干运行模式
```

## 干运行模式

在不做实际更改的情况下测试：

```bash
ansible-playbook tests/test_deployment.yml \
  -i tests/inventory/test_hosts.ini \
  --vault-password-file .vault_pass \
  --check \
  --diff
```

## 验证部署

使用官方验证playbook：

```bash
ansible-playbook playbooks/verify.yml \
  -i inventory/hosts.ini \
  --vault-password-file .vault_pass
```

## 持续集成

### GitHub Actions示例

```yaml
name: Test FRP Deployment

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'

      - name: Install Ansible
        run: pip install ansible

      - name: Run tests
        run: |
          ansible-playbook tests/test_deployment.yml \
            -i tests/inventory/test_hosts.ini \
            --check
```

## 测试检查清单

### 部署前测试

- [ ] Inventory配置正确
- [ ] 变量文件已加密
- [ ] 测试场景已配置
- [ ] 网络连接可用

### 功能测试

- [ ] Server安装成功
- [ ] Client安装成功
- [ ] 配置文件生成正确
- [ ] 服务启动成功
- [ ] SSH隧道工作
- [ ] HTTP代理工作（如配置）
- [ ] Dashboard可访问

### 安全测试

- [ ] Token已加密
- [ ] 密码已设置
- [ ] 防火墙规则正确
- [ ] 文件权限正确

## 故障排查

### 测试失败

如果测试失败：

1. **查看详细输出**:
   ```bash
   ansible-playbook tests/test_deployment.yml -vvv
   ```

2. **检查日志**:
   - Server: `/var/log/frp/frps.log`
   - Client: `/var/log/frp/frpc.log`

3. **验证配置**:
   ```bash
   # 验证server配置
   /opt/frp/frp_*_linux_amd64/frps verify -c /opt/frp/frps.ini

   # 验证client配置
   /opt/frp/frp_*_*/frpc verify -c /opt/frp/frpc.ini
   ```

### 常见问题

**问题**: 测试inventory无法连接

**解决**: 确保 `ansible_connection=local` 或配置正确的SSH密钥

**问题**: 配置文件未找到

**解决**: 检查 `frp_install_dir` 路径是否正确

**问题**: 服务启动失败

**解决**: 查看systemd/launchd日志获取详细信息

## 性能测试

### 延迟测试

```bash
# 测试网络延迟
ping -c 10 <server_ip>

# 测试SSH隧道延迟
time ssh -p 6000 user@server_ip "echo test"
```

### 吞吐测试

```bash
# 测试传输速度
dd if=/dev/zero bs=1M count=100 | \
  ssh -p 6000 user@server_ip "dd of=/tmp/test"
```

## 报告问题

如果发现测试问题：

1. 收集测试输出
2. 收集相关日志
3. 提交Issue并附上详细信息

## 最佳实践

1. **先在测试环境验证** - 再应用到生产环境
2. **使用版本控制** - 跟踪测试配置变更
3. **自动化测试** - 集成到CI/CD流程
4. **定期测试** - 确保系统稳定性
5. **记录结果** - 保存测试结果供分析
