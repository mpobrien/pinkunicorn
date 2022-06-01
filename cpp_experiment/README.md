# Playing with cpp interface

it uses realm-core as submodule before to run cmake

```
git submodule update --init --recursive
mkdir build 
cd build
cmake -D CMAKE_BUILD_TYPE=<Debug/Release> ..
cmake --build .
./pink_unicorn
```

### it just sync the remote sync with whatever schema it has