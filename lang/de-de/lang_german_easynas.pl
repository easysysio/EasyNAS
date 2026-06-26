
# @FILE@
# Version @PROJECT_VERSION@
#
# @MYNAME_UC@ is free software: You can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# This file is part of @MYNAME_UC@ (c) created by @PROJECT_AUTHOR@ 2012-@YEAR@
#
# Homepage    : @PROJECT_URL@
# Sourceforge : @PROJECT_SF_URL@
#
#########################################################################

$TEXT{'easynas'} = "EasyNAS";
$TEXT{'yariv'} = "Yariv Hakim";
$TEXT{'username'} = "Benutzername";
$TEXT{'password'} = "Passwort";
$TEXT{'please_wait'} = "Bitte warten....";
$TEXT{'not_authorized'} = "Benutzung dieser Funktion nicht erlaubt";
$TEXT{'edit'} = "Bearbeiten";
$TEXT{'delete'} = "Löschen";
$TEXT{'about'} = "Über";
$TEXT{'save'} = "Speichern";
$TEXT{'reset'} = "Reset";
$TEXT{'create'} = "Erstellen";
$TEXT{'add'} = "Hinzufügen";
$TEXT{'web_system'} = "System";
$TEXT{'web_storage'} = "Speicher";
$TEXT{'web_users'} = "Benutzer / Gruppen";
$TEXT{'web_sharing'} = "File Sharing";
$TEXT{'web_services'} = "Netzwerkdienste";
$TEXT{'web_applications'} = "Programme";
$TEXT{'index_help'} = "
<h1><center>EasyNAS</center></h1><br>
<h3><center>$firmware_ver</center></h3><br><br>
<center>Copyright &copy; 2013-2017</center><br>
<h4><center><a href=\"http://www.easynas.org\"  target=\"new\" >http://www.easynas.org</a></center><h4>";

#### Search ####
$TEXT{'search'} = "Suchen";
$TEXT{'search_help'} = "
Durchsuchen folgender Rubriken ist möglich:<br><br>
Dateisystemverwaltung<br>
Datenträgerverwaltung<br>
Benutzerverwaltung<br>
Gruppenverwaltung<br><br>";

#### System Info ####
$TEXT{'sysinfo'} = "System Information";
$TEXT{'cpu'} = "CPU";
$TEXT{'vendor'} = "Hersteller";
$TEXT{'model'} = "Modell";
$TEXT{'cache_size'} = "Cache Size";
$TEXT{'speed'} = "Geschwindiwgkeit";
$TEXT{'system'} = "System";
$TEXT{'os'} = "Kernel";
$TEXT{'architecture'} = "Architektur";
$TEXT{'firmware'} = "Firmware";
$TEXT{'filesystem'} = "Dateisystem";
$TEXT{'memory'} = "Speicher (RAM/Swap)";
$TEXT{'total_memory'} = "Gesamtkapazität RAM";
$TEXT{'free_memory'} = "Freier RAM-Speicher";
$TEXT{'total_swap_memory'} = "Gesamtkapazität Swap";
$TEXT{'free_swap_memory'} = "Freier Swap-Speicher";
$TEXT{'storage'} = "Speicher";
$TEXT{'sysinfo_help'} = "
<p>Hier werden Systeminformationen wie CPU, Arbeits- und Swapspeicher, Betriesbsystem- und Hardwareinformationen angezeigt.<p>";

#### Settings ####
$TEXT{'general_settings'} = "Allgemeine Einstellungen";
$TEXT{'bad_system_port'} = "Ungültiger System Port";
$TEXT{'bad_secure_port'} = "Ungültiger Secure Port";
$TEXT{'bad_web_port'} = "Ungültiger Web Port";
$TEXT{'settings'} = "Einstellungen";
$TEXT{'date_time'} = "Datum / Uhrzeit";
$TEXT{'access_list'} = "Zugriffsliste";
$TEXT{'host_name'} = "Hostname";
$TEXT{'system_port'} = "System Port";
$TEXT{'secure_port'} = "System Secure Port";
$TEXT{'change_settings_in_progress'} = "Änderungen werden angewendet....";
$TEXT{'certificate'} = "Zertifikat";
$TEXT{'cert_details'} = "Zertifikat Details";
$TEXT{'no_cert'} = "Kein Zertifikat gefunden";
$TEXT{'upload'} = "Upload";
$TEXT{'error_updating_date'} = "Fehler bei Aktualisierung von Datum / Uhrzeit";
$TEXT{'error_settings_demo'} = "Einstellungen können im Demo-Modus nicht verändert werden";
$TEXT{'settings_help'} = "
<p>Allgemeine Einstellungen der NAS Funktionen.<br>
Alle Einstellungen werden erst nach einem Neustart aktiv.<br><br>
Einstellungsmöglichkeiten:<br><br>
Hostname - Anzeigename von EasyNAS im Netzwerk.<br>
System Port - Portnummer an dem die Weboberfläche läuft.<br>
Datum - Einstellung vom Datum.<br>
Uhrzeit - Einsteunng der Uhrzeit<br>
Zugriffsliste - Zugriffsmöglichkeiten für die Weboberfläche einstellen.<br>
Zertifikat - Ermöglicht das ändern des voreingestellten SSL-Zertifikats.</p>"; 

