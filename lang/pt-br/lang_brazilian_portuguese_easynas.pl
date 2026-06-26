
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

$TEXT{'username'} = "Usuário";
$TEXT{'password'} = "Senha";
$TEXT{'please_wait'} = "Por favor, aguarde...";
$TEXT{'not_authorized'} = "Você não está autorizado a usar esta função";
$TEXT{'edit'} = "Editar";
$TEXT{'delete'} = "Eliminar";
$TEXT{'about'} = "Sobre";
$TEXT{'save'} = "Salvar";
$TEXT{'create'} = "Criar";
$TEXT{'add'} = "Adicionar";
$TEXT{'index_help'} = "<h1><center>EasyNAS</center></h1><br>
                       <h3><center>$firmware_ver</center></h3><br><br>
                       <center>Copyright &copy; 2013-2017</center><br>
                       <h4><center><a href=\"http://www.easynas.org\"  target=\"new\" >http://www.easynas.org</a></center><h4>";


#### Search ####
$TEXT{'search'} = "Pesquisa";
$TEXT{'search_help'} = "Menu de pesquisa habilita você a pesquisar um texto em uma das seguintes seções:<br><br>
                        Gerenciador de Sistema de Arquivos<br>
                        Gerenciador de Volume<br>
    			Usuários<br>
			Grupos<br><br>
			Você irá ver somente as linhas que contêm a sua pesquisa<br>
			e será capaz de fazer qualquer ação como nos menus regulares.";
			

#### System Info ####
$TEXT{'system_info'} = "Informação do Sistema";
$TEXT{'cpu'} = "CPU";
$TEXT{'vendor'} = "Fornecedor";
$TEXT{'model'} = "Modelo";
$TEXT{'cache_size'} = "Tamanho Cache";
$TEXT{'speed'} = "Velocidade";
$TEXT{'system'} = "Sistema";
$TEXT{'os'} = "SO";
$TEXT{'architecture'} = "Arquitetura";
$TEXT{'firmware'} = "Firmware";
$TEXT{'filesystem'} = "Sistema de Arquivos";
$TEXT{'memory'} = "Memória";
$TEXT{'total_memory'} = "Memória Total";
$TEXT{'free_memory'} = "Memória Livre";
$TEXT{'total_swap_memory'} = "Memória de Troca Total";
$TEXT{'free_swap_memory'} = "Memória de Troca Livre";
$TEXT{'storage'} = "Armazenamento";
$TEXT{'sysinfo_help'} = "<p>Este menu mostra informações do sistema como CPU, Memória, SO instalado e armazenamento.<p>";


#### Settings ####
$TEXT{'general_settings'} = "Configurações Gerais";
$TEXT{'bad_system_port'} = "Porta do Sistema Errônea";
$TEXT{'bad_secure_port'} = "Porta de Segurança Errônea";
$TEXT{'bad_web_port'} = "Porta Web Errônea";
$TEXT{'settings'} = "Configurações";
$TEXT{'date_time'} = "Data / Hora";
$TEXT{'access_list'} = "Lista de Acesso";
$TEXT{'host_name'} = "Nome do Host";
$TEXT{'system_port'} = "Porta do Sistema";
$TEXT{'secure_port'} = "Porta de Segurança Sistema";
$TEXT{'change_settings_in_progress'} = "Alteração de configurações em progresso...";
$TEXT{'certificate'} = "Certificado";
$TEXT{'cert_details'} = "Detalhes do Certificado";
$TEXT{'no_cert'} = "Nenhum certificado localizado";
$TEXT{'upload'} = "Envio";
$TEXT{'error_updating_date'} = "Atualização de Data/Hora errada";
$TEXT{'settings_help'} = "<p>Este menu habilita você a alterar as configurações gerais da funcionalidade NAS.<br> 
A alteração de qualquer configuração será salva mesmo reiniciando o sistema. <br><br>
Altere as seguintes configurações: <br><br>
Nome do Host - o nome do NAS na rede. <br>
Porta do Sistema - o nro. da porta deste gerenciador GUI que irá ouvir. <br>
Data - a data corrente. <br>
Hora - a hora corrente. <br>
Lista de Acesso - Previne o acesso não autorizado ao gerenciador web GUI.<br>
Certificado - Permite alterar o certificado SSL padrão. </p>"; 
$TEXT{'error_settings_demo'} = "Não é possivel alterar as configurações em site demonstração.";


