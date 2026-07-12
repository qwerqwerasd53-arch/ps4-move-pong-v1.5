# Makefile - PS4 Pong (Real)

OO_PS4_TOOLCHAIN ?= $(shell pwd)/OpenOrbis-PS4-Toolchain

CC = clang
LD = ld.lld

TARGET = x86_64-scei-ps4

CFLAGS = -target $(TARGET)
CFLAGS += -fPIC -fno-strict-aliasing -fvisibility=hidden
CFLAGS += -isystem $(OO_PS4_TOOLCHAIN)/include
CFLAGS += -Iinclude

LDFLAGS = -m elf_x86_64 -pie --eh-frame-hdr
LDFLAGS += --script $(OO_PS4_TOOLCHAIN)/link.x
LDFLAGS += -L$(OO_PS4_TOOLCHAIN)/lib
LDFLAGS += -L$(OO_PS4_TOOLCHAIN)/lib/x86_64-scei-ps4

SRCDIR = src
OBJDIR = objs

SOURCES = \
	$(SRCDIR)/main.c \
	$(SRCDIR)/game.c \
	$(SRCDIR)/input.c \
	$(SRCDIR)/video.c

OBJECTS = $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
EBOOT = eboot.elf

all: $(EBOOT)

$(OBJDIR):
	@mkdir -p $(OBJDIR)

$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	@echo "[CC] $<"
	$(CC) $(CFLAGS) -c $< -o $@

$(EBOOT): $(OBJECTS)
	@echo "[LD] Linking $@"
	$(LD) $(LDFLAGS) -o $@ $(OO_PS4_TOOLCHAIN)/lib/crt1.o $(OBJECTS) \
		-lkernel -lc -lm -lSceVideoOut -lSceSysmodule -lScePad -lSceUserService
	@echo "Build complete: $@"
	@ls -lh $@

clean:
	@rm -rf $(OBJDIR) $(EBOOT) $(PKGDIR) $(CONTENT_ID).pkg
	@echo "Clean complete"

TITLE      := PS4 Pong
VERSION    := 01.00
TITLE_ID   := BREW00099
CONTENT_ID := IV0000-BREW00099_00-PONGHOMEBREW0000

PKGDIR := pkg
TOOLCHAIN_BIN := $(OO_PS4_TOOLCHAIN)/bin/linux
TOOLCHAIN_DATA := $(OO_PS4_TOOLCHAIN)/bin/data

CREATE_EBOOT := $(TOOLCHAIN_BIN)/create-eboot
PKGTOOL_CORE := $(TOOLCHAIN_BIN)/PkgTool.Core

pkg: $(CONTENT_ID).pkg

$(PKGDIR)/eboot.bin: $(EBOOT)
	@mkdir -p $(PKGDIR)
	$(CREATE_EBOOT) -in=$(EBOOT) -out=$(PKGDIR)/eboot.bin --paid 0x3800000000000011

$(PKGDIR)/sce_sys/param.sfo: Makefile
	@mkdir -p $(PKGDIR)/sce_sys
	$(PKGTOOL_CORE) sfo_new $@
	$(PKGTOOL_CORE) sfo_setentry $@ APP_TYPE --type Integer --maxsize 4 --value 1
	$(PKGTOOL_CORE) sfo_setentry $@ APP_VER --type Utf8 --maxsize 8 --value '$(VERSION)'
	$(PKGTOOL_CORE) sfo_setentry $@ ATTRIBUTE --type Integer --maxsize 4 --value 0
	$(PKGTOOL_CORE) sfo_setentry $@ CATEGORY --type Utf8 --maxsize 4 --value 'gd'
	$(PKGTOOL_CORE) sfo_setentry $@ CONTENT_ID --type Utf8 --maxsize 48 --value '$(CONTENT_ID)'
	$(PKGTOOL_CORE) sfo_setentry $@ DOWNLOAD_DATA_SIZE --type Integer --maxsize 4 --value 0
	$(PKGTOOL_CORE) sfo_setentry $@ SYSTEM_VER --type Integer --maxsize 4 --value 0
	$(PKGTOOL_CORE) sfo_setentry $@ TITLE --type Utf8 --maxsize 128 --value '$(TITLE)'
	$(PKGTOOL_CORE) sfo_setentry $@ TITLE_ID --type Utf8 --maxsize 12 --value '$(TITLE_ID)'
	$(PKGTOOL_CORE) sfo_setentry $@ VERSION --type Utf8 --maxsize 8 --value '$(VERSION)'

$(PKGDIR)/sce_sys/about/right.sprx:
	@mkdir -p $(PKGDIR)/sce_sys/about
	cp $(TOOLCHAIN_DATA)/right.sprx $@

$(PKGDIR)/sce_sys/icon0.png:
	@mkdir -p $(PKGDIR)/sce_sys
	cp $(TOOLCHAIN_DATA)/icon0.png $@

$(PKGDIR)/sce_sys/pic0.png:
	@mkdir -p $(PKGDIR)/sce_sys
	cp $(TOOLCHAIN_DATA)/pic0.png $@

define GP4_CONTENT
<?xml version="1.0"?>
<psproject xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" fmt="gp4" version="1000">
  <volume>
    <volume_type>pkg_ps4_app</volume_type>
    <volume_id>PS4VOLUME</volume_id>
    <volume_ts>2018-01-30 04:20:11</volume_ts>
    <package content_id="$(CONTENT_ID)" passcode="00000000000000000000000000000000" storage_type="digital50" app_type="full" />
    <chunk_info chunk_count="1" scenario_count="1">
      <chunks>
        <chunk id="0" layer_no="0" label="Chunk #0" />
      </chunks>
      <scenarios default_id="0">
        <scenario id="0" type="sp" initial_chunk_count="1" label="Scenario #0">0</scenario>
      </scenarios>
    </chunk_info>
  </volume>
  <files img_no="0">
    <file targ_path="eboot.bin" orig_path="eboot.bin" />
    <file targ_path="sce_sys/param.sfo" orig_path="sce_sys/param.sfo" />
    <file targ_path="sce_sys/icon0.png" orig_path="sce_sys/icon0.png" />
    <file targ_path="sce_sys/pic0.png" orig_path="sce_sys/pic0.png" />
    <file targ_path="sce_sys/about/right.sprx" orig_path="sce_sys/about/right.sprx" />
  </files>
  <rootdir>
    <dir targ_name="sce_sys">
      <dir targ_name="about" />
    </dir>
  </rootdir>
</psproject>
endef
export GP4_CONTENT

$(PKGDIR)/pkg.gp4: $(PKGDIR)/eboot.bin $(PKGDIR)/sce_sys/about/right.sprx $(PKGDIR)/sce_sys/param.sfo $(PKGDIR)/sce_sys/icon0.png $(PKGDIR)/sce_sys/pic0.png
	@echo "$$GP4_CONTENT" > $@

$(CONTENT_ID).pkg: $(PKGDIR)/pkg.gp4
	$(PKGTOOL_CORE) pkg_build $< .

.PHONY: all clean pkg
