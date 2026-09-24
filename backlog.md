# Backlog — Sistema de Controle de Ponto Eletrônico

Última atualização: 2026-09-24

## Status

- `[ ]` Pendente
- `[~]` Em desenvolvimento
- `[x]` Concluído
- `[!]` Bloqueado

---

## Fase 1 — Fundação

### PWA

- [x] PWA-001 — Criar `manifest.webmanifest`
  - Data: 2026-09-24
  - Status: Concluído
  - Escopo: manifesto inicial da aplicação.

- [x] PWA-002 — Criar Service Worker
  - Data: 2026-09-24
  - Status: Concluído
  - Escopo: cache inicial e fallback offline.

- [x] PWA-003 — Criar estrutura CSS
  - Data: 2026-09-24
  - Status: Concluído
  - Escopo: reset, variáveis, layout e componentes.

### Interface

- [x] UI-001 — Criar tela inicial do terminal
  - Data: 2026-09-24
  - Status: Concluído
  - Escopo: identificação, relógio e status.

- [x] UI-002 — Implementar indicador de rede
  - Data: 2026-09-24
  - Status: Concluído
  - Escopo: Online/Offline.

- [x] UI-003 — Implementar indicador de impressora
  - Data: 2026-09-24
  - Status: Parcial
  - Escopo: componente visual inicial; integração real pendente.

- [x] UI-004 — Integrar Lucide
  - Data: 2026-09-24
  - Status: Concluído
  - Escopo: ícones vetoriais.

### Câmera

- [x] CAM-001 — Implementar acesso à câmera
  - Data: 2026-09-24
  - Status: Concluído
  - Escopo: `getUserMedia`.

- [x] CAM-002 — Implementar captura local
  - Data: 2026-09-24
  - Status: Concluído
  - Escopo: captura JPEG em memória.

### Offline

- [x] OFF-001 — Criar banco IndexedDB
  - Data: 2026-09-24
  - Status: Concluído
  - Escopo: banco local inicial.

- [x] OFF-002 — Criar fila de marcações
  - Data: 2026-09-24
  - Status: Concluído
  - Escopo: registros pendentes de sincronização.

- [ ] OFF-003 — Implementar sincronização com Supabase
  - Data: 2026-09-24
  - Status: Pendente
  - Escopo: sincronização idempotente.

---

## Fase 2 — Banco de Dados

- [ ] DB-001 — Criar schema PostgreSQL
- [ ] DB-002 — Criar empresas
- [ ] DB-003 — Criar funcionários
- [ ] DB-004 — Criar usuários e perfis
- [ ] DB-005 — Criar jornadas
- [ ] DB-006 — Criar marcações imutáveis
- [ ] DB-007 — Criar justificativas
- [ ] DB-008 — Criar atestados
- [ ] DB-009 — Criar auditoria
- [ ] DB-010 — Implementar RLS
- [ ] DB-011 — Implementar integridade das marcações

---

## Fase 3 — Registro de Ponto

- [ ] PONTO-001 — Identificação por matrícula
- [ ] PONTO-002 — Autenticação por PIN
- [ ] PONTO-003 — Integração RFID
- [ ] PONTO-004 — Fluxo de Entrada
- [ ] PONTO-005 — Fluxo de saída para intervalo
- [ ] PONTO-006 — Fluxo de retorno
- [ ] PONTO-007 — Fluxo de saída
- [ ] PONTO-008 — Prevenção de marcação duplicada
- [ ] PONTO-009 — Registro de evidência fotográfica

---

## Fase 4 — Regras de Negócio

- [ ] RULE-001 — Tolerância de 5 minutos
- [ ] RULE-002 — Limite diário de 10 minutos
- [ ] RULE-003 — Cálculo de excedentes
- [ ] RULE-004 — Justificativa obrigatória
- [ ] RULE-005 — Atrasos
- [ ] RULE-006 — Saídas antecipadas
- [ ] RULE-007 — Faltas
- [ ] RULE-008 — Jornadas noturnas
- [ ] RULE-009 — Feriados e folgas

---

## Fase 5 — Comprovantes

- [ ] PRINT-001 — Modelo de ticket
- [ ] PRINT-002 — Dados da empresa
- [ ] PRINT-003 — Dados do funcionário
- [ ] PRINT-004 — Data/hora do registro
- [ ] PRINT-005 — Abstração de impressora
- [ ] PRINT-006 — Detecção de falha
- [ ] PRINT-007 — Comprovante digital
- [ ] PRINT-008 — Edge Function de e-mail

---

## Fase 6 — Gestão

- [ ] ADMIN-001 — Dashboard
- [ ] ADMIN-002 — Funcionários
- [ ] ADMIN-003 — Jornadas
- [ ] ADMIN-004 — Inconsistências
- [ ] ADMIN-005 — Justificativas
- [ ] ADMIN-006 — Atestados
- [ ] ADMIN-007 — Abonos
- [ ] ADMIN-008 — Auditoria

---

## Fase 7 — Segurança

- [ ] SEC-001 — RLS completo
- [ ] SEC-002 — Controle de permissões
- [ ] SEC-003 — Integridade dos registros
- [ ] SEC-004 — Auditoria
- [ ] SEC-005 — Proteção contra replay
- [ ] SEC-006 — Proteção contra duplicidade

---

## Fase 8 — Testes e Deploy

- [ ] TEST-001 — Testes de regras de negócio
- [ ] TEST-002 — Testes offline
- [ ] TEST-003 — Testes de sincronização
- [ ] TEST-004 — Testes de permissões
- [ ] TEST-005 — Testes de câmera
- [ ] TEST-006 — Testes de impressão
- [ ] DEPLOY-001 — GitHub Actions
- [ ] DEPLOY-002 — Deploy
