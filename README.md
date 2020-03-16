Скрипт предназначен для организации блокировки от перебора из access.log'ов nginx при помощи iptables, без изменения самих настроек nginx и iptables.  
## Принцип работы:  
1. Лог парсится по дате и времени и выбираются записи за определённое время в минутах указанное при запуске скрипта.  
2. Из лога выбираются только ip, сортируются, считаются и самое большое количество запросов с одного IP записывается в файл __/etc/ipbans/reqests-count.txt__ в формате "<count> <ip>"  
3. Из этого файла забирается количество и проверяется превышает ли оно порог  
4. Если превышает и IP не забанен ранее - IP Блокируется через iptables, если нет - проверяется нужно ли разбанить кого-то из ранее заблокированных  
5. Заблокированный IP вместе с датой и параметрами отбора заносится в файл лога, __/etc/ipbans/state.log__
***
## Установка и использование скрипта:  
1. Склонить репозиторий или просто скопировать скрипт  
2. Создать директорию __/etc/ipbans__  
3. Создать в ней файл __/etc/ipbans/ignore_ip.list__ и внести в него IP которые никак нельзя банить   
4. Добавить в crontab запись вида __/path/to/script <time> <limit>__, например __/root/scripts/ipban.sh 60 120__ , что значит блокировать IP у которых за 60 минут больше чем 120 запросов  
5. Добавить в __/etc/logrotate.d/__ файл _logrotate_ipban_ переименовав его в любое другое произвольное имя