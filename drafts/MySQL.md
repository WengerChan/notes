# MySQL

## 一、MySQL数据库基础篇

### 1. 数据库概述与MySQL安装篇

#### 第01章：数据库概述

* 为什么要使用数据库？

    持久化存储数据

* 数据库、数据库管理系统、SQL

    DB-数据库， 本质是一个文件系统，它保存了一系列有组织的数据
    
    DBMS-数据库管理系统，是操纵和管理数据的软件
    
    SQL-结构化查询语言（Structured Query Language）

* 关系型数据库和非关系型数据库

    * 关系型数据库RDBMS 以 行(row) 和 列(column) 的形式存储数据，以便于用户理解。这一系列的行和列被称为 表(table) ，一组表组成了一个库(database)。

    * 优势:

        复杂查询 可以用SQL语句方便的在一个表以及多个表之间做非常复杂的数据查询。

        事务支持 使得对于安全性能很高的数据访问要求得以实现
    
    * 非关系型数据库

        键值型数据库, 典型使用场景是作为内存缓存, redis
        
        文档型数据库, MongoDB, Couch DB

        搜索引擎数据库, Solr, Elasticsearch, Splunk
        
        列式数据库, HBase
        
        图形数据库, Neo4J, InfoGrid

* 数据库设计规则

    E-R（entity-relationship，实体-联系）模型中有三个主要概念是： 实体集、 属性、 联系集。

    一个实体集（class）对应于数据库中的一个表（table）
    
    一个实体（instance）则对应于数据库表中的一行（row），也称为一条记录（record）
    
    一个属性（attribute）对应于数据库表中的一列（column），也称为一个字段（field）。

* 表的关联关系

    
    一对一
    
    一对多: 在从表(多方)创建一个字段，字段作为外键指向主表(一方)的主键
    
    多对多: 要表示多对多关系，必须创建第三个表，该表通常称为 联接表，它将多对多关系划分为两个一对多关系，将这两个表的主键都插入到第三个表中
    
    自我引用: 


#### 第02章：MySQL环境搭建

* 登录方式

    * MySQL 自带客户端
    
    * 命令行

        ```sh
        mysql -h 主机名 -P 端口号 -u 用户名 -p密码

        # mysql -h localhost -P 3306 -u root -pabc123
        ```

* 修改编码

    在MySQL 8.0版本之前，默认字符集为 `latin1` ，utf8 字符集指向的是 `utf8mb3` 。

    从MySQL 8.0开始，数据库的默认编码改为 `utf8mb4` ，从而避免了上述的乱码问题

    * 步骤1：查看编码命令

        ```sh
        show variables like 'character_%';
        show variables like 'collation_%';
        ```

    * 步骤2：修改mysql的数据目录下的 my.ini 配置文件

        ```sh
        [mysql]
        ...
        default-character-set=utf8
        [mysqld]
        ...
        character-set-server=utf8
        collation-server=utf8_general_ci
        ```

    * 重启服务

* 查看目录信息

    ```sql
    mysql> SELECT @@basedir,@@datadir FROM DUAL;

    +---------------------------------------------+------------------------------------------+
    | @@datadir                                   | @@basedir                                |
    +---------------------------------------------+------------------------------------------+
    | C:\ProgramData\MySQL\MySQL Server 5.7\Data\ | C:\Program Files\MySQL\MySQL Server 5.7\ |
    +---------------------------------------------+------------------------------------------+

    mysql> SHOW VARIABLES LIKE '%dir%';
    ```

* 忘记root密码

    * 1 关闭mysqld进程
    
    * 2 执行命令手动启动mysql: `mysqld --defaults-file="xxxx/my.ini" --skip-grant-tables`
    
    * 3 连接到mysql: `mysql -uroot`
    
    * 4 修改密码

        ```sql
        use mysql;
        update user set authentication_string=password('password') where user='root' and Host='localhost';
        flush privileges;
        ```
    * 5 重启mysql服务, 此时不需要添加 `--skip-grant-tables` 参数


### 2. SQL之SELECT使用篇

#### 第03章：基本的SELECT语句

* SQL 分类

    DDL（Data Definition Languages、数据定义语言）: 定义了不同的数据库、表、视图、索引等数据库对象，还可以用来创建、删除、修改数据库和数据表的结构

    DML（Data Manipulation Language、数据操作语言）: 用于添加、删除、更新和查询数据库记录，并检查数据完整性

    DCL（Data Control Language、数据控制语言）: 用于定义数据库、表、字段、用户的访问权限和安全级别


    | 类型 | 关键字 |
    | -- | :-- |
    | DDL | CREATE, DROP, ALTER |
    | DML | INSERT, DELETE, UPDATE, SELECT |
    | DCL | GRANT, REVOKE,COMMIT, ROLLBACK, SAVEPOINT |

