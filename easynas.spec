Name:           easynas
Version:        1.99
Release:        1
# NOTE on addon versioning: each addon subpackage below carries its OWN
# Release. The CI workflow only auto-bumps the base easynas Release (the first
# Release: line above), so addons keep a stable NEVRA across builds and don't
# show up as spurious updates. To publish an update for a SINGLE addon, bump
# just that subpackage's "Release:" line (e.g. fs-samba 1 -> 2); leave the
# others untouched.
Summary:        Network Attached Storage
License:        GPL-3.0
Group:          System Environment/Daemons
URL:            https://www.easynas.org
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz

Requires:       perl
Requires:       perl-Mojolicious
Requires:       perl-XML-LibXML
Requires:       perl-IO-Socket-SSL
Requires:       btrfsprogs
Requires:       cron
Requires:       hdparm
Requires:       smartmontools
Requires:       net-snmp
Requires:       openssl
Requires:       sudo
Requires:       tar
Requires:       rsync
Requires:       NetworkManager
Requires:       dmidecode

%description
EasyNAS is a Network Attached Storage Server.

%prep
%setup -q

%install
mkdir -p %{buildroot}/easynas
mkdir -p %{buildroot}/etc/easynas/addons
mkdir -p %{buildroot}/etc/cron.d
mkdir -p %{buildroot}/etc/sudoers.d
mkdir -p %{buildroot}/var/log/easynas
mkdir -p %{buildroot}/usr/lib/systemd/system

cp -a addons lib templates public script startup lang t %{buildroot}/easynas/
cp easy_n_a_s.yml %{buildroot}/easynas/

cat > %{buildroot}/etc/sudoers.d/easynas << 'EOF'
easynas ALL = NOPASSWD: ALL
EOF
chmod 440 %{buildroot}/etc/sudoers.d/easynas

# /etc/cron.d/easynas.cron is no longer shipped in the image; it is seeded on
# the writable config layer by the firstboot service (see startup/firstboot.sh)
# because the app rewrites it at runtime.

echo "en-en" > %{buildroot}/etc/easynas/easynas.lang

cat > %{buildroot}/etc/easynas/addons/easynas.addons << 'EOF'
<?xml version='1.0'?>
<stream>
<search-result version="0.0">
<solvable-list>
<solvable status="installed" name="easynas" summary="Network Attached Storage" kind="package"/>
<solvable status="not-installed" name="easynas-fs-ftp" summary="FTP addon for EasyNAS" kind="package"/>
<solvable status="not-installed" name="easynas-fs-nfs" summary="NFS addon for EasyNAS" kind="package"/>
<solvable status="not-installed" name="easynas-fs-rsyncd" summary="RSyncd addon for EasyNAS" kind="package"/>
<solvable status="not-installed" name="easynas-fs-samba" summary="SAMBA addon for EasyNAS" kind="package"/>
<solvable status="not-installed" name="easynas-fs-ssh" summary="SSH addon for EasyNAS" kind="package"/>
<solvable status="not-installed" name="easynas-fs-tftp" summary="TFTP addon for EasyNAS" kind="package"/>
<solvable status="not-installed" name="easynas-lang-chinese" summary="Simplified Chinese Language for EasyNAS" kind="package"/>
<solvable status="not-installed" name="easynas-lang-german" summary="German Language for EasyNAS" kind="package"/>
<solvable status="not-installed" name="easynas-lang-polish" summary="Polish Language for EasyNAS" kind="package"/>
<solvable status="not-installed" name="easynas-lang-portuguese" summary="Portuguese Language for EasyNAS" kind="package"/>
<solvable status="not-installed" name="easynas-mm-dlna" summary="DLNA addon for EasyNAS" kind="package"/>
<solvable status="not-installed" name="easynas-mm-plex" summary="PLEX addon for EasyNAS" kind="package"/>
<solvable status="not-installed" name="easynas-srv-lxc" summary="Virtualization addon for EasyNAS" kind="package"/>
<solvable status="not-installed" name="easynas-srv-mariadb" summary="MariaDB addon for EasyNAS" kind="package"/>
<solvable status="not-installed" name="easynas-srv-radius" summary="Radius addon for EasyNAS" kind="package"/>
<solvable status="not-installed" name="easynas-stg-iscsi" summary="iSCSI Initiator addon for EasyNAS" kind="package"/>
</solvable-list>
</search-result>
</stream>
EOF

