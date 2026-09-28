# Especificação Técnica: Reservas de Áreas Comuns

## 1. Premissas Assumidas e Interpretação do Edital

* **Documentação Original e Setup:** Durante a análise inicial do repositório base, constatei a ausência de um ficheiro `README.md` com instruções de configuração inicial. Para cumprir rigorosamente a diretriz do edital de "não criar um documento paralelo", abstive-me de redigir um manual de instalação do zero. Todas as decisões arquiteturais, técnicas e operacionais relativas à nova funcionalidade de reservas estão centralizadas exclusivamente neste documento.
* **Autenticação e Estrutura Base:** Baseando-me na análise prévia dos ficheiros de configuração fornecidos (`devise.rb`, `database.yml` e `docker-compose.yml`), assumi que a gestão de sessões, a conexão com a base de dados PostgreSQL e os perfis de utilizador (Morador, Administrador, Colaborador) já se encontram estruturados. A nova funcionalidade consumirá esta base para a aplicação rigorosa das regras de autorização.
* [INSERIR AQUI: Outras premissas assumidas ao longo do desenvolvimento do projeto]

## 2. Decisões Técnicas e Modelação de Dados

* **Tratamento de Conflito de Intervalos:** [INSERIR AQUI: Explicação técnica de como o sistema impede reservas sobrepostas para a mesma área. Exemplo: Validações ao nível do modelo e restrições únicas na base de dados.]
* **Gestão de Concorrência (Aprovações Simultâneas):** [INSERIR AQUI: Estratégia adotada para impedir que dois administradores aprovem reservas conflituosas exatamente ao mesmo tempo. Exemplo: Utilização de concorrência com lock otimista/pessimista ou transações atómicas no banco.]
* **Impacto no Modelo Existente:** [INSERIR AQUI: Relação das novas tabelas (ex: `areas`, `reservations`) e como se ligam aos modelos de utilizadores existentes, referenciando o diagrama relacional atualizado.]

## 3. Limitações Conhecidas e Delimitação de Escopo

* **Fora do Escopo:** Conforme delimitado nos requisitos funcionais e não funcionais do desafio, as regras relativas a pagamentos, cobranças, notificações externas, listas de espera e reservas recorrentes não foram implementadas.
* **Imprecisões do Código Base:** [INSERIR AQUI: Registo de qualquer erro, bug intencional ou comportamento inesperado encontrado no código herdado, e a respetiva decisão técnica adotada (corrigir, contornar ou manter o comportamento).]
* **Propostas de Melhoria Futura:** [INSERIR AQUI: O que seria implementado se houvesse maior margem de tempo. Exemplo: Testes de carga massivos, refinamento da interface de calendário, etc.]

## 4. Documentação do Uso de Inteligência Artificial

As ferramentas de Inteligência Artificial foram utilizadas estritamente como assistentes de raciocínio lógico, validação da interpretação de regras de negócio e revisão estrutural. Nenhuma decisão de arquitetura, segurança ou código final foi delegada de forma cega sem a devida validação e aprovação humana.

**Interações Relevantes:**

1. **Contexto:** Interpretação da diretriz restritiva sobre "documentação paralela" face à ausência do `README.md` no código base herdado.
   * **Sugestão da IA:** Apresentou duas linhas de raciocínio profissionais (1. Ação corretiva com criação de um manual técnico mínimo para setup; 2. Abstenção de criação e foco exclusivo na justificação dentro do ficheiro `ESPECIFICACAO.md`).
   * **Decisão e Validação:** Optei pela abstenção (opção 2) para garantir o cumprimento estrito da regra de restrição de novos ficheiros documentais imposta pelo edital, centralizando a justificação técnica da ausência neste documento.

2. **Contexto:** [INSERIR AQUI: Descrição resumida da dúvida técnica futura (ex: estruturação da base de dados)]
   * **Sugestão da IA:** [INSERIR AQUI: O que a IA sugeriu]
   * **Decisão e Validação:** [INSERIR AQUI: O que decidiu aceitar, modificar ou rejeitar, e a justificação técnica]

3. **Contexto:** [INSERIR AQUI: Descrição resumida de outra interação de desenvolvimento]
   * **Sugestão da IA:** [INSERIR AQUI]
   * **Decisão e Validação:** [INSERIR AQUI]