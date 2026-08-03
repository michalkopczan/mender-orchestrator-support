DESTDIR ?= /
prefix ?= $(DESTDIR)
datadir ?= /usr/share
datarootdir ?= /data


UPDATE_INTERFACES := $(shell find interfaces/v1 -type f)
UPDATE_INTERFACES_INSTALL_TARGETS = $(addprefix install-,$(subst /,-,$(UPDATE_INTERFACES)))
UPDATE_INTERFACES_UNINSTALL_TARGETS = $(addprefix uninstall-,$(subst /,-,$(UPDATE_INTERFACES)))

MOCK_ENV_INTERFACES := $(shell find demo/mock-env/interfaces/v1 -type f 2>/dev/null)
MOCK_ENV_INTERFACES_INSTALL_TARGETS = $(addprefix install-mock-env-,$(subst /,-,$(subst demo/mock-env/,,$(MOCK_ENV_INTERFACES))))
MOCK_ENV_INTERFACES_UNINSTALL_TARGETS = $(addprefix uninstall-mock-env-,$(subst /,-,$(subst demo/mock-env/,,$(MOCK_ENV_INTERFACES))))


all:

install: $(UPDATE_INTERFACES_INSTALL_TARGETS)
uninstall: $(UPDATE_INTERFACES_UNINSTALL_TARGETS)

install-mock-env: install-mock-instances install-mock-topology $(MOCK_ENV_INTERFACES_INSTALL_TARGETS)
uninstall-mock-env: uninstall-mock-instances uninstall-mock-topology $(MOCK_ENV_INTERFACES_UNINSTALL_TARGETS)

install-mock-interfaces: $(MOCK_ENV_INTERFACES_INSTALL_TARGETS)
uninstall-mock-interfaces: $(MOCK_ENV_INTERFACES_UNINSTALL_TARGETS)

# Dynamic targets like install-interfaces-v1-rootfs-image
install-interfaces-v1-%: INTERFACE=$*
install-interfaces-v1-%:
	install -m 755 -d $(prefix)$(datadir)/mender-orchestrator/interfaces/v1
	install -m 755 interfaces/v1/$(INTERFACE) $(prefix)$(datadir)/mender-orchestrator/interfaces/v1/

# Dynamic targets like uninstall-interfaces-v1-rootfs-image
uninstall-interfaces-v1-%: INTERFACE=$*
uninstall-interfaces-v1-%:
	rm -f $(prefix)$(datadir)/mender-orchestrator/interfaces/v1/$(INTERFACE)
	-rmdir -p $(prefix)$(datadir)/mender-orchestrator/interfaces/v1

install-mock-instances:
	install -m 755 -d $(prefix)$(datarootdir)/mender-orchestrator
	cp -r demo/mock-env/mock-instances $(prefix)$(datarootdir)/mender-orchestrator/

uninstall-mock-instances:
	rm -rf $(prefix)$(datarootdir)/mender-orchestrator/mock-instances

install-mock-topology:
	install -m 755 -d $(prefix)$(datarootdir)/mender-orchestrator
	install -m 755 demo/mock-env/topology.yaml $(prefix)$(datarootdir)/mender-orchestrator/topology.yaml

uninstall-mock-topology:
	rm -f $(prefix)$(datarootdir)/mender-orchestrator/topology.yaml

# Dynamic targets like install-mock-env-interfaces-v1-rtos-interface
install-mock-env-interfaces-v1-%: INTERFACE=$*
install-mock-env-interfaces-v1-%:
	install -m 755 -d $(prefix)$(datadir)/mender-orchestrator/interfaces/v1
	install -m 755 demo/mock-env/interfaces/v1/$(INTERFACE) $(prefix)$(datadir)/mender-orchestrator/interfaces/v1/

# Dynamic targets like uninstall-mock-env-interfaces-v1-rtos-interface
uninstall-mock-env-interfaces-v1-%: INTERFACE=$*
uninstall-mock-env-interfaces-v1-%:
	rm -f $(prefix)$(datadir)/mender-orchestrator/interfaces/v1/$(INTERFACE)

# remote-mqtt: not part of the default install target, since the broker and the component
# agent are two different pieces installed on two different boards (RPi #1 vs RPi #2/#3/...).
# The mqtt-component Interface itself is a regular interfaces/v1 entry and is already covered
# by the default `install` target above.

# Run on the System Device (RPi #1), alongside the mqtt-component Interface. Plaintext,
# appropriate for a trusted LAN -- see remote-mqtt/README.md.
install-mqtt-broker:
	install -m 755 -d $(prefix)/etc/mosquitto/conf.d
	install -m 644 remote-mqtt/broker/mosquitto-orchestrator.conf $(prefix)/etc/mosquitto/conf.d/mender-orchestrator.conf
	@echo "Installed. Still needed, as root on this board:"
	@echo "  systemctl restart mosquitto"

uninstall-mqtt-broker:
	rm -f $(prefix)/etc/mosquitto/conf.d/mender-orchestrator.conf

# Run on each Component board (RPi #2, #3, ...).
install-mqtt-component-agent:
	install -m 755 -d $(prefix)$(datadir)/mender-orchestrator/remote-mqtt
	install -m 755 remote-mqtt/component-agent/mender-mqtt-agent $(prefix)$(datadir)/mender-orchestrator/remote-mqtt/mender-mqtt-agent
	install -m 755 -d $(prefix)/etc/mender-mqtt-agent
	install -m 644 remote-mqtt/component-agent/mender-mqtt-agent.conf.example $(prefix)/etc/mender-mqtt-agent/mender-mqtt-agent.conf.example
	install -m 755 -d $(prefix)/lib/systemd/system
	install -m 644 remote-mqtt/component-agent/mender-mqtt-agent.service $(prefix)/lib/systemd/system/mender-mqtt-agent.service
	@echo "Installed. Still needed, as root on this board:"
	@echo "  cp /etc/mender-mqtt-agent/mender-mqtt-agent.conf.example /etc/mender-mqtt-agent/mender-mqtt-agent.conf, then edit it"
	@echo "  systemctl enable --now mender-mqtt-agent"

uninstall-mqtt-component-agent:
	systemctl disable --now mender-mqtt-agent 2>/dev/null || true
	rm -f $(prefix)$(datadir)/mender-orchestrator/remote-mqtt/mender-mqtt-agent
	-rmdir $(prefix)$(datadir)/mender-orchestrator/remote-mqtt
	rm -f $(prefix)/etc/mender-mqtt-agent/mender-mqtt-agent.conf.example
	rm -f $(prefix)/lib/systemd/system/mender-mqtt-agent.service


.PHONY: all
.PHONY: install
.PHONY: uninstall
.PHONY: install-mock-env
.PHONY: install-mock-instances
.PHONY: install-mock-topology
.PHONY: install-mock-interfaces
.PHONY: uninstall-mock-env
.PHONY: uninstall-mock-instances
.PHONY: uninstall-mock-topology
.PHONY: uninstall-mock-interfaces
.PHONY: install-mqtt-broker
.PHONY: uninstall-mqtt-broker
.PHONY: install-mqtt-component-agent
.PHONY: uninstall-mqtt-component-agent
