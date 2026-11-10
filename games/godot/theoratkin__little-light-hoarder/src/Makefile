gd = godot --export
builddir = build
name = little-light-hoarder
version := $(file < VERSION)
butler = butler push --userversion $(version)
butler_target = thokr/little-light-hoarder


all: web linux64 win64 mac

linux64:
	$(gd) $@ $(builddir)/$@/$(name).x86_64

win64:
	$(gd) $@ $(builddir)/$@/$(name).exe

mac:
	$(gd) $@ $(builddir)/$@/$(name).zip

web:
	$(gd) $@ $(builddir)/$@/index.html


publish: publish-web publish-linux64 publish-win64 publish-mac

define publish
	$(butler) $(builddir)/$(subst publish-,,$@) $(butler_target):$(subst publish-,,$@)
endef

define publish_mac
	$(butler) $(builddir)/$(subst publish-,,$@)/$(name).zip $(butler_target):$(subst publish-,,$@)
endef

publish-web:
	$(call publish)

publish-linux64:
	$(call publish)

publish-win64:
	$(call publish)

publish-mac:
	$(call publish_mac)
