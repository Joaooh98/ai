# Detecção de dado pessoal (LGPD)

**Estado:** ideia
**Desde:** 2026-07-30
**Onde:** cortada do escopo do [vault-de-credenciais](vault-de-credenciais.md) por decisão do operador

## O problema

Existe uma promessa no repositório que **nenhum código cumpre**.

`skills/sdlc-quality/SKILL.md:30` manda disparar o `security-auditor` sempre que o `diff-scope` marcar
*"auth, dados pessoais, pagamento, upload ou entrada externa"* como área de risco. Mas
`tools/diff-scope.sh` não tem área de dados pessoais — as seis que existem são AUTENTICAÇÃO,
MIGRAÇÃO, SEGREDOS/CONFIG, PIPELINE, DEPENDÊNCIAS e ENTRADA EXTERNA (linhas 59-64).

A skill instrui a agir sobre um sinal que não é produzido. Na prática, mudança que toca dado pessoal
só vira auditoria se cair em alguma das outras áreas por acaso.

O contexto agrava: `agents/02-design/threat-modeler.md:27` é o **único** lugar do repositório que
menciona LGPD, e `agents/02-design/data-architect.md:56` afirma que *"unclassified personal data is a
defect"* — regra que nenhuma ferramenta consegue verificar.

## Por que ficou de fora

Decisão explícita do operador ao desenhar a camada de segredos: **só segredo técnico**. Foi a escolha
certa para aquele escopo — misturar as duas coisas teria dobrado a superfície de falso positivo num
detector que precisava nascer confiável.

## O caminho, quando for a hora

A infraestrutura já existe: `tools/_secret-shapes.sh` é um detector com classes por expressão, e
adicionar classes novas é aditivo.

O que muda em relação a segredo técnico é a **validação**. Chave de API se reconhece por prefixo
(`AKIA`, `ghp_`); CPF e CNPJ são só dígitos, e um detector ingênuo acusa número de pedido, código de
barras e id. A saída é usar o **dígito verificador**: CPF e CNPJ têm checksum, e validar elimina quase
todo falso positivo. Cartão idem, por Luhn — com a ressalva de que Luhn sozinho ainda casa sequência
aleatória com sorte, então convém exigir também prefixo IIN conhecido.

Implementar em `grep -E` não dá: checksum precisa de aritmética. E `awk` está fora pelo mesmo motivo
que já derrubou o detector principal — o `mawk` desta máquina não suporta intervalo em ERE. Ou seja,
esta classe provavelmente pede um caminho separado, em Python, chamado só quando o arquivo é candidato.

Passos:

1. Fechar a incoerência primeiro: acrescentar a área `DADOS PESSOAIS` ao `tools/diff-scope.sh`, para a
   skill parar de prometer o que não existe. É barato e independe do resto.
2. Decidir se detecção de conteúdo entra no `secret-scan.sh` ou vira ferramenta própria.
3. Validar por dígito verificador desde o primeiro dia. Sem isso, o volume de falso positivo mata a
   adoção antes de a coisa provar valor.
4. Nunca aplicar em `**/fixtures/**`, `**/testdata/**` nem `**/docs/**`: dado de teste brasileiro é
   cheio de CPF sintaticamente válido.

## O risco de não fazer

O repositório afirma tratar dado pessoal em prosa, em pelo menos quatro agentes, e não tem como
verificar. É a distância entre política escrita e política imposta — o mesmo problema que a camada de
segredos resolveu para credencial e que continua aberto para dado pessoal.
