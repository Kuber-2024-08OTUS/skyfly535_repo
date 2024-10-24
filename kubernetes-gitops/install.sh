# Установка кластера Kubernetes удовлетваряющего условиям ДЗ в Yandex Cloud
cd terraform_YC_k8s && terraform apply -auto-approve
# Регистррация кластер локально
yc managed-kubernetes cluster get-credentials skyfly535 --external
# Установка из Helm чарта argocd с требуемыми настройками
cd ../argocd && helmfile apply && cd ..
# установк из Helm чарта ingress-nginx для тестовых приложений поднимаемых а argocd
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
# Установка в Argocd `project` с именем `Otus`
kubectl apply -f appproject.yaml
# Установка в Argocd тестового приложения `kubernetes-network`
kubectl apply -f kubernetes-network.yaml
# Установка в Argocd тестового приложения `kubernetes-templating`
kubectl apply -f kubernetes-templating.yaml

