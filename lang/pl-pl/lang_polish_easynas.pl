
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
# This file is part of EasyNAS (c) created by Yariv Hakim 2012-2020
#
# Homepage    : https://www.easynas.org
#
#########################################################################

######  Dashboard ######

$TEXT{'dashboard'} = "Pulpit";
$TEXT{'sharing'} = "Udostęnianie Plików";
$TEXT{'services'} = "Usługi";


$TEXT{'easynas'} = "EasyNAS";
$TEXT{'yariv'} = "Yariv Hakim";
$TEXT{'username'} = "Użytkownik";
$TEXT{'password'} = "Hasło";
$TEXT{'please_wait'} = "Proszę Czekać....";
$TEXT{'not_authorized'} = "Nie masz uprawnień do użycia tej funkcji";
$TEXT{'edit'} = "Edycja";
$TEXT{'delete'} = "Kasuj";
$TEXT{'about'} = "O...";
$TEXT{'save'} = "Zapisz";
$TEXT{'reset'} = "Resetuj";
$TEXT{'create'} = "Utwórz";
$TEXT{'add'} = "Dodaj";
$TEXT{'performance'} = "Wydajność";
$TEXT{'web_system'} = "System";
$TEXT{'web_storage'} = "Magazyn";
$TEXT{'web_users'} = "Użytkownicy / Grupy";
$TEXT{'web_sharing'} = "Udostępnianie Plików";
$TEXT{'web_services'} = "Usługi Sieciowe";
$TEXT{'web_applications'} = "Aplikacje";
$TEXT{'about_help'} = "
<h1><center>EasyNAS</center></h1><br>
<h3><center>Version ".easynas_ver()."</center></h3><br><br>
<center>Copyright &copy; 2013-2020</center><br>
<h4><center><a href=\"https://www.easynas.org\"  target=\"new\" >https://www.easynas.org</a></center><h4>";

#### Search ####
$TEXT{'search'} = "Szukaj";

#### System Info ####
$TEXT{'sysinfo'} = "System Info";
$TEXT{'cpu'} = "CPU";
$TEXT{'vendor'} = "Dostawca";
$TEXT{'model'} = "Model";
$TEXT{'cache_size'} = "Rozmiar Cache";
$TEXT{'speed'} = "Prędkość";
$TEXT{'system'} = "System";
$TEXT{'os'} = "OS";
$TEXT{'architecture'} = "Architektura";
$TEXT{'firmware'} = "Firmware";
$TEXT{'filesystem'} = "System Plików";
$TEXT{'memory'} = "Pamięć";
$TEXT{'total_memory'} = "Całkowita Pamięć";
$TEXT{'free_memory'} = "Wolna Pamięć";
$TEXT{'total_swap_memory'} = "Całkowita Pamięć Swap";
$TEXT{'free_swap_memory'} = "Wolna Pamięć Swap";
$TEXT{'storage'} = "Magazyn";

#### Settings ####
$TEXT{'general_settings'} = "Ustawiena Główne";
$TEXT{'bad_system_port'} = "Zły Port Systemu";
$TEXT{'bad_secure_port'} = "Zły Port Zabezpieczeń";
$TEXT{'bad_web_port'} = "Zły Port Web";
$TEXT{'settings'} = "Ustawienia";
$TEXT{'date_time'} = "Data / Czas";
$TEXT{'access_list'} = "Lista Dostępu";
$TEXT{'host_name'} = "Nazwa Hosta";
$TEXT{'system_port'} = "Port Systemowy";
$TEXT{'secure_port'} = "Port Systemu Zabezpieczeń";
$TEXT{'change_settings_in_progress'} = "Trwa zmiana ustawień....";
$TEXT{'certificate'} = "Certifikat";
$TEXT{'cert_details'} = "Szczegóły Certyfikatu";
$TEXT{'no_cert'} = "Certifikatu nie znaleziono";
$TEXT{'bad_cert'} = "Zły Certifikat";
$TEXT{'upload'} = "Wgraj";
$TEXT{'error_updating_date'} = "Bład aktualizacji Daty / Czasu";
$TEXT{'error_settings_demo'} = "Nie można znienić ustawień na stronie demo";
$TEXT{'repositories'} = "Repozytoria";
$TEXT{'repository'} = "Repozytorium";
$TEXT{'enabled'} = "Włączone";
$TEXT{'disabled'} = "Wyłączone";
$TEXT{'enable'} = "Włącz";
$TEXT{'disable'} = "Wyłącz";

