
# lang_german_easynas.pl
# Version 1.2.0
#
# EasyNAS is free software: You can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# This file is part of EasyNAS (c) created by Yariv Hakim 2012-2022
#
# Homepage    : https://www.easynas.org
#
#########################################################################


$TEXT{'easynas'} = "EasyNAS";
$TEXT{'yariv'} = "Yariv Hakim";
$TEXT{'please_wait'} = "Bitte warten....";
$TEXT{'not_authorized'} = "Benutzung dieser Funktion nicht erlaubt";
$TEXT{'edit'} = "Bearbeiten";
$TEXT{'delete'} = "Löschen";
$TEXT{'about'} = "Über";
$TEXT{'save'} = "Speichern";
$TEXT{'reset'} = "Reset";
$TEXT{'create'} = "Erstellen";
$TEXT{'add'} = "Hinzufügen";
$TEXT{'easynas_url'} = "https://www.easynas.org";
$TEXT{'running'} = "Läuft auf";
$TEXT{'close'} = "Schließen";

#### Types ####
$TEXT{'storage'} = "Speicher";
$TEXT{'system'} = "System";
$TEXT{'sharing'} = "Dateifreigabe";
$TEXT{'services'} = "Dienste";
$TEXT{'multimedia'} = "Multimedia";
$TEXT{'realm'} = "Realm";


#####   Login #####
$TEXT{'login'} = "Anmelden";
$TEXT{'login_to_easynas'} = "Bei EasyNAS anmelden";
$TEXT{'login_username'} = "Benutzername";
$TEXT{'login_password'} = "Passwort";
$TEXT{'login_remember_me'} = "Angemeldet bleiben";

######  Dashboard ######
$TEXT{'dashboard'} = "Dashboard";
$TEXT{'dashboard_view_details'} = "Details anzeigen";
$TEXT{'dashboard_update_available'} = "Updates für EasyNAS und seine Add-ons sind verfügbar.";
$TEXT{'dashboard_update_here'} = "Add-ons öffnen";
$TEXT{'dashboard_drives'} = "Laufwerke";
$TEXT{'dashboard_filesystems'} = "Dateisysteme";
$TEXT{'dashboard_users'} = "Benutzer";
$TEXT{'dashboard_volumes'} = "Volumes";
$TEXT{'dashboard_disk'} = "Datenträger";
$TEXT{'dashboard_filesystem'} = "Dateisystem";
$TEXT{'dashboard_failed'} = "Ausgefallen";
$TEXT{'dashboard_used'} = "Belegt";
$TEXT{'dashboard_system'} = "System";
$TEXT{'dashboard_free'} = "Frei";
$TEXT{'dashboard_good'} = "Gut";
$TEXT{'dashboard_degreded'} = "Degradiert";
$TEXT{'dashboard_update_available'} = "Updates für EasyNAS und seine Add-ons sind verfügbar.";
$TEXT{'dashboard_click_here'} = " zum Aktualisieren hier klicken";
$TEXT{'dashboard_cpu'} = "CPU";
$TEXT{'dashboard_cores'} = "Kerne";
$TEXT{'dashboard_load'} = "Last";
$TEXT{'dashboard_memory'} = "Arbeitsspeicher";
$TEXT{'dashboard_memory_available'} = "Verfügbar";
$TEXT{'dashboard_swap'} = "Swap";

#### Search ####
$TEXT{'search'} = "Suchen";

#### System Info ####
$TEXT{'sysinfo'} = "System Information";
$TEXT{'cpu'} = "CPU";
$TEXT{'vendor'} = "Hersteller";
$TEXT{'model'} = "Modell";
$TEXT{'cache_size'} = "Cache Size";
$TEXT{'speed'} = "Geschwindiwgkeit";
$TEXT{'os'} = "Kernel";
$TEXT{'architecture'} = "Architektur";
$TEXT{'firmware'} = "Firmware";
$TEXT{'filesystem'} = "Dateisystem";
$TEXT{'memory'} = "Speicher (RAM/Swap)";
$TEXT{'total_memory'} = "Gesamtkapazität RAM";
$TEXT{'free_memory'} = "Freier RAM-Speicher";
$TEXT{'total_swap_memory'} = "Gesamtkapazität Swap";
$TEXT{'free_swap_memory'} = "Freier Swap-Speicher";

#### Settings ####
$TEXT{'settings'} = "Einstellungen";
$TEXT{'settings_date_time'} = "Datum / Uhrzeit";
$TEXT{'settings_date'} = "Datum";
$TEXT{'settings_time'} = "Uhrzeit";
$TEXT{'settings_date_help'} = "Manuelle Einstellung nur, wenn kein NTP verwendet wird; andernfalls synchronisiert NTP die Uhr erneut.";
$TEXT{'settings_date_set'} = "Datum und Uhrzeit aktualisiert.";
$TEXT{'settings_cert'} = "Zertifikat";
$TEXT{'settings_cert_current'} = "Aktuelles Zertifikat";
$TEXT{'settings_cert_file'} = "Zertifikat (PEM)";
$TEXT{'settings_key_file'} = "Privater Schlüssel (PEM, optional)";
$TEXT{'settings_cert_help'} = "Passendes Zertifikat und Schlüssel hochladen. Der Webserver startet zur Übernahme neu.";
$TEXT{'settings_cert_uploaded'} = "Zertifikat hochgeladen. Neustart zur Übernahme...";
$TEXT{'no_cert'} = "Kein Zertifikat gefunden";
$TEXT{'settings_repo'} = "Repository";
$TEXT{'settings_hostname'} = "Hostname";
$TEXT{'settings_port'} = "Port";
$TEXT{'settings_save'} = "Speichern";
$TEXT{'settings_reset'} = "Zurücksetzen";
$TEXT{'settings_bad_port'} = "Ungültiger Port";
$TEXT{'settings_saved'} = "Einstellungen gespeichert. Für die Übernahme ist ggf. ein Neustart erforderlich.";