#### Network settings ####
$TEXT{'network_setting'} = "Configurações de rede";
$TEXT{'error_ip_demo'} = "Não pode alterar IP no site demonstração";
$TEXT{'network_restart'} = "Reinicie o servidor EasyNAS para que as alterações sejam aceitas.";
$TEXT{'network_help'} = "Este menu irá ajudá-lo a alterar as configurações de rede em sua placa de rede. <br>
						 Selecione uma interface para ajustar os parâmetros IP. <br><br><br>
						 Nota: As mesmas configurações também podem ser alteradas na console.";

#### Scheduler ##########
$TEXT{'scheduler'} = "Agendador";
$TEXT{'snapshots'} = "Snapshots";
$TEXT{'syncs'} = "Syncs Remota";
$TEXT{'scrubs'} = "Sistema de Arquivos Scrub";
$TEXT{'powers'} = "Controle de Energia";
$TEXT{'create_sc'} = "Criar Agendador";
$TEXT{'schedule_snapshot'} = "Agenda Snapshot";
$TEXT{'schedule_sync'} = "Agenda Sync Remota";
$TEXT{'schedule_scrub'} = "Agenda Scrub";
$TEXT{'schedule_power'} = "Agenda de Controle de Energia";
$TEXT{'no_vol_selected'} = "Nenhum volume foi selecionado";
$TEXT{'sc_exists'} = "Nome do agendador já existe";
$TEXT{'control_type'} = "Tipo de Controle";
$TEXT{'error_restarting_sc'} = "Erro de inicialização do agendador";
$TEXT{'delete_sc'} = "Eliminar Agendador";
$TEXT{'error_deleting_sc'} = "Erro ao eliminar agendador";
$TEXT{'update_sc'} = "Atualizar Agendador"; 
$TEXT{'sc_name'} = "Nome da Agendador";
$TEXT{'remote_system'} = "Sistema Remoto";
$TEXT{'time'} = "Hora";
$TEXT{'date'} = "Data";
$TEXT{'day_of_week'} = "Dia da semana";
$TEXT{'sc'} = "AGENDA";
$TEXT{'scs'} = "Agendas";
$TEXT{'sc_name'} = "Nome";
$TEXT{'sc_task'} = "Tarefa";
$TEXT{'vol_name'} = "Nome do Volume";
$TEXT{'fs_name'} = "Nome Sistema de Arquivos";
$TEXT{'weekday'} = "Dia Semana";
$TEXT{'delete_sc?'} = "Tem certeza de que deseja eliminar o agendador ?";
$TEXT{'schedule_help'} = "A agenda pode criar tarefas em tempo hábil<br>
						  Crie uma agenda para cada dia, mês, ano, hora, dia da semana ou qualquer combinação entre eles<br>
 			  Tipos de agendas que podem se criadas:<br>
                          Snapshot - O snapshot irá ser criado automaticamente com o nome: Volume.Data<br>
 			  Scrub - Encontrar erros no sistema de arquivos e corrigí-los";



 

#### Power Managment ####
$TEXT{'power_management'} = "Gerenciamento de Energia";
$TEXT{'shutdown_restart'} = "Desligar / Reiniciar";
$TEXT{'error_restart_demo'} = "Não é possivel reiniciar em site demonstração";
$TEXT{'restart_system'} = "Reiniciando o sistema...";
$TEXT{'error_shutdown_demo'} = "Não é possivel desligar em site demonstração";
$TEXT{'shutdown_system'} = "Desligando o sistema...";
$TEXT{'execute_immediately'} = "Execute a reinicialização/desligamento do sistema imediatamente!";
$TEXT{'poewer_help'} = "Use este menu para desligar ou reiniciar o seu NAS";


