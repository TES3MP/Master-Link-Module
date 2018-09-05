mkdir cmake-build-msvc-release-Win64 & pushd cmake-build-msvc-release-Win64
cmake -G "Visual Studio 15 2017 Win64" ^
	-DLUA_INCLUDE_DIR="C:\projects\lua-5.1.5\src" -DLUA_LIBRARY="C:\projects\lua-5.1.5\src\lua51.lib" ^
	-DCURL_LIBRARY="C:\projects\curl-7.61.0\cmake-build-msvc-release-Win64\lib\Release\libcurl.lib" ^
	-DCURL_INCLUDE_DIR=C:\projects\curl-7.61.0\include ^
	..
popd
cmake --build cmake-build-msvc-release-Win64 --config Release --parallel