$TEXT{'change_settings_in_progress'} = "Änderungen werden angewendet....";
$TEXT{'cert_details'} = "Zertifikat Details";
$TEXT{'no_cert'} = "Kein Zertifikat gefunden";
$TEXT{'bad_cert'} = "Ungültiges Zertifikat";
$TEXT{'upload'} = "Upload";
$TEXT{'error_updating_date'} = "Fehler bei Aktualisierung von Datum / Uhrzeit";
$TEXT{'error_settings_demo'} = "Einstellungen können im Demo-Modus nicht verändert werden";
$TEXT{'enabled'} = "Aktiviert";
$TEXT{'disabled'} = "Deaktiviert";
$TEXT{'enable'} = "Aktivieren";
$TEXT{'disable'} = "Deaktivieren";

#### User Profile ####
$TEXT{'user_profile'} = "Benutzerprofil";


#### Backup ####
$TEXT{'backup_restore'} = "Sicherung & Wiederherstellung";
$TEXT{'backup'} = "Sicherung";
$TEXT{'restore'} = "Wiederherstellung";
$TEXT{'file_name'} = "Dateiname";
$TEXT{'backup_failed'} = "Sicherung fehlgeschlagen";
$TEXT{'backup_completed'} = "Sicherung erfolgreich abgeschlossen";
$TEXT{'restore_failed'} = "Wiederherstellung fehlgeschlagen";
$TEXT{'testore_completed'} = "Wiederherstellung abgeschlossen";

#### Network settings ####
$TEXT{'network_setting'} = "Netzwerkeinstellungen";
$TEXT{'network_interface'} = "Schnittstelle";
$TEXT{'network_type'} = "Typ";
$TEXT{'network_state'} = "Status";
$TEXT{'network_speed'} = "Geschwindigkeit";
$TEXT{'network_connection_type'} = "Verbindungstyp";
$TEXT{'network_ip'} = "IP-Adresse";
$TEXT{'network_subnet'} = "Subnetzmaske";
$TEXT{'network_gateway'} = "Gateway";
$TEXT{'network_dns1'} = "Primärer DNS";
$TEXT{'network_dns2'} = "Sekundärer DNS";
$TEXT{'network_domain'} = "Domäne";
$TEXT{'network_actions'} = "Aktionen";
$TEXT{'network_edit'} = "Bearbeiten";
$TEXT{'network_static'} = "Statisch";
$TEXT{'network_dhcp'} = "DHCP";
$TEXT{'network_saved'} = "IP-Adresse geändert";
$TEXT{'network_failed_to_save'} = "Ändern der IP-Einstellungen fehlgeschlagen";
$TEXT{'network_manager_down'} = "Network Manager ist nicht aktiv";
$TEXT{'network_settings_can_not_change'} = "Netzwerkeinstellungen können nicht geändert werden";
$TEXT{'network_click_here_to_activate'} = "Zum Aktivieren hier klicken";

$TEXT{'error_ip_demo'} = "IP-Adresse kann im Demo-Modus nicht geändert werden";
$TEXT{'network_restart'} = "Netzwerk neustart";


#### Scheduler ##########
$TEXT{'scheduler'} = "Aufgabenplaner";
$TEXT{'snapshots'} = "Snapshots";
$TEXT{'syncs'} = "Remote-Synchronisierung";
$TEXT{'scrubs'} = "Dateisystembereinigung";
$TEXT{'powers'} = "Power Control";
$TEXT{'create_sc'} = "Aufgabe erstellen";
$TEXT{'schedule_snapshot'} = "Schattenkopie planen";
$TEXT{'schedule_sync'} = "Remote-Synchronisierung planen";
$TEXT{'schedule_scrub'} = "Dateisystembereinigung planen";
$TEXT{'schedule_power'} = "Neustart/Herunterfahren planen";
$TEXT{'no_vol_selected'} = "Kein Datenträger ausgewählt";
$TEXT{'sc_exists'} = "Aufgabenname bereits vorhanden";
$TEXT{'control_type'} = "Kontrolltyp";
$TEXT{'error_restarting_sc'} = "Fehler bei Neustart der Aufgabenplanung";
$TEXT{'delete_sc'} = "Aufgabe löschen";
$TEXT{'error_deleting_sc'} = "Fehler bei Löschung der Aufgabe";
$TEXT{'update_sc'} = "Planung aktualisieren";
$TEXT{'sc_name'} = "Name";
$TEXT{'remote_system'} = "Remote System";
$TEXT{'time'} = "Zeit";
$TEXT{'date'} = "Datum";
$TEXT{'day_of_week'} = "Wochentag";
$TEXT{'sc'} = "SCHEDULE";
$TEXT{'scs'} = "Aufgaben";
$TEXT{'sc_name'} = "Name";
$TEXT{'sc_task'} = "Task";
$TEXT{'vol_name'} = "Datenträgername";
$TEXT{'fs_name'} = "Name";
$TEXT{'fs_delete'} = "Dateisystem löschen";
$TEXT{'weekday'} = "Wochentag";
$TEXT{'delete_sc?'} = "Aufgabe wirklich löschen?";

