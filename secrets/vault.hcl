// Configuração do Vault. Montada somente-leitura no container.

// Storage de arquivo, num volume nomeado do Docker. É o que faz o segredo
// sobreviver a restart. O modo dev do Vault guarda em memória e perde tudo —
// serve para experimentar, não para guardar credencial.
storage "file" {
  path = "/vault/file"
}

listener "tcp" {
  // 0.0.0.0 aqui é DENTRO do container. Quem decide a exposição real é o
  // mapeamento de porta do compose, que prende em 127.0.0.1 no host.
  address = "0.0.0.0:8200"

  // Sem TLS, e isso é uma decisão consciente com uma condição amarrada:
  // o tráfego nunca sai do loopback da sua máquina. Se algum dia esta porta
  // for publicada em rede — trocando o mapeamento do compose para "8200:8200"
  // ou colocando isto num servidor — esta linha vira um vazamento de token em
  // texto puro. Publicou na rede, ligue TLS antes.
  tls_disable = true
}

api_addr = "http://127.0.0.1:8200"
ui       = true

// mlock ligado: impede que a memória do Vault vá para o swap. Depende do
// cap_add IPC_LOCK no compose. Se você remover a capability, esta linha
// precisa virar `disable_mlock = true` ou o Vault não sobe.
disable_mlock = false
