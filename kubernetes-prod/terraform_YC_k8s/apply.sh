# Развёртывание инфраструктуры с помощью Terraform
terraform apply -auto-approve
# Ожидание инициализации виртуальных машин
sleep 60
# Выполнение скрипта установки на мастер-ноде
cat install_master.sh | ssh -o StrictHostKeyChecking=no ubuntu@$(terraform output -json | jq  '.master_ip_addr.value' | tr -d '"') 'sudo bash' | tee out/master.log
# Приостанавливает выполнение скрипта на 5 секунд для завершения процессов инициализации на мастер-ноде
sleep 5
# Подготовка скрипта для воркер-нод
echo 'cloud-init status --wait' > out/install_worker.sh 
cat out/master.log  | grep -A 1 'kubeadm join' >> out/install_worker.sh  
# Выполнение скрипта на воркер-нодах
for i in $(terraform output -json | jq  '.worker_ip_addr.value[]' | tr -d '"') ;do cat out/install_worker.sh | ssh  -o StrictHostKeyChecking=no ubuntu@$i sudo bash ; done  
