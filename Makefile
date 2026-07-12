# Makefile - PS4 Pong (Real)
#
# نکته: هدرهای عمومی C (stdio.h و...) و خودِ clang/ld.lld در ریپوی گیت OpenOrbis
# نیستن (اونا تو ریپوی جدای musl و در نسخه‌ی ریلیزشده‌ی تول‌چین هستن).
# برای همین تو ورک‌فلوی گیت‌هاب اکشن، کل جاب داخل ایمیج داکر رسمی
# openorbisofficial/toolchain اجرا میشه که همه‌چی از قبل توش آماده‌ست.

OO_PS4_TOOLCHAIN ?= $(shell pwd)/OpenOrbis-PS4-Toolchain

# نکته مهم (رفع قطعی خطای اجرا روی خودِ PS4 - علت واقعی کرش):
# لاگ کرش نشون داد GoldHENLoader موقع اجرا با null pointer کرش می‌کنه.
# دلیل واقعی: تو نسخه‌های قبلی این Makefile، فایل استارتاپ واقعی PS4
# (crt1.o) هیچ‌وقت لینک نمی‌شد. این فایله که _start رو تعریف می‌کنه و
# قبل از main() محیط اجرا (استک، TLS و...) رو آماده می‌کنه. بدون اون:
#   orbis-ld: warning: cannot find entry symbol _start
# یعنی هیچ entry point معتبری نداریم و کنسول موقع اجرا کرش می‌کنه.
#
# راه‌حل درست و مستند (بر اساس پروژه‌های واقعی و کارکن OpenOrbis مثل
# ps4-ipi و PS4RPI): باید مستقیم با خودِ ld.lld لینک کنیم، با اسکریپت
# لینکر رسمی تول‌چین (link.x) و فایل استارتاپ (crt1.o) که خودِ تول‌چین
# همراهش میاد. این کار کاملاً جایگزین تلاش‌های قبلی با clang -fuse-ld
# می‌شه و اون مشکلات رو از اساس کنار می‌ذاره.
CC = clang
LD = ld.lld

# Target
TARGET = x86_64-scei-ps4

# Flags
CFLAGS = -target $(TARGET)
CFLAGS += -fPIC -fno-strict-aliasing -fvisibility=hidden
CFLAGS += -isystem $(OO_PS4_TOOLCHAIN)/include
CFLAGS += -Iinclude

LDFLAGS = -m elf_x86_64 -pie --eh-frame-hdr
LDFLAGS += --script $(OO_PS4_TOOLCHAIN)/link.x
LDFLAGS += -L$(OO_PS4_TOOLCHAIN)/lib
LDFLAGS += -L$(OO_PS4_TOOLCHAIN)/lib/x86_64-scei-ps4

# Files
SRCDIR = src
OBJDIR = objs

SOURCES = \
	$(SRCDIR)/main.c \
	$(SRCDIR)/game.c \
	$(SRCDIR)/input.c \
	$(SRCDIR)/video.c

OBJECTS = $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
EBOOT = eboot.elf

# Rules
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

# ==========================================================================
# ساخت فایل .pkg (قابل نصب واقعی، نه فقط ELF خام)
#
# این بخش بر پایه‌ی داده‌ی واقعی از لاگ diagnostic خودمون نوشته شده، نه حدس:
#   - create-fself و create-gp4 (که تو نسخه‌های قدیمی‌تر تول‌چین بودن)
#     تو این ایمیج داکر اصلاً وجود ندارن (جستجوی کامل تو کل پوشه‌ی تول‌چین
#     هیچی پیدا نکرد). این دو ابزار بعداً با create-eboot ادغام شدن
#     (طبق CHANGELOG رسمی خودِ OpenOrbis: "Merged create-eboot and
#     create-lib into one tool for ease-of-use").
#   - create-eboot و PkgTool.Core هر دو واقعاً هستن، دقیقاً اینجا:
#       /lib/OpenOrbisSDK/bin/linux/create-eboot
#       /lib/OpenOrbisSDK/bin/linux/PkgTool.Core
#     (تایید شده از لاگ)، ولی رو PATH نیستن، پس با مسیر کامل صداشون می‌زنیم.
#   - python3 هم اصلاً رو این ایمیج نیست (تایید شده از لاگ)، پس به‌جای
#     دانلود/ساخت آیکون با پایتون، از فایل‌های آماده‌ای که خودِ تول‌چین
#     از قبل داره استفاده می‌کنیم:
#       /lib/OpenOrbisSDK/bin/data/right.sprx
#       /lib/OpenOrbisSDK/bin/data/icon0.png
#       /lib/OpenOrbisSDK/bin/data/pic0.png
#     (این مسیرها هم مستقیم از خروجی find تو لاگ خودمون تایید شدن.)
#   - چون create-gp4 وجود نداره، فایل pkg.gp4 رو مستقیم و دستی می‌سازیم،
#     بر اساس اسکیمای واقعی و تاییدشده‌ی GP4 (از پروژه‌ی واقعی و منتشرشده‌ی
#     Al-Azif/ps4vibe که دقیقاً همین فرمت رو استفاده می‌کنه).
# ==========================================================================

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
<?xml version="1.0" encoding="utf-8"?>
<psproject xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" fmt="gp4" version="1000">
  <volume>
    <volume_type>pkg_ps4_app</volume_type>
    <volume_ts>2012-01-01 08:00:00</volume_ts>
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
    <dir targ_name="sce_sys">
      <dir targ_name="about" />
    </dir>
    <file targ_path="sce_sys/param.sfo" orig_path="sce_sys/param.sfo" />
    <file targ_path="sce_sys/icon0.png" orig_path="sce_sys/icon0.png" />
    <file targ_path="sce_sys/pic0.png" orig_path="sce_sys/pic0.png" />
    <file targ_path="sce_sys/about/right.sprx" orig_path="sce_sys/about/right.sprx" />
  </files>
</psproject>
endef
export GP4_CONTENT

$(PKGDIR)/pkg.gp4: $(PKGDIR)/eboot.bin $(PKGDIR)/sce_sys/about/right.sprx $(PKGDIR)/sce_sys/param.sfo $(PKGDIR)/sce_sys/icon0.png $(PKGDIR)/sce_sys/pic0.png
	@echo "$$GP4_CONTENT" > $@

$(CONTENT_ID).pkg: $(PKGDIR)/pkg.gp4
	$(PKGTOOL_CORE) pkg_build $< .

.PHONY: all clean pkg
