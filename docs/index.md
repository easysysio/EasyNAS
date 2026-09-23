---
title: EasyNAS, a turnkey NAS appliance you manage from the browser
hide:
  - navigation
  - toc
---

<div class="es-home">
<header class="es-band es-nav">
<div class="es-wrap es-nav-inner">
<a href="." class="es-brand">
<img src="assets/logo.svg" alt="EasyNAS" />
<span class="es-brand-name">Easy<span>NAS</span></span>
</a>
<nav class="es-nav-links" aria-label="Page sections">
<a href="#storage">Storage</a>
<a href="#sharing">Sharing</a>
<a href="#architecture">Architecture</a>
<a href="#install">Install</a>
<a href="supported-hardware/">Docs</a>
</nav>
<div class="es-nav-actions">
<a class="es-btn es-btn--secondary" href="https://github.com/easysysio/EasyNAS" target="_blank" rel="noopener noreferrer">
<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true"><path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"></path></svg>
GitHub
</a>
<a class="es-btn es-btn--primary" href="#install">Get started</a>
</div>
</div>
</header>
<section class="es-band es-hero">
<div class="es-wrap es-hero-grid">
<div class="es-hero-copy es-rise">
<div class="es-eyebrow"><span class="es-eyebrow-dot"></span>Network attached storage · part of EasySYS</div>
<h1 class="es-h1">A spare machine in, a managed NAS out.</h1>
<p class="es-lead">EasyNAS is an appliance, not an application: one image installs a complete operating system with the management stack on top. Write it to a disk, boot it, and build Btrfs pools, volumes, snapshots and network shares from your browser — no Linux administration required.</p>
<div class="es-actions">
<a class="es-btn es-btn--primary es-btn--lg" href="#install">
Get started
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 5v14M6 13l6 6 6-6"></path></svg>
</a>
<a class="es-btn es-btn--ghost es-btn--lg" href="installation/">Read the docs</a>
</div>
<div class="es-pills">
<span class="es-pill"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="2" y="5" width="20" height="6" rx="2"></rect><rect x="2" y="13" width="20" height="6" rx="2"></rect><path d="M6 8h.01M6 16h.01"></path></svg>Btrfs pools</span>
<span class="es-pill"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 12a9 9 0 1 0 3-6.7"></path><path d="M3 4v5h5"></path></svg>Snapshots</span>
<span class="es-pill"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="4" y="11" width="16" height="10" rx="2"></rect><path d="M8 11V7a4 4 0 018 0v4"></path></svg>HTTPS web UI</span>
<span class="es-pill"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 8l-9-5-9 5v8l9 5 9-5V8z"></path><path d="M3 8l9 5 9-5M12 13v8"></path></svg>openSUSE Tumbleweed</span>
</div>
</div>
<div class="es-terminal-wrap es-rise es-rise--late">
<div class="es-terminal">
<div class="es-terminal-accent"></div>
<div class="es-terminal-bar">
<div class="es-dots"><span></span><span></span><span></span></div>
<span class="es-mono">admin@workstation — bash</span>
<span style="width: 47px;"></span>
</div>
<div class="es-term-body es-mono"><span class="t-c"># 1 — write the image to the machine's system disk</span>
<span class="t-p">$</span> xz -d EasyNAS.x86_64-2.0.install.iso.xz
<span class="t-p">$</span> sudo dd if=EasyNAS.x86_64-2.0.install.iso \
    of=/dev/sdX bs=4M status=progress
