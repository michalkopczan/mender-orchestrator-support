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
clean:

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

# Dynamic targets like install-mock-env-interfaces-v1-rtos
install-mock-env-interfaces-v1-%: INTERFACE=$*
install-mock-env-interfaces-v1-%:
	install -m 755 -d $(prefix)$(datadir)/mender-orchestrator/interfaces/v1
	install -m 755 demo/mock-env/interfaces/v1/$(INTERFACE) $(prefix)$(datadir)/mender-orchestrator/interfaces/v1/

# Dynamic targets like uninstall-mock-env-interfaces-v1-rtos
uninstall-mock-env-interfaces-v1-%: INTERFACE=$*
uninstall-mock-env-interfaces-v1-%:
	rm -f $(prefix)$(datadir)/mender-orchestrator/interfaces/v1/$(INTERFACE)


.PHONY: all
.PHONY: install
.PHONY: uninstall
.PHONY: clean
.PHONY: install-mock-env
.PHONY: install-mock-instances
.PHONY: install-mock-topology
.PHONY: install-mock-interfaces
.PHONY: uninstall-mock-env
.PHONY: uninstall-mock-instances
.PHONY: uninstall-mock-topology
.PHONY: uninstall-mock-interfaces
