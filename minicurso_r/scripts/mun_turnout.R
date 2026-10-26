
# Pacotes e função auxiliar ----

library(tidyverse)
library(duckplyr)
library(DBI)
library(duckdb)
library(R.utils)
library(here)
source(here::here("minicurso_r/scripts/download_tse.R"))


# Diretório e coleta dos dados ----


if(!dir.exists(here::here("minicurso_r/data/dados_brutos/mun_turnout"))) dir.create(here::here("minicurso_r/data/dados_brutos/mun_turnout"), recursive = TRUE)

download_tse(file_name = "detalhe_votacao_munzona", years = seq(1998, 2024, 2), unzip_path = here::here("minicurso_r/data/dados_brutos/mun_turnout"))

# Tratamento principal ----

lista_df <- list()

for (x in list.files(here::here("minicurso_r/data/dados_brutos/mun_turnout"), full.names = TRUE)){
  print(x)
  
  lista_df[[x]] <- data.table::fread(x, encoding = "Latin-1") |> 
    select(
      any_of(
        c(
          "ANO_ELEICAO", "NM_TIPO_ELEICAO", 
          "DT_ELEICAO", "NR_TURNO", 
          "SG_UF", "CD_MUNICIPIO", 
          "DS_CARGO", 
          "QT_APTOS", 
          "QT_COMPARECIMENTO", "QT_VOTOS_CONCORRENTES",
          "QT_ABSTENCOES", "QT_VOTOS_BRANCOS",  "QT_VOTOS_NULOS"
        )
      )
    ) |> 
    group_by(ANO_ELEICAO, NM_TIPO_ELEICAO, DT_ELEICAO, NR_TURNO, SG_UF, CD_MUNICIPIO, DS_CARGO) |> 
    summarise(
      across(contains("QT_"), ~ sum(.x, na.rm = TRUE))
    )
  
}

mun_turnout <- lista_df |>
  bind_rows() |> 
  mutate(
    NM_TIPO_ELEICAO = NM_TIPO_ELEICAO  |>
      stringi::stri_trans_general("ascii") |>
      toupper(),
    DS_CARGO = DS_CARGO |> 
      stringi::stri_trans_general("ascii") |>
      toupper()
  )


# Base tratada ----

if(!dir.exists(here::here("minicurso_r/data/tratados"))) dir.create(here::here("minicurso_r/data/tratados"), recursive = TRUE)

con <- dbConnect(
  duckdb(),
  dbdir = here::here("minicurso_r/data/tratados/TSE")
)

dbWriteTable(con, "mun_turnout", mun_turnout, overwrite = TRUE)

