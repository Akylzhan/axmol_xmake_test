add_rules("mode.debug", "mode.release")

add_rules("plugin.compile_commands.autoupdate", {outputdir = "$(builddir)"})

set_languages("c++23")

if is_plat("linux") then
    set_toolchains("clang")
elseif is_plat("wasm") then
    add_requires("emscripten 4.0.8")
    add_requireconfs("emscripten.openssl", { system = true })
    set_toolchains("emcc@emscripten")
end

includes("axmol")

target("axmol_test")
    set_kind("binary")
    add_files("src/*.cpp")

    set_warnings("allextra", "pedantic")

    -- set_rundir("assets") -- workaround for loading assets

    if is_mode("release") then
        set_optimize("fastest")
        set_policy("build.optimization.lto", true)
    elseif is_mode("debug") then
        set_policy("build.sanitizer.address", true)
        set_policy("build.sanitizer.undefined", true)
        set_policy("build.sanitizer.leak", true)
    end

    before_run(function(target)
        local assets_symlink_path = path.join(target:targetdir(), "assets")
        if not os.exists(assets_symlink_path) then
            os.ln(path.absolute("assets"), assets_symlink_path)
        end
    end)

    after_install(function(target)
        -- copy assets
    end)

    if is_plat("wasm") then
        add_ldflags(
            "-sUSE_GLFW=3 "..
            "-sASSERTIONS "..
            "-sMIN_WEBGL_VERSION=2 "..
            "-sGL_ENABLE_GET_PROC_ADDRESS "..
            "--use-preload-cache "..
            -- "-pthread -sPTHREAD_POOL_SIZE=4 ".. -- needs dependencies to compile with -pthread
            "-sFORCE_FILESYSTEM=1 -sFETCH=1 "..
            "-lidbfs.js "..
            "--shell-file axmol/core/platform/wasm/shell_minimal.html",
            {expand = false}
        )
        add_values("wasm.preloadfiles", "assets", "./$(builddir)/$(plat)/$(arch)/$(mode)/axslc@/") -- targetdir
    end

    add_deps("axmol")
--
-- If you want to known more usage about xmake, please see https://xmake.io
--
-- ## FAQ
--
-- You can enter the project directory firstly before building project.
--
--   $ cd projectdir
--
-- 1. How to build project?
--
--   $ xmake
--
-- 2. How to configure project?
--
--   $ xmake f -p [macosx|linux|iphoneos ..] -a [x86_64|i386|arm64 ..] -m [debug|release]
--
-- 3. Where is the build output directory?
--
--   The default output directory is `./build` and you can configure the output directory.
--
--   $ xmake f -o outputdir
--   $ xmake
--
-- 4. How to run and debug target after building project?
--
--   $ xmake run [targetname]
--   $ xmake run -d [targetname]
--
-- 5. How to install target to the system directory or other output directory?
--
--   $ xmake install
--   $ xmake install -o installdir
--
-- 6. Add some frequently-used compilation flags in xmake.lua
--
-- @code
--    -- add debug and release modes
--    add_rules("mode.debug", "mode.release")
--
--    -- add macro definition
--    add_defines("NDEBUG", "_GNU_SOURCE=1")
--
--    -- set warning all as error
--    set_warnings("all", "error")
--
--    -- set language: c99, c++11
--    set_languages("c99", "c++11")
--
--    -- set optimization: none, faster, fastest, smallest
--    set_optimize("fastest")
--
--    -- add include search directories
--    add_includedirs("/usr/include", "/usr/local/include")
--
--    -- add link libraries and search directories
--    add_links("tbox")
--    add_linkdirs("/usr/local/lib", "/usr/lib")
--
--    -- add system link libraries
--    add_syslinks("z", "pthread")
--
--    -- add compilation and link flags
--    add_cxflags("-stdnolib", "-fno-strict-aliasing")
--    add_ldflags("-L/usr/local/lib", "-lpthread", {force = true})
--
-- @endcode
--

