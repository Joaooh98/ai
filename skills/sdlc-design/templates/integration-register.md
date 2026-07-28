# Inventário de integrações externas

Toda dependência de sistema que o time **não controla**. Existe para responder três perguntas em
segundos: *de quem dependemos*, *o que quebra se cair*, e *quem cuida quando mudar*.

Sem este inventário, a resposta a incidente começa com "será que é o fornecedor?" e ninguém sabe
nem a lista.

---

## <fornecedor> — <capacidade de negócio que atende>

**Criticidade:** bloqueia o produto | degrada uma função | cosmética
**Dono:** <pessoa ou time> · **Desde:** <data> · **Contrato/plano:**

### Interface interna

O tipo do **seu** domínio que abstrai este fornecedor. Se este campo estiver vazio ou apontar
para uma classe com o nome do fornecedor, a camada anticorrupção não existe — e trocar de
fornecedor vai custar um trimestre.

```
<ex.: CobrancaGateway — porta em domain/pagamento/>
Adapter: <ex.: adapters/stripe/StripeCobrancaGateway>
```

### Operações

| operação | timeout | retry | idempotente | comportamento na falha |
|---|---|---|---|---|
| | | transitório / nunca | chave: | degrada / enfileira / falha |

Erro 4xx nunca entra em retry cego — é erro nosso.

### Webhooks recebidos

| evento | assinatura | janela de replay | deduplicação por | processamento |
|---|---|---|---|---|
| | HMAC sobre corpo cru | | id do evento | síncrono / fila |

Se não há webhook, escreva "nenhum" — campo vazio é ambíguo.

### Limites e custo

| dimensão | valor | o que fazemos ao chegar perto |
|---|---|---|
| rate limit | | |
| quota mensal | | |
| custo por chamada | | |

### Confiabilidade do fornecedor

- **SLA contratado:**
- **Página de status:**
- **Canal de suporte e tempo de resposta:**
- **Histórico de incidentes relevante:**

### Credenciais

- **Onde vivem:** (gerenciador de segredos — nunca código, imagem ou variável em texto claro)
- **Como rotacionar, sem deploy:**
- **Quem tem acesso:**
- **Última rotação:**

### Ciclo de vida

- **Versão da API em uso:**
- **Deprecação anunciada / `Sunset` conhecido:**
- **Como acompanhamos mudanças:** (changelog, RSS, headers `Deprecation`/`Sunset` — RFC 8594)
- **Dono do acompanhamento:**

### Degradação

O que o produto faz quando isto está fora. **Decisão de produto, não de engenharia.**

- Usuário vê:
- Dados em trânsito:
- Recuperação ao voltar: (reprocessa fila? pede de novo? perde?)

### Saída

Como sairíamos deste fornecedor, se precisássemos. Se a resposta for "não dá", isso é um risco
registrado, não um detalhe.

---

## Resumo de risco

| fornecedor | criticidade | SLA | degradação definida? | saída viável? |
|---|---|---|---|---|

Integração crítica **sem** degradação definida é um incidente esperando data.
