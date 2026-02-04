#!/bin/bash

# Script de inicialização rápida do Luv
#

echo "🚀 Luv - Iniciando aplicação..."
echo ""

# Verifica se está na raiz do projeto
if [ ! -d "back" ] || [ ! -d "front" ]; then
    echo "❌ Erro: Execute este script da raiz do projeto"
    exit 1
fi

# Verifica .env
if [ ! -f "back/.env" ]; then
    echo "⚠️  Arquivo .env não encontrado!"
    echo "📝 Criando a partir do .env.example..."
    cp back/.env.example back/.env
    echo ""
    echo "⚠️  IMPORTANTE: Configure sua GOOGLE_API_KEY no arquivo back/.env"
    echo "   Obtenha sua chave em: https://aistudio.google.com/apikey"
    echo ""
    read -p "Pressione Enter depois de configurar a API Key..."
fi

# Função para iniciar o backend
start_backend() {
    echo "🐍 Iniciando backend..."
    cd back
    
    # Verifica se Poetry está instalado
    if ! command -v poetry &> /dev/null; then
        echo "❌ Poetry não encontrado. Instalando..."
        curl -sSL https://install.python-poetry.org | python3 -
    fi
    
    # Instala dependências se necessário
    if [ ! -d ".venv" ]; then
        echo "📦 Instalando dependências do backend..."
        poetry install
    fi
    
    echo "✅ Backend iniciado em http://localhost:8000"
    poetry run python main.py
}

# Função para iniciar o frontend
start_frontend() {
    echo "⚛️  Iniciando frontend..."
    cd front
    
    # Instala dependências se necessário
    if [ ! -d "node_modules" ]; then
        echo "📦 Instalando dependências do frontend..."
        npm install
    fi
    
    echo "✅ Frontend iniciado em http://localhost:5173"
    npm run dev
}

# Inicia backend em background
start_backend &
BACKEND_PID=$!

# Aguarda um pouco para o backend iniciar
sleep 3

# Inicia frontend
start_frontend &
FRONTEND_PID=$!

# Trap para limpar processos ao sair
cleanup() {
    echo ""
    echo "🛑 Encerrando aplicação..."
    kill $BACKEND_PID 2>/dev/null
    kill $FRONTEND_PID 2>/dev/null
    exit 0
}

trap cleanup SIGINT SIGTERM

# Aguarda
echo ""
echo "✨ Aplicação rodando!"
echo "   Backend:  http://localhost:8000"
echo "   Frontend: http://localhost:5173"
echo ""
echo "Pressione Ctrl+C para encerrar"
echo ""

wait