#### User Profile ####
$TEXT{'user_profile'} = "Profil Użytkownika";



#### Backup ####
$TEXT{'backup_restore'} = "Kopia zapasowa & Przywracanie";
$TEXT{'backup'} = "Kopia zapasowa";
$TEXT{'restore'} = "Przywracanie";
$TEXT{'file_name'} = "Nazwa pliku";
$TEXT{'backup_failed'} = "Błąd tworzenia kopii zapasowej";
$TEXT{'backup_completed'} = "Kopia zapasowa utworzona pomyślnie";
$TEXT{'restore_failed'} = "Przywracanie nieudane";
$TEXT{'testore_completed'} = "Przywracanie zakończone sukcesem";

#### Network settings ####
$TEXT{'network_setting'} = "Ustawienia Sieci";
$TEXT{'error_ip_demo'} = "Nie można zmienić IP na stronie demo";
$TEXT{'network_restart'} = "Zrestartuj serwer EasyNAS by zastosować zmiany.";

#### Scheduler ##########
$TEXT{'scheduler'} = "Harmonogram";
$TEXT{'snapshots'} = "Migawka";
$TEXT{'syncs'} = "Zdalna Synchronizacja";
$TEXT{'scrubs'} = "Czyszczenie Systemów Plików";
$TEXT{'powers'} = "Kontrola Zasilania";
$TEXT{'create_sc'} = "Utwórz Harmonogram";
$TEXT{'schedule_snapshot'} = "Harmonogram Migawek";
$TEXT{'schedule_sync'} = "Harmonogram Zdalnej Synchronizacji";
$TEXT{'schedule_scrub'} = "Harmonogram Czyszczenia";
$TEXT{'schedule_power'} = "Harmonogram Zasilania";
$TEXT{'no_vol_selected'} = "Nie wybrano Woluminu";
$TEXT{'sc_exists'} = "Nazwa Harmonogramu już istnieje!";
$TEXT{'control_type'} = "Typ Kontroli";
$TEXT{'error_restarting_sc'} = "Błąd restartu harmonogramu";
$TEXT{'delete_sc'} = "Kasuj Harmonogram";
$TEXT{'error_deleting_sc'} = "Błąd kasowania harmonogramu";
$TEXT{'update_sc'} = "Uaktualij Harmonogram"; 
$TEXT{'sc_name'} = "Nazwa Harmonogramu";
$TEXT{'remote_system'} = "System Zdalny";
$TEXT{'time'} = "Czas";
$TEXT{'date'} = "Data";
$TEXT{'day_of_week'} = "Dzień tygodnia";
$TEXT{'sc'} = "HARMONOGRAM";
$TEXT{'scs'} = "Harmonogramy";
$TEXT{'sc_name'} = "Nazwa";
$TEXT{'sc_task'} = "Zadanie";
$TEXT{'vol_name'} = "Nazwa Woluminu";
$TEXT{'fs_name'} = "Nazwa Systemu Plików";
$TEXT{'fs_delete'} = "Kasuj Systemu Plików";
$TEXT{'weekday'} = "Dni tygodnia";
$TEXT{'delete_sc?'} = "Na pewno usunąć harmonogram ?";

### NETWORK ###
$TEXT{'network_settings'} = "Ustawienia Sieciowe";
$TEXT{'network_interfaces'} = "Interfejs Sieciowy";
$TEXT{'interface'} = "Interfejs";
$TEXT{'state'} = "Stan";
$TEXT{'broadcast'} = "Rozgłoszenie";
$TEXT{'net_mask'} = "Maska";
$TEXT{'hardware_mac'} = "Adres MAC";
$TEXT{'dhcp'} = "DHCP";
$TEXT{'static'} = "Statyczny";
$TEXT{'ip_address'} = "Adres IP";
$TEXT{'subnet_mask'} = "Maska Podsieci";
$TEXT{'gateway'} = "Brama";
$TEXT{'domain'} = "Domena";
$TEXT{'pri_dns'} = "Podstawowy DNS";
$TEXT{'sec_dns'} = "Zapasowy DNS";
$TEXT{'state_up'} = "Góra";
$TEXT{'state_down'} = "Dół";
$TEXT{'error_ip_demo'} = "Nie można zmienić IP na stronie demo";
$TEXT{'network_restart'} = "Zrestartuj serwer EasyNAS by zastosować zmiany.";

