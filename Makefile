all: ./Normaliz-offline/local/lib/libnormaliz.so
	echo "running dune..."; ls; dune build --verbose; echo "Make done"

./Normaliz-offline/local/lib/libnormaliz.so:
	cd ./Normaliz-offline; \
	echo "installing normaliz"; \
	./install_normaliz_with_eantic.sh; \
	echo "installed normaliz"

.PHONY: clean

clean:
	rm -r Normaliz-offline/local
	rm -r Normaliz-offline/build

