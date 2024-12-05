# Ожидание завершения процессов Cloud-Init (аставляет скрипт ждать, пока все процессы cloud-init не завершатся)
cloud-init status --wait
# команда, используемая для инициализации мастер-ноды Kubernetes, то есть для установки компонентов управления (control plane)
kubeadm init --upload-certs --pod-network-cidr=10.244.0.0/16
# Настройка окружения для kubectl
export KUBECONFIG=/etc/kubernetes/admin.conf
# Установка сетевого плагина Flannel
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