# The channel repo (EasyNAS or EasyNAS_Beta) is NOT shipped by this RPM. It is
# baked into the image by KIWI (imageinclude), one channel per image, so an RPM
# update never resets which channel the appliance updates from.

cat > %{buildroot}/usr/lib/systemd/system/easynas.service << 'EOF'
[Unit]
Description=EasyNAS application
After=network.target

[Service]
Type=simple
User=easynas
Environment=EASYNAS_PORT=1443
EnvironmentFile=-/etc/easynas/easynas.conf
ExecStart=/easynas/script/easy_nas daemon -m production -l https://*:${EASYNAS_PORT}?cert=/etc/easynas/easynas.cert&key=/etc/easynas/easynas.key

[Install]
WantedBy=multi-user.target
EOF

cat > %{buildroot}/usr/lib/systemd/system/easynas-firstboot.service << 'EOF'
[Unit]
Description=EasyNAS first-boot config seeding
After=local-fs.target
Before=easynas.service

[Service]
Type=oneshot
ExecStart=/easynas/startup/firstboot.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# The console (getty@tty1 autologin -> easynas.sh) runs the EasyNAS menu and the
# first-boot admin-password prompt. It must start AFTER easynas-firstboot has
# mounted the config partition over /etc/easynas, or the prompt writes
# admin.conf to the OS layer and the mount then shadows it.
mkdir -p %{buildroot}/usr/lib/systemd/system/getty@tty1.service.d
cat > %{buildroot}/usr/lib/systemd/system/getty@tty1.service.d/easynas-firstboot.conf << 'EOF'
[Unit]
After=easynas-firstboot.service
Wants=easynas-firstboot.service
EOF

# Persistent settings file (config layer). Seeded only if absent so an
# upgrade never overwrites a user-chosen port; see %post.
echo "EASYNAS_PORT=1443" > %{buildroot}/etc/easynas/easynas.conf

touch %{buildroot}/var/log/easynas/easynas.log

# ImageVersion identifies the OS build and is read from /etc/ImageVersion by
# easynas.pm; it lives on the image (updates with the OS), not the config layer.
mkdir -p %{buildroot}/etc
echo "EasyNAS-%{version}-%{release}" > %{buildroot}/etc/ImageVersion

# SSH subpackage files.
# sshd_config is a static addon file and lives on the OS image under
# /easynas/conf, NOT /etc/easynas -- the config partition mounts over
# /etc/easynas and would otherwise shadow it (see docs/immutable-design.md 8.2).
mkdir -p %{buildroot}/easynas/conf
cat > %{buildroot}/easynas/conf/sshd_config << 'EOF'
AuthorizedKeysFile	.ssh/authorized_keys
UsePAM yes
X11Forwarding yes
Subsystem	sftp	/usr/lib/ssh/sftp-server
AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL
EOF

cat > %{buildroot}/usr/lib/systemd/system/easynas-sshd.service << 'EOF'
[Unit]
Description=OpenSSH Daemon
After=network.target

[Service]
Type=notify
EnvironmentFile=-/etc/sysconfig/ssh
ExecStartPre=/usr/sbin/sshd-gen-keys-start
ExecStartPre=/usr/sbin/sshd -t $SSHD_OPTS
ExecStart=/usr/sbin/sshd -f /easynas/conf/sshd_config  -D $SSHD_OPTS
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=always
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOF

# EasyNAS FreeRADIUS unit: the distro's radiusd pointed at the writable config
# tree seeded under /etc/easynas/raddb by the srv-radius %post (the read-only
# system /etc/raddb can't hold runtime client edits). Derived verbatim from the
# stock radiusd.service -- only the -d config dir differs.
cat > %{buildroot}/usr/lib/systemd/system/easynas-radiusd.service << 'EOF'
[Unit]
Description=EasyNAS FreeRADIUS server
After=syslog.target network.target

[Service]
Type=forking
PIDFile=/run/radiusd/radiusd.pid
ExecStartPre=-/bin/chown -R radiusd:radiusd /run/radiusd /var/log/radius
ExecStartPre=/usr/sbin/radiusd -C -d /etc/easynas/raddb
ExecStart=/usr/sbin/radiusd -d /etc/easynas/raddb
ExecReload=/usr/sbin/radiusd -C -d /etc/easynas/raddb
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF

