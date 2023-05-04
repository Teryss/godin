cd ./src
odin build . -o:speed -no-bounds-check --microarch:native -out:godin.bin
cd ..
mv ./src/godin.bin ./godin.bin
chmod +x godin.bin