### NETWORK ###
$TEXT{'network_settings'} = "Netzwerkeinstellungen";
$TEXT{'network_interfaces'} = "Netzwerkschnittstelle";
$TEXT{'interface'} = "Schnittstelle";
$TEXT{'state'} = "Status";
$TEXT{'broadcast'} = "Broadcast";
$TEXT{'net_mask'} = "Netzwerk-Maske";
$TEXT{'hardware_mac'} = "MAC-Address";
$TEXT{'dhcp'} = "DHCP";
$TEXT{'static'} = "Static";
$TEXT{'ip_address'} = "IP-Address";
$TEXT{'subnet_mask'} = "Subnet Mask";
$TEXT{'gateway'} = "Gateway";
$TEXT{'domain'} = "Domain";
$TEXT{'pri_dns'} = "Primary DNS";
$TEXT{'sec_dns'} = "Secondary DNS";
$TEXT{'state_up'} = "Up";
$TEXT{'state_down'} = "Down";
$TEXT{'error_ip_demo'} = "IP-Adresse kann im Demo-Modus nicht geändert werden";
$TEXT{'network_restart'} = "Netzwerk neustart";

#### Realm ####
$TEXT{'computers'} = "Computer";
$TEXT{'computers_manager'} = "Computerverwaltung";


#### Monitor ####
$TEXT{'cpu'} = "CPU";
$TEXT{'memory'} = "Speicher (RAM/Swap)";
$TEXT{'disk_io'} = "Datenträger-E/A";
$TEXT{'network_band'} = "Netzwerkbandbreite";


#### Power Managment ####
$TEXT{'power_management'} = "Power Management";
$TEXT{'shutdown_restart'} = "Herunterfahren / Neustart";
$TEXT{'power_restart'} = "Neu starten";
$TEXT{'power_shutdown'} = "Herunterfahren";
$TEXT{'power_restarting'} = "Die Appliance wird neu gestartet...";
$TEXT{'power_shuttingdown'} = "Die Appliance wird heruntergefahren...";
$TEXT{'power_restart_confirm'} = "Appliance jetzt neu starten?";
$TEXT{'power_shutdown_confirm'} = "Appliance jetzt herunterfahren?";
$TEXT{'error_restart_demo'} = "Neustart im Demo-Modus nicht verfügbar";
$TEXT{'restart_system'} = "Neustart des Systems......";
$TEXT{'error_shutdown_demo'} = "Herunterfahren im Demo-Modus nicht verfügbar";
$TEXT{'shutdown_system'} = "Herunterfahren des Systems.....";
$TEXT{'execute_immediately'} = "System Herunterfahren / Neustarten.";
$TEXT{'restart'} = "Neustart";
$TEXT{'shutdown'} = "Herunterfahren";
$TEXT{'close_service'} = "Dienste werden beendet.....";
$TEXT{'close_fs'} = "Dateisysteme werden ausgehängt.....";
$TEXT{'restart_are_u_sure'} = "Wirklich neu starten?";
$TEXT{'restart_help'} = "Sie sind dabei, EasyNAS neu zu starten<br>Bitte speichern Sie alle Dateien und schließen Sie offene Dienste<br><br>Klicken Sie auf Neu starten, wenn Sie bereit sind";
$TEXT{'shutdown_help'} = "Sie sind dabei, EasyNAS herunterzufahren<br>Bitte speichern Sie alle Dateien und schließen Sie offene Dienste<br><br>Klicken Sie auf Herunterfahren, wenn Sie bereit sind";

#### Firmware ####
$TEXT{'firmware'} = "Firmware";
$TEXT{'firmware_name'} = "Name";
$TEXT{'firmware_desc'} = "Beschreibung";
$TEXT{'firmware_new'} = "Neue Version";
$TEXT{'firmware_current'} = "Aktuelle Version";
$TEXT{'firmware_actions'} = "Aktionen";
$TEXT{'firmware_update_r_u_sure'} = "Wirklich aktualisieren?";
$TEXT{'firmware_update'} = "Aktualisieren";
$TEXT{'firmware_update_available'} = "Neue Updates verfügbar";
$TEXT{'firmware_here'} = " zum Aktualisieren hier klicken";
$TEXT{'firmware_refresh'} = "Neu laden";
$TEXT{'firmware_refreshed'} = "Repositories neu geladen";
$TEXT{'firmware_noupdate'} = "Keine Updates verfügbar";
$TEXT{'firmware_update_success'} = "Update erfolgreich abgeschlossen";
$TEXT{'firmware_update_failed'} = "Update fehlgeschlagen";
$TEXT{'firmware_updating'} = "Systemupdate läuft im Hintergrund...";
$TEXT{'firmware_phase_down'} = "Herunterladen";
$TEXT{'firmware_phase_inst'} = "Installieren";
$TEXT{'firmware_phase_prep'} = "Vorbereiten";