#### Firmware ####
$TEXT{'firmware_ugpgrade'} = "Atualização do Firmware";
$TEXT{'firmware'} = "Firmware";
$TEXT{'upgrade_in_progress'} = "Atualização em progresso...";
$TEXT{'downloading_firmware'} = "Baixando o firmware...";
$TEXT{'installing_new_firmware'} = "Instalando novo firmware...";
$TEXT{'firmware_upgraded'} = "Atualização do firmware com sucesso!";
$TEXT{'error_upgrading'} = "Erro na atualização do firmware - Tente novamente mais tarde, por favor.";
$TEXT{'check_for_update'} = "Verifique por atualização";
$TEXT{'cheking_firmware_availble'} = "Verificando firmware mais recente disponível em EasyNAS...";
$TEXT{'could_not_get_connection'} = "Não foi possível obter conexão com servidores EasyNAS.";
$TEXT{'latest_firmware'} = "Seu sistema possui a última versão disponível do firmware";
$TEXT{'download_latest_version_here'} = "Baixe a última versão <a href=http://www.easynas.org/download target=New_Page>aqui</a>";
$TEXT{'firmware_help'} = "Recurso de atualização de firmware estará habilitado para atualização de nova versão recente. <br>
Sua versão atual será verificada contra a versão recente da EasyNAS, e você saberá se uma atualização está disponível. <br>
A atualização requer conexão direta com a internet. Não é necessário a reinicialização após a atualização. <br>
Versão principal inclui, normalmente, atualização do kernel; então nova instalação será necessária."; 



#### Disk ####
$TEXT{'free'} = "Livre";
$TEXT{'used'} = "Usado";
$TEXT{'system'} = "Sistema";
$TEXT{'failed'} = "Falhado";
$TEXT{'disk_manager'} = "Gerenciador de Disco";
$TEXT{'disk_performace'} = "Desempenho do Disco";
$TEXT{'testing'} = "Teste";
$TEXT{'rerun_test'} = "Reexecução Teste";
$TEXT{'disk_performance_help'} = " Teste de desempenho de disco verificará o desempenho de leitura de um disco.";
$TEXT{'error_updating_param'} = "Erro na atualização dos parâmetros de disco";
$TEXT{'physical_disks'} = "Discos Físicos";
$TEXT{'disk'} = "Disco";
$TEXT{'size'} = "Tamanho";
$TEXT{'status'} = "Estado";
$TEXT{'model_number'} = "Nro. Modelo";
$TEXT{'serial_number'} = "Nro. Serial";
$TEXT{'firmware_version'} = "Versão Firmware";
$TEXT{'actions'} = "Ações";
$TEXT{'test_performance'} = "Teste de Desempenho";
$TEXT{'disk_distribution'} = "Distribuição do Disco";
$TEXT{'disk_settings'} = "Configurações de Disco";
$TEXT{'multi_count'} = "Multi Count:";
$TEXT{'io_supprt'} = "Suporte de E/S:";
$TEXT{'read_only'} = "Somente Leitura:";
$TEXT{'read_ahead'} = "Read Ahead:";
$TEXT{'disk_help1'} = "Selecione um disco para alterar as configurações padrão";
$TEXT{'disk_help2'} = "Alterar a configuração do disco: <br><br>
                       Read Ahead - Contagem de setor de sistema de arquivos (software) de leitura antecipada. <br>
                       Isto é usado para melhorar o desempenho em leituras sequenciais de arquivos 
					   grandes, por pré-busca antecipada deste blocos adicionais
					   sendo necessário para a tarefa em execução. Diversos discos IDE possuem uma 
					   função read-ahead construída em separado, o qual aumenta esta função read-ahead
					   no sistema de arquivos (software)..";
                      

