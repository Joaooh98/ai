# Protocolo de experimentos

Cada execução deve registrar prompt e dataset com suas versões, provedor,
modelo, parâmetros, ferramentas, data, respostas, pontuações, tokens, custo e
latência quando disponíveis.

1. Execute a versão atual e a candidata sobre o mesmo dataset.
2. Rode verificações determinísticas antes dos julgamentos subjetivos.
3. Oculte a identidade da candidata e alterne a ordem A/B.
4. Compare qualidade, falsos positivos, custo, latência e estabilidade.
5. Exija revisão humana para segurança ou decisões de alto impacto.
6. Promova somente se os thresholds forem atingidos e casos críticos não
   regredirem.
7. Transforme falhas reais em novos casos, sem dados sensíveis.

Resultados são artefatos separados dos prompts. Ignore-os no Git quando
contiverem dados sensíveis; versione resultados agregados quando precisar de
auditoria.