#### Backup ####
$TEXT{'backup_restore'} = "Sicherung & Wiederherstellung";
$TEXT{'backup'} = "Sicherung";
$TEXT{'restore'} = "Wiederherstellung";
$TEXT{'file_name'} = "Dateiname";
$TEXT{'backup_help'} = "
No text available in the moment";

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
$TEXT{'sc_name'} = "Aufgabenname";
$TEXT{'remote_system'} = "Remote System";
$TEXT{'time'} = "Zeit";
$TEXT{'date'} = "Datum";
$TEXT{'day_of_week'} = "Wochentag";
$TEXT{'sc'} = "SCHEDULE";
$TEXT{'scs'} = "Aufgaben";
$TEXT{'sc_name'} = "Name";
$TEXT{'sc_task'} = "Task";
$TEXT{'vol_name'} = "Volume Name";
$TEXT{'fs_name'} = "Dateisystem";
$TEXT{'weekday'} = "Wochentag";
$TEXT{'delete_sc?'} = "Aufgabe wirklich löschen?";
$TEXT{'schedule_help'} = "
Der Aufgabenplaner ermöglich das zeitgesteuerte erledigen von Aufgaben<br>
Aufgaben können Minütlich, Stündlich, Täglich, Wöchentlich, Monatlich oder Jährlich erstellt werden.<br>
Auch die Kombination aus allen steht zur Verfügung.<br>
Folgende Aufgaben können erstellt werden:<br>
Schattenkopie - Schnappshuss von Daten. Das Sicherungsformat besteht aus Name und Datum<br>
Remote-Synchronisierung - Synchronisierung über das Internet.<br>
Dateisystembereinigung - Fehlerbehebung an einem Dateisystem<br>
Power Control - Zeitgesteuertes Neustarten / herunterfahren des Servers";

### NETWORK
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
$TEXT{'network_help'} = "
Netzwerkkarteneinstellungen anzeigen oder bearbeiten.<br>
Um Änderungen vozunehmen die Netzwerkkarte auswählen.<br><br><br>
Anmerkung: Alle Einstellungen können auch über die Konsole geändert werden.";

#### Power Managment ####
$TEXT{'power_management'} = "Power Management";
$TEXT{'shutdown_restart'} = "Herunterfahren / Neustart";
$TEXT{'error_restart_demo'} = "Neustart im Demo-Modus nicht verfügbar";
$TEXT{'restart_system'} = "Neustart des Systems......";
$TEXT{'error_shutdown_demo'} = "Herunterfahren im Demo-Modus nicht verfügbar";
$TEXT{'shutdown_system'} = "Herunterfahren des Systems.....";
$TEXT{'execute_immediately'} = "System Herunterfahren / Neustarten.";
$TEXT{'restart'} = "Neustart";
$TEXT{'shutdown'} = "Herunterfahren";
$TEXT{'power_help'} = "
Hier kann der NAS neu gestartet oder ausgeschaltet werden";

