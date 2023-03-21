# awk, gawk

## 常用

匹配与不匹配：

* `~` - 匹配正则
* `!~` - 不匹配正则
* `==` - 等于
* `!=` - 不等于


内置变量：

* `NF` - 字段个数，（读取的列数）
* `NR` - 记录数（行号），从1开始，新的文件延续上面的计数，新文件不从1开始
* `FNR` - 读取文件的记录数（行号），从1开始，新的文件重新从1开始计数
* `FS` - 输入字段分隔符，默认是空格
* `OFS` - 输出字段分隔符 默认也是空格
* `RS` - 输入行分隔符，默认为换行符
* `ORS` - 输出行分隔符，默认为换行符


打印或不打印:

* `NR==n` - 表示打印第n行
* `NR!=n` - 表示不打印第n行



## 获取外部变量

* 使用 `"'${VAR_NAME}'"`形式

    如: 要获取 `UID < 1000` 的所有用户名

    ```sh
    limit=1000
    awk -F':' '{if($3<"'${limit}'") print $1}' /etc/passwd
    ```

    此时, `"'${limit}'"` 被解释成字符串 `"1000"`, `awk` 进行字符串比对的结果并不是我们想得到的:

    ```sh
    ~] awk -F: '{if($3<"'${limit}'") print $1}' /etc/passwd
    root  # uid 0
    bin   # uid 1
    ```

* 通过传参

    ```sh
    # 格式一:
    awk -F':' '{if($3<limit) print $1}' limit=1000 /etc/passwd 
    
    # 格式二:
    awk -v limit=1000 -F':' '{if($3<limit) print $1}' /etc/passwd
    ```

    - `awk '{action}' name=value`, 这样传入的变量, `BEGIN` 字段的 {action} 不能正常取值, 因为 **`BEGIN` 的执行时机是在 `awk` 程序一开始，尚未读取任何数据之前**

    - `awk –v name1=value1 [–v name1=value1 …] 'BEGIN{action}' ...`, 用 `-v` 传入变量顺序在 `{action}` 前面, 所有 `{action}` 都可以正常取值

* 从环境变量获取

    `awk` 内置变量 `ENVIRON`, 是一个存放系统环境变量的字典数组, `键: 环境变量, 值:环境变量值`.

    ```sh
    awk 'BEGIN{for (i in ENVIRON) {print i"="ENVIRON[i];}}'
    awk 'BEGIN{print ENVIRON["LANG"]}'
    ```


## 指定输入、输出分隔符

| 用法                   | 解释                                     |
| ---------------------- | ---------------------------------------- |
| `-F','`                | 指定输入分隔符为"`,`"                    |
| `-v FS=',' -v OFS=':'` | 指定输入分隔符为"`,`"，输出分隔符为"`:`" |

* 输出分隔符
  
    示例:

    ```sh
    ~] echo "chrony,postfix" | awk -v FS=',' -v OFS=':' '{print $1,$2}'

    chrony:postfix
    ```

    使用`$0`时, `OFS`未生效：

    > `$0` is the whole record 

    ```sh
    ~] echo "chrony,postfix,sshd" | awk -v FS=',' -v OFS=':' '{print $0}'
    chrony,postfix,sshd
    ```

* 输入分隔符

    可使用以下方法指定多个分割符：

    ```sh
    # 0. 注：awk默认会忽略开头和结尾的空格
    # 1. 使用"[]"
    awk -F'[ :]' xxx   
    awk -F'[ :]+' xxx      # "+" 将连续出现的记录分隔符当一个处理  
    awk -F'[\\[\\]]+' xxx  # 特殊符号用 "\\" 来转义

    # 2. 1. 使用"|"
    awk -F'a|b' xxx
    ```

## 输出多列

- 使用 `$1, $2, ...` 形式

- 使用 `$0` 搭配 `$1, $2, ...`

    ```sh
    ~] cat a
    1 2 3 4 5 6 7 8 9 0
    1 2 3 4 5 6 7 8 9 0
    ```

    输出第2列到最后一列 (将第一列替换成空):

    ```sh
    ~] cat a | awk '{$1=""; print $0}'
     2 3 4 5 6 7 8 9 0
     2 3 4 5 6 7 8 9 0
    ```

    将第二列替换成空:

    ```sh
    ~] cat a | awk '{$2=""; print $0}'
    1  3 4 5 6 7 8 9 0
    1  3 4 5 6 7 8 9 0
    ```

    输出第6列到最后一列 (将前5列替换成空):

    ```sh
    ~] cat a | awk '{for(i=1; i<=5; i++){ $i=""};print $0}' # 
        6 7 8 9 0
        6 7 8 9 0
    ```

    行首的空格可用 `sed` 处理:

    ```sh
    ~] cat a | awk '{for(i=1; i<=5; i++){ $i=""};print $0}' | sed 's/^[[:space:]]*//g'
    6 7 8 9 0
    6 7 8 9 0
    ```

- 使用函数

    输出第4列到最后一列, 使用空格作为分隔符:

    ```sh
    ~] cat a | awk '{for (i=4;i<=NF;i++)printf("%s ", $i);print ""}'
    4 5 6 7 8 9 0 
    4 5 6 7 8 9 0 
    ```

    输出第4列到最后一列, 使用 `,` 作为分隔符:

    ```sh
    ~] cat a | awk '{for (i=4;i<=NF;i++)printf("%s,", $i);print ""}'
    4,5,6,7,8,9,0,
    4,5,6,7,8,9,0,
    ```

    行尾的分隔符可用 `sed` 处理:

    ```sh
    ~] cat a | awk '{for (i=4;i<=NF;i++)printf("%s,", $i);print ""}' | sed 's/\,*$//g'
    4,5,6,7,8,9,0,
    4,5,6,7,8,9,0,
    ```

## 依据列字段进行数据匹配

```sh
awk '$2 ~ /^f/ {print $0}' a.txt # 提取第二列以f开头的行
awk '$3 ~ /^r/ {print $0}' a.txt # 提取第三列以r开头的行
awk '$1 ~ /r$/ {print $0}' a.txt # 提取第一列以r结尾的行
awk '$3 ~ /^r|^s/ {print $0}' a.txt  # 同时提取第三列以r开头或者以s开头的行
awk '$3 ~ /^r.*w$/ {print $0}' a.txt # 提取第三列以r开头同时以w结尾的行
```