* SQL基本规则

    * SQL 可以写在一行或者多行。为了提高可读性，各子句分行写，必要时使用缩进

    * 每条命令以 `;` 或 `\g` 或 `\G` 结束

    * 关键字不能被缩写也不能分行

    * 关于标点符号
        
        * 必须保证所有的 `()`、单引号、双引号是 **成对** 结束的
        
        * 必须使用英文状态下的 **半角** 输入方式
        
        * 字符串型和日期时间类型的数据可以使用单引号 `''` 表示
        
        * 列的别名，尽量使用双引号 `""`，而且不建议省略 `as`

    * 大小写规范

        * 建议 数据库名、表名、表别名、字段名、字段别名等都小写
        * 建议 SQL 关键字、函数名、绑定变量等都大写

    * 注释

        * 单行注释：`# 注释文字` (MySQL特有的方式)

        * 单行注释：`-- 注释文字`(--后面必须包含一个空格。)

        * 多行注释：`/* 注释文字 */`

* 去除重复行: `DISTINCT`

    ```sql
    SELECT DISTINCT department_id
    FROM employees;
    ```

* 查询常数

    ```sql
    mysql> SELECT 'DaA' AS corporation, last_name
        -> FROM employees;

    +-------------+-----------+
    | corporation | last_name |
    +-------------+-----------+
    | DaA         | King      |
    | DaA         | Kochhar   |
    | DaA         | De Haan   |
    | DaA         | Hunold    |
    | DaA         | Ernst     |
    +-------------+-----------+
    ```

* 显示表结构: `DESC`/`DESCRIBE`



#### 第04章：运算符


* 算术运算符

    | 运算符 | 作用 |
    | -- | :-- |
    | + | 加, 计算和 |
    | - | 减, 计算差 |
    | * | 乘, 计算乘积 |
    | / 或 DIV | 除, 计算商 |
    | % 或 MOD | 求模/求余, 计算余数 |

    ```sql
    mysql> SELECT 100, 100 + 0, 100 - 0, 100 + 50, 100 + 50 -30, 100 + 35.5, 100 - 35.5
        -> FROM DUAL;

    +-----+---------+---------+----------+--------------+------------+------------+
    | 100 | 100 + 0 | 100 - 0 | 100 + 50 | 100 + 50 -30 | 100 + 35.5 | 100 - 35.5 |
    +-----+---------+---------+----------+--------------+------------+------------+
    | 100 |     100 |     100 |      150 |          120 |      135.5 |       64.5 |
    +-----+---------+---------+----------+--------------+------------+------------+
    1 row in set (0.02 sec)
    ```

    一个整数类型的值对整数进行加法和减法操作，结果还是一个整数；一个整数类型的值对浮点数进行加法和减法操作，结果是一个浮点数。


    ```sql
    mysql> SELECT 100, 100 * 1, 100 * 1.0, 100 / 1.0, 100 / 2,100 + 2 * 5 / 2,100 /3, 100 DIV 0 
        -> FROM DUAL;

    +-----+---------+-----------+-----------+---------+-----------------+---------+-----------+
    | 100 | 100 * 1 | 100 * 1.0 | 100 / 1.0 | 100 / 2 | 100 + 2 * 5 / 2 | 100 /3  | 100 DIV 0 |
    +-----+---------+-----------+-----------+---------+-----------------+---------+-----------+
    | 100 |     100 |     100.0 |  100.0000 | 50.0000 |        105.0000 | 33.3333 |      NULL |
    +-----+---------+-----------+-----------+---------+-----------------+---------+-----------+
    1 row in set (0.00 sec)


    mysql> SELECT employee_id, salary, salary * 12 AS annual_sal
        -> FROM employees LIMIT 0,5;

    +-------------+----------+------------+
    | employee_id | salary   | annual_sal |
    +-------------+----------+------------+
    |         100 | 24000.00 |  288000.00 |
    |         101 | 17000.00 |  204000.00 |
    |         102 | 17000.00 |  204000.00 |
    |         103 |  9000.00 |  108000.00 |
    |         104 |  6000.00 |   72000.00 |
    +-------------+----------+------------+
    5 rows in set (0.00 sec)
    ```
    
    一个数乘以整数1和除以整数1后仍得原数；
    
    一个数乘以浮点数1和除以浮点数1后变成浮点数，数值与原数相等；
    
    一个数除以整数后，不管是否能除尽，结果都为一个浮点数；
    
    一个数除以另一个数，除不尽时，结果为一个浮点数，并保留到小数点后4位；
    
    乘法和除法的优先级相同，进行先乘后除操作与先除后乘操作，得出的结果相同。
    
    在数学运算中，0不能用作除数，在MySQL中，一个数除以0为NULL。


    ```sql
    mysql> SELECT 12 % 3, 12 MOD 5
        -> FROM DUAL;

    +--------+----------+
    | 12 % 3 | 12 mod 5 |
    +--------+----------+
    |      0 |        2 |
    +--------+----------+
    1 row in set (0.05 sec)
    ```


