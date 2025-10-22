#!/bin/bash

HOST="http://localhost:8080"
REPS=30

declare -A CENARIOS
CENARIOS["A"]="50 10 10m"
CENARIOS["B"]="100 20 10m"
CENARIOS["C"]="200 40 5m"

# Função para esperar um serviço HTTP ficar disponível
wait_for_service() {
    local url=$1
    local name=$2
    local timeout=${3:-60}  # timeout padrão 60s
    local interval=2         # verifica a cada 2s
    local elapsed=0

    echo "⏳ Aguardando ${name} ficar pronto em ${url} ..."
    while ! curl -s -f "$url" >/dev/null 2>&1; do
        sleep $interval
        elapsed=$((elapsed + interval))
        if [ $elapsed -ge $timeout ]; then
            echo "⚠️ Timeout: ${name} não respondeu em ${timeout}s"
            exit 1
        fi
    done
    echo "✅ ${name} está pronto!"
}

for cenario in "${!CENARIOS[@]}"; do
    read users ramp time <<< "${CENARIOS[$cenario]}"
    echo "🚀 Executando CENÁRIO ${cenario} (${users} usuários por ${time})"

    for i in $(seq 1 $REPS); do
        echo "➡️  Execução ${i}/${REPS}"

        # Reinicia os serviços com banco em memória
        echo "♻️ Reiniciando microserviços com HSQLDB..."
        docker compose restart customers-service visits-service vets-service

        # Espera os serviços ficarem prontos
        wait_for_service "http://localhost:8081/actuator/health" "customers-service"
        wait_for_service "http://localhost:8082/actuator/health" "visits-service"
        wait_for_service "http://localhost:8083/actuator/health" "vets-service"

        CSV_PREFIX="resultados/${cenario}_${i}"
        mkdir -p resultados

        # Executa o Locust
        locust -f locustfile.py --headless \
            -u $users -r $ramp -t $time \
            --host=$HOST --csv=$CSV_PREFIX \
            > "${CSV_PREFIX}.log" 2>&1

        echo "✅ Execução ${i} finalizada — CSV salvo em ${CSV_PREFIX}_stats.csv"
    done
done

echo "🏁 Todos os testes finalizados!"
