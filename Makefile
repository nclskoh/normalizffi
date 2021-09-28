all: ./Normaliz-build/lib/libnormaliz.so
	echo "running dune..."; ls; dune build --verbose; echo "ls again"; ls;
	dune build -p normalizffi @install; echo "ls yet again"; ls;
	dune install -p normalizffi --create-install-files normalizffi; echo "final ls"; ls

./Normaliz-build/lib/libnormaliz.so:
	cd ./Normaliz-offline; \
	echo "installing normaliz"; \
	./install_normaliz_with_eantic.sh; \
	cp -r local ../Normaliz-build; \
	cp -r local/include ./include; \
	echo "installed normaliz"

.PHONY: clean

clean:
	rm -r Normaliz-build

