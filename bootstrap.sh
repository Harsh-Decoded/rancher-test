#!/bin/bash
set -e

ANSIBLE_VERSION="2.20.5"
PYTHON_MIN_VERSION="3.10"

log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

check_python() {
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 is not installed"
        exit 1
    fi

    local python_version=$(python3 --version 2>&1 | awk '{print $2}')
    log_info "Python version: $python_version"
}

detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        log_info "Detected Debian-based system (apt)"
        export PKG_MANAGER="apt"
        export INSTALL_CMD="apt-get update && apt-get install -y"
    elif command -v dnf &> /dev/null; then
        log_info "Detected RedHat-based system (dnf)"
        export PKG_MANAGER="dnf"
        export INSTALL_CMD="dnf install -y"
    elif command -v yum &> /dev/null; then
        log_info "Detected RedHat-based system (yum)"
        export PKG_MANAGER="yum"
        export INSTALL_CMD="yum install -y"
    elif command -v zypper &> /dev/null; then
        log_info "Detected SUSE-based system (zypper)"
        export PKG_MANAGER="zypper"
        export INSTALL_CMD="zypper install -y"
    else
        log_error "No supported package manager found"
        log_error "Supported: apt-get, dnf, yum, zypper"
        exit 1
    fi
}

install_dependencies() {
    log_info "Installing dependencies for ansible-core"

    case "$PKG_MANAGER" in
        apt)
            eval "$INSTALL_CMD python3-pip python3-venv python3-dev git"
            ;;
        dnf|yum)
            eval "$INSTALL_CMD python3-pip python3-devel git"
            ;;
        zypper)
            eval "$INSTALL_CMD python3-pip python3-devel git"
            ;;
    esac
}

install_ansible() {
    log_info "Installing ansible-core $ANSIBLE_VERSION"

    python3 -m pip install --upgrade pip setuptools wheel

    python3 -m pip install ansible-core==$ANSIBLE_VERSION

    ansible --version
}

verify_installation() {
    log_info "Verifying ansible installation"

    if ! command -v ansible &> /dev/null; then
        log_error "Ansible installation verification failed"
        exit 1
    fi

    local ansible_version=$(ansible --version | head -n1 | awk '{print $2}')
    log_info "Ansible version: $ansible_version"

    if ! ansible-playbook --version &> /dev/null; then
        log_error "ansible-playbook not found"
        exit 1
    fi

    log_info "Ansible installation successful"
}

main() {
    log_info "Starting ansible-core bootstrap"
    log_info "Target ansible-core version: $ANSIBLE_VERSION"

    check_python
    detect_package_manager
    install_dependencies
    install_ansible
    verify_installation

    log_info "Bootstrap complete. You can now run the playbook with:"
    log_info "ansible-playbook -i hosts site.yml"
}

main "$@"
