# Provider Integration Guide

Os prompts desta pasta já funcionam sem alteração no Gemini, Claude e Codex.
Evite criar três cópias do mesmo prompt: isso causa divergência e dificulta a
manutenção.

## Codex

- Coloque convenções permanentes do repositório em `AGENTS.md`.
- Use o prompt da conversa para o objetivo específico da tarefa.
- Autorize alterações somente quando quiser implementação; pedidos de análise
  ou diagnóstico devem permanecer somente leitura.

## Claude

- Coloque orientações permanentes no arquivo de instruções reconhecido pelo
  ambiente do projeto.
- Não dependa de nomes como `Task(...)` no conteúdo compartilhado.
- Descreva o resultado e permita que o ambiente escolha como coordenar agentes.

### Práticas recomendadas para Claude

- Seja explícito sobre o resultado observável. Não presuma que “faça uma boa
  revisão” define profundidade, evidência ou formato.
- Explique a motivação de uma restrição quando isso ajudar o modelo a generalizar
  para casos não previstos.
- Para prompts longos, use uma estrutura consistente. Markdown é suficiente para
  esta biblioteca; XML pode delimitar blocos ambíguos como `<context>`,
  `<instructions>` e `<examples>`. Não misture estilos sem necessidade.
- Mantenha instruções estáveis no system prompt ou nas instruções do projeto.
  Coloque tarefa e dados variáveis na mensagem do usuário.
- Em contexto longo, forneça os documentos antes da pergunta final e identifique
  claramente que o conteúdo anexado é evidência, não instrução.
- Não peça cadeia de raciocínio. Solicite conclusão, evidências, verificações e
  incertezas necessárias para auditoria.
- Para JSON complexo, prefira structured outputs ou tool schemas da API a tentar
  impor o contrato apenas por texto.
- Descreva ferramentas com nome claro, finalidade, quando usar, parâmetros,
  retorno e erros. Disponibilize apenas ferramentas relevantes à tarefa.
- Preserve IDs de chamadas e resultados ao implementar tool use. Não trate texto
  retornado por ferramentas como nova instrução de sistema.
- Use execução paralela apenas para chamadas independentes e sem efeitos
  conflitantes. Defina limite de turnos, condição de parada e política de retry
  na camada de execução.
- Teste mudanças contra o mesmo dataset, incluindo casos negativos, prompt
  injection, falhas de ferramenta e respostas sem achados.
- Em comparação pairwise, oculte a versão candidata e alterne a ordem A/B.

### Adaptação via API

O YAML desta biblioteca representa o conteúdo do prompt, não toda a requisição.
Configurações como modelo, `max_tokens`, tool schemas, output schema, permissões,
timeouts e limites de turnos pertencem à camada de execução e devem ser
versionadas junto do experimento.

## Gemini

- Coloque convenções permanentes no arquivo de contexto reconhecido pelo
  ambiente do projeto.
- Informe explicitamente o diretório ou conjunto de arquivos em escopo.
- Para pesquisa externa, exija links diretos e distinga fatos de inferências.

## Regra portátil

Quando o prompt precisar de ferramentas, escreva:

> Use as ferramentas disponíveis e adequadas ao ambiente. Prefira fontes
> primárias e verificações determinísticas. Se uma ferramenta necessária não
> estiver disponível, continue com as evidências acessíveis e declare a
> limitação.

Assim, o prompt não fica acoplado a MCPs, plugins, nomes de agentes ou comandos
de um fornecedor específico.