<span class="t-c"># 2 — boot it, and the console prints where to go</span>
<span class="t-ok">→</span> https://192.168.1.50:1443</div>
<div class="es-term-meta">
<div><div class="es-term-meta-label">Web UI</div><div class="es-term-meta-value es-mono">:1443</div></div>
<div><div class="es-term-meta-label">Storage</div><div class="es-term-meta-value es-mono">Btrfs</div></div>
<div><div class="es-term-meta-label">Arch</div><div class="es-term-meta-value es-mono">x86_64 · aarch64</div></div>
</div>
</div>
</div>
</div>
<div class="es-strip">
<div class="es-wrap es-strip-inner">
<span class="es-strip-label">Runs on</span>
<div class="es-strip-items">
<span>PCs and servers with UEFI</span>
<span>Raspberry Pi 3 rev 1.2+, 4, 400, 5</span>
<span>ARM64 boards with UEFI firmware</span>
<span>KVM · Proxmox · QEMU</span>
</div>
</div>
</div>
</section>
<section id="storage" class="es-band es-section">
<div class="es-wrap">
<div class="es-head">
<div>
<span class="es-kicker-lg">Storage</span>
<h2 class="es-h2">Btrfs, without learning Btrfs.</h2>
</div>
<p class="es-desc">Disks become pools, pools carry volumes, volumes are what you share and snapshot. Every step is a form in the web UI, and the layout survives an OS reinstall because it lives on the data disks, not the system disk.</p>
</div>
<div class="en-areas">
<div class="es-card en-area">
<div class="en-area-top">
<div class="es-icon"><svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"></circle><circle cx="12" cy="12" r="3"></circle><path d="M18.5 18.5l-4.4-4.4"></path></svg></div>
<span class="es-tag es-mono">Storage → Disk</span>
</div>
<span class="es-kicker">Disks</span>
<h3 class="es-h3">Every drive, with its health</h3>
<p class="es-product-text">Model, capacity and state for each drive — system, used, free or failed. SMART self-test results and Btrfs error counters surface on the dashboard, so a dying disk is visible before it takes data with it.</p>
<div class="es-tags"><span class="es-tag">SMART</span><span class="es-tag">Error counters</span></div>
</div>
<div class="es-card en-area">
<div class="en-area-top">
<div class="es-icon"><svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="2" y="4" width="20" height="6" rx="2"></rect><rect x="2" y="14" width="20" height="6" rx="2"></rect><path d="M6 7h.01M6 17h.01"></path></svg></div>
<span class="es-tag es-mono">Storage → File System</span>
</div>
<span class="es-kicker">Pools</span>
<h3 class="es-h3">RAID across the disks you pick</h3>
<p class="es-product-text">Create a pool over one or more free disks with a RAID profile and transparent compression. Grow it later by adding devices, mount it read-only, or watch it warn you when an array is running degraded.</p>
<div class="es-tags"><span class="es-tag">JBOD · RAID 0 · 1 · 10</span><span class="es-tag">RAID 5 · 6</span><span class="es-tag">zstd · lzo · zlib</span></div>
</div>
<div class="es-card en-area">
<div class="en-area-top">
<div class="es-icon"><svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 7a2 2 0 012-2h4l2 2h8a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2V7z"></path><path d="M8 13h8"></path></svg></div>
<span class="es-tag es-mono">Storage → Volume</span>
</div>
<span class="es-kicker">Volumes</span>
<h3 class="es-h3">The unit you share and snapshot</h3>
<p class="es-product-text">Volumes are Btrfs subvolumes on a pool, mounted at <code>/mnt/&lt;pool&gt;/&lt;volume&gt;</code>. Set the owning user or group, take a snapshot before a risky change, and hand the path to a sharing protocol.</p>
<div class="es-tags"><span class="es-tag">Snapshots</span><span class="es-tag">Owner</span></div>
</div>
</div>
</div>
</section>
<section id="sharing" class="es-band es-section es-subtle">
<div class="es-wrap">
<div class="es-head--stack">
<span class="es-kicker-lg">Sharing &amp; add-ons</span>
<h2 class="es-h2">The protocols your clients already speak.</h2>
<p class="es-desc">NFS, Samba and SSH come with the base image: toggle the service on, add a share, mount it. Everything else installs on demand from the EasyNAS repository, so the appliance stays small until you ask it for more.</p>
</div>
<div class="en-groups">
<div class="es-card en-group">
<div class="en-group-head">
<div class="es-icon es-icon--sm"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="2" y="3" width="20" height="14" rx="2"></rect><path d="M8 21h8M12 17v4"></path></svg></div>
<h3 class="en-group-title">In the base image</h3>
</div>
<ul class="en-list">
<li><strong>NFS</strong> for Linux and UNIX clients</li>
<li><strong>Samba</strong> for Windows, macOS and mixed networks</li>
<li><strong>SSH / SFTP</strong> for shell and file transfer</li>
<li>Users created in EasyNAS get their Samba credentials automatically</li>
</ul>
</div>
<div class="es-card en-group">
<div class="en-group-head">
<div class="es-icon es-icon--sm"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 16V8a2 2 0 00-1-1.73l-7-4a2 2 0 00-2 0l-7 4A2 2 0 003 8v8a2 2 0 001 1.73l7 4a2 2 0 002 0l7-4A2 2 0 0021 16z"></path><path d="M3.3 7L12 12l8.7-5M12 22V12"></path></svg></div>
<h3 class="en-group-title">More protocols</h3>
</div>
<ul class="en-list">
<li><code>fs-ftp</code> · <code>fs-tftp</code> for legacy clients and network boot</li>
<li><code>fs-rsyncd</code> for backups and replication</li>
<li><code>stg-iscsi</code> for block storage a hypervisor can boot from</li>
<li><code>mm-dlna</code> · <code>mm-plex</code> for TVs and media players</li>
</ul>
</div>
<div class="es-card en-group">
<div class="en-group-head">
<div class="es-icon es-icon--sm"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="3" width="7" height="7" rx="1.5"></rect><rect x="14" y="3" width="7" height="7" rx="1.5"></rect><rect x="3" y="14" width="7" height="7" rx="1.5"></rect><rect x="14" y="14" width="7" height="7" rx="1.5"></rect></svg></div>
<h3 class="en-group-title">Services and languages</h3>
</div>
<ul class="en-list">
<li><code>srv-lxc</code> — Linux containers with a web terminal</li>
<li><code>srv-mariadb</code> — a database server on the volume you choose</li>
<li><code>srv-radius</code> — FreeRADIUS</li>
<li>Language packs for German, Polish, Portuguese and Chinese</li>
</ul>
</div>
</div>
<p class="en-note">Add-ons are ordinary signed packages installed from <strong>Admin → Add-ons</strong>, and they update together with EasyNAS itself. The <a href="addons/">add-ons page</a> lists what each one provides.</p>
</div>
</section>
<section id="architecture" class="es-band es-section">
<div class="es-wrap">
<div class="es-head--stack">
<span class="es-kicker-lg">Architecture</span>
<h2 class="es-h2">One appliance, two ways in</h2>
<p class="es-desc">The image carries its own operating system, the management web application, and a console menu on the attached display. Settings live on a partition of their own, separate from the OS, and your data lives on the disks you gave to the pools.</p>
</div>
<div class="es-diagram">
<div class="es-diagram-scroll">
<svg viewBox="0 0 1120 360" role="img" aria-label="Diagram: clients reach the appliance over SMB, NFS and SSH while an administrator uses the web UI on port 1443 or the console menu on the attached display; EasyNAS keeps its settings on a separate partition and stores data on Btrfs pools built from the data disks.">
<defs>
<marker id="en-ah" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path class="a-head" d="M0 0L10 5L0 10z"></path></marker>
<marker id="en-ahb" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path class="a-head a-head--es" d="M0 0L10 5L0 10z"></path></marker>
</defs>
<text class="a-lane" x="0" y="14">YOUR NETWORK</text>
<text class="a-lane" x="300" y="14">EASYNAS APPLIANCE</text>
<text class="a-lane" x="880" y="14">YOUR DISKS</text>
<g class="a-ext"><rect x="0" y="60" width="220" height="76" rx="10"></rect><text class="a-title" x="20" y="92">Clients</text><text class="a-sub" x="20" y="116">SMB · NFS · SFTP</text></g>
<g class="a-ext"><rect x="0" y="196" width="220" height="76" rx="10"></rect><text class="a-title" x="20" y="228">Administrator</text><text class="a-sub" x="20" y="252">browser · console</text></g>
<g class="a-es"><rect x="300" y="30" width="500" height="310" rx="14"></rect><text class="a-title" x="324" y="66">EasyNAS</text><text class="a-sub" x="324" y="90">openSUSE Tumbleweed</text></g>
<g class="a-box"><rect x="324" y="120" width="210" height="80" rx="10"></rect><text class="a-title" x="340" y="152">Sharing services</text><text class="a-sub" x="340" y="176">nfs · samba · ssh</text></g>
<g class="a-box"><rect x="566" y="120" width="210" height="80" rx="10"></rect><text class="a-title" x="582" y="152">Web UI</text><text class="a-sub" x="582" y="176">:1443 · console menu</text></g>
<g class="a-box"><rect x="324" y="240" width="452" height="76" rx="10"></rect><text class="a-title" x="340" y="272">Settings partition</text><text class="a-sub" x="340" y="296">kept across updates and reinstalls</text></g>
<g class="a-ext"><rect x="880" y="50" width="240" height="84" rx="10"></rect><text class="a-title" x="900" y="84">Btrfs pool</text><text class="a-sub" x="900" y="110">RAID · compression</text></g>
<g class="a-ext"><rect x="880" y="186" width="240" height="84" rx="10"></rect><text class="a-title" x="900" y="220">Volumes</text><text class="a-sub" x="900" y="246">/mnt/pool/volume</text></g>
<line class="a-line" x1="220" y1="98" x2="322" y2="130" marker-end="url(#en-ah)"></line>
<text class="a-label" x="252" y="100">shares</text>
<line class="a-line" x1="220" y1="234" x2="322" y2="190" marker-end="url(#en-ah)"></line>
<text class="a-label" x="248" y="232">HTTPS</text>
<line class="a-line a-line--es" x1="640" y1="200" x2="640" y2="238" marker-end="url(#en-ahb)"></line>
<text class="a-label a-label--es" x="652" y="224">settings</text>
<path class="a-line a-line--es" fill="none" d="M776 160 H828 V92 H878" marker-end="url(#en-ahb)"></path>
<path class="a-line a-line--es" fill="none" d="M776 160 H828 V228 H878" marker-end="url(#en-ahb)"></path>
<text class="a-label a-label--es" x="836" y="156">btrfs</text>
</svg>
</div>
<div class="es-legend">
<span><span class="es-swatch"></span>The appliance</span>
<span><span class="es-swatch es-swatch--ext"></span>Your network and your disks</span>
<span class="es-legend-note">The system disk is installed and updated; the data disks are only ever mounted.</span>
</div>
</div>
</div>
</section>
<section id="install" class="es-band es-section es-subtle">
<div class="es-wrap es-install">
<div>
<span class="es-kicker-lg">Install</span>
<h2 class="es-h2">One image per platform, then a browser.</h2>
<p class="es-desc">Every image contains the same system — only the boot mechanics differ. The <a href="installation/">installation guide</a> covers each path, and <a href="supported-hardware/">supported hardware</a> answers whether your board will work.</p>
<div class="es-steps">
<div class="es-step"><span class="es-step-num es-mono">1</span><div><div class="es-step-title">Write the image</div><div class="es-step-text">An install ISO for UEFI PCs and ARM64 boards, a raw image for the Pi, a qcow2 for VMs.</div></div></div>
<div class="es-step"><span class="es-step-num es-mono">2</span><div><div class="es-step-title">Boot the machine</div><div class="es-step-text">The installer erases the system disk only; first boot makes a certificate and prints the address.</div></div></div>
<div class="es-step"><span class="es-step-num es-mono">3</span><div><div class="es-step-title">Open the web UI</div><div class="es-step-text">Set the admin password, build a pool and a volume, then turn on a sharing protocol.</div></div></div>
</div>
</div>
<div class="es-terminal es-code">
<input class="es-os-radio" type="radio" name="es-os" id="es-os-deb" checked />
<input class="es-os-radio" type="radio" name="es-os" id="es-os-rpm" />
<input class="es-os-radio" type="radio" name="es-os" id="es-os-suse" />
<input class="es-os-radio" type="radio" name="es-os" id="es-os-air" />
<div class="es-tabs">
<label for="es-os-deb">PC / server</label>
<label for="es-os-rpm">Raspberry Pi</label>
<label for="es-os-suse">ARM64 board</label>
<label for="es-os-air">Virtual machine</label>
</div>
<div class="es-panel es-panel--deb"><div class="es-term-body es-mono"><span class="t-c"># 1 — write the install ISO to a USB stick</span>
<span class="t-p">$</span> sudo dd if=EasyNAS.x86_64-&lt;version&gt;.install.iso \
    of=/dev/sdX bs=4M status=progress
