# ----------------------------------------------------------------
# llm - https://virtualenv.pypa.io/en/latest/
# ----------------------------------------------------------------

@llm-install:
    llm install llm-claude
    llm install llm-ollama

@llm-upgrade:
    llm install llm-claude
    llm install llm-ollama
