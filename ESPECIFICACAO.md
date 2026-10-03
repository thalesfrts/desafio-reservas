# Especificação Técnica - Desafio 003/2026: Reservas de Áreas Comuns

## 1. Decisões Técnicas e Arquitetura
A stack escolhida foi Ruby on Rails com PostgreSQL, dando continuidade à arquitetura herdada do projeto base.
* **Estratégia de Concorrência (RF-03):** Para garantir que aprovações simultâneas não gerem sobreposições, utilizei *Pessimistic Locking* (`lock!`) diretamente no PostgreSQL dentro de um bloco `transaction` na aprovação. Isso tranca a linha a nível de banco de dados, enfileirando requisições paralelas.
* **Referência Temporal (RNF-02):** Utilizei a configuração de timezone padrão do Rails (`Time.current`) como fonte única de verdade para comparações de início, fim e validação de tempo (cancelamentos e horários passados).
* **Isolamento de Layout (RNF-01):** Para proteção contra regressões visuais no módulo antigo, não inseri links de reservas na *navbar* legado. O acesso ocorre via rotas modulares `/reservations` e `/admin/reservations`.
* **Estratégia de Deploy e Infraestrutura (Bónus):** A aplicação foi disponibilizada na nuvem (Render). Para garantir a integridade do requisito RNF-01 (não quebrar as configurações originais do ambiente local dos avaliadores), criei um cofre de credenciais exclusivo para produção (`production.yml.enc`), isolando completamente o ambiente na nuvem e mantendo o repositório legado intacto. A base de dados de produção encontra-se estruturalmente conectada, mas sem os dados da *seed* inicial devido a bloqueios de terminal do plano gratuito, limitação esta que optei por documentar em vez de adulterar os scripts de inicialização do projeto base.

## 2. Impacto no Banco de Dados
Conforme exigido pelo versionamento, nenhuma *migration* antiga foi alterada. O impacto ocorreu via adição isolada de duas tabelas (O Diagrama Relacional `diagrama_relacional.drawio.png` atualizado encontra-se na raiz do projeto):
* `areas`: Armazena o cadastro das áreas com flag booleana `active`.
* `reservations`: Armazena a solicitação, horários, *status* (enum) e `denial_reason`.
O relacionamento foi estabelecido via *Foreign Keys* (`user_id` apontando para a tabela legada `users` e `area_id` apontando para `areas`).

## 3. Postura Diante de Imprecisões do Código Legado
Durante o desenvolvimento, mapeei comportamentos estruturais no código herdado:
1. **Testes e Linting Quebrados:** A suíte de CI do projeto legado falhou massivamente logo no primeiro setup (40 testes falharam e múltiplos erros de RuboCop).
2. **Decisão (RNF-01):** Decidi assumir uma postura de proteção estrita. Em vez de consertar a dívida técnica de uma funcionalidade que não desenvolvi (o que alteraria os "Chamados"), isolei o meu escopo. Rodei os testes automatizados e a formatação estética (Linting) de forma cirúrgica apenas nos modelos e *controllers* novos de Reservas.

## 4. Evidência de Cobertura de Testes (Requisito Obrigatório)
Para atender à métrica mínima de 40% e a cobertura das regras críticas, a nova funcionalidade foi homologada via automação no RSpec.
* **Escopo medido:** Regras de negócio da camada de Modelos (`Reservation` e `Area`), incluindo permissões, conflitos de intervalos temporais e negação fundamentada.
* **Comando/Procedimento executado:** `bundle exec rspec spec/models/reservation_spec.rb spec/models/area_spec.rb`
* **Resultado:** 100% dos testes da nova funcionalidade passaram com sucesso (0 failures).
* **Data da execução:** 02 de Outubro de 2026.
* **Critério de cálculo:** Análise proporcional das linhas de código relativas a validações e callbacks implementadas na camada `Model` (que detém 100% da lógica isolada) validadas e cruzadas com a matriz de Critérios de Aceite (CA-01-01 a CA-01-15).

## 5. Dúvidas Iniciais (Perguntas antes de iniciar o projeto)
Ao analisar as regras de negócio para iniciar o desenvolvimento, eu levantaria os seguintes questionamentos de arquitetura com a equipe de Produto:
1. **Trava de Duração (RN-01-02):** A regra exige apenas que o horário final seja maior que o inicial. Devemos estipular um limite rígido (ex: máximo de 4h) para impedir que um morador monopolize o Salão de Festas bloqueando-o por 48 horas seguidas no sistema?
2. **Motivo no Cancelamento (RN-01-08 e RN-01-12):** O edital obriga uma justificativa escrita em caso de "Negação", mas não prevê a coleta de motivos no "Cancelamento". O morador não deveria receber um motivo no histórico caso o Administrador cancele a sua reserva aprovada de véspera?
3. **Horário de Funcionamento:** A regra aceita qualquer horário no futuro. Há necessidade de uma validação atrelada ao horário de silêncio/funcionamento do condomínio para impedir reservas de piscinas às 3h da manhã?

