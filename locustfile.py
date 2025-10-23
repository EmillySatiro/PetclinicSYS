
from locust import HttpUser, task, between
import random
import json

class PetClinicUser(HttpUser):
    """
    Usuário que simula requisições ao Spring PetClinic API Gateway
    """
    
    # Tempo de espera entre requisições (1 a 3 segundos)
    wait_time = between(1, 3)
    
    # URL base do API Gateway 
    # host = "http://localhost:8080"  # será definido na linha de comando
    
    # Lista para armazenar IDs de owners criados
    owner_ids = []
    
    def on_start(self):
        """
        Executado quando um usuário inicia.
        Popula a lista de IDs existentes fazendo uma requisição inicial.
        """
        try:
            response = self.client.get("/api/customer/owners", name="GET /owners (setup)")
            if response.status_code == 200:
                owners = response.json()
                if isinstance(owners, list) and len(owners) > 0:
                    self.owner_ids = [owner.get('id') for owner in owners if owner.get('id')]
                    print(f"[Setup] Carregados {len(self.owner_ids)} owner IDs existentes")
        except Exception as e:
            print(f"[Setup] Erro ao carregar owners: {e}")
        
        # Se não houver IDs, adiciona alguns padrão para evitar erros nos testes
        if not self.owner_ids:
            self.owner_ids = list(range(1, 11))  # IDs de 1 a 10 como fallback
    
    @task(40)
    def get_owners_list(self):
        """
        GET /owners (lista donos) — 40% das requisições
        Lista todos os proprietários (owners)
        """
        with self.client.get(
            "/api/customer/owners",
            name="GET /owners",
            catch_response=True
        ) as response:
            if response.status_code == 200:
                try:
                    owners = response.json()
                    if isinstance(owners, list):
                        response.success()
                        # Atualiza a lista de IDs disponíveis
                        new_ids = [owner.get('id') for owner in owners if owner.get('id')]
                        if new_ids:
                            self.owner_ids = new_ids
                    else:
                        response.failure("Resposta não é uma lista")
                except json.JSONDecodeError:
                    response.failure("Erro ao decodificar JSON")
            else:
                response.failure(f"Status code: {response.status_code}")
    
    @task(30)
    def get_owner_by_id(self):
        """
        GET /owners/{id} — 30% das requisições
        Busca um proprietário específico por ID
        """
        if self.owner_ids:
            owner_id = random.choice(self.owner_ids)
        else:
            owner_id = random.randint(1, 10)
        
        with self.client.get(
            f"/api/customer/owners/{owner_id}",
            name="GET /owners/{id}",
            catch_response=True
        ) as response:
            if response.status_code == 200:
                try:
                    owner = response.json()
                    if owner and 'id' in owner:
                        response.success()
                    else:
                        response.failure("Resposta inválida")
                except json.JSONDecodeError:
                    response.failure("Erro ao decodificar JSON")
            elif response.status_code == 404:
                # 404 pode ser aceitável se o ID não existir
                response.success()
            else:
                response.failure(f"Status code: {response.status_code}")
    
    @task(20)
    def get_vets(self):
        """
        GET /vets — 20% das requisições
        Lista todos os veterinários
        """
        with self.client.get(
            "/api/vet/vets",
            name="GET /vets",
            catch_response=True
        ) as response:
            if response.status_code == 200:
                try:
                    vets = response.json()
                    if isinstance(vets, list) or (isinstance(vets, dict) and 'vetList' in vets):
                        response.success()
                    else:
                        response.failure("Resposta não é uma lista")
                except json.JSONDecodeError:
                    response.failure("Erro ao decodificar JSON")
            else:
                response.failure(f"Status code: {response.status_code}")
    
    @task(10)
    def create_owner(self):
        """
        POST /owners (cadastro simples) — 10% das requisições
        Cria um novo proprietário
        """
        # Gera dados aleatórios para o novo owner
        random_id = random.randint(10000, 99999)
        
        new_owner = {
            "firstName": f"User{random_id}",
            "lastName": f"Test{random_id}",
            "address": f"{random.randint(1, 999)} Main St",
            "city": random.choice(["Madison", "New York", "Los Angeles", "Chicago", "Boston"]),
            "telephone": f"{random.randint(1000000000, 9999999999)}"
        }
        
        with self.client.post(
            "/api/customer/owners",
            json=new_owner,
            name="POST /owners",
            catch_response=True
        ) as response:
            if response.status_code in [200, 201]:
                try:
                    created_owner = response.json()
                    if created_owner and 'id' in created_owner:
                        # Adiciona o novo ID à lista
                        self.owner_ids.append(created_owner['id'])
                        response.success()
                    else:
                        response.success()  # Considera sucesso mesmo sem ID no retorno
                except json.JSONDecodeError:
                    response.success()  # Alguns endpoints podem não retornar JSON
            elif response.status_code == 204:
                response.success()  # 204 No Content também é sucesso
            else:
                response.failure(f"Status code: {response.status_code}")


if __name__ == "__main__":
    import os
    os.system("locust -f locustfile.py --host=http://localhost:8080")