#### Firmware ####
$TEXT{'firmware_ugpgrade'} = "Firmware Upgrade";
$TEXT{'firmware'} = "Firmware";
$TEXT{'component'} = "Component";
$TEXT{'author'} = "Author";
$TEXT{'installed_version'} = "Installierte Version";
$TEXT{'current_version'} = "Derzeitige Version";
$TEXT{'upgrade_in_progress'} = "Upgrade wird ausgeführt.........";
$TEXT{'downloading_firmware'} = "Herunterladen der Firmware.......";
$TEXT{'installing_new_firmware'} = "Installieren der neuen Firmware......";
$TEXT{'firmware_upgraded'} = "Firmware-Upgrade erfolgreich";
$TEXT{'error_upgrading'} = "Fehler bei dem Firmware-Upgrade - Versuchen Sie es später noch einmal";
$TEXT{'check_for_update'} = "Nach Update suchen";
$TEXT{'cheking_firmware_availble'} = "Suche die aktuellste Firmware von EasyNAS: ......  ";
$TEXT{'could_not_get_connection'} = "Verbindung mit dem EasyNAS nicht erfolgreich.";
$TEXT{'latest_firmware'} = "Das System ist bereits auf den neusten Stand";
$TEXT{'download_latest_version_here'} = "Download der aktuellsten Version <a href=http://www.easynas.org/download target=New_Page>hier</a>";
$TEXT{'firmware_help'} = "
Hier kann EasyNAS auf eine neue Version aktualisiert werden.<br>
Falls eine aktuellere Version verfügbar ist, wird dies hier angezeigt.<br>
Der Aktualisierungsvorgang benötigt eine Internetverbindung.<br>
Bei Aktualisierungen von EasyNAS ist kein Neustart nach der Aktualisierung notwendig.<br>";

#### Disk ####
$TEXT{'free'} = "Frei";
$TEXT{'used'} = "Genutzt";
$TEXT{'system'} = "System";
$TEXT{'failed'} = "Fehlerhaft";
$TEXT{'disk_manager'} = "Festplattenverwaltung";
$TEXT{'disk_performace'} = "Festplatten-Performance";
$TEXT{'testing'} = "Test";
$TEXT{'rerun_test'} = "Test wiederholen";
$TEXT{'disk_performance_help'} = "Der Festplatten-Performance-Test prüft die Lesegeschwindigkeit eines Datenträgers.";
$TEXT{'error_updating_param'} = "Fehler bei der Aktualisierung der Disk Parameter";
$TEXT{'physical_disks'} = "Physikalische Festplatten";
$TEXT{'disk'} = "Disk";
$TEXT{'size'} = "Größe";
$TEXT{'status'} = "Status";
$TEXT{'model_number'} = "Modellnummer";
$TEXT{'serial_number'} = "Seriennummer";
$TEXT{'firmware_version'} = "Firmware Version";
$TEXT{'actions'} = "Aktionen";
$TEXT{'test_performance'} = "Leistungstest";
$TEXT{'disk_distribution'} = "Disk Distribution";
$TEXT{'disk_settings'} = "Festplatteneinstellungen";
$TEXT{'multi_count'} = "Multi Count:";
$TEXT{'io_supprt'} = "I/O Unterstützung:";
$TEXT{'read_only'} = "Nur lesen:";
$TEXT{'read_ahead'} = "Read Ahead:";
$TEXT{'disk_help1'} = "
Wählen Sie einen Datenträger um seine Einstellungen zu ändern";
$TEXT{'disk_help2'} = "
Datenträgereinstellungen:<br><br>
Read Ahead - Sektorengröße des vorauslesen vom Dateisystem.<br>
Dies dient zur Verbesserung der Leistung der sequenziellen Lesevorgängen von großen Dateien.";