<span class="t-c"># 2 — boot the stick in UEFI mode, pick "Install EasyNAS"</span>
<span class="t-c">#     the system disk is erased; data disks are untouched</span>
<span class="t-ok">→</span> https://&lt;ip-address&gt;:1443</div></div>
<div class="es-panel es-panel--rpm"><div class="es-term-body es-mono"><span class="t-c"># 1 — flash the raw image to the SD card, USB or NVMe disk</span>
<span class="t-p">$</span> xz -d EasyNAS.aarch64-&lt;version&gt;.raw.xz
<span class="t-p">$</span> sudo dd if=EasyNAS.aarch64-&lt;version&gt;.raw \
    of=/dev/sdX bs=4M status=progress
<span class="t-c"># 2 — insert and power on; first boot expands the filesystem</span>
<span class="t-ok">→</span> https://&lt;ip-address&gt;:1443</div></div>
<div class="es-panel es-panel--suse"><div class="es-term-body es-mono"><span class="t-c"># 0 — one-time: put UEFI firmware (EDK2) on the board's SPI flash</span>
<span class="t-c"># 1 — flash the raw image, or install from the ISO onto eMMC/NVMe</span>
<span class="t-p">$</span> xz -d EasyNAS.arm64efi-&lt;version&gt;.raw.xz
<span class="t-p">$</span> sudo dd if=EasyNAS.arm64efi-&lt;version&gt;.raw \
    of=/dev/sdX bs=4M status=progress