#### Monitor ####
$TEXT{'cpu'} = "CPU";
$TEXT{'memory'} = "Pamięć";
$TEXT{'disk_io'} = "Dysk IO";
$TEXT{'network_band'} = "Przepustowość Sieci";


#### Power Managment ####
$TEXT{'power_management'} = "Zasilanie";
$TEXT{'shutdown_restart'} = "Wyłącz / Restartuj";
$TEXT{'error_restart_demo'} = "Nie można uruchomić ponownie na stronie demo";
$TEXT{'restart_system'} = "Restartuję System......";
$TEXT{'error_shutdown_demo'} = "Nie można wyłączyć na stronie demo";
$TEXT{'shutdown_system'} = "Wyłączam System.....";
$TEXT{'execute_immediately'} = "Natychmiastowe uruchomienie/wyłączenie systemu.";
$TEXT{'restart'} = "Restartuj";
$TEXT{'shutdown'} = "Wyłącz";
$TEXT{'close_service'} = "Zamykam Usługi.....";
$TEXT{'close_fs'} = "Odmontowuję System Plików.....";
$TEXT{'restart_are_u_sure'} = "Na pewno restartować ?";
$TEXT{'restart_help'} = "Masz zamiar uruchomić ponownie EasyNAS<br>
                         Zapisz wszystkie swoje pliki i zamknij otwarte usługi<br><br>
						 Naciśnij Restartuj gdy będziesz gotowy";
$TEXT{'shutdown_help'} = "Masz zamiar wyłączyć EasyNAS<br>
                         Zapisz wszystkie swoje pliki i zamknij otwarte usługi<br><br>
                         Naciśnij wyłącz gdy będziesz gotowy";

#### Firmware ####
$TEXT{'addons'} = "Dodatki";
$TEXT{'addon_installed'} = "Dodatek zainstalowany pomyślnie";
$TEXT{'addon_not_installed'} = "Błąd instalacji dodatku";
$TEXT{'addon_deleted'} = "Dodatek usunięty pomyślnie";
$TEXT{'addon_not_deleted'} = "Błąd kasowania dodatku";
$TEXT{'addon_updated'} = "Dodatek zaktualizowany pomyślnie";
$TEXT{'addon_not_updated'} = "Błąd aktualizacji dadtku";
$TEXT{'firmware_upgrade'} = "Aktualizacja Firmware";
$TEXT{'firmware'} = "Firmware";
$TEXT{'lang'} = "Język";
$TEXT{'other_apps'} = "Inne Aplikacje";
$TEXT{'multimedia'} = "Multi Media";
$TEXT{'component'} = "Komponenty";
$TEXT{'author'} = "Autor";
$TEXT{'version'}="Wersja";
$TEXT{'current_version'}="Bieżąca Wersja";
$TEXT{'new_version'}="Nowa Wersja";
$TEXT{'package_name'} = "Nazwa pakietu";
$TEXT{'update'} = "Aktualizuj";
$TEXT{'refresh'} = "Odśwież";
$TEXT{'refresh_failed'} = "Odświeżanie nieudane";
$TEXT{'installed_version'} = "Instalowana Wersja";
$TEXT{'current_version'} = "Bieżąca Wersja";
$TEXT{'install'} = "Instaluj";
$TEXT{'upgrade'} = "Uaktualnij";
$TEXT{'uninstall'} = "Odinstaluj";
$TEXT{'install_addon'} = "Instaluj Dodatek";
$TEXT{'uninstall_addon'} = "Odinstaluj Dodatek";
$TEXT{'upgrade_addon'} = "Uaktualnij Dodatek";
$TEXT{'check_for_update'} = "Sprawdź aktualizacje";
$TEXT{'cheking_firmware_availble'} = "Sprawdź dostępną wersję firmware: ";
$TEXT{'latest_firmware'} = "Twój system ma już najnowszą dostępną wersję firmware";
$TEXT{'download_latest_version_here'} = "Pobierz najnowszą wersję z  <a href=http://www.easynas.org/download target=New_Page>here</a>";
$TEXT{'upgrade_in_progress'} = "Aktualizacja w toku.........";
$TEXT{'downloading_firmware'} = "Pobieranie firmware.......";
$TEXT{'installing_new_firmware'} = "Instaluję nowy firmware......";
$TEXT{'firmware_upgraded'}="Firmware Zaktualizowany";
$TEXT{'error_upgrading'}="Błąd aktualizacji, spróbuj ponownie później";
$TEXT{'error_connecting'}="Błąd podłączenia do repozytorium EasyNAS, proszę spróbować później";
$TEXT{'failed_to_refresh_repo'}="Błąd odświeżania repozytorium EasyNAS. Proszę spróbować później";
$TEXT{'failed_to_install_addon'} = "Nie udało się zainstalować dodatku";
$TEXT{'refresh_repo'}="Odśwież Repozytorium";
$TEXT{'failed_to_delete_addon'} = "Nie udało się skasować dodatku";
$TEXT{'install_addon?'} = "Zainstalować Dodatek ?";
$TEXT{'update_addon?'} = "Uaktualnić Dodatek ?";
$TEXT{'delete_addon?'} = "Skasować Dodatek ?";
$TEXT{'update_all'} = "Uaktualnij Wszystko";
$TEXT{'firmware_update_available'} = "Nowe aktualizacje dostęne";
$TEXT{'firmware_here'} = " kliknij tutaj, aby zaktualizować";
$TEXT{'firmware_refreshed'} = "Repositoria odświeżone";


