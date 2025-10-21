
# Testes de Carga - Spring PetClinic Microservices

Script de teste de carga usando Locust para avaliar o desempenho do Spring PetClinic.

## Mix de Requisições

- **40%** - GET /owners (lista donos)
- **30%** - GET /owners/{id} (busca por ID)
- **20%** - GET /vets (lista veterinários)
- **10%** - POST /owners (cria novo dono)

## Instalação

```bash
pip install locust
```

## Como Executar

### Modo Interface Web
```bash
locust -f locustfile.py --host=http://localhost:8080
```
Abra no navegador: http://localhost:8089

### Cenários de Teste

**Cenário A (50 usuários, 10 min):**
```bash
locust -f locustfile.py --host=http://localhost:8080 --users=50 --spawn-rate=10 --run-time=10m --headless --html=scenario_A.html --csv=scenario_A
```

**Cenário B (100 usuários, 10 min):**
```bash
locust -f locustfile.py --host=http://localhost:8080 --users=100 --spawn-rate=10 --run-time=10m --headless --html=scenario_B.html --csv=scenario_B
```

**Cenário C (200 usuários, 5 min):**
```bash
locust -f locustfile.py --host=http://localhost:8080 --users=200 --spawn-rate=10 --run-time=5m --headless --html=scenario_C.html --csv=scenario_C
```

## Resultados

Os testes geram:
- `scenario_X.html` - Relatório visual
- `scenario_X_stats.csv` - Estatísticas
- `scenario_X_failures.csv` - Falhas registradas

## Aplicação Alvo

Spring PetClinic Microservices: https://github.com/spring-petclinic/spring-petclinic-microservices

```bash
git clone https://github.com/spring-petclinic/spring-petclinic-microservices.git
cd spring-petclinic-microservices
docker-compose up -d
```


### 2️⃣ Suba a Aplicação PetClinic
```bash
# Clone o repositório oficial (se ainda não tiver)
git clone https://github.com/spring-petclinic/spring-petclinic-microservices.git

# Entre no diretório
cd spring-petclinic-microservices

# Suba com Docker Compose
docker-compose up -d

# Aguarde ~2 minutos e verifique se está funcionando
curl http://localhost:8080/api/customer/owners
```

### 3️⃣ Execute um Teste Simples (10 min)
```bash
# Volte para o diretório do projeto
cd /home/emilly/sysPetclinic/sysPetclinic

# Execute o script interativo
./run_tests.sh

# Ou execute um cenário específico direto
locust -f locustfile.py \
  --host=http://localhost:8080 \
  --users 50 \
  --spawn-rate 5 \
  --run-time 10m \
  --html reports/teste.html \
  --csv reports/teste \
  --headless
```

### 4️⃣ Execute as 30 Repetições (COMPLETO)
```bash
# Para cada cenário, execute:
./run_multiple_tests.sh

# Selecione o cenário (A, B ou C)
# Confirme 30 repetições
# Aguarde... (pode levar várias horas!)
```

### 5️⃣ Consolide os Resultados
```bash
# Após as 30 repetições de cada cenário
python consolidate_results.py --scenario all --compare

# Isso gera:
# - reports/consolidado_cenario_A.csv
# - reports/consolidado_cenario_B.csv
# - reports/consolidado_cenario_C.csv
# - reports/comparacao_cenarios.csv
```

## 📊 Estrutura dos Resultados

```
reports/
├── cenario_A_run_1_report.html       # Relatório visual da execução 1
├── cenario_A_run_1_stats.csv         # Estatísticas da execução 1
├── cenario_A_run_1_stats_history.csv # Histórico temporal
├── ...
├── cenario_A_run_30_stats.csv        # Última execução
├── consolidado_cenario_A.csv         # MÉDIAS E DESVIOS PADRÃO
└── comparacao_cenarios.csv           # COMPARAÇÃO FINAL
```

## 🎓 Para o Trabalho

### Dados que você vai usar:

1. **consolidado_cenario_X.csv** - Contém:
   - Tempo médio de resposta (média ± desvio padrão)
   - Tempo máximo de resposta (média ± desvio padrão)
   - Requisições por segundo (média ± desvio padrão)
   - Total de requisições (média ± desvio padrão)
   - Taxa de falha (média ± desvio padrão)

2. **comparacao_cenarios.csv** - Contém:
   - Comparação lado a lado dos 3 cenários
   - Já calculado: taxa de sucesso %

### Como escrever as conclusões:

```
Exemplo baseado nos dados reais:

"Cenário A (50 usuários):
 - Tempo médio: 45.2ms ± 3.1ms
 - Taxa de sucesso: 99.8%
 - Throughput: 83.5 req/s

Cenário B (100 usuários):
 - Tempo médio: 89.7ms ± 5.4ms (↑ 98% em relação ao Cenário A)
 - Taxa de sucesso: 99.2%
 - Throughput: 167.3 req/s (↑ 2x)

Cenário C (200 usuários):
 - Tempo médio: 234.5ms ± 12.8ms (↑ 161% em relação ao Cenário B)
 - Taxa de sucesso: 96.5% (↓ 2.7 pontos percentuais)
 - Throughput: 298.4 req/s

Conclusões:
- O sistema suporta bem até 100 usuários simultâneos
- A partir de 200 usuários, o tempo de resposta degrada significativamente
- A taxa de erro começa a aparecer em cargas altas
- etc."
```

## 🚨 Troubleshooting

### Erro: Connection refused
```bash
# Verifique se os serviços estão rodando
docker-compose ps

# Reinicie se necessário
docker-compose restart
```

### Erro: Locust não encontrado
```bash
# Instale novamente
pip install locust

# Ou use um ambiente virtual
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Resultados estranhos / muitos erros
```bash
# Popule o banco com dados
# Acesse http://localhost:8080 e cadastre alguns owners manualmente

# Ou ajuste o script para não falhar com 404
# (já está tratado no locustfile.py)
```

## ⚡ Dicas

1. **Não execute tudo de uma vez** - Teste primeiro com 1-2 repetições
2. **Monitore o sistema** - Use `docker stats` para ver uso de CPU/memória
3. **Faça backups** - Copie a pasta reports periodicamente
4. **Use screen/tmux** - Para execuções longas que não podem ser interrompidas
5. **Analise incrementalmente** - Não espere todas as 30 repetições para começar a análise

## 📞 Ajuda

Se algo der errado:
1. Verifique os logs: `docker-compose logs -f`
2. Teste os endpoints manualmente com `curl`
3. Revise o README_LOCUST.md para detalhes técnicos
4. Use o modo interativo do Locust (sem --headless) para debug

Boa sorte! 🚀
