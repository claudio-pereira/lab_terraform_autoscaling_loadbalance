# lab_terraform_autoscaling_loadbalance
lab_terraform_autoscaling_loadbalance

Esse Primeiro repósitorio de Integração AWS_ Terraform configura um Load Balance com Autoscaling Group e executa 3 instancias em subnets separadas.
Seguem os passos que o código segue:

1º - Declarar chaves para o acesso das instancias

2º - Declarar que a vpc default da conta será usada

3º - Pegar a id da vpc para as subnets

4º - Criar o launch_configuration com a security group do Load Balance

5º - Criar a security group do Load Balance

6º - Criar o AutoScaling Group

7º - Criar o Load Balance

8º - Criar o Listener do load balance

9º - Criar o target group do load balance

10º - Configurar as regras do Listener

11º - Fazer o terraform destruir toda a Infra para não gerar custos na AWS.

Deve-se criar as chaves para acessar as instâncias e exportar as credenciais da aws antes de usar os comandos do Terraform.

Comandos utilizados para o Terraform:

1º - terraform init
2º - terraform fmt
3º - terraform validate
4º - terraform plan -out=projeto
5º - terraform apply projeto
6º - terraform destroy