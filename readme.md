# qduck

>修改自 [https://github.com/jparmstrong/qduck](https://github.com/jparmstrong/qduck)


`qduck` 为 kdb+/q 提供 DuckDB 支持，通过 `qduck.l64.so` 动态库使 q 代码可以直接执行 DuckDB SQL。

本项目包含自动下载 DuckDB 动态库、编译 `qduck` 扩展并安装到 kdb+ 环境的脚本。

或者可以直接下载 release 包, 解压放到模块路径下即可。

---

## 📦 1. 克隆仓库

```bash
git clone https://github.com/786980206/qduck.git
cd qduck
chmod +x build.sh
```

---

## 🔨 2. 编译

**Linux** — 使用 `build.sh`，自动完成 DuckDB 库下载、解压和 qduck 编译：

```bash
wget https://install.duckdb.org/v1.4.5/libduckdb-linux-amd64.zip
unzip libduckdb-linux-amd64.zip -d libduckdb
gcc -shared -fPIC -o qduck/qduck.l64.so src/c/qduck.c -I./libduckdb -L./libduckdb -lduckdb -mavx2 -O2 -Wl,-rpath,'$ORIGIN'
cp libduckdb/libduckdb.so qduck/
```

运行：

```bash
./build.sh
```

输出：

```
qduck/qduck.l64.so
qduck/libduckdb.so
```

**Windows** — 使用 `build.bat`（需要 [MinGW-w64](https://www.mingw-w64.org/)）：

```bat
build.bat
```

输出：

```
qduck\qduck.w64.dll
qduck\duckdb.dll
```

---

## 📥 3. 安装到 kdb+

将生成的模块复制到你的 kdb+ 模块目录：

```bash
cp -r qduck ${QHOME}/mod
# or
cp -r qduck ~/.kx/mod
```

确保 `${QHOME}/mod/qduck` 中包含：

```
qduck.l64.so
libduckdb.so
init.q
```

---

## ▶️ 4. 在 q 中使用

加载模块：

```q
.x: use `qduck
```

执行 DuckDB SQL：

```q
.x.e "select 123"
```

或直接使用语法糖：

```q
q)x)select 123
```

---

## ✔️ 完成

你现在可以在 kdb+ 中直接使用 DuckDB 作为 SQL 引擎，对 Parquet、CSV 或任意 DuckDB 支持的数据源进行查询。

如需我为你补充示例、多文件查询、Parquet 示例或 API 说明，也可以继续告诉我。
