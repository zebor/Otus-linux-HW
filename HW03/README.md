#Дисковые подсистемы и LVM (Logical Volume Manager)#

##ПРАКТИКА## 

##Введение в работу с LVM##

Определяемся какие устройства будем использовать в качестве  **Physical Volumes (PV)** для наших будущих **Volume Groups (VG)**. Для этого воспользуемся командой ***lsblk*** (или ***lvmdiskscan***)
Диски sdb, sdc - для базовых вещей и снапшотов
Диски sdd, sde - для lvm mirror

###Уровни абстракции LVM###

**PV** - Physical Volume - любое блочное устройство
**VG** - Volume Group - группа PV
**LV** - Logical Volume - часть VG, доступная в виде блочного устройства

sda1     sda2     sdb     sdc       <-- PV
 |        |        |       |
 |        |        |       |
 +-------VG00------+	  VG01      <-- VG
	  |		   |
       +-------+      +---------+
       |       |      |         |
      root    var    home      tmp  <-- LV
       |       |      |         | 
      ext3    xfs    ext4      xfs  <-- Файловые системы
	  
#####################

Разметим диск для будущего использования LVM - создадим **PV**:
***pvcreate /dev/sdb***

Создаем первый уровень абстракции - **VG "otus"**:	  
***vgcreate otus /dev/sdb***

Создаем **LV "test"**:
***lvcreate -l+80%FREE -n test otus***

Просмотр информации о только что созданном **VG "otus"**:
***vgdisplay otus***

Просмотр информации о том, какие диски входят в состав **VG**:
***vgdisplay -v otus | grep 'PV Name'***

Получаем детальную информацию о **LV**
***lvdisplay /dev/otus/test***

Информация в сжатом виде - команды ***vgs*** и ***lvs***

Создаем еще один LV с именем **small** из свободного места с указанием абсолютного указания в мегабайтах:
***lvcreate -L100M -n small otus***

Создаем на **LV test** файловую систему и монтируем его в каталог **/data**:
***mkfs.ext4 /dev/otus/test***
***mkdir /data***
***mount /dev/otus/test /data/***

Проверяем монтирование:
***mount | grep /data***

##Расширение LVM##

Пробуем расширить файловую систему на **LV /dev/otus/test** за счет нового блочного устройства **/dev/sdc**

+ Создаем **PV**
***pvcreate /dev/sdc***

+ Расширяем **VG "otus"**, добавляя в него этот диск:
***vgextend otus /dev/sdc***

+ Убеждаемся, что новый диск присутствует в **VG**:
***vgdisplay -v otus | grep 'PV Name'***

+ Проверяем, что места в **VG** прибавилось:
***vgs***

Сымитируем занятое место с помощью команды ***dd*** для большей наглядности. Забиваем все пространство в **/data**:
***dd if=/dev/zero of=/data/test.log bs=1M count=8000 status=progress***

Убеждаемся, что занято 100% дискового пространства:
***df -Th /data/***

+ Увеличиваем **LV** за счет появившегося свободного места. При этом оставим 20% для демонтстрации снапшотов.
***lvextend -l+80%FREE /dev/otus/test***

Убеждаемся, что **LV** расширен:
***lvs /dev/otus/test***

+ Т.к. размер файловой системы остался без изменений (проверить можно командой ***df -Th /data/***), нужно произвести ***resize*** ФС:
***resize2fs /dev/otus/test***

Проверяем изменение размера ФС:
***df -Th /data/***

##Уменьшение LVM##

Для уменьшения существующего **LV** применяется команда ***lvreduce***, но перед этим надо отмонтировать ФС, проверить ее на ошибки и уменьшить ее размер до 10G
***umount /data/***
***e2fsck -fy /dev/otus/test***
***resize2fs /dev/otus/test 10G***

Уменьшаем **LV test**
***lvreduce /dev/otus/test -L 10G***

Монтируем обратно ФС:
***mount /dev/otus/test /data/***

Проверяем размеры ФС и lvm
***df -Th /data/***
***lvs /dev/otus/test***

##Снапшоты LVM##

Снапшоты создаются командой ***lvcreate***, только с флагом ***-s***, который указывает, что это снимок:
*** lvcreate -L 500M -s -n test-snap /dev/otus/test***

Проверим с помощью ***vgs***:
***vgs -o +lv_size,lv_name | grep test***

Более наглядно отображается информация команды ***lsblk***

Оригинальный **LV** указан в выводе как **otus-test-real**, а снапшот как **otus-test-snap**. Все изменения пишутся в **otus-test--snap-cow**, где **cow**= Copy-on-Write
Снапшот можно смонтировать как и любой другой **LV**:
***mkdir /data-snap***
***mount /dev/otus/test-snap /data-snap/***
***ll /data-snap/***
***umount /data-snap***

Можно также совершить откат на снапшот для возврата предыдущего состояния. Для наглядности удалим наш **test.log**:
***rm /data/test.log***
***ll /data*** - осталась только директория **lost+found**

Отмонтируем **/data** и восстановим снапшот:
***umount /data***
***lvconvert --merge /dev/otus/test-snap***
***mount /dev/otus/test /data***
***ll /data*** - убеждаемся, что файл **test.log** восстановлен

##Зеркалирование LVM##

Создаем 2 **PV**:
***pvcreate /dev/sd{d,e}***

Создаем **VG vg0**:
***vgcreate vg0 /dev/sd{d,e}***

