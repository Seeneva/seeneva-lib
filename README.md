# Seeneva-lib

Native part of [Seeneva](https://github.com/Seeneva/seeneva-reader-android) comic book reader. Used to build `libseeneva` shared library. The output shared library is useful only for Android targets right now.

## Build

Check [Seeneva](https://github.com/Seeneva/seeneva-reader-android) documentation to know more about the building process for Android targets.

Also you can use Android [NDK](https://developer.android.com/ndk) and provided [CMakeLists.txt](CMakeLists.txt) to build output shared library without Gradle. Check Android [CMake](https://developer.android.com/ndk/guides/cmake.html#build-command) documentation to know more about it.  

## Formatting

This projects ships with predefined code styles:

- `.editorconfig`
- `rustfmt.toml` to format Rust code using [rustfmt](https://github.com/rust-lang/rustfmt).

Please ensure that they are enabled in your code editor.

## [License](https://www.gnu.org/licenses/gpl-3.0.html)

<p align="center">
    <img src="docs/img/icon/gplv3-or-later.svg" width=200>
</p>

```text
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
```

### Third party dependencies

This project uses third-party open source crates. Please check the [Cargo.toml](Cargo.toml) file to know more about them.
