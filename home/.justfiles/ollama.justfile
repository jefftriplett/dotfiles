# ----------------------------------------------------------------
# Ollama recipes
# ----------------------------------------------------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/ollama.justfile"
export OLLAMA_FLASH_ATTENTION := "true"
export OLLAMA_HOST := "0.0.0.0:11434"
export OLLAMA_KEEP_ALIVE := "30m"
export OLLAMA_KV_CACHE_TYPE := "f16"
export OLLAMA_ORIGINS := "http://*"

[private]
@default:
    just --justfile {{ justfile }} --list

[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# copy custom ollama plist file to homebrew directory
@copy-plist:
    cp ~/.plists/homebrew.mxcl.ollama.plist /opt/homebrew/opt/ollama/homebrew.mxcl.ollama.plist

# compare local ollama plist with installed version
@diff-plist:
    diff ~/.plists/homebrew.mxcl.ollama.plist /opt/homebrew/opt/ollama/homebrew.mxcl.ollama.plist

# download various ollama models (- prefix makes failures non-fatal)
@download:
    # https://github.com/jmorganca/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values
    # https://github.com/jmorganca/ollama/blob/main/examples/python/client.py
    # https://github.com/jmorganca/ollama/pull/405/files#diff-7f12e314e14b1321e41971e2e84a07a9e200b99b6ecac2a5c7a6b98d887f3305

    -ollama pull codellama:13b
    -ollama pull codellama:13b-instruct
    -ollama pull codellama:13b-python
    -ollama pull codellama:7b-code
    -ollama pull codellama:7b-instruct
    -ollama pull codellama:7b-python
    -ollama pull codellama:latest
    -ollama pull codeup:latest
    -ollama pull dolphin-mixtral
    -ollama pull falcon:40b
    -ollama pull falcon:7b
    -ollama pull falcon:latest
    -ollama pull llama2-uncensored:7b
    -ollama pull llama2-uncensored:latest
    -ollama pull llama2:13b
    -ollama pull llama2:latest
    -ollama pull mixtral
    -ollama pull orca2:13b
    -ollama pull orca2:7b
    -ollama pull orca2:latest
    -ollama pull wizard-vicuna:latest

# list all downloaded ollama models
@list:
    ollama list

# display ollama environment variables from launchctl
@getenv:
    launchctl getenv OLLAMA_FLASH_ATTENTION
    launchctl getenv OLLAMA_HOST
    launchctl getenv OLLAMA_KEEP_ALIVE
    launchctl getenv OLLAMA_KV_CACHE_TYPE
    launchctl getenv OLLAMA_ORIGINS

# serve ollama in a tandem process with optional arguments
@serve *ARGS:
    tandem 'ollama serve {{ ARGS }}'

# set ollama environment variables in launchctl
@setenv:
    launchctl setenv OLLAMA_FLASH_ATTENTION {{ OLLAMA_FLASH_ATTENTION }}
    launchctl setenv OLLAMA_HOST {{ OLLAMA_HOST }}
    launchctl setenv OLLAMA_KEEP_ALIVE {{ OLLAMA_KEEP_ALIVE }}
    launchctl setenv OLLAMA_KV_CACHE_TYPE {{ OLLAMA_KV_CACHE_TYPE }}
    launchctl setenv OLLAMA_ORIGINS {{ OLLAMA_ORIGINS }}
