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


### Parameters of smb.conf

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

* Using smbclient in Scripting Mode (with `-c`)

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
