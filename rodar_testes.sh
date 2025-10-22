#!/bin/bash

HOST="http://localhost:8080"
REPS=30

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
    local elapsed=0
    echo "⏳ Aguardando endpoint $url ficar pronto..."
    until curl -s -f "$url" >/dev/null 2>&1; do
        sleep $WAIT_INTERVAL
        echo "Tentando..."
        elapsed=$((elapsed + WAIT_INTERVAL))
        if [ $elapsed -ge $WAIT_TIMEOUT ]; then
            echo "⚠️ Timeout: endpoint $url não respondeu em $WAIT_TIMEOUT segundos"
            exit 1
        fi
    done
    echo "✅ Endpoint $url está pronto!"
}

for cenario in "${!CENARIOS[@]}"; do
    read users ramp time <<< "${CENARIOS[$cenario]}"
    echo "🚀 Executando CENÁRIO ${cenario} (${users} usuários por ${time})"

    for i in $(seq 1 $REPS); do
        echo "➡️  Execução ${i}/${REPS}"

        # 🔁 Reinicia os microserviços com HSQLDB
        echo "♻️ Reiniciando docker compose"
        docker compose -f "$MICROSERVICES_DIR/docker-compose.yml" down
        docker compose -f "$MICROSERVICES_DIR/docker-compose.yml" up -d

        # ⏳ Espera o endpoint principal ficar pronto
        wait_for_endpoint "$HOST/api/customer/owners"

        # Diretório para salvar resultados
        CSV_PREFIX="resultados/${cenario}_${i}"
        mkdir -p resultados

        # 🚀 Executa o Locust em modo headless
        locust -f locustfile.py --headless \
            -u $users -r $ramp -t $time \
            --host=$HOST --csv=$CSV_PREFIX \
            > "${CSV_PREFIX}.log" 2>&1

        echo "✅ Execução ${i} finalizada — CSV salvo em ${CSV_PREFIX}_stats.csv"
    done
done

echo "🏁 Todos os testes finalizados!"