#### File System ####
$TEXT{'fs'} = "Sistema de Arquivos";
$TEXT{'fs_manager'} = "Gerenciador Sistema de Arquivos";
$TEXT{'remove_hd'} = "Remover HD";
$TEXT{'failed_to_remove_hd'} = "Falha ao remover HD";
$TEXT{'add_hd'} = "Adicionar HD";
$TEXT{'failed_to_add_HD'} = "Falha ao adicionar HD";
$TEXT{'repair_hd'} = "Reparar HD";
$TEXT{'fs_need_to_be_unmounted'} = "Sistema de Arquivos necessita ser desmontado";
$TEXT{'check&repair_hd'} = "Verifica e Repara HD";
$TEXT{'create_fs'} = "Criar Sistema de Arquivos";
$TEXT{'no_disks_were_selected'} = "Discos não foram selecionados";
$TEXT{'create_fs'} = "Cria Sistema de Arquivos";
$TEXT{'no_fs_name_was_entered'} = "Nenhum nome de Sistema de Arquivos foi introduzido";
$TEXT{'reserved_fs'} = "O ROOT é um nome reservado";
$TEXT{'raid_0_require_two'} = "Raid 0 requer ao menos dois discos";
$TEXT{'raid_1_require_two'} = "Raid 1 requer ao menos dois discos";
$TEXT{'raid_10_require_four'} = "Raid 10 requer ao menos quatro discos";
$TEXT{'raid_5_require_three'} = "Raid 5 requer ao menos três discos";
$TEXT{'raid_6_require_four'} = "Raid 6 requer ao menos quatro discos";
$TEXT{'failed_creating_directory'} = "Falha na criação de um diretório.";
$TEXT{'failed_creating_fs'} = "Falha na criação de um Sistema de Arquivos.";
$TEXT{'failed_mounting_fs'} = "Falha na montagem de um Sistema de Arquivos.";
$TEXT{'mount_fs'} = "Montagem Sistema de Arquivos";
$TEXT{'unmount_fs'} = "Desmontagem Sistema de Arquivos";
$TEXT{'failed_unmounting_fs'} = "Falha na desmontagem Sistema de Arquivos.";
$TEXT{'create_fs'} = "Cria Sistema de Arquivos";
$TEXT{'no_free_disk'} = "Não há discos livres!";
$TEXT{'fs_name'} = "Nome";
$TEXT{'raid_profile'} = "Perfil de Raid";
$TEXT{'compression'} = "Compressão";
$TEXT{'disks'} = "Discos";
$TEXT{'ssd_optimization'} = "Otimização de SSD";
$TEXT{'auto_mount'} = "Montagem automática";
$TEXT{'auto_defrag'} = "Defragmentação automática";
$TEXT{'mount_option'} = "Opções de Montagem";
$TEXT{'file_system_name'} = "Nome Sistema de Arquivos";
$TEXT{'raid_level'} = "Nível de Raid";
$TEXT{'raid_profile'} = "Perfil de Raid";
$TEXT{'force_raid_change'} = "Alteração de Raid forçada";
$TEXT{'change_raid'} = "Alterar Raid";
$TEXT{'fs_mount_options'} = "Opções de Montagem";
$TEXT{'fs_disks'} = "Discos";
$TEXT{'number'} = "Número";
$TEXT{'disk'} = "Disco";
$TEXT{'total_size'} = "Tamanho Total";
$TEXT{'used'} = "Usado";
$TEXT{'status'} = "Estado";
$TEXT{'remove_hd?'} = "Tem certeza que deseja remover o disco rígido ?";
$TEXT{'repair_hd?'} = "Tem certeza que deseja reparar o disco rígido ?";
$TEXT{'add_hd'} = "Adiciona Disco Rígido";
$TEXT{'no_free_disks_available'} = "Não há discos livres disponíveis!";
$TEXT{'drives'} = "Discos";
$TEXT{'create_fs'} = "Criar Sistema de Arquivos";
$TEXT{'fs_limit'} = "Limite de quota no Sistema de Arquivos";
$TEXT{'0_no_limit'} = "(Entre 0 para sem limites)";
$TEXT{'failed_limit'} = "Falha na limitação de quota no Sistema de Arquivos";
$TEXT{'fs_help1'} = "Um Sistema de Arquivos consiste de um ou mais discos. <br>
		     Cada Sistema de Arquivos pode ter características como: Compressão, Redundância e Disponibilidade. <br>
                     O Sistema de Arquivos não poderá ser eliminado se este contiver volumes.";