# EasyNAS rsync daemon: the distro rsync in daemon mode, reading the addon's
# config on the writable config partition. rsyncd needs only a single conf file
# (no config tree), seeded by the fs-rsyncd %post.
cat > %{buildroot}/usr/lib/systemd/system/easynas-rsyncd.service << 'EOF'
[Unit]
Description=EasyNAS rsync daemon
After=network.target

[Service]
ExecStart=/usr/bin/rsync --daemon --no-detach --config=/etc/easynas/rsyncd/rsyncd.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF


%files
%config(noreplace) /etc/easynas/easynas.lang
%config(noreplace) /etc/easynas/easynas.conf
%config(noreplace) /etc/easynas/addons/easynas.addons
%config(noreplace) /var/log/easynas/easynas.log
/etc/sudoers.d/easynas
/etc/ImageVersion
/usr/lib/systemd/system/easynas.service
/usr/lib/systemd/system/easynas-firstboot.service
/usr/lib/systemd/system/getty@tty1.service.d/easynas-firstboot.conf
/easynas/easy_n_a_s.yml
/easynas/script
/easynas/public
/easynas/t
/easynas/addons/dashboard.easynas
/easynas/addons/addons.easynas
/easynas/addons/backup.easynas
/easynas/addons/disk.easynas
/easynas/addons/filesystem.easynas
/easynas/addons/groups.easynas
/easynas/addons/network.easynas
/easynas/addons/profile.easynas
/easynas/addons/scheduler.easynas
/easynas/addons/users.easynas
/easynas/addons/volume.easynas
/easynas/addons/sync.easynas
/easynas/addons/firmware.easynas
/easynas/addons/power.easynas
/easynas/addons/logs.easynas
/easynas/addons/settings.easynas
/easynas/addons/computers.easynas
/easynas/addons/realm.easynas
/easynas/lib/EasyNAS.pm
/easynas/lib/EasyNAS/Controller/disk.pm
/easynas/lib/EasyNAS/Controller/easynas.pm
/easynas/lib/EasyNAS/Controller/filesystem.pm
/easynas/lib/EasyNAS/Controller/volume.pm
/easynas/lib/EasyNAS/Controller/dashboard.pm
/easynas/lib/EasyNAS/Controller/logs.pm
/easynas/lib/EasyNAS/Controller/login.pm
/easynas/lib/EasyNAS/Controller/addons.pm
/easynas/lib/EasyNAS/Controller/users.pm
/easynas/lib/EasyNAS/Controller/groups.pm
/easynas/lib/EasyNAS/Controller/realm.pm
/easynas/lib/EasyNAS/Controller/firmware.pm
/easynas/lib/EasyNAS/Controller/network.pm
/easynas/lib/EasyNAS/Controller/settings.pm
/easynas/lib/EasyNAS/Controller/power.pm
/easynas/lib/EasyNAS/Controller/language.pm
/easynas/templates/layouts
/easynas/templates/easynas/disk*
/easynas/templates/easynas/filesystem*
/easynas/templates/easynas/volume*
/easynas/templates/easynas/dashboard*
/easynas/templates/easynas/logs.html.ep
/easynas/templates/easynas/settings*
/easynas/templates/easynas/addons*
/easynas/templates/easynas/users*
/easynas/templates/easynas/groups*
/easynas/templates/easynas/realm*
/easynas/templates/easynas/network*
/easynas/templates/easynas/firmware*
/easynas/templates/easynas/login*
/easynas/templates/easynas/power*
/easynas/startup
/easynas/lang/en-en/iso.txt
/easynas/lang/en-en/lang_english_easynas.pl


%pre
/usr/bin/getent group easynas || /usr/sbin/groupadd -r easynas
# easynas is the single system user: it runs the service AND the console (the
# getty autologs in as easynas and runs the menu as its login shell). Give it
# the menu as its shell; keep it set on upgrades of an existing easynas user.
/usr/bin/getent passwd easynas || /usr/sbin/useradd -r -g easynas -d /easynas -s /easynas/startup/easynas.sh easynas
/usr/sbin/usermod -s /easynas/startup/easynas.sh easynas 2>/dev/null || true