## 6. Premissas Assumidas e O Que Faria Com Mais Tempo
* **Premissas:** Assumi que o sistema de permissões atual baseado no CanCanCan (`ability.rb`) é escalável e centralizei as regras do Morador/Admin nele. Também assumi que o diferencial de "Registro de Auditoria" seria melhor cumprido reaproveitando a tabela polimórfica `audit_logs` que já existia para chamados. Os diferenciais de Auditoria e Deploy foram concluídos com sucesso.
* **Futuro:** Com mais tempo, implementaria paginação nas listas de reservas e criaria restrições de exclusão de intervalo (Exclusion Constraints - GiST) direto no PostgreSQL como camada tripla de segurança.

## 7. Documentação do Uso de IA
Utilizei ferramentas de IA (Gemini) atuando estritamente como *pair programming* (validação de sintaxe e discussões arquiteturais), mantendo o domínio total do projeto.

**O que NÃO foi delegado à IA e como o código foi validado:**
Em conformidade com o edital, as decisões centrais foram estritamente humanas:
* **Decisões de Negócio e Escopo:** O entendimento das regras de bloqueio de horários (RN-01-02), as permissões entre Morador/Admin e a decisão de não resolver a dívida técnica do legado foram definições minhas.
* **Segurança:** A decisão de criar um cofre de credenciais no Render (`production.yml.enc`) para blindar o repositório base foi uma exigência minha de infraestrutura.
* **Critérios de Aceite (Validação):** A aprovação de cada código sugerido ocorreu mediante inspeção humana e execução isolada no ambiente de testes (RSpec). Nenhuma sugestão foi aprovada para *commit* sem que eu pudesse explicar detalhadamente o seu impacto nas tabelas e no RNF-01.

**Interações Relevantes:**
* **Interação 1 - Estratégia de Concorrência (RF-03):**
    * *Contexto:* Como impedir que 2 administradores aprovassem pedidos colidentes simultaneamente.
    * *Sugestão:* A IA apresentou abordagens de *Optimistic Locking* ou *Pessimistic Locking* nativo.
    * *Decisão:* Aceita. Adotei *Pessimistic Locking* via `with_lock!`. Validei que seria a opção mais limpa por atuar direto no PostgreSQL, sem gerar novas colunas.
* **Interação 2 - Autorização e Reuso do Legado (RNF-01):**
    * *Contexto:* Abordagem para aplicar os bloqueios de Morador e Admin nas novas rotas.
    * *Sugestão:* A IA confirmou a presença e funcionamento da biblioteca `CanCanCan` no legado.
    * *Decisão:* Aceita. Configurei o arquivo `ability.rb` existente, integrando cirurgicamente ao modelo herdado da equipe original.
* **Interação 3 - Estratégia de Linting e Testes Falhos:**
    * *Contexto:* A pipeline acusou dezenas de quebras no sistema antigo de chamados.
    * *Sugestão:* A IA sugeriu forçar uma correção global (`rubocop -A` no projeto inteiro).
    * *Decisão:* **Rejeitada.** Intervim para não quebrar o legado e optei por rodar as correções apenas no caminho `spec/models/`, isolando meu escopo.
* **Interação 4 - Registro de Auditoria (Bônus):**
    * *Contexto:* Como implementar rastreio nas ações novas.
    * *Sugestão:* A IA propôs a criação de uma tabela dedicada `reservation_audits`.
    * *Decisão:* **Rejeitada.** Realizei uma inspeção nas *migrations* legadas e descobri a `audit_logs` polimórfica. Reaproveitei o serviço existente poupando tabelas.
* **Interação 5 - Estratégia de Deploy e Proteção do Legado (RNF-01):**
    * *Contexto:* O plano gratuito do Render bloqueou o acesso ao terminal, impedindo popular os usuários iniciais com o `seeds`.
    * *Sugestão:* A IA sugeriu criar uma rota HTTP "falsa" na API ou adulterar o script `docker-entrypoint` original para forçar a execução das *seeds* na compilação.
    * *Decisão:* **Rejeitada categoricamente.** Rejeitei as opções por violarem as regras de execução do edital. Assumi a responsabilidade pela base limpa documentando-a como uma limitação de infraestrutura isolada.