$TEXT{'fs_help2'} = "Adicione um novo Sistema de Arquivos <br><br>
                     Nome do Sistema de Arquivos - O nome do Sistema de Arquivos <br> 
                     JBOD (Just Bunch Of Disks): Flexibility without redundancy <br>
					 Perfil de Raid - Considerando o ganho de desempenho e redundâcia extra, escolha o nível de Raid que deseja:<br>
		     RAID 0  (Disk Striping - Distribuição em discos).: Ganho de desempenho mas sem redundância (proteção) <br>
		     RAID 1  (Disk Mirroring - Espelhamento de discos): Permite falha em um disco <br>
		     RAID 10 (Disk Mirroring and Striping - Espelhamento e distribuição em discos): Permite falha de um disco em cada par de RAID 1 <br>
		     RAID 5  (Disk Striping with parity - Distribuição em discos com paridade): Permite falha de um disco <br>
		     RAID 6  (Disk Striping with double parity - Distribuição em discos com dupla paridade): Permite falha em dois discos <br>
	
		     Compressão (Compression) - Reduz o tamanho dos dados com a seleção: Melhor (Better), Faster (Rápido) ou None (Nenhum). <br>
		     Discos (Disks) - Lista de discos disponíveis que podem ser usados para este Sistema de Arquivos. <br>
		     Otimização SSD (SSD Optimization) - Ao usar disco SSD, esta opção irá otimizar o uso para uma vida mais longa. <br> 
             Defragmentação automática (Auto Defrag) - Irá detectar gravações aleatórias em arquivos existentes e começará a defragmentar em segundo plano. <br>
		     Montagem Automática (Auto Mount) - Esta opção irá montar automaticamente um Sistema de Arquivos";	
$TEXT{'fs_help3'} = "Altere as configurações do Sistema de Arquivos:<br><br>
                     Altere o Nome -  Mude o nome e as ligações do Sistema de Arquivos e de quaisquer volumes conectado a ele.<br>
		     Altere o Raid - Mude o nivel de raid que o Sistema de Arquivos tem. No caso de haver uma redução na integridade, você deverá selecionar forçar a alteração do raid. <br>
		     Opções de Montagem - Monte ou desmonte um Sistema de Arquivos com ou sem compressão ou otimização SSD.<br>
		     Discos do Sistema de Arquivos - Balanceie, corrija, ajuste ou remova um disco de um conjunto de discos do Sistema de Arquivos.<br>";


#### Volumes ####
$TEXT{'vol_manager'} = "Gerenciador de Volume";
$TEXT{'create_vol'} = "Criar Volume";
$TEXT{'no_vol_name'} = "Nenhum volume foi digitado";
$TEXT{'no_fs_selected'} = "Nenhum Sistema de Arquivos foi selecionado";
$TEXT{'delete_vol'} = "Elimina Volume";
$TEXT{'faild_to_delete_vol'} = "Falha ao eliminar volume";
$TEXT{'create_snapshot'} = "Criar Snapshot";
$TEXT{'no_snapshot_name'} = "Nenhum nome de Snapshot foi digitado";
$TEXT{'failed_to_add_snapshot'} = "Falha ao adicionar snapshot";
$TEXT{'failed_to_change_owner'} = "Falha ao alterar o proprietário";
$TEXT{'failed_to_change_permission'} = "Falha ao alterar a permissão";
$TEXT{'vol_name'} = "Nome Volume";
$TEXT{'user_owner'} = "Usuário Proprietário";
$TEXT{'group_owner'} = "Proprietário do Grupo";
$TEXT{'user_permission'} = "Permissão do Usuário";
$TEXT{'group_permission'} = "Permissão do Grupo";
$TEXT{'others_permission'} = "Outras Permissões";
$TEXT{'snapshot_name'} = "Nome Snapshot";
$TEXT{'vols'} = "Volumes";
$TEXT{'vol'} = "Volume";
$TEXT{'id'} = "ID";
$TEXT{'vol_name'} = "Nome Volume";
$TEXT{'size'} = "Tamanho";
$TEXT{'delete_vol?'} = "Você tem certeza que deseja eliminar o volume ?";
$TEXT{'no_schedule_name'} = "Nenhum nome de agendamento foi digitado.";
$TEXT{'failed_add_vol'} = "Falha na adição de um volume.";
$TEXT{'vol_help1'} = "Um ou mais volumes podem ser criados em um Sistema de Arquivos <br>
	 	      O volume irá herdar as características de um Sistema de Arquivos como: Compressão, Redundância, Disponibilidade. <br>
                      O volume estará disponível somente se o Sistema de Arquivos estiver montado.";
