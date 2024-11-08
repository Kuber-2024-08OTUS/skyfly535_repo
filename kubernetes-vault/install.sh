# Установка кластера Kubernetes удовлетворяющего условиям ДЗ в Yandex Cloud
cd terraform_YC_k8s && terraform apply -auto-approve
# Регистрация кластер локально
yc managed-kubernetes cluster get-credentials skyfly535 --external
# Установка из Helm чарта consul с требуемыми настройками
cd ../consul && helmfile apply . && cd ..
# Установка из Helm чарта vault с требуемыми настройками
cd vault && helmfile apply . && cd ..
#Ожидание (проверка) запуска Pod'ов Vault
while [[ "$(kubectl get pod -n vault  | grep -E 'vault-[0-9]' | grep  Running | wc -l)"  -lt "3" ]]; do echo 'waiting for all pod is running'; sleep 1 ;done
# Инициализация Vault (инициализирует Vault с тремя ключами и порогом в три для разблокировки (unseal))
kubectl -n vault exec -it vault-0 -- vault operator init \
          -key-shares=3 \
          -key-threshold=3 
# Расшифровка (Unseal) всех экземпляров Vault (потребуется вручную вводить unseal-ключи, которые были сгенерированы на этапе инициализации)
for i in 0 1 2; do
  for j in 1 2 3; do
    echo "Enter key number $j"
    kubectl -n vault exec -it  vault-$i -- vault operator unseal 
  done
done
# Настройка порт-форвардинга для доступа к Vault
kubectl -n vault  port-forward svc/vault 8200:8200 >/dev/null 2>&1 &
# Установка переменных окружения для доступа к Vault
echo "Enter Token"
read token
export VAULT_TOKEN=$token
export VAULT_ADDR=http://127.0.0.1:8200
# Настройка секретного хранилища и создание секретов в Vault
vault secrets enable -path otus/ kv-v2
vault kv put otus/cred 'username=otus'
vault kv patch otus/cred 'password=asajkjkahs'
# Создается ServiceAccount vault-auth в namespace vault (этот ServiceAccount будет использоваться для аутентификации Pod'ов в Kubernetes при обращении к Vault)
kubectl apply -f sa.yaml
# Настройка аутентификации Vault через Kubernetes
# Включает метод аутентификации Kubernetes в Vault
vault auth enable kubernetes
# Настраивает подключение к Kubernetes API из Vault
vault write auth/kubernetes/config \
    kubernetes_host=https://kubernetes.default.svc
# Создание политики vault с именем otus-policy     
vault policy write otus-policy otus-policy.hcl
# Создание роли otus для аутентификации через Kubernetes, связывая ее с ServiceAccount vault-auth в namespace vault и назначая политики default и otus-policy
vault write auth/kubernetes/role/otus \
      bound_service_account_names=vault-auth \
      bound_service_account_namespaces=vault \
      policies=default,otus-policy \
      ttl=24h
# Установка External Secrets Operator с помощью Helm (позволяет синхронизировать секреты из внешних систем (таких как Vault) в Kubernetes Secrets)
helmfile apply -f external-secrets-operator/
#  Ожидание готовности Pod'ов в namespace vault
kubectl wait pod \
  --all \
  --for=condition=Ready \
  --namespace=vault
# Применение конфигураций для SecretStore и ExternalSecret
kubectl apply -f secretStore.yaml
kubectl apply -f externalSecret.yaml