%post
systemctl enable easynas.service easynas-firstboot.service

# On a live system, seed the config layer (cert, port, cron) and restart now.
# During an image build there is no running systemd, so this is skipped and the
# enabled firstboot service seeds at the first real boot instead -- which keeps
# the SSL cert out of the image so every appliance gets its own (conflict #3).
if [ -d /run/systemd/system ]; then
    /easynas/startup/firstboot.sh
    systemctl daemon-reload
    systemctl restart easynas.service
fi


%postun


%clean


#### lxc ####
%package        srv-lxc
Version:        %{version}
Release:        4
Summary:        Virtualization addon for EasyNAS
Group:          easynas/addon
Requires:       easynas >= %{version}
Requires:       lxc
Requires:       ttyd
Requires:       libwebsockets-devel

%description srv-lxc
Virtualization addon for EasyNAS

%files srv-lxc
/easynas/addons/lxc.easynas
/easynas/lib/EasyNAS/Controller/lxc.pm
/easynas/lang/en-en/lang_english_lxc.pl
/easynas/templates/easynas/lxc.html.ep
/easynas/templates/easynas/lxc_create.html.ep


#### mariadb ####
%package        srv-mariadb
Version:        %{version}
Release:        4
Summary:        MariaDB addon for EasyNAS
Group:          easynas/addon
Requires:       easynas >= %{version}
Requires:       mariadb
Requires:       mariadb-client

%description srv-mariadb
MariaDB addon for EasyNAS

%files srv-mariadb
/easynas/addons/mariadb.easynas
/easynas/lib/EasyNAS/Controller/mariadb.pm
/easynas/templates/easynas/mariadb.html.ep
/easynas/lang/en-en/lang_english_mariadb.pl


##### TFTP #####
%package        fs-tftp
Version:        %{version}
Release:        4
Summary:        TFTP addon for EasyNAS
Group:          easynas/addon
Requires:       easynas >= %{version}
Requires:       tftp

%description fs-tftp
TFTP addon for EasyNAS

%files fs-tftp
/easynas/addons/tftp.easynas
/easynas/lib/EasyNAS/Controller/tftp.pm
/easynas/templates/easynas/tftp.html.ep
/easynas/lang/en-en/lang_english_tftp.pl
/easynas/lang/de-de/lang_german_tftp.pl
/easynas/lang/pt-br/lang_brazilian_portuguese_tftp.pl
/easynas/lang/zh-cn/lang_chinese_tftp.pl
/easynas/lang/pl-pl/lang_polish_tftp.pl


##### FTP ####
%package        fs-ftp
Version:        %{version}
Release:        4
Summary:        FTP addon for EasyNAS
Group:          easynas/addon
Requires:       easynas >= %{version}
Requires:       pureftpd

%description fs-ftp
FTP addon for EasyNAS

%files fs-ftp
/easynas/addons/ftp.easynas
/easynas/lib/EasyNAS/Controller/ftp.pm
/easynas/templates/easynas/ftp.html.ep
/easynas/lang/en-en/lang_english_ftp.pl
/easynas/lang/de-de/lang_german_ftp.pl
/easynas/lang/pt-br/lang_brazilian_portuguese_ftp.pl
/easynas/lang/zh-cn/lang_chinese_ftp.pl
/easynas/lang/pl-pl/lang_polish_ftp.pl


##### NFS ####
%package        fs-nfs
Version:        %{version}
Release:        4
Summary:        NFS addon for EasyNAS
Group:          easynas/addon
Requires:       easynas >= %{version}
Requires:       nfs-kernel-server

%description fs-nfs
NFS addon for EasyNAS

%files fs-nfs
/easynas/addons/nfs.easynas
/easynas/lib/EasyNAS/Controller/nfs.pm
/easynas/templates/easynas/nfs.html.ep
/easynas/templates/easynas/nfs_create.html.ep
/easynas/lang/en-en/lang_english_nfs.pl
/easynas/lang/de-de/lang_german_nfs.pl
/easynas/lang/pt-br/lang_brazilian_portuguese_nfs.pl
/easynas/lang/zh-cn/lang_chinese_nfs.pl
/easynas/lang/pl-pl/lang_polish_nfs.pl