* 比较运算符

    比较运算符用来对表达式左边的操作数和右边的操作数进行比较，比较的结果为真则返回1，比较的结果为假则返回0，其他情况则返回NULL。


    | 运算符 | 作用 |
    | -- | :-- |
    | = | 等于, 比较值,字符串,表达式是否相等 |
    | <=> | 等于, 可以对 NULL 值比较 |
    | <>,!= | 不等于 |
    | < | 小于 |
    | <= | 小于等于 |
    | > | 大于 |
    | >= | 大于等于 |

    非符号类型的运算符:

    | 运算符 | 作用 |
    | -- | :-- |
    | `IS NULL` | 为空 |
    | `ISNULL` | 为空 |
    | `IS NOT NULL` | 不为空 |
    | `LEAST` | 最小值, 在多个值中返回最小值 |
    | `GREATEST` | 最大值, 在多个值中返回最大值 |
    | `BETWEEN AND` | 两值之间 |
    | `IN` | 属于, IN (A, B, ...) |
    | `NOT IN` | 不属于, NOT IN (A, B, ...) |
    | `LIKE` | 模糊匹配, `%`:任意个任意字符, `_`: 1个任意字符, `\`:转义字符 |
    | `REGEXP` | 正则表达式 |
    | `RELIKE` | 正则表达式 |

    ```sql
    SELECT job_id 
    FROM jobs 
    WHERE job_id LIKE 'IT$_%' ESCAPE '$'  -- 自定义转义字符
    ```

* 逻辑运算符

    | 运算符 | 作用 |
    | -- | :-- |
    | AND, && | 逻辑与 |
    | OR, \|\| | 逻辑或 |
    | NOT, ! | 逻辑非 |
    | XOR |  逻辑异或 | 


    ```sql
    mysql> SELECT NOT 1, NOT 0, NOT (1+1), NOT !1, NOT NULL;

    +-------+-------+-----------+--------+----------+
    | NOT 1 | NOT 0 | NOT (1+1) | NOT !1 | NOT NULL |
    +-------+-------+-----------+--------+----------+
    |     0 |     1 |         0 |      1 |     NULL |
    +-------+-------+-----------+--------+----------+
    1 row in set (0.00 sec)


    mysql> SELECT 1 AND -1, 1 AND 0, 0 AND NULL, 1 AND NULL, -1 AND NULL;

    +----------+---------+------------+------------+-------------+
    | 1 AND -1 | 1 AND 0 | 0 AND NULL | 1 AND NULL | -1 AND NULL |
    +----------+---------+------------+------------+-------------+
    |        1 |       0 |          0 |       NULL |        NULL |
    +----------+---------+------------+------------+-------------+
    1 row in set (0.01 sec)


    mysql> SELECT 1 OR -1, 1 OR 0, 0 OR NULL, 1 OR NULL, -1 OR NULL, NULL OR 1;
    
    +---------+--------+-----------+-----------+------------+-----------+
    | 1 OR -1 | 1 OR 0 | 0 OR NULL | 1 OR NULL | -1 OR NULL | NULL OR 1 |
    +---------+--------+-----------+-----------+------------+-----------+
    |       1 |      1 |      NULL |         1 |          1 |         1 |
    +---------+--------+-----------+-----------+------------+-----------+
    1 row in set (0.01 sec)

    -- OR可以和AND一起使用，但是在使用时要注意两者的优先级，由于AND的优先级高于OR，因此先对AND两边的操作数进行操作，再与OR中的操作数结合。


    mysql> SELECT 0 XOR 0, 1 XOR -1, 1 XOR 0, 0 XOR NULL, 1 XOR NULL, -1 XOR NULL, NULL XOR 1;

    +---------+----------+---------+------------+------------+-------------+------------+
    | 0 XOR 0 | 1 XOR -1 | 1 XOR 0 | 0 XOR NULL | 1 XOR NULL | -1 XOR NULL | NULL XOR 1 |
    +---------+----------+---------+------------+------------+-------------+------------+
    |       0 |        0 |       1 |       NULL |       NULL |        NULL |       NULL |
    +---------+----------+---------+------------+------------+-------------+------------+
    1 row in set (0.00 sec)

    -- 逻辑异或（XOR）运算符是当给定的值中任意一个值为NULL时，则返回NULL；如果两个非NULL的值都是0或者都不等于0时，则返回0；如果一个值为0，另一个值不为0时，则返回1。
    ```

* 位运算符

    | 运算符 | 作用 |
    | -- | :-- |
    | & | 按位与 |
    | \| | 按位或 |
    | ^ | 按位异或 |
    | ~ | 按位取反 |
    | >> | 按位右移 |
    | << | 按位左移 |

    按位右移运算符 按位右移（>>）运算符将给定的值的二进制数的所有位右移指定的位数。右移指定的位数后，右边低位的数值被移出并丢弃，左边高位空出的位置用0补齐

    按位左移运算符 按位左移（<<）运算符将给定的值的二进制数的所有位左移指定的位数。左移指定的位数后，左边高位的数值被移出并丢弃，右边低位空出的位置用0补齐。


* 运算符的优先级

    ![运算符优先级](./pictures/MySQL/运算符优先级.png)


#### 第05章：排序与分页

* 排序数据 `ORDER BY`
 
    ASC（ascend）: 升序

    DESC（descend）: 降序


    ```sql
    -- 单列排序
    SELECT last_name, job_id, department_id, hire_date
    FROM employees
    ORDER BY salary;  -- 可以使用 select 未选中的字段

    -- 多列排序
    SELECT last_name, job_id, department_id, hire_date
    FROM employees
    ORDER BY last_name, hire_date;

    -- 默认使用升序排列, 可使用 ASC 和 DESC 进行设置
    -- 使用 ASC 时, NULL值在最前面
    -- 使用 DESC 时, NULL值在最后面
    SELECT last_name, job_id, department_id, hire_date
    FROM employees
    ORDER BY last_name DESC, hire_date ASC;
    ```

* 分页

    ```sql
    SELECT ...
    FROM ...
    WHERE ...
    ORDER BY ...
    LIMIT [位置偏移量,] 行数 -- 位置偏移量省略时, 等同于设置为 0
    ```

    假设要设置每页显示 item_num 条记录, 则要显示第 x 页时:

    ```sql
    LIMIT (x-1)*item_num, item_num
    ```

    其他语言使用分页:

    ```sql
    --LIMIT: MySQL, PGSQL, SQLite
    SELECT last_name, job_id FROM employees LIMIT 10,5;

    --LIMIT ... OFFSET ...: MySQL 8.0
    SELECT last_name, job_id FROM employees LIMIT 5 OFFSET 10;

    -- TOP: SQL Server, Access
    SELECT TOP 5 name, hp_max FROM heros ORDER BY hp_max DESC;

    -- FETCH FIRST 5 ROWS ONLY
    SELECT name, hp_max FROM heros ORDER BY hp_max DESC FETCH FIRST 5 ROWS ONLY;

    -- rownum: Oracle 的 rownum 是个隐藏字段, 记录数据编号
    SELECT rownum,last_name,salary FROM employees WHERE rownum < 5 ORDER BY salary DESC;
    ```

#### 第06章：多表查询

#### 第07章：单行函数

#### 第08章：聚合函数

#### 第09章：子查询

### 3. SQL之DDL、DML、DCL使用篇

#### 第10章：创建和管理表

#### 第11章：数据处理之增删改

#### 第12章：MySQL数据类型精讲

#### 第13章：约束

### 4. 其它数据库对象篇

#### 第14章：视图

#### 第15章：存储过程与函数

#### 第16章：变量、流程控制与游标

#### 第17章：触发器


### 5. MySQL8 新特性篇

#### 第18章：MySQL8其它新特性


## 二、MySQL高级特性篇

### 1. MySQL架构篇

#### 第01章：Linux下MySQL的安装与使用

#### 第02章：MySQL的数据目录

#### 第03章：用户与权限管理

#### 第04章：逻辑架构

#### 第05章：存储引擎

#### 第06章：InnoDB数据页结构

### 2. 索引及调优篇
#### 第07章：索引

#### 第08章：性能分析工具的使用

#### 第09章：索引优化与SQL优化

#### 第10章：数据库的设计规范

#### 第11章：数据库其他调优策略
### 3. 事务篇

#### 第12章：事务基础知识

#### 第13章：MySQL事务日志
#### 第14章：锁

#### 第15章：多版本并发控制(MVCC)

### 4. 日志与备份篇

#### 第16章：其它数据库日志

#### 第17章：主从复制

#### 第18章：数据库备份与恢复