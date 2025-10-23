HOST="http://localhost:8080"
REPS=5
# Tempo máximo para esperar o serviço subir (em segundos)
WAIT_TIMEOUT=120
# Intervalo entre tentativas (em segundos)
WAIT_INTERVAL=10
MICROSERVICES_DIR="./spring-petclinic-microservices"

declare -A CENARIOS
CENARIOS["A"]="50 5 10m"
CENARIOS["B"]="100 10 10m"
CENARIOS["C"]="200 20 5m"

# Função para esperar o endpoint estar pronto
wait_for_endpoint() {
    local url=$1
    local service_name=$2
    local elapsed=0
    
    echo "⏳ Aguardando endpoint $service_name ($url) ficar pronto..."
    
    # Usamos "curl -s -o /dev/null -w %{http_code}" para checar o status HTTP
    until [ "$(curl -s -o /dev/null -w %{http_code} $url)" -eq 200 ]; do
        sleep $WAIT_INTERVAL
        echo "Tentando $service_name..."
        elapsed=$((elapsed + WAIT_INTERVAL))
        
        if [ $elapsed -ge $WAIT_TIMEOUT ]; then
            echo "⚠️ Timeout: endpoint $service_name ($url) não respondeu 200 em $WAIT_TIMEOUT segundos"
            # Decide se quer parar o script ou apenas a execução
            # exit 1 # Para o script inteiro
            return 1 # Retorna falha para esta execução
        fi
    done
    
    echo "✅ Endpoint $service_name ($url) está pronto!"
    return 0
}

for cenario in "${!CENARIOS[@]}"; do
    read users ramp time <<< "${CENARIOS[$cenario]}"
    echo "🚀 Executando CENÁRIO ${cenario} (${users} usuários por ${time})"
    
    for i in $(seq 1 $REPS); do
        # Diretório para salvar resultados
        CSV_PREFIX="resultados/${cenario}_${i}"
        STATS_FILE="${CSV_PREFIX}_stats.csv"

        # Checa se a execução já foi feita
        if [ -f "$STATS_FILE" ]; then
            echo "⚡ Execução ${i}/${REPS} do cenário ${cenario} já existe ($STATS_FILE). Pulando..."
            continue
        fi

        echo "➡️  Execução ${i}/${REPS} do cenário ${cenario}"

        # 🔁 Reinicia os microserviços com HSQLDB
        echo "♻️ Reiniciando docker compose"
        docker compose -f "$MICROSERVICES_DIR/docker-compose.yml" down
        docker compose -f "$MICROSERVICES_DIR/docker-compose.yml" up -d
        
        # ⏳ Espera pelos endpoints
        if ! wait_for_endpoint "$HOST/api/customer/owners" "customers-service"; then
            echo "Erro ao esperar pelo customers-service. Pulando execução ${i}."
            continue # Pula para a próxima repetição
        fi
        
        if ! wait_for_endpoint "$HOST/api/vet/vets" "vets-service"; then
            echo "Erro ao esperar pelo vets-service. Pulando execução ${i}."
            continue # Pula para a próxima repetição
        fi
        
        echo "✅ Todos os serviços estão prontos. Iniciando Locust em 5s..."
        sleep 5 # Um tempinho extra para garantir o registro no Eureka
        
        mkdir -p resultados
        
        # 🚀 Executa o Locust em modo headless
        locust -f locustfile.py --headless \
            -u $users -r $ramp -t $time \
            --host=$HOST --csv=$CSV_PREFIX \
            > "${CSV_PREFIX}.log" 2>&1
            
        echo "✅ Execução ${i} finalizada — CSV salvo em ${STATS_FILE}"
    done
done

echo "🏁 Todos os testes finalizados!"