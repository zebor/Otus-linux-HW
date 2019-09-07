#!/bin/bash

### Создаем RAID 10 на 6 дисках (b,c,d,e,f,g)

# Зануляем суперблоки

mdadm --zero-superblock --force /dev/sd{b,c,d,e,f,g}

# Создаем RAID 10 на 6 дисках

mdadm --create --verbose /dev/md0 -l10 -n6 /dev/sd{b,c,d,e,f,g}

# Создаем конфигурационный файл mdadm.conf

mkdir /etc/mdadm/
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf

# Создаем GPT раздел на RAID

parted -s /dev/md0 mklabel gpt

# Создаем 5 разделов

parted /dev/md0 mkpart primary ext4 0% 20%
parted /dev/md0 mkpart primary ext4 20% 40%
parted /dev/md0 mkpart primary ext4 40% 60%
parted /dev/md0 mkpart primary ext4 60% 80%
parted /dev/md0 mkpart primary ext4 80% 100%

# Создаем ФС на разделах, создаем каталоги для монтирования ФС, изменяем файл /etc/fstab

for i in $(seq 1 5)

do
	mkfs.ext4 /dev/md0p$i
	mkdir -p /raid/part$i
	echo "/dev/md0p$i /raid/part$i ext4 defaults 0 0" >> /etc/fstab
done

# Монтируем ФС

mount -a