#### Addons #####
$TEXT{'addons'} = "Add-ons";
$TEXT{'addons_sharing'} = "Dateifreigabe";
$TEXT{'addons_storage'} = "Speicher&Backup";
$TEXT{'addons_multimedia'} = "Multimedia";
$TEXT{'addons_services'} = "Dienste";
# Addon grid category labels, keyed by package group code (easynas-<group>-*).
$TEXT{'addons_fs'} = "Dateifreigabe";
$TEXT{'addons_mm'} = "Multimedia";
$TEXT{'addons_srv'} = "Dienst";
$TEXT{'addons_stg'} = "Speicher";
$TEXT{'addons_easynas'} = "EasyNAS";
$TEXT{'addons_lang'} = "Sprache";
$TEXT{'addons_other'} = "Weitere Apps";
$TEXT{'addons_name'} = "Add-on-Name";
$TEXT{'addons_version'} = "Version";
$TEXT{'addons_update'} = "Aktualisieren";
$TEXT{'addons_delete'} = "Löschen";
$TEXT{'addons_status'} = "Status";
$TEXT{'addons_desc'} = "Beschreibung";
$TEXT{'addons_actions'} = "Aktionen";
$TEXT{'addons_install'} = "Installieren";
$TEXT{'addons_delete'} = "Löschen";
$TEXT{'addons_update'} = "Aktualisieren";
$TEXT{'addons_install?'} = "Add-on installieren?";
$TEXT{'addons_update?'} = "Add-on aktualisieren?";
$TEXT{'addons_delete?'} = "Add-on löschen?";
$TEXT{'addons_info'} = "Information";
$TEXT{'addons_installed'} = "Add-on erfolgreich installiert";
$TEXT{'addons_not_installed'} = "Fehler bei der Add-on-Installation";
$TEXT{'addons_notinst'} = "nicht installiert";
$TEXT{'addons_deleted'} = "Add-on erfolgreich entfernt";
$TEXT{'addons_not_deleted'} = "Fehler beim Entfernen des Add-ons";
$TEXT{'addons_updated'} = "Add-on erfolgreich aktualisiert";
$TEXT{'addons_not_updated'} = "Fehler beim Aktualisieren des Add-ons";
$TEXT{'addons_close'} = "Schließen";
$TEXT{'addons_details'} = "Details";
$TEXT{'addons_version'} = "Version";
$TEXT{'addons_nodesc'} = "Keine Beschreibung verfügbar.";


$TEXT{'firmware_upgrade'} = "Firmware-Upgrade";
$TEXT{'lang'} = "Sprache";
$TEXT{'other_apps'} = "Weitere Apps";
$TEXT{'component'} = "Component";
$TEXT{'author'} = "Author";
$TEXT{'version'} = "Version";
$TEXT{'current_version'} = "Derzeitige Version";
$TEXT{'new_version'} = "Neue Version";
$TEXT{'package_name'} = "Paketname";
$TEXT{'update'} = "Aktualisieren";
$TEXT{'refresh'} = "Neu laden";
$TEXT{'refresh_failed'} = "Neuladen fehlgeschlagen";
$TEXT{'installed_version'} = "Installierte Version";
$TEXT{'current_version'} = "Derzeitige Version";
$TEXT{'install_addon'} = "Add-on installieren";
$TEXT{'uninstall_addon'} = "Add-on deinstallieren";
$TEXT{'upgrade_addon'} = "Add-on aktualisieren";
$TEXT{'check_for_update'} = "Nach Update suchen";
$TEXT{'cheking_firmware_availble'} = "Suche die aktuellste Firmware von EasyNAS: ......  ";
$TEXT{'latest_firmware'} = "Das System ist bereits auf den neusten Stand";
$TEXT{'download_latest_version_here'} = "Download der aktuellsten Version <a href=http://www.easynas.org/download target=New_Page>hier</a>";
$TEXT{'upgrade_in_progress'} = "Upgrade wird ausgeführt.........";
$TEXT{'downloading_firmware'} = "Herunterladen der Firmware.......";
$TEXT{'installing_new_firmware'} = "Installieren der neuen Firmware......";
$TEXT{'firmware_upgraded'} = "Firmware-Upgrade erfolgreich";
$TEXT{'error_upgrading'} = "Fehler bei dem Firmware-Upgrade - Versuchen Sie es später noch einmal";
$TEXT{'error_connecting'} = "Fehler beim Verbinden mit dem EasyNAS-Repository, bitte später erneut versuchen";
$TEXT{'failed_to_refresh_repo'} = "EasyNAS-Repository konnte nicht neu geladen werden. Bitte später erneut versuchen";
$TEXT{'failed_to_install_addon'} = "Add-on konnte nicht installiert werden";
$TEXT{'refresh_repo'} = "Repository neu laden";
$TEXT{'failed_to_delete_addon'} = "Add-on konnte nicht entfernt werden";
$TEXT{'install_addon?'} = "Add-on installieren?";
$TEXT{'update_addon?'} = "Add-on aktualisieren?";
$TEXT{'delete_addon?'} = "Add-on löschen?";
$TEXT{'update_all'} = "Alle aktualisieren";
$TEXT{'firmware_refreshed'} = "Repositories neu geladen";
$TEXT{'firmware_not_refreshed'} = "Fehler beim Neuladen der Repositories";

