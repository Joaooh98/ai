# Pesquisa — configuração arquitetural autônoma de projetos

**Data:** 2026-08-28  
**Objetivo:** embasar o agente `project-configurator`, responsável por preparar projetos novos ou
existentes para futuras implementações assistidas por IA com poucas interações humanas.

## Resposta executiva

Não existe uma ferramenta capaz de identificar a “melhor arquitetura” de um projeto novo: antes do
código, arquitetura é uma decisão orientada por contexto, restrições e atributos de qualidade. A
combinação mais sólida encontrada foi:

- **Greenfield:** cenários mensuráveis de atributos de qualidade + opções e trade-offs + C4 e
  Structurizr DSL como arquitetura versionável + ADRs para decisões aceitas + contratos de interface.
- **Brownfield:** evidência extraída de manifests, dependências, código, testes, CI/CD, deploy e
  histórico + regras persistentes curtas + testes arquiteturais executáveis.
- **Projetos em nuvem:** revisão complementar pelo Well-Architected Framework oficial do provedor.

SOLID e Clean Code são boas heurísticas subsidiárias, mas não selecionam topologia, limites de
serviços, consistência de dados, modelo de integração ou operação. Eles também não devem substituir
uma convenção estável e comprovada do projeto existente.

## Evidências e ferramentas selecionadas

### 1. Arquitetura como código para projetos novos

O Structurizr DSL é uma DSL textual para modelar arquitetura segundo o C4, adequada a controle de
versão e automação. O ecossistema também trata documentação e ADRs junto do modelo. Isso o torna uma
boa escolha padrão para **registrar e evoluir** arquitetura — não um oráculo que decide a arquitetura.

Fontes primárias:

- [Structurizr DSL](https://docs.structurizr.com/dsl)
- [Structurizr — documentação oficial](https://docs.structurizr.com/)
- [Structurizr — architecture as code](https://docs.structurizr.com/as-code)

### 2. Atributos de qualidade antes da escolha tecnológica

O Quality Attribute Workshop do Software Engineering Institute elicita e prioriza cenários de
qualidade antes ou durante o desenho arquitetural. Essa prática evita escolher microserviços,
eventos, banco ou framework por popularidade em vez de confiabilidade, segurança, desempenho,
operabilidade, custo e demais necessidades concretas.

Fontes primárias:

- [SEI — Quality Attribute Workshop](https://www.sei.cmu.edu/library/the-sei-quality-attribute-workshop/)
- [SEI — QAW, Third Edition](https://www.sei.cmu.edu/library/quality-attribute-workshops-qaws-third-edition/)

### 3. Regras persistentes para a IA

Claude Code suporta instruções de projeto e regras modulares em `.claude/rules/`, inclusive com
escopo por caminho. O GitHub Copilot reconhece `AGENTS.md` e outros arquivos de instrução; o formato
AGENTS.md foi projetado como orientação portátil entre ferramentas. A recomendação é preservar os
arquivos existentes, usar regras específicas e verificáveis e evitar um manual genérico enorme.

Fontes primárias:

- [Claude Code — memória e regras de projeto](https://code.claude.com/docs/en/memory)
- [GitHub Copilot — suporte a instruções personalizadas](https://docs.github.com/en/copilot/reference/custom-instructions-support)
- [AGENTS.md — formato aberto](https://agents.md/)

### 4. Enforcement arquitetural

Instruções em prosa orientam, mas CI e testes impedem regressões. O agente deve sugerir o menor
conjunto compatível com a stack, sempre aguardando autorização antes de instalar:

| Ecossistema/necessidade | Ferramenta | Uso |
|---|---|---|
| Java | ArchUnit | Testar dependências, camadas, ciclos e regras arquiteturais |
| JavaScript/TypeScript | dependency-cruiser | Validar e visualizar dependências e ciclos |
| Multilíngue | Semgrep | Codificar regras estruturais e práticas específicas do projeto |
| Interfaces | OpenAPI/AsyncAPI/protobuf/schemas | Tornar limites e compatibilidade verificáveis |

Fontes primárias:

- [ArchUnit — User Guide](https://www.archunit.org/userguide/html/000_Index.html)
- [dependency-cruiser — repositório oficial](https://github.com/sverweij/dependency-cruiser)
- [Semgrep — ideias para regras customizadas](https://semgrep.dev/docs/writing-rules/rule-ideas)

### 5. Greenfield e brownfield exigem estratégias distintas

O Azure Well-Architected Framework trata explicitamente a aplicação do processo em workloads novos
e existentes e recomenda revisão contínua, não uma avaliação única. Quando um provedor de nuvem já
foi escolhido, seu framework oficial deve complementar — e não substituir — os drivers do sistema.

Fontes primárias:

- [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/architecture/framework/)
- [Implementing Well-Architected recommendations](https://learn.microsoft.com/en-us/azure/well-architected/design-guides/implementing-recommendations)

## Pesquisa emergente relevante

Dois trabalhos de 2026 reforçam a direção, mas devem ser tratados como evidência preliminar, não
como padrão consolidado:

- *Architecture as a Capability Equalizer for Coding Agents* relata ganhos ao fornecer C4,
  Structurizr, ADRs, contratos e verificações como ArchUnit a agentes de código.
- *CIAO: Code In, Architecture Out* propõe gerar documentação arquitetural a partir de código com
  visões alinhadas a ISO 42010, SEI Views and Beyond e C4.

Fontes:

- [Architecture as a Capability Equalizer for Coding Agents](https://arxiv.org/abs/2608.21747)
- [CIAO: Code In, Architecture Out](https://arxiv.org/abs/2604.08293)

## Decisões incorporadas ao agente

1. Três modos: brownfield, greenfield e híbrido.
2. Toda regra brownfield é classificada como `enforced`, `documented`, `de facto` ou `proposed`.
3. Projeto novo começa por contexto, restrições e cenários de qualidade mensuráveis.
4. Decisões consequenciais comparam alternativas e exigem aprovação antes de virar baseline/ADR.
5. Structurizr DSL/C4 é o padrão de documentação arquitetural quando o projeto não possui outro.
6. Regras ficam em `.claude/rules/`; `AGENTS.md` é opcional para portabilidade e nunca sobrescreve
   instruções existentes.
7. SOLID e Clean Code são defaults; YAGNI e simplicidade impedem abstração especulativa.
8. O configurador não altera código de produto, dependências, banco, deploy ou produção.
9. Convenções importantes devem migrar gradualmente de prosa para testes/lint arquitetural.

## Limitações

- Ferramentas de grafo e índices de linguagem mostram estrutura estática; não provam comportamento
  operacional, ownership real ou fluxos dinâmicos.
- Código existente pode conter dívida e inconsistência; frequência sozinha não transforma um padrão
  ruim em regra. Conflitos precisam ficar visíveis.
- A pesquisa emergente citada é recente e ainda não substitui validação prática no próprio toolkit.
- O agente reduz interações repetidas, mas não pode decidir sozinho requisitos, risco aceitável,
  compliance ou compromissos caros e irreversíveis.
