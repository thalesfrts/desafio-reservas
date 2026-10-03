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
Utilizei ferramentas de IA atuando estritamente como *pair programming* (validação de sintaxe e arquitetura), mantendo o domínio total das regras de negócio.
* **Interação 1 - Estratégia de Concorrência e Race Conditions:**
    * *Contexto:* Como impedir que 2 administradores aprovassem pedidos colidentes simultaneamente.
    * *Sugestão:* A IA apresentou abordagens de *Optimistic Locking* (via `lock_version`) ou *Pessimistic Locking* nativo.
    * *Decisão:* Adotei *Pessimistic Locking* via `with_lock!`. Validei que seria a opção mais limpa por não exigir novas colunas no schema, atuando diretamente em transações do SGBD.
* **Interação 2 - Autorização e Reuso do Legado (RNF-01):**
    * *Contexto:* Qual melhor abordagem para aplicar os bloqueios de Morador e Admin nas novas rotas sem vazar permissões.
    * *Sugestão:* Após compartilhar o `application_controller.rb` herdado, a IA confirmou a presença da biblioteca `CanCanCan`.
    * *Decisão:* Em vez de gerar middlewares autorizadores manuais, configurei o arquivo `ability.rb` existente, garantindo integração cirúrgica ao modelo herdado da equipe original.
* **Interação 3 - Estratégia de Linting e Testes Falhos:**
    * *Contexto:* A pipeline acusou dezenas de quebras no sistema antigo de chamados após meu primeiro envio.
    * *Sugestão:* A IA sugeriu forçar uma correção global (`rubocop -A` no projeto inteiro) ou adotar um isolamento defensivo.
    * *Decisão:* Rejeitei a correção global. Optei por rodar o corretor e as execuções apenas no caminho `spec/models/` para isolar meu escopo e não correr o risco de quebrar o legado.
* **Interação 4 - Registro de Auditoria (Diferencial):**
    * *Contexto:* Como implementar rastreio nas ações novas (Aprovar, Criar) exigidas como bônus.
    * *Sugestão:* A IA apresentou a criação de uma tabela dedicada `reservation_audits`.
    * *Decisão:* Rejeitei a tabela dedicada. Realizei uma inspeção nas *migrations* legadas e descobri a `audit_logs` polimórfica. Reaproveitei o serviço existente de log, poupando banco de dados.
* **Interação 5 - Estratégia de Deploy e Proteção do Legado (RNF-01):**
    * *Contexto:* Como lidar com restrições do plano gratuito do Render (bloqueio de acesso ao Shell) que impediam a execução do ficheiro de *seeds* na nuvem para popular a base de dados de produção.
    * *Sugestão:* A IA sugeriu criar uma rota HTTP "falsa" no sistema ou adulterar o script `docker-entrypoint` original para forçar a execução das *seeds* durante a compilação.
    * *Decisão:* Rejeitei categoricamente ambas as sugestões por violarem o edital e as boas práticas. Criar atalhos na aplicação ou adulterar scripts de inicialização legados violaria o RNF-01 e as instruções originais de execução. Aceitei apenas a sugestão de isolamento do cofre de credenciais e decidi documentar a base de dados vazia como uma limitação arquitetural consciente.