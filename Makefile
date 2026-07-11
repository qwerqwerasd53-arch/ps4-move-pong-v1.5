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
# بر پایه‌ی الگوی دقیق پروژه‌ی واقعی و منتشرشده‌ی 0x199/ps4-ipi (که کاملاً
# چک شده)، با همون ابزارهای رسمی و متن‌باز خودِ OpenOrbis (create-fself,
# create-gp4, PkgTool.Core) که از قبل داخل همین ایمیج داکر
# openorbisofficial/toolchain نصب هستن.
# ==========================================================================

TITLE      := PS4 Pong
VERSION    := 01.00
TITLE_ID   := BREW00099
CONTENT_ID := IV0000-BREW00099_00-PONGHOMEBREW0000

PKGDIR := pkg
PKGTOOL_CORE := $(OO_PS4_TOOLCHAIN)/bin/linux/PkgTool.Core

pkg: $(CONTENT_ID).pkg

$(PKGDIR)/eboot.bin: $(EBOOT)
	@mkdir -p $(PKGDIR)
	create-fself -eboot=$(PKGDIR)/eboot.bin -in=$(EBOOT) -out=$(OBJDIR)/eboot.oelf --paid 0x3800000000000010

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

# right.sprx یه فایل استاندارد و شناخته‌شده‌ست که تقریباً همه‌ی هوم‌بروهای
# PS4 لازمش دارن (بخش "about" پکیج). مستقیم از ریپوی رسمی و شناخته‌شده‌ی
# Al-Azif دانلودش می‌کنیم، نه این‌که حدس زده بشه.
$(PKGDIR)/sce_sys/about/right.sprx:
	@mkdir -p $(PKGDIR)/sce_sys/about
	python3 -c "import urllib.request; urllib.request.urlretrieve('https://raw.githubusercontent.com/Al-Azif/ps4-hello-world/main/hello_world/pkg/sce_sys/about/right.sprx', '$@')"

$(PKGDIR)/sce_sys/icon0.png:
	@mkdir -p $(PKGDIR)/sce_sys
	python3 tools/make_placeholder_png.py $@ 512 512

$(PKGDIR)/sce_sys/pic1.png:
	@mkdir -p $(PKGDIR)/sce_sys
	python3 tools/make_placeholder_png.py $@ 1920 1080

$(PKGDIR)/pkg.gp4: $(PKGDIR)/eboot.bin $(PKGDIR)/sce_sys/about/right.sprx $(PKGDIR)/sce_sys/param.sfo $(PKGDIR)/sce_sys/icon0.png $(PKGDIR)/sce_sys/pic1.png
	cd $(PKGDIR) && create-gp4 -out pkg.gp4 --content-id=$(CONTENT_ID) --files "eboot.bin sce_sys/about/right.sprx sce_sys/param.sfo sce_sys/icon0.png sce_sys/pic1.png"

$(CONTENT_ID).pkg: $(PKGDIR)/pkg.gp4
	$(PKGTOOL_CORE) pkg_build $< .

.PHONY: all clean pkg