#### Disk ####
$TEXT{'free'} = "Wolne";
$TEXT{'used'} = "Użyto";
$TEXT{'system'} = "System";
$TEXT{'failed'} = "Nieudane";
$TEXT{'disk_manager'} = "Menadżer Dysku";
$TEXT{'disk_performace'} = "Wydajność Dysku";
$TEXT{'testing'} = "Testowanie";
$TEXT{'rerun_test'} = "Testuj Ponownie";
$TEXT{'disk_performance_help'} = "Test wydajności dysku sprawdzi wydajność odczytu dysku.";
$TEXT{'error_updating_param'} = "Błąd aktualizacji parameterów dysku";
$TEXT{'error_formating_disk'} = "Błąd Formatowania Dysku";
$TEXT{'disk_format_success'} = "Dysk sformatowany poprawnie";
$TEXT{'disk_update_success'} = "Dysk uaktualniony poprawnie";
$TEXT{'physical_disks'} = "Dyski Fizyczne";
$TEXT{'disk'} = "Dysk";
$TEXT{'size'} = "Rozmiar";
$TEXT{'status'} = "Status";
$TEXT{'model_number'} = "Model Number";
$TEXT{'serial_number'} = "Numer Seryjny";
$TEXT{'firmware_version'} = "Wersja Firmware";
$TEXT{'actions'} = "Akcja";
$TEXT{'disk_format_are_u_sure'} = "Czy na pewno formatować dysk ?";
$TEXT{'disk_test_are_u_sure'} = "Czy na pewno chcesz testować dysk ?";
$TEXT{'disk_format'} = "Format";
$TEXT{'test_performance'} = "Test Wydajności";
$TEXT{'disk_distribution'} = "Disk Distribution";
$TEXT{'disk_settings'} = "Ustawienia Dysku";
$TEXT{'multi_count'} = "Multi Count:";
$TEXT{'io_supprt'} = "IO Support:";
$TEXT{'read_only'} = "Tylko Odczyt:";
$TEXT{'read_ahead'} = "Read Ahead:";