#### Disk ####
$TEXT{'disk_manager'} = "Festplattenverwaltung";
$TEXT{'disk'} = "Festplatte";
$TEXT{'disk_size'} = "Größe";
$TEXT{'disk_status'} = "Status";
$TEXT{'disk_type'} = "Typ";
$TEXT{'disk_health'} = "Zustand";
$TEXT{'disk_model'} = "Modell";
$TEXT{'disk_serial'} = "Seriennummer";
$TEXT{'disk_firmware'} = "Firmware";
$TEXT{'disk_actions'} = "Aktionen";
$TEXT{'disk_free'} = "Frei";
$TEXT{'disk_used'} = "Belegt";
$TEXT{'disk_system'} = "System";
$TEXT{'disk_bad'} = "Defekt";
$TEXT{'disk_good'} = "Gut";
$TEXT{'disk_format'} = "Formatieren";
$TEXT{'disk_settings'} = "Festplatteneinstellungen";
$TEXT{'disk_format_success'} = "Datenträger erfolgreich formatiert";
$TEXT{'disk_format_failed'} = "Formatieren des Datenträgers fehlgeschlagen";
$TEXT{'disk_write_io_errs'} = "Schreibfehler";
$TEXT{'disk_read_io_errs'} = "Lesefehler";
$TEXT{'disk_flush_io_errs'} = "Flush-Fehler";
$TEXT{'disk_corruption_errs'} = "Korruptionsfehler";
$TEXT{'disk_generation_errs'} = "Generationsfehler";
$TEXT{'disk_clean_errs'} = "Fehler zurücksetzen";
$TEXT{'disk_clean_errs_success'} = "Fehler zurückgesetzt";
$TEXT{'disk_clean_errs_failed'} = "Fehler konnten nicht zurückgesetzt werden";
$TEXT{'disk_close'} = "Schließen";

#### File System ####
$TEXT{'fs'} = "Dateisystem";
$TEXT{'fs_create'} = "Dateisystem erstellen";
$TEXT{'fs_name'} = "Name";
$TEXT{'fs_raid_level'} = "RAID-Level";
$TEXT{'fs_compression'} = "Komprimierung";
$TEXT{'fs_ssd_optimization'} = "SSD-Optimierung";
$TEXT{'fs_auto_defrag'} = "Auto-Defragmentierung";
$TEXT{'fs_auto_mount'} = "Automatisch einhängen";
$TEXT{'fs_add'} = "Dateisystem hinzufügen";
$TEXT{'fs_reset'} = "Zurücksetzen";
$TEXT{'fs_used'} = "Belegt";
$TEXT{'fs_status'} = "Status";
$TEXT{'fs_drives'} = "Laufwerke";
$TEXT{'fs_health'} = "Zustand";
$TEXT{'fs_readonly'} = "Nur Lesen";
$TEXT{'fs_read&write'} = "Lesen & Schreiben";
$TEXT{'fs_filesystem_contain_vol'} = "Das Dateisystem enthält Volumes";
$TEXT{'fs_failed_changing_label'} = "Dateisystem-Label konnte nicht geändert werden";
$TEXT{'fs_invalid_name'} = "Ungültiger Name: nur Buchstaben, Ziffern, Bindestrich und Unterstrich";
$TEXT{'fs_busy'} = "Das Dateisystem wird noch verwendet (offene Dateien). Dateien schließen oder Freigabedienste neu starten und erneut versuchen";
$TEXT{'fs_name_changed'} = "Dateisystemname wurde geändert";
$TEXT{'fs_umount_first'} = "Das Dateisystem muss vor dem Umbenennen ausgehängt werden";
$TEXT{'fs_failed_formating_disk'} = "Formatieren der Datenträger fehlgeschlagen";
$TEXT{'fs_failed_creating_dir'} = "Verzeichnis konnte nicht erstellt werden";
$TEXT{'fs_failed_mounting'} = "Einhängen des Dateisystems fehlgeschlagen";
$TEXT{'fs_mounted'} = "Dateisystem eingehängt";
$TEXT{'fs_size'} = "Größe";
$TEXT{'fs_better'} = "Besser";
$TEXT{'fs_faster'} = "Schneller";
$TEXT{'fs_optimized'} = "Optimiert";
$TEXT{'fs_none'} = "Keine";
$TEXT{'fs_mount'} = "Einhängen";
$TEXT{'fs_unmount'} = "Aushängen";
$TEXT{'fs_delete?'} = "Dateisystem löschen?";
$TEXT{'fs_change_settings'} = "Einstellungen ändern";

