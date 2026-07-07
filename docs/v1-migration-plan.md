# EasyNAS v1 → v2 Migration Plan

v2 is a full rewrite on Mojolicious. v1 (the CGI app under `easynasv1/`) is the
feature reference. This tracks what is still missing and the order to port it.

- v1 = 26 CGI programs (`easynasv1/cgi-bin/*.pl`)
- v2 = Mojolicious controllers (`lib/EasyNAS/Controller/*.pm`)

Two reusable scaffolds unlock most of the not-yet-ported services and should be
built before Phase 4:

- **Service-toggle mixin** — `<svc>off` / `<svc>on` → `systemctl` + status.
  Needed by ftp, afp, rsyncd, tftp, dlna, plex, radius, iscsi (already
  hand-rolled in ssh/nfs/samba).
- **Share-CRUD helper** — add/edit/delete share → write config → reload, reusing
  the in-volume share-marker rediscovery in `easynas.pm`.

---

## A. Reachable in the UI but dead in v2 (do first)

- [ ] **Restart / Shutdown** — v1 `power.pl`. Modals `#restart`/`#shutdown` in
      `templates/layouts/default.html.ep` have no body and there is no controller.
- [ ] **Language switcher** — v1 `index.pl?action=language`. Not routed; the flag
      dropdown links nowhere.
- [ ] **Global search** — v1 `search.pl` (313 loc). The sidebar search box is inert.

## B. Ported controllers with partial parity

- [ ] **settings** (v1 399 → v2 80 loc): date/time (`setdate`), SSL cert upload
      (`upload_crt`), ACL config (`acl`).
- [ ] **samba**: edit share (`change`/`change_share`), NetBIOS/nmbd toggle
      (`nmboff`/`nmbon`).
- [ ] **groups**: edit group settings (`changesetting`).
- [ ] **filesystem**: balance/scrub pause/resume/cancel (`bpause`/`bresume`/
      `bcancel`/`scancel`), replace-cancel, `ChangeMount`. (Ties into the live
      balance/scrub progress banner discussed separately.)
- [ ] **network** (v1 320 → v2 102 loc): review — likely missing static IP / DNS /
      gateway / bonding depth.
- [ ] **disk**: `setparam` (spindown / APM disk parameters).

## C. Not yet ported (no controller; addon `enable=false`)

Sharing:
- [ ] ftp (91)   - [ ] afp (196)   - [ ] rsyncd (234)   - [ ] tftp (187)

Storage:
- [ ] iscsi (250)

Multimedia:
- [ ] dlna (226)   - [ ] plex (144)

Services:
- [ ] radius (199)

Data protection:
- [ ] backup (178)   - [ ] sync (159)

System:
- [ ] scheduler (809) — large; a UI over the scrub/snapshot/update cron v2
      already writes.

## D. New in v2 (no v1 parity needed)

`realm` (directory backends), `lxc` (container terminal), `mariadb` (addon stub,
no controller yet).

## E. Cleanup

- [ ] Remove the dead `profile.easynas` addon — profile/password is handled by
      `users.pm` (`passwordmenu`).

---

## Phased order

| Phase | Scope | Size |
|-------|-------|------|
| 1 — Make the chrome honest | power (restart/shutdown + modals), language switch, search | S |
| 2 — Close parity gaps | settings (date/time, cert upload, ACL), samba edit-share + nmbd, groups edit, disk setparam, network review, filesystem balance/scrub control | M |
| 3 — Build the two scaffolds | service-toggle mixin + share-CRUD helper | S–M |
| 4 — Sharing protocols | ftp → afp → rsyncd → tftp | M |
| 5 — Storage / services | iscsi, radius | M |
| 6 — Multimedia | dlna, plex | S–M |
| 7 — Data protection + scheduler | backup, sync, scheduler | L |
| 8 — New + cleanup | mariadb scope, finalize realm/computers, drop profile stub | S |

**Rationale:** Phase 1 stops the UI lying. Phase 2 finishes half-built
controllers. Phase 3's scaffolds make 4–6 largely mechanical (each service ≈
toggle + config writer + template). Scheduler is last in the service work
because the cron it manages already runs headless.