<span class="t-ok">→</span> https://&lt;ip-address&gt;:1443</div></div>
<div class="es-panel es-panel--air"><div class="es-term-body es-mono"><span class="t-c"># 1 — import the disk image (Proxmox shown)</span>
<span class="t-p">$</span> qm importdisk 100 EasyNAS.x86_64-&lt;version&gt;.qcow2 local-lvm
<span class="t-c"># 2 — set the VM to UEFI (OVMF), 2+ GB RAM, pass the data disks</span>
<span class="t-c"># 3 — boot: no installer pass, it expands to the virtual disk</span>
<span class="t-ok">→</span> https://&lt;ip-address&gt;:1443</div></div>
</div>
</div>
<div class="es-wrap">
<div class="en-platforms">
<div class="es-card en-platform">
<div class="es-icon es-icon--sm"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="4" width="18" height="12" rx="2"></rect><path d="M8 20h8M12 16v4"></path></svg></div>
<div class="en-platform-title">x86_64 PC</div>
<div class="en-platform-text">Install ISO, UEFI firmware required (roughly 2012 or newer).</div>
</div>
<div class="es-card en-platform">
<div class="es-icon es-icon--sm"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="6" y="6" width="12" height="12" rx="2"></rect><path d="M9 2v4M15 2v4M9 18v4M15 18v4M2 9h4M2 15h4M18 9h4M18 15h4"></path></svg></div>
<div class="en-platform-title">Raspberry Pi</div>
<div class="en-platform-text">Raw image for 64-bit models: Pi 3 rev 1.2+, 4, 400 and 5.</div>
</div>
<div class="es-card en-platform">
<div class="es-icon es-icon--sm"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="4" y="4" width="16" height="16" rx="2"></rect><rect x="9" y="9" width="6" height="6" rx="1"></rect><path d="M2 10h2M2 14h2M20 10h2M20 14h2M10 2v2M14 2v2M10 20v2M14 20v2"></path></svg></div>
<div class="en-platform-title">ARM64 board</div>
<div class="en-platform-text">For boards that hold their own UEFI firmware, such as the RK3588 family.</div>
</div>
<div class="es-card en-platform">
<div class="es-icon es-icon--sm"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="2" y="4" width="20" height="7" rx="2"></rect><rect x="2" y="13" width="20" height="7" rx="2"></rect><path d="M6 8h.01M6 17h.01"></path></svg></div>
<div class="en-platform-title">Virtual machine</div>
<div class="en-platform-text">qcow2 for KVM, Proxmox and QEMU with OVMF firmware.</div>
</div>
</div>
</div>
</section>
<section class="es-band es-cta">
<div class="es-wrap">
<div class="es-cta-box">
<svg class="es-cta-hex" viewBox="0 0 512 512" aria-hidden="true"><polygon points="86,256 171,109 341,109 426,256 341,403 171,403" fill="none" stroke="#ffffff" stroke-width="34" stroke-linejoin="round"></polygon></svg>
<div class="es-cta-copy">
<h2 class="es-h2">Give an old machine a second job.</h2>
<p class="es-cta-text">Two disks and a spare box are enough for a mirrored pool with snapshots and network shares. Free software under the GPL v3, developed in the open.</p>
</div>
<div class="es-cta-actions">
<a class="es-btn es-btn--primary es-btn--lg" href="https://repo.easysys.io/easynas" target="_blank" rel="noopener noreferrer">Download</a>
<a class="es-btn es-btn--on-dark es-btn--lg" href="https://github.com/easysysio/EasyNAS" target="_blank" rel="noopener noreferrer">GitHub</a>
</div>
</div>
</div>
</section>
<footer class="es-band es-footer">
<div class="es-wrap es-footer-grid">
<div>
<a href="." class="es-brand"><img src="assets/logo.svg" alt="EasyNAS" /><span class="es-brand-name">Easy<span>NAS</span></span></a>
<p class="en-small">A turnkey NAS appliance, managed from the browser. Part of the <a href="https://easysys.io">EasySYS</a> suite.</p>
</div>
<div class="es-footer-col">
<span class="es-footer-title">Documentation</span>
<a href="supported-hardware/">Supported hardware</a>
<a href="installation/">Installation</a>
<a href="getting-started/">Getting started</a>
<a href="storage/">Storage</a>
<a href="sharing/">Sharing</a>
<a href="addons/">Add-ons</a>
<a href="administration/">Administration</a>
</div>
<div class="es-footer-col">
<span class="es-footer-title">EasySYS</span>
<a href="https://easysys.io">easysys.io</a>
<a href="https://easylog.easysys.io">EasyLog</a>
<a href="https://easywaf.easysys.io">EasyWAF</a>
<a href="https://easyvault.easysys.io">EasyVault</a>
<a href="https://easydc.easysys.io">EasyDC</a>
</div>
<div class="es-footer-col">
<span class="es-footer-title">Community</span>
<a href="https://github.com/easysysio/EasyNAS">GitHub</a>
<a href="https://repo.easysys.io/easynas">Downloads</a>
<a href="https://discord.gg/easysys">Discord</a>
</div>
</div>
<div class="es-wrap">
<div class="es-footer-bottom">
<span>© 2026 EasySYS · GPL-3.0 licensed</span>
<span class="es-mono">easynas.org</span>
</div>
</div>
</footer>
</div>