Создаем зеркало с помощью ключа **-m1**:
***lvcreate -l+80%FREE -m1 -n mirror vg0***

Проверяем командой ***lvs***

#Домашняя работа#

##Уменьшение тома под / до 8G##

Очищаем диски от предыдущих экспериментов:

***lvremove /dev/otus***
***lvremove /dev/vg0/mirror***
***vgremove /dev/otus***
***vgremove /dev/vg0***

Проверяем ***lsblk***, ***vgs***

Устанавливаем пакет **xfsdump**, будет нужен для снятия копии **/** тома:
***yum install xfsdump***

Готовим временный том для **/** раздела - создаем **PV**, **VG** и **LV**:
***pvcreate /dev/sdb***
***vgcreate vg_root /dev/sdb***
***lvcreate -n lv_root -l +100%FREE /dev/vg_root***

Создаем на **lv_root** файловую систему и монтируем его в **/mnt**, чтобы перенсти туда данные:
***mkfs.xfs /dev/vg_root/lv_root***
***mount /dev/vg_root/lv_root /mnt***

Теперь копируем все данные с **/** раздела в **/mnt**:
***xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt***

Проверяем, что данные скопировались:
***ls /mnt***

Настроим **grub** для перехода в новый **/** после загрузки.
Создаем синонимы каталогов, имитируем **root**:
***for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done***

Изменяем корневой каталог при помощи **chroot**:
***chroot /mnt/***

Обновляем **grub**:
***grub2-mkconfig -o /boot/grub2/grub.cfg***

Обновляем образ **initrd**:
***cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done***

Вносим изменения в файле настроек загрузчика. В файле **/boot/grub2/grub.cfg** заменяем **rd.lvm.lv=VolGroup00/LogVol00** на **rd.lvm.lv=vg_root/lv_root**.

Перезагружаем машину и убеждаемся, что **/** теперь на новом разделе при помощи команды ***lsblk***

Следущий этап - изменение размера старой **VG** с 40G на 8G и возвращение на него **/**.

Удаляем старый **LV**
***lvremove /dev/VolGroup00/LogVol00***

Создаем новый **LV** на 8G:
***lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00***

Создаем ФС **xfs** на новом разделе:
***mkfs.xfs /dev/VolGroup00/LogVol00***

Монтируем в **/mnt**
***mount /dev/VolGroup00/LogVol00 /mnt***

Копируем данные из **/** в **/mnt**:
***xfsdump -J - /dev/vg_root/lv_root | xfsrestore -J - /mnt***

Переконфигурируем **grub** так же как и в первый раз, за исключением правки **/etc/grub2/grub.cfg**
***for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done***
***chroot /mnt/***
***grub2-mkconfig -o /boot/grub2/grub.cfg***
***cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done***

##Выделить том под /var в зеркало##

Продолжаем без перезагрузки и выхода из **chroot**

Создаем зеркало на свободных дисках в 3 этапа:

1. Создаем **PV**
***pvcreate /dev/sdc /dev/sdd***

2. Создаем **VG**
***vgcreate vg_var /dev/sdc /dev/sdd***

3. Создаем зеркало **LV** с ключом **-m1** размеро 950М:
***lvcreate -L 950M -m1 -n lv_var vg_var***

После создания зеркала создаем на полученном разделе ФС **ext4**:
***mkfs.ext4 /dev/vg_var/lv_var***

Перемещаем туда **/var**
***mount /dev/vg_var/lv_var /mnt*** или альтернативной командой синхронизируем каталоги ***rsync -avHPSAX /var/ /mnt/***

На всякий случай сохраняем содержимое старого **/var**:
***mkdir /tmp/oldvar && mv /var/* /tmp/oldvar***

Монтируем новый **var** в каталог **/var**:
***umount /mnt***
***mount /dev/vg_var/lv_var /var***

Правим **fstab** для автоматического монтирования **/var**:
***echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab***

Перезагружаемся и удаляем временную **VG vg_root** 
***lvremove /dev/vg_root/lv_root***
***vgremove /dev/vg_root***
***pvremove /dev/sdb***

##Выделить том под /home##

Выделяем том под **/home** по тому же принципу что делали для **/var**:
Создаем **LV LogVol_Home** размером 2G
***lvcreate -n LogVol_Home -L 2G /dev/VolGroup00***

Создаем ФС на новом томе:
***mkfs.xfs /dev/VolGroup00/LogVol_Home***

Монтируем новый раздел в **/mnt**
***mount /dev/VolGroup00/LogVol_Home /mnt/***

Копируем туда содержимое **/home**
***cp -aR /home/* /mnt/***

Удаляем файлы из оригинального **/home**
***rm -rf /home/* ***

Отмонтируем **/mnt** и примонтируем новый раздел в **/mnt**
***umount /mnt***
***mount /dev/VolGroup00/LogVol_Home /home/***

Правим **fstab** для автоматического монтирования **/home**
***echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab***

##Сделать том для снапшотов в /home##

Для наглядности генерируем 100500 файлов в **/home**
***touch /home/file{1..20}***

Снимаем снапшот:
***lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home***

Удаляем часть файлов и убеждаемся в их отсутствии:
***rm -f /home/file{5..17}***
***ls -l /home/***

Теперь восстановим данные из снапшота. 
Отмонтируем **/home**
***umount /home***

Восстанавливаем информацию из снапшота
***lvconvert --merge /dev/VolGroup00/home_snap***

Монтируем **/home** и радуемся восстановленным файлам
***mount /home***
***ls -l /home/***


































