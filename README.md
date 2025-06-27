# Ansible MySQL Role

A robust and comprehensive Ansible role for installing and configuring MySQL Server on Ubuntu systems.

## Features

- **Complete MySQL Installation**: Automated installation with proper configuration
- **Security Hardening**: Implements MySQL secure installation with configurable password policies
- **Performance Tuning**: Configurable performance parameters for different workloads
- **SSL Support**: Optional SSL/TLS encryption for secure connections
- **Replication Ready**: Master/slave replication configuration support
- **User & Database Management**: Automated creation and management of users and databases
- **Backup Integration**: Built-in backup configuration with retention policies
- **Log Management**: Proper log rotation and monitoring setup
- **Version Management**: Support for version pinning and custom repositories

## Requirements

- Ansible 2.9 or higher
- Ubuntu 24.04+
- Sudo privileges on target hosts
- Python 3 with pymysql module

## Role Variables

### Basic Configuration

```yaml
# MySQL service settings
mysql_root_password: "secure_password"
mysql_port: "3306"
mysql_bind_address: "127.0.0.1"

# Package selection
mysql_packages:
  - mysql-server
  - mysql-client
  - python3-mysqldb
```

### Performance Tuning

```yaml
# Memory settings
mysql_innodb_buffer_pool_size: "256M"
mysql_key_buffer_size: "256M"
mysql_max_connections: "151"
mysql_query_cache_size: "16M"

# InnoDB settings
mysql_innodb_log_file_size: "64M"
mysql_innodb_flush_log_at_trx_commit: "1"
```

### Security Configuration

```yaml
# Secure installation options
mysql_remove_anonymous_users: true
mysql_remove_test_database: true
mysql_disallow_root_login_remotely: true

# Password validation
mysql_validate_password_enable: true
mysql_validate_password_policy: "MEDIUM"
mysql_validate_password_length: 8
```

### SSL/TLS Configuration

```yaml
mysql_ssl_enabled: false
mysql_ssl_ca: "/path/to/ca.pem"
mysql_ssl_cert: "/path/to/server-cert.pem"
mysql_ssl_key: "/path/to/server-key.pem"
```

### User Management

```yaml
mysql_users:
  - name: application_user
    host: localhost
    password: secure_password
    priv: "app_db.*:ALL"
    state: present
  - name: readonly_user
    host: "%"
    password: readonly_pass
    priv: "app_db.*:SELECT"
    state: present
```

### Database Management

```yaml
mysql_databases:
  - name: application_db
    collation: utf8mb4_unicode_ci
    encoding: utf8mb4
    state: present
  - name: test_db
    state: absent
```

### Replication Configuration

```yaml
# Master configuration
mysql_replication_role: "master"
mysql_server_id: "1"
mysql_binlog_format: "ROW"

# Replication user
mysql_replication_user:
  - name: repl_user
    host: "%"
    password: replication_password
    state: present
```

### Backup Configuration

```yaml
mysql_backup_enabled: true
mysql_backup_dir: "/var/backups/mysql"
mysql_backup_retention_days: 7
```

## Dependencies

None.

## Example Playbook

### Basic Installation

```yaml
- hosts: database_servers
  become: yes
  roles:
    - role: ansible-mysql
      mysql_root_password: "very_secure_password"
      mysql_bind_address: "0.0.0.0"
```

### Production Setup with Users and Databases

```yaml
- hosts: database_servers
  become: yes
  roles:
    - role: ansible-mysql
      mysql_root_password: "{{ vault_mysql_root_password }}"
      mysql_bind_address: "10.0.1.100"
      mysql_max_connections: "500"
      mysql_innodb_buffer_pool_size: "2G"

      mysql_users:
        - name: webapp
          host: "10.0.1.%"
          password: "{{ vault_webapp_mysql_password }}"
          priv: "webapp_prod.*:ALL"
          state: present
        - name: analytics
          host: "10.0.2.%"
          password: "{{ vault_analytics_mysql_password }}"
          priv: "webapp_prod.*:SELECT"
          state: present

      mysql_databases:
        - name: webapp_prod
          collation: utf8mb4_unicode_ci
          encoding: utf8mb4
          state: present

      mysql_backup_enabled: true
      mysql_ssl_enabled: true
```

