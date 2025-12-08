"""
Molecule tests for Rancher role
"""
import os
import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']
).get_hosts('all')


def test_docker_installed(host):
    """Verify Docker is installed"""
    docker = host.package("docker-ce")
    assert docker.is_installed


def test_docker_service_running(host):
    """Verify Docker service is running and enabled"""
    docker_service = host.service("docker")
    assert docker_service.is_running
    assert docker_service.is_enabled


def test_ntp_service_running(host):
    """Verify NTP service is running"""
    ntp_service = host.service("ntp")
    assert ntp_service.is_running
    assert ntp_service.is_enabled


def test_docker_socket(host):
    """Verify Docker socket exists"""
    docker_sock = host.socket("unix:///var/run/docker.sock")
    assert docker_sock.exists


def test_rancher_volume_exists(host):
    """Verify Rancher data volume exists"""
    cmd = host.run("docker volume ls --format '{{.Name}}' | grep rancher_data")
    assert cmd.rc == 0
    assert "rancher_data" in cmd.stdout


# Note: The following tests are skipped in Docker-based Molecule tests
# due to Docker-in-Docker limitations with Rancher's containerd overlays.
# These would be tested in a full VM-based scenario.
#
# def test_rancher_container_running(host):
#     """Verify Rancher container is running"""
#     cmd = host.run("docker ps --filter name=rancher --format '{{.Status}}'")
#     assert cmd.rc == 0
#     assert "Up" in cmd.stdout
#
# def test_rancher_ports_exposed(host):
#     """Verify Rancher ports are listening"""
#     cmd = host.run("docker port rancher")
#     assert cmd.rc == 0
#     assert "80/tcp" in cmd.stdout
#     assert "443/tcp" in cmd.stdout


def test_docker_group_exists(host):
    """Verify docker group exists"""
    docker_group = host.group("docker")
    assert docker_group.exists


def test_keyrings_directory(host):
    """Verify APT keyrings directory exists with correct permissions"""
    keyrings_dir = host.file("/etc/apt/keyrings")
    assert keyrings_dir.exists
    assert keyrings_dir.is_directory
    assert keyrings_dir.mode == 0o755


def test_docker_gpg_key(host):
    """Verify Docker GPG key is present"""
    docker_key = host.file("/etc/apt/keyrings/docker.asc")
    assert docker_key.exists
    assert docker_key.mode == 0o644