$TEXT{'vol_help2'} = "Adicione ou altere as seguintes configurações:<br><br>
		      Usuário e grupo proprietário irá determinar quem pode ler e gravar arquivos<br>
		      Permissão nos arquivos irá determinar quais serão as permissões de usuário, grupo e outros.<br>
                      Quota no Sistema de Arquivos irá limitar a quantidade máxima de armazenamento";


#### Sync ####
$TEXT{'sync'} = "Sincronia de Volumes";
$TEXT{'hostname'} = "Nome do Host";
$TEXT{'rdir'} = "Diretório Remoto";
$TEXT{'password'} = "Senha";
$TEXT{'sync_option'} = "Opção de Sincronia";
$TEXT{'sync_complete'} = "Sincronia concluída";
$TEXT{'failed_to_sync'} = "Falha ao sincronizar";
$TEXT{'sync_could_not_connect'} = "Não pode conectar ao servidor RSync";
$TEXT{'sync_bad_user_password'} = "Falha ao sincronizar - Usuário ou senha incorreta";
$TEXT{'no_hostname'} = "Nome do Host não foi digitado";
$TEXT{'no_rdir'} = "Diretório remoto não foi digitado";
$TEXT{'no_vol'} = "Volume não foi selecionado";
$TEXT{'sync_help'} = "Use a opção de sincronia para copiar a partir de um daemon rsync remoto um diretório completo<br>
Use os seguintes parâmetros:<br><br>
Nome do Host - O IP ou nome do host de um servidor remoto<br>
Diretório Remoto - O nome do diretório do servidor remoto que você está indo sincronizar a partir dele.<br>
Nome do Usuário - O usuário remoto<br>
Senha - A senha remota<br>
Sistema de Arquivos / Volume - O Nome do volume que você deseja copiar os dados<br>
Opção de Sincronia - O protocolo usado para sincronia<br><br>
Nota: O servidor remoto deve possuir instalado o RSync para usar esta opção";

