Обновление и конфигурирование ядра CentOS

Обновляем систему и перезагружаемся
# yum update
# shutdown -r now 

Устанавливаем wget и качаем нужную версию ядра с kernel.org
# yum install wget
# wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.19.66.tar.xz

Распаковываем архив с ядром в каталог /usr/src/ и переходим в него
# tar -xvf linux-4.19.66.tar.xz -C /usr/src/
# cd /usr/src/linux-4.19.66/

Устанавливаем инструменты для компиляции пакетов
# yum groupinstall -y "Development Tools"
# yum install -y ncurses-devel openssl-devel bc elfutils-libelf-devel

Копируем старый конфигурационный файл
# cp -v /boot/config-3.10.0-957.27.2.el7.x86_64 /usr/src/linux-4.19.66/.config

Создаем новый конфиг на основе старого в текстовом виде
# make oldconfig

Или в виде меню
# make menuconfig


Компилируем ядро
# make

Устанавливаем ядро и модули
# make modules_install install

---------------------------------

Применяем новое ядро

Вносим зменения в файл настроек загрузчика grub.
# vi /etc/default/grub
Меняем значение переменной GRUB_DEFAULT=0

Применяем настройки для grub и перезагружаемся
# grub2-mkconfig -o /boot/grub2/grub.cfg
# shutdown -r now

Проверяем версию ядра

# uname -r







