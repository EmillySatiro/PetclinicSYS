# 🧪 Testes de Carga - Spring PetClinic Microservices

Este projeto realiza **testes de carga automatizados** utilizando o **Locust** para avaliar o desempenho do sistema **Spring PetClinic Microservices**, simulando diferentes níveis de carga em cenários controlados.

---

## 🎥 Demonstração

👉 [Assista no YouTube](https://youtu.be/MbJSzSjjFMI)

## ⚙️ Requisitos

Antes de executar os testes, certifique-se de ter instalado:

- **Docker** e **Docker Compose**  
- **Python 3.10+**  
- **Virtualenv**

---

## 🐍 Criação do Ambiente Python

```bash
# Crie e ative o ambiente virtual
python -m venv venv
source venv/bin/activate   # (Linux/Mac)
venv\Scripts\activate      # (Windows)

# Instale as dependências
pip install -r requirements.txt
```

---

## 🐳 Subir o Sistema Alvo (Spring PetClinic)

1. **Clone o repositório oficial:**

```bash
git clone https://github.com/spring-petclinic/spring-petclinic-microservices.git
cd spring-petclinic-microservices
```

2. **Suba a aplicação:**

```bash
docker compose up --build -d
```

3. **Verifique se os serviços estão ativos:**

```bash
curl http://localhost:8080/api/customer/owners
```

---

## 🧰 Estrutura do Projeto de Testes

O repositório contém:

```
.
├── locustfile.py           # Define as tarefas e mix de requisições
├── rodar_testes.sh         # Script principal que executa todos os cenários
├── requirements.txt
└── resultados/             # Pasta onde são salvos os CSVs e logs
```

---

## 🚀 Execução dos Testes

1. **Dê permissão de execução ao script:**
```bash
chmod +x rodar_testes.sh
```

2. **Execute todos os testes automaticamente:**
```bash
./rodar_testes.sh
```

O script define:
- Todos os cenários de carga
- Quantidade de execuções repetidas
- Armazenamento automático dos resultados em CSV

---

## 🧩 Execução Manual (Opcional)

### Cenário A – 50 usuários, 10 min
```bash
locust -f locustfile.py --host=http://localhost:8080   --users=50 --spawn-rate=5 --run-time=10m   --headless --csv=resultados/A_1 --html=resultados/A_1.html
```

### Cenário B – 100 usuários, 10 min
```bash
locust -f locustfile.py --host=http://localhost:8080   --users=100 --spawn-rate=10 --run-time=10m   --headless --csv=resultados/B_1 --html=resultados/B_1.html
```

### Cenário C – 200 usuários, 5 min
```bash
locust -f locustfile.py --host=http://localhost:8080   --users=200 --spawn-rate=20 --run-time=5m   --headless --csv=resultados/C_1 --html=resultados/C_1.html
```

---

## 📊 Estrutura dos Resultados

Após as execuções, os resultados são armazenados em `resultados/`, incluindo:

| Arquivo | Descrição |
|----------|------------|
| `A_1_exceptions.csv` | Exceções registradas na execução 1 do cenário A |
| `A_1_failures.csv` | Falhas de requisições |
| `A_1_stats.csv` | Estatísticas acumuladas da execução |
| `A_1_stats_history.csv` | Histórico temporal completo |
| `A_1_log.txt` | Log detalhado da execução |

---

## 🧠 Observações

- As execuções **não utilizam a interface Web do Locust**, sendo totalmente automatizadas por linha de comando.  
- Cada cenário é repetido múltiplas vezes para permitir análise estatística robusta.  
- O sistema do Pet Clinic já realiza **pré-carregamento automático de dados** no banco, garantindo consistência nas requisições de leitura.
