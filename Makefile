all: ./Normaliz-build/lib/libnormaliz.so
	echo "running dune..."; ls; dune build --verbose; echo "ls again"; ls

./Normaliz-build/lib/libnormaliz.so:
	cd ./Normaliz-off; \
	echo "installing normaliz"; \
	./install_normaliz_with_eantic.sh; \
	cp -r local ../Normaliz-build; \
	cp -r local/include ./include; \
	echo "installed normaliz"

.PHONY: clean

clean:
	rm -r Normaliz-build

