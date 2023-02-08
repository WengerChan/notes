# Samba

> Samba in RHEL 7

## Services

* smbd
  
  This service provides file sharing and printing services using the SMB protocol.

  Additionally, the service is responsible for resource locking and for authenticating connecting users. The `smb systemd` service starts and stops the smbd daemon.
  
  To use the `smbd` service, install the **samba** package.

* nmbd
  
  This service provides host name and IP resolution using the NetBIOS over IPv4 protocol.

  Additionally to the name resolution, the nmbd service enables browsing the SMB network to locate domains, work groups, hosts, file shares, and printers.The `nmb systemd` service starts and stops the nmbd daemon. (*Note that modern SMB networks use DNS to resolve clients and IP addresses.*)

  To use the `nmbd` service, install the **samba** package.

* winbindd

  The `winbindd` service provides an interface for the Name Service Switch (NSS) to use AD or NT4 domain users and groups on the local system. The `winbind systemd` service starts and stops the winbindd daemon.

  If you set up Samba as a domain member, `winbindd` must be started before the `smbd` service. Otherwise, domain users and groups are not available to the local system.

  To use the `winbindd` service, install the **samba-winbin**d package.

## Configure Samba

* Verifying the `smb.conf` File by Using the `testparm` Utility

  The `testparm` utility verifies that the Samba configuration in the `/etc/samba/smb.conf` file is correct. The utility detects invalid parameters and values, but also incorrect settings, such as for ID mapping.

   * If `testparm` reports no problem, the Samba services will successfully load the /`etc/samba/smb.conf` file. 
   * Note that `testparm` cannot verify that the configured services will be available or work as expected.

* Security Modes

  The `security` parameter in the `[global]` section in the `/etc/samba/smb.conf `file manages how Samba authenticates users that are connecting to the service. Depending on the mode you install Samba in, the parameter must be set to different values:

  * On an AD domain member, set `security = ads`.

    In this mode, Samba uses Kerberos to authenticate AD users.

  * On a standalone server, set `security = user`.

    In this mode, Samba uses a local database to authenticate connecting users.

  * On an NT4 PDC or BDC, set `security = user`.

    In this mode, Samba authenticates users to a local or LDAP database.

  * On an NT4 domain member, set `security = domain`.

    In this mode, Samba authenticates connecting users to an NT4 PDC or BDC. You cannot use this mode on AD domain members.