#### File System ####
$TEXT{'fs'} = "System Plików";
$TEXT{'cancel'} = "Anuluj";
$TEXT{'resume'} = "Wznów";
$TEXT{'snapshot'} = "Migawka";
$TEXT{'filesystems'} = "System Plików";
$TEXT{'fs_manager'} = "Menadżer SystemU Plików";
$TEXT{'better'} = "Lepszy";
$TEXT{'faster'} = "Szybszy";
$TEXT{'none'} = "Nic";
$TEXT{'health'} = "Zdrowie";
$TEXT{'good'} = "Dobry";
$TEXT{'degreded'} = "Zdegradowany";
$TEXT{'mount'} = "Zamontowany";
$TEXT{'unmount'} = "Odmontowany";
$TEXT{'fs_name'} = "Nazwa Systemu Plików";
$TEXT{'remove_hd'} = "Usuń HD";
$TEXT{'replace_hd'} = "Zamień HD";
$TEXT{'source_hd'} = "Źródłowy HD";
$TEXT{'target_hd'} = "Docelowy HD";
$TEXT{'failed_to_remove_hd'} = "Nie można usunąć HD";
$TEXT{'fs_hd_removed'} = "HD usunięty poprawnie";
$TEXT{'fs_hd_added'} = "HD dodany poprawnie";
$TEXT{'fs_hd_replaced'} = "HD zamieniony poprawnie";
$TEXT{'fs_failed_to_replace'} = "NIe udało się zastąpić HD";
$TEXT{'add_hd'} = "Dodaj HD";
$TEXT{'failed_to_add_HD'} = "Nie udało się dodać HD";
$TEXT{'repair_hd'} = "Napraw HD";
$TEXT{'fs_need_to_be_unmounted'} = "System plików musi zostać odmontowany";
$TEXT{'fs_need_to_be_mounted'} = "FSystem plików musi zostać zamontowany";
$TEXT{'check&repair_hd'} = "Sprawdź & Napraw HD";
$TEXT{'create_fs'} = "Utwórz System Plików";
$TEXT{'no_disks_were_selected'} = "Nie wybrano dysków";
$TEXT{'no_fs_name_was_entered'} = "Nie wprowadzono nazwy systemu plików";
$TEXT{'reserved_fs'} = "ROOT jest nazwą zarezerwowaną";
$TEXT{'raid_0_require_two'} = "Raid 0 wymaga co najmniej dwóch dysków";
$TEXT{'raid_1_require_two'} = "Raid 1 wymaga co najmniej dwóch dysków";
$TEXT{'raid_10_require_four'} = "Raid 10 wymaga co najmniej czterech dysków";
$TEXT{'raid_5_require_three'} = "Raid 5 wymaga co najmniej trzech dysków";
$TEXT{'raid_6_require_four'} = "Raid 6 wymaga co najmniej czterech dysków";
$TEXT{'raid_the_same'} = "Poziom RAID jest taki sam, nie jest wymagane żadne działanie.";
$TEXT{'raid_require_force'} = "Przechodzenie między poziomami rajdu zmniejszy integralność, musisz wymusić tę zmianę.";
$TEXT{'failed_creating_directory'} = "Nie udało się utworzyć katalogu.";
$TEXT{'failed_creating_fs'} = "Nie udało się utworzyć systemu plików.";
$TEXT{'failed_mounting_fs'} = "Nie udało się zamontować systemu plików.";
$TEXT{'mount_fs'} = "Zamontuj System Plików";
$TEXT{'unmount_fs'} = "Odmontuj System Plików";
$TEXT{'failed_unmounting_fs'} = "Nie udało się odmontować System Plików.";
$TEXT{'no_free_disk'} = "Brak dostęnych wolnych dysków";
$TEXT{'fs_name'} = "Nazwa";
$TEXT{'raid_profile'} = "Raid Profil";
$TEXT{'compression'} = "Kompresja";
$TEXT{'disks'} = "Dyski";
$TEXT{'ssd_optimization'} = "Optymizacja SSD";
$TEXT{'auto_mount'} = "Auto Montowanie";
$TEXT{'auto_defrag'} = "Auto Defrag";
$TEXT{'mount_option'} = "Opcje Montowania";
$TEXT{'file_system_name'} = "Nazwa Systemu Plików";
$TEXT{'raid_level'} = "Poziom Raid";
$TEXT{'raid_profile'} = "Profil Raid";
$TEXT{'force_raid_change'} = "Wymuś Zmianę Raid";
$TEXT{'change_raid'} = "Zmiana Raid";
$TEXT{'fs_mount_options'} = "Opcje Montowania";
$TEXT{'fs_disks'} = "Dyski";
$TEXT{'number'} = "Numer";
$TEXT{'disk'} = "Dysk";
$TEXT{'total_size'} = "Całkowity Rozmiar";
$TEXT{'used'} = "Użyto";
$TEXT{'status'} = "Status";
$TEXT{'remove_hd?'} = "Czy na pewno chcesz usunąć dysk twardy ?";
$TEXT{'repair_hd?'} = "Czy na pewno chcesz nareperować dysk twardy ?";
$TEXT{'check_repair_complete'} = "Sprawdzenie & Naprawa zakończona";
$TEXT{'add_hd'} = "Dodaj Dysk Twardy";
$TEXT{'no_free_disks_available'} = "Brak wolnych dysków";
$TEXT{'drives'} = "Dyski";
$TEXT{'fs_limit'} = "Limit Przydziału Systemu Plików";
$TEXT{'0_no_limit'} = "(Wprowadź 0 dla braku limitu)";
$TEXT{'failed_limit'} = "Nie udało się ustawić limitu przydziału dla systemy plików";
$TEXT{'filesystem_contain_vol'} = "System Plików zawiera Woluminy";
$TEXT{'filesystem_not_changed'} = "Nazwa Systemu Plików nie została zmieniona";
$TEXT{'fs_created'} = "Systemu Plików utworzony poprawnie";