##### SAMBA ####
%package        fs-samba
Version:        %{version}
Release:        4
Summary:        SAMBA addon for EasyNAS
Group:          easynas/addon
Requires:       easynas >= %{version}
Requires:       samba
Requires:       samba-winbind
Requires:       rpcbind

%description fs-samba
SAMBA addon for EasyNAS

%files fs-samba
/easynas/addons/samba.easynas
/easynas/lib/EasyNAS/Controller/samba.pm
/easynas/templates/easynas/samba*
/easynas/lang/en-en/lang_english_samba.pl
/easynas/lang/de-de/lang_german_samba.pl
/easynas/lang/pt-br/lang_brazilian_portuguese_samba.pl
/easynas/lang/zh-cn/lang_chinese_samba.pl
/easynas/lang/pl-pl/lang_polish_samba.pl


##### SSH ####
%package        fs-ssh
Version:        %{version}
Release:        3
Summary:        SSH addon for EasyNAS
Group:          easynas/addon
Requires:       easynas >= %{version}
Requires:       openssh

%description fs-ssh
SSH addon for EasyNAS

%files fs-ssh
/easynas/addons/ssh.easynas
/easynas/lib/EasyNAS/Controller/ssh.pm
/easynas/templates/easynas/ssh*
/easynas/lang/en-en/lang_english_ssh.pl
/easynas/conf/sshd_config
/usr/lib/systemd/system/easynas-sshd.service


#### DLNA ####
%package        mm-dlna
Version:        %{version}
Release:        4
Summary:        DLNA addon for EasyNAS
Group:          easynas/addon
Requires:       easynas >= %{version}
Requires:       minidlna
Requires:       ffmpeg

%description mm-dlna
DLNA addon for EasyNAS

%files mm-dlna
/easynas/addons/dlna.easynas
/easynas/lib/EasyNAS/Controller/dlna.pm
/easynas/templates/easynas/dlna.html.ep
/easynas/lang/en-en/lang_english_dlna.pl
/easynas/lang/de-de/lang_german_dlna.pl
/easynas/lang/pt-br/lang_brazilian_portuguese_dlna.pl
/easynas/lang/zh-cn/lang_chinese_dlna.pl
/easynas/lang/pl-pl/lang_polish_dlna.pl


#### Plex ####
%package        mm-plex
Version:        %{version}
Release:        4
Summary:        PLEX addon for EasyNAS
Group:          easynas/addon
Requires:       easynas >= %{version}
Requires:       plexmediaserver

%description mm-plex
Plex Server addon for EasyNAS

%files mm-plex
/easynas/addons/plex.easynas
/easynas/lib/EasyNAS/Controller/plex.pm
/easynas/templates/easynas/plex.html.ep
/easynas/lang/en-en/lang_english_plex.pl
/easynas/lang/pl-pl/lang_polish_plex.pl


#### RSync ####
%package        fs-rsyncd
Version:        %{version}
Release:        6
Summary:        RSyncd addon for EasyNAS
Group:          easynas/addon
Requires:       easynas >= %{version}
Requires:       rsync

%description fs-rsyncd
RSyncd addon for EasyNAS

%files fs-rsyncd
/easynas/addons/rsyncd.easynas
/easynas/lib/EasyNAS/Controller/rsyncd.pm
/easynas/templates/easynas/rsyncd.html.ep
/easynas/templates/easynas/rsyncd_create.html.ep
/usr/lib/systemd/system/easynas-rsyncd.service
/easynas/lang/en-en/lang_english_rsync.pl
/easynas/lang/de-de/lang_german_rsync.pl
/easynas/lang/pt-br/lang_brazilian_portuguese_rsync.pl
/easynas/lang/zh-cn/lang_chinese_rsync.pl
/easynas/lang/pl-pl/lang_polish_rsync.pl

%post fs-rsyncd
# Seed the addon's rsync config on first install. The rsyncd controller only
# appends module sections to this file, so it must already exist with sane
# globals. Never clobber an existing config so shares survive upgrades.
mkdir -p /etc/easynas/rsyncd
if [ ! -e /etc/easynas/rsyncd/rsyncd.conf ] ; then
  cat > /etc/easynas/rsyncd/rsyncd.conf << 'RSCONF'