$TEXT{'cancel'} = "Abbrechen";
$TEXT{'resume'} = "Fortsetzen";
$TEXT{'snapshot'} = "Snapshot";
$TEXT{'filesystems'} = "Dateisysteme";
$TEXT{'fs_manager'} = "Dateisystem Manager";
$TEXT{'better'} = "Besser";
$TEXT{'faster'} = "Schneller";
$TEXT{'none'} = "Keine";
$TEXT{'health'} = "Zustand";
$TEXT{'good'} = "Gut";
$TEXT{'degraded'} = "Degradiert";
$TEXT{'disk_errors'} = "Datenträgerfehler";
$TEXT{'insufficient'} = "Zu wenige Datenträger";
$TEXT{'remove_hd'} = "Festplatte entfernen";
$TEXT{'replace_hd'} = "Festplatte ersetzen";
$TEXT{'source_hd'} = "Quellfestplatte";
$TEXT{'target_hd'} = "Zielfestplatte";
$TEXT{'failed_to_remove_hd'} = "Fehler beim entfernen der Festplatte";
$TEXT{'fs_hd_removed'} = "Festplatte erfolgreich entfernt";
$TEXT{'fs_hd_added'} = "Festplatte erfolgreich hinzugefügt";
$TEXT{'fs_hd_replaced'} = "Festplatte erfolgreich ersetzt";
$TEXT{'fs_failed_to_replace'} = "Festplatte konnte nicht ersetzt werden";
$TEXT{'add_hd'} = "Festplatte hinzufügen";
$TEXT{'failed_to_add_HD'} = "Fehler beim hinzufügen von Festplatte";
$TEXT{'repair_hd'} = "Festplatte reparieren";
$TEXT{'fs_need_to_be_unmounted'} = "Dateisystem muss entladen werden";
$TEXT{'fs_need_to_be_mounted'} = "Das Dateisystem muss eingehängt sein";
$TEXT{'check&repair_hd'} = "Festplattencheck & Reparatur";
$TEXT{'create_fs'} = "Dateisystem erstellen";
$TEXT{'fs_deleted'} = "Dateisystem erfolgreich gelöscht";
$TEXT{'no_disks_were_selected'} = "Keine Festplatte ausgewählt";
$TEXT{'no_fs_name_was_entered'} = "Kein Name für das Daeisystem angegeben";
$TEXT{'reserved_fs'} = "ROOT ist ein reservierter Name";
$TEXT{'raid_0_require_two'} = "Raid 0 benötigt minimum zwei Festplatten";
$TEXT{'raid_1_require_two'} = "Raid 1 benötigt minimum zwei Festplatten";
$TEXT{'raid_10_require_four'} = "Raid 10 benötigt minimum vier Festplatten";
$TEXT{'raid_5_require_three'} = "Raid 5 benötigt minimum drei Festplatten";
$TEXT{'raid_6_require_four'} = "Raid 6 benötigt minimum vier Festplatten";
$TEXT{'raid_the_same'} = "RAID-Level ist unverändert, keine Aktion erforderlich.";
$TEXT{'raid_require_force'} = "Der Wechsel des RAID-Levels verringert die Integrität; die Änderung muss erzwungen werden.";
$TEXT{'raid_converting'} = "Das Dateisystem wird im Hintergrund auf das neue RAID-Level umgestellt. Das kann eine Weile dauern.";
$TEXT{'fs_not_mounted'} = "Für diese Aktion muss das Dateisystem eingehängt sein.";
$TEXT{'fs_balancing'} = "Balance läuft im Hintergrund.";
$TEXT{'fs_scrubbing'} = "Scrub gestartet; das Dateisystem wird überprüft.";
$TEXT{'fs_repairing'} = "Reparatur gestartet: ein Scrub stellt defekte Blöcke aus der Redundanz wieder her.";
$TEXT{'fs_removing_disk'} = "Der Datenträger wird im Hintergrund entfernt; die Daten werden migriert.";
$TEXT{'fs_disk_added'} = "Datenträger hinzugefügt. Balance ausführen, um die Daten zu verteilen.";
$TEXT{'fs_failed_adding_disk'} = "Datenträger konnte nicht hinzugefügt werden.";
$TEXT{'fs_replacing_disk'} = "Der Datenträger wird im Hintergrund ersetzt.";
$TEXT{'fs_add_disk'} = "Festplatte hinzufügen";
$TEXT{'fs_replace_disk'} = "Festplatte ersetzen";
$TEXT{'fs_replace_from'} = "Zu ersetzender Datenträger";
$TEXT{'fs_select_disk'} = "Freien Datenträger wählen";
$TEXT{'fs_apply'} = "Übernehmen";
$TEXT{'failed_creating_directory'} = "Fehler bei Verzeichniserstellung.";
$TEXT{'failed_creating_fs'} = "Fehler bei Erstellung von Dateisystem.";
$TEXT{'failed_mounting_fs'} = "Fehler bei Einbindung von Dateisystem.";
$TEXT{'mount_fs'} = "Dateisystem bereitstellen";
$TEXT{'unmount_fs'} = "Dateisystem aushängen";
$TEXT{'fs_failed_unmounting_fs'} = "Aushängen eines Dateisystems fehlgeschlagen.";
$TEXT{'no_free_disk'} = "Keine freie Festplatte verfügbar";
$TEXT{'raid_profile'} = "Raid-Profil";
$TEXT{'compression'} = "Komprimmierung";
$TEXT{'disks'} = "Festplatten";
$TEXT{'ssd_optimization'} = "SSD Optimierung";
$TEXT{'auto_mount'} = "Auto Einbindung";
$TEXT{'auto_defrag'} = "Auto Defragmentierung";
$TEXT{'mount_option'} = "Mount Optionen";
$TEXT{'file_system_name'} = "Dateisystemname";
$TEXT{'fs_raidlevel'} = "RAID-Level";
$TEXT{'raid_profile'} = "Raid-Profil";
$TEXT{'force_raid_change'} = "Erzwinge Raid-Änderung";
$TEXT{'change_raid'} = "Raid anwenden";
$TEXT{'fs_change_name'} = "Namen ändern";
$TEXT{'fs_mount_options'} = "Mount Options";
$TEXT{'fs_disks'} = "Festplatten";
$TEXT{'number'} = "Nummer";
$TEXT{'disk'} = "Festplatte";
$TEXT{'total_size'} = "Gesamtgröße";
$TEXT{'status'} = "Status";
$TEXT{'remove_hd?'} = "Wollen Sie wirklich die Festplatte entfernen ?";
$TEXT{'repair_hd?'} = "Wollen Sie wirklich die Festplatte reparieren ?";
$TEXT{'check_repair_complete'} = "Prüfen & Reparieren abgeschlossen";
$TEXT{'add_hd'} = "Festplatte hinzufügen";
$TEXT{'no_free_disks_available'} = "Keine freie Festplatte verfügbar";
$TEXT{'drives'} = "Laufwerke";
$TEXT{'fs_limit'} = "Dateisystem Kontingent";
$TEXT{'0_no_limit'} = "(0 = Keine Grenze)";
$TEXT{'failed_limit'} = "Fehler bei Limitierung des Kontingents";
$TEXT{'filesystem_contain_vol'} = "Das Dateisystem enthält Volumes";
$TEXT{'filesystem_not_changed'} = "Dateisystemname wurde nicht geändert";
$TEXT{'fs_created'} = "Dateisystem erfolgreich erstellt";