### Master-Slave Replication Setup

```yaml
# Master server
- hosts: mysql_master
  become: yes
  roles:
    - role: ansible-mysql
      mysql_replication_role: "master"
      mysql_server_id: "1"
      mysql_replication_user:
        - name: repl_user
          host: "%"
          password: "{{ vault_replication_password }}"
          state: present

# Slave server
- hosts: mysql_slave
  become: yes
  roles:
    - role: ansible-mysql
      mysql_replication_role: "slave"
      mysql_server_id: "2"
      mysql_replication_master: "{{ hostvars[groups['mysql_master'][0]]['ansible_default_ipv4']['address'] }}"
```

## Security Considerations

1. **Always use Ansible Vault** for sensitive variables like passwords
2. **Change default passwords** immediately after installation
3. **Configure firewall rules** to restrict MySQL port access
4. **Enable SSL/TLS** for production environments
5. **Regular security updates** should be applied
6. **Monitor logs** for suspicious activity

## Performance Tuning

The role includes sensible defaults, but you should adjust these based on your specific requirements:

- **Memory allocation**: Set `mysql_innodb_buffer_pool_size` to 70-80% of available RAM
- **Connection limits**: Adjust `mysql_max_connections` based on your application needs
- **Query cache**: Disable (`mysql_query_cache_type: "0"`) for MySQL 8.0+ as it's deprecated

## Testing

### Prerequisites

1. **Docker**: Required for running Molecule tests
2. **Python 3.8+**: Required for Ansible and testing tools
3. **pip**: Python package manager

### Quick Start

Install testing dependencies:
```bash
make install-dev
```

Run all tests:
```bash
make test
```

### Testing Options

#### Platform-Specific Testing
```bash
# Test only Ubuntu 24.04
make test-ubuntu2404
```

#### Development Testing
```bash
# Quick test (single platform)
make quick-test

# Run only linting
make lint

# Syntax check only
make syntax-check
```

#### Molecule Commands
```bash
# Create test instances
make molecule-create

# Apply the role
make molecule-converge

# Run verification tests
make molecule-verify

# Login to test instance for debugging
make molecule-login

# Destroy test instances
make molecule-destroy
```

#### Debugging
```bash
# Debug specific platform
make debug-ubuntu2404
```

### Test Structure

- **Lint Tests**: YAML and Ansible syntax validation
- **Molecule Tests**: Full role deployment and verification
- **Platform Tests**: Ubuntu 24.04
- **Ansible Versions**: Tests against Ansible 6, 7, and 8
- **Security Tests**: Vulnerability scanning and best practices
- **Idempotence Tests**: Ensures role can run multiple times safely

### Continuous Integration

The role includes GitHub Actions workflows that automatically:
- Run linting and syntax checks
- Test across multiple platforms and Ansible versions
- Perform security scans
- Validate role structure
- Generate documentation

### Manual Testing

For manual testing without Molecule:
```bash
# Install dependencies
pip install -r requirements-dev.txt

# Create a test playbook
cat > test-playbook.yml << EOF
---
- hosts: localhost
  become: yes
  roles:
    - ansible-mysql
  vars:
    mysql_root_password: "test123!"
EOF

# Run the playbook
ansible-playbook -i localhost, test-playbook.yml
```

## Troubleshooting

### Common Issues

1. **Permission denied errors**: Ensure the mysql user has proper permissions on data directories
2. **Connection refused**: Check if MySQL is running and firewall settings
3. **Authentication issues**: Verify user credentials and host settings

### Log Locations

- Error log: `/var/log/mysql/error.log`
- Slow query log: `/var/log/mysql/mysql-slow.log`
- Binary logs: `/var/log/mysql/mysql-bin.*`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT-0

## Author Information

This role was created by the Ansible community as a robust foundation for MySQL deployments.

## Tags

Available tags for selective execution:

- `mysql` - All MySQL tasks
- `mysql_install` - Installation tasks only
- `mysql_config` - Configuration tasks only
- `mysql_secure` - Security hardening tasks only
- `mysql_users` - User management tasks only
- `mysql_databases` - Database management tasks only
