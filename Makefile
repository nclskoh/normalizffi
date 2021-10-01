all: ./Normaliz-build/lib/libnormaliz.so
	echo "running dune..."; ls; dune build --verbose; echo "Make done"

./Normaliz-build/lib/libnormaliz.so:
	cd ./Normaliz-offline; \
	echo "installing normaliz"; \
	./install_normaliz.sh; \
	cp -r local ../Normaliz-build; \
	cp -r local/include ./include; \
	echo "installed normaliz"

.PHONY: clean

clean:
	rm -r Normaliz-build