#### Users ####
$TEXT{'users_manager'} = "Gerenciador de Usuários";
$TEXT{'create_user'} = "Criar Usuário";
$TEXT{'passwords_do_not_match'} = "Senhas não correspondem!";
$TEXT{'failed_to_add_user'} = "Falha ao adicionar usuário";
$TEXT{'failed_to_change_password'} = "Falha a alterar a senha";
$TEXT{'failed_to_add_samba_user'} = "Falha ao adicionar o usuário ao Samba";
$TEXT{'delete_user'} = "Eliminar Usuário";
$TEXT{'user_admin_cant_be_delete'} = "Usuário admin não poderá ser eliminado.";
$TEXT{'user_admin_cant_be_changed'} = "Usuário admin não poderá ser alterado.";
$TEXT{'failed_to_delete_user'} = "Falha ao eliminar o usuário";
$TEXT{'cant_change_admin_password'} = "Não pode alterar a senha do admin em um site demonstração";
$TEXT{'passwords_do_not_match'} = "Senhas não correspondem!";
$TEXT{'password_must_exist'} = "Senha deve existir";
$TEXT{'change_password'} = "Alterar Senha";
$TEXT{'one_group_needed'} = "Ao menos um grupo é necessário";
$TEXT{'failed_to_change_samba_password'} = "Falha ao alterar a senha do Samba";
$TEXT{'change_settings'} = "Mudar Configurações";
$TEXT{'failed_to_change_settings'} = "Falha ao alterar as configurações.";
$TEXT{'users'} = "Usuários";
$TEXT{'user_name'} = "Nome Usuário";
$TEXT{'name'} = "Nome";
$TEXT{'desc'} = "Descrição";
$TEXT{'uid'} = "UserID";
$TEXT{'group'} = "Grupo";
$TEXT{'groups'} = "Grupos";
$TEXT{'password'} = "Senha";
$TEXT{'password_again'} = "Senha novamente";
$TEXT{'easynas_admin'} = "Administrador EasyNAS";
$TEXT{'delete_user?'} = "Você tem certeza de que deseja eliminar o usuário ?";
$TEXT{'user_settings'} = "CONFIGURAÇÕES DE USUÁRIO";
$TEXT{'users_help'} = "Use este menu para adicionar/eliminar contas.";
		      

#### Groups ####
$TEXT{'groups_manager'} = "Gerenciador de Grupos";
$TEXT{'create_group'} = "Criar Grupo";
$TEXT{'failed_to_add_group'} = "Falha ao adicionar grupo";
$TEXT{'delete_group'} = "Eliminar Grupo";
$TEXT{'group'} = "Grupo";
$TEXT{'groups'} = "Grupos";
$TEXT{'can_not_deleted'} = "Não pode ser eliminado";
$TEXT{'failed_to_delete_group'} = "Falha ao eliminar o grupo";
$TEXT{'group_name'} = "nome do Grupo";
$TEXT{'access_permission'} = "Permissão de Acesso";
$TEXT{'groups_settings'} = "Configurações de Grupos";
$TEXT{'gid'} = "GroupID";
$TEXT{'delete_group?'} = "Você tem certeza de que deseja eliminar o grupo ?";
$TEXT{'groups_help'} = "Use este menu para adicionar/eliminar grupos.<br>
                        ou para alterar as configurações do grupo";
$TEXT{'groups_help2'} = "Digite o nome do grupo e os papéis que este grupo terá acesso:<br><br>
                         SISTEMA (SYSTEM)           - Configurações gerais do NAS.<br>
                         ARMAZENAMENTO (STORAGE)    - Permite adicionar/alterar/eliminar os Sistemas de Arquivos e os Volumes<br>
                         USUÁRIOS (USERS)           - Gerencia usuário e grupos<br>
                         COMPARTILHAMENTO (SHARING) - Configura os protocolos de compartilhamento de arquivos<br>
                         SERVIÇOS (SERVICES)        - Configura os serviços de rede.";



#### Security ####
$TEXT{'security'} = "Segurança";
$TEXT{'access_control'} = "Controle de Acesso";
$TEXT{'security_help'} = "";
$TEXT{'enter_ip_or_network'} = "Digite o endereço IP ou a rede na qual as conexões para este servidor serão permitidas ou rejeitadas";
$TEXT{'error_security_demo'} = "Não é possível alterar ACL em site demonstração";
$TEXT{'security_help'} = "Controle de Acesso <br><br>
						  Permitir ou negar o acesso ao menu de administração de IPs ou da rede<br><br>
                          Permitir todas as conexões: Qualquer um pode acessar o menu de administração. <br>
                          Negar conexão a partir da lista: Qualquer um da lista não pode acessar o menu de administração, o restante pode.<br>
                          Permitir conexão a partir da lista: Qualquer um da lista pode acessar o menu de administração, o restante não pode.<br><br>
                          A lista de IP/rede precisa estar no seguinte formato:<br>
                          IP: x.y.z.w <br>
                          Sub-rede (subnet):  x.y.z.w/[1-32] <br>";
			

1;


