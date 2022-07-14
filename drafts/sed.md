# sed

> sed - stream editor for filtering and transforming text

使用格式:

```sh
sed OPTIONS... [SCRIPT] [INPUTFILE...]
```

## 命令行选项



input-file: 指定操作的文件；如果没指定 input-file 或者指定 - 表明 sed 将从标准输入中读取数据


## Options

--help     display this help and exit
--version  output version information and exit
--debug    开启 debug 模式，将会详细输出执行过程
-n, --quiet, --silent
           禁用自动打印模式空间（默认会全部打印全部模式空间内容）
-e script, --expression=script
           指定要执行的脚本命令
-f script-file, --file=script-file
           指定要执行的脚本命令文件
-i[SUFFIX], --in-place[=SUFFIX]
           表明 sed 将要就地修改文件，而不是只在内存中操作然后打印
           1) sed 会先新建一个临时文件
           2) 将原本输出到标准输出的内容写入临时文件
           3) 最后将这个临时文件修改成目标文件 (如果通过 "SUFFIX" 指定了后缀，原文件会以这个后缀被备份)
--follow-symlinks
           (仅和 "-i" 一起才生效) 表明 sed 将始终修改符号链接指向的原文件
           (默认行为是破坏符号链接，这样链接目的地就不会被修改)

-l N, --line-length=N
       specify the desired line-wrap length for the `l' command
--posix
       disable all GNU extensions.
-E, -r, --regexp-extended
       use extended regular expressions in the script (for portability use POSIX -E).
-s, --separate
       consider files as separate rather than as a single, continuous long stream.
--sandbox
       operate in sandbox mode (disable e/r/w commands).
-u, --unbuffered  load minimal amounts of data from the input files and flush the output buffers more often
-z, --null-data   separate lines by NUL characters

If no -e, --expression, -f, or --file option is given, then the first non-option argument is taken as the sed script to interpret.  All remaining arguments are names of input files; if no in‐
       put files are specified, then the standard input is read.


-- 

替换指定行行尾的换行符：

```sh
~] cat test.txt
VLAN96
10.5.96.132/24
VLAN305
10.5.5.14/24
```

```sh
~] cat test.txt | sed '/VLAN[0-9]*/N;s/\n/: /'
VLAN96: 10.5.96.132/24
VLAN305: 10.5.5.14/24

~] cat test.txt | sed ':a;N;s/\n/: /;ba' # 或 sed ':a;N;s/\n/: /;ta'

VLAN96: 10.5.96.132/24: VLAN305: 10.5.5.14/24

# N 是把下一行加入到当前的 hold space 模式空间里，使之进行后续处理
# :a ta 或 :a ba 是配套使用, 实现跳转; t 多一层判断
```



-i[SUFFIX], --in-place[=SUFFIX]

    ```sh
    ~] ls
    a
    b -> a

    ~] cat a
    aa

    ~] sed --follow-symlinks -i 's/a/b/' b
    ~] cat a
    ba
    ~] ls
    a
    b -> a

    ~] sed --follow-symlinks -i'.bak' 's/a/b/' b
    ~] cat a
    ba
    ~] cat a.bak
    aa
    ~] ls
    a
    a.bak
    b -> a

    ~] sed -i 's/a/b/' b
    ~] cat a
    aa
    ~] cat b
    ba
    ~] ls
    a
    b

    ~] sed -i'.bak' 's/a/b/' b
    ~] cat a
    aa
    ~] cat b
    ba
    ~] ls
    a
    b
    b.bak -> a

    ```


--debug 

    ```sh
    ~] cat test.txt
    aaaa
    bbbb
    
    ~] sed --debug -n 's/a/b/p' test.txt
    SED PROGRAM:
      s/a/b/p
    INPUT:   'test.txt' line 1  
    PATTERN: aaaa
    COMMAND: s/a/b/p
    MATCHED REGEX REGISTERS
      regex[0] = 0-1 'a'
    baaa                          # 第一行经过sed处理后的输出
    PATTERN: baaa
    END-OF-CYCLE:
    INPUT:   'test.txt' line 2
    PATTERN: bbbb
    COMMAND: s/a/b/p
    PATTERN: bbbb
    END-OF-CYCLE:                 # "-n" 屏蔽了模式空间的输出，而第二行又未匹配到规则，所以没有被 "p" 打印
    ```



* 删除匹配行和匹配行后5行

    ```sh
    sed '/pipei/,+5d' filename
    ```


* 删除 "InternalIP" 和 "Allocated resources" 中间的所有行

```sh
~] cat aaa.txt
  InternalIP:  10.2.56.231
  Hostname:    ran-test-hw12-1
Capacity:
  cpu:                8
  ephemeral-storage:  51175Mi
  hugepages-1Gi:      0
--
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests       Limits
  --------           --------       ------
  cpu                7150m (89%)    9400m (117%)
  memory             12688Mi (79%)  13258Mi (83%)
--
  InternalIP:  10.2.56.232
  Hostname:    ran-test-hw12-2
Capacity:
  cpu:                8
  ephemeral-storage:  51175Mi
  hugepages-1Gi:      0
--
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests      Limits
  --------           --------      ------
  cpu                2620m (32%)   5800m (72%)
  memory             3376Mi (21%)  4956Mi (31%)

~] sed '/InternalIP/,/^Allocated/{/InternalIP/!{/^Allocated/!d}}' aaa.txt
  InternalIP:  10.2.56.231
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests       Limits
  --------           --------       ------
  cpu                7150m (89%)    9400m (117%)
  memory             12688Mi (79%)  13258Mi (83%)
--
  InternalIP:  10.2.56.232
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests      Limits
  --------           --------      ------
  cpu                2620m (32%)   5800m (72%)
  memory             3376Mi (21%)  4956Mi (31%)
```