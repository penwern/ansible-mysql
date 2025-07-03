# Makefile for ansible-mysql role testing and development

.PHONY: help install test test-all lint clean molecule-test molecule-converge molecule-verify molecule-destroy

# Default target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install required dependencies
	pip install --upgrade pip
	pip install -r requirements-dev.txt

test: ## Run basic molecule test
	molecule test

lint: ## Run linting tools
	yamllint .
	ansible-lint

syntax-check: ## Check Ansible syntax
	ansible-playbook --syntax-check molecule/default/converge.yml

molecule-test: ## Run full molecule test cycle
	molecule test

molecule-converge: ## Run molecule converge (apply role)
	molecule converge

molecule-verify: ## Run molecule verify (run tests)
	molecule verify

molecule-destroy: ## Destroy molecule test instances
	molecule destroy

molecule-login: ## Login to molecule test instance
	molecule login

molecule-create: ## Create molecule test instances
	molecule create

molecule-prepare: ## Run molecule prepare
	molecule prepare

molecule-list: ## List molecule instances
	molecule list

debug-ubuntu2404: ## Debug Ubuntu 24.04 instance
	molecule converge -s default -- --limit ubuntu2404-mysql
	molecule login -s default -h ubuntu2404-mysql

clean: ## Clean up test artifacts
	molecule destroy
	rm -rf .molecule/
	rm -rf .cache/
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

quick-test: ## Quick test on single platform
	molecule test -s default -- --limit ubuntu2404-mysql

role-check: ## Check role structure and best practices
	@echo "Checking role structure..."
	@test -d tasks || echo "WARNING: tasks/ directory missing"
	@test -d defaults || echo "WARNING: defaults/ directory missing"
	@test -d handlers || echo "WARNING: handlers/ directory missing"
	@test -d templates || echo "WARNING: templates/ directory missing"
	@test -d meta || echo "WARNING: meta/ directory missing"
	@test -f README.md || echo "WARNING: README.md missing"
	@echo "Role structure check complete"

install-dev: ## Install development dependencies
	pip install --upgrade pip
	pip install -r requirements-dev.txt
	pre-commit install

pre-commit: ## Run pre-commit hooks
	pre-commit run --all-files

requirements: ## Generate locked requirements file
	pip-compile requirements-dev.in --output-file requirements-dev.txt

info: ## Show environment information
	@echo "Python version: $$(python --version)"
	@echo "Ansible version: $$(ansible --version | head -1)"
	@echo "Molecule version: $$(molecule --version)"
	@echo "Docker version: $$(docker --version)"

# Platform-specific tests
test-ubuntu2404: ## Test only Ubuntu 24.04
	molecule test -s default -- --limit ubuntu2404-mysql

# Docker Compose testing
docker-test: ## Quick test using Docker Compose
	docker compose up -d
	sleep 10
	docker compose exec -T mysql-test ansible-playbook -i /inventory/hosts.yml /inventory/test-playbook.yml
	docker compose down

docker-shell: ## Open shell in test container
	docker compose up -d
	docker compose exec mysql-test bash
