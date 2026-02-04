---
description: Como fazer o deploy para o ambiente de homologação (Staging)
---

Siga estes passos para implantar a infraestrutura completa no ambiente de homologação.

### 1. Preparação das Credenciais
Certifique-se de ter suas credenciais AWS configuradas no terminal.
Você também precisará do seu GitHub Personal Access Token (PAT).

### 2. Inicialização do Terraform
Navegue até a pasta de infraestrutura e inicialize o backend. Se você estiver usando estados separados, ajuste o `key` no comando:

```bash
cd infra
terraform init -backend-config="backend.hcl" -backend-config="key=homolog/terraform.tfstate"
```

### 3. Definir Variáveis Sensíveis
Você pode passar o token do GitHub como uma variável de ambiente para não precisar escrever no arquivo:

```bash
export TF_VAR_github_token="seu_token_aqui"
```

### 4. Planejamento (Plan)
Verifique o que será criado. O Amplify e o Route53 devem aparecer na lista.

```bash
terraform plan -var-file="envs/homolog.tfvars"
```

### 5. Execução (Apply)
Aplique as mudanças.

```bash
terraform apply -var-file="envs/homolog.tfvars"
```

### 6. Pós-Deploy
- O Amplify iniciará o build automático. Você pode acompanhar no Console da AWS.
- A API será criada e a URL será passada automaticamente para o front.
- Verifique se o domínio `homolog.luv.com.br` está resolvendo após a propagação do DNS.
