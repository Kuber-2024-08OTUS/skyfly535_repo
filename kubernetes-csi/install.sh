# Переход в каталог с конфигурации Terraform для развертывания необходимой инфраструктуры
cd terraform_YC_k8s
# Инициализация Terraform и обновление версии провайдеров и модулей до последних доступных
terraform init -upgrade
# Установка кластера Kubernetes удовлетворяющего условиям ДЗ в Yandex Cloud (без запроса дополнительного ввода от пользователя)
terraform apply -input=false  -compact-warnings -auto-approve
# Получение учетных данных Kubernetes-кластера, регистрация кластер локально
yc k8s cluster get-credentials --id $(yc k8s cluster list  | grep 'RUNNING' | awk -F '|' '{print $2}')  --external --force
# Добавляение репозитория Helm charts для CSI-драйвера Yandex S3 с указанным URL
helm repo add yandex-s3 https://yandex-cloud.github.io/k8s-csi-s3/charts
# Установка CSI-драйвер Yandex S3 в Kubernetes-кластер, используя Helm. Релиз называется csi-s3.
helm install csi-s3 yandex-s3/csi-s3
# Применение манифеста storageClass.yaml, который определяет StorageClass для динамического создания PersistentVolume на основе Yandex S3
cd .. && kubectl apply -f manifest/storageClass.yaml
# Применение манифеста pvc.yaml, который создает PersistentVolumeClaim, запрашивая хранилище согласно ранее созданному StorageClass
kubectl apply -f  manifest/pvc.yaml
# Применение манифеста s3-test-pod.yaml, который будет использовать примонтированный том из Yandex S3
kubectl apply -f  manifest/s3-test-pod.yaml