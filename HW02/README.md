* [Как начать Git](git_quick_start.md)
* [Как начать Vagrant](vagrant_quick_start.md)

############# RAID 10 на 6 дисках ######################################

## Vagrantfile

Добавляем еще 2 диска, чтобы было 6 для создания RAID

	:sata5 => {
            :dfile => './sata5.vdi',
            :size => 250,
            :port => 5
        },
        :sata6 => {
            :dfile => './sata6.vdi',
            :size => 250, 
            :port => 6
        }
		
# Проверяем блочные устройства

lshw -short | grep disk

На RAID определим диски b,c,d,e,f,g

# Зануляем суперблоки

Для того, чтобы убрать запись на блочном устройстве о mdraid, актуально для использовавшихся ранее дисков, для новых не нужно.

mdadm --zero-superblock --force /dev/sd{b,c,d,e,f,g}

# Создаем RAID 10 на 6 дисков

mdadm --create --verbose /dev/md0 -l 10 -n 6 /dev/sd{b,c,d,e,f,g}

-l - тип RAID
-n - количество используемых дисков

# Проверяем сборку RAID

cat /proc/mdstat
mdadm -D /dev/md0

# Создаем конфигурационный файл mdadm.conf для сохранения конфигураци после перезагрузки

Проверка информации о массиве

mdadm -detail --scan --verbose

Создаем файл mdadm в две команды:

echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf

# Ломаем RAID 

Искусственно выводим из строя блочное устройство sdc

mdadm /dev/md0 --fail /dev/sdc

Проверяем состояние RAID и убеждаемся в выходе из строя нашего дисках

cat /proc/mdstat
mdadm -D /dev/md0

# Чиним RAID

Удаляем сломанный диск из массива

mdadm /dev/md0 --remove /dev/sdc

Заменяем сломанный диск новым устройством. Диск должен совершить rebuild

mdadm /dev/md0 --add /dev/sdc

Проверяем rebuild нового диска и статус RAID, все те же команды

cat /proc/mdstat
mdadm -D /dev/md0

# Создаем раздел GPT на RAID с помощью parted

parted -s /dev/md0 mklabel gpt

Создаем 5 разделов

parted /dev/md0 mkpart primary ext4 0% 20%
parted /dev/md0 mkpart primary ext4 20% 40%
parted /dev/md0 mkpart primary ext4 40% 60%
parted /dev/md0 mkpart primary ext4 60% 80%
parted /dev/md0 mkpart primary ext4 80% 100%

Проверяем что получилось

parted /dev/md0 print

# Создаем ФС ext4 сразу на 5 созданных разделах

for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done

# Монтируем ФС по каталогам в /raid/

Создаем каталоги для монтирования

mkdir -p /raid/part{1,2,3,4,5}

Монтируем циклом

for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done

############################################################

* Скрипт [raid10.sh] (raid10.sh) для автоматического создания RAID по большей части копирует предыдущие операции

Правим Vagrantfile, для указания ссылки на файл добавляем 

box.vm.provision "shell", path: "./raid10.sh"


* Файл конфигурации [mdadm.conf] (./mdadm.conf)
* Файл [Vagrantfile] (./Vagrantfile)