$TEXT{'fs_jbod_info'} = "JBOD (just a bunch of disks) fasst mehrere Datenträger zu einem logischen Volume zusammen, ohne Redundanz oder Striping.";
$TEXT{'fs_raid0_info'} = "RAID 0 (Striping) verteilt die Daten gleichmäßig auf zwei oder mehr Datenträger, ohne Parität oder Redundanz. Fällt ein Laufwerk aus, ist das gesamte Array verloren, da die Daten über alle Datenträger verteilt sind.";
$TEXT{'fs_raid1_info'} = "RAID 1 spiegelt die Daten identisch auf zwei oder mehr Datenträger; ein klassisches RAID-1-Paar besteht aus zwei Laufwerken. Keine Parität, kein Striping.";
$TEXT{'fs_raid5_info'} = "RAID 5 nutzt Striping auf Blockebene mit verteilter Parität. Fällt ein einzelnes Laufwerk aus, lassen sich die Daten aus der Parität rekonstruieren. RAID 5 erfordert mindestens drei Datenträger.";
$TEXT{'fs_raid6_info'} = "RAID 6 erweitert RAID 5 um einen zweiten Paritätsblock: Striping auf Blockebene mit zwei über alle Datenträger verteilten Paritätsblöcken.";
$TEXT{'fs_raid10_info'} = "RAID 10 kombiniert Spiegelung und Striping: Die Daten werden über gespiegelte Paare verteilt. Es toleriert einen Laufwerksausfall pro Spiegel und erfordert mindestens vier Laufwerke.";

#### Volumes ####
$TEXT{'vol_manager'} = "Datenträgerverwaltung";
$TEXT{'vol_create'} = "Volume erstellen";
$TEXT{'vol_name'} = "Datenträgername";
$TEXT{'vol_filesystem'} = "Dateisystem";
$TEXT{'vol_user_owner'} = "Besitzer (Benutzer)";
$TEXT{'vol_group_owner'} = "Besitzer (Gruppe)";
$TEXT{'vol_no_vol_name'} = "Kein Volume-Name eingegeben";
$TEXT{'vol_no_fs_selected'} = "Kein Dateisystem ausgewählt";
$TEXT{'vol_created'} = "Volume erfolgreich erstellt";
$TEXT{'vol_id'} = "ID";
$TEXT{'vol_size'} = "Größe";
$TEXT{'vol_fs'} = "Dateisystem";
$TEXT{'vol_actions'} = "Aktionen";
$TEXT{'vol_delete'} = "Volume löschen";
$TEXT{'vol_delete?'} = "Volume wirklich löschen?";
$TEXT{'vol_faild_to_delete'} = "Volume konnte nicht gelöscht werden";
$TEXT{'vol_deleted'} = "Volume erfolgreich gelöscht";
$TEXT{'vol_snapshot'} = "Snapshot";
$TEXT{'vol_settings'} = "Einstellungen";
$TEXT{'vol_permission'} = "Volume-Berechtigungen";
$TEXT{'vol_user'} = "Benutzer";
$TEXT{'vol_group'} = "Gruppe";
$TEXT{'vol_others'} = "Andere";
$TEXT{'vol_readonly'} = "Nur Lesen";
$TEXT{'vol_read&write'} = "Lesen & Schreiben";
$TEXT{'vol_deny'} = "Verweigern";
$TEXT{'vol_reset'} = "Zurücksetzen";
$TEXT{'vol_save'} = "Speichern";
$TEXT{'vol_create_snapshot'} = "Snapshot erstellen";
$TEXT{'vol_snapshot_name'} = "Snapshot-Name";
$TEXT{'vol_no_snapshot_name'} = "Kein Snapshot-Name eingegeben";
$TEXT{'vol_failed_to_add_snapshot'} = "Snapshot konnte nicht erstellt werden";
$TEXT{'vol_snapshot_created'} = "Snapshot erfolgreich erstellt";
$TEXT{'vol_saved'} = "Volume erfolgreich gespeichert";
$TEXT{'vol_no_fs'} = "Kein Dateisystem verfügbar";

$TEXT{'failed_to_change_owner'} = "Fehler bei Besitzeränderung";
$TEXT{'failed_to_change_permission'} = "Fehler beim ändern der Berechtigung";
$TEXT{'group_owner'} = "Gruppenberechtigung";
$TEXT{'user_permission'} = "User Permission";
$TEXT{'group_permission'} = "Group Permission";
$TEXT{'others_permission'} = "Andere Berechtigung";
$TEXT{'vols'} = "Datenträger";
$TEXT{'vol'} = "Datenträger";
$TEXT{'id'} = "ID";
$TEXT{'vol_name'} = "Datenträgername";
$TEXT{'size'} = "Größe";
$TEXT{'delete_vol?'} = "Wollen sie wirklich den Datenträger löschen ?";
$TEXT{'no_schedule_name'} = "Name der Aufgabe nicht vergeben.";
$TEXT{'failed_add_vol'} = "Fehler beim  hinzufügen des Datenträgers.";
$TEXT{'group_created'} = "Gruppe erfolgreich erstellt";
$TEXT{'group_deleted'} = "Gruppe erfolgreich gelöscht";