# EasyNAS rsync daemon config. Module sections are appended below by the
# RSyncd add-on page; edit globals here.
pid file = /run/easynas-rsyncd.pid
use chroot = yes
max connections = 10
secrets file = /etc/easynas/rsyncd/rsyncd.secrets
RSCONF
fi
[ -e /etc/easynas/rsyncd/rsyncd.secrets ] || : > /etc/easynas/rsyncd/rsyncd.secrets
chmod 600 /etc/easynas/rsyncd/rsyncd.secrets
/usr/bin/systemctl daemon-reload 2>/dev/null || true

%preun fs-rsyncd
# On final removal (not upgrade) stop and disable the service so no unit lingers
# after its file is gone. The seeded config is left on the config partition.
if [ "$1" = 0 ] ; then
  /usr/bin/systemctl disable --now easynas-rsyncd.service 2>/dev/null || true
fi


#### Radius ####
%package        srv-radius
Version:        %{version}
Release:        6
Summary:        Radius addon for EasyNAS
Group:          easynas/addon
Requires:       easynas >= %{version}
Requires:       freeradius-server

%description srv-radius
Radius addon for EasyNAS

%files srv-radius
/easynas/addons/radius.easynas
/easynas/lib/EasyNAS/Controller/radius.pm
/easynas/templates/easynas/radius.html.ep
/easynas/templates/easynas/radius_create.html.ep
/usr/lib/systemd/system/easynas-radiusd.service
/easynas/lang/en-en/lang_english_radius.pl
/easynas/lang/de-de/lang_german_radius.pl
/easynas/lang/pt-br/lang_brazilian_portuguese_radius.pl
/easynas/lang/zh-cn/lang_chinese_radius.pl
/easynas/lang/pl-pl/lang_polish_radius.pl

%post srv-radius
# Seed the writable RADIUS config from the distro's stock tree on first install
# (freeradius-server is a hard dep, so /etc/raddb exists here). radiusd needs
# its whole config tree -- not just radiusd.conf/clients.conf -- so copy it
# wholesale, preserving the mods-enabled/sites-enabled symlinks and the
# root:radiusd ownership the daemon expects. Never clobber an existing tree, so
# client edits survive upgrades.
if [ ! -e /etc/easynas/raddb/radiusd.conf ] && [ -d /etc/raddb ] ; then
  cp -a /etc/raddb /etc/easynas/raddb
fi
/usr/bin/systemctl daemon-reload 2>/dev/null || true

%preun srv-radius
# On final removal (not upgrade) stop and disable the service so no unit lingers
# after its file is gone. The seeded /etc/easynas/raddb is left in place (config
# partition) so a reinstall keeps existing clients.
if [ "$1" = 0 ] ; then
  /usr/bin/systemctl disable --now easynas-radiusd.service 2>/dev/null || true
fi


#### iSCSI ####
%package        stg-iscsi
Version:        %{version}
Release:        4
Summary:        iSCSI Initiator addon for EasyNAS
Group:          easynas/addon
Requires:       easynas >= %{version}
Requires:       tgt

%description stg-iscsi
iSCSI addon for EasyNAS

%files stg-iscsi
/easynas/addons/iscsi.easynas
/easynas/lib/EasyNAS/Controller/iscsi.pm
/easynas/templates/easynas/iscsi.html.ep
/easynas/templates/easynas/iscsi_create.html.ep
/easynas/lang/en-en/lang_english_iscsi.pl
/easynas/lang/pl-pl/lang_polish_iscsi.pl


##### German Language ####
%package        lang-german
Version:        %{version}
Release:        3
Summary:        German Language for EasyNAS
Group:          easynas/lang
Requires:       easynas >= %{version}

%description lang-german
German Language for EasyNAS

%files lang-german
/easynas/lang/de-de/iso.txt
/easynas/lang/de-de/lang_german_easynas.pl


##### Portuguese Language ####
%package        lang-portuguese
Version:        %{version}
Release:        3
Summary:        Portuguese Language for EasyNAS
Group:          easynas/lang
Requires:       easynas >= %{version}

%description lang-portuguese
Portuguese Language for EasyNAS

