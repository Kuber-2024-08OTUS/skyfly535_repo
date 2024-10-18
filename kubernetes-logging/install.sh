
# Создание сервисного акаунта для работы в YC
yc iam service-account create --name k8s-cluster-logging
FOLDER_ID=$(yc config get folder-id)
SA_ID=$(yc iam service-account get --name k8s-cluster-logging --format json | jq .id -r)
# Назначение роли admin сервисному аккаунту
yc resource-manager folder add-access-binding --id $FOLDER_ID  --role admin --subject serviceAccount:$SA_ID
# Создание статического ключа доступа для сервисного аккаунта, который можно использовать для доступа к Yandex Object Storage
if [ ! -f .sa.secret ]; then
  yc iam access-key create  --service-account-id $SA_ID >  .sa.secret
fi 
# Создание переменных окружения с параметрами созданного секрета
export accessKeyId=$(cat .sa.secret | grep 'key_id' | awk -F ':' '{print $2}')
export secretAccessKey=$(cat .sa.secret | grep 'secret' | awk -F ':' '{print $2}')

# Шаблонизировоние файла переменных для loki
cat loki/values.yaml.tpl | envsubst > loki/values.yaml

# Создание кластера managed-kubernetes в YC
yc managed-kubernetes cluster create \
 --name k8s-logging --network-name default \
 --zone ru-central1-a  --subnet-name k8s \
 --public-ip \
 --service-account-id ${SA_ID} --node-service-account-id ${SA_ID} 

# Создание групп узлов (Node Groups)
# Группа узлов для рабочих нагрузок
 yc managed-kubernetes node-group create   \
 --name  k8s-logging-workers \
 --cluster-name k8s-logging \
 --cores 2 \
 --memory 4 \
 --core-fraction 5 \
 --preemptible \
 --fixed-size 1 \
 --network-interface subnets=k8s,ipv4-address=nat
# Группа узлов для инфраструктуры
 yc managed-kubernetes node-group create \
 --name  k8s-logging-infra \
 --cluster-name k8s-logging \
 --cores 2 \
 --memory 4 \
 --core-fraction 5 \
 --fixed-size 1 \
 --preemptible \
 --node-labels node-role=infra \
 --network-interface subnets=k8s,ipv4-address=nat
# Регистррация кластер локально
yc managed-kubernetes cluster get-credentials --external --name k8s-logging --force
# Создание taint для узлов инфраструктуры
kubectl taint nodes -l node-role=infra node-role=infra:NoSchedule
# Создание namespase monitoring
kubectl create ns monitoring

# Создание S3 бакетов для хранения логов
yc storage bucket create  monitoring-loki-chunks
yc storage bucket create  monitoring-loki-ruler
yc storage bucket create  monitoring-loki-admin
# Предоставление созданному сервисному акаунту прав на созданные S3 бакеты
yc storage bucket update --name monitoring-loki-chunks  \
    --grants grant-type=grant-type-account,grantee-id=${SA_ID},permission=permission-full-control

yc storage bucket update --name monitoring-loki-ruler   \
    --grants grant-type=grant-type-account,grantee-id=${SA_ID},permission=permission-full-control

yc storage bucket update --name monitoring-loki-admin  \
    --grants grant-type=grant-type-account,grantee-id=${SA_ID},permission=permission-full-control

# Запуск установки Helm loki
cd loki && helmfile apply; cd ..
# Запуск установки Helm promtail
cd promtail && helmfile apply; cd ..
# Запуск установки Helm grafana
cd grafana && helmfile apply; cd ..