#### File System ####
$TEXT{'fs'} = "Dateisystem";
$TEXT{'fs_manager'} = "Dateisystem Manager";
$TEXT{'remove_hd'} = "Festplatte entfernen";
$TEXT{'failed_to_remove_hd'} = "Fehler beim entfernen der Festplatte";
$TEXT{'add_hd'} = "Festplatte hinzufügen";
$TEXT{'failed_to_add_HD'} = "Fehler beim hinzufügen von Festplatte";
$TEXT{'repair_hd'} = "Festplatte reparieren";
$TEXT{'fs_need_to_be_unmounted'} = "Dateisystem muss entladen werden";
$TEXT{'check&repair_hd'} = "Festplattencheck & Reparatur";
$TEXT{'create_fs'} = "Dateisystem erstellen";
$TEXT{'no_disks_were_selected'} = "Keine Festplatte ausgewählt";
$TEXT{'no_fs_name_was_entered'} = "Kein Name für das Daeisystem angegeben";
$TEXT{'reserved_fs'} = "ROOT ist ein reservierter Name";
$TEXT{'raid_0_require_two'} = "Raid 0 benötigt minimum zwei Festplatten";
$TEXT{'raid_1_require_two'} = "Raid 1 benötigt minimum zwei Festplatten";
$TEXT{'raid_10_require_four'} = "Raid 10 benötigt minimum vier Festplatten";
$TEXT{'raid_5_require_three'} = "Raid 5 benötigt minimum drei Festplatten";
$TEXT{'raid_6_require_four'} = "Raid 6 benötigt minimum vier Festplatten";
$TEXT{'failed_creating_directory'} = "Fehler bei Verzeichniserstellung.";
$TEXT{'failed_creating_fs'} = "Fehler bei Erstellung von Dateisystem.";
$TEXT{'failed_mounting_fs'} = "Fehler bei Einbindung von Dateisystem.";
$TEXT{'mount_fs'} = "Dateisystem bereitstellen";
$TEXT{'unmount_fs'} = "Dateisystem aushängen";
$TEXT{'failed_unmounting_fs'} = "Fehler beim aushängen des Dateisystems.";
$TEXT{'create_fs'} = "Dateisystem erstellen";
$TEXT{'fs_delete'} = "Dateisystem löschen";
$TEXT{'no_free_disk'} = "Keine freie Festplatte verfügbar";
$TEXT{'fs_name'} = "Name";
$TEXT{'raid_profile'} = "Raid-Profil";
$TEXT{'compression'} = "Komprimmierung";
$TEXT{'disks'} = "Festplatten";
$TEXT{'ssd_optimization'} = "SSD Optimierung";
$TEXT{'auto_mount'} = "Auto Einbindung";
$TEXT{'auto_defrag'} = "Auto Defragmentierung";
$TEXT{'mount_option'} = "Mount Optionen";
$TEXT{'file_system_name'} = "Dateisystemname";
$TEXT{'raid_level'} = "Raid Level";
$TEXT{'force_raid_change'} = "Erzwinge Raid-Änderung";
$TEXT{'change_raid'} = "Raid anwenden";
$TEXT{'fs_mount_options'} = "Mount Options";
$TEXT{'fs_disks'} = "Festplatten";
$TEXT{'number'} = "Nummer";
$TEXT{'disk'} = "Festplatte";
$TEXT{'total_size'} = "Gesamtgröße";
$TEXT{'used'} = "Genutzt";
$TEXT{'status'} = "Status";
$TEXT{'remove_hd?'} = "Wollen Sie wirklich die Festplatte entfernen ?";
$TEXT{'repair_hd?'} = "Wollen Sie wirklich die Festplatte reparieren ?";
$TEXT{'add_hd'} = "Festplatte hinzufügen";
$TEXT{'no_free_disks_available'} = "Keine freie Festplatte verfügbar";
$TEXT{'drives'} = "Laufwerke";
$TEXT{'create_fs'} = "Dateisystem erstellen";
$TEXT{'fs_limit'} = "Dateisystem Kontingent";
$TEXT{'0_no_limit'} = "(0 = Keine Grenze)";
$TEXT{'failed_limit'} = "Fehler bei Limitierung des Kontingents";
$TEXT{'fs_help1'} = "
Eine Dateisystem bestehen eine oder mehreren Festplattenn.<br>
Jedes Dateisystem kann folgende Eigenschaften haben: Kompression, Redundanz und Verfügbarkeit.<br>
Ein Dateisystem kann nicht gelöscht werden, wenn es Datenträger enthält.";
$TEXT{'fs_help2'} = "
Dateisystem hinzufügen<br><br>
Dateisystemname - Der Name des Dateisystems<br> 	
Raid Profil - Wählen sie einen passendes Raid Profil:<br>
JBOD (Just Bunch Of Disks): Flexibilität ohne Redundanz<br>
RAID 0  : Hohe Performance, aber keine Ausfallsicherheit<br>
RAID 1  : Alle Daten werden gespiegelt.<br>
RAID 10 : bietet hohe Performance wie RAID 0, kombiniert mit der Datensicherheit von RAID 1<br>
RAID 5  : Paritätsinformationen werden auf alle Datenträger verteilt, fällt ein Datenträger aus<br>
und wird dieser durch einen neuen ersetzt kann der ursprüngliche Inhalt rekonstruiert werden<br>
RAID 6  : Doppelte Paritätsinformationen erlauben den Ausfall von zwei Datenträgern ohne Datenverlust.<br>
Kompresion - Komprimierung der Daten : Besser (Gut), Schnell (wenig) oder Keine<br>
Datenträger - Liste der verfügbaren Datenträger, die zu diesem Dateisystem verwendet werden können<br>
SSD Optimimierung - Bei der Verwendung von SSD-Laufwerk wird diese Option die Nutzung für eine längere Lebensdauer optimieren.<br> 
Auto Defragmentierung - Automatisches defragmentieren im Hintergrund.<br>
Auto Einbindung - Automatisches einbinden des Dateisystems";
$TEXT{'fs_help3'} = "
Dateisystemeinstellungen:<br><br>
Namensänderung - Änderung der Links und des Dateisystemsname und alle damit verbundenen Datenträger.<br>
Change Raid - RAID-Level Anderung. Im Fall einer Reduzierung der Integrität, muss die Option 'erzwingen' gewählt werden.<br>
Mount Optionen - Ein- Aushängen eines Dateisystems mit oder ohne Komprimierung oder SSD Optimierung.<br>
Dateisystem - Balance, Fehlerbehebung, Tuning oder das entfernen aus einem Datenträgerverbunds.<br>";

