# 🤖 Luv - IA Atendente Comercial Virtual

> **Assistente comercial inteligente para fotógrafos e prestadores de serviço**

---

## 🎯 Visão do Produto

Criar uma IA atuando como **atendente comercial virtual**, capaz de conduzir o cliente do primeiro contato até o fechamento do serviço, com integração direta à agenda do profissional.

### Objetivos Principais

- ✅ Reduzir o gargalo de atendimento
- ✅ Automatizar tarefas operacionais (orçamento, agendamento, lembretes)
- ✅ Aumentar a taxa de conversão (atendimento 24/7, resposta instantânea)
- ✅ Manter o controle final com o profissional

### Público-Alvo

📸 Fotógrafos | 🏢 Estúdios | 🎬 Videomakers | 💼 Profissionais autônomos com agenda

---

## 🏗️ Arquitetura Técnica (MVP)

### Backend (`back/`) - Clean Architecture

```
domain/        # Entities (Message, Conversation) and interfaces - immutable, no external deps
application/   # Use cases (ChatUseCase) - orchestration layer
infrastructure/# External adapters (GeminiAdapter) - implements domain interfaces
presentation/  # API (WebSocket) + agents (LangGraph) - entry points
config/        # Pydantic settings from .env
```

**Key Pattern**: Dependency inversion - domain defines interfaces, infrastructure implements them. Example: `LLMInterface` (domain) ← `GeminiAdapter` (infrastructure).

### LangGraph Workflow ([chat_agent.py](back/src/presentation/agents/chat_agent.py))

Simple graph: `START → process_message → END`. The agent handles both streaming and non-streaming responses. State management uses `ChatState` TypedDict with `messages`, `current_input`, `current_response`, `is_streaming`, `error`.

### Frontend (`front/`)

React 19 + Vite + TailwindCSS 4. WebSocket hook ([useWebSocket.ts](front/src/hooks/useWebSocket.ts)) manages reconnection logic (max 5 attempts, 3s interval). Components: `Chat`, `MessageList`, `MessageInput`, `Message`, `TypingIndicator`.

## Critical Patterns

### Immutability in Domain

- `Message` and `Conversation` entities are **frozen Pydantic models**
- `Conversation.add_message()` returns a new instance: `return Conversation(id=self.id, messages=[*self.messages, new_message], ...)`
- Never mutate entities directly

### WebSocket Message Protocol

```json
// Client → Server
{"type": "message", "content": "user input", "conversation_id": "optional-uuid"}
{"type": "clear", "conversation_id": "uuid"}
{"type": "ping"}

// Server → Client
{"type": "start", "conversation_id": "uuid"}
{"type": "token", "content": "streaming chunk"}
{"type": "end", "conversation_id": "uuid"}
{"type": "error", "message": "error details"}
```

See [websocket_handler.py](back/src/presentation/api/websocket_handler.py#L63-L80) for handling logic.

### Conversation State Management

In-memory storage in `ChatUseCase._conversations: dict[str, Conversation]`. Thread ID = conversation ID. No persistence layer - conversations reset on server restart.

## Development Workflows

### Backend Setup & Run

```bash
cd back
poetry install              # Install dependencies
cp .env.example .env        # Configure GOOGLE_API_KEY
poetry run python main.py   # Start on 0.0.0.0:8000
```

### Frontend Setup & Run

```bash
cd front
npm install
npm run dev                 # Vite dev server on http://localhost:5173
```

### Quick Start (Both Services)

```bash
./start.sh  # From project root - handles both backend + frontend
```

### Testing

```bash
cd back
poetry run pytest           # Run backend tests
```

## Key Configuration

### Environment Variables ([settings.py](back/src/config/settings.py))

- `GOOGLE_API_KEY`: **Required** for Gemini API (get from https://aistudio.google.com/apikey)
- `LLM_MODEL`: Default `gemini-2.5-flash`
- `LLM_MAX_TOKENS`: 8192
- `LLM_TEMPERATURE`: 0.7
- `API_HOST`: 0.0.0.0
- `API_PORT`: 8000

### CORS Configuration ([main.py](back/main.py#L49-L56))

Currently allows all origins (`"*"`) for WebSocket connections. Restrict in production.

## Dependencies

### Backend

- `google-genai ^1.0.0` - Google Gemini API client
- `langgraph ^0.2.0` - Agent workflow orchestration
- `fastapi ^0.115.0` + `uvicorn` - WebSocket server
- `pydantic ^2.10.0` + `pydantic-settings` - Config & validation

### Frontend

- `react ^19.2.3` - UI framework
- `tailwindcss ^4.1.18` - Styling (uses Vite plugin)
- `vite ^7.2.4` - Build tool

## Code Style

- **Backend**: Black formatter (line-length 88), Ruff linter (Python 3.12+)
- **Frontend**: TypeScript strict mode, React 19 hooks

## Common Gotchas

1. **Message role conversion**: Gemini uses `"model"` role, we use `"assistant"` - conversion in [gemini_adapter.py](back/src/infrastructure/adapters/gemini_adapter.py#L23-L36)
2. **Streaming**: Use `execute_stream()` method in `ChatUseCase`, not `execute()` - returns `AsyncIterator[tuple[str, str]]` with (conversation_id, token)
3. **WebSocket reconnection**: Frontend auto-reconnects but loses conversation history (no server persistence)
4. **Poetry virtual env**: Always use `poetry run` or activate venv before running Python commands

---

## 💬 Funcionalidades da IA (Roadmap)

### Capacidades Planejadas para o Atendente Virtual

#### Atendimento Automatizado

1. **Iniciar e conduzir conversas** via WhatsApp/Instagram
2. **Entender necessidades**: tipo de ensaio, data, local, duração
3. **Apresentar serviços**: pacotes, valores, portfólio
4. **Responder dúvidas frequentes** com linguagem natural
5. **Enviar arquivos**: propostas, contratos, PDFs
6. **Conduzir ao fechamento** com validação final do profissional

#### Integração com Calendário

- 📅 Verificar disponibilidade automaticamente
- 🔒 Bloquear horários após fechamento
- ✏️ Permitir edição manual pelo profissional
- 🔔 Enviar lembretes automáticos (48h e 24h antes)

#### Gestão de Pagamentos

- 💵 Informar valores e formas de pagamento
- 📤 Enviar dados de pagamento (Pix, link)
- 📥 Receber comprovantes automaticamente
- ⏳ Status "Aguardando conferência" → ✅ "Confirmado" (após validação)

#### Sistema de Notificações

- 🎉 Notificar profissional sobre fechamentos
- 💳 Alertar sobre pagamentos recebidos
- 📆 Informar alterações de agenda

---

## 🎛️ Painel do Profissional (Futuro)

### Funcionalidades de Gestão Planejadas

- **Visualização de leads**: status (em atendimento, fechado, pendente, cancelado)
- **Edição manual**: qualquer informação pode ser ajustada
- **Configuração da IA**:
  - Horários ativos
  - Tipos de serviço e valores
  - Tom de comunicação
  - Textos padrão

### Filosofia do Produto

> **"A IA não substitui o profissional — ela protege o tempo dele."**

**Estratégia MVP**: Começar semi-automático (IA conduz → profissional valida com 1 clique)

---

## 📊 Métricas de Sucesso (Alvo)

| Métrica             | Meta                |
| ------------------- | ------------------- |
| Taxa de resposta    | < 1 minuto          |
| Disponibilidade     | 24/7 (99.9% uptime) |
| Conversão vs manual | +30%                |
| Tempo economizado   | 10-15h/semana       |