%files lang-portuguese
/easynas/lang/pt-br/iso.txt
/easynas/lang/pt-br/lang_brazilian_portuguese_easynas.pl


##### Chinese Language ####
%package        lang-chinese
Version:        %{version}
Release:        3
Summary:        Simplified Chinese Language for EasyNAS
Group:          easynas/lang
Requires:       easynas >= %{version}

%description lang-chinese
Simplified Chinese Language for EasyNAS

%files lang-chinese
/easynas/lang/zh-cn/iso.txt
/easynas/lang/zh-cn/lang_chinese_easynas.pl


##### Polish Language ####
%package        lang-polish
Version:        %{version}
Release:        3
Summary:        Polish Language for EasyNAS
Group:          easynas/lang
Requires:       easynas >= %{version}

%description lang-polish
Polish Language for EasyNAS

%files lang-polish
/easynas/lang/pl-pl/iso.txt
/easynas/lang/pl-pl/lang_polish_easynas.pl


%changelog
* Tue Jul 21 2026 Yariv Hakim
  - Add-ons: serialize install/update through a FIFO click-order queue;
    per-tile waiting/installing badges advance as the worker drains
  - Add-ons: "Check for updates" button refreshes the channel metadata and
    recomputes the pending-update list on demand
  - UI speed: cache the addon-catalog parse (mtime-keyed) so it isn't re-parsed
    several times per render; count updates and read the lang code natively
    instead of forking grep/wc/cat each request; drop dead IE8 CDN shims and a
    stray debug print
  - Add-ons: mark x86_64-only add-ons (Plex) "Not available on ARM" on aarch64
    instead of offering an Install button that always fails (Plex ships no ARM
    RPM upstream)
  - Radius add-on: ship the easynas-radiusd.service unit and seed /etc/easynas/
    raddb from the stock freeradius config on install -- the unit and config the
    addon drives were never packaged, so it installed but could not start
  - LXC add-on: enable it in the descriptor so it appears in the sidebar Services
    menu after install (it shipped with enable=false, which get_menu hides)
  - Add-ons: restart the web service after the install queue drains, so a newly
    installed addon's route is registered and its menu link works without a
    manual restart (routes are built once at startup)
  - RSyncd add-on: ship the easynas-rsyncd.service unit and seed
    /etc/easynas/rsyncd/rsyncd.conf on install (same missing-unit gap as radius)
  - Retire the AFP add-on: netatalk was dropped from openSUSE Tumbleweed (AFP is
    deprecated; use Samba/SMB for Mac clients), so easynas-fs-afp could never
    resolve its dependency. Remove the subpackage and all AFP files.
  - Filesystem list: show zstd ("Optimized") compression correctly -- the legacy
    status reader only knew zlib/lzo, so zstd displayed as "None"; it now reads
    /proc/mounts natively and the list shows the same translated labels as the
    settings page
  - Add-ons grid: list easynas-srv-lxc and easynas-srv-mariadb in the seeded
    catalog so they appear without waiting for an update-check refresh
  - MariaDB add-on: build it out (was a stub) -- controller with on/off + version
    display, on/off template, enable it in the menu, and Requires: mariadb +
    mariadb-client so the DB server is actually pulled in
  - MariaDB add-on: manage databases (list/create/delete) and set the root
    password from the UI -- all via the local unix socket as root, with SQL fed
    on stdin (never the command line), name whitelisting, and delete confirmation
  - AD-DC realm: pick a reachable DNS forwarder -- prefer the DHCP-provided
    resolver (then the gateway) over the hardcoded 1.1.1.1, which is blocked on
    many networks and left a freshly provisioned DC unable to resolve anything
  - Add-ons grid: lay tiles out with flexbox and a larger bottom margin so a
    category spanning more than one line spaces its rows evenly
  - MariaDB add-on: choose which volume stores the database. Data is bind-mounted
    onto /var/lib/mysql (datadir unchanged, so AppArmor/config are untouched),
    existing data is migrated, and the bind is persisted + ordered so the DB
    survives firmware updates. A "Storage" tab picks the volume or reverts to
    internal.
* Fri Jun 26 2026 Yariv Hakim
  - Restructure repo, add CI build via GitHub Actions
* Wed Apr 10 2024 Yariv
  - First Release (R1)