#### Volumes ####
$TEXT{'vol_manager'} = "Datenträgerverwaltung";
$TEXT{'create_vol'} = "Datenträger erstellen";
$TEXT{'no_vol_name'} = "Datenträgername nicht angegeben";
$TEXT{'no_fs_selected'} = "Kein Dateisystem ausgewählt";
$TEXT{'delete_vol'} = "Datenträger entfernen";
$TEXT{'faild_to_delete_vol'} = "Fehler beim entfernen des Datenträgers";
$TEXT{'create_snapshot'} = "Schattenkopie erstellen";
$TEXT{'no_snapshot_name'} = "Kein Schattenkopiename angegeben";
$TEXT{'failed_to_add_snapshot'} = "Fehler beim hinzufügen der Schattenkopie";
$TEXT{'failed_to_change_owner'} = "Fehler bei Besitzeränderung";
$TEXT{'failed_to_change_permission'} = "Fehler beim ändern der Berechtigung";
$TEXT{'vol_name'} = "Datenträgername";
$TEXT{'user_owner'} = "Benutzerberechtigung";
$TEXT{'group_owner'} = "Gruppenberechtigung";
$TEXT{'user_permission'} = "User Permission";
$TEXT{'group_permission'} = "Group Permission";
$TEXT{'others_permission'} = "Andere Berechtigung";
$TEXT{'snapshot_name'} = "Schattenkopiename";
$TEXT{'vols'} = "Datenträger";
$TEXT{'vol'} = "Datenträger";
$TEXT{'id'} = "ID";
$TEXT{'vol_name'} = "Datenträgername";
$TEXT{'size'} = "Größe";
$TEXT{'delete_vol?'} = "Wollen sie wirklich den Datenträger löschen ?";
$TEXT{'no_schedule_name'} = "Name der Aufgabe nicht vergeben.";
$TEXT{'failed_add_vol'} = "Fehler beim  hinzufügen des Datenträgers.";
$TEXT{'vol_help1'} = "
Ein oder mehrere Datenträger können in einem Dateisystem erstellt werden<br>
The volume will inherite the FileSystem features like: compression, redunduncy, availabity. <br>
The volume will be available only if the FileSystem will be mounted.";
$TEXT{'vol_help2'} = "
Add or change the following settings:<br><br>
Benutzer & Gruppen : Benutzer- Gruppenfreigaben<br>
Dateiberechtigung : Genauere festlegung der Benutzer- und Gruppenfreigaben.<br>
Kontingent : Festlegung des maximal reservierten Speichers";

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
$TEXT{'sync_help'} = "
Diese Synchronisation ermöglicht von einem remote Rsync-Daemon ein vollständiges Verzeichnis zu spiegeln<br>
Folgenden Parameter stehen zur Verfügung:<br><br>
Host name - IP-Adresse oder Host Name des Remote-Servers<br>
Remote-Verzeichnis - Verzeichnis vom Remote-Server<br>
Benutzername - Berechtigter Benutzer auf dem Remote-Servers<br>
Passwort - Das Passwort des Benutzers<br>
Dateisystem/Datenträger - Zielverzeichnis / Zieldatenträger<br>
Sync-Option - Synchronisierungsprotokoll<br><br>
Anmerkung: Der remote-Server muss Rsync installiert haben";

