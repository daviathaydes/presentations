library(glue)
#############################################################################
#############################################################################
check_dir <- function(path = "data/dados_brutos/cand/"){

  if (dir.exists(path)){
    message(paste("Diretorio Existe: ", path))
  } else {

    dir.create(path)
    message(paste("Diretorio Criado: ", path))
  }
}

check_file <- function(path = "data/dados_brutos/cand/consulta_cand_2024_BRASIL.csv"){

  if (file.exists(path)){
    message(paste("Arquivo Existe: ", path, "(Portanto não foi baixado)"))
    return(TRUE)

  } else {

    message(paste("Arquivo Não Existe: ", path))
    return(FALSE)
  }
}

#############################################################################
#############################################################################
download_tse <- function(file_name = "", folder_name = file_name, years = 2024, unzip_path = getwd()){
  options(timeout = Inf)
  check_dir(path = unzip_path)
  TSE_URL <- "https://cdn.tse.jus.br/estatistica/sead/odsele/"
  
  handle <- curl::new_handle(
    useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
  )
  
  for (x in years){
    url_year <- glue(TSE_URL, "{folder_name}/{file_name}_{x}.zip")
    temp_path <- file.path(tempdir(), glue("{file_name}_{x}.zip"))
    future_file <- file.path(unzip_path, glue("{file_name}_{x}_BRASIL.csv"))
    if (check_file(future_file)){
      next
    }
    message("Download From:\n", url_year)
    curl::curl_download(
      url      = url_year,
      destfile = temp_path,
      handle   = handle
    )
    unzip(
      zipfile = temp_path,
      files   = glue("{file_name}_{x}_BRASIL.csv"),
      exdir   = unzip_path
    )
  }
}