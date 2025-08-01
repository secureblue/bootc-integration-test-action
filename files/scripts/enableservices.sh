systemctl unmask sshd
systemctl enable sshd

systemctl enable install-key.service

chmod 600 /etc/NetworkManager/system-connections/static.nmconnection

nmcli connection reload
nmcli connection up static-enp1s0