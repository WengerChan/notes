# echo, printf

## echo

```sh
-e 解释转义字符
-n 不换行
-E 不解释转移字符(默认))
```

### 颜色控制

```sh
echo -e "\033[NUM1;NUM2;m STRING \033[0m"
```

* `\033`: 转义起始符，定义一个转义序列，可以使用 `\e` 或 `\E` 代替。
* `[`: 表示开始定义颜色。
* `NUM1`: 字体背景范围 40-47 (黑、红、绿、黄、蓝、紫、天蓝、白)
* `NUM2`: 字体颜色范围 30-37 (黑、红、绿、黄、蓝、紫、天蓝、白)
    特殊地，黑底彩色范围 90-97 (黑、红、绿、黄、蓝、紫、天蓝、白) 即`NUM1`默认为黑色
* `m`: 转义终止符，表示颜色定义完毕。
* `\033[`: 表示再次开启颜色定义，0 表示颜色定义结束，所以 \033[0m 的作用是恢复之前的配色方案
* `STRING`: 要打印的字符串

### 字体控制选项

* `\e[0m`: 关闭所有属性
* `\e[1m`: 设置高亮度
* `\e[4m`: 下划线
* `\e[5m`: 闪烁
* `\e[7m`: 反显，撞色显示，显示为白字黑底，或者显示为黑底白字
* `\e[8m`: 消影，字符颜色将会与背景颜色相同
* `\e[nA`: 光标上移 n 行
* `\e[nB`: 光标下移 n 行
* `\e[nC`: 光标右移 n 字符
* `\e[nD`: 光标左移 n 字符
* `\e[y;xH`: 设置光标位置
* `\e[2J`: 清屏
* `\e[K`: 清除从光标到行尾的内容
* `\e[s`: 保存光标位置
* `\e[u`: 恢复光标位置
* `\e[?25`: 隐藏光标
* `\e[?25h`: 显示光标
* `\e[60G`: 将光标移动至本行第60个字符处，60可替换成其他数字


### 示例

* 示例1：

    ```sh
    echo -en "\e[2J\e[1;1HStart Game...\e[60G\e[5;33mLoading\e[0m"
    sleep 5
    echo -e "\e[7D\e[K\e[32m[ OK ]\e[0m"
    ```

* 示例2: ping脚本

    ```sh
    for ip in $(cat ip_list);do
        echo -n -e "Ping ${ip}\033[40G\033[5;33mPing...\033[0m"
        ping -c 1 -W 5 ${ip} 1>/dev/null 2>&1
        [ $? -eq 0 ] && status="32m[OK]" || status="31m[ERROR]"
        echo -e "\033[7D\033[K\033[${status}\033[0m"
    done
    ```

* 示例3: 从 git 远程库拉取的脚本

    [`pull.sh`](../scripts/pull_git.sh)


* 示例4: 推送到 git 远程库的脚本

    [`push.sh`](../scripts/pull_git.sh)


## printf

```sh
printf [-v var] format [arguments]

# -v var：将结果输出到变量var中而不是输出到标准输出
# format：输出格式
# arguments：一到多个参数
```

### 转义字符

```sh
\"          # 双引号
\\          # 反斜杠
\a          # 响铃
\b          # 退格
\c          # 截断输出
\e          # 退出
\f          # 翻页
\n          # 换行
\r          # 回车
\t          # 水平制表符
\v          # 竖直制表符
\NNN        # 八进制数 (1到3位数字)
\xHH        # 十六进制数 (1到2位数字)
\uHHHH      # Unicode字符附加4位十六进制数字
\UHHHHHHHH  # Unicode字符附加8位十六进制数字
%%          # 百分号
```

内建printf还支持以下转义序列：

```sh
%q       # 将参数扩起以用作shell输入
```

```sh
~] printf "%q" 'a b c'
a\ b\ c

~] printf "%q" 'a b c\n'
a\ b\ c\\n
``` 

### 格式替换符(format substitution character)

* 类型转换符

    ```sh
    %d, %i # 整数
    %f     # 浮点数
    %e, %E # 科学计数法
    %s     # 字符串
    %x, %X # 十六进制(unsigned)
    %o, %O # 八进制(unsigned)
    %u     # unsigned decimal
    ```

* Flag Characters:

    ```sh
    # 1. C Standard +5
    "#" # 单个#: 在八进制数前显示"0", 十六进制数前显示"0x"/"0X"
    0   # 用0在左侧填充; '-'和'0'同时出现时，忽略'0'
    -   # 左对齐（默认右对齐
    ' ' # 空格: 正数前留空格
    +   # 正数前显示"+"符号

    # 2. SUSv2 +1
    ''  # 单引号，按本地locale输出数字
        # eg.. Locale = en_US.UTF-8
          ~] printf "%'.2f" 1234567.89
          1,234,567.89

          ~] printf "%''.2f" 1234567.89
          1,234,567.89   

    # 3. glibc2 +1
    I  # 
    ```

### 示例

* 格式控制

    ```sh
    # 单引号、双引号、或者不加引号都一样，但是转义字符需要用引号
    ~] printf "%d %s\n" 1 'hello'
    1 hello

    ~] printf "%d %s\n" 1 'hello'
    1 hello
    ```

* 取变量

    ```sh
    ~] a=10; b='hello'
    ~] printf "%d %s\n" $a $b
    10 hello
    ```

* `%m,nf`, `%md`: *m*表示整体长度，*n*表示小数部分长度

    `%5,2f`, `%-5,2f`, `%10d`, `%-10d`, `%010d`

* `format`会被重用; 参数数量不够时，`%d`使用"0"、`%s`使用"NULL"(即"空")补充

    ```sh
    ~] printf "%d %d %d\n" $(seq 1 10)
    1 2 3
    4 5 6
    7 8 9
    10 0 0
    ~] printf "%s %s %s\n" $(seq 1 10)
    1 2 3
    4 5 6
    7 8 9
    10 
    ```

* 转移序列

    ```sh
    ~] printf 'abc\b'  # 退格; 使字符c显示不出来，但是不代表字符c不在
    ab
    ~] str=$(printf 'abc\b')
    ~] echo $str
    abc

    ~] printf 'line1\fline2'  # 换页符。line2前面缩进与line1长度有关，在word 中，abc 和 hello 各一页。
    line1
        line2
    ~] printf "linelinelineline1\fline2"
    linelinelineline1
                    line2

    ~] printf "abc\rdef"    # 回车。此操作会将当前行内容清空。
    def
    ~] str=$(printf 'abc\rdef')
    ~] echo $str
    def

    ~] printf "1234567\t[end]"# 水平制表符。Linux中占8位
    1234567	[end]

    ~] printf "linelinelineline1\fline2" # 垂直制表符。在同一页，注意区别\f
    linelinelineline1
                    line2

    ~] printf '\101' # 打印八进制/十六进制值代表的字符(ASCII)
    A
    ~] printf '\141'
    a
    ~] printf '\x41'
    A
    ~] printf '\x61'
    a
    ```