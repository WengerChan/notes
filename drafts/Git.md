# Git

## 删除历史commit

操作方法: 首先创建一个新分支 `newBranch`, 然后将 `master` 分支删除, 再将当前分支 `newBranch` 重命名为 `master`, 再强制push到远程仓库即可。

具体操作流程如下: 

* 创建新分支: 

    ```sh
    git checkout --orphan newBranch
    ```

* 添加所有文件: 

    ```sh
    git add -A
    ```

* 提交更改: 

    ```sh
    git commit -am "message"
    ```

* 删除主分支: 

    ```sh
    git branch -D master
    ```

* 重命名当前分支: 

    ```sh
    git branch -m master
    ```

* 强制提交: 

    ```sh
    git push -f origin master
    ```
