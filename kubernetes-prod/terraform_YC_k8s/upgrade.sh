echo "Start upgrade master"
# Получение IP-адреса мастер-ноды
MASTER_IP=$(terraform output -json | jq  '.master_ip_addr.value' | tr -d '"')
# Установка SSH-подключения и выполнение команд на мастер-ноде
cat <<  EOF  | ssh -o StrictHostKeyChecking=no ubuntu@$MASTER_IP  'sudo bash'
        # Добавление репозитория Kubernetes версии v1.31
        echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
        # Обновление списка пакетов
        apt-get update
        # Разблокировка пакетов kubeadm и kubectl
        apt-mark unhold kubeadm kubectl
        # Установка новых версий kubeadm и kubectl
        apt-get install -y kubeadm kubectl
        # Блокировка пакетов kubeadm и kubectl
        apt-mark hold kubeadm kubectl
        # Экспорт переменной KUBECONFIG
        export KUBECONFIG=/etc/kubernetes/admin.conf
        # Планирование обновления Kubernetes
        kubeadm upgrade plan
        # Применение обновления до версии v1.31.0
        echo 'y' | kubeadm upgrade apply v1.31.0
        # Разблокировка пакета kubelet
        apt-mark unhold kubelet 
        # Установка новой версии kubelet
        apt-get install -y kubelet
        # Блокировка пакета kubelet
        apt-mark hold kubelet 
        # Перезапуск kubelet
        systemctl daemon-reload
        systemctl restart kubelet
        # Создание скрипта upgrade-worker.sh для воркер-нод
        echo 'echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
        apt-get update
        apt-mark unhold kubeadm kubectl kubelet
        apt-get install -y kubeadm kubectl kubelet
        apt-mark hold kubeadm kubectl kubelet
        systemctl daemon-reload
        systemctl restart kubelet' >  upgrade-worker.sh
EOF
# Ожидание завершения обновления мастер-ноды
sleep 60
# Получение списка воркер-нод и их IP-адресов
ssh   -o StrictHostKeyChecking=no ubuntu@$MASTER_IP 'export KUBECONFIG=/etc/kubernetes/admin.conf ; sudo -E kubectl get nodes -o json' | python3 -c "
import json
import sys
data = json.load(sys.stdin)
for i in (data['items']):
   print(i['status']['addresses'][1]['address']+' '+i['status']['addresses'][0]['address'])"  | grep 'worker' | while read a b
 do
    # Обновление воркер-нод в цикле
    echo "Upgrading on $a"
    # Выполнение команд на мастер-ноде для управления воркер-нодой
    cat  << EOF | ssh -A -o StrictHostKeyChecking=no  ubuntu@$MASTER_IP  "bash" 
    # Дрейн воркер-ноды
    export KUBECONFIG=/etc/kubernetes/admin.conf ; sudo -E kubectl  drain $a --ignore-daemonsets &&
    sleep 10 &&
    # Обновление воркер-ноды
    cat upgrade-worker.sh | ssh -o StrictHostKeyChecking=no  $b 'sudo bash' &&
    sleep 10 &&
    # Разблокировка воркер-ноды
    sudo -E kubectl uncordon $a &&
    sleep 10
EOF 
    echo "Upgrade on $a done"
done