#### Volumes ####
$TEXT{'vol_manager'} = "Menadżer Woluminów";
$TEXT{'create_vol'} = "Utwórz Wolumin";
$TEXT{'no_vol_name'} = "Nie wprowadzono nazwy Woluminu";
$TEXT{'no_fs_selected'} = "Nie wybrano Systemu Plików";
$TEXT{'delete_vol'} = "Kasuj Wolumin";
$TEXT{'faild_to_delete_vol'} = "Nie udalo się skasować woluminu";
$TEXT{'create_snapshot'} = "Utwórz Migawkę";
$TEXT{'no_snapshot_name'} = "Nie wprowadzono nazwy migawki";
$TEXT{'failed_to_add_snapshot'} = "Nie udało się dodać migawki";
$TEXT{'failed_to_change_owner'} = "Nie udało się zmienić właściciela";
$TEXT{'failed_to_change_permission'} = "Nie udało się zmienić uprawnień";
$TEXT{'vol_name'} = "Nazwa Woluminu";
$TEXT{'user_owner'} = "Właściciel Użytkownika ";
$TEXT{'group_owner'} = "Właściciel Grupy";
$TEXT{'user_permission'} = "Uprawnienia Użytkownika";
$TEXT{'group_permission'} = "Uprawnienia Grupy";
$TEXT{'others_permission'} = "Pozostałe Uprawnienia";
$TEXT{'snapshot_name'} = "Nazwa Migawki";
$TEXT{'vols'} = "Woluminy";
$TEXT{'vol'} = "Wolumin";
$TEXT{'id'} = "ID";
$TEXT{'vol_name'} = "Nazwa Woluminu";
$TEXT{'size'} = "Rozmiar";
$TEXT{'delete_vol?'} = "Czy na pewno chcesz usunąć wolumin ?";
$TEXT{'no_schedule_name'} = "Nie wprowadzono nazwy harmonogramu.";
$TEXT{'failed_add_vol'} = "Nie udało się dodać woluminu.";
$TEXT{'group_created'} = "Grupa zostałą utworzona pomyślnie";
$TEXT{'group_deleted'} = "Grupa została pomyślnie usunięta";


#### Sync ####
$TEXT{'sync'} = "Synchronizuj Woluminy";
$TEXT{'hostname'} = "Nazwa Hosta";
$TEXT{'rdir'} = "Zdalny Katalog";
$TEXT{'password'} = "Password";
$TEXT{'sync_option'} = "Opcje Syncchronizacji";
$TEXT{'sync_complete'} = "Synchronizacja Kompletna";
$TEXT{'failed_to_sync'} = "Synchronizacja NIE UDANA !";
$TEXT{'sync_could_not_connect'} = "Nie można połączyć z serwerem RSync";
$TEXT{'sync_bad_user_password'} = "Błąd Synchronizacji - Nieprawidłowy Użytkownik lub Hasło";
$TEXT{'no_hostname'} = "Nie wprowadzono nazwy Hosta";
$TEXT{'no_rdir'} = "Nie wprowadzono zdalnego katalogu";
$TEXT{'no_vol'} = "Nie wybrano Woluminu";

