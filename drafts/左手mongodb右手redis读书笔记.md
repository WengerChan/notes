# 左手mongodb 右手redis

* MongoDB

库--集合--文档
库--表--行--列

* Redis

缓存: 哈希表, 字符串
队列: 列表, 有序集合, 哈希表
去重: 集合(小批量), 字符串(位操作, 大规模), HypeLogLog(大规模, 计数)
积分板: 有序集合
发布/订阅功能


* 爬虫开发中, MongoDB主要用来写数据, Redis主要用来缓存网址;
* 数据分析中, MongoDB的聚合操作用得比较多;
* 后端开发中, 主要用到MongoDB的增, 删, 改, 查功能, Redis用来做缓存;
* 游戏开发中, Redis可以用来做排名功能.

## Redis 有序集合（sorted set）

数据和集合一样, 也是不能重复的；
但是每一个元素又关联了一个分数(Score), 这个分数可以重复, 可用来排序。


* 1.添加数据

```
zadd('有序集合名', 值1, 评分1, 值2, 评分2, ..., 值n, 评分n) # 值和评分都可以使用变量
zadd('有序集合名', 值1=评分1, 值2=评分2, ..., 值n=评分n)    # 值不能使用变量, 评分可以使用变量
```

* 2.修改评分

```
zincrby('有序集合名', 值, 改变量)
```

e.g.
 
```
zincrby('age_set', 'xiaoming', 0.5)   # 加0.5岁
zincrby('age_set', 'xiaohong', -0.5)  # 减0.5岁
```

* 3.基于评分范围排序

```
zrangebyscore    # 从小到大排序
zrevrangebyscore # 从大到小排序

zrangebyscore('有序集合名', 评分上限, 评分下限, 结果切片起始位置, 结果数量, withscores=False)
zrevrangebyscore('有序集合名', 评分上限, 评分下限, 结果切片起始位置, 结果数量, withscores=False)

# withscores 设置为False时, 返回的结果是直接排序好的值
             设置为True时, 返回的列表中的元素是元组, 元组中第一个元素是值, 第二个元素是评分
# 在rediscli中: zrangebyscore 有序集合名 评分下限 评分上限 withscores limit 结果切片起始位置 结果数量
```

e.g.

```python
import redis

client = redis.Redis()

rank_100_1000 = client.zrevrangebyscore('rank', 100, 10, 0, 3, withscores=True) # 10-100分之间, 取分数前3的
for index, one in enumerate(rank_100_1000):
    print(f'用户ID: {one[0].decode()}, 积分: {one[1]}, 排名第: {index + 1}')
```


* 4.对有序集合基于位置排序(取指定范围内的值)

```
zrange    # 从小到大排序
zrevrange # 从大到小排序

zrange('有序集合名', 开始位置(含), 结束位置(含), desc=False, withscore=False) # desc=True时, 等同于zrevrange
zrevrange('有序集合名', 开始位置(含), 结束位置(含), withscore=False)
```

* 5.根据值查询排名, 根据值查询评分

```
zrank('有序集合名', '值')     # 值不存在时返回None; 排名从0开始, 评分越小排名越接近0
zrevrank('有序集合名', '值')  # 值不存在时返回None; 排名从0开始, 评分越大排名越接近0
zscore('有序集合名', '值')    # 值不存在时返回None; 查询一个值的评分
```

* 6.其他常用方法

```
zcard('有序集合名')                      # 统计有序集合中一共有多少值; 该集合不存在时,返回0
zcount('有序集合名', 评分下限, 评分上限) # 统计某个评分范围内的值有多少个
```


## Redis安全管理

* 设置密码并开放外网访问

`redis.conf` 配置文件中: 

```sh
requirepass foobared    # 修改密码
bind 127.0.0.1 ::1      # 修改绑定的IP
port 6378               # 修改端口
```

* 禁用危险命令

```sh
rename-command CONFIG ""
rename-command FLUSHDB dfadfasgsg
rename-command FLUSHALL IWERDF
rename-command PEXPIRE OKOSSF
rename-command SHUTDOWN ""
rename-command BGREWRITEAOF SFASFFF
rename-command BGSAVE FFAFS
rename-command SAVE SFDSFF
rename-command DEBUG ""

```

## ?

```
{'$lookup': {
 'from': 'answer',
 'localField': '_id',
 'foreignField': 'question_id',
 'as': 'answer_list'}
}
```




