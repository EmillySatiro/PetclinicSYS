# Host do sistema a ser testado
HOST="http://localhost:8080"

# Quantas repetições por cenário
REPS=30

# Definição dos cenários: nome, usuários, duração, taxa de ramp-up
declare -A CENARIOS
CENARIOS["A"]="50 10 10m"
CENARIOS["B"]="100 20 10m"
CENARIOS["C"]="200 40 5m"

for cenario in "${!CENARIOS[@]}"; do
    read users ramp time <<< "${CENARIOS[$cenario]}"
    echo "🚀 Executando CENÁRIO ${cenario} (${users} usuários por ${time})"

    for i in $(seq 1 $REPS); do
        echo "➡️  Execução ${i}/${REPS}"

        # 🔁 Reinicia os containers que contêm os bancos em memória
        echo "♻️ Reiniciando ambiente para estado inicial..."
        docker compose restart customers-service visits-service vets-service
        sleep 10  # aguarda o bootstrap e o repovoamento do HSQLDB

        CSV_PREFIX="resultados/${cenario}_${i}"
        mkdir -p resultados

        locust -f locustfile.py --headless \
            -u $users -r $ramp -t $time \
            --host=$HOST --csv=$CSV_PREFIX \
            > "${CSV_PREFIX}.log" 2>&1

        echo "✅ Execução ${i} finalizada — CSV salvo em ${CSV_PREFIX}_stats.csv"
    done
done

echo "🏁 Todos os testes finalizados!"