#### Sync ####
$TEXT{'sync'} = "Datenträgersynchronisierung";
$TEXT{'hostname'} = "Host";
$TEXT{'rdir'} = "Remote-Verzeichnis";
$TEXT{'password'} = "Passwort";
$TEXT{'sync_option'} = "Optionen";
$TEXT{'sync_complete'} = "Synchronisierung beendet";
$TEXT{'failed_to_sync'} = "Fehler bei der Synchronisierung";
$TEXT{'sync_could_not_connect'} = "Konnte keine Verbindung zum RSync-Server herstellen";
$TEXT{'sync_bad_user_password'} = "Fehler bei der Synchronisierung - Benutzername oder Passwort falsch";
$TEXT{'no_hostname'} = "Hostname nicht angegeben";
$TEXT{'no_rdir'} = "Remote-Verzeichnis nicht angegeben";
$TEXT{'no_vol'} = "Kein datenträgen ausgewählt";

#### Users ####
$TEXT{'users_manager'} = "Benutzerverwaltung";
$TEXT{'users_create'} = "Benutzer erstellen";
$TEXT{'users_id'} = "ID";
$TEXT{'users_name'} = "Benutzername";
$TEXT{'users_desc'} = "Beschreibung";
$TEXT{'users_groups'} = "Gruppen";
$TEXT{'users_actions'} = "Aktionen";
$TEXT{'users_password'} = "Passwort";
$TEXT{'users_password_retype'} = "Passwort wiederholen";
$TEXT{'users_created'} = "Benutzer erfolgreich erstellt";
$TEXT{'users_deleted'} = "Benutzer erfolgreich gelöscht";
$TEXT{'users_add'} = "Benutzer hinzufügen";
$TEXT{'users_reset'} = "Zurücksetzen";
$TEXT{'users_delete'} = "Benutzer löschen";
$TEXT{'users_settings'} = "Einstellungen";
$TEXT{'users_change_password'} = "Passwort ändern";
$TEXT{'users_passwords_do_no_match'} = "Passwörter stimmen nicht überein";
$TEXT{'users_password_must_exist'} = "Passwort erforderlich";
$TEXT{'users_user_must_exist'} = "Benutzer erforderlich";
$TEXT{'users_failed_to_add_user'} = "Benutzer konnte nicht angelegt werden";
$TEXT{'users_failed_to_add_samba_user'} = "Samba-Benutzer konnte nicht angelegt werden";
$TEXT{'users_failed_to_add_samba_user'} = "Samba-Benutzer konnte nicht angelegt werden";
$TEXT{'users_failed_to_delete_user'} = "Benutzer konnte nicht gelöscht werden";
$TEXT{'users_delete?'} = "Benutzer wirklich löschen?";
$TEXT{'users_change_password'} = "Passwort ändern";
$TEXT{'users_save_password'} = "Passwort speichern";
$TEXT{'users_password_changed'} = "Passwort erfolgreich geändert";
$TEXT{'users_save'} = "Speichern";
$TEXT{'users_settings_failed_to_save'} = "Einstellungen konnten nicht gespeichert werden";
$TEXT{'users_settings_saved'} = "Einstellungen erfolgreich gespeichert";


#### Groups ####
$TEXT{'groups_manager'} = "Gruppenverwaltung";
$TEXT{'groups_create'} = "Gruppe erstellen";
$TEXT{'groups_failed_to_add'} = "Gruppe konnte nicht angelegt werden";
$TEXT{'group_delete'} = "Gruppe löschen";
$TEXT{'group'} = "Gruppe";
$TEXT{'groups'} = "Gruppen";
$TEXT{'group_can_not_delete'} = "kann nicht gelöscht werden";
$TEXT{'groups_failed_to_delete'} = "Gruppe konnte nicht gelöscht werden";
$TEXT{'group_name'} = "Gruppenname";
$TEXT{'access_permission'} = "Zugriffsberechtigung";
$TEXT{'groups_settings'} = "Gruppeneinstellungen";
$TEXT{'groups_id'} = "Gruppen-ID";
$TEXT{'groups_name'} = "Gruppenname";
$TEXT{'groups_actions'} = "Aktionen";
$TEXT{'groups_delete?'} = "Gruppe wirklich löschen?";
$TEXT{'groups_add'} = "Gruppe hinzufügen";
$TEXT{'groups_reset'} = "Zurücksetzen";
$TEXT{'groups_deleted'} = "Gruppe erfolgreich gelöscht";
$TEXT{'groups_added'} = "Gruppe erfolgreich hinzugefügt";



#### Security ####
$TEXT{'security'} = "Sicherheit";
$TEXT{'access_control'} = "Zugriffskontrolle";
$TEXT{'security_help'} = " Zugriffskontrolle / Zugriffssteuerung<br><br> Zugriffe erlauben / verbieten die auf mit diesem Server verbinden können<br><br> - Alle Verbindungen erlauben.<br> - Alle Verbindungen verbieten, die in der Liste eingetragen sind.<br> - Alle Verbindungen erlauben, die in der Liste eingetragen sind<br><br> Format:<br> IP-Adresse: xxx.yyy.zzz.www<br> Netzwerk  : xxx.yyy.zzz.wwww/[1-32]<br>";
$TEXT{'enter_ip_or_network'} = "Eingabe der IP-Adresse oder Netzwerks, von der/dem Verbindungen zu deisem Server zugelassen/abgelehnt werden sollen";
$TEXT{'error_security_demo'} = "Keine Änderungen an ACL ist im Demo-Modus zugelassen";