#### Users ####
$TEXT{'users_manager'} = "Benutzerverwaltung";
$TEXT{'create_user'} = "Benutzer erstellen";
$TEXT{'passwords_do_not_match'} = "Passwörter stimmen nicht überein.";
$TEXT{'failed_to_add_user'} = "Fehler bei Benutzererstellung";
$TEXT{'failed_to_change_password'} = "Fehler bei Passwortänderung";
$TEXT{'failed_to_add_samba_user'} = "Fehler bei Erstellung des Samba-Benutzers";
$TEXT{'delete_user'} = "Benutzer löschen";
$TEXT{'user_admin_cant_be_delete'} = "Administrator kann nicht gelöscht werden.";
$TEXT{'user_admin_cant_be_changed'} = "Administrator kann nicht geändert werden.";
$TEXT{'failed_to_delete_user'} = "Fehler bei Benutzerlöschung";
$TEXT{'cant_change_admin_password'} = "Administratorpasswort kann im Demo-Modus nicht geändert werden";
$TEXT{'passwords_do_not_match'} = "Passwörter stimmen nicht überein";
$TEXT{'password_must_exist'} = "Passwort muss angegebn werden";
$TEXT{'change_password'} = "Passwort ändern";
$TEXT{'one_group_needed'} = "Eine Benutzergruppe ist erforderlich";
$TEXT{'failed_to_change_samba_password'} = "Fehler bei Änderung des Samba-Passworts";
$TEXT{'change_settings'} = "Einstellungen ändern";
$TEXT{'failed_to_change_settings'} = "Fehler bei Einstellungsänderung.";
$TEXT{'users'} = "Benutzer";
$TEXT{'user_name'} = "Benutzername";
$TEXT{'name'} = "Name";
$TEXT{'desc'} = "Beschreibung";
$TEXT{'uid'} = "UID";
$TEXT{'group'} = "Gruppe";
$TEXT{'groups'} = "Gruppen";
$TEXT{'password'} = "Passwort";
$TEXT{'password_again'} = "Passwortwiederholung";
$TEXT{'easynas_admin'} = "EasyNAS Administrator";
$TEXT{'delete_user?'} = "Wollen Sie wirklich den Benutzer entfernen ?";
$TEXT{'user_settings'} = "Benutzereinstellungen";
$TEXT{'users_help'} = "
Bearbeiten der Benutzerkonten.";

#### Groups ####
$TEXT{'groups_manager'} = "Gruppenverwaltung";
$TEXT{'create_group'} = "Gruppe erstellen";
$TEXT{'failed_to_add_group'} = "Fehler bei Gruppenerstellung";
$TEXT{'delete_group'} = "Gruppe entfernen";
$TEXT{'can_not_deleted'} = "Kann nicht entfernt werden";
$TEXT{'failed_to_delete_group'} = "Fehler beim löschen der Gruppe";
$TEXT{'group_name'} = "Gruppenname";
$TEXT{'access_permission'} = "Zugriffsberechtigung";
$TEXT{'groups_settings'} = "Gruppeneinstellungen";
$TEXT{'gid'} = "GID";
$TEXT{'delete_group?'} = "Wollen Sie wirklich die Gruppe entfernen ?";
$TEXT{'groups_help'} = "
Bearbeitung von Gruppen und Gruppeneinstellungen.<br>";
$TEXT{'groups_help2'} = "
Hier können die Gruppenberechtigungen wie folgt eingestellt werden:<br><br>
System - Allgemeine Einstellungen von EasyNAS.<br>
Speicher - Bearbeitung von Dateisystemen und Datenträgern<br>
Benutzer - Benutzer- Gruppenverwaltung<br>
Dateifreigabe - Konfiguration der Freigaben<br>
Dienste - Konfiguration der installierten Dienste.";

#### Security ####
$TEXT{'security'} = "Sicherheit";
$TEXT{'access_control'} = "Zugriffskontrolle";
$TEXT{'enter_ip_or_network'} = "Eingabe der IP-Adresse oder Netzwerks, von der/dem Verbindungen zu deisem Server zugelassen/abgelehnt werden sollen";
$TEXT{'error_security_demo'} = "Keine Änderungen an ACL ist im Demo-Modus zugelassen";
$TEXT{'security_help'} = "
Zugriffskontrolle / Zugriffssteuerung<br><br>
Zugriffe erlauben / verbieten die auf mit diesem Server verbinden können<br><br>
- Alle Verbindungen erlauben.<br>
- Alle Verbindungen verbieten, die in der Liste eingetragen sind.<br>
- Alle Verbindungen erlauben, die in der Liste eingetragen sind<br><br>
Format:<br>
IP-Adresse: xxx.yyy.zzz.www<br>
Netzwerk  : xxx.yyy.zzz.wwww/[1-32]<br>";
