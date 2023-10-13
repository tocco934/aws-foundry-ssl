#!/bin/bash

# -------------------------------------------------------
# Enable, disable, or install Amazon Linux kernel updates
#--------------------------------------------------------

if [[ "${EUID}" -ne 0 ]]; then
    echo "Please run this script as root (sudo ./restart_foundry.sh)"
    exit 1
fi

# Default variable values
mode=""

# Function to display script usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo " -h, --help      Display this help message"
    echo " -e, --enable    Enable kernel auto-patching"
    echo " -d, --disable   Disable kernel auto-patching"
    echo " -n, --now       Install available kernel and security patches"
}

has_argument() {
    [[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

extract_argument() {
    echo "${2:-${1#*=}}"
}

handle_options() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h | --help)
                usage
                exit 0
                ;;
            -e | --enable)
                mode="enable"
                ;;
            -d | --disable)
                mode="disable"
                ;;
            -n | --now)
                mode="now"
                ;;
            *)
                echo "Invalid option: $1" >&2
                usage
                exit 1
                ;;
        esac
        shift
    done
}

# Main script execution
handle_options "$@"

if [[ $mode == "" ]]; then
    echo "No options were passed"
    usage
    exit 1
fi

service_running=$(systemctl is-active kpatch.service)

if [[ $mode == "enable" ]]; then
    if [[ $service_running == "active" ]]; then
        echo "Kernel patching service is already enabled!"
        exit 0
    fi

    sudo dnf install -y kpatch-dnf
    sudo dnf kernel-livepatch -y auto

    sudo dnf install -y kpatch-runtime
    sudo dnf update kpatch-runtime

    sudo systemctl enable --now kpatch.service

    echo "Kernel patching service enabled."
    exit 0
fi

if [[ $mode == "disable" ]]; then
    if [[ $service_running != "active" ]]; then
        echo "Kernel patching service is not enabled!"
        exit 0
    fi

    sudo dnf kernel-livepatch manual
    sudo systemctl disable --now kpatch.service

    sudo dnf remove -y kpatch-dnf
    sudo dnf remove -y kpatch-runtime
    sudo dnf remove -y kernel-livepatch

    echo "Kernel patching service disabled."
    exit 0
fi

if [[ $mode == "now" ]]; then
    sudo dnf update --security

    echo "Available security updates applied."
    exit 0
fi

# Should never get here, unless I stuffed something up
echo "Unknown mode ${mode}!"
exit 1