* Set up Samba as a Standalone Server

  * 1. Install the samba package:

    ```sh
    ~] yum install samba
    ```

  * 2. Edit the `/etc/samba/smb.conf` file and set the following parameters:

    ```conf
    [global]
        workgroup = Example-WG
        netbios name = Server
        security = user

        log file = /var/log/samba/%m.log
        log level = 1
    ```

    This configuration defines a standalone server named Server within the `Example-WG` work group. Additionally, this configuration enables `logging` on a minimal level (1) and `log files` will be stored in the `/var/log/samba/` directory. Samba will expand the `%m` macro in the log file parameter to the NetBIOS name of connecting clients. This enables individual log files for each client.

    For further details, see: [smb.conf](#smb.conf)

  * 3. Configure file or printer sharing. 
    
    see:
    
    * [file sharing](#file-sharing)
    * [printer sharing](#printer-sharing)

  * 4. Verify the `/etc/samba/smb.conf` file:

    ```sh
    ~] testparm
    ```

  * 5. If you set up shares that require authentication, create and enable local user accounts (For example, `example` Samba user):

    * If you use the` passdb backend = tdbsam` default setting, Samba stores user accounts in the `/var/lib/samba/private/passdb.tdb` database.

    * Create os account, then set a password: 

      ```sh
      ~] useradd -M -s /sbin/nologin example
      ~] passwd example # Samba does not use the password set on the operating system account to authenticate. 
                        # However, you need to set a password to enable the account. 
                        # If an account is disabled, Samba denies access if this user connects.
      ```

    * Add the user to the Samba database and set a password to the account:

      ```sh
      ~] smbpasswd -a example
      New SMB password: password
      Retype new SMB password: password
      Added user example.
      ```
    
    * Enable the Samba account:

      ```sh
      ~] smbpasswd -e example
      Enabled user example.
      ```

  * 6. (Optional) Open the required ports and reload the firewall configuration by using the `firewall-cmd` utility:

    ```sh
    ~] firewall-cmd --permanent --add-port={139/tcp,445/tcp}  # or "--add-service=samba"
    ~] firewall-cmd --reload
    ```

  * 7. Start the smb service:

    ```sh
    ~] systemctl start smb
    ~] systemctl enable smb # optional
    ```

* Setting up Samba as a Domain Member
  
  :

## smb.conf

### file sharing

To use Samba as a file server, add shares to the `/etc/samba/smb.conf` file of your stanadlone or domain member configuration.

You can add shares that uses either:

* POSIX ACLs.
* Fine-granular Windows ACLs

#### Setting up a Share That Uses POSIX ACLs (Not-Use acls is also OK)

To create a share named `example`, that provides the content of the `/srv/samba/example/` directory, and uses POSIX ACLs:

* Adding a Share That Uses POSIX ACLs

  * 1. Optionally, create the folder if it does not exist. For example:

    ```sh
    ~] mkdir -p /srv/samba/example/
    ```

  * 2. If you run SELinux in `enforcing` mode, set the `samba_share_t` context on the directory:

    ```sh
    ~] semanage fcontext -a -t samba_share_t "/srv/samba/example(/.*)?"
    ~] restorecon -Rv /srv/samba/example/
    ```

  * 3. Set file system ACLs on the directory. 

    * Standard Linux ACLs: `chmod`, `chown`
    * Extended ACLs: Set `inherit acls = yes` in the share’s section to enable ACL inheritance of extended ACL

  * 4. Add the example share to the `/etc/samba/smb.conf` file. For example, to add the share write-enabled:

    ```conf
    [example]
      path = /srv/samba/example/
      read only = no
    ```

    > Note: Regardless of the file system ACLs; if you do not set `read only = no`, Samba shares the directory in **read-only mode**.

  * 5. Verify the `/etc/samba/smb.conf` file:

    ```sh
    ~] testparm
    ```

  * 6. Open the required ports and reload the firewall configuration using the firewall-cmd utility:

    ```sh
    ~] firewall-cmd --permanent --add-service=samba
    ~] firewall-cmd --reload
    ```

  * 7. Restart the smb service:

    ```sh
    ~] systemctl restart smb
    ~] systemctl enable smb # optional
    ```

* Setting Permissions on a Share

  * User and Group-based Share Access

    ```conf
    valid users = greg, @pcusers 
    invalid users = root fred admin @wheel 
        # 1. A name starting with a '@' is interpreted as an NIS netgroup first (if your system supports NIS), 
        #    and then as a UNIX group if the name was not found in the NIS netgroup database.
        # 2. A name starting with '+' is interpreted only by looking in the UNIX group database via the NSS getgrnam() interface.
        # 3. A name starting with '&' is interpreted only by looking in the NIS netgroup database (this requires 
        #    NIS to be working on your system). 
        # 4. The characters '+' and '&' may be used at the start of the name in either order so the value +&group means check 
        #    the UNIX group database, followed by the NIS netgroup database, and the value &+group means check the NIS netgroup 
        #    database, followed by the UNIX group database (the same as the '@' prefix).
    ```

    The `invalid users` parameter has a higher priority than valid users parameter.


  * Host-based Share Access

    * 1. Add the following parameters to the configuration of the share in the /etc/samba/smb.conf:

      ```conf
      hosts allow = 127.0.0.1 150.203.15.0/24 150.203.15.0/255.255.255.0 lapland 150.203. EXCEPT 150.203.6.66
      hosts deny = 150.203.1. client2.example.com
      ```

    * 2. Reload the Samba configuration

      ```sh
      ~] smbcontrol all reload-config
      ```
    
    The `hosts deny` parameter has a higher priority than hosts allow.


#### Setting up a Share That Uses Windows ACLs

* Enable windows ACLs support

  Add the following settings to the `[global]` section or `[example]` section of the `/etc/samba/smb.conf file`:

  ```conf
  vfs objects = acl_xattr
  map acl inherit = yes
  store dos attributes = yes
  ```

* :

### printer sharing

[RedHat_KB: Setting Up a Samba Print Server](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/ch-file_and_print_servers#setting_up_a_samba_print_server)


### Parameters of `smb.conf`

Each section in the configuration file (except for the `[global]` section) describes a shared resource (known as a "share"). The section name is the name of the shared resource and the parameters within the section define the shares attributes.

#### Special Section

There are three special sections, `[global]`, `[homes]` and `[printers]`, which are described under special sections.

* `[global]` - parameters in this section apply to the sever as a whole, or are defaults for sections.

* `[homes]` - services connecting clients to their home directories can be created on the fly by the server.

  * The share name is changed from `homes` to the located username.

  * If no `path` was given, the `path` is set to the user's home directory.

  * If you decide to use a `path = line` in your `[homes]` section, it may be useful to use the `%S` macro. For example:

    ```conf
    path = /data/pchome/%S
    ```

    is useful if you have different home directories for your PCs than for UNIX access.

* `[printers]` - works like `[home]`, but for printers. 

#### USERSHARES

Starting with Samba version `3.0.23` the capability for **non-root users** to *add*, *modify*, and *delete* their own share definitions has been added. This capability is called `usershares` and is controlled by a set of parameters in the `[global]` section of the `smb.conf`. The relevant parameters are :

| PARAMETERS                    | MEANING                                                                                                                                                                                    |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `usershare allow guests`      | Controls if usershares can permit guest access.                                                                                                                                            |
| `usershare max shares`        | Maximum number of user defined shares allowed.                                                                                                                                             |
| `usershare owner only`        | If set only directories owned by the sharing user can be shared.                                                                                                                           |
| `usershare path`              | Points to the directory containing the user defined share definitions. The filesystem permissions on this directory control who can create user defined shares.                            |
| `usershare prefix allow list` | Comma-separated list of absolute pathnames restricting what directories can be shared. Only directories below the pathnames in this list are permitted.                                    |
| `usershare prefix deny list`  | Comma-separated list of absolute pathnames restricting what directories can be shared. Directories below the pathnames in this list are prohibited.                                        |
| `usershare template share`    | Names a pre-existing share used as a template for creating new usershares. All other share parameters not specified in the user defined share definition are copied from this named share. |

Example:

To allow members of the UNIX group `foo` to create user defined shares, create the directory to contain the share definitions as follows:

* Become root:

  ```sh
  mkdir /usr/local/samba/lib/usershares
  chgrp foo /usr/local/samba/lib/usershares
  chmod 1770 /usr/local/samba/lib/usershares
  ```

* Then add the parameters:

  ```conf
  usershare path = /usr/local/samba/lib/usershares
  usershare max shares = 10 # (or the desired number of shares)
  ```

  to the global section of your `smb.conf`. Members of the group `foo` may then manipulate the user defined shares using the following commands:

  ```sh
  # To create or modify (overwrite) a user defined share.
  net usershare add sharename path [comment] [acl] [guest_ok=[y|n]]

  # To delete a user defined share.
  net usershare delete sharename

  # To list user defined shares.
  net usershare list wildcard-sharename

  # To print information about user defined shares.
  net usershare info wildcard-sharename
  ```

#### VARIABLE SUBSTITUTIONS

<table>
<tr>
  <td>Variable</td>
  <td>Substitution</td>
</tr>
<tr>
  <td>%U</td>
  <td>session username (the username that the client wanted, not necessarily the same as the one they got). </td>
</tr>
<tr>
  <td>%G</td>
  <td>primary group name of %U. </td>
</tr>
<tr>
  <td>%h</td>
  <td>the Internet hostname that Samba is running on. </td>
</tr>
<tr>
  <td>%m</td>
  <td>the NetBIOS name of the client machine (very useful).<sup id="a1">[1]</sup></td>
</tr>
<tr>
  <td>%L</td>
  <td>the NetBIOS name of the server. This allows you to change your config based on what the client calls you. Your server can have a “dual personality”.</td>
</tr>
<tr>
  <td>%M</td>
  <td>the Internet name of the client machine.</td>
</tr>
<tr>
  <td>%R</td>
  <td>the selected protocol level after protocol negotiation. It can be one of CORE, COREPLUS, LANMAN1, LANMAN2, NT1, SMB2_02, SMB2_10, SMB3_00, SMB3_02, SMB3_11 or SMB2_FF. </td>
</tr>
<tr>
  <td>%d</td>
  <td>the process id of the current server process. </td>
</tr>
<tr>
  <td>%a</td>
  <td>The architecture of the remote machine. It currently recognizes Samba (Samba), the Linux CIFS file system (CIFSFS), OS/2, (OS2), Mac OS X (OSX), Windows for Workgroups (WfWg), Windows 9x/ME (Win95), Windows NT (WinNT), Windows 2000 (Win2K), Windows XP (WinXP), Windows XP 64-bit(WinXP64), Windows 2003 including 2003R2 (Win2K3), and Windows Vista (Vista). Anything else will be known as UNKNOWN. </td>
</tr>
<tr>
  <td>%I</td>
  <td>the IP address of the client machine. <sup id="a2">[2]</sup> </td>
</tr>
<tr>
  <td>%J</td>
  <td>the IP address of the client machine, colons/dots replaced by underscores.</td>
</tr>
<tr>
  <td>%i</td>
  <td>the local IP address to which a client connected.<sup id="a2">[2]</sup></td>
</tr>
<tr>
  <td>%j</td>
  <td>the local IP address to which a client connected, colons/dots replaced by underscores.</td>
</tr>
<tr>
  <td>%T</td>
  <td>the current date and time.</td>
</tr>
<tr>
  <td>%t</td>
  <td>the current date and time in a minimal format without colons (YYYYYmmdd_HHMMSS).</td>
</tr>
<tr>
  <td>%D</td>
  <td>name of the domain or workgroup of the current user.</td>
</tr>
<tr>
  <td>%w</td>
  <td>the winbind separator.</td>
</tr>
<tr>
  <td colspan="2">The following substitutes apply only to some configuration options (only those that are used when a connection has been established):</td>
</tr>
<tr>
  <td>%$(envvar)</td>
  <td>the value of the environment variable envar.</td>
</tr>
<tr>
  <td>%S</td>
  <td>the name of the current service, if any.<td>
</tr>
<tr>
  <td>%P</td>
  <td>the root directory of the current service, if any.<td>
</tr>
<tr>
  <td>%u</td>
  <td>username of the current service, if any.<td>
</tr>
<tr>
  <td>%g</td>
  <td>primary group name of %u. <td>
</tr>
<tr>
  <td>%H</td>
  <td>the home directory of the user given by %u. <td>
</tr>
<tr>
  <td>%N</td>
  <td>This value is the same as %L. <td>
</tr>
</table>


<b id="f1">1 This parameter is not available when Samba listens on port `445`, as clients no longer send this information. If you use this macro in an include statement on a domain that has a Samba domain controller be sure to set in the `[global]` section `smb ports = 139`. This will cause Samba to not listen on port `445` and will permit include functionality to function as it did with Samba 2.x. [?](#a1)  
<b id="f2">2 Before 4.0.0 it could contain IPv4 mapped IPv6 addresses, now it only contains IPv4 or IPv6 addresses. [?](#a2)

#### NAME MANGLING

> These options can be set separately for each service.

* `case sensitive = yes/no/auto`

  controls whether filenames are case sensitive. If they aren't, Samba must do a filename search and match on passed names. The default setting of `auto` allows clients that support case sensitive filenames (Linux CIFSVFS and smbclient 3.0.5 and above currently) to tell the Samba server on a per-packet basis that they wish to access the file system in a case-sensitive manner (to support UNIX case sensitive semantics). No Windows or DOS system supports case-sensitive filename so setting this option to `auto` is that same as setting it to no for them. Default `auto`.

* `default case = upper/lower`

  controls what the `default case` is for new filenames (*ie.* files that don't currently exist in the filesystem). Default `lower`. **IMPORTANT NOTE**: As part of the optimizations for directories containing large numbers of files, the following special case applies. If the options `case sensitive = yes`, `preserve case = No`, and `short preserve case = No` are set, then the case of all incoming client filenames, not just new filenames, will be modified. See additional notes below.

* `preserve case = yes/no`

  controls whether new files (ie. files that don't currently exist in the filesystem) are created with the case that the client passes, or if they are forced to be the `default case`. Default `yes`.

* `short preserve case = yes/no`

  controls if new files (ie. files that don't currently exist in the filesystem) which conform to *8.3 syntax*, that is all in upper case and of suitable length, are created upper case, or if they are forced to be the `default case`. This option can be used with `preserve case = yes` to permit long filenames to retain their case, while short names are lowercased. Default `yes`.

By default, Samba 3.0 has the same semantics as a Windows NT server, in that it is **case insensitive** but **case preserving**. As a special case for directories with large numbers of files, if the case options are set as follows, "`case sensitive = yes`", "`preserve case = no`", "`short preserve case = no`" then the "`default case`" option will be applied and will modify all filenames sent from the client when accessing this share.


#### EXPLANATION OF EACH PARAMETER

See [smb.conf(5)](smb.conf.txt) manual page (Start at line 574).

> Original manual page is [smb.conf(5)](smb.conf.man)

| Parameters       | Meanings                                                                        |
| ---------------- | ------------------------------------------------------------------------------- |
| `comment`        |                                                                         |
| `path`           | A directory to which the user of this service is to be given access                    |
| `browseable`     | This control whether this share is seen in the list of available shares in a net view and in the browse list.            |
| `printable`      |                                                              |
| `hide dot files` | 是yes/否no隐藏隐藏文件                                                          |
| `public`         | 是yes/否no公开共享，若为否则进行身份验证(只有当security = share 时此项才起作用) |
| `guest ok`       | 是yes/否no公开共享，若为否则进行身份验证(只有当security = share 时此项才起作用) |
| `read only`      | 是yes/否no以只读方式共享当与writable发生冲突时也writable为准                    |
| `writable`       | 是yes/否no不以只读方式共享当与read only发生冲突时，无视read only                |
| `vaild users`    | 设定只有此名单内的用户才能访问共享资源(拒绝优先)(用户名/@组名)                  |
| `invalid users`  | 设定只有此名单内的用户不能访问共享资源(拒绝优先)(用户名/@组名)                  |
| `read list`      | 设定此名单内的成员为只读(用户名/@组名)                                          |
| `write list`     | 若设定为只读时，则只有此设定的名单内的成员才可作写入动作(用户名/@组名)          |
| `create mask`    | 建立文件时所给的权限                                                            |
| `directory mask` | 建立目录时所给的权限                                                            |
| `force group`    | 指定存取资源时须以此设定的群组使用者进入才能存取(用户名/@组名)                  |
| `force user`     | 指定存取资源时须以此设定的使用者进入才能存取(用户名/@组名)                      |
| `allow hosts`    | 设定只有此网段/IP的用户才能访问共享资源                                         |
| `allwo hosts`    | 网段 except IP                                                                  |
| `deny hosts`     | 设定只有此网段/IP的用户不能访问共享资源                                         |
| `allow hosts`    | 本网段指定IP指定IP                                                              |
| `deny hosts`     | 指定IP本网段指定IP                                                              |


## Tuning the Performance of a Samba Server

### SMB Protocol Version

Each new SMB version adds features and improves the performance of the protocol. The recent Windows and Windows Server operating systems always supports the latest protocol version. If Samba also uses the latest protocol version, Windows clients connecting to Samba benefit from the performance improvements. 

In Samba, the default value of the `server max protocol` is set to the latest supported stable SMB protocol version.

To always have the latest stable SMB protocol version enabled, **do not** set the `server max protocol` parameter. If you set the parameter manually, you will need to modify the setting with each new version of the SMB protocol, to have the latest protocol version enabled.

To unset, remove the `server max protocol` parameter from the `[global]` section in the `/etc/samba/smb.conf file`.

### Shares with Directories That Contain a Large Number of Files

To improve the performance of shares that contain directories with more than 100,000 files:

* 1. Rename all files on the share to lowercase.

* 2. Set the following parameters in the share’s section:

  ```conf
  case sensitive = true
  default case = lower
  preserve case = no
  short preserve case = no
  ```

  > Using the settings in this procedure, files with names other than in lowercase will no longer be displayed.

* 3. Reload the Samba configuration:

  ```sh
  ~] smbcontrol all reload-config
  ```

After you applied these settings, the names of all newly created files on this share use lowercase. Because of these settings, Samba no longer needs to scan the directory for uppercase and lowercase, which improves the performance.

## Command-line Utilities

### smbclient

ftp-like client to access SMB/CIFS resources on servers

* Using `smbclient` in Interactive Mode (without `-c`)

  * Connect to the share:
  
    ```sh
    # smbclient <servicename> [password] [-U username]
    ~] smbclient //server_name/share_name 123qweQ -U smbuser01
    ```
  
  * Change into the /example/ directory:
  
    ```sh
    smb: \> cd /example/
    ```
  
  * List the files in the directory:
  
    ```sh
    smb: \example\> ls
     .          D     0 Mon Sep 1 10:00:00 2017
     ..          D     0 Mon Sep 1 10:00:00 2017
     example.txt     N  1048576 Mon Sep 1 10:00:00 2017
    
         9950208 blocks of size 1024. 8247144 blocks available
    ```
  
  * Download the example.txt file:
  
    ```sh
    smb: \example\> get example.txt
    getting file \directory\subdirectory\example.txt of size 1048576 as example.txt (511975,0 KiloBytes/sec) (average 170666,7 KiloBytes/sec)
    ```
  
  * Disconnect from the share:
  
    ```sh
    smb: \example\> exit
    ```

* Using `smbclient` in Scripting Mode (with `-c`)

  ```sh
  ~] smbclient //server_name/share_name 123qweQ -U smbuser01 \
    -c "cd /example/ ; get example.txt ; exit"
  ```

### smbcontrol

The `smbcontrol` utility enables you to send command messages to the `smbd`, `nmbd`, `winbindd`, or `all` of these services. These control messages instruct the service, for example, to reload its configuration.

```sh
smbcontrol all reload-config  # man smbcontrol
```

### smbpasswd

The `smbpasswd` utility manages user accounts and passwords in the local Samba database.

* Change password:

  ```sh
  smbpasswd user_name
  ```

* Create a new user:

  ```sh
  smbpasswd -a user_name
  ```

* Enable a Samba user:

  ```sh
  smbpasswd -e user_name
  ```

* Disable a Samba user:

  ```sh
  smbpasswd -x user_name
  ```

* Delete a user:

  ```sh
  smbpasswd -x user_name
  ```

### smbstatus

The `smbstatus` utility reports on:

* Connections per PID of each `smbd` daemon to the Samba server. This report includes the user name, primary group, SMB protocol version, encryption, and signing information.
* Connections per Samba share. This report includes the PID of the `smbd` daemon, the IP of the connecting machine, the time stamp when the connection was established, encryption, and signing information.
* A list of locked files. The report entries include further details, such as opportunistic lock (oplock) types

```sh
~] smbstatus

Samba version 4.6.2
PID    Username    Group        Machine                                  Protocol Version Encryption  Signing
----------------------------------------------------------------------------------------------------------------------
20678  smbuser01   smbuser01    192.168.161.2 (ipv4:192.168.161.2:57786) SMB3_02          -           AES-128-CMAC

Service pid   Machine       Connected at                Encryption  Signing
-------------------------------------------------------------------------------
data01  20678 192.168.161.2 Web Feb 1 10:00:00 2023 PST -           -
IPC$

No locked files
```

### smbtar

The `smbtar` utility backs up the content of an SMB share or a subdirectory of it and stores the content in a `tar` archive. Alternatively, you can write the content to a tape device.

For example, to back up the content of the `demo` directory on the `//server/example/` share and store the content in the `/root/example.tar` archive:

```sh
~] smbtar -s server -x example -u user_name -p password -t /root/example.tar
```

### pdbedit

Manage the SAM database (Database of Samba Users).

| Options                       | Notes |
| ----------------------------- | ----- |
| -L,--list                     |       |
| -v,--verbose                  |       |
| -u,--user <username>          |       |
| -f,--fullname <fullname>      |       |
| -h,--homedir <homedir>        |       |
| -S,--script <script>          |       |
| -p,--profile <profile>        |       |
| -c,--account-control <flag>   |       |
| -a,--create                   |       |
| -t,--password-from-stdin      |       |
| -r,--modify                   |       |
| -x,--delete                   |       |
| -i,--import <passdb>          |       |
| -e,--export <passdb>          |       |
| -g,--group                    |       |
| -z,--bad-password-count-reset |       |