#### Users ####
$TEXT{'users_manager'} = "Menadżer Urzytkowników";
$TEXT{'create_user'} = "Utwórz Użytkownika";
$TEXT{'passwords_do_not_match'} = "Hasła nie pasują !!!.";
$TEXT{'admin_account'} = "Konto Administracyjne";
$TEXT{'all_groups'} = "Wszystkie grupy";
$TEXT{'failed_to_add_user'} = "Nie można dodać użytkownika";
$TEXT{'failed_to_change_password'} = "Nie można zmienić hasła";
$TEXT{'failed_to_add_samba_user'} = "Nie można dodać użytkownika Samby";
$TEXT{'delete_user'} = "Usuń użytkownika";
$TEXT{'user_admin_cant_be_delete'} = "Użytkownika admin nie można usunąć.";
$TEXT{'user_admin_cant_be_changed'} = "Użytkownika admin nie można zmienić.";
$TEXT{'failed_to_delete_user'} = "Nie można skasować użytkownika";
$TEXT{'cant_change_admin_password'} = "Nie można zmienić hasła admina na stronie demo";
$TEXT{'passwords_do_not_match'} = "Hasła nie pasują";
$TEXT{'password_must_exist'} = "Hasło musi istnieć";
$TEXT{'change_password'} = "Zmień Hasło";
$TEXT{'one_group_needed'} = "Co najmniej jedna grupa jest wymagana";
$TEXT{'failed_to_change_samba_password'} = "Błąd przy zmianie hasła do Samby";
$TEXT{'failed_to_delete_samba_user'} = "Błąd przy usunięciu użytkownika Samby";
$TEXT{'change_settings'} = "Zmiana Ustawień";
$TEXT{'failed_to_change_settings'} = "Nie można zapisać zmian.";
$TEXT{'users'} = "Użytkownicy";
$TEXT{'user_name'} = "Nazwa użytkownika";
$TEXT{'name'} = "Nazwa";
$TEXT{'desc'} = "Opis";
$TEXT{'uid'} = "UID";
$TEXT{'group'} = "Grupa";
$TEXT{'groups'} = "Groupy";
$TEXT{'password'} = "Hasło";
$TEXT{'password_again'} = "Powtórz Hasło";
$TEXT{'easynas_admin'} = "EasyNAS Admin";
$TEXT{'delete_user?'} = "Czy na pewno usunąć użytkownika ?";
$TEXT{'user_settings'} = "USTAWIENIA UŻYTKOWNIKA";
$TEXT{'user_created'} = "Użytkownik został poprawnie utworzony";
$TEXT{'user_deleted'} = "Użytkownik został poprawnie usunięty"; 



#### Groups ####
$TEXT{'groups_manager'} = "Menadżer Grup";
$TEXT{'create_group'} = "Utwórz Grupę";
$TEXT{'failed_to_add_group'} = "Nie udało się dodać grupy";
$TEXT{'delete_group'} = "Kasuj Grupę";
$TEXT{'group'} = "Grupa";
$TEXT{'groups'} = "Grupy";
$TEXT{'can_not_deleted'} = "nie można usunąć";
$TEXT{'failed_to_delete_group'} = "Nie udało się usunąc grupy";
$TEXT{'group_name'} = "Nazwa Grupy";
$TEXT{'access_permission'} = "Uprawnienia Dostępu";
$TEXT{'groups_settings'} = "Ustawienia Grupy";
$TEXT{'gid'} = "GID";
$TEXT{'delete_group?'} = "Na pewno chcesz usunąć grupę ?";

#### Security ####
$TEXT{'security'} = "Zabezpieczenia";
$TEXT{'access_control'} = "Kontrola dostępu";
$TEXT{'security_help'} = "";
$TEXT{'enter_ip_or_network'} = "Wprowadź adres IP lub sieć, z której połączenia z tym serwerem będą dozwolone lub odrzucone";
$TEXT{'error_security_demo'} = "Nie mogę zmienić ACL na stronie demo";
